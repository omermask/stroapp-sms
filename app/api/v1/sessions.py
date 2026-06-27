import re

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.response import success_response
from app.core.security import verify_token
from app.core.session_manager import SessionManager
from app.domain.models import User, UserSession
from app.services.audit_service import AuditService
from app.services.blacklist_service import BlacklistService

router = APIRouter(prefix="/user/sessions", tags=["Sessions"])


def _parse_device(ua: str | None) -> str:
    if not ua:
        return "متصفح"
    ua_lower = ua.lower()

    # Flutter/Dart app (e.g. "Dart/3.11 (dart:io)" or "StroApp/1.0 ...")
    if "dart:" in ua_lower or "stroapp" in ua_lower:
        parts = ua.split()
        if "stroapp" in ua_lower:
            # "StroApp/1.0 android 14 Pixel_8" → "Pixel 8"
            if len(parts) >= 4:
                return parts[-1].replace("_", " ")
            # "StroApp/1.0 android 14" or "StroApp/1.0 android" → "Android"
            if len(parts) >= 2:
                name = parts[1]
                if name.lower() == "ios":
                    return "iOS"
                return name.capitalize()
        return "تطبيق StroApp"

    if "android" in ua_lower:
        return "Android"
    if "iphone" in ua_lower:
        return "iPhone"
    if "ipad" in ua_lower or "ios" in ua_lower:
        return "iPad"
    if "macintosh" in ua_lower or "mac os" in ua_lower:
        return "Mac"
    if "windows" in ua_lower:
        return "Windows"
    if "linux" in ua_lower:
        return "Linux"
    return "متصفح"


def _parse_os(ua: str | None) -> str | None:
    if not ua:
        return None
    ua_lower = ua.lower()

    # Flutter/Dart app
    if "stroapp" in ua_lower or "dart:" in ua_lower:
        parts = ua.split()
        if "stroapp" in ua_lower and len(parts) >= 3:
            os_name = parts[1]
            if os_name.lower() == "ios":
                os_name = "iOS"
            else:
                os_name = os_name.capitalize()
            os_ver = parts[2] if len(parts) >= 3 else None
            if os_ver:
                return f"{os_name} {os_ver}"
            return os_name
        if "stroapp" in ua_lower and len(parts) >= 2:
            os_name = parts[1]
            if os_name.lower() == "ios":
                return "iOS"
            return os_name.capitalize()
        if "dart:" in ua_lower:
            return "Flutter"
        return None

    m = re.search(r"android (\d+(?:\.\d+)*)", ua_lower)
    if m:
        return f"Android {m.group(1)}"

    m = re.search(r"(?:iphone|ipad|ipod).*?os (\d+[_0-9]*)", ua_lower)
    if m:
        return f"iOS {m.group(1).replace('_', '.')}"

    m = re.search(r"mac os x (\d+[_0-9]*)", ua_lower)
    if m:
        return f"macOS {m.group(1).replace('_', '.')}"

    m = re.search(r"windows nt (\d+(?:\.\d+)?)", ua_lower)
    if m:
        versions = {"10.0": "10", "6.3": "8.1", "6.2": "8", "6.1": "7"}
        ver = m.group(1)
        return f"Windows {versions.get(ver, ver)}"

    if "linux" in ua_lower and "android" not in ua_lower:
        return "Linux"
    return None


def _parse_browser(ua: str | None) -> str | None:
    if not ua:
        return None
    ua_lower = ua.lower()

    if "stroapp" in ua_lower:
        return None

    m = re.search(r"edg(?:e)?/(\d+)", ua_lower)
    if m:
        return f"Edge {m.group(1)}"

    m = re.search(r"chrome(?:/| )(\d+)", ua_lower)
    if m and "chromium" not in ua_lower:
        return f"Chrome {m.group(1)}"

    m = re.search(r"firefox(?:/| )(\d+)", ua_lower)
    if m:
        return f"Firefox {m.group(1)}"

    m = re.search(r"safari(?:/| )(\d+)", ua_lower)
    if m and "chrome" not in ua_lower:
        return f"Safari {m.group(1)}"

    m = re.search(r"chromium(?:/| )(\d+)", ua_lower)
    if m:
        return f"Chromium {m.group(1)}"
    return None


def _get_current_session_id(request: Request) -> str | None:
    auth = request.headers.get("authorization", "")
    if auth.startswith("Bearer "):
        payload = verify_token(auth[7:], expected_type="access")
        if payload:
            return payload.get("sid")
    return None


@router.get("")
async def list_sessions(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    sessions = SessionManager.get_user_sessions(db, current_user.id)
    current_session_id = _get_current_session_id(request)
    return success_response([
        {
            "id": s.id,
            "ip": s.ip_address,
            "ip_address": s.ip_address,
            "user_agent": s.user_agent,
            "device": _parse_device(s.user_agent),
            "os": _parse_os(s.user_agent),
            "browser": _parse_browser(s.user_agent),
            "city": s.city,
            "country": s.country,
            "is_current": s.id == current_session_id,
            "is_active": s.is_active,
            "created_at": s.created_at.isoformat() if s.created_at else None,
            "last_used_at": s.created_at.isoformat() if s.created_at else None,
            "expires_at": s.expires_at.isoformat() if s.expires_at else None,
        }
        for s in sessions
    ], request_id=getattr(request.state, "request_id", ""))


@router.post("/{session_id}/revoke")
async def revoke_session(
    session_id: str,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = db.query(UserSession).filter(
        UserSession.id == session_id,
        UserSession.user_id == current_user.id,
    ).first()
    if not session:
        raise AppException("NOT_FOUND", "الجلسة غير موجودة", 404)
    SessionManager.invalidate_session(db, session.refresh_token)
    AuditService.log(db, current_user.id, "session.revoke", "session", session_id, {},
                   request.client.host if request.client else "",
                   getattr(request.state, "request_id", ""))
    return success_response({"message": "تم إلغاء الجلسة"},
                          request_id=getattr(request.state, "request_id", ""))


@router.post("/revoke-all")
async def revoke_all_sessions(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Blacklist current access token so user is logged out immediately
    auth_header = request.headers.get("Authorization", "")
    if auth_header.startswith("Bearer "):
        payload = verify_token(auth_header[7:], expected_type="access")
        if payload and payload.get("jti"):
            BlacklistService.blacklist_token(
                db, payload["jti"], "access", current_user.id, "revoke_all"
            )
    SessionManager.invalidate_all_sessions(db, current_user.id)
    AuditService.log(db, current_user.id, "session.revoke_all", "user", current_user.id, {},
                   request.client.host if request.client else "",
                   getattr(request.state, "request_id", ""))
    return success_response({"message": "تم إلغاء جميع الجلسات"},
                          request_id=getattr(request.state, "request_id", ""))
