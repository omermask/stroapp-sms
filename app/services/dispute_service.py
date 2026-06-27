from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.domain.models import (
    Dispute,
    DisputeAttachment,
    DisputeComment,
    DisputeTimeline,
    SMSOrder,
    gen_uuid,
)


class DisputeService:
    DISPUTE_REASONS = ["wrong_number", "not_delivered", "spam", "wrong_content", "unauthorized", "other"]

    @staticmethod
    def create_dispute(db: Session, user_id: str, data: dict) -> dict:
        order_id = data.get("order_id")
        if order_id:
            order = db.query(SMSOrder).filter(SMSOrder.id == order_id, SMSOrder.user_id == user_id).first()
            if not order:
                raise AppException("NOT_FOUND", "الطلب غير موجود أو لا يتبع لك", 404)

        reason = data.get("reason", "other")
        if reason not in DisputeService.DISPUTE_REASONS:
            raise AppException("INVALID_REASON", f"سبب النزاع غير صالح. الأسباب المسموحة: {', '.join(DisputeService.DISPUTE_REASONS)}")

        dispute = Dispute(
            id=gen_uuid(),
            user_id=user_id,
            order_id=order_id,
            dispute_type=data.get("dispute_type", "billing"),
            reason=reason,
            description=data.get("description", ""),
            priority=data.get("priority", "normal"),
        )
        db.add(dispute)
        db.flush()

        timeline = DisputeTimeline(
            id=gen_uuid(),
            dispute_id=dispute.id,
            status=dispute.status,
            actor_id=user_id,
            actor_type="user",
            note="تم إنشاء النزاع",
        )
        db.add(timeline)
        db.commit()
        db.refresh(dispute)
        return DisputeService._dispute_to_dict(dispute)

    @staticmethod
    def get_user_disputes(db: Session, user_id: str, status: Optional[str] = None, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(Dispute).filter(Dispute.user_id == user_id)
        if status:
            query = query.filter(Dispute.status == status)
        query = query.order_by(Dispute.created_at.desc())
        total = query.count()
        items = query.offset((page - 1) * per_page).limit(per_page).all()
        return [DisputeService._dispute_to_dict(d) for d in items], total

    @staticmethod
    def get_dispute_detail(db: Session, dispute_id: str, user_id: Optional[str] = None) -> Optional[dict]:
        query = db.query(Dispute).filter(Dispute.id == dispute_id)
        if user_id:
            query = query.filter(Dispute.user_id == user_id)
        dispute = query.first()
        if not dispute:
            return None

        result = DisputeService._dispute_to_dict(dispute)

        comments = db.query(DisputeComment).filter(DisputeComment.dispute_id == dispute_id).order_by(DisputeComment.created_at.asc()).all()
        result["comments"] = [
            {
                "id": c.id,
                "actor_id": c.actor_id,
                "actor_type": c.actor_type,
                "content": c.content,
                "is_internal": c.is_internal,
                "created_at": c.created_at.isoformat(),
            }
            for c in comments
        ]

        timeline = db.query(DisputeTimeline).filter(DisputeTimeline.dispute_id == dispute_id).order_by(DisputeTimeline.created_at.asc()).all()
        result["timeline"] = [
            {
                "id": t.id,
                "status": t.status,
                "actor_id": t.actor_id,
                "actor_type": t.actor_type,
                "note": t.note,
                "created_at": t.created_at.isoformat(),
            }
            for t in timeline
        ]

        attachments = db.query(DisputeAttachment).filter(DisputeAttachment.dispute_id == dispute_id).all()
        result["attachments"] = [
            {
                "id": a.id,
                "file_name": a.file_name,
                "file_type": a.file_type,
                "file_url": a.file_url,
                "created_at": a.created_at.isoformat(),
            }
            for a in attachments
        ]
        return result

    @staticmethod
    def add_comment(db: Session, dispute_id: str, actor_id: str, actor_type: str, content: str, is_internal: bool = False) -> dict:
        dispute = db.query(Dispute).filter(Dispute.id == dispute_id).first()
        if not dispute:
            raise AppException("NOT_FOUND", "النزاع غير موجود", 404)
        if actor_type == "user" and dispute.user_id != actor_id:
            raise AppException("FORBIDDEN", "لا يمكنك التعليق على نزاع ليس لك", 403)

        comment = DisputeComment(
            id=gen_uuid(),
            dispute_id=dispute_id,
            actor_id=actor_id,
            actor_type=actor_type,
            content=content,
            is_internal=is_internal,
        )
        db.add(comment)
        db.commit()
        return {"id": comment.id, "content": content, "actor_type": actor_type, "created_at": comment.created_at.isoformat()}

    @staticmethod
    def update_status(db: Session, dispute_id: str, admin_id: str, status: str, note: str = "") -> Optional[dict]:
        valid_statuses = ["open", "investigating", "resolved", "closed", "escalated"]
        if status not in valid_statuses:
            raise AppException("INVALID_STATUS", f"حالة غير صالحة. الحالات المسموحة: {', '.join(valid_statuses)}")

        dispute = db.query(Dispute).filter(Dispute.id == dispute_id).first()
        if not dispute:
            return None

        old_status = dispute.status
        dispute.status = status
        if status == "resolved":
            dispute.resolved_at = datetime.now(timezone.utc)
        if status in ("investigating", "escalated"):
            dispute.investigated_by = admin_id

        timeline = DisputeTimeline(
            id=gen_uuid(),
            dispute_id=dispute_id,
            status=status,
            actor_id=admin_id,
            actor_type="admin",
            note=note or f"تغيرت الحالة من {old_status} إلى {status}",
        )
        db.add(timeline)
        db.commit()
        return DisputeService._dispute_to_dict(dispute)

    @staticmethod
    def resolve_dispute(db: Session, dispute_id: str, admin_id: str, resolution: str, note: str = "",
                        refund_amount: float = 0) -> Optional[dict]:
        from app.domain.models import User, Transaction, gen_uuid as _gen_uuid
        dispute = db.query(Dispute).filter(Dispute.id == dispute_id).first()
        if not dispute:
            return None

        dispute.status = "resolved"
        dispute.resolution = resolution
        dispute.resolved_at = datetime.now(timezone.utc)
        dispute.refund_amount = refund_amount
        dispute.investigated_by = admin_id

        # H-7 FIX: تنفيذ استرداد الكوينز فعلياً عند وجود مبلغ استرداد
        if refund_amount and refund_amount > 0:
            refund_coins = int(refund_amount)
            user = db.query(User).filter(User.id == dispute.user_id).with_for_update().first()
            if user:
                coins_before = user.coins
                user.coins += refund_coins
                tx = Transaction(
                    id=_gen_uuid(),
                    user_id=user.id,
                    amount=refund_coins,
                    type="refund",
                    description=f"استرداد نزاع #{dispute.id}",
                    reference=dispute.id,
                    coins_before=coins_before,
                    coins_after=user.coins,
                )
                db.add(tx)

        timeline = DisputeTimeline(
            id=gen_uuid(),
            dispute_id=dispute_id,
            status="resolved",
            actor_id=admin_id,
            actor_type="admin",
            note=note or f"تم الحل: {resolution}",
        )
        db.add(timeline)
        db.commit()
        return DisputeService._dispute_to_dict(dispute)

    @staticmethod
    def get_all_disputes(db: Session, status: Optional[str] = None, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(Dispute)
        if status:
            query = query.filter(Dispute.status == status)
        query = query.order_by(Dispute.created_at.desc())
        total = query.count()
        items = query.offset((page - 1) * per_page).limit(per_page).all()
        return [DisputeService._dispute_to_dict(d) for d in items], total

    @staticmethod
    def get_stats(db: Session) -> dict:
        total = db.query(func.count(Dispute.id)).scalar() or 0
        open_count = db.query(func.count(Dispute.id)).filter(Dispute.status == "open").scalar() or 0
        investigating = db.query(func.count(Dispute.id)).filter(Dispute.status == "investigating").scalar() or 0
        resolved = db.query(func.count(Dispute.id)).filter(Dispute.status == "resolved").scalar() or 0
        escalated = db.query(func.count(Dispute.id)).filter(Dispute.status == "escalated").scalar() or 0
        high_priority = db.query(func.count(Dispute.id)).filter(Dispute.priority == "high").scalar() or 0

        return {
            "total": total,
            "open": open_count,
            "investigating": investigating,
            "resolved": resolved,
            "escalated": escalated,
            "high_priority": high_priority,
            "resolution_rate": round((resolved / total * 100) if total > 0 else 0, 2),
        }

    @staticmethod
    def _dispute_to_dict(dispute: Dispute) -> dict:
        return {
            "id": dispute.id,
            "user_id": dispute.user_id,
            "order_id": dispute.order_id,
            "dispute_type": dispute.dispute_type,
            "reason": dispute.reason,
            "description": dispute.description,
            "status": dispute.status,
            "priority": dispute.priority,
            "resolution": dispute.resolution,
            "refund_amount": dispute.refund_amount,
            "investigated_by": dispute.investigated_by,
            "resolved_at": dispute.resolved_at.isoformat() if dispute.resolved_at else None,
            "created_at": dispute.created_at.isoformat(),
            "updated_at": dispute.updated_at.isoformat() if dispute.updated_at else None,
        }
