from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import User
from app.services.audit_service import AuditService


class OnboardingStepRequest(BaseModel):
    step: int

router = APIRouter(prefix="/user/onboarding", tags=["Onboarding"])


@router.get("")
async def get_onboarding_status(
    request: Request,
    current_user: User = Depends(get_current_user),
):
    return success_response({
        "completed": current_user.onboarding_completed,
        "onboarding_step": current_user.onboarding_step,
    }, request_id=getattr(request.state, "request_id", ""))


@router.post("/step")
async def update_onboarding_step(
    body: OnboardingStepRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if body.step < 0 or body.step > 10:
        raise AppException("VALIDATION_ERROR", "خطوة الإعداد غير صالحة", 400)
    current_user.onboarding_step = body.step
    if body.step >= 10:
        current_user.onboarding_completed = True
    db.commit()
    return success_response({
        "message": "تم تحديث خطوة الإعداد",
        "onboarding_step": current_user.onboarding_step,
        "completed": current_user.onboarding_completed,
    }, request_id=getattr(request.state, "request_id", "") if request else "")


@router.post("/complete")
async def complete_onboarding(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    current_user.onboarding_completed = True
    current_user.onboarding_step = 10
    db.commit()
    AuditService.log(db, current_user.id, "onboarding.complete", "user", current_user.id, {},
                   request.client.host if request and request.client else "",
                   getattr(request.state, "request_id", "") if request else "")
    return success_response({"message": "تم إكمال الإعداد"},
                          request_id=getattr(request.state, "request_id", ""))


@router.post("/skip")
async def skip_onboarding(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    current_user.onboarding_completed = True
    current_user.onboarding_step = 0
    db.commit()
    AuditService.log(db, current_user.id, "onboarding.skip", "user", current_user.id, {},
                   request.client.host if request and request.client else "",
                   getattr(request.state, "request_id", "") if request else "")
    return success_response({"message": "تم تخطي الإعداد"},
                          request_id=getattr(request.state, "request_id", ""))
