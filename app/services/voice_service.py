from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.config import get_settings, get_app_setting
from app.core.exceptions import AppException
from app.domain.models import SMSOrder, User, gen_uuid
from app.infrastructure.providers import ProviderRouter
from app.services.audit_service import AuditService


class VoiceService:
    def __init__(self, db: Session):
        self.db = db
        self.settings = get_settings()
        self.coins_per_usd = get_app_setting(db, "coins_per_usd", self.settings.coins_per_usd)
        self.default_markup = get_app_setting(db, "default_markup", self.settings.default_markup)
        self.provider_router = ProviderRouter()

    async def get_voice_services(self):
        voice_providers = [p for p in self.provider_router.enabled_providers if p.supports_voice]
        all_services = {}
        for p in voice_providers:
            try:
                services = await p.get_services("US")
                for s in services:
                    sid = s.service_id
                    if sid not in all_services:
                        all_services[sid] = {
                            "id": sid,
                            "name": s.service_name,
                            "prices": {},
                        }
                    all_services[sid]["prices"][p.name] = s.cost
            except Exception:
                continue
        return list(all_services.values())

    async def purchase_voice(
        self, user: User, service: str, country: str,
        ip_address: str = "", request_id: str = "",
    ) -> dict:
        voice_providers = [p for p in self.provider_router.enabled_providers if p.supports_voice]
        if not voice_providers:
            raise AppException("SERVICE_UNAVAILABLE", "لا يوجد مزود صوتي متاح حالياً", 503)

        best_price = None
        preferred_provider = None
        for p in voice_providers:
            try:
                price = await p.get_price(service, country)
                if best_price is None or price < best_price:
                    best_price = price
                    preferred_provider = p.name
            except Exception:
                continue

        if not preferred_provider or best_price is None:
            raise AppException("SERVICE_UNAVAILABLE", "لا تتوفر هذه الخدمة الصوتية حالياً", 404)

        markup = self.default_markup
        cost_coins = int(best_price * markup * self.coins_per_usd)

        self.db.execute(
            text("SELECT coins FROM users WHERE id = :uid FOR UPDATE"),
            {"uid": user.id},
        )
        self.db.refresh(user)
        if user.coins < cost_coins:
            raise AppException("INSUFFICIENT_BALANCE", "رصيدك غير كافٍ", 402)

        provider_obj = None
        result = None
        for p in voice_providers:
            if p.name == preferred_provider:
                try:
                    result = await p.purchase_number(service, country)
                    provider_obj = p
                    break
                except Exception:
                    continue

        if not provider_obj or not result:
            raise AppException("PROVIDER_ERROR", "جميع المزودين غير متاحين حالياً", 502)

        user.coins -= cost_coins
        order = SMSOrder(
            id=gen_uuid(),
            user_id=user.id,
            service=service,
            country=country,
            provider=provider_obj.name,
            phone_number=result.phone_number,
            type="voice",
            status="pending",
            cost_coins=cost_coins,
            activation_id=result.order_id,
        )
        self.db.add(order)
        self.db.commit()

        AuditService.log(self.db, user.id, "voice.purchase", "sms_order", order.id,
                       {"service": service, "country": country, "provider": provider_obj.name,
                        "cost_coins": cost_coins, "phone_number": result.phone_number},
                       ip_address, request_id)

        return {
            "order_id": order.id,
            "phone_number": result.phone_number,
            "cost_coins": cost_coins,
            "balance": user.coins,
            "status": "pending",
        }
