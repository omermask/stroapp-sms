from typing import Optional

from sqlalchemy.orm import Session

from app.core.config import get_settings, get_app_setting
from app.domain.models import MarkupRule, ServiceCountry, User
from app.services.pricing_engine_service import PricingEngineService


def _resolve_markup(
    db: Session,
    service: str,
    country_code: str,
    provider: str,
    user_tier: Optional[str] = None,
) -> float:
    rules = (
        db.query(MarkupRule)
        .filter(MarkupRule.is_active == True)
        .order_by(MarkupRule.priority.desc())
        .all()
    )
    matched = None
    for rule in rules:
        if rule.service and rule.service != service:
            continue
        if rule.country_code and rule.country_code != country_code:
            continue
        if rule.provider and rule.provider != provider:
            continue
        if rule.user_tier and rule.user_tier != user_tier:
            continue
        matched = rule.markup_multiplier
        break

    if matched is not None:
        return matched

    default = (
        db.query(MarkupRule)
        .filter(
            MarkupRule.service.is_(None),
            MarkupRule.country_code.is_(None),
            MarkupRule.provider.is_(None),
            MarkupRule.user_tier.is_(None),
            MarkupRule.is_active == True,
        )
        .first()
    )
    return default.markup_multiplier if default else 1.20


class PriceCalculator:
    """يحسب السعر النهائي للمستخدم بناءً على:
    1. سعر المزوّد من ServiceCountry (آخر sync)
    2. Markup rules (عام / لكل خدمة / لكل بلد)
    3. Custom pricing للمستخدمين (PricingEngineService)
    4. Coins conversion
    """

    def __init__(self, db: Session):
        self.db = db
        self.settings = get_settings()
        self.coins_per_usd = get_app_setting(db, "coins_per_usd", self.coins_per_usd)
        self.default_markup = get_app_setting(db, "default_markup", self.settings.default_markup)

    def get_best_price(
        self,
        service: str,
        country_code: str,
        user: Optional[User] = None,
    ) -> Optional[dict]:
        records = (
            self.db.query(ServiceCountry)
            .filter(
                ServiceCountry.service == service,
                ServiceCountry.country_code == country_code,
                ServiceCountry.is_active == True,
            )
            .order_by(ServiceCountry.provider_cost.asc())
            .all()
        )
        if not records:
            return None

        user_tier = user.tier if user else None
        user_id = user.id if user else None

        best = None
        for rec in records:
            markup = _resolve_markup(
                self.db, service, country_code, rec.provider, user_tier,
            )
            raw_price = rec.provider_cost * markup
            coins = max(1, round(raw_price * self.coins_per_usd))

            entry = {
                "provider": rec.provider,
                "provider_cost": rec.provider_cost,
                "markup": markup,
                "raw_price_usd": round(raw_price, 4),
                "cost_coins": coins,
                "available_count": rec.available_count,
                "currency": rec.currency,
            }

            if user_id:
                custom = PricingEngineService.get_pricing_for_user(self.db, user_id)
                if custom["has_custom_pricing"]:
                    cp = custom["pricing"]
                    discount = cp.get("discount_percentage", 0)
                    if discount > 0:
                        discounted = raw_price * (1 - discount / 100)
                        entry["raw_price_usd"] = round(discounted, 4)
                        entry["cost_coins"] = max(1, round(discounted * self.coins_per_usd))
                        entry["discount_applied"] = discount

            if best is None or entry["cost_coins"] < best["cost_coins"]:
                best = entry

        return best

    def list_available(
        self,
        service: str,
        country_code: str,
        user: Optional[User] = None,
    ) -> list[dict]:
        records = (
            self.db.query(ServiceCountry)
            .filter(
                ServiceCountry.service == service,
                ServiceCountry.country_code == country_code,
                ServiceCountry.is_active == True,
            )
            .order_by(ServiceCountry.provider_cost.asc())
            .all()
        )
        results = []
        user_tier = user.tier if user else None
        for rec in records:
            markup = _resolve_markup(
                self.db, service, country_code, rec.provider, user_tier,
            )
            raw_price = rec.provider_cost * markup
            final_price_usd = round(raw_price, 4)
            coins = max(1, round(final_price_usd * self.coins_per_usd))

            results.append({
                "provider": rec.provider,
                "provider_cost": rec.provider_cost,
                "markup": markup,
                "final_price_usd": final_price_usd,
                "cost_coins": coins,
                "available_count": rec.available_count,
                "last_synced_at": rec.last_synced_at.isoformat() if rec.last_synced_at else None,
            })
        return results

    def get_services_with_prices(
        self,
        country_code: str,
        user: Optional[User] = None,
    ) -> list[dict]:
        records = (
            self.db.query(ServiceCountry)
            .filter(
                ServiceCountry.country_code == country_code,
                ServiceCountry.is_active == True,
            )
            .all()
        )
        seen: dict[str, dict] = {}
        user_tier = user.tier if user else None
        for rec in records:
            if rec.service in seen:
                existing = seen[rec.service]
                if rec.provider_cost < existing["provider_cost"]:
                    markup = _resolve_markup(
                        self.db, rec.service, country_code, rec.provider, user_tier,
                    )
                    raw = rec.provider_cost * markup
                    seen[rec.service] = {
                        "service": rec.service,
                        "provider": rec.provider,
                        "provider_cost": rec.provider_cost,
                        "cost_coins": max(1, round(raw * self.coins_per_usd)),
                    }
            else:
                markup = _resolve_markup(
                    self.db, rec.service, country_code, rec.provider, user_tier,
                )
                raw = rec.provider_cost * markup
                seen[rec.service] = {
                    "service": rec.service,
                    "provider": rec.provider,
                    "provider_cost": rec.provider_cost,
                    "cost_coins": max(1, round(raw * self.coins_per_usd)),
                }
        return list(seen.values())

    def get_best_price_for_countries(
        self,
        service: str,
        country_codes: list[str],
        user: Optional[User] = None,
    ) -> dict[str, dict]:
        if not country_codes:
            return {}
        records = (
            self.db.query(ServiceCountry)
            .filter(
                ServiceCountry.service == service,
                ServiceCountry.country_code.in_(country_codes),
                ServiceCountry.is_active == True,
            )
            .order_by(ServiceCountry.provider_cost.asc())
            .all()
        )
        user_tier = user.tier if user else None
        user_id = user.id if user else None
        results: dict[str, dict] = {}
        for rec in records:
            code = rec.country_code
            if code in results:
                continue
            markup = _resolve_markup(
                self.db, service, code, rec.provider, user_tier,
            )
            raw_price = rec.provider_cost * markup
            coins = max(1, round(raw_price * self.coins_per_usd))
            entry = {
                "service": service,
                "country": code,
                "provider": rec.provider,
                "provider_cost": rec.provider_cost,
                "markup": markup,
                "final_price_usd": round(raw_price, 4),
                "cost_coins": coins,
                "available_count": rec.available_count,
            }
            if user_id:
                custom = PricingEngineService.get_pricing_for_user(self.db, user_id)
                if custom.get("has_custom_pricing"):
                    discount = custom["pricing"].get("discount_percentage", 0)
                    if discount > 0:
                        discounted = raw_price * (1 - discount / 100)
                        entry["final_price_usd"] = round(discounted, 4)
                        entry["cost_coins"] = max(1, round(discounted * self.coins_per_usd))
                        entry["discount_applied"] = discount
            results[code] = entry
        return results

    def get_countries_for_service(self, service: str) -> list[dict]:
        records = (
            self.db.query(ServiceCountry)
            .filter(
                ServiceCountry.service == service,
                ServiceCountry.is_active == True,
            )
            .order_by(ServiceCountry.provider_cost.asc())
            .all()
        )
        seen: dict[str, dict] = {}
        for rec in records:
            if rec.country_code in seen:
                existing = seen[rec.country_code]
                if rec.provider_cost < existing["min_cost"]:
                    seen[rec.country_code] = {
                        "country_code": rec.country_code,
                        "provider": rec.provider,
                        "min_cost": rec.provider_cost,
                    }
            else:
                seen[rec.country_code] = {
                    "country_code": rec.country_code,
                    "provider": rec.provider,
                    "min_cost": rec.provider_cost,
                }
        return list(seen.values())
