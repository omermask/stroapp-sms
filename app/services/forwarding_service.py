import hashlib
import hmac
import json
from datetime import datetime, timezone

import httpx
from sqlalchemy.orm import Session

from app.core.logging import get_logger

logger = get_logger(__name__)

from app.domain.models import ForwardingConfig, gen_uuid
from app.services.notification_service import NotificationService
from app.services.webhook_service import validate_webhook_url


class ForwardingService:
    def __init__(self, db: Session):
        self.db = db

    def get_config(self, user_id: str) -> ForwardingConfig:
        config = self.db.query(ForwardingConfig).filter(
            ForwardingConfig.user_id == user_id,
        ).first()
        if not config:
            config = ForwardingConfig(id=gen_uuid(), user_id=user_id)
            self.db.add(config)
            self.db.commit()
        return config

    def update_config(self, user_id: str, data: dict) -> ForwardingConfig:
        config = self.get_config(user_id)
        for key in ("email_enabled", "email_address", "webhook_enabled", "webhook_url",
                     "webhook_secret", "forward_all", "forward_services", "is_active"):
            if key in data:
                setattr(config, key, data[key])
        if config.webhook_url:
            config.webhook_url = validate_webhook_url(config.webhook_url)
        self.db.commit()
        return config

    async def forward_sms(self, user_id: str, phone_number: str, service: str,
                           verification_code: str, sms_text: str):
        config = self.get_config(user_id)
        if not config.is_active:
            return
        if not config.forward_all and config.forward_services:
            if service not in (config.forward_services or []):
                return
        if config.webhook_enabled and config.webhook_url:
            await self._send_webhook(config, phone_number, service, verification_code, sms_text)
        if config.email_enabled and config.email_address:
            await self._send_email(config, user_id, phone_number, service, verification_code, sms_text)

    async def _send_webhook(self, config, phone_number, service, code, text):
        if not config.webhook_url:
            return
        payload = json.dumps({
            "event": "sms.received",
            "phone_number": phone_number,
            "service": service,
            "verification_code": code,
            "sms_text": text,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }).encode()
        secret = config.webhook_secret or ""
        signature = hmac.new(secret.encode(), payload, hashlib.sha256).hexdigest()
        try:
            async with httpx.AsyncClient(timeout=15) as client:
                await client.post(
                    config.webhook_url,
                    content=payload,
                    headers={
                        "Content-Type": "application/json",
                        "X-Forwarding-Signature": signature,
                    },
                )
        except Exception as e:
            logger.warning(f"Webhook forwarding failed for user: {e}")

    async def _send_email(self, config, user_id, phone_number, service, code, text):
        if not config.email_address:
            return
        NotificationService(self.db).create_notification(
            user_id, "forwarding_sms",
            "تم استلام رسالة SMS", f"الخدمة: {service} - الرمز: {code}",
            {"phone_number": phone_number, "service": service, "code": code},
        )

    def test_forwarding(self, user_id: str) -> dict:
        config = self.get_config(user_id)
        flags = []
        if config.webhook_enabled and config.webhook_url:
            flags.append("webhook")
        if config.email_enabled and config.email_address:
            flags.append("email")
        return {
            "is_active": config.is_active,
            "enabled_channels": flags,
            "email": config.email_address,
            "webhook": config.webhook_url,
            "forward_all": config.forward_all,
        }
