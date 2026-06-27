from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Any

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.domain.models import PnLReport, PaymentLog, SMSOrder, Country, gen_uuid


class PnLService:
    @staticmethod
    def generate_report(db: Session, period_start: date, period_end: date,
                        generated_by: str = "") -> PnLReport:
        existing = db.query(PnLReport).filter(
            PnLReport.period_start == period_start,
            PnLReport.period_end == period_end,
        ).first()
        if existing:
            return existing

        payments = db.query(
            func.sum(PaymentLog.amount_usd),
            func.count(PaymentLog.id),
        ).filter(
            PaymentLog.status == "completed",
            func.date(PaymentLog.created_at) >= period_start,
            func.date(PaymentLog.created_at) <= period_end,
        ).first()

        total_revenue = float(payments[0] or 0.0)
        payment_count = payments[1] or 0

        orders = db.query(
            func.sum(SMSOrder.cost_coins),
            func.count(SMSOrder.id),
        ).filter(
            func.date(SMSOrder.created_at) >= period_start,
            func.date(SMSOrder.created_at) <= period_end,
        ).first()

        total_cost_coins = float(orders[0] or 0.0)
        order_count = orders[1] or 0

        avg_cost_per_order = total_cost_coins / order_count if order_count else 0
        operating_expenses = total_revenue * 0.3
        net_profit = total_revenue - total_cost_coins - operating_expenses

        breakdown = {
            "revenue": {"total_usd": total_revenue, "payment_count": payment_count},
            "costs": {"total_coins": total_cost_coins, "order_count": order_count,
                      "avg_cost_per_order": avg_cost_per_order},
            "operating_expenses_usd": operating_expenses,
            "gross_profit_usd": total_revenue - total_cost_coins,
            "net_profit_usd": net_profit,
        }

        report = PnLReport(
            id=gen_uuid(),
            period_start=period_start,
            period_end=period_end,
            total_revenue=total_revenue,
            total_cost=total_cost_coins,
            gross_profit=total_revenue - total_cost_coins,
            operating_expenses=operating_expenses,
            net_profit=net_profit,
            breakdown=breakdown,
            generated_by=generated_by,
        )
        db.add(report)
        db.commit()
        return report

    @staticmethod
    def get_reports(db: Session, limit: int = 12, offset: int = 0) -> list[PnLReport]:
        return db.query(PnLReport).order_by(PnLReport.period_start.desc()).offset(offset).limit(limit).all()
