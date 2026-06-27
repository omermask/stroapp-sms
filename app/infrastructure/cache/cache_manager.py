import functools
import json
import time
from typing import Any, Callable, Optional

import redis.asyncio as aioredis

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)


class InMemoryCache:
    def __init__(self):
        self._cache: dict[str, Any] = {}
        self._expiry: dict[str, float] = {}

    async def get(self, key: str) -> Optional[Any]:
        if key not in self._cache:
            return None
        if key in self._expiry and time.time() > self._expiry[key]:
            del self._cache[key]
            del self._expiry[key]
            return None
        return self._cache[key]

    async def set(self, key: str, value: Any, ttl: int = 3600):
        self._cache[key] = value
        self._expiry[key] = time.time() + ttl

    async def delete(self, key: str):
        self._cache.pop(key, None)
        self._expiry.pop(key, None)

    async def clear(self, pattern: str = "*"):
        if pattern == "*":
            self._cache.clear()
            self._expiry.clear()
            return
        import fnmatch
        keys_to_delete = [k for k in self._cache if fnmatch.fnmatch(k, pattern)]
        for k in keys_to_delete:
            await self.delete(k)

    async def keys(self, pattern: str = "*"):
        import fnmatch
        return [key for key in self._cache if fnmatch.fnmatch(key, pattern)]


class CacheManager:
    def __init__(self):
        self._redis: Optional[aioredis.Redis] = None
        self._memory = InMemoryCache()
        self._redis_ok = False
        self.ttl_defaults = {
            "countries": 86400,
            "services": 3600,
            "verification": 300,
            "user": 1800,
            "provider": 600,
            "prices": 600,
            "default": 3600,
        }

    async def connect(self):
        if self._redis_ok:
            return
        settings = get_settings()
        try:
            self._redis = aioredis.from_url(
                settings.redis_url,
                decode_responses=True,
                max_connections=20,
                retry_on_timeout=True,
                socket_connect_timeout=5,
                socket_timeout=5,
            )
            await self._redis.ping()
            self._redis_ok = True
            logger.info("Redis connected")
        except Exception as e:
            logger.warning(f"Redis unavailable, using in-memory cache: {e}")
            self._redis = None
            self._redis_ok = False

    async def disconnect(self):
        if self._redis:
            await self._redis.close()
        self._redis = None
        self._redis_ok = False

    async def _ensure_redis(self):
        if self._redis is None and not self._redis_ok:
            await self.connect()
            return self._redis_ok
        if self._redis and not self._redis_ok:
            try:
                await self._redis.ping()
                self._redis_ok = True
            except Exception:
                self._redis_ok = False
                return False
        return self._redis_ok

    async def get(self, key: str) -> Optional[Any]:
        if await self._ensure_redis() and self._redis:
            try:
                value = await self._redis.get(key)
                if value is not None:
                    return json.loads(value)
            except Exception as e:
                logger.warning(f"Redis get error: {e}")
                self._redis_ok = False

        return await self._memory.get(key)

    async def set(self, key: str, value: Any, ttl: Optional[int] = None):
        ttl = ttl or self.ttl_defaults["default"]
        if await self._ensure_redis() and self._redis:
            try:
                await self._redis.setex(key, ttl, json.dumps(value, default=str))
            except Exception as e:
                logger.warning(f"Redis set error: {e}")
                self._redis_ok = False

        await self._memory.set(key, value, ttl)

    async def delete(self, key: str):
        if await self._ensure_redis() and self._redis:
            try:
                await self._redis.delete(key)
            except Exception as e:
                logger.warning(f"Redis delete error: {e}")
                self._redis_ok = False
        await self._memory.delete(key)

    async def invalidate_pattern(self, pattern: str):
        if await self._ensure_redis() and self._redis:
            try:
                cursor = 0
                while True:
                    cursor, keys = await self._redis.scan(cursor=cursor, match=pattern, count=100)
                    if keys:
                        await self._redis.delete(*keys)
                    if cursor == 0:
                        break
            except Exception as e:
                logger.warning(f"Redis pattern invalidation error: {e}")
                self._redis_ok = False

        await self._memory.clear(pattern)

    async def clear(self):
        if await self._ensure_redis() and self._redis:
            try:
                cursor = 0
                while True:
                    cursor, keys = await self._redis.scan(cursor=cursor, count=500)
                    if keys:
                        await self._redis.delete(*keys)
                    if cursor == 0:
                        break
            except Exception as e:
                logger.warning(f"Redis clear error: {e}")
                self._redis_ok = False
        await self._memory.clear()

    def cache_key(self, prefix: str, *args) -> str:
        return f"{prefix}:{':'.join(str(a) for a in args)}"

    def cached(self, ttl: Optional[int] = None, key_prefix: str = ""):
        def decorator(func: Callable):
            @functools.wraps(func)
            async def wrapper(*args, **kwargs):
                cache_key = self.cache_key(key_prefix or func.__name__, *args, **kwargs)
                cached = await self.get(cache_key)
                if cached is not None:
                    return cached
                result = await func(*args, **kwargs)
                await self.set(cache_key, result, ttl)
                return result
            return wrapper
        return decorator


cache = CacheManager()
