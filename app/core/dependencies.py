import hashlib
from datetime import datetime, timezone
from typing import Optional

import jwt
from fastapi import Depends
from fastapi.requests import Request
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.database import get_db
from app.core.exceptions import AppException
from app.core.security import get_user_id_from_token, verify_token
from app.domain.models import APIKey, User, UserSession
from app.services.blacklist_service import BlacklistService
from app.services.mfa_service import MFAService


def _get_jti_from_token(token: str) -> Optional[str]:
    try:
        payload = jwt.decode(token, get_settings().jwt_secret_key, algorithms=[get_settings().jwt_algorithm])
        return payload.get("jti")
    except (jwt.ExpiredSignatureError, jwt.InvalidTokenError, Exception):
        return None


def _resolve_user_id(request: Request, db: Session) -> Optional[str]:
    auth = request.headers.get("authorization", "")
    if auth.startswith("Bearer "):
        token = auth[7:]
        if token.startswith("nsk_"):
            key_hash = hashlib.sha256(token.encode()).hexdigest()
            # H-4 FIX: إضافة فحص expires_at لمنع استخدام مفاتيح API منتهية الصلاحية
            api_key = db.query(APIKey).filter(
                APIKey.key_hash == key_hash,
                APIKey.is_active == True,
            ).first()
            if api_key:
                # التحقق من انتهاء الصلاحية (إذا كان الحقل محدداً)
                if api_key.expires_at and api_key.expires_at <= datetime.now(timezone.utc):
                    return None  # مفتاح منتهي الصلاحية — يُعامل كغير صالح
                api_key.last_used_at = datetime.now(timezone.utc)
                db.commit()
                return api_key.user_id
        return get_user_id_from_token(token)
    cookie = request.cookies.get("admin_token")
    if cookie:
        return get_user_id_from_token(cookie)
    return None


async def get_current_user(
    request: Request,
    db: Session = Depends(get_db),
) -> User:
    auth = request.headers.get("authorization", "")
    if auth.startswith("Bearer "):
        token = auth[7:]
        if not token.startswith("nsk_"):
            payload = verify_token(token, expected_type="access")
            if not payload:
                raise AppException("UNAUTHORIZED", "يرجى تسجيل الدخول", status_code=401)
            jti = payload.get("jti")
            if jti and BlacklistService.is_token_blacklisted(db, jti):
                raise AppException("UNAUTHORIZED", "الجلسة منتهية، الرجاء تسجيل الدخول مرة أخرى", status_code=401)
            # If token has a session ID, check the session is still active
            sid = payload.get("sid")
            if sid:
                session = db.query(UserSession).filter(UserSession.id == sid).first()
                if not session or not session.is_active or session.expires_at <= datetime.now(timezone.utc):
                    raise AppException("UNAUTHORIZED", "انتهت صلاحية الجلسة، الرجاء تسجيل الدخول مرة أخرى", status_code=401)

    user_id = _resolve_user_id(request, db)
    if not user_id:
        raise AppException("UNAUTHORIZED", "يرجى تسجيل الدخول", status_code=401)
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise AppException("UNAUTHORIZED", "المستخدم غير موجود", status_code=401)
    if user.is_banned:
        raise AppException("FORBIDDEN", "الحساب محظور", status_code=403)
    return user


async def get_current_admin(
    current_user: User = Depends(get_current_user),
) -> User:
    if not current_user.is_admin:
        raise AppException("FORBIDDEN", "صلاحية أدمن مطلوبة", status_code=403)
    return current_user


async def require_mfa(
    request: Request,
    current_user: User = Depends(get_current_user),
) -> User:
    if current_user.mfa_enabled:
        mfa_token = request.headers.get("x-mfa-token", "")
        if not mfa_token or not MFAService.verify_token(current_user.mfa_secret or "", mfa_token):
            raise AppException("MFA_REQUIRED", "يرجى إكمال التحقق بخطوتين", 403)
    return current_user
