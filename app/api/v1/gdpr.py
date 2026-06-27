from datetime import datetime, timezone

from typing import Optional

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.response import success_response
from app.domain.models import ConsentRecord, User, gen_uuid
from app.services.audit_service import AuditService


class UpdateConsentRequest(BaseModel):
    marketing: Optional[bool] = None
    analytics: Optional[bool] = None
    data_sharing: Optional[bool] = None

router = APIRouter(prefix="/user/gdpr", tags=["GDPR"])


@router.get("/export")
async def export_data(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from app.domain.models import SMSOrder, Transaction, AuditLog, APIKey, Webhook, \
        PaymentLog, Notification, NumberRental, TempEmail, Referral, ReferralCode, \
        ForwardingConfig, ConsentRecord, DeviceToken, UserSession
    user_data = {
        "user": {
            "id": current_user.id,
            "email": current_user.email,
            "display_name": current_user.display_name,
            "coins": current_user.coins,
            "lifetime_coins": current_user.lifetime_coins,
            "tier": current_user.tier,
            "is_admin": current_user.is_admin,
            "mfa_enabled": current_user.mfa_enabled,
            "onboarding_completed": current_user.onboarding_completed,
            "created_at": current_user.created_at.isoformat() if current_user.created_at else None,
            "last_login_at": current_user.last_login_at.isoformat() if current_user.last_login_at else None,
            "google_id": current_user.google_id,
            "apple_id": current_user.apple_id,
        },
        "transactions": [
            {"id": t.id, "amount": t.amount, "type": t.type, "description": t.description, "reference": t.reference, "created_at": t.created_at.isoformat() if t.created_at else None}
            for t in db.query(Transaction).filter(Transaction.user_id == current_user.id).all()
        ],
        "sms_orders": [
            {"id": o.id, "service": o.service, "country": o.country, "status": o.status, "cost_coins": o.cost_coins, "phone_number": o.phone_number,
             "created_at": o.created_at.isoformat() if o.created_at else None}
            for o in db.query(SMSOrder).filter(SMSOrder.user_id == current_user.id).all()
        ],
        "payments": [
            {"id": p.id, "provider": p.provider, "product_id": p.product_id, "amount_usd": p.amount_usd, "coins": p.coins, "status": p.status, "created_at": p.created_at.isoformat() if p.created_at else None}
            for p in db.query(PaymentLog).filter(PaymentLog.user_id == current_user.id).all()
        ],
        "audit_logs": [
            {"action": a.action, "resource_type": a.resource_type, "resource_id": a.resource_id, "ip_address": a.ip_address,
             "created_at": a.created_at.isoformat() if a.created_at else None}
            for a in db.query(AuditLog).filter(AuditLog.user_id == current_user.id).all()
        ],
        "api_keys": [
            {"name": k.name, "prefix": k.prefix, "is_active": k.is_active, "created_at": k.created_at.isoformat() if k.created_at else None}
            for k in db.query(APIKey).filter(APIKey.user_id == current_user.id).all()
        ],
        "webhooks": [
            {"url": w.url, "events": w.events, "is_active": w.is_active, "created_at": w.created_at.isoformat() if w.created_at else None}
            for w in db.query(Webhook).filter(Webhook.user_id == current_user.id).all()
        ],
        "notifications": [
            {"id": n.id, "type": n.type, "title": n.title, "is_read": n.is_read, "created_at": n.created_at.isoformat() if n.created_at else None}
            for n in db.query(Notification).filter(Notification.user_id == current_user.id).all()
        ],
        "rentals": [
            {"id": r.id, "service": r.service, "country": r.country, "status": r.status, "cost_coins": r.cost_coins, "created_at": r.created_at.isoformat() if r.created_at else None}
            for r in db.query(NumberRental).filter(NumberRental.user_id == current_user.id).all()
        ],
        "temp_emails": [
            {"email_address": e.email_address, "is_active": e.is_active, "created_at": e.created_at.isoformat() if e.created_at else None}
            for e in db.query(TempEmail).filter(TempEmail.user_id == current_user.id).all()
        ],
        "referrals": [
            {"code": r.code, "reward_coins": r.reward_coins, "status": r.status, "created_at": r.created_at.isoformat() if r.created_at else None}
            for r in db.query(Referral).filter(Referral.referrer_id == current_user.id).all()
        ],
        "referral_codes": [
            {"code": rc.code, "created_at": rc.created_at.isoformat() if rc.created_at else None}
            for rc in db.query(ReferralCode).filter(ReferralCode.user_id == current_user.id).all()
        ],
        "forwarding_config": [
            {"email_enabled": f.email_enabled, "webhook_enabled": f.webhook_enabled,
             "created_at": f.created_at.isoformat() if f.created_at else None}
            for f in db.query(ForwardingConfig).filter(ForwardingConfig.user_id == current_user.id).all()
        ],
        "consent_records": [
            {"consent_type": c.consent_type, "granted": c.granted, "created_at": c.created_at.isoformat() if c.created_at else None}
            for c in db.query(ConsentRecord).filter(ConsentRecord.user_id == current_user.id).all()
        ],
        "device_tokens": [
            {"platform": d.platform, "active": d.active, "created_at": d.created_at.isoformat() if d.created_at else None}
            for d in db.query(DeviceToken).filter(DeviceToken.user_id == current_user.id).all()
        ],
        "sessions": [
            {"ip_address": s.ip_address, "is_active": s.is_active, "created_at": s.created_at.isoformat() if s.created_at else None}
            for s in db.query(UserSession).filter(UserSession.user_id == current_user.id).all()
        ],
        "export_date": datetime.now(timezone.utc).isoformat(),
    }
    return success_response(user_data, request_id=getattr(request.state, "request_id", ""))


@router.get("/consent")
async def get_consent(
    request: Request,
    current_user: User = Depends(get_current_user),
):
    return success_response({
        "marketing_consent": current_user.marketing_consent,
        "analytics_consent": current_user.analytics_consent,
        "data_sharing_consent": current_user.data_sharing_consent,
    }, request_id=getattr(request.state, "request_id", ""))


@router.put("/consent")
async def update_consent(
    body: UpdateConsentRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ip = request.client.host if request and request.client else ""
    request_id_val = getattr(request.state, "request_id", "")
    if body.marketing is not None:
        current_user.marketing_consent = body.marketing
        db.add(ConsentRecord(id=gen_uuid(), user_id=current_user.id, consent_type="marketing", granted=body.marketing, ip_address=ip))
    if body.analytics is not None:
        current_user.analytics_consent = body.analytics
        db.add(ConsentRecord(id=gen_uuid(), user_id=current_user.id, consent_type="analytics", granted=body.analytics, ip_address=ip))
    if body.data_sharing is not None:
        current_user.data_sharing_consent = body.data_sharing
        db.add(ConsentRecord(id=gen_uuid(), user_id=current_user.id, consent_type="data_sharing", granted=body.data_sharing, ip_address=ip))
    db.commit()
    AuditService.log(db, current_user.id, "gdpr.consent_update", "user", current_user.id, {},
                   ip, request_id_val)
    return success_response({"message": "تم تحديث الإعدادات"},
                          request_id=getattr(request.state, "request_id", "") if request else "")


@router.get("/retention-policy")
async def retention_policy(request: Request):
    return success_response({
        "user_data": "مدة الحساب + 30 يوماً",
        "verification_data": "90 يوماً",
        "transaction_data": "7 سنوات (حسب القانون)",
        "audit_logs": "سنة واحدة",
    }, request_id=getattr(request.state, "request_id", ""))
