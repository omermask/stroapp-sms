import asyncio
import os
import uuid
from contextlib import asynccontextmanager

from dotenv import load_dotenv

load_dotenv()

import uvicorn
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.middleware.gzip import GZipMiddleware

from app.api.v1.router import router as v1_router
from app.api.v4.router import router as v4_router
from app.core.config import get_settings
from app.core.database import test_connection
from app.core.data_masker import mask_headers, sanitize_log_message
from app.core.exceptions import AppException
import app.domain.models  # noqa: F401 - register models with SQLAlchemy metadata
from app.core.logging import get_logger, setup_logging
from app.core.middleware import RequestBodySizeLimitMiddleware, RequestIDMiddleware
from app.core.unified_rate_limiting import RateLimitMiddleware as UnifiedRateLimitMiddleware, rate_limiter as adaptive_rate_limiter
from app.core.response import error_response
from app.core.security_headers import SecurityHeadersMiddleware
from app.core.csrf import CSRFTokenMiddleware
from app.core.sentry import init_sentry
from app.core.openapi import customize_openapi
from app.core.xss_protection import XSSProtectionMiddleware
from app.middleware.audit_middleware import EnterpriseAuditMiddleware
from app.middleware.blacklist_middleware import BlacklistMiddleware
from app.middleware.proxy_detection import ProxyDetectionMiddleware
from app.middleware.device_fingerprint import DeviceFingerprintMiddleware
from app.core.database import SessionLocal
from app.services.background import RefundEnforcer, HealthChecker, TempEmailQuotaResetter, RentalExpiryEnforcer, IdempotencyCleanupTask
from app.services.security_scanner import SecurityAuditJob
from app.services.backup_service import BackupJob
from app.services.retry_service import RetryService
from app.services.cache_warming import CacheWarmingService
from app.services.adaptive_polling import SMSPollingJob
from app.services.sync_service import SyncOrchestrator
from app.services.payment_service import PaymentService
from app.services.webhook_service import WebhookService
from app.services.tier_service import TierService
from app.services.email_template_service import EmailTemplateService
from prometheus_client import make_asgi_app, Counter, Histogram, CollectorRegistry
from starlette.middleware.base import BaseHTTPMiddleware
import time

PROM_REGISTRY = CollectorRegistry()
REQUEST_COUNT = Counter("http_requests_total", "Total HTTP requests", ["method", "endpoint", "status"], registry=PROM_REGISTRY)
REQUEST_DURATION = Histogram("http_request_duration_seconds", "HTTP request duration", ["method", "endpoint"], registry=PROM_REGISTRY)

settings = get_settings()
logger = get_logger("startup")


def create_app() -> FastAPI:
    setup_logging()

    init_sentry()

    fastapi_app = FastAPI(
        title=settings.app_name,
        version=settings.version,
        description="SMS Verification Service",
        docs_url="/stroapp/docs",
        redoc_url="/stroapp/redoc",
        lifespan=lifespan,
    )

    fastapi_app.add_middleware(GZipMiddleware, minimum_size=1000)

    fastapi_app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["Content-Type", "Authorization", "X-Request-Id"],
    )

    fastapi_app.add_middleware(SecurityHeadersMiddleware)
    fastapi_app.add_middleware(XSSProtectionMiddleware)
    fastapi_app.add_middleware(UnifiedRateLimitMiddleware)
    fastapi_app.add_middleware(RequestBodySizeLimitMiddleware)
    fastapi_app.add_middleware(RequestIDMiddleware)
    fastapi_app.add_middleware(CSRFTokenMiddleware)
    fastapi_app.add_middleware(EnterpriseAuditMiddleware)
    fastapi_app.add_middleware(BlacklistMiddleware)
    fastapi_app.add_middleware(ProxyDetectionMiddleware)
    fastapi_app.add_middleware(DeviceFingerprintMiddleware)

    fastapi_app.include_router(v1_router)
    fastapi_app.include_router(v4_router)

    customize_openapi(fastapi_app)

    try:
        metrics_app = make_asgi_app(registry=PROM_REGISTRY)
        fastapi_app.mount("/stroapp/metrics", metrics_app)
    except Exception as e:
        logger.warning(f"Prometheus metrics mount failed: {e}")

    class RequestLogMiddleware(BaseHTTPMiddleware):
        async def dispatch(self, request: Request, call_next):
            start = time.time()
            response = await call_next(request)
            duration = time.time() - start
            logger.info(f"[{response.status_code}] {request.method} {request.url.path} ({duration:.3f}s)")
            return response

    fastapi_app.add_middleware(RequestLogMiddleware)

    class PrometheusMiddleware(BaseHTTPMiddleware):
        async def dispatch(self, request: Request, call_next):
            start = time.time()
            response = await call_next(request)
            duration = time.time() - start
            REQUEST_COUNT.labels(method=request.method, endpoint=request.url.path, status=response.status_code).inc()
            REQUEST_DURATION.labels(method=request.method, endpoint=request.url.path).observe(duration)
            return response

    fastapi_app.add_middleware(PrometheusMiddleware)

    @fastapi_app.exception_handler(404)
    async def not_found_handler(request: Request, exc: Exception):
        request_id = getattr(request.state, "request_id", str(uuid.uuid4()))
        return JSONResponse(
            status_code=404,
            content=error_response(
                code="NOT_FOUND",
                message="الصفحة المطلوبة غير موجودة",
                request_id=request_id,
            ),
        )

    @fastapi_app.exception_handler(AppException)
    async def app_exception_handler(request: Request, exc: AppException):
        request_id = getattr(request.state, "request_id", str(uuid.uuid4()))
        return JSONResponse(
            status_code=exc.status_code,
            content=error_response(
                code=exc.code,
                message=exc.message,
                request_id=request_id,
                error_id=exc.error_id,
            ),
        )

    @fastapi_app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception):
        request_id = getattr(request.state, "request_id", str(uuid.uuid4()))
        error_id = str(uuid.uuid4())
        safe_msg = sanitize_log_message(str(exc))
        safe_headers = mask_headers(dict(request.headers))
        logger.error(
            f"Unhandled error [{error_id}]: {safe_msg}",
            extra={"request_id": request_id, "error_id": error_id, "headers": safe_headers},
        )
        return JSONResponse(
            status_code=500,
            content=error_response(
                code="INTERNAL_ERROR",
                request_id=request_id,
                error_id=error_id,
            ),
        )

    return fastapi_app


@asynccontextmanager
async def lifespan(app: FastAPI):
    background_tasks: list[asyncio.Task] = []
    logger.info(f"Starting {settings.app_name} v{settings.version}...")
    await adaptive_rate_limiter.init_redis()
    if not test_connection():
        logger.error("Database connection failed")
        raise RuntimeError("Database connection failed")
    logger.info("Database migrations must be run manually or via Docker CMD (alembic upgrade head)")

    _validate_config(settings)
    background_tasks.append(asyncio.create_task(RefundEnforcer().run()))
    background_tasks.append(asyncio.create_task(HealthChecker().run()))
    background_tasks.append(asyncio.create_task(TempEmailQuotaResetter().run()))
    background_tasks.append(asyncio.create_task(RentalExpiryEnforcer().run()))
    background_tasks.append(asyncio.create_task(SecurityAuditJob().run()))
    background_tasks.append(asyncio.create_task(BackupJob().run()))
    background_tasks.append(asyncio.create_task(IdempotencyCleanupTask().run()))
    background_tasks.append(asyncio.create_task(_cache_warming()))
    background_tasks.append(asyncio.create_task(_retry_processor()))
    background_tasks.append(asyncio.create_task(SMSPollingJob().run()))
    background_tasks.append(asyncio.create_task(_webhook_retry_worker()))
    # sync_orchestrator = SyncOrchestrator()
    # sync_orchestrator.start(interval_seconds=3600)
    # if sync_orchestrator._task:
    #     background_tasks.append(sync_orchestrator._task)
    db = SessionLocal()
    try:
        PaymentService(db).seed_products()
        logger.info("Payment products seeded")
    except Exception as e:
        logger.warning(f"Could not seed payment products: {e}")
    try:
        TierService.seed_tiers(db)
        logger.info("Subscription tiers seeded")
    except Exception as e:
        logger.warning(f"Could not seed tiers: {e}")
    try:
        EmailTemplateService.seed_templates(db)
        logger.info("Email templates seeded")
    except Exception as e:
        logger.warning(f"Could not seed email templates: {e}")
    finally:
        db.close()
    logger.info("Application startup completed")

    yield

    logger.info(f"Shutting down {len(background_tasks)} background tasks...")
    for task in background_tasks:
        task.cancel()
    done, pending = await asyncio.wait(
        background_tasks,
        timeout=10,
        return_when=asyncio.ALL_COMPLETED,
    )
    if pending:
        logger.warning(f"{len(pending)} tasks did not finish within 10s timeout")
    for task in done:
        if task.cancelled():
            continue
        exc = task.exception()
        if exc:
            logger.error(f"Background task error during shutdown: {exc}")
    logger.info("Application shutdown completed")


async def _cache_warming():
    await asyncio.sleep(10)
    await CacheWarmingService.warm_all()
    while True:
        try:
            await asyncio.sleep(3600)
            await CacheWarmingService.warm_all()
        except asyncio.CancelledError:
            break
        except Exception as e:
            logger.error(f"Cache warming error: {e}")


async def _retry_processor():
    while True:
        try:
            await asyncio.sleep(30)
            await RetryService.process_pending_retries()
        except asyncio.CancelledError:
            break
        except Exception as e:
            logger.error(f"Retry processor error: {e}")


async def _webhook_retry_worker():
    while True:
        try:
            await asyncio.sleep(60)
            db = SessionLocal()
            try:
                svc = WebhookService(db)
                await svc.retry_failed_events()
            finally:
                db.close()
        except asyncio.CancelledError:
            break
        except Exception as e:
            logger.error(f"Webhook retry worker error: {e}")


def _validate_config(settings):
    warnings = []
    errors = []
    if not settings.secret_key or len(settings.secret_key) < 32:
        warnings.append("SECRET_KEY must be at least 32 characters")
    if not settings.jwt_secret_key or len(settings.jwt_secret_key) < 32:
        warnings.append("JWT_SECRET_KEY must be at least 32 characters")
    if settings.environment == "production":
        if not settings.database_url.startswith("postgresql://"):
            errors.append("DATABASE_URL must be a PostgreSQL URL")
        if not settings.base_url.startswith("https://"):
            warnings.append("BASE_URL should use HTTPS in production")
        if not settings.sentry_dsn:
            errors.append("SENTRY_DSN is required in production — errors will be invisible")
        if not settings.smtp_host:
            errors.append("SMTP_HOST is required in production — forgot password / email verification will fail")
        if not settings.turnstile_secret_key:
            errors.append("TURNSTILE_SECRET_KEY not set — registration has no bot protection")
        if settings.apple_issuer_id and (not settings.apple_key_id or not settings.apple_private_key):
            warnings.append("APPLE_ISSUER_ID set but APPLE_KEY_ID or APPLE_PRIVATE_KEY missing")
        if settings.apple_app_apple_id and not settings.apple_bundle_id:
            warnings.append("APPLE_APP_APPLE_ID set but APPLE_BUNDLE_ID missing")
    for w in warnings:
        logger.warning(f"Configuration warning: {w}")
    for e in errors:
        logger.error(f"Configuration error: {e}")


app = create_app()


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=settings.port)
