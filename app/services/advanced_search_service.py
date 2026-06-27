from typing import Any

from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.domain.models import User, SMSOrder, Transaction, PaymentLog


class AdvancedSearchService:
    @staticmethod
    def search_users(db: Session, query: str, limit: int = 20) -> list[dict[str, Any]]:
        term = f"%{query}%"
        users = db.query(User).filter(
            or_(
                User.email.ilike(term),
                User.display_name.ilike(term),
                User.id.ilike(term),
            )
        ).limit(limit).all()
        return [
            {"id": u.id, "email": u.email, "display_name": u.display_name,
             "tier": u.tier, "is_admin": u.is_admin, "is_banned": u.is_banned,
             "coins": u.coins, "created_at": str(u.created_at)}
            for u in users
        ]

    @staticmethod
    def search_orders(db: Session, query: str, limit: int = 20) -> list[dict[str, Any]]:
        term = f"%{query}%"
        orders = db.query(SMSOrder).filter(
            or_(
                SMSOrder.phone_number.ilike(term),
                SMSOrder.service.ilike(term),
                SMSOrder.id.ilike(term),
                SMSOrder.user_id.ilike(term),
            )
        ).limit(limit).all()
        return [
            {"id": o.id, "user_id": o.user_id, "service": o.service,
             "country": o.country, "phone_number": o.phone_number,
             "status": o.status, "created_at": str(o.created_at)}
            for o in orders
        ]

    @staticmethod
    def search_transactions(db: Session, query: str, limit: int = 20) -> list[dict[str, Any]]:
        term = f"%{query}%"
        txns = db.query(Transaction).filter(
            or_(
                Transaction.reference.ilike(term),
                Transaction.id.ilike(term),
                Transaction.user_id.ilike(term),
                Transaction.description.ilike(term),
            )
        ).limit(limit).all()
        return [
            {"id": t.id, "user_id": t.user_id, "amount": t.amount,
             "type": t.type, "reference": t.reference, "created_at": str(t.created_at)}
            for t in txns
        ]

    @staticmethod
    def search_payments(db: Session, query: str, limit: int = 20) -> list[dict[str, Any]]:
        term = f"%{query}%"
        payments = db.query(PaymentLog).filter(
            or_(
                PaymentLog.reference.ilike(term),
                PaymentLog.id.ilike(term),
                PaymentLog.user_id.ilike(term),
                PaymentLog.product_id.ilike(term),
            )
        ).limit(limit).all()
        return [
            {"id": p.id, "user_id": p.user_id, "provider": p.provider,
             "product_id": p.product_id, "amount_usd": p.amount_usd,
             "status": p.status, "created_at": str(p.created_at)}
            for p in payments
        ]

    @staticmethod
    def global_search(db: Session, query: str, limit: int = 5) -> dict[str, Any]:
        return {
            "users": AdvancedSearchService.search_users(db, query, limit),
            "orders": AdvancedSearchService.search_orders(db, query, limit),
            "transactions": AdvancedSearchService.search_transactions(db, query, limit),
            "payments": AdvancedSearchService.search_payments(db, query, limit),
        }
