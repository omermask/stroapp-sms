from typing import Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import User
from app.services.telegram_service import TelegramService

router = APIRouter(prefix="/telegram", tags=["Telegram"])


class ConnectTelegram(BaseModel):
    chat_id: str
    bot_token: str
    username: Optional[str] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    language_code: Optional[str] = None


class CreateRule(BaseModel):
    source_type: str = "sms"
    filter_criteria: dict = {}
    destination: str = "telegram"


class ToggleRule(BaseModel):
    active: bool = True


@router.get("/connect")
async def get_connection(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = TelegramService.get_connection(db, current_user.id)
    if not result:
        return success_response({"connected": False})
    return success_response(result)


@router.post("/connect")
async def connect_telegram(
    body: ConnectTelegram,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = TelegramService.connect(db, current_user.id,
                                     body.chat_id,
                                     body.bot_token,
                                     body.model_dump(exclude={"chat_id", "bot_token"}))
    return success_response(result)


@router.post("/disconnect")
async def disconnect_telegram(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = TelegramService.disconnect(db, current_user.id)
    return success_response(result)


@router.get("/rules")
async def get_rules(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = TelegramService.get_rules(db, current_user.id)
    return success_response(result)


@router.post("/rules")
async def create_rule(
    body: CreateRule,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = TelegramService.create_forwarding_rule(db, current_user.id, body.model_dump())
    return success_response(result)


@router.put("/rules/{rule_id}/toggle")
async def toggle_rule(
    rule_id: str,
    body: ToggleRule,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = TelegramService.toggle_rule(db, rule_id, current_user.id, body.active)
    if not result:
        raise AppException(code="not_found", message="القاعدة غير موجودة", status_code=404)
    return success_response(result)


@router.delete("/rules/{rule_id}")
async def delete_rule(
    rule_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = TelegramService.delete_rule(db, rule_id, current_user.id)
    if not result:
        raise AppException(code="not_found", message="القاعدة غير موجودة", status_code=404)
    return success_response({"deleted": True})
