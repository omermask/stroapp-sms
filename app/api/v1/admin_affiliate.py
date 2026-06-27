from typing import Optional

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import User
from app.services.affiliate_service import AffiliateService
from app.services.audit_service import AuditService

router = APIRouter(prefix="/admin/affiliate", tags=["Admin Affiliate"])


class ReviewApplication(BaseModel):
    status: str
    rejection_reason: Optional[str] = None


class CreateTier(BaseModel):
    name: str
    base_rate: float
    bonus_rate: float = 0.0
    min_volume_usd: float = 0.0
    min_referrals: int = 0
    requirements: dict = {}


class ProcessPayout(BaseModel):
    notes: Optional[str] = None
    status: str = "approved"


@router.get("/applications")
async def list_applications(
    status: Optional[str] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = AffiliateService.list_applications(db, status, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.post("/applications/{application_id}/review")
async def review_application(
    application_id: str,
    body: ReviewApplication,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    if body.status not in ("approved", "rejected"):
        raise AppException(code="validation_error", message="يجب أن تكون الحالة approved أو rejected")
    result = AffiliateService.review_application(db, application_id, body.status, admin_user.id, body.rejection_reason)
    if not result:
        raise AppException(code="not_found", message="الطلب غير موجود", status_code=404)

    AuditService.log(db, admin_user.id, "application.review", "affiliate_application", application_id,
                    {"status": body.status})
    return success_response(result)


@router.get("/commissions")
async def list_commissions(
    affiliate_id: Optional[str] = None,
    status: Optional[str] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    if not affiliate_id:
        raise AppException(code="validation_error", message="affiliate_id مطلوب")
    items, total = AffiliateService.get_commissions(db, affiliate_id, status, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.post("/commissions/{commission_id}/approve")
async def approve_commission(
    commission_id: str,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = AffiliateService.approve_commission(db, commission_id)
    if not result:
        raise AppException(code="not_found", message="العمولة غير موجودة", status_code=404)

    AuditService.log(db, admin_user.id, "commission.approve", "commission", commission_id, {})
    return success_response(result)


@router.get("/tiers")
async def list_tiers(
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    tiers = AffiliateService.list_tiers(db)
    return success_response(tiers)


@router.post("/tiers")
async def create_tier(
    body: CreateTier,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = AffiliateService.create_tier(db, body.model_dump())

    AuditService.log(db, admin_user.id, "tier.create", "commission_tier", result.get("id", ""),
                    {"name": body.name, "base_rate": body.base_rate})
    return success_response(result)


@router.get("/payouts")
async def list_payouts(
    affiliate_id: Optional[str] = None,
    status: Optional[str] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = AffiliateService.get_payouts(db, affiliate_id, status, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.post("/payouts/{payout_id}/process")
async def process_payout(
    payout_id: str,
    body: ProcessPayout,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = AffiliateService.process_payout(db, payout_id, admin_user.id, body.notes, body.status)
    if not result:
        raise AppException(code="not_found", message="طلب الدفع غير موجود", status_code=404)

    AuditService.log(db, admin_user.id, "payout.process", "payout", payout_id,
                    {"status": body.status})
    return success_response(result)
