from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import User, SMSOrder, Transaction, PaymentLog, UserSession
from app.services.audit_service import AuditService

router = APIRouter(prefix="/admin/api/users", tags=["Admin User Management"])


def _get_ip(request: Request) -> str:
    if not request:
        return ""
    forwarded = request.headers.get("x-forwarded-for", "")
    return forwarded.split(",")[0].strip() if forwarded else (request.client.host if request.client else "")


@router.get("")
async def list_users(
    request: Request,
    page: int = Query(default=1, ge=1),
    per_page: int = Query(default=20, ge=1, le=100),
    search: str = Query(default=""),
    tier: str = Query(default=""),
    is_banned: bool = Query(default=None),
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    q = db.query(User)
    if search:
        term = f"%{search}%"
        q = q.filter(User.email.ilike(term) | User.display_name.ilike(term) | User.id.ilike(term))
    if tier:
        q = q.filter(User.tier == tier)
    if is_banned is not None:
        q = q.filter(User.is_banned == is_banned)

    total = q.count()
    users = q.order_by(User.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()

    return success_response({
        "users": [{
            "id": u.id, "email": u.email, "display_name": u.display_name,
            "coins": u.coins, "tier": u.tier, "is_admin": u.is_admin,
            "is_banned": u.is_banned, "is_active": u.is_active,
            "email_verified": u.email_verified,
            "mfa_enabled": u.mfa_enabled,
            "created_at": u.created_at.isoformat() if u.created_at else None,
            "last_login_at": u.last_login_at.isoformat() if u.last_login_at else None,
        } for u in users],
        "total": total,
        "page": page,
        "per_page": per_page,
    }, request_id=getattr(request.state, "request_id", ""))


@router.get("/{user_id}")
async def get_user_detail(
    request: Request,
    user_id: str,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise AppException("NOT_FOUND", "المستخدم غير موجود", 404)

    order_count = db.query(func.count(SMSOrder.id)).filter(SMSOrder.user_id == user_id).scalar() or 0
    txn_count = db.query(func.count(Transaction.id)).filter(Transaction.user_id == user_id).scalar() or 0
    payment_total = db.query(func.sum(PaymentLog.amount_usd)).filter(
        PaymentLog.user_id == user_id, PaymentLog.status == "completed",
    ).scalar() or 0
    session_count = db.query(func.count(UserSession.id)).filter(
        UserSession.user_id == user_id, UserSession.is_active == True,
    ).scalar() or 0

    return success_response({
        "id": user.id, "email": user.email, "display_name": user.display_name,
        "photo_url": user.photo_url, "coins": user.coins,
        "lifetime_coins": user.lifetime_coins, "tier": user.tier,
        "is_admin": user.is_admin, "is_banned": user.is_banned,
        "is_active": user.is_active, "email_verified": user.email_verified,
        "mfa_enabled": user.mfa_enabled, "onboarding_completed": user.onboarding_completed,
        "marketing_consent": user.marketing_consent,
        "analytics_consent": user.analytics_consent,
        "created_at": user.created_at.isoformat() if user.created_at else None,
        "last_login_at": user.last_login_at.isoformat() if user.last_login_at else None,
        "stats": {
            "order_count": order_count,
            "transaction_count": txn_count,
            "total_payments_usd": float(payment_total),
            "active_sessions": session_count,
        },
    }, request_id=getattr(request.state, "request_id", ""))


class BanUserRequest(BaseModel):
    reason: str = ""


class AdjustCoinsRequest(BaseModel):
    amount: int
    reason: str = ""


class ChangeTierRequest(BaseModel):
    tier: str


@router.post("/{user_id}/ban")
async def toggle_ban(
    request: Request,
    user_id: str,
    body: BanUserRequest,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise AppException("NOT_FOUND", "المستخدم غير موجود", 404)

    user.is_banned = not user.is_banned
    action = "user.ban" if user.is_banned else "user.unban"
    db.commit()

    AuditService.log(db, _admin.id, action, "user", user_id,
                    {"reason": body.reason, "target_user": user_id},
                    _get_ip(request), getattr(request.state, "request_id", ""))

    status_text = "تم حظر المستخدم" if user.is_banned else "تم فك الحظر عن المستخدم"
    return success_response({"message": status_text, "is_banned": user.is_banned},
                           request_id=getattr(request.state, "request_id", ""))


@router.post("/{user_id}/adjust-coins")
async def adjust_coins(
    request: Request,
    user_id: str,
    body: AdjustCoinsRequest,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise AppException("NOT_FOUND", "المستخدم غير موجود", 404)

    user.coins = max(0, user.coins + body.amount)
    db.commit()

    AuditService.log(db, _admin.id, "user.adjust_coins", "user", user_id,
                    {"amount": body.amount, "reason": body.reason, "new_balance": user.coins},
                    _get_ip(request), getattr(request.state, "request_id", ""))

    return success_response({
        "message": "تم تعديل الرصيد",
        "previous_coins": user.coins - body.amount,
        "new_coins": user.coins,
        "adjustment": body.amount,
    }, request_id=getattr(request.state, "request_id", ""))


@router.post("/{user_id}/change-tier")
async def change_tier(
    request: Request,
    user_id: str,
    body: ChangeTierRequest,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise AppException("NOT_FOUND", "المستخدم غير موجود", 404)

    old_tier = user.tier
    user.tier = body.tier
    db.commit()

    AuditService.log(db, _admin.id, "user.change_tier", "user", user_id,
                    {"old_tier": old_tier, "new_tier": body.tier},
                    _get_ip(request), getattr(request.state, "request_id", ""))

    return success_response({"message": "تم تغيير الشريحة", "old_tier": old_tier, "new_tier": body.tier},
                           request_id=getattr(request.state, "request_id", ""))


@router.post("/{user_id}/sessions/invalidate")
async def invalidate_sessions(
    request: Request,
    user_id: str,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    from app.core.session_manager import SessionManager
    SessionManager.invalidate_all_sessions(db, user_id)

    AuditService.log(db, _admin.id, "user.invalidate_sessions", "user", user_id,
                    {}, _get_ip(request), getattr(request.state, "request_id", ""))

    return success_response({"message": "تم إلغاء جميع الجلسات"},
                           request_id=getattr(request.state, "request_id", ""))


@router.delete("/{user_id}")
async def delete_user(
    request: Request,
    user_id: str,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    if user_id == _admin.id:
        raise AppException("VALIDATION_ERROR", "لا يمكن حذف حسابك", 400)

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise AppException("NOT_FOUND", "المستخدم غير موجود", 404)

    user.is_active = False
    user.is_banned = True
    user.email = f"deleted_{user_id}@deleted.com"
    db.commit()

    AuditService.log(db, _admin.id, "user.delete", "user", user_id,
                    {}, _get_ip(request), getattr(request.state, "request_id", ""))

    return success_response({"message": "تم حذف المستخدم"},
                           request_id=getattr(request.state, "request_id", ""))
