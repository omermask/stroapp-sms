from typing import Optional

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import User
from app.services.affiliate_service import AffiliateService

router = APIRouter(prefix="/affiliate", tags=["Affiliate"])


class AffiliateApply(BaseModel):
    program_type: str = "standard"
    message: Optional[str] = None


class RequestPayout(BaseModel):
    amount: float
    payment_method: str
    payment_details: Optional[dict] = None


@router.post("/apply")
async def apply(
    body: AffiliateApply,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = AffiliateService.apply(db, current_user.id, body.program_type, body.message)
    return success_response(result)


@router.get("/application")
async def get_application(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = AffiliateService.get_user_application(db, current_user.id)
    if not result:
        raise AppException(code="not_found", message="لم يتم تقديم طلب بعد", status_code=404)
    return success_response(result)


@router.get("/commissions")
async def list_commissions(
    status: Optional[str] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    items, total = AffiliateService.get_commissions(db, current_user.id, status, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/summary")
async def get_summary(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = AffiliateService.get_commission_summary(db, current_user.id)
    return success_response(result)


@router.post("/payouts")
async def request_payout(
    body: RequestPayout,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = AffiliateService.create_payout(
        db, current_user.id, body.amount, body.payment_method, body.payment_details,
    )
    if "error" in result:
        raise AppException(code="insufficient_funds", message=result["error"])
    return success_response(result)


@router.get("/payouts")
async def list_payouts(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    items, total = AffiliateService.get_payouts(db, current_user.id, None, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/revenue-share")
async def get_revenue_share(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    items, total = AffiliateService.get_revenue_share(db, current_user.id, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/tiers")
async def list_tiers(
    db: Session = Depends(get_db),
):
    tiers = AffiliateService.list_tiers(db)
    return success_response(tiers)
