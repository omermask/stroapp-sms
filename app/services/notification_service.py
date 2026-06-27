from sqlalchemy.orm import Session

from app.domain.models import Notification, gen_uuid
from app.services.push_notification_service import push_notification_service
from app.websocket.manager import WebSocketManager


class NotificationService:
    def __init__(self, db: Session):
        self.db = db

    def create_notification(self, user_id: str, type: str, title: str, body: str = "", data: dict = None):
        notification = Notification(
            id=gen_uuid(), user_id=user_id, type=type,
            title=title, body=body, data=data or {},
        )
        self.db.add(notification)
        self.db.commit()
        return notification

    async def notify(self, user_id: str, type: str, title: str, body: str = "", data: dict = None):
        notification = self.create_notification(user_id, type, title, body, data)
        try:
            await WebSocketManager.broadcast(user_id, {
                "id": notification.id,
                "type": type,
                "title": title,
                "body": body,
                "data": data or {},
                "is_read": False,
                "created_at": notification.created_at.isoformat() if notification.created_at else "",
            })
        except Exception:
            pass
        if push_notification_service.is_configured():
            try:
                await push_notification_service.send_to_user(
                    self.db, user_id, title, body,
                    {"type": type, **(data or {})},
                )
            except Exception:
                pass

    def get_notifications(self, user_id: str, limit: int = 50, offset: int = 0):
        return self.db.query(Notification).filter(
            Notification.user_id == user_id,
        ).order_by(Notification.created_at.desc()).offset(offset).limit(limit).all()

    def get_unread_count(self, user_id: str) -> int:
        return self.db.query(Notification).filter(
            Notification.user_id == user_id,
            Notification.is_read == False,
        ).count()

    def mark_all_read(self, user_id: str):
        self.db.query(Notification).filter(
            Notification.user_id == user_id,
            Notification.is_read == False,
        ).update({"is_read": True})
        self.db.commit()
