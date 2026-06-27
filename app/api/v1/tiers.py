from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import User
from app.services.audit_service import AuditService
from app.services.tier_service import TierService


class UpgradeTierRequest(BaseModel):
    tier: str

router = APIRouter(prefix="/user/tiers", tags=["Tiers"])
TIER_HIERARCHY = {"freemium": 0, "payg": 1, "pro": 2, "custom": 3}


@router.get("")
async def list_tiers(
    request: Request,
    db: Session = Depends(get_db),
):
    return success_response(TierService.all_tiers(db), request_id=getattr(request.state, "request_id", ""))


@router.get("/current")
async def current_tier(
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    config = TierService.get_user_tier_config(db, current_user)
    return success_response({
        "tier": current_user.tier,
        "config": config,
        "expires_at": current_user.tier_expires_at.isoformat() if current_user.tier_expires_at else None,
    }, request_id=getattr(request.state, "request_id", ""))


@router.post("/upgrade")
async def upgrade_tier(
    body: UpgradeTierRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    valid_tiers = ["freemium", "payg", "pro", "custom"]
    if body.tier not in valid_tiers:
        raise AppException("INVALID_TIER", "الرتبة غير صالحة", 400)
    current_level = TIER_HIERARCHY.get(current_user.tier, 0)
    target_level = TIER_HIERARCHY.get(body.tier, 0)
    if target_level <= current_level:
        raise AppException("INVALID_TIER", "لا يمكن الترقية إلى رتبة أقل أو مساوية لرتبتك الحالية", 400)
    target = TierService.DEFAULTS.get(body.tier)
    if not target:
        raise AppException("TIER_NOT_FOUND", "الرتبة غير موجودة", 404)
    cost = target.get("price_monthly", 0)
    if current_user.coins < cost:
        raise AppException("INSUFFICIENT_COINS", "رصيد الكوين غير كافٍ للترقية", 402)
    current_user.coins -= cost
    old_tier = current_user.tier
    current_user.tier = body.tier
    current_user.tier_expires_at = None
    db.commit()
    AuditService.log(db, current_user.id, "tier.upgrade", "user", current_user.id,
                   {"from": old_tier, "to": body.tier, "cost": cost},
                   request.client.host if request and request.client else "",
                   getattr(request.state, "request_id", "") if request else "")
    return success_response({
        "message": f"تم الترقية إلى رتبة {body.tier}",
        "tier": body.tier,
        "coins_remaining": current_user.coins,
    }, request_id=getattr(request.state, "request_id", "") if request else "")
