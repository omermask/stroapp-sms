from typing import Optional

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.response import success_response
from app.domain.models import User, Webhook, WebhookEvent
from app.services.webhook_service import WEBHOOK_EVENTS, WebhookService

router = APIRouter(prefix="/user/webhooks", tags=["Webhooks"])


class CreateWebhookRequest(BaseModel):
    url: str
    events: list[str]
    secret: Optional[str] = None


class UpdateWebhookRequest(BaseModel):
    url: Optional[str] = None
    events: Optional[list[str]] = None
    is_active: Optional[bool] = None


@router.get("/events")
async def list_webhook_events(
    request: Request,
    _user: User = Depends(get_current_user),
):
    return success_response(
        [{"event": e, "description": _event_description(e)} for e in WEBHOOK_EVENTS],
        request_id=getattr(request.state, "request_id", ""),
    )


@router.post("")
async def create_webhook(
    body: CreateWebhookRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from app.services.audit_service import AuditService
    svc = WebhookService(db)
    webhook = svc.create_webhook(current_user.id, body.url, body.events, body.secret)
    AuditService.log(db, current_user.id, "webhook.create", "webhook", webhook.id, {"url": body.url, "events": body.events}, request.client.host if request.client else "", getattr(request.state, "request_id", ""))
    return success_response(
        {
            "id": webhook.id,
            "url": webhook.url,
            "events": webhook.events,
            "secret": webhook.secret if body.secret else None,
            "is_active": webhook.is_active,
            "created_at": webhook.created_at.isoformat() if webhook.created_at else None,
        },
        request_id=getattr(request.state, "request_id", ""),
    )


@router.get("")
async def list_webhooks(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    webhooks = db.query(Webhook).filter(
        Webhook.user_id == current_user.id,
        Webhook.is_active == True,
    ).all()
    return success_response(
        [
            {
                "id": w.id,
                "url": w.url,
                "events": w.events,
                "is_active": w.is_active,
                "last_success_at": w.last_success_at.isoformat() if w.last_success_at else None,
                "last_failure_at": w.last_failure_at.isoformat() if w.last_failure_at else None,
                "consecutive_failures": w.consecutive_failures,
                "created_at": w.created_at.isoformat() if w.created_at else None,
            }
            for w in webhooks
        ],
        request_id=getattr(request.state, "request_id", ""),
    )


@router.get("/{webhook_id}")
async def get_webhook(
    webhook_id: str,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    webhook = db.query(Webhook).filter(
        Webhook.id == webhook_id,
        Webhook.user_id == current_user.id,
    ).first()
    if not webhook:
        return success_response(None, request_id=getattr(request.state, "request_id", ""))
    return success_response(
        {
            "id": webhook.id,
            "url": webhook.url,
            "events": webhook.events,
            "is_active": webhook.is_active,
            "last_success_at": webhook.last_success_at.isoformat() if webhook.last_success_at else None,
            "last_failure_at": webhook.last_failure_at.isoformat() if webhook.last_failure_at else None,
            "consecutive_failures": webhook.consecutive_failures,
            "created_at": webhook.created_at.isoformat() if webhook.created_at else None,
        },
        request_id=getattr(request.state, "request_id", ""),
    )


@router.put("/{webhook_id}")
async def update_webhook(
    webhook_id: str,
    body: UpdateWebhookRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from app.services.audit_service import AuditService
    svc = WebhookService(db)
    kwargs = {k: v for k, v in body.model_dump().items() if v is not None}
    webhook = svc.update_webhook(webhook_id, current_user.id, **kwargs)
    AuditService.log(db, current_user.id, "webhook.update", "webhook", webhook.id, {"changes": kwargs}, request.client.host if request.client else "", getattr(request.state, "request_id", ""))
    return success_response(
        {
            "id": webhook.id,
            "url": webhook.url,
            "events": webhook.events,
            "is_active": webhook.is_active,
        },
        request_id=getattr(request.state, "request_id", ""),
    )


@router.delete("/{webhook_id}")
async def delete_webhook(
    webhook_id: str,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from app.services.audit_service import AuditService
    svc = WebhookService(db)
    svc.delete_webhook(webhook_id, current_user.id)
    AuditService.log(db, current_user.id, "webhook.delete", "webhook", webhook_id, {}, request.client.host if request.client else "", getattr(request.state, "request_id", ""))
    return success_response(
        {"deleted": True},
        request_id=getattr(request.state, "request_id", ""),
    )


@router.get("/{webhook_id}/events")
async def list_webhook_events_for(
    webhook_id: str,
    request: Request,
    limit: int = Query(default=20, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    webhook = db.query(Webhook).filter(
        Webhook.id == webhook_id,
        Webhook.user_id == current_user.id,
    ).first()
    if not webhook:
        return success_response([], request_id=getattr(request.state, "request_id", ""))

    events = db.query(WebhookEvent).filter(
        WebhookEvent.webhook_id == webhook_id,
    ).order_by(WebhookEvent.created_at.desc()).limit(limit).all()

    return success_response(
        [
            {
                "id": e.id,
                "event": e.event,
                "status": e.status,
                "response_code": e.response_code,
                "retry_count": e.retry_count,
                "created_at": e.created_at.isoformat() if e.created_at else None,
                "completed_at": e.completed_at.isoformat() if e.completed_at else None,
            }
            for e in events
        ],
        request_id=getattr(request.state, "request_id", ""),
    )


def _event_description(event: str) -> str:
    descriptions = {
        "sms.received": "SMS message received for an order",
        "sms.completed": "SMS verification completed successfully",
        "sms.expired": "SMS verification expired without receiving code",
        "sms.cancelled": "SMS order was cancelled",
        "order.completed": "Purchase order completed",
        "user.deposit": "User made a deposit",
    }
    return descriptions.get(event, "")
