from datetime import datetime, timezone

from fastapi import Request
from sqlalchemy.orm import Session
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.database import SessionLocal
from app.core.logging import get_logger
from app.domain.models import AuditLog, gen_uuid

logger = get_logger(__name__)

EXCLUDED_PATHS = {"/stroapp/v1/health", "/stroapp/metrics", "/stroapp/docs", "/stroapp/redoc", "/stroapp/openapi.json"}
WRITE_METHODS = {"POST", "PUT", "PATCH", "DELETE"}


class EnterpriseAuditMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)

        if request.method not in WRITE_METHODS:
            return response
        if request.url.path in EXCLUDED_PATHS:
            return response

        try:
            user_id = ""
            if hasattr(request.state, "user_id"):
                user_id = request.state.user_id
            elif hasattr(request.state, "user"):
                user_id = getattr(request.state.user, "id", "")

            if not user_id:
                return response

            db = SessionLocal()
            try:
                log = AuditLog(
                    id=gen_uuid(),
                    user_id=user_id,
                    action=f"{request.method.lower()}.{request.url.path.replace('/', '.')}",
                    resource_type="api",
                    resource_id="",
                    details={
                        "method": request.method,
                        "path": request.url.path,
                        "query": str(request.url.query),
                        "status_code": response.status_code,
                    },
                    ip_address=request.client.host if request.client else "",
                    request_id=getattr(request.state, "request_id", ""),
                )
                db.add(log)
                db.commit()
            except Exception as e:
                logger.warning(f"Audit log error: {e}")
            finally:
                db.close()
        except Exception as e:
            logger.warning(f"Enterprise audit middleware error: {e}")

        return response
