from datetime import datetime, timezone, timedelta
from typing import Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.domain.models import SMSOrder, User, TempEmail


class QuotaService:
    def __init__(self, db: Session):
        self.db = db

    def get_daily_order_count(self, user_id: str) -> int:
        today = datetime.now(timezone.utc).date()
        return self.db.query(func.count(SMSOrder.id)).filter(
            SMSOrder.user_id == user_id,
            func.date(SMSOrder.created_at) == today,
        ).scalar() or 0

    def get_monthly_order_count(self, user_id: str) -> int:
        now = datetime.now(timezone.utc)
        month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        return self.db.query(func.count(SMSOrder.id)).filter(
            SMSOrder.user_id == user_id,
            SMSOrder.created_at >= month_start,
        ).scalar() or 0

    def get_remaining_daily(self, user_id: str, tier: str = "freemium") -> int:
        # L-1 FIX: توحيد قائمة التيرز مع تلك المعيّنة في admin.py
        max_per_day = {
            "freemium": 20,
            "payg": 100,      # أضيف لتوحيد التيرز
            "pro": 500,       # أضيف لتوحيد التيرز
            "custom": 1000,   # أضيف لتوحيد التيرز
            # للتوافق مع الإصدارات القديمة
            "basic": 100,
            "premium": 500,
            "enterprise": 99999,
        }
        used = self.get_daily_order_count(user_id)
        limit = max_per_day.get(tier, 20)
        return max(0, limit - used)

    def get_remaining_monthly(self, user_id: str, tier: str = "freemium") -> int:
        max_per_month = {
            "freemium": 200,
            "payg": 1000,
            "pro": 5000,
            "custom": 10000,
            # للتوافق مع الإصدارات القديمة
            "basic": 1000,
            "premium": 5000,
            "enterprise": 999999,
        }
        used = self.get_monthly_order_count(user_id)
        limit = max_per_month.get(tier, 200)
        return max(0, limit - used)

    def check_daily_quota(self, user_id: str, tier: str = "freemium") -> bool:
        return self.get_remaining_daily(user_id, tier) > 0

    def get_temp_email_quota(self, user_id: str) -> dict:
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            return {"used": 0, "remaining": 0, "limit": 0}
        from app.core.config import get_settings
        limit = get_settings().temp_emails_per_month
        used = user.temp_emails_used
        return {"used": used, "remaining": max(0, limit - used), "limit": limit}

    def get_quota_summary(self, user_id: str, tier: str = "freemium") -> dict:
        return {
            "daily_orders": {
                "used": self.get_daily_order_count(user_id),
                "remaining": self.get_remaining_daily(user_id, tier),
            },
            "monthly_orders": {
                "used": self.get_monthly_order_count(user_id),
                "remaining": self.get_remaining_monthly(user_id, tier),
            },
            "temp_emails": self.get_temp_email_quota(user_id),
            "tier": tier,
        }
