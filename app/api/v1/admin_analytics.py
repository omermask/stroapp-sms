from typing import Optional

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import User
from app.services.analytics_service import AnalyticsService

router = APIRouter(prefix="/admin/analytics", tags=["Admin Analytics"])


class SetMonthlyTarget(BaseModel):
    month: str
    target_new_users: Optional[int] = None
    target_revenue: Optional[float] = None
    target_verifications: Optional[int] = None
    target_success_rate: Optional[float] = None
    notes: Optional[str] = None


@router.get("/dashboard")
async def get_dashboard(
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = AnalyticsService.get_dashboard(db)
    return success_response(result)


@router.post("/snapshot/compute")
async def compute_snapshot(
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = AnalyticsService.compute_daily_snapshot(db)
    return success_response(result)


@router.get("/verifications")
async def get_verification_stats(
    days: int = Query(30, ge=1, le=365),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = AnalyticsService.get_verification_stats(db, days)
    return success_response(result)


@router.get("/carriers")
async def get_carrier_analytics(
    days: int = Query(30, ge=1, le=365),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = AnalyticsService.get_carrier_analytics(db, days)
    return success_response(result)


@router.get("/purchase-outcomes")
async def get_purchase_outcomes(
    days: int = Query(7, ge=1, le=90),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = AnalyticsService.get_purchase_outcomes(db, page, per_page, days)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/monthly-targets")
async def get_monthly_targets(
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = AnalyticsService.get_monthly_targets(db)
    return success_response(result)


@router.post("/monthly-targets")
async def set_monthly_target(
    body: SetMonthlyTarget,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = AnalyticsService.set_monthly_target(db, body.model_dump())
    return success_response(result)


@router.get("/users/{user_id}")
async def get_user_snapshot(
    user_id: str,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = AnalyticsService.get_user_snapshot(db, user_id)
    return success_response(result)
