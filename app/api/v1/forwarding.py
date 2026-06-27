from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_mfa
from app.core.response import success_response
from app.domain.models import User
from app.services.forwarding_service import ForwardingService

router = APIRouter(prefix="/user/forwarding", tags=["Forwarding"])


class ForwardingUpdate(BaseModel):
    email_enabled: bool = None
    email_address: str = None
    webhook_enabled: bool = None
    webhook_url: str = None
    webhook_secret: str = None
    forward_all: bool = None
    forward_services: list = None
    is_active: bool = None


@router.get("")
async def get_forwarding(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = ForwardingService(db)
    config = svc.get_config(current_user.id)
    return success_response({
        "email_enabled": config.email_enabled,
        "email_address": config.email_address,
        "webhook_enabled": config.webhook_enabled,
        "webhook_url": config.webhook_url,
        "forward_all": config.forward_all,
        "forward_services": config.forward_services,
        "is_active": config.is_active,
    }, request_id=getattr(request.state, "request_id", ""))


@router.put("")
async def update_forwarding(
    body: ForwardingUpdate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    _mfa: User = Depends(require_mfa),
):
    svc = ForwardingService(db)
    config = svc.update_config(current_user.id, body.model_dump(exclude_none=True))
    return success_response({
        "email_enabled": config.email_enabled,
        "email_address": config.email_address,
        "webhook_enabled": config.webhook_enabled,
        "webhook_url": config.webhook_url,
        "forward_all": config.forward_all,
        "forward_services": config.forward_services,
        "is_active": config.is_active,
    }, request_id=getattr(request.state, "request_id", ""))


@router.get("/test")
async def test_forwarding(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = ForwardingService(db)
    result = svc.test_forwarding(current_user.id)
    return success_response(result, request_id=getattr(request.state, "request_id", ""))
