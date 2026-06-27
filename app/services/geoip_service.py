import asyncio
import logging
import re
from typing import Optional

import aiohttp

logger = logging.getLogger(__name__)

_PRIVATE_IPS = re.compile(r"^(127\.|10\.|172\.(1[6-9]|2\d|3[01])\.|192\.168\.|::1|fd)")

_cache: dict[str, tuple[str | None, str | None]] = {}

_SESSION: Optional[aiohttp.ClientSession] = None


async def _get_session() -> aiohttp.ClientSession:
    global _SESSION
    if _SESSION is None or _SESSION.closed:
        _SESSION = aiohttp.ClientSession()
    return _SESSION


def _is_private_ip(ip: str) -> bool:
    return bool(_PRIVATE_IPS.match(ip))


async def lookup(ip: str) -> tuple[str | None, str | None]:
    if not ip or _is_private_ip(ip):
        return (None, None)

    cached = _cache.get(ip)
    if cached:
        return cached

    try:
        session = await _get_session()
        async with session.get(
            f"http://ip-api.com/json/{ip}?fields=city,country",
            timeout=aiohttp.ClientTimeout(total=3),
        ) as resp:
            if resp.status == 200:
                data = await resp.json()
                city = data.get("city") or None
                country = data.get("country") or None
                _cache[ip] = (city, country)
                return (city, country)
    except asyncio.TimeoutError:
        logger.warning("GeoIP lookup timed out for %s", ip)
    except Exception as e:
        logger.warning("GeoIP lookup failed for %s: %s", ip, e)

    _cache[ip] = (None, None)
    return (None, None)
