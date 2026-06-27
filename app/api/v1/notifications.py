from typing import Optional

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.response import success_response
from app.domain.models import User
from app.services.notification_prefs import NotificationPrefsService
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/user/notifications", tags=["Notifications"])


class UpdatePreferences(BaseModel):
    push_enabled: Optional[bool] = None
    email_enabled: Optional[bool] = None
    sms_enabled: Optional[bool] = None
    telegram_enabled: Optional[bool] = None
    whatsapp_enabled: Optional[bool] = None
    quiet_hours_start: Optional[str] = None
    quiet_hours_end: Optional[str] = None
    digest_frequency: Optional[str] = None
    categories: Optional[list] = None


@router.get("")
async def list_notifications(
    request: Request,
    limit: int = Query(default=50, le=100),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = NotificationService(db)
    notifications = svc.get_notifications(current_user.id, limit, offset)
    return success_response([
        {
            "id": n.id,
            "type": n.type,
            "title": n.title,
            "body": n.body,
            "data": n.data,
            "is_read": n.is_read,
            "created_at": n.created_at.isoformat() if n.created_at else None,
        }
        for n in notifications
    ], request_id=getattr(request.state, "request_id", ""))


@router.get("/unread")
async def unread_count(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = NotificationService(db)
    count = svc.get_unread_count(current_user.id)
    return success_response({"count": count}, request_id=getattr(request.state, "request_id", ""))


@router.post("/read-all")
async def mark_all_read(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = NotificationService(db)
    svc.mark_all_read(current_user.id)
    return success_response({"success": True}, request_id=getattr(request.state, "request_id", ""))


# ---- Phase 9: Notification Preferences ----

@router.get("/preferences")
async def get_preferences(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = NotificationPrefsService.get_preferences(db, current_user.id)
    if not result:
        result = {
            "push_enabled": True,
            "email_enabled": True,
            "sms_enabled": True,
            "telegram_enabled": False,
            "whatsapp_enabled": False,
            "quiet_hours_start": None,
            "quiet_hours_end": None,
            "digest_frequency": "daily",
            "categories": None,
        }
    return success_response(result)


@router.put("/preferences")
async def update_preferences(
    body: UpdatePreferences,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = NotificationPrefsService.upsert_preferences(db, current_user.id, body.model_dump(exclude_none=True))
    return success_response(result)
