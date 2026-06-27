from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

from app.core.database import SessionLocal
from app.services.blacklist_service import BlacklistService


class BlacklistMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if request.url.path in ("/stroapp/v1/health", "/stroapp/metrics",
                                 "/stroapp/docs", "/stroapp/redoc") or request.method == "OPTIONS":
            return await call_next(request)

        ip = request.client.host if request.client else "unknown"
        db = SessionLocal()
        try:
            if BlacklistService.is_ip_blacklisted(db, ip):
                return JSONResponse(status_code=403, content={"success": False, "error": {"code": "IP_BLACKLISTED", "message": "تم حظر عنوان IP الخاص بك"}})
        finally:
            db.close()

        return await call_next(request)
