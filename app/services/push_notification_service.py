from datetime import datetime, timezone, timedelta

import httpx
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.domain.models import DeviceToken, gen_uuid


class PushNotificationService:
    def __init__(self):
        settings = get_settings()
        self.fcm_server_key = settings.fcm_server_key
        self.fcm_url = "https://fcm.googleapis.com/fcm/send"
        self.vapid_key = settings.fcm_vapid_key
        self._configured = bool(self.fcm_server_key)

    def is_configured(self) -> bool:
        return self._configured

    async def register_device(self, db: Session, user_id: str, token: str, platform: str,
                                device_type: str = None, device_name: str = None) -> DeviceToken:
        existing = db.query(DeviceToken).filter(DeviceToken.token == token).first()
        if existing:
            if existing.user_id != user_id:
                raise PermissionError("هذا الجهاز مسجل بالفعل لمستخدم آخر")
            existing.active = True
            existing.platform = platform
            existing.device_type = device_type or existing.device_type
            existing.device_name = device_name or existing.device_name
            existing.last_used_at = datetime.now(timezone.utc)
            existing.expires_at = datetime.now(timezone.utc) + timedelta(days=90)
            db.commit()
            return existing
        device = DeviceToken(
            id=gen_uuid(), user_id=user_id, token=token, platform=platform,
            device_type=device_type, device_name=device_name,
            last_used_at=datetime.now(timezone.utc),
            expires_at=datetime.now(timezone.utc) + timedelta(days=90),
        )
        db.add(device)
        db.commit()
        return device

    async def unregister_device(self, db: Session, user_id: str, token: str) -> bool:
        device = db.query(DeviceToken).filter(
            DeviceToken.user_id == user_id,
            DeviceToken.token == token,
        ).first()
        if not device:
            return False
        device.active = False
        db.commit()
        return True

    async def send_to_user(self, db: Session, user_id: str, title: str, body: str,
                            data: dict = None, tag: str = None) -> dict:
        if not self._configured:
            return {"success": False, "error": "FCM not configured"}
        devices = db.query(DeviceToken).filter(
            DeviceToken.user_id == user_id,
            DeviceToken.active == True,
        ).all()
        if not devices:
            return {"success": True, "sent": 0, "message": "No active devices"}
        active = []
        now = datetime.now(timezone.utc)
        for d in devices:
            if d.expires_at is None or d.expires_at > now:
                active.append(d)
        sent = 0
        for device in active:
            ok = await self._send_to_device(device.token, title, body, data or {}, tag)
            if ok:
                device.last_used_at = now
                sent += 1
        db.commit()
        return {"success": True, "sent": sent, "total": len(active)}

    async def send_to_all(self, db: Session, title: str, body: str, data: dict = None, tag: str = None) -> dict:
        if not self._configured:
            return {"success": False, "error": "FCM not configured"}
        devices = db.query(DeviceToken).filter(DeviceToken.active == True).all()
        now = datetime.now(timezone.utc)
        sent = 0
        for device in devices:
            if device.expires_at is None or device.expires_at > now:
                ok = await self._send_to_device(device.token, title, body, data or {}, tag)
                if ok:
                    device.last_used_at = now
                    sent += 1
        db.commit()
        return {"success": True, "sent": sent, "total": len(devices)}

    async def _send_to_device(self, token: str, title: str, body: str,
                               data: dict, tag: str = None) -> bool:
        try:
            notification = {"title": title, "body": body}
            if tag:
                notification["tag"] = tag
            payload = {
                "to": token,
                "notification": notification,
                "data": data,
                "priority": "high",
            }
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.post(
                    self.fcm_url,
                    json=payload,
                    headers={"Authorization": f"key={self.fcm_server_key}"},
                )
                return resp.status_code == 200
        except Exception:
            return False


push_notification_service = PushNotificationService()
