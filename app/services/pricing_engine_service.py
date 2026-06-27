from datetime import datetime, timezone
from typing import Optional

from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.domain.models import (
    PricingHistory,
    PricingTemplate,
    PromoCodeUsage,
    ServicePromotion,
    TierPricing,
    UserPricingAssignment,
    gen_uuid,
)


class PricingEngineService:
    @staticmethod
    def get_templates(db: Session, page: int = 1, per_page: int = 20, is_active: Optional[bool] = None, is_promo: Optional[bool] = None) -> tuple[list[dict], int]:
        query = db.query(PricingTemplate)
        if is_active is not None:
            query = query.filter(PricingTemplate.is_active == is_active)
        if is_promo is not None:
            query = query.filter(PricingTemplate.is_promo == is_promo)
        total = query.count()
        templates = query.order_by(PricingTemplate.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
        return [t.to_dict() for t in templates], total

    @staticmethod
    def get_template(db: Session, template_id: str) -> Optional[dict]:
        template = db.query(PricingTemplate).filter(PricingTemplate.id == template_id).first()
        if not template:
            return None
        result = template.to_dict()
        result["tiers"] = [
            {
                "id": t.id,
                "tier_name": t.tier_name,
                "monthly_price": t.monthly_price,
                "included_quota_usd": t.included_quota_usd,
                "overage_rate": t.overage_rate,
                "features": t.features or [],
            }
            for t in db.query(TierPricing).filter(TierPricing.template_id == template_id).all()
        ]
        result["assignments"] = db.query(UserPricingAssignment).filter(UserPricingAssignment.template_id == template_id).count()
        return result

    @staticmethod
    def _validate_template_data(data: dict):
        markup = data.get("markup_multiplier", 1.15)
        if not isinstance(markup, (int, float)) or markup < 1.0:
            raise AppException(code="validation_error", message="markup_multiplier يجب أن يكون >= 1.0")
        discount = data.get("discount_percentage", 0.0)
        if not isinstance(discount, (int, float)) or discount < 0 or discount > 100:
            raise AppException(code="validation_error", message="discount_percentage يجب أن يكون بين 0 و 100")
        promo_max = data.get("promo_max_uses")
        if promo_max is not None and (not isinstance(promo_max, int) or promo_max < 1):
            raise AppException(code="validation_error", message="promo_max_uses يجب أن يكون >= 1")
        max_assign = data.get("max_assignments")
        if max_assign is not None and (not isinstance(max_assign, int) or max_assign < 1):
            raise AppException(code="validation_error", message="max_assignments يجب أن يكون >= 1")

    @staticmethod
    def create_template(db: Session, data: dict, changed_by: str) -> dict:
        PricingEngineService._validate_template_data(data)
        template = PricingTemplate(
            id=gen_uuid(),
            name=data["name"],
            description=data.get("description"),
            markup_multiplier=data.get("markup_multiplier", 1.15),
            discount_percentage=data.get("discount_percentage", 0.0),
            region=data.get("region"),
            currency=data.get("currency", "USD"),
            is_promo=data.get("is_promo", False),
            promo_code=data.get("promo_code"),
            promo_max_uses=data.get("promo_max_uses"),
            promo_expires_at=data.get("promo_expires_at"),
            effective_date=data.get("effective_date") or datetime.now(timezone.utc),
            max_assignments=data.get("max_assignments"),
        )
        db.add(template)
        db.flush()

        for tier_data in data.get("tiers", []):
            db.add(TierPricing(
                id=gen_uuid(),
                template_id=template.id,
                tier_name=tier_data["tier_name"],
                monthly_price=tier_data.get("monthly_price", 0.0),
                included_quota_usd=tier_data.get("included_quota_usd", 0.0),
                overage_rate=tier_data.get("overage_rate", 0.0),
                features=tier_data.get("features", []),
            ))

        db.add(PricingHistory(
            id=gen_uuid(),
            template_id=template.id,
            action="created",
            changed_by=changed_by,
            snapshot_after=template.to_dict(),
        ))
        db.commit()
        db.refresh(template)
        return template.to_dict()

    @staticmethod
    def update_template(db: Session, template_id: str, data: dict, changed_by: str) -> Optional[dict]:
        template = db.query(PricingTemplate).filter(PricingTemplate.id == template_id).first()
        if not template:
            return None

        PricingEngineService._validate_template_data(data)

        snapshot_before = template.to_dict()

        updatable = [
            "name", "description", "markup_multiplier", "discount_percentage",
            "region", "currency", "is_promo", "promo_code", "promo_max_uses",
            "promo_expires_at", "effective_date", "max_assignments",
        ]
        for key in updatable:
            if key in data:
                setattr(template, key, data[key])

        if "tiers" in data:
            db.query(TierPricing).filter(TierPricing.template_id == template_id).delete()
            for tier_data in data["tiers"]:
                db.add(TierPricing(
                    id=gen_uuid(),
                    template_id=template_id,
                    tier_name=tier_data["tier_name"],
                    monthly_price=tier_data.get("monthly_price", 0.0),
                    included_quota_usd=tier_data.get("included_quota_usd", 0.0),
                    overage_rate=tier_data.get("overage_rate", 0.0),
                    features=tier_data.get("features", []),
                ))

        db.add(PricingHistory(
            id=gen_uuid(),
            template_id=template_id,
            action="updated",
            changed_by=changed_by,
            snapshot_before=snapshot_before,
            snapshot_after=template.to_dict(),
        ))
        db.commit()
        db.refresh(template)
        return template.to_dict()

    @staticmethod
    def delete_template(db: Session, template_id: str, changed_by: str) -> bool:
        template = db.query(PricingTemplate).filter(PricingTemplate.id == template_id).first()
        if not template:
            return False

        db.add(PricingHistory(
            id=gen_uuid(),
            template_id=template_id,
            action="deleted",
            changed_by=changed_by,
            snapshot_before=template.to_dict(),
        ))
        db.query(UserPricingAssignment).filter(UserPricingAssignment.template_id == template_id).delete()
        db.query(TierPricing).filter(TierPricing.template_id == template_id).delete()
        db.delete(template)
        db.commit()
        return True

    @staticmethod
    def activate_template(db: Session, template_id: str) -> Optional[dict]:
        db.query(PricingTemplate).filter(PricingTemplate.is_active == True).update({"is_active": False})
        template = db.query(PricingTemplate).filter(PricingTemplate.id == template_id).first()
        if not template:
            return None
        template.is_active = True
        db.commit()
        db.refresh(template)
        return template.to_dict()

    @staticmethod
    def assign_user(db: Session, user_id: str, template_id: str, expires_at: Optional[datetime] = None) -> dict:
        existing = db.query(UserPricingAssignment).filter(UserPricingAssignment.user_id == user_id).first()
        if existing:
            existing.template_id = template_id
            existing.expires_at = expires_at
        else:
            db.add(UserPricingAssignment(
                user_id=user_id,
                template_id=template_id,
                expires_at=expires_at,
            ))
        db.commit()
        return {"user_id": user_id, "template_id": template_id, "expires_at": expires_at}

    @staticmethod
    def unassign_user(db: Session, user_id: str) -> bool:
        deleted = db.query(UserPricingAssignment).filter(UserPricingAssignment.user_id == user_id).delete()
        db.commit()
        return deleted > 0

    @staticmethod
    def get_user_assignments(db: Session, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(UserPricingAssignment)
        total = query.count()
        items = query.order_by(UserPricingAssignment.assigned_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
        result = []
        for a in items:
            template = db.query(PricingTemplate).filter(PricingTemplate.id == a.template_id).first()
            result.append({
                "user_id": a.user_id,
                "template_id": a.template_id,
                "template_name": template.name if template else None,
                "assigned_at": a.assigned_at.isoformat(),
                "expires_at": a.expires_at.isoformat() if a.expires_at else None,
            })
        return result, total

    @staticmethod
    def get_history(db: Session, template_id: str, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(PricingHistory).filter(PricingHistory.template_id == template_id)
        total = query.count()
        items = query.order_by(PricingHistory.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": h.id,
                "action": h.action,
                "changed_by": h.changed_by,
                "notes": h.notes,
                "snapshot_before": h.snapshot_before,
                "snapshot_after": h.snapshot_after,
                "created_at": h.created_at.isoformat(),
            }
            for h in items
        ], total

    @staticmethod
    def get_active_promotions(db: Session, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(ServicePromotion).filter(ServicePromotion.is_active == True)
        total = query.count()
        items = query.order_by(ServicePromotion.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": p.id,
                "service": p.service,
                "country": p.country,
                "discount_percentage": p.discount_percentage,
                "original_price": p.original_price,
                "promotional_price": p.promotional_price,
                "max_uses": p.max_uses,
                "used_count": p.used_count,
                "starts_at": p.starts_at.isoformat(),
                "expires_at": p.expires_at.isoformat(),
                "is_active": p.is_active,
            }
            for p in items
        ], total

    @staticmethod
    def create_promotion(db: Session, data: dict) -> dict:
        discount_pct = data.get("discount_percentage", 0)
        original_price = data.get("original_price", 0)
        promotional_price = data.get("promotional_price", 0)
        if not isinstance(discount_pct, (int, float)) or discount_pct < 0 or discount_pct > 100:
            raise AppException("validation_error", "discount_percentage must be between 0 and 100")
        if not isinstance(original_price, (int, float)) or original_price < 0:
            raise AppException("validation_error", "original_price must be non-negative")
        if not isinstance(promotional_price, (int, float)) or promotional_price < 0:
            raise AppException("validation_error", "promotional_price must be non-negative")
        if promotional_price > original_price:
            raise AppException("validation_error", "promotional_price must be <= original_price")
        promo = ServicePromotion(
            id=gen_uuid(),
            service=data["service"],
            country=data.get("country"),
            discount_percentage=discount_pct,
            original_price=original_price,
            promotional_price=promotional_price,
            max_uses=data.get("max_uses"),
            starts_at=data["starts_at"],
            expires_at=data["expires_at"],
        )
        db.add(promo)
        db.commit()
        db.refresh(promo)
        return {
            "id": promo.id,
            "service": promo.service,
            "country": promo.country,
            "discount_percentage": promo.discount_percentage,
            "original_price": promo.original_price,
            "promotional_price": promo.promotional_price,
            "max_uses": promo.max_uses,
            "used_count": promo.used_count,
            "starts_at": promo.starts_at.isoformat(),
            "expires_at": promo.expires_at.isoformat(),
            "is_active": promo.is_active,
        }

    @staticmethod
    def toggle_promotion(db: Session, promotion_id: str) -> Optional[dict]:
        promo = db.query(ServicePromotion).filter(ServicePromotion.id == promotion_id).first()
        if not promo:
            return None
        promo.is_active = not promo.is_active
        db.commit()
        db.refresh(promo)
        return {
            "id": promo.id,
            "service": promo.service,
            "is_active": promo.is_active,
        }

    @staticmethod
    def validate_promo_code(db: Session, code: str, user_id: str) -> dict:
        template = db.query(PricingTemplate).filter(
            PricingTemplate.promo_code == code,
            PricingTemplate.is_promo == True,
        ).first()
        if not template:
            return {"valid": False, "reason": "رمز ترويجي غير صالح"}

        if not template.is_active:
            return {"valid": False, "reason": "الرمز الترويجي غير نشط"}

        if template.promo_expires_at and template.promo_expires_at < datetime.now(timezone.utc):
            return {"valid": False, "reason": "انتهت صلاحية الرمز الترويجي"}

        if template.promo_max_uses and template.promo_used_count >= template.promo_max_uses:
            return {"valid": False, "reason": "تم استنفاذ عدد استخدامات الرمز الترويجي"}

        if template.max_assignments:
            current = db.query(UserPricingAssignment).filter(UserPricingAssignment.template_id == template.id).count()
            if current >= template.max_assignments:
                return {"valid": False, "reason": "تم بلوغ الحد الأقصى للتعيينات"}

        return {
            "valid": True,
            "template": template.to_dict(),
            "discount_percentage": template.discount_percentage,
        }

    @staticmethod
    def apply_promo_code(db: Session, code: str, user_id: str, order_id: Optional[str] = None) -> dict:
        validation = PricingEngineService.validate_promo_code(db, code, user_id)
        if not validation["valid"]:
            return validation

        template = db.query(PricingTemplate).filter(
            PricingTemplate.promo_code == code,
        ).with_for_update().first()
        if not template:
            return {"valid": False, "reason": "رمز ترويجي غير صالح"}
        if template.promo_max_uses and (template.promo_used_count or 0) >= template.promo_max_uses:
            return {"valid": False, "reason": "تم استنفاذ عدد استخدامات الرمز الترويجي"}
        if template.max_assignments:
            current = db.query(UserPricingAssignment).filter(UserPricingAssignment.template_id == template.id).count()
            if current >= template.max_assignments:
                return {"valid": False, "reason": "تم بلوغ الحد الأقصى للتعيينات"}

        PricingEngineService.assign_user(db, user_id, template.id)

        template.promo_used_count = (template.promo_used_count or 0) + 1
        db.commit()

        return {
            "valid": True,
            "template_id": template.id,
            "discount_percentage": template.discount_percentage,
            "message": "تم تطبيق الرمز الترويجي بنجاح",
        }

    @staticmethod
    def get_promo_usage(db: Session, template_id: str, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(PromoCodeUsage).filter(PromoCodeUsage.template_id == template_id)
        total = query.count()
        items = query.order_by(PromoCodeUsage.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": u.id,
                "user_id": u.user_id,
                "order_id": u.order_id,
                "discount_amount": u.discount_amount,
                "original_amount": u.original_amount,
                "created_at": u.created_at.isoformat(),
            }
            for u in items
        ], total

    @staticmethod
    def get_pricing_for_user(db: Session, user_id: str) -> dict:
        assignment = db.query(UserPricingAssignment).filter(UserPricingAssignment.user_id == user_id).first()
        if not assignment:
            return {"has_custom_pricing": False, "pricing": None}

        template = db.query(PricingTemplate).filter(PricingTemplate.id == assignment.template_id).first()
        if not template or not template.is_active:
            return {"has_custom_pricing": False, "pricing": None}

        if assignment.expires_at and assignment.expires_at < datetime.now(timezone.utc):
            return {"has_custom_pricing": False, "pricing": None}

        tiers = db.query(TierPricing).filter(TierPricing.template_id == template.id).all()
        return {
            "has_custom_pricing": True,
            "pricing": {
                "template_name": template.name,
                "discount_percentage": template.discount_percentage,
                "markup_multiplier": template.markup_multiplier,
                "currency": template.currency,
                "tiers": [
                    {
                        "tier_name": t.tier_name,
                        "monthly_price": t.monthly_price,
                        "included_quota_usd": t.included_quota_usd,
                        "overage_rate": t.overage_rate,
                        "features": t.features or [],
                    }
                    for t in tiers
                ],
            },
        }

    @staticmethod
    def calculate_price(db: Session, user_id: str, service: str, base_cost: float) -> dict:
        pricing = PricingEngineService.get_pricing_for_user(db, user_id)
        if pricing["has_custom_pricing"]:
            markup = pricing["pricing"]["markup_multiplier"]
            discount = pricing["pricing"]["discount_percentage"]
        else:
            markup = 1.15
            discount = 0.0

        active_promo = db.query(ServicePromotion).filter(
            ServicePromotion.service == service,
            ServicePromotion.is_active == True,
            ServicePromotion.starts_at <= datetime.now(timezone.utc),
            ServicePromotion.expires_at >= datetime.now(timezone.utc),
        ).first()

        if active_promo and (not active_promo.max_uses or active_promo.used_count < active_promo.max_uses):
            final_price = active_promo.promotional_price
            return {
                "base_cost": base_cost,
                "final_price": final_price,
                "markup_multiplier": 1.0,
                "discount_percentage": active_promo.discount_percentage,
                "promotion_applied": True,
                "promotion_id": active_promo.id,
            }

        raw_price = base_cost * markup
        final_price = raw_price * (1 - discount / 100)
        return {
            "base_cost": base_cost,
            "final_price": round(final_price, 4),
            "markup_multiplier": markup,
            "discount_percentage": discount,
            "promotion_applied": False,
        }
