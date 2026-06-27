import base64
import os

from starlette.datastructures import MutableHeaders
from starlette.types import ASGIApp, Receive, Scope, Send

from app.core.config import get_settings


class SecurityHeadersMiddleware:
    def __init__(self, app: ASGIApp):
        self.app = app
        self.settings = get_settings()

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        nonce = base64.b64encode(os.urandom(16)).decode("utf-8")
        if "state" not in scope:
            scope["state"] = {}
        scope["state"]["csp_nonce"] = nonce

        is_production = self.settings.environment == "production"
        is_https = scope.get("scheme", "") == "https" or scope.get("server", [None])[0] in ("localhost", "127.0.0.1")

        csp_policy = (
            f"default-src 'self'; "
            f"script-src 'self' 'unsafe-inline' 'unsafe-eval' https://unpkg.com "
            f"https://cdn.jsdelivr.net https://cdn.tailwindcss.com; "
            f"style-src 'self' 'unsafe-inline' https://fonts.googleapis.com "
            f"https://cdnjs.cloudflare.com; "
            f"font-src 'self' https://fonts.gstatic.com https://cdnjs.cloudflare.com; "
            f"img-src 'self' data: https:; "
            f"connect-src 'self'; "
            f"frame-src 'none'; object-src 'none'; "
            f"base-uri 'self'; form-action 'self';"
        )

        async def send_with_headers(message: dict) -> None:
            if message["type"] == "http.response.start":
                headers = MutableHeaders(scope=message)
                headers["X-Content-Type-Options"] = "nosniff"
                headers["X-Frame-Options"] = "DENY"
                headers["X-XSS-Protection"] = "1; mode=block"
                headers["Content-Security-Policy"] = csp_policy
                headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
                headers["Permissions-Policy"] = (
                    "camera=(), microphone=(), geolocation=()"
                )
                headers["Cross-Origin-Opener-Policy"] = "same-origin"
                if is_production:
                    headers["Strict-Transport-Security"] = (
                        "max-age=31536000; includeSubDomains"
                    )
            await send(message)

        await self.app(scope, receive, send_with_headers)
