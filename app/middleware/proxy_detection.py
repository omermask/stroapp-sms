import socket
from typing import Optional

from fastapi import Request, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.logging import get_logger
logger = get_logger(__name__)


KNOWN_PROXY_HEADERS = {
    "x-forwarded-for", "x-real-ip", "x-forwarded-proto",
    "via", "x-varnish", "forwarded",
}

RESIDENTIAL_PROXY_ORG_NAMES = [
    "amazon", "google cloud", "microsoft azure", "digitalocean",
    "linode", "vultr", "ovh", "hetzner", "scaleway", "oracle cloud",
    "alibaba cloud", "tencent cloud",
]

PRIVATE_RANGES = [
    ("127.0.0.0", 8), ("10.0.0.0", 8), ("172.16.0.0", 12),
    ("192.168.0.0", 16),
]


def _ip_in_private_range(ip: str) -> bool:
    try:
        packed = int.from_bytes(socket.inet_aton(ip), "big")
        for base, prefix in PRIVATE_RANGES:
            mask = (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF
            base_int = int.from_bytes(socket.inet_aton(base), "big")
            if (packed & mask) == (base_int & mask):
                return True
    except OSError as e:
        logger.warning(f"Proxy detection IP check error: {e}")
    return False


class ProxyDetectionMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if request.url.path in ("/stroapp/v1/health", "/stroapp/metrics",
                                 "/stroapp/docs", "/stroapp/redoc"):
            return await call_next(request)

        ip = request.client.host if request.client else ""

        proxy_headers_present = any(
            h.lower() in KNOWN_PROXY_HEADERS for h in request.headers.keys()
        )

        is_private = _ip_in_private_range(ip) if ip else False

        request.state.proxy_detected = proxy_headers_present and not is_private
        request.state.client_ip = ip

        return await call_next(request)
