from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.domain.models import SupportTicket, SupportTicketReply, gen_uuid
from app.services.audit_service import AuditService


class SupportService:
    def __init__(self, db: Session):
        self.db = db

    def create_ticket(self, user_id: str, subject: str, message: str,
                      category: str = "general", priority: str = "normal") -> SupportTicket:
        ticket = SupportTicket(
            id=gen_uuid(),
            user_id=user_id,
            subject=subject,
            message=message,
            category=category,
            priority=priority,
        )
        self.db.add(ticket)
        self.db.commit()

        AuditService.log(self.db, user_id, "support.create", "support_ticket",
                        ticket.id, {"subject": subject, "category": category},
                        "", "")
        return ticket

    def add_reply(self, ticket_id: str, user_id: str, message: str,
                  is_admin: bool = False) -> SupportTicketReply:
        ticket = self.db.query(SupportTicket).filter(SupportTicket.id == ticket_id).first()
        if not ticket:
            return None

        if ticket.status == "closed":
            ticket.status = "reopened"

        ticket.updated_at = datetime.now(timezone.utc)

        reply = SupportTicketReply(
            id=gen_uuid(),
            ticket_id=ticket_id,
            user_id=user_id,
            message=message,
            is_admin=is_admin,
        )
        self.db.add(reply)
        self.db.commit()
        return reply

    def close_ticket(self, ticket_id: str, closed_by: str):
        ticket = self.db.query(SupportTicket).filter(SupportTicket.id == ticket_id).first()
        if not ticket:
            return None
        ticket.status = "closed"
        ticket.closed_by = closed_by
        ticket.closed_at = datetime.now(timezone.utc)
        self.db.commit()
        return ticket

    def get_user_tickets(self, user_id: str, limit: int = 50,
                          offset: int = 0) -> list[SupportTicket]:
        return self.db.query(SupportTicket).filter(
            SupportTicket.user_id == user_id,
        ).order_by(SupportTicket.updated_at.desc()).offset(offset).limit(limit).all()

    def get_ticket(self, ticket_id: str) -> SupportTicket | None:
        return self.db.query(SupportTicket).filter(SupportTicket.id == ticket_id).first()

    def get_ticket_replies(self, ticket_id: str) -> list[SupportTicketReply]:
        return self.db.query(SupportTicketReply).filter(
            SupportTicketReply.ticket_id == ticket_id,
        ).order_by(SupportTicketReply.created_at.asc()).all()

    def get_all_tickets(self, status: str | None = None, category: str | None = None,
                        limit: int = 50, offset: int = 0) -> list[SupportTicket]:
        q = self.db.query(SupportTicket)
        if status:
            q = q.filter(SupportTicket.status == status)
        if category:
            q = q.filter(SupportTicket.category == category)
        return q.order_by(SupportTicket.updated_at.desc()).offset(offset).limit(limit).all()

    def assign_ticket(self, ticket_id: str, admin_id: str) -> SupportTicket | None:
        ticket = self.get_ticket(ticket_id)
        if not ticket:
            return None
        ticket.assigned_to = admin_id
        self.db.commit()
        return ticket
