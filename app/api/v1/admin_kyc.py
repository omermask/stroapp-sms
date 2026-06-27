from typing import Optional

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import User
from app.services.kyc_service import KYCService

router = APIRouter(prefix="/admin/kyc", tags=["Admin KYC"])


class VerifyProfile(BaseModel):
    level: str = "basic"


class RejectProfile(BaseModel):
    reason: str = ""


class SuspendProfile(BaseModel):
    reason: str = ""


class UpdateKYCSetting(BaseModel):
    setting_key: str
    setting_value: str


class UpdateKYCLimit(BaseModel):
    daily_limit_coins: Optional[float] = None
    monthly_limit_coins: Optional[float] = None
    annual_limit_coins: Optional[float] = None
    max_single_transaction: Optional[float] = None
    allowed_services: Optional[list] = None
    country_restrictions: Optional[list] = None


@router.get("/pending")
async def list_pending(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = KYCService.get_pending(db, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/all")
async def list_all(
    status: Optional[str] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = KYCService.get_all(db, status, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/{profile_id}")
async def get_profile(
    profile_id: str,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = KYCService.get_profile_by_id(db, profile_id)
    if not result:
        raise AppException(code="not_found", message="ملف KYC غير موجود", status_code=404)
    return success_response(result)


@router.post("/{profile_id}/verify")
async def verify_profile(
    profile_id: str,
    body: VerifyProfile,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = KYCService.verify_profile(db, profile_id, admin_user.id, body.level)
    if not result:
        raise AppException(code="not_found", message="ملف KYC غير موجود", status_code=404)
    return success_response(result)


@router.post("/{profile_id}/reject")
async def reject_profile(
    profile_id: str,
    body: RejectProfile,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = KYCService.reject_profile(db, profile_id, admin_user.id, body.reason)
    if not result:
        raise AppException(code="not_found", message="ملف KYC غير موجود", status_code=404)
    return success_response(result)


@router.post("/{profile_id}/suspend")
async def suspend_profile(
    profile_id: str,
    body: SuspendProfile,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = KYCService.suspend_profile(db, profile_id, admin_user.id, body.reason)
    if not result:
        raise AppException(code="not_found", message="ملف KYC غير موجود", status_code=404)
    return success_response(result)


@router.post("/{profile_id}/aml-screen")
async def run_aml_screening(
    profile_id: str,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = KYCService.run_aml_screening(db, profile_id)
    return success_response(result)


@router.get("/{profile_id}/documents")
async def get_documents(
    profile_id: str,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = KYCService.get_documents(db, profile_id)
    return success_response(result)


@router.get("/{profile_id}/audit")
async def get_audit_logs(
    profile_id: str,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = KYCService.get_audit_logs(db, profile_id, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/stats")
async def get_stats(
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = KYCService.get_stats(db)
    return success_response(result)


@router.get("/settings")
async def get_settings(
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = KYCService.get_settings(db)
    return success_response(result)


@router.put("/settings")
async def update_setting(
    body: UpdateKYCSetting,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = KYCService.update_setting(db, body.setting_key, body.setting_value)
    return success_response(result)


@router.get("/limits")
async def get_limits(
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = KYCService.get_all_limits(db)
    return success_response(result)


@router.put("/limits/{level}")
async def update_limit(
    level: str,
    body: UpdateKYCLimit,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = KYCService.update_limit(db, level, body.model_dump(exclude_none=True))
    return success_response(result)
