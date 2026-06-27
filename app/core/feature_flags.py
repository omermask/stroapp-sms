import hashlib

from sqlalchemy.orm import Session

from app.domain.models import FeatureFlag, gen_uuid


class FeatureFlags:
    _defaults = {
        "new_dashboard": {"enabled": True, "strategy": "all_users", "config": None},
        "enhanced_analytics": {"enabled": False, "strategy": "admin_only", "config": None},
        "sms_forwarding": {"enabled": True, "strategy": "all_users", "config": None},
        "voice_verification": {"enabled": True, "strategy": "all_users", "config": None},
        "number_rental": {"enabled": True, "strategy": "all_users", "config": None},
        "temp_email": {"enabled": True, "strategy": "all_users", "config": None},
        "api_access": {"enabled": False, "strategy": "percentage", "config": {"percentage": 50}},
    }

    @staticmethod
    def get_flag(db: Session, name: str) -> dict:
        flag = db.query(FeatureFlag).filter(FeatureFlag.name == name).first()
        if not flag:
            default = FeatureFlags._defaults.get(name)
            if default:
                flag = FeatureFlag(
                    id=gen_uuid(), name=name,
                    enabled=default["enabled"],
                    strategy=default["strategy"],
                    config=default["config"],
                )
                db.add(flag)
                db.commit()
                return default
            return {"enabled": True, "strategy": "all_users", "config": None}
        return {"enabled": flag.enabled, "strategy": flag.strategy, "config": flag.config}

    VALID_STRATEGIES = {"all_users", "admin_only", "percentage"}

    @staticmethod
    def is_enabled(db: Session, name: str, user_id: str = None, is_admin: bool = False) -> bool:
        flag = FeatureFlags.get_flag(db, name)
        if not flag["enabled"]:
            return False
        if flag["strategy"] == "all_users":
            return True
        if flag["strategy"] == "admin_only":
            return is_admin
        if flag["strategy"] == "percentage":
            pct = (flag.get("config") or {}).get("percentage", 0)
            if not user_id:
                return False
            h = int(hashlib.sha256(user_id.encode()).hexdigest(), 16) % 100
            return h < pct
        return True

    @staticmethod
    def set_flag(db: Session, name: str, enabled: bool, strategy: str = "all_users", config: dict = None):
        if strategy not in FeatureFlags.VALID_STRATEGIES:
            raise ValueError(f"Invalid strategy '{strategy}'. Must be one of: {FeatureFlags.VALID_STRATEGIES}")
        flag = db.query(FeatureFlag).filter(FeatureFlag.name == name).first()
        if not flag:
            flag = FeatureFlag(id=gen_uuid(), name=name)
            db.add(flag)
        flag.enabled = enabled
        flag.strategy = strategy
        flag.config = config
        db.commit()

    @staticmethod
    def all_flags(db: Session) -> list[dict]:
        names = set(FeatureFlags._defaults.keys())
        for flag in db.query(FeatureFlag).all():
            names.add(flag.name)
        result = []
        for name in sorted(names):
            flag = FeatureFlags.get_flag(db, name)
            result.append({"name": name, **flag})
        return result
