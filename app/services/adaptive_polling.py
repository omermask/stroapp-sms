import asyncio
import statistics
from datetime import datetime, timezone, timedelta
from typing import Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.core.logging import get_logger
from app.domain.models import SMSOrder

logger = get_logger(__name__)


class AdaptivePollingService:
    BASE_INTERVAL = 5.0
    MAX_INTERVAL = 60.0
    MIN_INTERVAL = 2.0
    SPEEDUP_FACTOR = 0.7
    SLOWDOWN_FACTOR = 1.3
    HISTORY_WINDOW = 100

    def __init__(self):
        self._intervals: dict[str, float] = {}
        self._history: dict[str, list[float]] = {}

    def get_interval(self, service: str = "") -> float:
        return self._intervals.get(service, self.BASE_INTERVAL)

    def record_response_time(self, service: str, response_time: float):
        if service not in self._history:
            self._history[service] = []
            self._intervals[service] = self.BASE_INTERVAL

        history = self._history[service]
        history.append(response_time)
        if len(history) > self.HISTORY_WINDOW:
            history.pop(0)

        if len(history) >= 5:
            avg_time = statistics.mean(history)
            if avg_time < 3.0:
                self._intervals[service] = max(self.MIN_INTERVAL,
                                                self._intervals[service] * self.SPEEDUP_FACTOR)
            elif avg_time > 10.0:
                self._intervals[service] = min(self.MAX_INTERVAL,
                                                self._intervals[service] * self.SLOWDOWN_FACTOR)

    def record_timeout(self, service: str):
        current = self._intervals.get(service, self.BASE_INTERVAL)
        self._intervals[service] = min(self.MAX_INTERVAL, current * self.SLOWDOWN_FACTOR * 1.5)

    def get_stats(self, service: str = "") -> dict:
        return {
            "current_interval": self._intervals.get(service, self.BASE_INTERVAL),
            "history_count": len(self._history.get(service, [])),
            "average_response": statistics.mean(self._history.get(service, [0]))
            if self._history.get(service) else 0,
        }


class SMSPollingJob:
    def __init__(self):
        self.polling = AdaptivePollingService()

    async def run(self):
        while True:
            try:
                db = SessionLocal()
                try:
                    await self._poll_pending_orders(db)
                finally:
                    db.close()
                interval = self.polling.get_interval("sms_poll")
                await asyncio.sleep(interval)
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"SMS polling error: {e}")
                await asyncio.sleep(30)

    async def _poll_pending_orders(self, db: Session):
        now = datetime.now(timezone.utc)
        cutoff = now - timedelta(hours=2)
        pending = db.query(SMSOrder).filter(
            SMSOrder.status.in_(["pending", "waiting"]),
            SMSOrder.created_at >= cutoff,
            SMSOrder.phone_number.isnot(None),
        ).order_by(SMSOrder.created_at.asc()).limit(50).all()

        if not pending:
            self.polling.record_response_time("sms_poll", 0.1)
            return

        start = datetime.now(timezone.utc)
        for order in pending:
            try:
                from app.services.purchase_service import PurchaseService
                svc = PurchaseService(db)
                result = await svc.check_status(order.id)
                if result:
                    order.status = "completed"
                    order.verification_code = result.get("code", "")
                    order.sms_text = result.get("text", "")
                    order.sms_received_at = datetime.now(timezone.utc)
                    db.commit()
                    await self._dispatch_webhook(db, order)
                    await self._notify_user(db, order)
                    await self._forward_telegram(db, order)
                    await self._forward_sms_config(db, order)
            except Exception as e:
                logger.warning(f"Poll error for order {order.id}: {e}")
                self.polling.record_timeout("sms_poll")

        elapsed = (datetime.now(timezone.utc) - start).total_seconds()
        self.polling.record_response_time("sms_poll", elapsed / max(len(pending), 1))

    async def _dispatch_webhook(self, db: Session, order: SMSOrder):
        try:
            from app.services.webhook_service import WebhookService
            ws = WebhookService(db)
            await ws.dispatch_event("sms.completed", {
                "order_id": order.id,
                "service": order.service,
                "country": order.country,
                "phone_number": order.phone_number,
                "provider": order.provider,
                "cost_coins": order.cost_coins,
                "verification_code": order.verification_code,
                "status": order.status,
            }, order.user_id)
        except Exception as e:
            logger.warning(f"Webhook dispatch failed for order {order.id}: {e}")

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

    async def _notify_user(self, db: Session, order: SMSOrder):
        try:
            from app.services.notification_service import NotificationService
            svc = NotificationService(db)
            await svc.notify(
                order.user_id, "sms.received",
                "تم استلام الرسالة",
                f"تم استلام رسالة التحقق من {order.service}",
                {"order_id": order.id},
            )
        except Exception:
            pass
