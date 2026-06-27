import os
from datetime import datetime
from typing import Optional, List

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.exceptions import AppException
from app.core.response import success_response
from app.core.security import create_access_token, verify_password
from app.domain.models import (
    AppSetting, AuditLog, EmailTemplate,
    SMSOrder, Service, Transaction, User, UserSession,
    Waitlist, gen_uuid,
)
from app.services.notification_prefs import NotificationPrefsService
from app.infrastructure.providers import ProviderRouter
from app.services.audit_service import AuditService
from app.core.feature_flags import FeatureFlags
from app.core.session_manager import SessionManager
from app.services.tier_service import TierService
from app.services.email_template_service import EmailTemplateService
from app.core.logging import get_logger

logger = get_logger(__name__)
router = APIRouter(prefix="/admin/api", tags=["Admin API"])
provider_router = ProviderRouter()


def _get_request_id(request: Request) -> str:
    return getattr(request.state, "request_id", "")


def _get_ip(request: Request) -> str:
    if not request:
        return ""
    forwarded = request.headers.get("x-forwarded-for", "")
    return forwarded.split(",")[0].strip() if forwarded else (request.client.host if request.client else "")


# ── Request Models ──

class LoginRequest(BaseModel):
    email: str
    password: str


class AdjustCoinsRequest(BaseModel):
    coins: int
    reason: str = ""


class SetTierRequest(BaseModel):
    tier: str


class CreateServiceRequest(BaseModel):
    name: str
    display_name: str = ""
    category: str = ""


class UpdateSettingsRequest(BaseModel):
    coins_per_usd: int
    default_markup: float
    temp_emails_per_month: int


class UpdateFeatureFlagRequest(BaseModel):
    enabled: bool
    strategy: str = "all_users"


class UpdateEmailTemplateRequest(BaseModel):
    subject: str
    html_content: str


class CreateAdminNotificationRequest(BaseModel):
    title: str
    message: str
    notification_type: str = "info"
    audience_filter: Optional[str] = None
    scheduled_at: Optional[datetime] = None


class UpdateNotificationDefaultRequest(BaseModel):
    push_enabled: Optional[bool] = None
    email_enabled: Optional[bool] = None
    sms_enabled: Optional[bool] = None
    telegram_enabled: Optional[bool] = None


class DeleteUserRequest(BaseModel):
    user_id: str


class BulkAdjustCoinsRequest(BaseModel):
    user_ids: List[str]
    amount: int
    reason: str = ""


# ── Auth ──

@router.post("/login")
async def admin_login(
    body: LoginRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.email == body.email).first()
    if not user or not user.is_admin:
        raise AppException("UNAUTHORIZED", "بيانات الدخول غير صحيحة", 401)
    if not verify_password(body.password, user.hashed_password or ""):
        raise AppException("UNAUTHORIZED", "بيانات الدخول غير صحيحة", 401)
    token = create_access_token(user.id)
    AuditService.log(db, user.id, "admin.login", ip_address=_get_ip(request), request_id=_get_request_id(request))
    return success_response({"access_token": token, "token_type": "bearer", "user": {"id": user.id, "email": user.email, "display_name": user.display_name}}, request_id=_get_request_id(request))


# ── Dashboard ──

@router.get("/dashboard")
async def admin_dashboard(
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    total_users = db.query(func.count(User.id)).scalar() or 0
    active_orders = db.query(func.count(SMSOrder.id)).filter(SMSOrder.status == "pending").scalar() or 0
    total_revenue = db.query(func.coalesce(func.sum(Transaction.amount), 0)).filter(Transaction.type == "deposit").scalar() or 0
    active_providers = sum(1 for p in provider_router.enabled_providers if p.enabled)
    analytics = {}
    try:
        from app.services.analytics_service import AnalyticsService as _AnalyticsService
        analytics = _AnalyticsService.get_dashboard(db) or {}
    except Exception:
        analytics = {}
    return success_response({
        "total_users": total_users,
        "active_orders": active_orders,
        "total_revenue": total_revenue,
        "active_providers": active_providers,
        "total_orders": db.query(func.count(SMSOrder.id)).scalar() or 0,
        "total_transactions": db.query(func.count(Transaction.id)).scalar() or 0,
        "analytics": analytics,
    }, request_id=_get_request_id(request))


# ── Stats ──

@router.get("/stats")
async def admin_stats(
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    return success_response({
        "total_users": db.query(func.count(User.id)).scalar() or 0,
        "active_orders": db.query(func.count(SMSOrder.id)).filter(SMSOrder.status == "pending").scalar() or 0,
        "total_revenue": db.query(func.coalesce(func.sum(Transaction.amount), 0)).filter(Transaction.type == "deposit").scalar() or 0,
        "active_providers": sum(1 for p in provider_router.enabled_providers if p.enabled),
        "total_orders": db.query(func.count(SMSOrder.id)).scalar() or 0,
        "total_transactions": db.query(func.count(Transaction.id)).scalar() or 0,
    }, request_id=_get_request_id(request))


# ── Users ──

@router.get("/users")
async def admin_list_users(
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
            "email_verified": u.email_verified, "mfa_enabled": u.mfa_enabled,
            "created_at": u.created_at.isoformat() if u.created_at else None,
            "last_login_at": u.last_login_at.isoformat() if u.last_login_at else None,
        } for u in users],
        "total": total,
        "page": page,
        "per_page": per_page,
    }, request_id=_get_request_id(request))


@router.get("/users/{user_id}")
async def admin_get_user(
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
    return success_response({
        "id": user.id, "email": user.email, "display_name": user.display_name,
        "photo_url": user.photo_url, "coins": user.coins,
        "lifetime_coins": user.lifetime_coins, "tier": user.tier,
        "is_admin": user.is_admin, "is_banned": user.is_banned,
        "is_active": user.is_active, "email_verified": user.email_verified,
        "mfa_enabled": user.mfa_enabled, "onboarding_completed": user.onboarding_completed,
        "created_at": user.created_at.isoformat() if user.created_at else None,
        "last_login_at": user.last_login_at.isoformat() if user.last_login_at else None,
        "stats": {"order_count": order_count, "transaction_count": txn_count},
    }, request_id=_get_request_id(request))


@router.post("/users/{user_id}/ban")
async def admin_ban_user(
    user_id: str,
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise AppException("NOT_FOUND", "المستخدم غير موجود", 404)
    user.is_banned = not user.is_banned
    db.commit()
    action = "user.ban" if user.is_banned else "user.unban"
    AuditService.log(db, _admin.id, action, "user", user.id, ip_address=_get_ip(request), request_id=_get_request_id(request))
    return success_response({"id": user.id, "is_banned": user.is_banned, "message": "تم حظر المستخدم" if user.is_banned else "تم فك الحظر"}, request_id=_get_request_id(request))


@router.post("/users/{user_id}/adjust")
async def admin_adjust_coins(
    user_id: str,
    body: AdjustCoinsRequest,
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise AppException("NOT_FOUND", "المستخدم غير موجود", 404)
    if user.is_banned:
        raise AppException("FORBIDDEN", "لا يمكن تعديل رصيد حساب محظور", 403)
    coins_before = user.coins
    user.coins += body.coins
    if body.coins > 0:
        user.lifetime_coins += body.coins
    description = body.reason or f"Admin adjustment: {body.coins:+d} coins by {_admin.id}"
    tx = Transaction(id=gen_uuid(), user_id=user.id, amount=body.coins, type="adjustment",
                     description=description, coins_before=coins_before, coins_after=user.coins)
    db.add(tx)
    db.commit()
    AuditService.log(db, _admin.id, "user.adjust_coins", "user", user.id,
                     {"coins_adjustment": body.coins, "reason": body.reason},
                     ip_address=_get_ip(request), request_id=_get_request_id(request))
    return success_response({"id": user.id, "coins": user.coins, "adjustment": body.coins, "reason": body.reason},
                           request_id=_get_request_id(request))


@router.post("/users/{user_id}/tier")
async def admin_set_user_tier(
    user_id: str,
    body: SetTierRequest,
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise AppException("NOT_FOUND", "المستخدم غير موجود", 404)
    valid_tiers = ["freemium", "payg", "pro", "custom"]
    if body.tier not in valid_tiers:
        raise AppException("INVALID_TIER", "الرتبة غير صالحة", 400)
    user.tier = body.tier
    db.commit()
    AuditService.log(db, _admin.id, "admin.set_tier", "user", user_id, {"tier": body.tier},
                     ip_address=_get_ip(request), request_id=_get_request_id(request))
    return success_response({"message": f"تم تغيير رتبة المستخدم إلى {body.tier}"}, request_id=_get_request_id(request))


@router.delete("/users/{user_id}")
async def admin_delete_user(
    user_id: str,
    request: Request,
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
    AuditService.log(db, _admin.id, "user.delete", "user", user_id, {},
                     ip_address=_get_ip(request), request_id=_get_request_id(request))
    return success_response({"message": "تم حذف المستخدم"}, request_id=_get_request_id(request))


@router.post("/users/{user_id}/sessions/invalidate")
async def admin_invalidate_sessions(
    user_id: str,
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    SessionManager.invalidate_all_sessions(db, user_id)
    AuditService.log(db, _admin.id, "user.invalidate_sessions", "user", user_id, {},
                     ip_address=_get_ip(request), request_id=_get_request_id(request))
    return success_response({"message": "تم إلغاء جميع الجلسات"}, request_id=_get_request_id(request))


# ── Providers ──

@router.get("/providers")
async def admin_list_providers(
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    providers = []
    for p in provider_router.all_providers:
        try:
            balance = await p.get_balance()
        except Exception:
            balance = None
        providers.append({
            "name": p.name, "display_name": getattr(p, "display_name", p.name),
            "enabled": p.enabled, "balance": balance,
        })
    return success_response(providers, request_id=_get_request_id(request))


@router.post("/providers/{name}/toggle")
async def admin_toggle_provider(
    name: str,
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    new_state = provider_router.toggle_provider(name)
    if new_state is None:
        raise AppException("NOT_FOUND", f"المزود '{name}' غير موجود", 404)
    AuditService.log(db, _admin.id, "provider.toggle", "provider", name, {"enabled": new_state},
                     ip_address=_get_ip(request), request_id=_get_request_id(request))
    return success_response({"name": name, "enabled": new_state}, request_id=_get_request_id(request))


# ── Services ──

@router.get("/services")
async def admin_list_services(
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    services = db.query(Service).order_by(Service.name).all()
    return success_response([{
        "id": s.id, "name": s.name, "display_name": s.display_name,
        "category": s.category, "is_active": s.is_active,
        "created_at": s.created_at.isoformat() if s.created_at else None,
    } for s in services], request_id=_get_request_id(request))


@router.post("/services/{name}/toggle")
async def admin_toggle_service(
    name: str,
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    service = db.query(Service).filter(Service.name == name).first()
    if not service:
        raise AppException("NOT_FOUND", f"الخدمة '{name}' غير موجودة", 404)
    service.is_active = not service.is_active
    db.commit()
    AuditService.log(db, _admin.id, "service.toggle", "service", service.id, {"is_active": service.is_active},
                     ip_address=_get_ip(request), request_id=_get_request_id(request))
    return success_response({"name": name, "is_active": service.is_active}, request_id=_get_request_id(request))


@router.post("/services")
async def admin_create_service(
    body: CreateServiceRequest,
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    existing = db.query(Service).filter(Service.name == body.name).first()
    if existing:
        existing.display_name = body.display_name or existing.display_name
        existing.category = body.category or existing.category
        db.commit()
        AuditService.log(db, _admin.id, "service.update", "service", existing.id, {"name": body.name},
                         ip_address=_get_ip(request), request_id=_get_request_id(request))
        return success_response({"id": existing.id, "name": body.name, "display_name": existing.display_name, "category": existing.category},
                               request_id=_get_request_id(request))
    service = Service(id=gen_uuid(), name=body.name, display_name=body.display_name or body.name, category=body.category)
    db.add(service)
    db.commit()
    AuditService.log(db, _admin.id, "service.create", "service", service.id, {"name": body.name},
                     ip_address=_get_ip(request), request_id=_get_request_id(request))
    return success_response({"id": service.id, "name": body.name, "display_name": service.display_name, "category": service.category},
                           request_id=_get_request_id(request))


# ── Settings ──

@router.get("/settings")
async def admin_get_settings(
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    s = get_settings()
    db_settings = db.query(AppSetting).all()
    overrides = {row.key: row.value for row in db_settings}
    return success_response({
        "coins_per_usd": int(overrides.get("coins_per_usd", s.coins_per_usd)),
        "default_markup": float(overrides.get("default_markup", s.default_markup)),
        "temp_emails_per_month": int(overrides.get("temp_emails_per_month", s.temp_emails_per_month)),
        "environment": s.environment,
        "jwt_expiration_hours": s.jwt_expiration_hours,
        "jwt_refresh_expiration_days": s.jwt_refresh_expiration_days,
        "third_party_configured": True,
    }, request_id=_get_request_id(request))


@router.post("/settings")
async def admin_update_settings(
    body: UpdateSettingsRequest,
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    try:
        for key, value in [("coins_per_usd", str(body.coins_per_usd)),
                           ("default_markup", str(body.default_markup)),
                           ("temp_emails_per_month", str(body.temp_emails_per_month))]:
            record = db.query(AppSetting).filter(AppSetting.key == key).first()
            if not record:
                record = AppSetting(id=gen_uuid(), key=key)
                db.add(record)
            record.value = value
        get_settings.cache_clear()
        logger.info(f"Admin {_admin.id} updated settings")
    except Exception as e:
        return success_response({"saved": False, "error": str(e)}, request_id=_get_request_id(request))
    AuditService.log(db, _admin.id, "settings.update", "settings", None,
                     {"coins_per_usd": body.coins_per_usd, "default_markup": body.default_markup, "temp_emails_per_month": body.temp_emails_per_month},
                     ip_address=_get_ip(request), request_id=_get_request_id(request))
    return success_response({"saved": True}, request_id=_get_request_id(request))


# ── Transactions ──

@router.get("/transactions")
async def admin_list_transactions(
    request: Request,
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=20, le=100),
    txn_type: str = Query(default="", alias="type"),
    user_id: str = Query(default=""),
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    query = db.query(Transaction)
    if txn_type:
        query = query.filter(Transaction.type == txn_type)
    if user_id:
        query = query.filter(Transaction.user_id == user_id)
    total = query.count()
    txs = query.order_by(Transaction.created_at.desc()).offset((page - 1) * limit).limit(limit).all()
    return success_response({
        "items": [{"id": t.id, "user_id": t.user_id, "amount": t.amount, "type": t.type,
                    "description": t.description, "reference": t.reference,
                    "coins_before": t.coins_before, "coins_after": t.coins_after,
                    "created_at": t.created_at.isoformat() if t.created_at else None} for t in txs],
        "total": total, "page": page, "total_pages": max(1, (total + limit - 1) // limit),
    }, request_id=_get_request_id(request))


# ── Orders ──

@router.get("/orders")
async def admin_list_orders(
    request: Request,
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=20, le=100),
    status: str = Query(default=""),
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    query = db.query(SMSOrder)
    if status:
        query = query.filter(SMSOrder.status == status)
    total = query.count()
    orders = query.order_by(SMSOrder.created_at.desc()).offset((page - 1) * limit).limit(limit).all()
    return success_response({
        "items": [{"id": o.id, "user_id": o.user_id, "service": o.service, "country": o.country,
                    "provider": o.provider, "phone_number": o.phone_number, "status": o.status,
                    "cost_coins": o.cost_coins, "activation_id": o.activation_id,
                    "verification_code": o.verification_code, "refunded": o.refunded,
                    "created_at": o.created_at.isoformat() if o.created_at else None} for o in orders],
        "total": total, "page": page, "total_pages": max(1, (total + limit - 1) // limit),
    }, request_id=_get_request_id(request))


# ── Audit Logs ──

@router.get("/logs")
async def admin_list_logs(
    request: Request,
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=30, le=100),
    action: str = Query(default=""),
    user_id: str = Query(default=""),
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    query = db.query(AuditLog)
    if action:
        query = query.filter(AuditLog.action == action)
    if user_id:
        query = query.filter(AuditLog.user_id == user_id)
    total = query.count()
    logs = query.order_by(AuditLog.created_at.desc()).offset((page - 1) * limit).limit(limit).all()
    return success_response({
        "items": [{"id": l.id, "user_id": l.user_id, "action": l.action,
                    "resource_type": l.resource_type, "resource_id": l.resource_id,
                    "details": l.details, "ip_address": l.ip_address,
                    "created_at": l.created_at.isoformat() if l.created_at else None} for l in logs],
        "total": total, "page": page, "total_pages": max(1, (total + limit - 1) // limit),
    }, request_id=_get_request_id(request))


# ── Tiers ──

@router.get("/tiers")
async def admin_list_tiers(
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    return success_response(TierService.all_tiers(db), request_id=_get_request_id(request))


# ── Feature Flags ──

@router.get("/feature-flags")
async def admin_list_flags(
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    return success_response(FeatureFlags.all_flags(db), request_id=_get_request_id(request))


@router.post("/feature-flags/{name}")
async def admin_update_flag(
    name: str,
    body: UpdateFeatureFlagRequest,
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    FeatureFlags.set_flag(db, name, body.enabled, body.strategy)
    AuditService.log(db, _admin.id, "admin.update_feature_flag", "feature_flag", name,
                     {"enabled": body.enabled, "strategy": body.strategy},
                     ip_address=_get_ip(request), request_id=_get_request_id(request))
    return success_response({"message": "تم تحديث الخاصية"}, request_id=_get_request_id(request))


# ── Sessions ──

@router.get("/sessions")
async def admin_list_sessions(
    request: Request,
    user_id: str = Query(default=None),
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    if user_id:
        sessions = SessionManager.get_user_sessions(db, user_id)
    else:
        sessions = db.query(UserSession).order_by(UserSession.created_at.desc()).limit(100).all()
    return success_response([{
        "id": s.id, "user_id": s.user_id, "ip_address": s.ip_address,
        "user_agent": s.user_agent, "is_active": s.is_active,
        "created_at": s.created_at.isoformat() if s.created_at else None,
        "expires_at": s.expires_at.isoformat() if s.expires_at else None,
    } for s in sessions], request_id=_get_request_id(request))


@router.post("/sessions/{session_id}/revoke")
async def admin_revoke_session(
    session_id: str,
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    session = db.query(UserSession).filter(UserSession.id == session_id).first()
    if not session:
        raise AppException("NOT_FOUND", "الجلسة غير موجودة", 404)
    SessionManager.invalidate_session(db, session.refresh_token)
    AuditService.log(db, _admin.id, "admin.revoke_session", "session", session_id, {"user_id": session.user_id},
                     ip_address=_get_ip(request), request_id=_get_request_id(request))
    return success_response({"message": "تم إلغاء الجلسة"}, request_id=_get_request_id(request))


# ── Email Templates ──

@router.get("/email-templates")
async def admin_list_email_templates(
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    templates = db.query(EmailTemplate).all()
    return success_response([{
        "id": t.id, "name": t.name, "subject": t.subject,
        "is_active": t.is_active,
        "updated_at": t.updated_at.isoformat() if t.updated_at else None,
    } for t in templates], request_id=_get_request_id(request))


@router.get("/email-templates/{name}")
async def admin_get_email_template(
    name: str,
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    t = db.query(EmailTemplate).filter(EmailTemplate.name == name).first()
    if not t:
        raise AppException("NOT_FOUND", "القالب غير موجود", 404)
    return success_response({
        "id": t.id, "name": t.name, "subject": t.subject,
        "html_content": t.html_content, "is_active": t.is_active,
    }, request_id=_get_request_id(request))


@router.put("/email-templates/{name}")
async def admin_update_email_template(
    name: str,
    body: UpdateEmailTemplateRequest,
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    EmailTemplateService.save_template(db, name, body.subject, body.html_content)
    AuditService.log(db, _admin.id, "admin.update_email_template", "email_template", name, {},
                     ip_address=_get_ip(request), request_id=_get_request_id(request))
    return success_response({"message": "تم تحديث القالب"}, request_id=_get_request_id(request))


# ── Waitlist ──

@router.get("/waitlist")
async def admin_get_waitlist(
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    entries = db.query(Waitlist).order_by(Waitlist.created_at.desc()).all()
    return success_response([{
        "id": e.id, "email": e.email, "name": e.name,
        "source": e.source, "is_notified": e.is_notified,
        "created_at": e.created_at.isoformat() if e.created_at else None,
    } for e in entries], request_id=_get_request_id(request))


@router.post("/waitlist/{entry_id}/notify")
async def admin_mark_waitlist_notified(
    entry_id: str,
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    entry = db.query(Waitlist).filter(Waitlist.id == entry_id).first()
    if not entry:
        raise AppException("NOT_FOUND", "الإدخال غير موجود", 404)
    entry.is_notified = True
    db.commit()
    return success_response({"message": "تم تحديث حالة الإشعار"}, request_id=_get_request_id(request))


# ── Notifications ──

@router.get("/notifications")
async def admin_list_notifications(
    request: Request,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    items, total = NotificationPrefsService.get_admin_notifications(db, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page},
                           request_id=_get_request_id(request))


@router.post("/notifications")
async def admin_create_notification(
    request: Request,
    body: CreateAdminNotificationRequest,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    result = NotificationPrefsService.create_admin_notification(db, body.model_dump())
    AuditService.log(db, _admin.id, "admin.notification.create", "admin_notification", result["id"],
                     {"title": body.title}, _get_ip(request), _get_request_id(request))
    return success_response(result, request_id=_get_request_id(request))


@router.get("/notification-defaults")
async def admin_get_notification_defaults(
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    return success_response(NotificationPrefsService.get_defaults(db), request_id=_get_request_id(request))


@router.put("/notification-defaults/{category}")
async def admin_update_notification_default(
    category: str,
    body: UpdateNotificationDefaultRequest,
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    result = NotificationPrefsService.upsert_default(db, category, body.model_dump(exclude_none=True))
    return success_response(result, request_id=_get_request_id(request))
