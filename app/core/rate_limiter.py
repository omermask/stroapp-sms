import time
from typing import Optional

from starlette.requests import Request
from starlette.responses import JSONResponse
from starlette.types import ASGIApp, Receive, Scope, Send

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)


try:
    import redis.asyncio as aioredis
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False


class RedisRateLimiter:
    def __init__(self):
        self._client: Optional[aioredis.Redis] = None
        self._enabled = False

    async def init(self):
        if not REDIS_AVAILABLE:
            logger.warning("redis not installed, falling back to in-memory rate limiter")
            return
        settings = get_settings()
        try:
            self._client = aioredis.from_url(settings.redis_url, decode_responses=True)
            await self._client.ping()
            self._enabled = True
            logger.info("Redis rate limiter enabled")
        except Exception as e:
            logger.warning(f"Redis unavailable for rate limiter: {e}, falling back to in-memory")
            self._enabled = False

    async def is_allowed(self, key: str, max_requests: int, window: int) -> bool:
        if not self._enabled or not self._client:
            _memory = InMemoryRateLimiter()
            return _memory.is_allowed(key, max_requests, window)
        try:
            current = await self._client.incr(key)
            if current == 1:
                await self._client.expire(key, window)
            return current <= max_requests
        except Exception as e:
            logger.error(f"Redis rate check failed: {e}, falling back to in-memory")
            _memory = InMemoryRateLimiter()
            return _memory.is_allowed(key, max_requests, window)

    async def close(self):
        if self._client:
            await self._client.aclose()


class InMemoryRateLimiter:
    MAX_BUCKETS = 100_000

    def __init__(self):
        self._buckets: dict[str, list[float]] = {}
        self._last_cleanup: float = time.time()

    def is_allowed(self, key: str, max_requests: int, window: float) -> bool:
        now = time.time()
        if now - self._last_cleanup > 300:
            self.cleanup()
            self._last_cleanup = now
        if key not in self._buckets:
            if len(self._buckets) >= self.MAX_BUCKETS:
                self._evict_one()
            self._buckets[key] = []
        timestamps = self._buckets[key]
        cutoff = now - window
        timestamps[:] = [t for t in timestamps if t > cutoff]
        if len(timestamps) >= max_requests:
            return False
        timestamps.append(now)
        return True

    def _evict_one(self):
        now = time.time()
        oldest_key = None
        oldest_time = now
        for k, v in self._buckets.items():
            if v and v[-1] < oldest_time:
                oldest_time = v[-1]
                oldest_key = k
        if oldest_key:
            del self._buckets[oldest_key]

    def cleanup(self):
        now = time.time()
        expired_keys = [
            k for k, v in self._buckets.items()
            if not v or (now - v[-1]) > 3600
        ]
        for k in expired_keys:
            del self._buckets[k]


class RateLimitMiddleware:
    def __init__(self, app: ASGIApp):
        self.app = app
        self.settings = get_settings()
        self._memory = InMemoryRateLimiter()
        self._redis = RedisRateLimiter()

    async def _is_allowed_hybrid(self, key: str, max_requests: int, window: int) -> bool:
        if self._redis._enabled:
            return await self._redis.is_allowed(key, max_requests, window)
        return self._memory.is_allowed(key, max_requests, window)

    def _get_client_ip(self, request: Request) -> str:
        forwarded = request.headers.get("x-forwarded-for")
        if forwarded:
            return forwarded.split(",")[0].strip()
        cf_ip = request.headers.get("cf-connecting-ip")
        if cf_ip:
            return cf_ip
        real_ip = request.headers.get("x-real-ip")
        if real_ip:
            return real_ip
        return request.client.host if request.client else "unknown"

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        request = Request(scope, receive)
        client_ip = self._get_client_ip(request)
        path = request.url.path

        static_routes = ("/stroapp/docs", "/stroapp/redoc", "/openapi.json")
        if path in static_routes:
            await self.app(scope, receive, send)
            return

        if not await self._is_allowed_hybrid(
            f"ip:{client_ip}",
            self.settings.rate_limit_per_minute,
            60,
        ):
            response = JSONResponse(
                status_code=429,
                content={
                    "success": False,
                    "data": None,
                    "error": {
                        "code": "RATE_LIMITED",
                        "message": "طلبات كثيرة جداً، الرجاء المحاولة لاحقاً",
                    },
                    "meta": {"timestamp": time.time()},
                },
            )
            await response(scope, receive, send)
            return

        await self.app(scope, receive, send)
