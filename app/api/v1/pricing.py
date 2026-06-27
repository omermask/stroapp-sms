from typing import Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import User
from app.services.pricing_engine_service import PricingEngineService

router = APIRouter(prefix="/pricing", tags=["Pricing"])


class ValidatePromoCode(BaseModel):
    code: str


class ApplyPromoCode(BaseModel):
    code: str
    order_id: Optional[str] = None


@router.get("/my")
async def get_my_pricing(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = PricingEngineService.get_pricing_for_user(db, current_user.id)
    return success_response(result)


@router.post("/validate-promo")
async def validate_promo_code(
    body: ValidatePromoCode,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not body.code:
        raise AppException(code="validation_error", message="رمز الترويج مطلوب")
    result = PricingEngineService.validate_promo_code(db, body.code, current_user.id)
    return success_response(result)


@router.post("/apply-promo")
async def apply_promo_code(
    body: ApplyPromoCode,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not body.code:
        raise AppException(code="validation_error", message="رمز الترويج مطلوب")
    result = PricingEngineService.apply_promo_code(db, body.code, current_user.id, body.order_id)
    return success_response(result)
