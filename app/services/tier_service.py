from sqlalchemy.orm import Session

from app.domain.models import SubscriptionTier, User, gen_uuid


class TierService:
    TIER_HIERARCHY = {"freemium": 0, "payg": 1, "pro": 2, "custom": 3}

    DEFAULTS = {
        "freemium": {"name": "Freemium", "description": "حساب مجاني مع حدود يومية", "price_monthly": 0,
                     "payment_required": False, "quota_usd": 0, "has_api_access": True, "api_key_limit": 2,
                     "daily_verification_limit": 500, "monthly_verification_limit": 15000, "support_level": "community",
                     "rate_limit_per_minute": 200,
                     "features": {"area_code": False, "city_filtering": False, "webhooks": False, "priority_routing": False}},
        "payg": {"name": "Pay-As-You-Go", "description": "ادفع حسب الاستخدام بدون اشتراك", "price_monthly": 0,
                 "payment_required": False, "quota_usd": 0, "has_api_access": True, "api_key_limit": 10,
                 "daily_verification_limit": 5000, "monthly_verification_limit": 150000, "support_level": "email",
                 "rate_limit_per_minute": 1000,
                 "features": {"area_code": True, "city_filtering": False, "webhooks": True, "priority_routing": False}},
        "pro": {"name": "Pro", "description": "باقة احترافية للمطورين والشركات", "price_monthly": 2500,
                "payment_required": True, "quota_usd": 15, "has_api_access": True, "api_key_limit": 25,
                "daily_verification_limit": 15000, "monthly_verification_limit": 450000, "support_level": "priority",
                "rate_limit_per_minute": 2000,
                "features": {"area_code": True, "city_filtering": True, "webhooks": True, "priority_routing": True}},
        "custom": {"name": "Custom", "description": "حل مخصص للشركات الكبرى", "price_monthly": 3500,
                   "payment_required": True, "quota_usd": 25, "has_api_access": True, "api_key_limit": 100,
                   "daily_verification_limit": 50000, "monthly_verification_limit": 1500000, "support_level": "dedicated",
                   "rate_limit_per_minute": 5000,
                   "features": {"area_code": True, "city_filtering": True, "webhooks": True, "priority_routing": True}},
    }

    @staticmethod
    def seed_tiers(db: Session):
        for tier_name, cfg in TierService.DEFAULTS.items():
            existing = db.query(SubscriptionTier).filter(SubscriptionTier.tier == tier_name).first()
            if not existing:
                db.add(SubscriptionTier(
                    id=gen_uuid(), tier=tier_name, **cfg, is_active=True,
                ))
        db.commit()

    @staticmethod
    def get_user_tier_config(db: Session, user: User) -> dict:
        tier_name = user.tier or "freemium"
        tier = db.query(SubscriptionTier).filter(
            SubscriptionTier.tier == tier_name,
            SubscriptionTier.is_active == True,
        ).first()
        if tier:
            return {
                "tier": tier.tier,
                "name": tier.name,
                "has_api_access": tier.has_api_access,
                "api_key_limit": tier.api_key_limit,
                "daily_verification_limit": tier.daily_verification_limit,
                "monthly_verification_limit": tier.monthly_verification_limit,
                "support_level": tier.support_level,
                "rate_limit_per_minute": tier.rate_limit_per_minute,
                "features": tier.features or {},
            }
        default = TierService.DEFAULTS.get(tier_name, TierService.DEFAULTS["freemium"])
        return {"tier": tier_name, **default, "features": default.get("features", {})}

    @staticmethod
    def check_feature_access(db: Session, user: User, feature: str) -> bool:
        config = TierService.get_user_tier_config(db, user)
        features = config.get("features", {})
        return features.get(feature, False)

    @staticmethod
    def check_hierarchy(current_tier: str, required_tier: str) -> bool:
        current_level = TierService.TIER_HIERARCHY.get(current_tier, 0)
        required_level = TierService.TIER_HIERARCHY.get(required_tier, 0)
        return current_level >= required_level

    @staticmethod
    def all_tiers(db: Session) -> list[dict]:
        tiers = db.query(SubscriptionTier).all()
        if not tiers:
            TierService.seed_tiers(db)
            tiers = db.query(SubscriptionTier).all()
        tiers.sort(key=lambda t: TierService.TIER_HIERARCHY.get(t.tier, 99))
        return [
            {
                "tier": t.tier,
                "name": t.name,
                "description": t.description,
                "price_monthly": t.price_monthly,
                "payment_required": t.payment_required,
                "quota_usd": t.quota_usd,
                "has_api_access": t.has_api_access,
                "api_key_limit": t.api_key_limit,
                "daily_verification_limit": t.daily_verification_limit,
                "monthly_verification_limit": t.monthly_verification_limit,
                "support_level": t.support_level,
                "rate_limit_per_minute": t.rate_limit_per_minute,
                "features": t.features or {},
            }
            for t in tiers
        ]
