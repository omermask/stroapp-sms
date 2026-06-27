from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import User
from app.services.audit_service import AuditService
from app.services.mfa_service import MFAService


class MfaTokenRequest(BaseModel):
    token: str

router = APIRouter(prefix="/user/mfa", tags=["MFA"])


@router.post("/setup")
async def mfa_setup(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.mfa_enabled:
        raise AppException("MFA_ALREADY_ENABLED", "التحقق بخطوتين مفعل بالفعل", 400)
    result = MFAService.setup(current_user.email or current_user.display_name or "user")
    current_user.mfa_secret = result["secret"]
    db.commit()
    AuditService.log(db, current_user.id, "mfa.setup", "user", current_user.id, {},
                   request.client.host if request and request.client else "",
                   getattr(request.state, "request_id", "") if request else "")
    return success_response({
        "secret": result["secret"],
        "qr_code": result["qr_code"],
    }, request_id=getattr(request.state, "request_id", ""))


@router.post("/verify")
async def mfa_verify(
    body: MfaTokenRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not current_user.mfa_secret:
        raise AppException("MFA_NOT_SETUP", "يرجى إعداد التحقق بخطوتين أولاً", 400)
    MFAService.verify_and_enable(current_user.mfa_secret, body.token)
    current_user.mfa_enabled = True
    db.commit()
    AuditService.log(db, current_user.id, "mfa.enable", "user", current_user.id, {},
                   request.client.host if request and request.client else "",
                   getattr(request.state, "request_id", "") if request else "")
    return success_response({"message": "تم تفعيل التحقق بخطوتين بنجاح"},
                          request_id=getattr(request.state, "request_id", "") if request else "")


@router.post("/disable")
async def mfa_disable(
    body: MfaTokenRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not current_user.mfa_enabled or not current_user.mfa_secret:
        raise AppException("MFA_NOT_ENABLED", "التحقق بخطوتين غير مفعل", 400)
    MFAService.verify_and_disable(current_user.mfa_secret, body.token)
    current_user.mfa_enabled = False
    current_user.mfa_secret = None
    db.commit()
    AuditService.log(db, current_user.id, "mfa.disable", "user", current_user.id, {},
                   request.client.host if request and request.client else "",
                   getattr(request.state, "request_id", "") if request else "")
    return success_response({"message": "تم إلغاء التحقق بخطوتين"},
                          request_id=getattr(request.state, "request_id", "") if request else "")


@router.get("/status")
async def mfa_status(
    request: Request,
    current_user: User = Depends(get_current_user),
):
    return success_response({
        "enabled": current_user.mfa_enabled,
    }, request_id=getattr(request.state, "request_id", ""))
