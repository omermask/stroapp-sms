from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import User
from app.services.support_service import SupportService


class ReplyToTicketRequest(BaseModel):
    message: str

router = APIRouter(prefix="/user/support", tags=["Support Tickets"])


class CreateTicketRequest(BaseModel):
    subject: str
    message: str
    category: str = "general"
    priority: str = "normal"


@router.post("/tickets")
async def create_ticket(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = SupportService(db)
    raw = await request.json()
    ticket_body = CreateTicketRequest(**raw)
    ticket = svc.create_ticket(
        current_user.id, ticket_body.subject, ticket_body.message,
        ticket_body.category, ticket_body.priority
    )
    return success_response({
        "id": ticket.id, "subject": ticket.subject,
        "message": ticket.message, "status": ticket.status,
        "category": ticket.category, "priority": ticket.priority,
        "created_at": ticket.created_at.isoformat() if ticket.created_at else None,
    }, request_id=getattr(request.state, "request_id", ""))


@router.get("/tickets")
async def list_tickets(
    request: Request,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = SupportService(db)
    tickets = svc.get_user_tickets(current_user.id, limit, offset)
    return success_response([{
        "id": t.id, "subject": t.subject,
        "category": t.category, "priority": t.priority,
        "status": t.status,
        "reply_count": len(t.replies) if hasattr(t, "replies") else 0,
        "created_at": t.created_at.isoformat() if t.created_at else None,
        "updated_at": t.updated_at.isoformat() if t.updated_at else None,
    } for t in tickets], request_id=getattr(request.state, "request_id", ""))


@router.get("/tickets/{ticket_id}")
async def get_ticket(
    request: Request,
    ticket_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = SupportService(db)
    ticket = svc.get_ticket(ticket_id)
    if not ticket or ticket.user_id != current_user.id:
        raise AppException("NOT_FOUND", "التذكرة غير موجودة", 404)
    replies = svc.get_ticket_replies(ticket_id)
    return success_response({
        "id": ticket.id, "subject": ticket.subject,
        "message": ticket.message, "category": ticket.category,
        "priority": ticket.priority, "status": ticket.status,
        "assigned_to": ticket.assigned_to,
        "created_at": ticket.created_at.isoformat() if ticket.created_at else None,
        "updated_at": ticket.updated_at.isoformat() if ticket.updated_at else None,
        "replies": [{
            "id": r.id, "message": r.message,
            "is_admin": r.is_admin,
            "created_at": r.created_at.isoformat() if r.created_at else None,
        } for r in replies],
    }, request_id=getattr(request.state, "request_id", ""))


@router.post("/tickets/{ticket_id}/reply")
async def reply_to_ticket(
    request: Request,
    ticket_id: str,
    body: ReplyToTicketRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = SupportService(db)
    ticket = svc.get_ticket(ticket_id)
    if not ticket or ticket.user_id != current_user.id:
        raise AppException("NOT_FOUND", "التذكرة غير موجودة", 404)
    reply = svc.add_reply(ticket_id, current_user.id, body.message)
    return success_response({
        "id": reply.id, "message": reply.message,
        "created_at": reply.created_at.isoformat() if reply.created_at else None,
    }, request_id=getattr(request.state, "request_id", ""))


@router.post("/tickets/{ticket_id}/close")
async def close_ticket(
    request: Request,
    ticket_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = SupportService(db)
    ticket = svc.get_ticket(ticket_id)
    if not ticket or ticket.user_id != current_user.id:
        raise AppException("NOT_FOUND", "التذكرة غير موجودة", 404)
    svc.close_ticket(ticket_id, current_user.id)
    return success_response({"message": "تم إغلاق التذكرة"},
                           request_id=getattr(request.state, "request_id", ""))
