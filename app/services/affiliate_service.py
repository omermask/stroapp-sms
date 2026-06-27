from datetime import datetime, timezone
from typing import Optional

from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.domain.models import (
    AffiliateApplication,
    AffiliateCommission,
    CommissionTier,
    PayoutRequest,
    RevenueShare,
    Transaction,
    User,
    gen_uuid,
)


class AffiliateService:
    @staticmethod
    def apply(db: Session, user_id: str, program_type: str, message: Optional[str] = None) -> dict:
        existing = db.query(AffiliateApplication).filter(
            AffiliateApplication.user_id == user_id,
            AffiliateApplication.status == "pending",
        ).first()
        if existing:
            return {"id": existing.id, "status": "pending", "message": "لديك طلب قيد المراجعة بالفعل"}

        application = AffiliateApplication(
            id=gen_uuid(),
            user_id=user_id,
            program_type=program_type,
            message=message,
        )
        db.add(application)
        db.commit()
        db.refresh(application)
        return {"id": application.id, "status": application.status, "message": "تم تقديم الطلب بنجاح"}

    @staticmethod
    def get_user_application(db: Session, user_id: str) -> Optional[dict]:
        app = db.query(AffiliateApplication).filter(AffiliateApplication.user_id == user_id).first()
        if not app:
            return None
        return {
            "id": app.id,
            "program_type": app.program_type,
            "status": app.status,
            "message": app.message,
            "rejection_reason": app.rejection_reason,
            "created_at": app.created_at.isoformat(),
        }

    @staticmethod
    def list_applications(db: Session, status: Optional[str] = None, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(AffiliateApplication)
        if status:
            query = query.filter(AffiliateApplication.status == status)
        total = query.count()
        apps = query.order_by(AffiliateApplication.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
        result = []
        for a in apps:
            user = db.query(User).filter(User.id == a.user_id).first()
            result.append({
                "id": a.id,
                "user_id": a.user_id,
                "user_email": user.email if user else None,
                "program_type": a.program_type,
                "status": a.status,
                "message": a.message,
                "rejection_reason": a.rejection_reason,
                "created_at": a.created_at.isoformat(),
            })
        return result, total

    @staticmethod
    def review_application(db: Session, application_id: str, status: str, reviewed_by: str, rejection_reason: Optional[str] = None) -> Optional[dict]:
        app = db.query(AffiliateApplication).filter(AffiliateApplication.id == application_id).first()
        if not app:
            return None
        app.status = status
        app.reviewed_by = reviewed_by
        app.reviewed_at = datetime.now(timezone.utc)
        app.rejection_reason = rejection_reason if status == "rejected" else None

        if status == "approved":
            user = db.query(User).filter(User.id == app.user_id).first()
            if user:
                user.is_affiliate = True

        db.commit()
        db.refresh(app)
        return {
            "id": app.id,
            "status": app.status,
            "reviewed_by": app.reviewed_by,
            "reviewed_at": app.reviewed_at.isoformat() if app.reviewed_at else None,
        }

    @staticmethod
    def get_commissions(db: Session, affiliate_id: str, status: Optional[str] = None, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(AffiliateCommission).filter(AffiliateCommission.affiliate_id == affiliate_id)
        if status:
            query = query.filter(AffiliateCommission.status == status)
        total = query.count()
        items = query.order_by(AffiliateCommission.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": c.id,
                "transaction_id": c.transaction_id,
                "order_id": c.order_id,
                "referred_user_id": c.referred_user_id,
                "amount": c.amount,
                "commission_rate": c.commission_rate,
                "status": c.status,
                "payout_id": c.payout_id,
                "notes": c.notes,
                "created_at": c.created_at.isoformat(),
                "paid_at": c.paid_at.isoformat() if c.paid_at else None,
            }
            for c in items
        ], total

    @staticmethod
    def get_commission_summary(db: Session, affiliate_id: str) -> dict:
        commissions = db.query(AffiliateCommission).filter(AffiliateCommission.affiliate_id == affiliate_id).all()
        total_earned = sum(c.amount for c in commissions if c.status in ("approved", "paid"))
        total_pending = sum(c.amount for c in commissions if c.status == "pending")
        total_paid = sum(c.amount for c in commissions if c.status == "paid")
        return {
            "total_earned": total_earned,
            "total_pending": total_pending,
            "total_paid": total_paid,
            "total_commissions": len(commissions),
        }

    @staticmethod
    def create_commission(db: Session, affiliate_id: str, transaction_id: Optional[str], order_id: Optional[str], referred_user_id: Optional[str], amount: float, commission_rate: float) -> dict:
        commission = AffiliateCommission(
            id=gen_uuid(),
            affiliate_id=affiliate_id,
            transaction_id=transaction_id,
            order_id=order_id,
            referred_user_id=referred_user_id,
            amount=amount,
            commission_rate=commission_rate,
        )
        db.add(commission)
        db.commit()
        db.refresh(commission)
        return {
            "id": commission.id,
            "amount": commission.amount,
            "commission_rate": commission.commission_rate,
            "status": commission.status,
        }

    @staticmethod
    def approve_commission(db: Session, commission_id: str) -> Optional[dict]:
        c = db.query(AffiliateCommission).filter(AffiliateCommission.id == commission_id).first()
        if not c:
            return None
        c.status = "approved"
        db.commit()
        return {"id": c.id, "status": "approved"}

    @staticmethod
    def list_tiers(db: Session) -> list[dict]:
        tiers = db.query(CommissionTier).order_by(CommissionTier.base_rate.desc()).all()
        return [
            {
                "id": t.id,
                "name": t.name,
                "base_rate": t.base_rate,
                "bonus_rate": t.bonus_rate,
                "min_volume_usd": t.min_volume_usd,
                "min_referrals": t.min_referrals,
                "requirements": t.requirements or {},
            }
            for t in tiers
        ]

    @staticmethod
    def create_tier(db: Session, data: dict) -> dict:
        name = data.get("name", "")
        if not name or not isinstance(name, str) or not name.strip():
            raise AppException("validation_error", "اسم الشريحة مطلوب")
        base_rate = data.get("base_rate", 0)
        if not isinstance(base_rate, (int, float)) or base_rate < 0:
            raise AppException("validation_error", "base_rate must be non-negative")
        min_referrals = data.get("min_referrals", 0)
        if not isinstance(min_referrals, int) or min_referrals < 0:
            raise AppException("validation_error", "min_referrals must be non-negative")
        tier = CommissionTier(
            id=gen_uuid(),
            name=name.strip(),
            base_rate=base_rate,
            bonus_rate=data.get("bonus_rate", 0.0),
            min_volume_usd=data.get("min_volume_usd", 0.0),
            min_referrals=min_referrals,
            requirements=data.get("requirements", {}),
        )
        db.add(tier)
        db.commit()
        db.refresh(tier)
        return {
            "id": tier.id,
            "name": tier.name,
            "base_rate": tier.base_rate,
            "bonus_rate": tier.bonus_rate,
            "min_volume_usd": tier.min_volume_usd,
            "min_referrals": tier.min_referrals,
        }

    @staticmethod
    def create_payout(db: Session, affiliate_id: str, amount: float, payment_method: str, payment_details: Optional[dict] = None) -> dict:
        # C-2 FIX / H-1 FIX: قفل جميع سجلات العمولة معاً في استعلام واحد
        # لمنع حساب available بشكل غير متسق تحت تزامن عالي
        all_commissions = db.query(AffiliateCommission).filter(
            AffiliateCommission.affiliate_id == affiliate_id,
        ).with_for_update().all()

        total_earned = sum(
            c.amount for c in all_commissions
            if c.status in ("approved", "pending")
        )
        total_paid = sum(
            c.amount for c in all_commissions
            if c.status == "paid"
        )
        available = total_earned - total_paid

        if amount <= 0:
            return {"error": "يجب أن يكون المبلغ أكبر من صفر"}
        # N-4 FIX: تصحيح الخطأ الإملائي في رسالة الخطأ
        if amount > available:
            return {"error": "رصيد العمولة غير كافٍ"}

        payout = PayoutRequest(
            id=gen_uuid(),
            affiliate_id=affiliate_id,
            amount=amount,
            payment_method=payment_method,
            payment_details=payment_details,
        )
        db.add(payout)
        db.commit()
        db.refresh(payout)
        return {
            "id": payout.id,
            "amount": payout.amount,
            "status": payout.status,
            "payment_method": payout.payment_method,
        }

    @staticmethod
    def process_payout(db: Session, payout_id: str, processed_by: str, notes: Optional[str] = None, status: str = "approved") -> Optional[dict]:
        payout = db.query(PayoutRequest).filter(PayoutRequest.id == payout_id).first()
        if not payout:
            return None
        payout.status = status
        payout.processed_by = processed_by
        payout.processed_at = datetime.now(timezone.utc)
        payout.notes = notes

        if status == "approved":
            commissions = db.query(AffiliateCommission).filter(
                AffiliateCommission.affiliate_id == payout.affiliate_id,
                AffiliateCommission.status.in_(["pending", "approved"]),
            ).all()
            for c in commissions:
                c.status = "paid"
                c.payout_id = payout_id
                c.paid_at = datetime.now(timezone.utc)

        db.commit()
        return {
            "id": payout.id,
            "status": payout.status,
            "processed_by": payout.processed_by,
            "processed_at": payout.processed_at.isoformat() if payout.processed_at else None,
        }

    @staticmethod
    def get_payouts(db: Session, affiliate_id: Optional[str] = None, status: Optional[str] = None, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(PayoutRequest)
        if affiliate_id:
            query = query.filter(PayoutRequest.affiliate_id == affiliate_id)
        if status:
            query = query.filter(PayoutRequest.status == status)
        total = query.count()
        items = query.order_by(PayoutRequest.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": p.id,
                "affiliate_id": p.affiliate_id,
                "amount": p.amount,
                "currency": p.currency,
                "payment_method": p.payment_method,
                # L-3 FIX: إخفاء payment_details الحساسة (أرقام حسابات، بيانات بنكية)
                "payment_details": {"masked": True} if p.payment_details else None,
                "status": p.status,
                "processed_by": p.processed_by,
                "processed_at": p.processed_at.isoformat() if p.processed_at else None,
                "notes": p.notes,
                "created_at": p.created_at.isoformat(),
            }
            for p in items
        ], total

    @staticmethod
    def get_revenue_share(db: Session, partner_id: str, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(RevenueShare).filter(RevenueShare.partner_id == partner_id)
        total = query.count()
        items = query.order_by(RevenueShare.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": r.id,
                "transaction_id": r.transaction_id,
                "revenue_amount": r.revenue_amount,
                "commission_rate": r.commission_rate,
                "commission_amount": r.commission_amount,
                "tier_name": r.tier_name,
                "status": r.status,
                "created_at": r.created_at.isoformat(),
            }
            for r in items
        ], total
