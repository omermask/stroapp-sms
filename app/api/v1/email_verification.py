import secrets
from datetime import datetime, timezone, timedelta

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session


class VerifyEmailRequest(BaseModel):
    token: str

from app.core.config import get_settings
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.response import success_response
from app.core.logging import get_logger
from app.domain.models import User
from app.infrastructure.cache.cache_manager import cache
from app.services.audit_service import AuditService

logger = get_logger(__name__)

router = APIRouter(prefix="/user/email", tags=["Email Verification"])


async def _check_verify_rate(ip: str) -> bool:
    now = datetime.now(timezone.utc).timestamp()
    key = f"verify_rate:{ip}"
    count = await cache.get(key) or 0
    if count >= 10:
        return False
    await cache.set(key, count + 1, ttl=300)
    return True


@router.post("/send-verification")
async def send_verification(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.email_verified:
        raise AppException("ALREADY_VERIFIED", "البريد الإلكتروني موثق بالفعل", 400)
    if not current_user.email:
        raise AppException("NO_EMAIL", "لا يوجد بريد إلكتروني مسجل", 400)

    current_user.email_verification_token = secrets.token_urlsafe(32)
    db.commit()

    ip = request.client.host if request.client else ""
    AuditService.log(db, current_user.id, "email.send_verification", "user",
                    current_user.id, {}, ip,
                    getattr(request.state, "request_id", ""))

    return success_response(
        {"message": "تم إرسال رابط التوثيق إلى بريدك الإلكتروني"},
        request_id=getattr(request.state, "request_id", ""),
    )


@router.post("/verify")
async def verify_email(
    request: Request,
    body: VerifyEmailRequest,
    db: Session = Depends(get_db),
):
    ip = request.client.host if request.client else "unknown"
    if not await _check_verify_rate(ip):
        raise AppException("RATE_LIMITED", "طلبات كثيرة جداً، الرجاء المحاولة لاحقاً", 429)

    user = db.query(User).filter(
        User.email_verification_token == body.token,
    ).first()
    if not user:
        raise AppException("INVALID_TOKEN", "الرابط غير صالح أو منتهي الصلاحية", 400)

    user.email_verified = True
    user.email_verification_token = None
    db.commit()

    AuditService.log(db, user.id, "email.verified", "user", user.id,
                    {}, ip, getattr(request.state, "request_id", ""))

    return success_response(
        {"message": "تم توثيق البريد الإلكتروني بنجاح"},
        request_id=getattr(request.state, "request_id", ""),
    )
