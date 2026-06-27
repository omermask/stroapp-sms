from datetime import datetime, timezone

from fastapi import APIRouter, Request

from app.core.config import get_settings
from app.core.database import test_connection
from app.core.response import success_response

router = APIRouter(tags=["Health"])


@router.get("/health")
async def health(request: Request):
    request_id = getattr(request.state, "request_id", "")
    db_ok = test_connection()
    return success_response(
        {
            "status": "ok" if db_ok else "degraded",
            "app": "StroApp SMS",
            "version": "1.0.0",
            "database": "connected" if db_ok else "disconnected",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        },
        request_id=request_id,
    )


@router.get("/version")
async def version(request: Request):
    settings = get_settings()
    request_id = getattr(request.state, "request_id", "")
    return success_response(
        {
            "version": "1.0.0",
            "app": "StroApp SMS",
            "environment": settings.environment,
        },
        request_id=request_id,
    )
