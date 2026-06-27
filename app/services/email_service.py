import random
import string

import httpx

from app.core.config import get_settings
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import TempEmail, User, gen_uuid
from app.services.audit_service import AuditService


class EmailService:
    BASE_URL = "https://api.mail.tm"

    def __init__(self, db):
        self.db = db
        self.client = httpx.AsyncClient(base_url=self.BASE_URL, timeout=30)

    async def close(self):
        await self.client.aclose()

    async def get_or_create_temp_email(self, user_id: str) -> dict:
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            raise AppException("NOT_FOUND", "المستخدم غير موجود", 404)
        settings = get_settings()
        if user.temp_emails_used >= settings.temp_emails_per_month:
            raise AppException("QUOTA_EXCEEDED", "لقد استنفدت عدد الإيميلات المؤقتة لهذا الشهر", 429)
        existing = self.db.query(TempEmail).filter(
            TempEmail.user_id == user_id,
            TempEmail.is_active == True,
        ).first()
        if existing:
            return {
                "id": existing.id,
                "email": existing.email_address,
                "is_active": existing.is_active,
                "messages_count": existing.messages_count,
                "created_at": existing.created_at.isoformat() if existing.created_at else None,
            }
        try:
            domains = await self._get_domains()
            domain = domains[0] if domains else "@mail.tm"
            name = ''.join(random.choices(string.ascii_lowercase + string.digits, k=12))
            password = ''.join(random.choices(string.ascii_letters + string.digits, k=16))
            resp = await self.client.post("/accounts", json={
                "address": f"{name}{domain}",
                "password": password,
            })
            resp.raise_for_status()
            account = resp.json()
            token_resp = await self.client.post("/token", json={
                "address": account["address"],
                "password": password,
            })
            token_resp.raise_for_status()
            token_data = token_resp.json()
            temp_email = TempEmail(
                id=gen_uuid(),
                user_id=user_id,
                email_address=account["address"],
                password=password,
                token=token_data.get("token", ""),
                is_active=True,
            )
            self.db.add(temp_email)
            user.temp_emails_used += 1
            self.db.commit()
            AuditService.log(self.db, user_id, "email.create", "temp_email", temp_email.id,
                           {"email": account["address"]}, "", "")
            return {
                "id": temp_email.id,
                "email": temp_email.email_address,
                "is_active": temp_email.is_active,
                "messages_count": temp_email.messages_count,
                "created_at": temp_email.created_at.isoformat() if temp_email.created_at else None,
            }
        except httpx.HTTPStatusError:
            raise AppException("PROVIDER_ERROR", "فشل في إنشاء الإيميل المؤقت، حاول لاحقاً", 502)
        except Exception:
            raise AppException("PROVIDER_ERROR", "فشل في إنشاء الإيميل المؤقت، حاول لاحقاً", 502)

    async def get_messages(self, user_id: str) -> list[dict]:
        temp_email = self.db.query(TempEmail).filter(
            TempEmail.user_id == user_id,
            TempEmail.is_active == True,
        ).first()
        if not temp_email:
            raise AppException("NOT_FOUND", "لا يوجد إيميل مؤقت، أنشئ واحداً أولاً", 404)
        try:
            headers = {"Authorization": f"Bearer {temp_email.token}"}
            resp = await self.client.get("/messages", headers=headers)
            resp.raise_for_status()
            data = resp.json()
            messages = data.get("hydra:member", [])
            result = []
            for msg in messages:
                result.append({
                    "id": msg.get("id"),
                    "from": msg.get("from", {}).get("address", ""),
                    "subject": msg.get("subject", ""),
                    "intro": msg.get("intro", ""),
                    "has_attachments": msg.get("hasAttachments", False),
                    "created_at": msg.get("createdAt"),
                })
            temp_email.messages_count = len(result)
            self.db.commit()
            return result
        except Exception:
            return []

    async def delete_temp_email(self, user_id: str) -> dict:
        temp_email = self.db.query(TempEmail).filter(
            TempEmail.user_id == user_id,
            TempEmail.is_active == True,
        ).first()
        if not temp_email:
            raise AppException("NOT_FOUND", "لا يوجد إيميل مؤقت لحذفه", 404)
        temp_email.is_active = False
        self.db.commit()
        AuditService.log(self.db, user_id, "email.delete", "temp_email", temp_email.id,
                       {"email": temp_email.email_address}, "", "")
        return {"deleted": True}

    async def _get_domains(self) -> list[str]:
        try:
            resp = await self.client.get("/domains")
            resp.raise_for_status()
            data = resp.json()
            domains = data.get("hydra:member", [])
            return [d.get("domain", "") for d in domains if d.get("domain")]
        except Exception:
            return ["@mail.tm"]
