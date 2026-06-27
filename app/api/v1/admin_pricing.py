from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import PricingTemplate, User
from app.services.audit_service import AuditService
from app.services.pricing_engine_service import PricingEngineService

router = APIRouter(prefix="/admin/pricing", tags=["Admin Pricing"])


class TierData(BaseModel):
    tier_name: str
    monthly_price: float = 0.0
    included_quota_usd: float = 0.0
    overage_rate: float = 0.0
    features: list = []


class CreateTemplate(BaseModel):
    name: str
    description: Optional[str] = None
    markup_multiplier: float = 1.15
    discount_percentage: float = 0.0
    region: Optional[str] = None
    currency: str = "USD"
    is_promo: bool = False
    promo_code: Optional[str] = None
    promo_max_uses: Optional[int] = None
    promo_expires_at: Optional[datetime] = None
    effective_date: Optional[datetime] = None
    tiers: list[TierData] = []


class UpdateTemplate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    markup_multiplier: Optional[float] = None
    discount_percentage: Optional[float] = None
    region: Optional[str] = None
    currency: Optional[str] = None
    is_promo: Optional[bool] = None
    promo_code: Optional[str] = None
    promo_max_uses: Optional[int] = None
    promo_expires_at: Optional[datetime] = None
    effective_date: Optional[datetime] = None
    max_assignments: Optional[int] = None
    tiers: Optional[list[TierData]] = None


class AssignUser(BaseModel):
    user_id: str
    template_id: str
    expires_at: Optional[datetime] = None


class CreatePromotion(BaseModel):
    service: str
    discount_percentage: float
    original_price: float
    promotional_price: float
    starts_at: datetime
    expires_at: datetime


@router.get("/templates")
async def list_templates(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    is_active: Optional[bool] = None,
    is_promo: Optional[bool] = None,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    templates, total = PricingEngineService.get_templates(db, page, per_page, is_active, is_promo)
    return success_response({"items": templates, "total": total, "page": page, "per_page": per_page})


@router.get("/templates/{template_id}")
async def get_template(
    template_id: str,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    template = PricingEngineService.get_template(db, template_id)
    if not template:
        raise AppException(code="not_found", message="قالب التسعير غير موجود", status_code=404)
    return success_response(template)


@router.post("/templates")
async def create_template(
    body: CreateTemplate,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = PricingEngineService.create_template(db, body.model_dump(), admin_user.id)
    return success_response(result)


@router.put("/templates/{template_id}")
async def update_template(
    template_id: str,
    body: UpdateTemplate,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = PricingEngineService.update_template(db, template_id, body.model_dump(exclude_none=True), admin_user.id)
    if not result:
        raise AppException(code="not_found", message="قالب التسعير غير موجود", status_code=404)
    return success_response(result)


@router.delete("/templates/{template_id}")
async def delete_template(
    template_id: str,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = PricingEngineService.delete_template(db, template_id, admin_user.id)
    if not result:
        raise AppException(code="not_found", message="قالب التسعير غير موجود", status_code=404)
    return success_response({"deleted": True})


@router.post("/templates/{template_id}/activate")
async def activate_template(
    template_id: str,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = PricingEngineService.activate_template(db, template_id)
    if not result:
        raise AppException(code="not_found", message="قالب التسعير غير موجود", status_code=404)
    return success_response(result)


@router.get("/templates/{template_id}/history")
async def get_template_history(
    template_id: str,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = PricingEngineService.get_history(db, template_id, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.post("/assignments")
async def assign_user(
    body: AssignUser,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = PricingEngineService.assign_user(db, body.user_id, body.template_id, body.expires_at)
    return success_response(result)


@router.delete("/assignments/{user_id}")
async def unassign_user(
    user_id: str,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = PricingEngineService.unassign_user(db, user_id)
    if not result:
        raise AppException(code="not_found", message="لم يتم العثور على تعيين لهذا المستخدم", status_code=404)
    return success_response({"deleted": True})


@router.get("/assignments")
async def list_assignments(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = PricingEngineService.get_user_assignments(db, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/promotions")
async def list_promotions(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = PricingEngineService.get_active_promotions(db, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.post("/promotions")
async def create_promotion(
    body: CreatePromotion,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = PricingEngineService.create_promotion(db, body.model_dump())

    AuditService.log(db, admin_user.id, "promotion.create", "promotion", result.get("id", ""),
                    {"service": body.service, "discount_percentage": body.discount_percentage})
    return success_response(result)


@router.post("/promotions/{promotion_id}/toggle")
async def toggle_promotion(
    promotion_id: str,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = PricingEngineService.toggle_promotion(db, promotion_id)
    if not result:
        raise AppException(code="not_found", message="الترقية غير موجودة", status_code=404)
    return success_response(result)


@router.get("/promo-codes/{code}/usage")
async def get_promo_code_usage(
    code: str,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):

    t = db.query(PricingTemplate).filter(PricingTemplate.promo_code == code).first()
    if not t:
        raise AppException(code="not_found", message="الرمز الترويجي غير موجود", status_code=404)
    template_id = t.id
    items, total = PricingEngineService.get_promo_usage(db, template_id, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})
