from decimal import Decimal
from typing import Optional

from sqlalchemy.orm import Session

from app.core.logging import get_logger
from app.domain.models import AffiliateCommission, CommissionTier, User

logger = get_logger(__name__)


class CommissionEngine:
    def __init__(self, db: Session):
        self.db = db

    def calculate_commission(self, referrer_id: str, order_amount_coins: int) -> list[dict]:
        commissions = []
        referrer = self.db.query(User).filter(User.id == referrer_id).first()
        if not referrer:
            return commissions

        tier = self.db.query(CommissionTier).filter(
            CommissionTier.is_active == True,
        ).order_by(CommissionTier.min_referrals.desc()).first()

        if not tier:
            tier_rate = 0.10
        else:
            tier_rate = tier.commission_rate

        direct_commission = int(order_amount_coins * tier_rate)
        if direct_commission > 0:
            commissions.append({
                "user_id": referrer_id,
                "level": 1,
                "rate": tier_rate,
                "amount": direct_commission,
            })

        upline = self._get_upline_commission(referrer_id, order_amount_coins)
        commissions.extend(upline)

        return commissions

    def _get_upline_commission(self, user_id: str, order_amount: int) -> list[dict]:
        commissions = []
        referral = self.db.query(AffiliateCommission).filter(
            AffiliateCommission.user_id == user_id,
        ).first()
        if not referral or not referral.parent_id:
            return commissions

        parent_rates = {2: 0.03, 3: 0.01}
        for level, rate in parent_rates.items():
            amount = int(order_amount * rate)
            if amount > 0:
                commissions.append({
                    "user_id": referral.parent_id,
                    "level": level,
                    "rate": rate,
                    "amount": amount,
                })
        return commissions

    def record_commission(self, referrer_id: str, referred_user_id: str,
                          order_id: str, amount_coins: int,
                          description: str = "") -> list[AffiliateCommission]:
        calculated = self.calculate_commission(referrer_id, amount_coins)
        commissions = []
        for c in calculated:
            commission = AffiliateCommission(
                referrer_id=c["user_id"],
                referred_id=referred_user_id,
                order_id=order_id,
                amount_coins=c["amount"],
                level=c["level"],
                rate=c["rate"],
                status="pending",
                description=description or f"Commission Level {c['level']}",
            )
            self.db.add(commission)
            commissions.append(commission)
        self.db.commit()
        return commissions

    def get_pending_commissions(self, user_id: str) -> int:
        pending = self.db.query(AffiliateCommission).filter(
            AffiliateCommission.referrer_id == user_id,
            AffiliateCommission.status == "pending",
        ).count()
        return pending

    def get_total_earned(self, user_id: str) -> int:
        from sqlalchemy import func
        total = self.db.query(func.sum(AffiliateCommission.amount_coins)).filter(
            AffiliateCommission.referrer_id == user_id,
            AffiliateCommission.status == "approved",
        ).scalar() or 0
        return int(total)
