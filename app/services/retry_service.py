import asyncio
import json
from datetime import datetime, timezone, timedelta
from typing import Any

import httpx
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.core.logging import get_logger
from app.domain.models import WebhookEvent

logger = get_logger(__name__)


class RetryService:
    MAX_RETRIES = 5
    BACKOFF_SECONDS = [60, 300, 900, 3600, 14400]

    @staticmethod
    async def process_pending_retries():
        db = SessionLocal()
        try:
            now = datetime.now(timezone.utc)
            pending = db.query(WebhookEvent).filter(
                WebhookEvent.status.in_(["pending", "failed"]),
                WebhookEvent.retry_count < RetryService.MAX_RETRIES,
                (WebhookEvent.next_retry_at.is_(None) | (WebhookEvent.next_retry_at <= now)),
            ).limit(50).all()

            for event in pending:
                await RetryService._retry_event(db, event)
        except Exception as e:
            logger.error(f"Retry processing error: {e}")
        finally:
            db.close()

    @staticmethod
    async def _retry_event(db: Session, event: WebhookEvent):
        webhook = event.webhook
        if not webhook or not webhook.is_active:
            event.status = "cancelled"
            db.commit()
            return

        try:
            async with httpx.AsyncClient(timeout=30) as client:
                headers = {"Content-Type": "application/json"}
                if webhook.secret:
                    headers["X-Webhook-Secret"] = webhook.secret
                resp = await client.post(
                    webhook.url,
                    json={"event": event.event, "payload": event.payload},
                    headers=headers,
                )

            event.response_code = resp.status_code
            event.response_body = resp.text[:1000]
            event.retry_count += 1

            if 200 <= resp.status_code < 300:
                event.status = "completed"
                event.completed_at = datetime.now(timezone.utc)
                webhook.last_success_at = datetime.now(timezone.utc)
                webhook.consecutive_failures = 0
            else:
                event.status = "failed"
                webhook.last_failure_at = datetime.now(timezone.utc)
                webhook.consecutive_failures += 1
                RetryService._schedule_retry(event)
        except Exception as e:
            event.retry_count += 1
            event.status = "failed"
            event.error_message = str(e)[:500]
            webhook.last_failure_at = datetime.now(timezone.utc)
            webhook.consecutive_failures += 1
            RetryService._schedule_retry(event)

        db.commit()

    @staticmethod
    def _schedule_retry(event: WebhookEvent):
        if event.retry_count >= RetryService.MAX_RETRIES:
            event.status = "failed_permanent"
            event.next_retry_at = None
            return
        idx = min(event.retry_count - 1, len(RetryService.BACKOFF_SECONDS) - 1)
        event.next_retry_at = datetime.now(timezone.utc) + timedelta(seconds=RetryService.BACKOFF_SECONDS[idx])

    @staticmethod
    async def retry_webhook_event(db: Session, event_id: str) -> WebhookEvent | None:
        event = db.query(WebhookEvent).filter(WebhookEvent.id == event_id).first()
        if not event:
            return None
        event.retry_count = 0
        event.status = "pending"
        event.next_retry_at = datetime.now(timezone.utc)
        event.error_message = None
        db.commit()
        await RetryService._retry_event(db, event)
        return event
