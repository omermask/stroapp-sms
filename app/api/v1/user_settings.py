from typing import Optional

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.response import success_response
from app.domain.models import User, UserSettings, gen_uuid


class UpdateSettingsRequest(BaseModel):
    language: Optional[str] = None
    timezone: Optional[str] = None
    email_notifications: Optional[bool] = None
    push_notifications: Optional[bool] = None
    sms_notifications: Optional[bool] = None
    dark_mode: Optional[bool] = None

router = APIRouter(prefix="/user/settings", tags=["User Settings"])


@router.get("")
async def get_settings(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    settings = db.query(UserSettings).filter(
        UserSettings.user_id == current_user.id,
    ).first()
    if not settings:
        settings = UserSettings(user_id=current_user.id)
        db.add(settings)
        db.commit()
    return success_response({
        "language": settings.language,
        "timezone": settings.timezone,
        "email_notifications": settings.email_notifications,
        "push_notifications": settings.push_notifications,
        "sms_notifications": settings.sms_notifications,
        "dark_mode": settings.dark_mode,
    }, request_id=getattr(request.state, "request_id", ""))


@router.put("")
async def update_settings(
    request: Request,
    body: UpdateSettingsRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    settings = db.query(UserSettings).filter(
        UserSettings.user_id == current_user.id,
    ).first()
    if not settings:
        settings = UserSettings(id=gen_uuid(), user_id=current_user.id)
        db.add(settings)

    if body.language is not None:
        settings.language = body.language
    if body.timezone is not None:
        settings.timezone = body.timezone
    if body.email_notifications is not None:
        settings.email_notifications = body.email_notifications
    if body.push_notifications is not None:
        settings.push_notifications = body.push_notifications
    if body.sms_notifications is not None:
        settings.sms_notifications = body.sms_notifications
    if body.dark_mode is not None:
        settings.dark_mode = body.dark_mode
    db.commit()

    return success_response({
        "language": settings.language,
        "timezone": settings.timezone,
        "email_notifications": settings.email_notifications,
        "push_notifications": settings.push_notifications,
        "sms_notifications": settings.sms_notifications,
        "dark_mode": settings.dark_mode,
    }, request_id=getattr(request.state, "request_id", ""))
