import html

from typing import Optional

from fastapi import APIRouter, Depends, Query, Request

from app.core.country_names import COUNTRY_NAMES

from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.config import get_settings, get_app_setting
from app.core.database import get_db
from app.core.dependencies import get_current_user, require_mfa
from app.core.exceptions import AppException
from app.core.response import success_response
from app.core.security import hash_password, verify_password, verify_token
from app.core.session_manager import SessionManager
from app.core.logging import get_logger
from app.domain.coins import CoinsEngine
from app.domain.models import Country, SMSOrder, Service, Transaction, User
from app.infrastructure.providers import ProviderRouter
from app.services.audit_service import AuditService
from app.services.blacklist_service import BlacklistService
from app.services.fraud_service import FraudService
from app.services.purchase_service import PurchaseService
from app.services.quota_service import QuotaService

logger = get_logger(__name__)

router = APIRouter(prefix="/user", tags=["User"])


def _get_request_id(request: Request) -> str:
    return getattr(request.state, "request_id", "")


def _get_ip(request: Request) -> str:
    if not request:
        return ""
    forwarded = request.headers.get("x-forwarded-for", "")
    ip = forwarded.split(",")[0].strip() if forwarded else (request.client.host if request.client else "")
    import re
    if re.match(r"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$", ip):
        return ip
    return request.client.host if request.client else ""


@router.get("/profile")
async def get_profile(
    request: Request,
    current_user: User = Depends(get_current_user),
):
    return success_response(
        {
            "id": current_user.id,
            "email": current_user.email,
            "display_name": current_user.display_name,
            "photo_url": current_user.photo_url,
            "avatar": current_user.avatar,
            "coins": current_user.coins,
            "lifetime_coins": current_user.lifetime_coins,
            "temp_emails_used": current_user.temp_emails_used,
            "is_admin": current_user.is_admin,
            "created_at": current_user.created_at.isoformat() if current_user.created_at else None,
        },
        request_id=getattr(request.state, "request_id", ""),
    )


class UpdateProfileRequest(BaseModel):
    display_name: Optional[str] = None
    avatar: Optional[str] = None


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str


class RefundRequest(BaseModel):
    order_id: str


class PurchaseRequest(BaseModel):
    service: str
    country: str
    provider: Optional[str] = None


@router.put("/profile/update")
async def update_profile(
    body: UpdateProfileRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if body.display_name is not None:
        current_user.display_name = html.escape(body.display_name.strip()[:100])
    if body.avatar is not None:
        if body.avatar.startswith("data:image/") or (body.avatar.startswith("https://") and any(body.avatar.lower().endswith(ext) for ext in (".png", ".jpg", ".jpeg", ".gif", ".webp"))):
            current_user.avatar = html.escape(body.avatar)[:512]
    db.commit()
    return success_response(
        {
            "id": current_user.id,
            "display_name": current_user.display_name,
            "avatar": current_user.avatar,
        },
        request_id=getattr(request.state, "request_id", ""),
    )


@router.post("/change-password")
async def change_password(
    body: ChangePasswordRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    _mfa: User = Depends(require_mfa),
):
    if len(body.new_password) < 8:
        raise AppException("VALIDATION_ERROR", "كلمة المرور الجديدة يجب أن تكون 8 أحرف على الأقل", 400)
    if not verify_password(body.current_password, current_user.hashed_password or ""):
        raise AppException("WRONG_PASSWORD", "كلمة المرور الحالية غير صحيحة", 400)
    current_user.hashed_password = hash_password(body.new_password)

    auth_header = request.headers.get("Authorization", "") if request else ""
    current_refresh = request.headers.get("x-refresh-token", "")
    if auth_header.startswith("Bearer "):
        token = auth_header[7:]
        payload = verify_token(token)
        if payload and payload.get("jti"):
            BlacklistService.blacklist_token(db, payload["jti"], "access", current_user.id, "password_changed", 1)

    if current_refresh:
        SessionManager.invalidate_session(db, current_refresh)
    db.commit()
    AuditService.log(db, current_user.id, "user.change_password", "user", current_user.id, {},
                   request.client.host if request and request.client else "",
                   getattr(request.state, "request_id", ""))
    return success_response({"message": "تم تغيير كلمة المرور بنجاح"},
                          request_id=getattr(request.state, "request_id", ""))


@router.delete("/account")
async def delete_account(
    request: Request = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    _mfa: User = Depends(require_mfa),
):
    ip = request.client.host if request and request.client else ""
    request_id = getattr(request.state, "request_id", "") if request else ""
    AuditService.log(db, current_user.id, "user.delete_account", "user", current_user.id, {},
                   ip, request_id)
    # H-3 FIX: Soft delete — تعطيل الحساب بدلاً من حذفه فوراً
    # يتيح ذلك استرداد البيانات عند الضرورة ويمنع حذف بيانات المستخدمين بالخطأ
    current_user.is_active = False
    current_user.display_name = f"[deleted_{current_user.id[:8]}]"
    current_user.email = f"deleted_{current_user.id}@deleted.local"
    current_user.hashed_password = None
    current_user.reset_token = None
    current_user.reset_token_expires = None
    # إلغاء جميع جلسات المستخدم فوراً
    from app.core.session_manager import SessionManager
    SessionManager.invalidate_all_sessions(db, current_user.id)
    db.commit()
    return success_response({"message": "تم حذف الحساب بنجاح"},
                          request_id=getattr(request.state, "request_id", "") if request else "")


@router.get("/balance")
async def get_balance(
    request: Request,
    current_user: User = Depends(get_current_user),
):
    return success_response(
        {
            "coins": current_user.coins,
            "lifetime_coins": current_user.lifetime_coins,
            "coins_in_usd": CoinsEngine.coins_to_usd(current_user.coins),
        },
        request_id=getattr(request.state, "request_id", ""),
    )


@router.get("/wallet")
async def get_wallet_endpoint(
    request: Request,
    current_user: User = Depends(get_current_user),
):
    return success_response(
        {
            "coins": current_user.coins,
            "lifetime_coins": current_user.lifetime_coins,
            "coins_in_usd": CoinsEngine.coins_to_usd(current_user.coins),
        },
        request_id=getattr(request.state, "request_id", ""),
    )


@router.post("/coins/refund")
async def refund_coins(
    body: RefundRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    order = db.query(SMSOrder).filter(
        SMSOrder.id == body.order_id,
        SMSOrder.user_id == current_user.id,
    ).with_for_update().first()
    if not order:
        raise AppException("NOT_FOUND", "الطلب غير موجود", 404)
    if order.refunded:
        raise AppException("DUPLICATE_REQUEST", "تم استرداد هذا الطلب مسبقاً", 400)
    if order.status == "expired":
        raise AppException("ORDER_EXPIRED", "انتهت صلاحية الطلب ويتم معالجته تلقائياً", 400)
    provider = await ProviderRouter().get_provider(order.provider)
    if provider:
        try:
            await provider.cancel(order.activation_id)
        except Exception as e:
            logger.warning(f"Provider cancel failed for order {order.id}: {e}")
    svc = PurchaseService(db)
    refund_tx = svc.refund_coins(
        current_user, order.cost_coins,
        f"استرداد للطلب {order.id}",
    )
    order.refunded = True
    order.status = "refunded"
    order.refund_transaction_id = refund_tx.id
    db.commit()
    AuditService.log(db, current_user.id, "coins.refund", "sms_order", order.id,
                   {"coins": order.cost_coins}, _get_ip(request), _get_request_id(request))
    return success_response({
        "message": "تم استرداد الكوين بنجاح",
        "coins": order.cost_coins,
        "balance": current_user.coins,
    }, request_id=_get_request_id(request))


@router.get("/verifications")
async def list_verifications(
    request: Request,
    limit: int = Query(default=20, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    orders = db.query(SMSOrder).filter(
        SMSOrder.user_id == current_user.id,
    ).order_by(SMSOrder.created_at.desc()).limit(limit).all()
    return success_response([
        {
            "id": o.id,
            "service": o.service,
            "country": o.country,
            "provider": o.provider,
            "phone_number": o.phone_number,
            "status": o.status,
            "cost_coins": o.cost_coins,
            "created_at": o.created_at.isoformat() if o.created_at else None,
        }
        for o in orders
    ], request_id=_get_request_id(request))


@router.get("/verifications/{verification_id}")
async def get_verification(
    verification_id: str,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    order = db.query(SMSOrder).filter(
        SMSOrder.id == verification_id,
        SMSOrder.user_id == current_user.id,
    ).first()
    if not order:
        raise AppException("NOT_FOUND", "التحقق غير موجود", 404)
    return success_response({
        "id": order.id,
        "service": order.service,
        "country": order.country,
        "provider": order.provider,
        "phone_number": order.phone_number,
        "type": order.type,
        "status": order.status,
        "verification_code": order.verification_code,
        "sms_text": order.sms_text,
        "cost_coins": order.cost_coins,
        "refunded": order.refunded,
        "created_at": order.created_at.isoformat() if order.created_at else None,
        "updated_at": order.updated_at.isoformat() if order.updated_at else None,
    }, request_id=_get_request_id(request))


@router.get("/services/{service_name}/countries")
async def service_countries(
    service_name: str,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from app.domain.models import ServiceCountry

    rows = (
        db.query(ServiceCountry.country_code)
        .filter(
            ServiceCountry.service == service_name,
            ServiceCountry.is_active == True,
        )
        .distinct(ServiceCountry.country_code)
        .order_by(ServiceCountry.country_code.asc())
        .all()
    )
    if rows:
        codes = [r[0] for r in rows]
        name_map = {c.code: c.name for c in db.query(Country).filter(Country.code.in_(codes)).all()}
        cheapest = (
            db.query(ServiceCountry.country_code, ServiceCountry.provider)
            .filter(
                ServiceCountry.service == service_name,
                ServiceCountry.country_code.in_(codes),
                ServiceCountry.is_active == True,
            )
            .order_by(ServiceCountry.provider_cost.asc())
            .all()
        )
        provider_map: dict[str, str] = {}
        for code, prov in cheapest:
            if code not in provider_map:
                provider_map[code] = prov
        result = [
            {"code": code, "name": name_map.get(code, COUNTRY_NAMES.get(code, code)), "provider": provider_map.get(code)}
            for code in codes
        ]
        return success_response(result, request_id=_get_request_id(request))

    pr = ProviderRouter()
    seen = {}
    for p in pr.enabled_providers:
        try:
            clist = await p.get_countries()
            for c in clist:
                code = c.get("code", "")
                if code and code not in seen:
                    seen[code] = c.get("name", code)
        except Exception as e:
            logger.warning(f"Failed to fetch countries from {p.name}: {e}")
            continue
    fallback = [{"code": k, "name": v} for k, v in seen.items()]
    if not fallback:
        fallback = [{"code": code, "name": name} for code, name in COUNTRY_NAMES.items()][:50]
    return success_response(fallback, request_id=_get_request_id(request))


@router.get("/services/{service_name}/price")
async def service_price(
    service_name: str,
    country: str = Query(default="US"),
    request: Request = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    pr = ProviderRouter()
    best = None
    best_provider = None
    for p in pr.enabled_providers:
        try:
            cost = await p.get_price(service_name, country)
            if best is None or cost < best:
                best = cost
                best_provider = p.name
        except Exception as e:
            logger.warning(f"Failed to get price from {p.name}: {e}")
            continue
    if best is None:
        raise AppException("SERVICE_UNAVAILABLE", "السعر غير متاح حالياً", 404)
    coins_per_usd = get_app_setting(db, "coins_per_usd", get_settings().coins_per_usd)
    default_markup = get_app_setting(db, "default_markup", get_settings().default_markup)
    markup = default_markup
    return success_response({
        "service": service_name,
        "country": country,
        "provider": best_provider,
        "price": best,
        "price_with_markup": round(best * markup, 4),
        "cost_coins": int(best * markup * coins_per_usd),
    }, request_id=_get_request_id(request))


@router.post("/services/purchase")
async def user_service_purchase(
    body: PurchaseRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ip = request.client.host if request and request.client else ""
    request_id_val = _get_request_id(request)

    # H-5 FIX: إضافة فحص Fraud و Quota المفقودين من هذا الـ endpoint
    fraud = await FraudService.score_request(db, current_user.id, ip, body.service)
    if fraud["score"] > 50:
        raise AppException("FRAUD_DETECTED", "تم اكتشاف نشاط غير طبيعي، الرجاء المحاولة لاحقاً", 429)

    qs = QuotaService(db)
    remaining = qs.get_remaining_daily(current_user.id, current_user.tier or "freemium")
    if remaining <= 0:
        raise AppException("QUOTA_EXCEEDED", "لقد تجاوزت الحد اليومي للطلبات", 429)

    svc = PurchaseService(db)
    result = await svc.purchase(
        user=current_user,
        service=body.service,
        country=body.country,
        preferred_provider=body.provider,
        ip_address=ip,
        request_id=request_id_val,
    )
    return success_response(result, request_id=request_id_val)


@router.get("/transactions")
async def list_transactions(
    request: Request,
    limit: int = Query(default=20, le=100),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    transactions = (
        db.query(Transaction)
        .filter(Transaction.user_id == current_user.id)
        .order_by(Transaction.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return success_response(
        [
            {
                "id": t.id,
                "amount": t.amount,
                "type": t.type,
                "description": t.description,
                "reference": t.reference,
                "coins_before": t.coins_before,
                "coins_after": t.coins_after,
                "created_at": t.created_at.isoformat() if t.created_at else None,
            }
            for t in transactions
        ],
        request_id=getattr(request.state, "request_id", ""),
    )
