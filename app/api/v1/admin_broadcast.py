from typing import Optional

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.response import success_response
from app.domain.models import User, Notification, gen_uuid
from app.services.audit_service import AuditService
from app.websocket.manager import WebSocketManager
from app.core.logging import get_logger

logger = get_logger(__name__)


class BroadcastNotification(BaseModel):
    title: str
    body: str = ""
    notification_type: str = "broadcast"
    send_push: bool = False


class BroadcastToTier(BaseModel):
    tier: str
    title: str
    body: str = ""
    notification_type: str = "broadcast"

router = APIRouter(prefix="/admin/broadcast", tags=["Admin Broadcast"])


@router.post("/notification")
async def broadcast_notification(
    request: Request,
    body: BroadcastNotification,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):

    users = db.query(User.id).filter(User.is_active == True).all()
    user_ids = [u.id for u in users]

    for uid in user_ids:
        notification = Notification(
            id=gen_uuid(), user_id=uid, type=body.notification_type,
            title=body.title, body=body.body,
        )
        db.add(notification)

    db.commit()

    for uid in user_ids:
        try:
            await WebSocketManager.broadcast(uid, {
                "type": body.notification_type,
                "title": body.title,
                "body": body.body,
                "is_read": False,
            })
        except Exception as e:
            logger.warning(f"WebSocket broadcast to {uid} failed: {e}")

    AuditService.log(db, _admin.id, "admin.broadcast", "notification", "",
                    {"title": body.title, "user_count": len(user_ids)},
                    request.client.host if request.client else "",
                    getattr(request.state, "request_id", ""))

    return success_response({
        "message": "تم إرسال الإشعار لجميع المستخدمين",
        "user_count": len(user_ids),
    }, request_id=getattr(request.state, "request_id", ""))


@router.post("/notification/tier")
async def broadcast_to_tier(
    request: Request,
    body: BroadcastToTier,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):

    users = db.query(User.id).filter(
        User.is_active == True,
        User.tier == body.tier,
    ).all()
    user_ids = [u.id for u in users]

    for uid in user_ids:
        notification = Notification(
            id=gen_uuid(), user_id=uid, type=body.notification_type,
            title=body.title, body=body.body,
        )
        db.add(notification)

    db.commit()

    for uid in user_ids:
        try:
            await WebSocketManager.broadcast(uid, {
                "type": body.notification_type,
                "title": body.title,
                "body": body.body,
                "is_read": False,
            })
        except Exception as e:
            logger.warning(f"WebSocket broadcast to {uid} failed: {e}")

    AuditService.log(db, _admin.id, "admin.broadcast_tier", "notification",
                    body.tier, {"title": body.title, "user_count": len(user_ids)},
                    request.client.host if request.client else "",
                    getattr(request.state, "request_id", ""))

    return success_response({
        "message": f"تم إرسال الإشعار لمستخدمي الشريحة {body.tier}",
        "user_count": len(user_ids),
    }, request_id=getattr(request.state, "request_id", ""))
