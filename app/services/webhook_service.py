import hashlib
import hmac
import ipaddress
import json
import re
import socket
import uuid
from datetime import datetime, timezone, timedelta
from typing import Any, Optional
from urllib.parse import urlparse

import httpx
from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.core.logging import get_logger
from app.domain.models import Webhook, WebhookEvent, gen_uuid
from app.infrastructure.queue.webhook_queue import WebhookQueue

logger = get_logger(__name__)

WEBHOOK_EVENTS = [
    "sms.received",
    "sms.completed",
    "sms.expired",
    "sms.cancelled",
    "order.purchased",
    "order.completed",
    "user.deposit",
]

MAX_RETRIES = 5
RETRY_DELAYS = [60, 300, 900, 3600, 14400]


PRIVATE_HOSTNAMES = re.compile(r"^(localhost|local\.host|127\.0\.0\.1|0\.0\.0\.0)$", re.IGNORECASE)
PRIVATE_IP_RANGES = [
    ipaddress.ip_network("10.0.0.0/8"),
    ipaddress.ip_network("172.16.0.0/12"),
    ipaddress.ip_network("192.168.0.0/16"),
    ipaddress.ip_network("127.0.0.0/8"),
    ipaddress.ip_network("169.254.0.0/16"),
    ipaddress.ip_network("0.0.0.0/8"),
    ipaddress.ip_network("::1/128"),
    ipaddress.ip_network("fc00::/7"),
    ipaddress.ip_network("fe80::/10"),
]


def validate_webhook_url(url: str) -> str:
    parsed = urlparse(url)
    if parsed.scheme not in ("https", "http"):
        raise AppException("VALIDATION_ERROR", "رابط Webhook يجب أن يستخدم http أو https", status_code=400)
    from app.core.config import get_settings
    if get_settings().environment == "production" and parsed.scheme != "https":
        raise AppException("VALIDATION_ERROR", "رابط Webhook يجب أن يستخدم HTTPS في الإنتاج", status_code=400)
    host = parsed.hostname or ""
    if PRIVATE_HOSTNAMES.match(host):
        raise AppException("VALIDATION_ERROR", "رابط Webhook لا يمكن أن يشير إلى localhost", status_code=400)
    try:
        ip = ipaddress.ip_address(host)
        _raise_if_private(ip)
    except ValueError:
        addrs = _resolve_hostname(host)
        for addr in addrs:
            try:
                _raise_if_private(ipaddress.ip_address(addr))
            except ValueError:
                continue
    return url


def _raise_if_private(ip: ipaddress.IPAddress):
    for net in PRIVATE_IP_RANGES:
        if ip in net:
            raise AppException("VALIDATION_ERROR", f"رابط Webhook لا يمكن أن يشير إلى IP خاص: {ip}", status_code=400)


def _resolve_hostname(host: str) -> list[str]:
    try:
        addrs = socket.getaddrinfo(host, None)
        return list(set(a[4][0] for a in addrs))
    except Exception:
        return []


def sign_payload(payload: dict, secret: str) -> str:
    body = json.dumps(payload, separators=(",", ":"), default=str).encode()
    return hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()


class WebhookService:
    def __init__(self, db: Session):
        self.db = db

    def create_webhook(self, user_id: str, url: str, events: list[str], secret: Optional[str] = None) -> Webhook:
        url = validate_webhook_url(url)
        for event in events:
            if event not in WEBHOOK_EVENTS:
                raise AppException("VALIDATION_ERROR", f"حدث غير صالح: {event}", status_code=400)

        existing = self.db.query(Webhook).filter(
            Webhook.user_id == user_id,
            Webhook.url == url,
            Webhook.is_active == True,
        ).first()
        if existing:
            raise AppException("DUPLICATE_REQUEST", "رابط Webhook مسجل بالفعل", status_code=409)

        webhook_secret = secret or uuid.uuid4().hex
        webhook = Webhook(
            id=gen_uuid(),
            user_id=user_id,
            url=url,
            secret=webhook_secret,
            events=events,
            is_active=True,
        )
        self.db.add(webhook)
        self.db.commit()
        self.db.refresh(webhook)
        logger.info(f"Webhook created: user={user_id} url={url} events={events}")
        return webhook

    def update_webhook(self, webhook_id: str, user_id: str, **kwargs) -> Webhook:
        webhook = self.db.query(Webhook).filter(
            Webhook.id == webhook_id,
            Webhook.user_id == user_id,
        ).first()
        if not webhook:
            raise AppException("NOT_FOUND", "Webhook غير موجود", status_code=404)

        if "url" in kwargs:
            kwargs["url"] = validate_webhook_url(kwargs["url"])
        if "events" in kwargs:
            for event in kwargs["events"]:
                if event not in WEBHOOK_EVENTS:
                    raise AppException("VALIDATION_ERROR", f"حدث غير صالح: {event}", status_code=400)

        for key, value in kwargs.items():
            setattr(webhook, key, value)
        self.db.commit()
        self.db.refresh(webhook)
        return webhook

    def delete_webhook(self, webhook_id: str, user_id: str):
        webhook = self.db.query(Webhook).filter(
            Webhook.id == webhook_id,
            Webhook.user_id == user_id,
        ).first()
        if not webhook:
            raise AppException("NOT_FOUND", "Webhook غير موجود", status_code=404)
        webhook.is_active = False
        self.db.commit()
        logger.info(f"Webhook deleted: {webhook_id}")

    async def dispatch(self, webhook_id: str, event: str, payload: dict):
        webhook = self.db.query(Webhook).filter(Webhook.id == webhook_id).first()
        if not webhook or not webhook.is_active:
            return

        if event not in (webhook.events or []):
            return

        event_record = WebhookEvent(
            id=gen_uuid(),
            webhook_id=webhook_id,
            event=event,
            payload=payload,
            status="pending",
        )
        self.db.add(event_record)
        self.db.commit()
        self.db.refresh(event_record)

        await self._enqueue_delivery(webhook_id, event, payload)

        success = await self._deliver(webhook, event_record, payload)

        if success:
            event_record.status = "delivered"
            event_record.completed_at = datetime.now(timezone.utc)
            webhook.last_success_at = datetime.now(timezone.utc)
            webhook.consecutive_failures = 0
        else:
            event_record.status = "pending"
            event_record.retry_count = 0
            event_record.next_retry_at = datetime.now(timezone.utc) + timedelta(seconds=RETRY_DELAYS[0])
            webhook.last_failure_at = datetime.now(timezone.utc)
            webhook.consecutive_failures = (webhook.consecutive_failures or 0) + 1

        self.db.commit()

    async def _enqueue_delivery(self, webhook_id: str, event: str, payload: dict):
        try:
            queue = WebhookQueue()
            await queue.ensure_group()
            await queue.enqueue(webhook_id, event, payload)
            await queue.close()
        except Exception as e:
            logger.debug(f"Redis Streams unavailable for webhook {webhook_id}: {e}")

    async def dispatch_event(self, event: str, data: dict, user_id: str):
        webhooks = self.db.query(Webhook).filter(
            Webhook.user_id == user_id,
            Webhook.is_active == True,
        ).all()

        for webhook in webhooks:
            if event in (webhook.events or []):
                await self.dispatch(webhook.id, event, data)
        from app.services.audit_service import AuditService
        AuditService.log(self.db, user_id, f"webhook.dispatch", "webhook", None, {"event": event, "targets_count": len(webhooks)}, "", "")

    async def _deliver(self, webhook: Webhook, event_record: WebhookEvent, payload: dict) -> bool:
        body = {
            "event": event_record.event,
            "data": payload,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }

        signature = sign_payload(body, webhook.secret or "")

        try:
            async with httpx.AsyncClient(timeout=15) as client:
                resp = await client.post(
                    webhook.url,
                    json=body,
                    headers={
                        "Content-Type": "application/json",
                        "X-Webhook-Signature": signature,
                        "X-Webhook-Event": event_record.event,
                        "User-Agent": "StroApp-SMS-Webhook/1.0",
                    },
                )

            event_record.response_code = resp.status_code
            event_record.response_body = resp.text[:500]

            if 200 <= resp.status_code < 300:
                logger.info(f"Webhook delivered: {webhook.id} event={event_record.event}")
                return True

            logger.warning(f"Webhook failed: {webhook.id} status={resp.status_code}")
            return False

        except httpx.TimeoutException:
            event_record.error_message = "Timeout"
            logger.warning(f"Webhook timeout: {webhook.id}")
            return False
        except httpx.ConnectError as e:
            event_record.error_message = f"Connection failed: {e}"
            logger.warning(f"Webhook connection failed: {webhook.id}: {e}")
            return False
        except Exception as e:
            event_record.error_message = str(e)
            logger.error(f"Webhook delivery error: {webhook.id}: {e}")
            return False

    async def retry_failed_events(self):
        now = datetime.now(timezone.utc)
        pending = self.db.query(WebhookEvent).filter(
            WebhookEvent.status == "pending",
            WebhookEvent.next_retry_at.isnot(None),
            WebhookEvent.next_retry_at <= now,
        ).all()

        for event in pending:
            webhook = self.db.query(Webhook).filter(Webhook.id == event.webhook_id).first()
            if not webhook or not webhook.is_active:
                event.status = "cancelled"
                event.completed_at = now
                continue

            try:
                success = await self._deliver(webhook, event, event.payload or {})
            except Exception as e:
                logger.error(f"Webhook retry delivery error: {event.id}: {e}")
                success = False

            if success:
                event.status = "delivered"
                event.completed_at = now
                webhook.last_success_at = now
                webhook.consecutive_failures = 0
                logger.info(f"Webhook retry delivered: {event.id}")
            else:
                event.status = "failed"
                webhook.last_failure_at = now
                webhook.consecutive_failures = (webhook.consecutive_failures or 0) + 1
                if event.retry_count < MAX_RETRIES:
                    delay = RETRY_DELAYS[event.retry_count] if event.retry_count < len(RETRY_DELAYS) else RETRY_DELAYS[-1]
                    event.retry_count += 1
                    event.next_retry_at = now + timedelta(seconds=delay)
                    event.status = "pending"
                    logger.info(f"Webhook scheduled for next retry: {event.id} attempt {event.retry_count}")
                else:
                    event.status = "permanently_failed"
                    logger.warning(f"Webhook permanently failed: {event.id}")

        if pending:
            self.db.commit()
