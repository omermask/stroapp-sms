import secrets
import string

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import Referral, ReferralCode, User, gen_uuid
from app.services.audit_service import AuditService

router = APIRouter(prefix="/user/referral", tags=["Referrals"])


class ClaimReferral(BaseModel):
    code: str


def generate_referral_code() -> str:
    return ''.join(secrets.choice(string.ascii_uppercase + string.digits) for _ in range(8))


@router.get("/code")
async def get_referral_code(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    code = db.query(ReferralCode).filter(
        ReferralCode.user_id == current_user.id,
    ).first()
    if not code:
        code = ReferralCode(
            id=gen_uuid(),
            user_id=current_user.id,
            code=generate_referral_code(),
        )
        db.add(code)
        db.commit()
    return success_response({
        "code": code.code,
        "referral_url": f"https://stroapp.com/register?ref={code.code}",
        "deep_link_url": f"stroapp://register?ref={code.code}",
    }, request_id=getattr(request.state, "request_id", ""))


@router.post("/claim")
async def claim_referral(
    body: ClaimReferral,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    code_record = db.query(ReferralCode).filter(
        ReferralCode.code == body.code,
    ).with_for_update().first()
    if not code_record:
        raise AppException("INVALID_CODE", "كود الإحالة غير صالح", 404)
    if code_record.user_id == current_user.id:
        raise AppException("SELF_REFERRAL", "لا يمكنك استخدام كودك الخاص", 400)
    existing = db.query(Referral).filter(
        Referral.referred_id == current_user.id,
    ).first()
    if existing:
        raise AppException("ALREADY_REFERRED", "لقد تمت إحالتك مسبقاً", 409)
    referral = Referral(
        id=gen_uuid(),
        referrer_id=code_record.user_id,
        referred_id=current_user.id,
        code=body.code,
        status="pending",
    )
    db.add(referral)
    db.commit()
    AuditService.log(db, current_user.id, "referral.create", "referral", referral.id,
                   {"referrer_id": code_record.user_id, "code": body.code},
                   request.client.host if request.client else "",
                   getattr(request.state, "request_id", ""))
    return success_response({"status": "pending"}, request_id=getattr(request.state, "request_id", ""))


@router.get("/earnings")
async def referral_earnings(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    referrals = db.query(Referral).filter(
        Referral.referrer_id == current_user.id,
    ).order_by(Referral.created_at.desc()).all()
    total_reward = sum(r.reward_coins for r in referrals)
    return success_response({
        "total_referrals": len(referrals),
        "total_reward_coins": total_reward,
        "referrals": [
            {
                "id": r.id,
                "referred_id": r.referred_id,
                "reward_coins": r.reward_coins,
                "status": r.status,
                "created_at": r.created_at.isoformat() if r.created_at else None,
            }
            for r in referrals
        ],
    }, request_id=getattr(request.state, "request_id", ""))
