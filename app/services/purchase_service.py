import asyncio
from dataclasses import dataclass
from typing import Optional

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.config import get_settings, get_app_setting
from app.core.exceptions import AppException
from app.core.logging import get_logger
from app.domain.models import AuditLog, Referral, SMSOrder, Transaction, User, gen_uuid
from app.infrastructure.providers import ProviderRouter, PurchaseResult
from app.services.audit_service import AuditService
from app.services.webhook_service import WebhookService

logger = get_logger(__name__)
provider_router = ProviderRouter()


@dataclass
class PriceResult:
    provider: str
    provider_cost: float
    cost_coins: int


class PurchaseService:
    def __init__(self, db: Optional[Session]):
        self.db = db
        self.settings = get_settings()
        self.coins_per_usd = get_app_setting(db, "coins_per_usd", self.settings.coins_per_usd) if db else self.settings.coins_per_usd
        self.default_markup = get_app_setting(db, "default_markup", self.settings.default_markup) if db else self.settings.default_markup

    async def get_best_price(self, service: str, country: str,
                              user: Optional[User] = None) -> Optional[PriceResult]:
        best = None
        for provider in provider_router.enabled_providers:
            try:
                prices = await provider.get_services(country)
                for price in prices:
                    if price.service_id == service.lower():
                        cost_coins = self._provider_cost_to_coins(price.cost, user, service, country, provider.name)
                        if best is None or price.cost < best.provider_cost:
                            best = PriceResult(
                                provider=provider.name,
                                provider_cost=price.cost,
                                cost_coins=cost_coins,
                            )
                        break
            except Exception as e:
                logger.warning(f"[{provider.name}] get_services failed for {service}/{country}: {e}")
                continue
        return best

    async def purchase(
        self, user: User, service: str, country: str,
        preferred_provider: Optional[str] = None,
        ip_address: str = "",
        request_id: str = "",
    ) -> dict:
        if preferred_provider:
            provider = await provider_router.get_provider(preferred_provider)
            if not provider or not provider.enabled:
                raise AppException("PROVIDER_DISABLED", f"المزوّد '{preferred_provider}' غير متاح")
            try:
                result = await provider.purchase_number(service, country)
            except Exception:
                raise AppException("PROVIDER_ERROR", f"المزوّد {preferred_provider} غير متاح حالياً", status_code=502)
            try:
                prices = await provider.get_services(country)
                provider_cost = None
                for p in prices:
                    if p.service_id == service.lower():
                        provider_cost = p.cost
                        break
                cost_coins = self._provider_cost_to_coins(provider_cost, user, service, country, preferred_provider) if provider_cost else self._provider_cost_to_coins(result.cost, user, service, country, preferred_provider)
            except Exception:
                cost_coins = self._provider_cost_to_coins(result.cost, user, service, country, preferred_provider)
            self._lock_user(user)
            self._deduct_coins(user, cost_coins, f"SMS: {service} ({country}) via {preferred_provider}")
            order = self._save_order(user, service, country, result, cost_coins)
            self.db.commit()
            self.db.refresh(order)
            AuditService.log(self.db, user.id, "sms.purchase", "sms_order", order.id, {"service": service, "country": country, "provider": preferred_provider, "cost_coins": cost_coins, "phone_number": result.phone_number}, ip_address, request_id)
            self._reward_referrer(user.id, cost_coins)
            self._dispatch_webhook(order, user)
            return self._format_response(order)

        best = await self.get_best_price(service, country)
        if not best:
            raise AppException("SERVICE_UNAVAILABLE", f"لا يوجد مزوّد متاح لـ {service}/{country}")

        self._lock_user(user)

        last_error = None
        for provider in provider_router.enabled_providers:
            try:
                result = await provider.purchase_number(service, country)
                actual_coins = self._provider_cost_to_coins(result.cost, user, service, country, provider.name)
                if user.coins < actual_coins:
                    raise AppException("INSUFFICIENT_BALANCE", "رصيد غير كافٍ", status_code=402)
                tx = self._deduct_coins(user, actual_coins, f"SMS: {service} ({country}) via {provider.name}")
                order = self._save_order(user, service, country, result, actual_coins)
                self.db.commit()
                self.db.refresh(order)
                logger.info(
                    f"Purchase success: order={order.id} phone={result.phone_number} "
                    f"provider={provider.name} cost={actual_coins} coins"
                )
                AuditService.log(self.db, user.id, "sms.purchase", "sms_order", order.id, {"service": service, "country": country, "provider": provider.name, "cost_coins": actual_coins, "phone_number": result.phone_number}, ip_address, request_id)
                self._reward_referrer(user.id, actual_coins)
                self._dispatch_webhook(order, user)
                return self._format_response(order)
            except Exception as e:
                logger.warning(f"[{provider.name}] Purchase failed for {service}/{country}: {e}")
                last_error = e
                continue

        raise AppException("ALL_PROVIDERS_FAILED", "جميع المزوّدين غير متاحين حالياً، حاول لاحقاً", status_code=503)

    def _dispatch_webhook(self, order: SMSOrder, user: User):
        try:
            ws = WebhookService(self.db)
            asyncio.ensure_future(ws.dispatch_event("order.purchased", {
                "order_id": order.id,
                "service": order.service,
                "country": order.country,
                "phone_number": order.phone_number,
                "provider": order.provider,
                "cost_coins": order.cost_coins,
                "status": order.status,
            }, user.id))
        except Exception as e:
            logger.warning(f"Webhook dispatch failed for order {order.id}: {e}")

    def _provider_cost_to_coins(self, cost: float, user: Optional[User] = None,
                                 service: str = "", country: str = "", provider: str = "") -> int:
        from app.services.price_calculator import _resolve_markup
        if user and service and country:
            markup = _resolve_markup(self.db, service, country, provider, user.tier)
        else:
            markup = self.default_markup
        coins = max(1, round(cost * self.coins_per_usd * markup))
        return coins

    def _lock_user(self, user: User):
        self.db.execute(
            text("SELECT coins FROM users WHERE id = :uid FOR UPDATE"),
            {"uid": user.id},
        )
        self.db.refresh(user)

    def _deduct_coins(self, user: User, amount: int, description: str) -> Transaction:
        if user.coins < amount:
            raise AppException("INSUFFICIENT_BALANCE", "رصيد غير كافٍ", status_code=402)
        coins_before = user.coins
        user.coins -= amount
        tx = Transaction(
            id=gen_uuid(),
            user_id=user.id,
            amount=-amount,
            type="sms_purchase",
            description=description,
            coins_before=coins_before,
            coins_after=user.coins,
        )
        self.db.add(tx)
        return tx

    def _save_order(self, user: User, service: str, country: str,
                    result: PurchaseResult, cost_coins: int) -> SMSOrder:
        order = SMSOrder(
            id=gen_uuid(),
            user_id=user.id,
            service=service,
            country=country,
            provider=result.provider,
            phone_number=result.phone_number,
            status="pending",
            cost_coins=cost_coins,
            activation_id=result.order_id,
            provider_response=result.metadata,
        )
        self.db.add(order)
        return order

    async def check_status(self, order_id: str) -> Optional[dict]:
        order = self.db.query(SMSOrder).filter(SMSOrder.id == order_id).first()
        if not order or order.status not in ("pending", "waiting"):
            return None
        provider = await provider_router.get_provider(order.provider)
        if not provider:
            return None
        try:
            message = await provider.check_sms(order.activation_id)
            if message and message.code:
                return {"code": message.code, "text": message.text or ""}
        except Exception as e:
            logger.warning(f"check_status failed for order {order_id}: {e}")
        return None

    def refund_coins(self, user: User, amount: int, description: str) -> Transaction:
        self._lock_user(user)
        coins_before = user.coins
        user.coins += amount
        tx = Transaction(
            id=gen_uuid(),
            user_id=user.id,
            amount=amount,
            type="sms_refund",
            description=description,
            coins_before=coins_before,
            coins_after=user.coins,
        )
        self.db.add(tx)
        return tx

    def _reward_referrer(self, user_id: str, cost_coins: int):
        try:
            referral = self.db.query(Referral).filter(
                Referral.referred_id == user_id,
                Referral.status == "pending",
            ).with_for_update().first()
            if referral:
                reward = max(1, int(cost_coins * 0.10))
                self.db.execute(
                    text("SELECT coins FROM users WHERE id = :uid FOR UPDATE"),
                    {"uid": referral.referrer_id},
                )
                referrer = self.db.query(User).filter(User.id == referral.referrer_id).first()
                if referrer:
                    referrer.coins += reward
                    referral.reward_coins = reward
                    referral.status = "completed"
                    self.db.commit()
                    AuditService.log(self.db, referrer.id, "referral.complete", "referral", referral.id,
                                   {"referred_id": user_id, "reward_coins": reward, "cost_coins": cost_coins}, "", "")
        except Exception as e:
            logger.warning(f"Referral reward failed for user {user_id}: {e}")

    def _format_response(self, order: SMSOrder) -> dict:
        return {
            "order_id": order.id,
            "phone_number": order.phone_number,
            "provider": order.provider,
            "status": order.status,
            "cost_coins": order.cost_coins,
            "activation_id": order.activation_id,
            "created_at": order.created_at.isoformat() if order.created_at else None,
        }
