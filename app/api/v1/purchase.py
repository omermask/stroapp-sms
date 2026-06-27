import asyncio
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.logging import get_logger
from app.core.response import success_response
from app.core.country_names import COUNTRY_NAMES
from app.domain.models import SMSOrder, Transaction, User, AuditLog, Service, Country, gen_uuid
from app.infrastructure.providers import ProviderRouter
from app.core.idempotency import IdempotencyService
from app.services.audit_service import AuditService
from app.services.background import SMSPollingService
from app.services.fraud_service import FraudService
from app.services.price_calculator import PriceCalculator
from app.services.purchase_service import PurchaseService
from app.services.quota_service import QuotaService
from app.services.commission_engine import CommissionEngine
from app.services.geo_service import GeoService

logger = get_logger(__name__)

router = APIRouter(prefix="/sms", tags=["SMS"])
provider_router = ProviderRouter()
_polling_service = SMSPollingService()


class PurchaseRequest(BaseModel):
    service: str
    country: str
    provider: Optional[str] = None


class BulkPriceRequest(BaseModel):
    service: str
    countries: list[str]


@router.get("/price")
async def get_price(
    service: str = Query(...),
    country: str = Query(...),
    request: Request = None,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    calc = PriceCalculator(db)
    best = calc.get_best_price(service, country.upper(), user)
    if best:
        return success_response(
            {
                "service": service,
                "country": country.upper(),
                "provider": best["provider"],
                "provider_cost": best["provider_cost"],
                "markup": best["markup"],
                "final_price_usd": best["raw_price_usd"],
                "cost_coins": best["cost_coins"],
                "available_count": best["available_count"],
            },
            request_id=getattr(request.state, "request_id", "") if request else "",
        )

    svc = PurchaseService(db)
    best_live = await svc.get_best_price(service, country)
    if not best_live:
        raise AppException("SERVICE_UNAVAILABLE", f"لا يتوفر سعر لـ {service} في {country}")
    return success_response(
        {
            "service": service,
            "country": country,
            "provider": best_live.provider,
            "provider_cost": best_live.provider_cost,
            "cost_coins": best_live.cost_coins,
        },
        request_id=getattr(request.state, "request_id", "") if request else "",
    )


@router.get("/price/all")
async def get_price_all(
    service: str = Query(...),
    country: str = Query(...),
    request: Request = None,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    calc = PriceCalculator(db)
    providers = calc.list_available(service, country.upper(), user)

    if not providers:
        try:
            for p in provider_router.enabled_providers:
                try:
                    pservices = await p.get_services(country.upper())
                    for svc in pservices:
                        if svc.service_id == service:
                            markup = 1.20
                            raw = svc.cost * markup
                            providers.append({
                                "provider": p.name,
                                "provider_cost": svc.cost,
                                "markup": markup,
                                "final_price_usd": round(raw, 4),
                                "cost_coins": max(1, round(raw * 100)),
                                "available_count": svc.count,
                                "last_synced_at": None,
                            })
                except Exception as exc:
                    logger.exception("Failed to fetch price from provider: %s", exc)
                    continue
        except Exception as exc:
            logger.exception("Failed to fetch provider prices: %s", exc)

    return success_response(
        providers,
        request_id=getattr(request.state, "request_id", "") if request else "",
    )


@router.post("/prices/bulk")
async def get_bulk_prices(
    body: BulkPriceRequest,
    request: Request = None,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    calc = PriceCalculator(db)
    prices = calc.get_best_price_for_countries(
        body.service, [c.upper() for c in body.countries], user,
    )
    return success_response(
        prices,
        request_id=getattr(request.state, "request_id", "") if request else "",
    )


@router.post("/purchase")
async def purchase_number(
    body: PurchaseRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    logger.info(
        f"Purchase request: user={current_user.id} service={body.service} "
        f"country={body.country} provider={body.provider}"
    )

    idempotency_key = request.headers.get("Idempotency-Key") or request.headers.get("x-idempotency-key")
    if idempotency_key:
        # C-4 FIX: ربط مفتاح الـ idempotency بمعرف المستخدم لمنع اختراق نتائج مستخدمين آخرين
        scoped_key = f"{current_user.id}:{idempotency_key}"
        idem = IdempotencyService(db)
        cached = idem.get_response(scoped_key)
        if cached:
            return success_response(cached, request_id=getattr(request.state, "request_id", ""))
        if not idem.check_and_set(scoped_key):
            raise AppException("IDEMPOTENCY_ERROR", "تم استخدام هذا المفتاح مسبقاً", 409)

    ip = request.client.host if request.client else ""
    request_id_val = getattr(request.state, "request_id", "")

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

    order_id = result["order_id"]
    logger.info(
        f"Purchase success: order={order_id} phone={result['phone_number']} "
        f"provider={result['provider']} cost={result['cost_coins']} coins"
    )

    # C-1 FIX: استخدام asyncio.create_task لتشغيل الـ polling بشكل صحيح
    # الاستدعاء المباشر لـ async method بدون await لا يُنفّذ الكود
    asyncio.create_task(_polling_service.start(
        order_id=order_id,
        activation_id=result.get("activation_id", ""),
        provider_name=result["provider"],
    ))

    try:
        geo = await GeoService.lookup_ip(db, ip)
        if geo.get("country"):
            logger.info(f"Purchase geo: user={current_user.id} country={geo['country']}")
    except Exception as exc:
        logger.exception("Failed to lookup IP geo: %s", exc)

    try:
        from app.domain.models import AffiliateCommission
        parent = db.query(AffiliateCommission).filter(
            AffiliateCommission.user_id == current_user.id,
        ).first()
        if parent and parent.parent_id:
            ce = CommissionEngine(db)
            ce.record_commission(
                referrer_id=parent.parent_id,
                referred_user_id=current_user.id,
                order_id=order_id,
                amount_coins=result.get("cost_coins", 0),
                description=f"Commission for order {order_id}",
            )
    except Exception as exc:
        logger.exception("Failed to record commission: %s", exc)

    if idempotency_key:
        idem.set_response(scoped_key, result)

    return success_response(result, request_id=getattr(request.state, "request_id", ""))


@router.get("/orders")
async def list_orders(
    request: Request,
    status: str = Query(default=None),
    limit: int = Query(default=20, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(SMSOrder).filter(SMSOrder.user_id == current_user.id)
    if status:
        query = query.filter(SMSOrder.status == status)
    orders = query.order_by(SMSOrder.created_at.desc()).limit(limit).all()
    svc_ids = list({o.service for o in orders})
    svc_map = {s.name: s.display_name for s in db.query(Service).filter(Service.name.in_(svc_ids)).all()}
    return success_response(
        [
            {
                "id": o.id,
                "service": o.service,
                "service_name": svc_map.get(o.service, o.service),
                "country": o.country,
                "country_name": COUNTRY_NAMES.get(o.country, o.country),
                "provider": o.provider,
                "phone_number": o.phone_number,
                "status": o.status,
                "cost_coins": o.cost_coins,
                "verification_code": o.verification_code,
                "created_at": o.created_at.isoformat() if o.created_at else None,
                "updated_at": o.updated_at.isoformat() if o.updated_at else None,
            }
            for o in orders
        ],
        request_id=getattr(request.state, "request_id", ""),
    )


@router.get("/orders/{order_id}")
async def get_order(
    order_id: str,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    order = db.query(SMSOrder).filter(
        SMSOrder.id == order_id,
        SMSOrder.user_id == current_user.id,
    ).first()
    if not order:
        raise AppException("NOT_FOUND", "الطلب غير موجود", status_code=404)
    from app.domain.models import Service, Country

    svc = db.query(Service).filter(Service.name == order.service).first()
    ctry = db.query(Country).filter(Country.code == order.country).first()
    return success_response(
        {
            "id": order.id,
            "service": order.service,
            "service_name": svc.display_name if svc else order.service,
            "country": order.country,
            "country_name": ctry.name if ctry else COUNTRY_NAMES.get(order.country, order.country),
            "provider": order.provider,
            "phone_number": order.phone_number,
            "status": order.status,
            "cost_coins": order.cost_coins,
            "verification_code": order.verification_code,
            "sms_text": order.sms_text,
            "sms_received_at": order.sms_received_at.isoformat() if order.sms_received_at else None,
            "refunded": order.refunded,
            "error_message": order.error_message,
            "created_at": order.created_at.isoformat() if order.created_at else None,
            "updated_at": order.updated_at.isoformat() if order.updated_at else None,
        },
        request_id=getattr(request.state, "request_id", ""),
    )


@router.post("/orders/{order_id}/check")
async def check_sms(
    order_id: str,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    order = db.query(SMSOrder).filter(
        SMSOrder.id == order_id,
        SMSOrder.user_id == current_user.id,
    ).first()
    if not order:
        raise AppException("NOT_FOUND", "الطلب غير موجود", status_code=404)

    if order.status in ("completed", "cancelled", "expired"):
        return success_response(
            {
                "order_id": order.id,
                "status": order.status,
                "verification_code": order.verification_code,
                "sms_text": order.sms_text,
            },
            request_id=getattr(request.state, "request_id", ""),
        )

    provider = await provider_router.get_provider(order.provider)
    if not provider:
        raise AppException("PROVIDER_ERROR", f"المزود '{order.provider}' غير متاح", status_code=503)

    try:
        message = await provider.check_sms(order.activation_id)
    except Exception as e:
        logger.error(f"Check SMS failed for order {order.id}: {e}")
        raise AppException("PROVIDER_ERROR", "فشل التحقق من الرسائل النصية", status_code=502)

    if message and message.code:
        order.status = "completed"
        order.verification_code = message.code
        order.sms_text = message.text
        order.sms_received_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(order)

        ip = request.client.host if request.client else ""
        # H-1 FIX: لا يتم تسجيل verification_code في Audit Log لمنع تسريب البيانات
        AuditService.log(db, current_user.id, "sms.complete", "sms_order", order.id,
                         {"service": order.service, "country": order.country,
                          "provider": order.provider, "has_code": True},
                         ip, getattr(request.state, "request_id", ""))
        logger.info(f"SMS received for order {order.id}: code=***REDACTED***")

        try:
            if order.provider == "fivesim" and hasattr(provider, "finish_order"):
                await provider.finish_order(order.activation_id)
                logger.info(f"5SIM order {order.id} finished after SMS receipt")
        except Exception as e:
            logger.warning(f"Failed to finish 5SIM order {order.id}: {e}")

    return success_response(
        {
            "order_id": order.id,
            "status": order.status,
            "verification_code": order.verification_code,
            "sms_text": order.sms_text,
            "sms_received_at": order.sms_received_at.isoformat() if order.sms_received_at else None,
        },
        request_id=getattr(request.state, "request_id", ""),
    )


@router.post("/orders/{order_id}/cancel")
async def cancel_order(
    order_id: str,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    order = db.query(SMSOrder).filter(
        SMSOrder.id == order_id,
        SMSOrder.user_id == current_user.id,
    # H-4 FIX: قفل الطلب لمنع الإلغاء/الاسترداد المزدوج (Race Condition)
    ).with_for_update().first()
    if not order:
        raise AppException("NOT_FOUND", "الطلب غير موجود", status_code=404)

    if order.status in ("completed", "cancelled"):
        raise AppException("VALIDATION_ERROR", f"الطلب حالته: {order.status}", status_code=400)

    provider = await provider_router.get_provider(order.provider)
    if not provider:
        raise AppException("PROVIDER_ERROR", f"المزود '{order.provider}' غير متاح", status_code=503)

    try:
        cancelled = await provider.cancel(order.activation_id)
    except Exception as e:
        logger.error(f"Cancel failed for order {order.id}: {e}")
        raise AppException("PROVIDER_ERROR", "فشل إلغاء الطلب", status_code=502)

    if not cancelled:
        raise AppException("PROVIDER_ERROR", f"المزود '{order.provider}' رفض الإلغاء", status_code=502)

    order.status = "cancelled"
    order.refunded = True

    svc = PurchaseService(db)
    refund_tx = svc.refund_coins(
        current_user, order.cost_coins,
        f"Refund for cancelled order {order.id}",
    )
    order.refund_transaction_id = refund_tx.id

    db.commit()
    db.refresh(order)

    ip = request.client.host if request.client else ""
    AuditService.log(db, current_user.id, "sms.cancel", "sms_order", order.id, {"service": order.service, "country": order.country, "provider": order.provider, "cost_coins": order.cost_coins, "refunded": True}, ip, getattr(request.state, "request_id", ""))
    logger.info(f"Order {order.id} cancelled and refunded {order.cost_coins} coins")

    return success_response(
        {
            "order_id": order.id,
            "status": order.status,
            "refunded": order.refunded,
        },
        request_id=getattr(request.state, "request_id", ""),
    )
