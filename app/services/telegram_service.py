from typing import Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.core.logging import get_logger
from app.domain.models import (
    SMSOrder,
    TelegramConnection,
    TelegramForwardingRule,
    gen_uuid,
)

logger = get_logger(__name__)


class TelegramService:
    @staticmethod
    def connect(db: Session, user_id: str, chat_id: str, bot_token: str, data: dict) -> dict:
        existing = db.query(TelegramConnection).filter(
            TelegramConnection.user_id == user_id
        ).first()
        if existing:
            raise AppException("TELEGRAM_EXISTS", "لديك اتصال تيليغرام نشط بالفعل")

        conn = TelegramConnection(
            id=gen_uuid(),
            user_id=user_id,
            chat_id=chat_id,
            bot_token=bot_token,
            username=data.get("username"),
            first_name=data.get("first_name"),
            last_name=data.get("last_name"),
            language_code=data.get("language_code"),
            status="active",
        )
        db.add(conn)
        db.commit()
        db.refresh(conn)
        return {"id": conn.id, "chat_id": conn.chat_id, "status": conn.status}

    @staticmethod
    def disconnect(db: Session, user_id: str) -> dict:
        conn = db.query(TelegramConnection).filter(
            TelegramConnection.user_id == user_id,
            TelegramConnection.status == "active",
        ).first()
        if not conn:
            raise AppException("NOT_FOUND", "لا يوجد اتصال تيليغرام نشط", 404)

        conn.status = "disconnected"
        conn.disconnected_at = db.query(func.now()).scalar()
        db.commit()
        return {"id": conn.id, "status": "disconnected"}

    @staticmethod
    def get_connection(db: Session, user_id: str) -> Optional[dict]:
        conn = db.query(TelegramConnection).filter(
            TelegramConnection.user_id == user_id,
            TelegramConnection.status == "active",
        ).first()
        if not conn:
            return None
        return {
            "id": conn.id,
            "chat_id": conn.chat_id,
            "username": conn.username,
            "first_name": conn.first_name,
            "status": conn.status,
            "connected_at": conn.connected_at.isoformat(),
        }

    @staticmethod
    def get_all_connections(db: Session, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(TelegramConnection).order_by(TelegramConnection.connected_at.desc())
        total = query.count()
        items = query.offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": c.id,
                "user_id": c.user_id,
                "chat_id": c.chat_id,
                "username": c.username,
                "status": c.status,
                "connected_at": c.connected_at.isoformat(),
            }
            for c in items
        ], total

    @staticmethod
    def create_forwarding_rule(db: Session, user_id: str, data: dict) -> dict:
        conn = db.query(TelegramConnection).filter(
            TelegramConnection.user_id == user_id,
            TelegramConnection.status == "active",
        ).first()
        if not conn:
            raise AppException("NOT_FOUND", "يجب ربط تيليغرام أولاً", 404)

        rule = TelegramForwardingRule(
            id=gen_uuid(),
            connection_id=conn.id,
            user_id=user_id,
            source_type=data.get("source_type", "sms"),
            filter_criteria=data.get("filter_criteria", {}),
            destination=data.get("destination", "telegram"),
            is_active=True,
        )
        db.add(rule)
        db.commit()
        db.refresh(rule)
        return {"id": rule.id, "source_type": rule.source_type, "is_active": rule.is_active}

    @staticmethod
    def get_rules(db: Session, user_id: str) -> list[dict]:
        rules = db.query(TelegramForwardingRule).filter(
            TelegramForwardingRule.user_id == user_id
        ).all()
        return [
            {
                "id": r.id,
                "source_type": r.source_type,
                "filter_criteria": r.filter_criteria,
                "destination": r.destination,
                "is_active": r.is_active,
            }
            for r in rules
        ]

    @staticmethod
    def toggle_rule(db: Session, rule_id: str, user_id: str, active: bool) -> Optional[dict]:
        rule = db.query(TelegramForwardingRule).filter(
            TelegramForwardingRule.id == rule_id,
            TelegramForwardingRule.user_id == user_id,
        ).first()
        if not rule:
            return None
        rule.is_active = active
        db.commit()
        return {"id": rule.id, "is_active": rule.is_active}

    @staticmethod
    def delete_rule(db: Session, rule_id: str, user_id: str) -> bool:
        rule = db.query(TelegramForwardingRule).filter(
            TelegramForwardingRule.id == rule_id,
            TelegramForwardingRule.user_id == user_id,
        ).first()
        if not rule:
            return False
        db.delete(rule)
        db.commit()
        return True

    @staticmethod
    async def forward_sms_to_telegram(db: Session, order: SMSOrder):
        conn = db.query(TelegramConnection).filter(
            TelegramConnection.user_id == order.user_id,
            TelegramConnection.status == "active",
        ).first()
        if not conn:
            return

        rules = db.query(TelegramForwardingRule).filter(
            TelegramForwardingRule.user_id == order.user_id,
            TelegramForwardingRule.is_active == True,
            TelegramForwardingRule.source_type == "sms",
        ).all()

        if not rules:
            return

        matched = False
        for rule in rules:
            fc = rule.filter_criteria or {}
            services = fc.get("services") or fc.get("service")
            if services:
                if isinstance(services, str):
                    services = [s.strip() for s in services.split(",")]
                if order.service not in services:
                    continue
            matched = True

        if not matched:
            return

        from app.infrastructure.bot.telegram_bot import TelegramBotClient

        bot = TelegramBotClient(bot_token=conn.bot_token)
        text = (
            f"📩 <b>SMS مستلم</b>\n"
            f"───────\n"
            f"<b>الخدمة:</b> {order.service}\n"
            f"<b>الرقم:</b> {order.phone_number}\n"
            f"<b>رمز التحقق:</b> {order.verification_code or '—'}\n"
            f"<b>النص:</b> {order.sms_text or '—'}\n"
            f"───────\n"
            f"{order.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
        )
        result = await bot.send_message(conn.chat_id, text)
        if result.get("success"):
            logger.info(f"Telegram forwarding OK for user={order.user_id} order={order.id}")
        else:
            logger.warning(f"Telegram forwarding failed for user={order.user_id} order={order.id}: {result.get('error')}")


