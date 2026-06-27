from urllib.parse import urlparse

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from app.core.config import get_settings
from app.core.exceptions import AppException
from starlette.responses import JSONResponse
from app.core.response import error_response


STATEFUL_METHODS = frozenset({"POST", "PUT", "PATCH", "DELETE"})

SKIP_CSRF_PATHS = frozenset({
    "/stroapp/v1/user/auth/login",
    "/stroapp/v1/user/auth/register",
    "/stroapp/v1/user/auth/refresh",
    "/stroapp/v1/user/auth/google",
    "/stroapp/v1/user/auth/apple",
    "/stroapp/v1/user/auth/logout",
    "/stroapp/v1/user/auth/forgot-password",
    "/stroapp/v1/user/auth/reset-password",
    "/stroapp/v1/user/email/verify",
    "/stroapp/v1/user/email/temp/messages",
    "/stroapp/v1/admin/login",
    "/stroapp/v4/admin/api/login",
    "/stroapp/v1/waitlist/join",
    "/stroapp/v1/health",
    "/stroapp/metrics",
    "/stroapp/v1/auth/login",
})


class CSRFTokenMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        settings = get_settings()
        if request.method in STATEFUL_METHODS and request.url.path.startswith("/stroapp/"):
            if request.url.path in SKIP_CSRF_PATHS:
                response = await call_next(request)
                return response
            origin = request.headers.get("origin", "")
            allowed_hosts = settings.allowed_hosts
            parsed = urlparse(origin)
            origin_host = parsed.hostname or ""
            if origin and allowed_hosts and "*" not in allowed_hosts:
                if origin_host not in allowed_hosts:
                    return JSONResponse(
                        status_code=403,
                        content=error_response(
                            code="CSRF_ERROR",
                            message="فشل التحقق من CSRF: مصدر غير صالح",
                            request_id=getattr(request.state, "request_id", ""),
                        ),
                    )
            auth = request.headers.get("authorization", "")
            if not auth.startswith("Bearer "):
                csrf_token = request.headers.get("x-csrf-token", "") or request.headers.get("x-xsrf-token", "")
                if not csrf_token:
                    return JSONResponse(
                        status_code=403,
                        content=error_response(
                            code="CSRF_ERROR",
                            message="فشل التحقق من CSRF: الرأس x-csrf-token مفقود",
                            request_id=getattr(request.state, "request_id", ""),
                        ),
                    )
                if len(csrf_token) < 16:
                    return JSONResponse(
                        status_code=403,
                        content=error_response(
                            code="CSRF_ERROR",
                            message="فشل التحقق من CSRF: رمز غير صالح",
                            request_id=getattr(request.state, "request_id", ""),
                        ),
                    )
        response = await call_next(request)
        return response
