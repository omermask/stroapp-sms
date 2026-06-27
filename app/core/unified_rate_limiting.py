import asyncio
import time
from collections import defaultdict
from typing import Optional

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)

try:
    import redis.asyncio as aioredis
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False


class TokenBucket:
    def __init__(self, capacity: int, refill_rate: float):
        self.capacity = capacity
        self.refill_rate = refill_rate
        self.tokens = capacity
        self.last_refill = time.monotonic()

    def consume(self, tokens: int = 1) -> bool:
        now = time.monotonic()
        elapsed = now - self.last_refill
        self.tokens = min(self.capacity, self.tokens + elapsed * self.refill_rate)
        self.last_refill = now
        if self.tokens >= tokens:
            self.tokens -= tokens
            return True
        return False


class SlidingWindowCounter:
    def __init__(self, window_seconds: int = 60, max_requests: int = 60):
        self.window = window_seconds
        self.max_requests = max_requests
        self.entries: list[float] = []

    def allow(self) -> bool:
        now = time.monotonic()
        cutoff = now - self.window
        self.entries = [t for t in self.entries if t > cutoff]
        if len(self.entries) < self.max_requests:
            self.entries.append(now)
            return True
        return False


class RedisRateLimiterBackend:
    def __init__(self):
        self._client: Optional[aioredis.Redis] = None
        self._enabled = False

    async def init(self):
        if not REDIS_AVAILABLE:
            return
        settings = get_settings()
        try:
            self._client = aioredis.from_url(settings.redis_url, decode_responses=True)
            await self._client.ping()
            self._enabled = True
            logger.info("Redis rate limiter backend enabled")
        except Exception as e:
            logger.warning(f"Redis rate limiter backend unavailable: {e}")

    async def check_rate(self, ip: str, endpoint: str, base_limit: int) -> tuple[bool, dict]:
        if not self._enabled or not self._client:
            return True, {"limit": base_limit, "remaining": base_limit, "reset": 60}
        try:
            ip_key = f"rl:ip:{ip}"
            ep_key = f"rl:ep:{endpoint}"
            ip_count = await self._client.incr(ip_key)
            if ip_count == 1:
                await self._client.expire(ip_key, 60)
            ep_count = await self._client.incr(ep_key)
            if ep_count == 1:
                await self._client.expire(ep_key, 60)
            ip_limit = max(base_limit, 300)
            ip_allowed = ip_count <= ip_limit
            ep_allowed = ep_count <= base_limit
            if not ip_allowed or not ep_allowed:
                return False, {"limit": base_limit, "remaining": 0, "reset": 60}
            return True, {"limit": base_limit, "remaining": max(0, base_limit - ep_count), "reset": 60}
        except Exception as e:
            logger.error(f"Redis rate check error: {e}")
            return True, {"limit": base_limit, "remaining": base_limit, "reset": 60}

    async def close(self):
        if self._client:
            await self._client.aclose()


class AdaptiveRateLimiter:
    def __init__(self):
        self.system_load = 0.0
        self._buckets: dict[str, TokenBucket] = {}
        self._windows: dict[str, SlidingWindowCounter] = {}
        self._load_task: Optional[asyncio.Task] = None
        self._redis = RedisRateLimiterBackend()

    async def init_redis(self):
        await self._redis.init()

    def get_bucket(self, key: str, capacity: int = 60, refill_rate: float = 5.0) -> TokenBucket:
        if key not in self._buckets:
            self._buckets[key] = TokenBucket(capacity, refill_rate)
        return self._buckets[key]

    def get_window(self, key: str, window_seconds: int = 60, max_requests: int = 60) -> SlidingWindowCounter:
        wkey = f"{key}:{window_seconds}:{max_requests}"
        if wkey not in self._windows:
            self._windows[wkey] = SlidingWindowCounter(window_seconds, max_requests)
        return self._windows[wkey]

    def check_rate(self, ip: str, endpoint: str) -> tuple[bool, dict]:
        settings = get_settings()
        base_limit = settings.rate_limit_per_minute
        if self.system_load > 0.9:
            base_limit = int(base_limit * 0.5)

        bucket = self.get_bucket(f"ip:{ip}", capacity=500, refill_rate=20.0)
        if not bucket.consume():
            return False, {"limit": base_limit, "remaining": 0, "reset": 1}

        window = self.get_window(f"ep:{endpoint}", window_seconds=60, max_requests=base_limit)
        if not window.allow():
            return False, {"limit": base_limit, "remaining": 0, "reset": 60}

        return True, {
            "limit": base_limit,
            "remaining": int(bucket.tokens),
            "reset": int(max(0, 1 - (time.monotonic() - bucket.last_refill))),
        }

    async def check_rate_redis(self, ip: str, endpoint: str) -> tuple[bool, dict]:
        settings = get_settings()
        base_limit = settings.rate_limit_per_minute
        if self.system_load > 0.9:
            base_limit = int(base_limit * 0.5)
        return await self._redis.check_rate(ip, endpoint, base_limit)

    def update_system_load(self, load: float):
        self.system_load = load


rate_limiter = AdaptiveRateLimiter()


class RateLimitMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if request.url.path in ("/stroapp/v1/health", "/stroapp/metrics", "/stroapp/docs", "/stroapp/redoc") or request.method == "OPTIONS":
            return await call_next(request)

        ip = request.client.host if request.client else "unknown"
        endpoint = request.url.path

        if rate_limiter._redis._enabled:
            allowed, info = await rate_limiter.check_rate_redis(ip, endpoint)
        else:
            allowed, info = rate_limiter.check_rate(ip, endpoint)
        if not allowed:
            return JSONResponse(
                status_code=429,
                content={"success": False, "data": None, "error": {"code": "RATE_LIMITED", "message": "طلبات كثيرة جداً، الرجاء المحاولة لاحقاً", "rate_limit": info}, "meta": {}},
            )

        response = await call_next(request)
        response.headers["X-RateLimit-Limit"] = str(info["limit"])
        response.headers["X-RateLimit-Remaining"] = str(info["remaining"])
        response.headers["X-RateLimit-Reset"] = str(info["reset"])
        response.headers["X-System-Load"] = f"{rate_limiter.system_load:.2f}"
        return response
