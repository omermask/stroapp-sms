from typing import Optional

from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.domain.models import (
    NotificationPreference,
    NotificationPreferenceDefaults,
    NotificationAnalytics,
    AdminNotification,
    User,
    gen_uuid,
)
from app.services.notification_service import NotificationService


class NotificationPrefsService:
    @staticmethod
    def get_preferences(db: Session, user_id: str) -> Optional[dict]:
        prefs = db.query(NotificationPreference).filter(NotificationPreference.user_id == user_id).first()
        if not prefs:
            return None
        return {
            "push_enabled": prefs.push_enabled,
            "email_enabled": prefs.email_enabled,
            "sms_enabled": prefs.sms_enabled,
            "telegram_enabled": prefs.telegram_enabled,
            "whatsapp_enabled": prefs.whatsapp_enabled,
            "quiet_hours_start": prefs.quiet_hours_start.isoformat() if prefs.quiet_hours_start else None,
            "quiet_hours_end": prefs.quiet_hours_end.isoformat() if prefs.quiet_hours_end else None,
            "digest_frequency": prefs.digest_frequency,
            "categories": prefs.categories,
        }

    @staticmethod
    def upsert_preferences(db: Session, user_id: str, data: dict) -> dict:
        prefs = db.query(NotificationPreference).filter(NotificationPreference.user_id == user_id).first()
        if not prefs:
            prefs = NotificationPreference(user_id=user_id)
            db.add(prefs)

        fields = ["push_enabled", "email_enabled", "sms_enabled", "telegram_enabled",
                  "whatsapp_enabled", "quiet_hours_start", "quiet_hours_end",
                  "digest_frequency", "categories"]
        for field in fields:
            if field in data:
                setattr(prefs, field, data[field])

        db.commit()
        return {"user_id": user_id, "updated": True}

    @staticmethod
    def get_defaults(db: Session) -> list[dict]:
        items = db.query(NotificationPreferenceDefaults).all()
        return [
            {
                "category": d.category,
                "push_enabled": d.push_enabled,
                "email_enabled": d.email_enabled,
                "sms_enabled": d.sms_enabled,
                "telegram_enabled": d.telegram_enabled,
            }
            for d in items
        ]

    @staticmethod
    def upsert_default(db: Session, category: str, data: dict) -> dict:
        default = db.query(NotificationPreferenceDefaults).filter(
            NotificationPreferenceDefaults.category == category
        ).first()
        if not default:
            default = NotificationPreferenceDefaults(category=category)
            db.add(default)
        for key in ("push_enabled", "email_enabled", "sms_enabled", "telegram_enabled"):
            if key in data:
                setattr(default, key, data[key])
        db.commit()
        return {"category": category, "updated": True}

    @staticmethod
    def get_analytics(db: Session, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(NotificationAnalytics).order_by(NotificationAnalytics.created_at.desc())
        total = query.count()
        items = query.offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": a.id,
                "event_type": a.event_type,
                "channel": a.channel,
                "status": a.status,
                "latency_ms": a.latency_ms,
                "category": a.category,
                "created_at": a.created_at.isoformat(),
            }
            for a in items
        ], total

    @staticmethod
    def track_event(db: Session, event_type: str, channel: str, status: str,
                    latency_ms: Optional[int] = None, category: Optional[str] = None) -> dict:
        event = NotificationAnalytics(
            id=gen_uuid(),
            event_type=event_type,
            channel=channel,
            status=status,
            latency_ms=latency_ms,
            category=category,
        )
        db.add(event)
        db.commit()
        return {"id": event.id, "status": status}

    @staticmethod
    def create_admin_notification(db: Session, data: dict) -> dict:
        notification = AdminNotification(
            id=gen_uuid(),
            title=data["title"],
            message=data["message"],
            notification_type=data.get("notification_type", "info"),
            audience_filter=data.get("audience_filter"),
            scheduled_at=data.get("scheduled_at"),
        )
        db.add(notification)
        db.commit()
        db.refresh(notification)
        return {
            "id": notification.id,
            "title": notification.title,
            "notification_type": notification.notification_type,
            "status": notification.status,
        }

    @staticmethod
    def get_admin_notifications(db: Session, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(AdminNotification).order_by(AdminNotification.created_at.desc())
        total = query.count()
        items = query.offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": n.id,
                "title": n.title,
                "message": n.message,
                "notification_type": n.notification_type,
                "status": n.status,
                "audience_filter": n.audience_filter,
                "sent_count": n.sent_count,
                "failed_count": n.failed_count,
                "scheduled_at": n.scheduled_at.isoformat() if n.scheduled_at else None,
                "sent_at": n.sent_at.isoformat() if n.sent_at else None,
                "created_at": n.created_at.isoformat(),
            }
            for n in items
        ], total
