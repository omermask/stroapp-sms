from datetime import datetime, timezone, date
from typing import Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.logging import get_logger
from app.domain.models import ProviderSettlement, SMSOrder, Country, gen_uuid

logger = get_logger(__name__)


class ProviderSettlementService:
    def __init__(self, db: Session):
        self.db = db

    def calculate_settlement(self, provider_name: str,
                             period_start: date, period_end: date) -> dict:
        orders = self.db.query(SMSOrder).filter(
            SMSOrder.provider == provider_name,
            func.date(SMSOrder.created_at) >= period_start,
            func.date(SMSOrder.created_at) <= period_end,
            SMSOrder.status.in_(["received", "completed"]),
        ).all()

        total_orders = len(orders)
        gross_amount = sum(o.cost_coins for o in orders) / 100.0 if orders else 0.0
        commission = gross_amount * 0.15
        net_amount = gross_amount - commission

        existing = self.db.query(ProviderSettlement).filter(
            ProviderSettlement.provider_name == provider_name,
            ProviderSettlement.settlement_period_start == period_start,
            ProviderSettlement.settlement_period_end == period_end,
        ).first()

        return {
            "provider_name": provider_name,
            "period_start": period_start,
            "period_end": period_end,
            "total_orders": total_orders,
            "gross_amount": gross_amount,
            "commission": commission,
            "net_amount": net_amount,
            "existing_settlement_id": existing.id if existing else None,
        }

    def create_settlement(self, provider_name: str,
                          period_start: date, period_end: date) -> ProviderSettlement:
        calc = self.calculate_settlement(provider_name, period_start, period_end)
        if calc["existing_settlement_id"]:
            return self.db.query(ProviderSettlement).filter(
                ProviderSettlement.id == calc["existing_settlement_id"]
            ).first()

        settlement = ProviderSettlement(
            id=gen_uuid(),
            provider_name=provider_name,
            settlement_period_start=period_start,
            settlement_period_end=period_end,
            gross_amount=calc["gross_amount"],
            commission_amount=calc["commission"],
            net_amount=calc["net_amount"],
            status="pending",
        )
        self.db.add(settlement)
        self.db.commit()
        return settlement

    def approve_settlement(self, settlement_id: str, approved_by: str) -> ProviderSettlement:
        settlement = self.db.query(ProviderSettlement).filter(
            ProviderSettlement.id == settlement_id
        ).first()
        if not settlement:
            return None
        settlement.status = "approved"
        settlement.settlement_date = datetime.now(timezone.utc).date()
        self.db.commit()
        return settlement

    def mark_paid(self, settlement_id: str) -> ProviderSettlement:
        settlement = self.db.query(ProviderSettlement).filter(
            ProviderSettlement.id == settlement_id
        ).first()
        if not settlement:
            return None
        settlement.status = "paid"
        settlement.paid_at = datetime.now(timezone.utc)
        self.db.commit()
        return settlement

    def get_pending_settlements(self) -> list[ProviderSettlement]:
        return self.db.query(ProviderSettlement).filter(
            ProviderSettlement.status == "pending",
        ).order_by(ProviderSettlement.settlement_period_start.desc()).all()

    def get_settlements(self, provider: str = "", limit: int = 50, offset: int = 0) -> list[ProviderSettlement]:
        q = self.db.query(ProviderSettlement)
        if provider:
            q = q.filter(ProviderSettlement.provider_name == provider)
        return q.order_by(ProviderSettlement.settlement_period_start.desc()).offset(offset).limit(limit).all()
