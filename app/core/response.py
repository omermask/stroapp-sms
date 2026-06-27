import uuid
from datetime import datetime, timezone
from typing import Any, Optional

from app.core.exceptions import ERROR_CODES


def success_response(data: Any, request_id: str = "") -> dict:
    return {
        "success": True,
        "data": data,
        "error": None,
        "meta": {
            "request_id": request_id,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        },
    }


def error_response(
    code: str,
    message: Optional[str] = None,
    status_code: int = 400,
    request_id: str = "",
    error_id: Optional[str] = None,
) -> dict:
    if message is None:
        message = ERROR_CODES.get(code, "Unknown error")
    return {
        "success": False,
        "data": None,
        "error": {
            "code": code,
            "message": message,
            "error_id": error_id or str(uuid.uuid4()),
            "request_id": request_id,
        },
        "meta": {
            "request_id": request_id,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        },
    }
