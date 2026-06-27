from typing import Optional

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import User
from app.services.support_service import SupportService


class ReplyRequest(BaseModel):
    message: str


class AssignRequest(BaseModel):
    admin_id: str

router = APIRouter(prefix="/admin/support", tags=["Admin Support"])


@router.get("/tickets")
async def list_all_tickets(
    request: Request,
    status: str = Query(default=None),
    category: str = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    svc = SupportService(db)
    tickets = svc.get_all_tickets(status, category, limit, offset)
    return success_response([{
        "id": t.id, "user_id": t.user_id,
        "subject": t.subject, "category": t.category,
        "priority": t.priority, "status": t.status,
        "assigned_to": t.assigned_to,
        "created_at": t.created_at.isoformat() if t.created_at else None,
        "updated_at": t.updated_at.isoformat() if t.updated_at else None,
    } for t in tickets], request_id=getattr(request.state, "request_id", ""))


@router.get("/tickets/{ticket_id}")
async def get_ticket_detail(
    request: Request,
    ticket_id: str,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    svc = SupportService(db)
    ticket = svc.get_ticket(ticket_id)
    if not ticket:
        raise AppException("NOT_FOUND", "التذكرة غير موجودة", 404)
    replies = svc.get_ticket_replies(ticket_id)
    return success_response({
        "id": ticket.id, "user_id": ticket.user_id,
        "subject": ticket.subject, "message": ticket.message,
        "category": ticket.category, "priority": ticket.priority,
        "status": ticket.status, "assigned_to": ticket.assigned_to,
        "created_at": ticket.created_at.isoformat() if ticket.created_at else None,
        "updated_at": ticket.updated_at.isoformat() if ticket.updated_at else None,
        "replies": [{
            "id": r.id, "user_id": r.user_id,
            "message": r.message, "is_admin": r.is_admin,
            "created_at": r.created_at.isoformat() if r.created_at else None,
        } for r in replies],
    }, request_id=getattr(request.state, "request_id", ""))


@router.post("/tickets/{ticket_id}/reply")
async def admin_reply(
    request: Request,
    ticket_id: str,
    body: ReplyRequest,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    svc = SupportService(db)
    ticket = svc.get_ticket(ticket_id)
    if not ticket:
        raise AppException("NOT_FOUND", "التذكرة غير موجودة", 404)
    if not body.message.strip():
        raise AppException("VALIDATION_ERROR", "الرسالة مطلوبة", 400)
    reply = svc.add_reply(ticket_id, _admin.id, body.message, is_admin=True)
    return success_response({
        "id": reply.id, "message": reply.message,
        "created_at": reply.created_at.isoformat() if reply.created_at else None,
    }, request_id=getattr(request.state, "request_id", ""))


@router.post("/tickets/{ticket_id}/close")
async def admin_close_ticket(
    request: Request,
    ticket_id: str,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    svc = SupportService(db)
    ticket = svc.close_ticket(ticket_id, _admin.id)
    if not ticket:
        raise AppException("NOT_FOUND", "التذكرة غير موجودة", 404)
    return success_response({"message": "تم إغلاق التذكرة"},
                           request_id=getattr(request.state, "request_id", ""))


@router.post("/tickets/{ticket_id}/assign")
async def assign_ticket(
    request: Request,
    ticket_id: str,
    body: AssignRequest,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    svc = SupportService(db)
    ticket = svc.assign_ticket(ticket_id, body.admin_id)
    if not ticket:
        raise AppException("NOT_FOUND", "التذكرة غير موجودة", 404)
    return success_response({"message": "تم تعيين المسؤول", "assigned_to": body.admin_id},
                            request_id=getattr(request.state, "request_id", ""))
