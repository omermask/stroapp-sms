import asyncio
from datetime import datetime, timezone, timedelta
from typing import Optional

from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.core.logging import get_logger
from app.domain.models import AuditLog, NumberRental, SMSOrder, User
from app.infrastructure.providers import ProviderRouter
from app.services.audit_service import AuditService
from app.services.purchase_service import PurchaseService

logger = get_logger(__name__)
provider_router = ProviderRouter()


class SMSPollingService:
    def __init__(self):
        self._tasks: dict[str, asyncio.Task] = {}

    async def start(self, order_id: str, activation_id: str, provider_name: str):
        task = asyncio.create_task(self._poll_loop(order_id, activation_id, provider_name))
        # N-3 FIX: تنظيف المهمة من الـ dict بعد اكتمالها لمنع Memory Leak
        task.add_done_callback(lambda t: self._tasks.pop(order_id, None))
        self._tasks[order_id] = task
        logger.info(f"Polling started for order {order_id} via {provider_name}")

    async def _poll_loop(self, order_id: str, activation_id: str, provider_name: str):
        provider = await provider_router.get_provider(provider_name)
        if not provider:
            logger.error(f"Polling cannot start: provider {provider_name} not found")
            return

        timeout_minutes = 10
        start = datetime.now(timezone.utc)

        while (datetime.now(timezone.utc) - start).total_seconds() < timeout_minutes * 60:
            try:
                message = await provider.check_sms(activation_id)
                if message and message.code:
                    db = SessionLocal()
                    try:
                        order = db.query(SMSOrder).filter(SMSOrder.id == order_id).first()
                        if order and order.status == "pending":
                            order.status = "completed"
                            order.verification_code = message.code
                            order.sms_text = message.text
                            order.sms_received_at = datetime.now(timezone.utc)
                            db.commit()
                            AuditService.log(db, order.user_id, "sms.complete", "sms_order", order.id,
                                             {"service": order.service, "country": order.country,
                                              "provider": order.provider, "has_code": True}, "", "")
                            logger.info(f"Polling: order {order_id} code=***REDACTED***")
                            await self._dispatch_webhook(db, order)
                            await self._forward_telegram(db, order)
                            await self._forward_sms_config(db, order)
                    finally:
                        db.close()
                    return
            except Exception as e:
                logger.warning(f"Polling error [{order_id}]: {e}")

            await asyncio.sleep(5)

        db = SessionLocal()
        try:
            order = db.query(SMSOrder).filter(SMSOrder.id == order_id).first()
            if order and order.status == "pending":
                        order.status = "expired"
                        order.refunded = True
                        user = db.query(User).filter(User.id == order.user_id).first()
                        if user:
                            svc = PurchaseService(db)
                            svc.refund_coins(user, order.cost_coins, f"Auto-refund for expired order {order_id}")
                            AuditService.log(db, user.id, "sms.refund", "sms_order", order.id, {"service": order.service, "country": order.country, "provider": order.provider, "cost_coins": order.cost_coins, "refunded": True}, "", "")
                        db.commit()
                        logger.info(f"Order {order_id} expired, refunded {order.cost_coins} coins")
        finally:
            db.close()

    async def _forward_telegram(self, db: Session, order: SMSOrder):
        try:
            from app.services.telegram_service import TelegramService
            await TelegramService.forward_sms_to_telegram(db, order)
        except Exception as e:
            logger.warning(f"Telegram forwarding failed for order {order.id}: {e}")

    async def _forward_sms_config(self, db: Session, order: SMSOrder):
        try:
            from app.services.forwarding_service import ForwardingService
            svc = ForwardingService(db)
            await svc.forward_sms(order.user_id, order.phone_number or "", order.service,
                                   order.verification_code or "", order.sms_text or "")
        except Exception as e:
            logger.warning(f"SMS forwarding failed for order {order.id}: {e}")

    async def _dispatch_webhook(self, db: Session, order: SMSOrder):
        try:
            from app.services.webhook_service import WebhookService
            ws = WebhookService(db)
            # H-2 FIX: إزالة verification_code من payload الـ Webhook
            # لمنع تسريب رمز التحقق في حال اختراق الـ endpoint
            await ws.dispatch_event("sms.completed", {
                "order_id": order.id,
                "service": order.service,
                "country": order.country,
                "phone_number": order.phone_number,
                "provider": order.provider,
                "cost_coins": order.cost_coins,
                "has_code": bool(order.verification_code),  # إرسال بوليان فقط بدلاً من الكود
                "status": order.status,
            }, order.user_id)
        except Exception as e:
            logger.warning(f"Webhook dispatch failed for order {order.id}: {e}")

    def cancel(self, order_id: str):
        task = self._tasks.pop(order_id, None)
        if task:
            task.cancel()
            logger.info(f"Polling cancelled for order {order_id}")


class RefundEnforcer:
    async def run(self):
        while True:
            try:
                db = SessionLocal()
                try:
                    cutoff = datetime.now(timezone.utc) - timedelta(minutes=15)
                    expired = db.query(SMSOrder).filter(
                        SMSOrder.status == "pending",
                        SMSOrder.refunded == False,
                        SMSOrder.created_at < cutoff,
                    ).with_for_update(skip_locked=True).all()
                    for order in expired:
                        if order.refunded:
                            continue
                        provider = await provider_router.get_provider(order.provider)
                        if provider:
                            try:
                                await provider.cancel(order.activation_id)
                            except Exception as e:
                                logger.error(f"Failed to cancel order {order.id} with provider {order.provider}: {e}")
                        order.status = "expired"
                        order.refunded = True
                        user = db.query(User).filter(User.id == order.user_id).first()
                        if user:
                            svc = PurchaseService(db)
                            svc.refund_coins(user, order.cost_coins, f"Refund enforcer for order {order.id}")
                            AuditService.log(db, user.id, "sms.refund", "sms_order", order.id,
                                           {"service": order.service, "country": order.country,
                                            "provider": order.provider, "cost_coins": order.cost_coins,
                                            "refunded": True, "reason": "refund_enforcer"}, "", "")
                        logger.info(f"Refund enforcer: order {order.id} expired")
                    db.commit()
                finally:
                    db.close()
            except Exception as e:
                logger.error(f"Refund enforcer error: {e}")
            await asyncio.sleep(300)


class HealthChecker:
    async def run(self):
        while True:
            try:
                for provider in provider_router.all_providers:
                    if provider.enabled:
                        try:
                            balance = await provider.get_balance()
                            logger.info(f"[{provider.name}] Balance: {balance:.4f}")
                        except Exception as e:
                            logger.warning(f"[{provider.name}] Health check failed: {e}")
            except Exception as e:
                logger.error(f"Health checker crashed: {e}")
            await asyncio.sleep(14400)


class TempEmailQuotaResetter:
    async def run(self):
        while True:
            now = datetime.now(timezone.utc)
            next_reset = (now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
                          + timedelta(days=32)).replace(day=1)
            sleep_seconds = (next_reset - now).total_seconds()
            await asyncio.sleep(sleep_seconds)
            try:
                db = SessionLocal()
                try:
                    count = db.query(User).update({User.temp_emails_used: 0})
                    db.commit()
                    logger.info(f"Temp email quota reset for {count} users")
                finally:
                    db.close()
            except Exception as e:
                logger.error(f"Temp email quota reset failed: {e}")


class RentalExpiryEnforcer:
    async def run(self):
        while True:
            try:
                db = SessionLocal()
                try:
                    now = datetime.now(timezone.utc)
                    expired = db.query(NumberRental).filter(
                        NumberRental.status == "active",
                        NumberRental.expires_at < now,
                    ).all()
                    for rental in expired:
                        if rental.auto_extend:
                            from app.services.rental_service import RentalService
                            try:
                                svc = RentalService(db)
                                price = 0.0
                                for p in provider_router.enabled_providers:
                                    if p.name == rental.provider:
                                        price = await p.get_price(rental.service, rental.country)
                                        break
                                extra_coins = await svc.calculate_cost(price, 24)
                                # C-1 FIX: قفل صف المستخدم عند Auto-Extend لمنع Race Condition
                                user = db.query(User).filter(User.id == rental.user_id).with_for_update().first()
                                if user and user.coins >= extra_coins:
                                    user.coins -= extra_coins
                                    rental.expires_at = now + timedelta(hours=24)
                                    rental.duration_hours += 24
                                    rental.cost_coins += extra_coins
                                    logger.info(f"Rental {rental.id} auto-extended for 24h, cost={extra_coins}")
                                else:
                                    rental.status = "expired"
                                    logger.info(f"Rental {rental.id} expired (auto-extend failed: insufficient balance)")
                            except Exception as e:
                                logger.warning(f"Rental {rental.id} auto-extend failed: {e}")
                                rental.status = "expired"
                        else:
                            rental.status = "expired"
                            logger.info(f"Rental {rental.id} expired")
                    db.commit()
                finally:
                    db.close()
            except Exception as e:
                logger.error(f"Rental expiry enforcer error: {e}")
            await asyncio.sleep(300)


class IdempotencyCleanupTask:
    """C-4 FIX: تنظيف مفاتيح Idempotency المنتهية دورياً"""
    async def run(self):
        from app.core.idempotency import IdempotencyService
        while True:
            try:
                db = SessionLocal()
                try:
                    deleted = IdempotencyService.cleanup_expired(db)
                    if deleted:
                        logger.info(f"Idempotency cleanup: removed {deleted} expired keys")
                finally:
                    db.close()
            except Exception as e:
                logger.error(f"Idempotency cleanup error: {e}")
            await asyncio.sleep(3600)  # كل ساعة
