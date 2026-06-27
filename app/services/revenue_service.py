from datetime import datetime, timezone, timedelta, date
from decimal import Decimal
from typing import Optional

from sqlalchemy import func, desc
from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.core.logging import get_logger
from app.domain.models import RevenueRecognition, RevenueAdjustment, \
    DeferredRevenueSchedule, TaxJurisdictionConfig, TaxReport, \
    TaxExemptionCertificate, ProviderSettlement, ProviderCostTracking, \
    ProviderReconciliation, ProviderAgreement, FinancialStatement, \
    OperatingMetrics, PaymentLog, SMSOrder, gen_uuid

logger = get_logger(__name__)

DEFAULT_TAX_RATES = {
    "SA": 0.15, "AE": 0.05, "EG": 0.14, "TR": 0.18,
    "US": 0.0, "GB": 0.20, "DE": 0.19, "FR": 0.20,
    "IN": 0.18, "CN": 0.13,
    "default": 0.0,
}


class RevenueService:

    # ----- Revenue methods (used by admin_financial.py) -----

    @staticmethod
    def get_revenue_summary(db: Session, start_date: date, end_date: date) -> dict:
        recognized = db.query(
            func.sum(RevenueRecognition.recognized_amount),
        ).filter(
            RevenueRecognition.recognition_date >= start_date,
            RevenueRecognition.recognition_date <= end_date,
        ).scalar() or 0

        total_revenue = db.query(func.sum(PaymentLog.amount_usd)).filter(
            PaymentLog.created_at >= datetime.combine(start_date, datetime.min.time(), tzinfo=timezone.utc),
            PaymentLog.created_at <= datetime.combine(end_date, datetime.max.time(), tzinfo=timezone.utc),
            PaymentLog.status == "completed",
        ).scalar() or 0

        return {
            "start_date": start_date.isoformat(),
            "end_date": end_date.isoformat(),
            "recognized_revenue": float(recognized),
            "total_revenue_usd": float(total_revenue),
            "deferred_revenue": float(recognized) * 0.3 if recognized else 0,
        }

    @staticmethod
    def get_revenue_details(db: Session, page: int = 1, per_page: int = 20) -> tuple[list, int]:
        q = db.query(RevenueRecognition).order_by(desc(RevenueRecognition.recognition_date))
        total = q.count()
        items = q.offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": r.id, "user_id": r.user_id, "order_id": r.order_id,
                "total_amount": r.total_amount, "recognized_amount": r.recognized_amount,
                "recognition_method": r.recognition_method,
                "recognition_date": r.recognition_date.isoformat() if r.recognition_date else None,
            }
            for r in items
        ], total

    @staticmethod
    def adjust_revenue(db: Session, data: dict) -> dict:
        adj_type = data.get("adjustment_type", "correction")
        if adj_type not in ("correction", "refund", "chargeback", "write_off", "promotion"):
            raise AppException(code="validation_error", message="نوع التسوية غير صالح")
        amount = data.get("amount", 0)
        if not isinstance(amount, (int, float)) or abs(amount) > 1_000_000:
            raise AppException(code="validation_error", message="المبلغ غير صالح")
        adj = RevenueAdjustment(
            id=gen_uuid(),
            recognition_id=data.get("recognition_id"),
            adjustment_type=adj_type,
            amount=amount,
            currency=data.get("currency", "SAR"),
            reason=data.get("reason", ""),
            approved_by=data.get("approved_by"),
        )
        db.add(adj)
        db.commit()
        return {"id": adj.id, "amount": adj.amount, "type": adj.adjustment_type}

    @staticmethod
    def get_adjustments(db: Session, page: int = 1, per_page: int = 20) -> tuple[list, int]:
        q = db.query(RevenueAdjustment).order_by(desc(RevenueAdjustment.adjustment_date))
        total = q.count()
        items = q.offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": a.id, "recognition_id": a.recognition_id,
                "adjustment_type": a.adjustment_type, "amount": a.amount,
                "reason": a.reason, "approved_by": a.approved_by,
                "adjustment_date": a.adjustment_date.isoformat() if a.adjustment_date else None,
            }
            for a in items
        ], total

    # ----- Tax methods -----

    @staticmethod
    def get_tax_configs(db: Session) -> list[dict]:
        configs = db.query(TaxJurisdictionConfig).all()
        return [
            {
                "id": c.id, "jurisdiction": c.jurisdiction,
                "tax_type": c.tax_type, "tax_rate": c.tax_rate,
                "is_active": c.is_active,
                "effective_from": c.effective_from.isoformat() if c.effective_from else None,
                "effective_to": c.effective_to.isoformat() if c.effective_to else None,
            }
            for c in configs
        ]

    @staticmethod
    def upsert_tax_config(db: Session, data: dict) -> dict:
        tax_rate = data.get("tax_rate", 0.0)
        if not isinstance(tax_rate, (int, float)) or tax_rate < 0 or tax_rate > 1:
            raise AppException(code="validation_error", message="tax_rate يجب أن يكون بين 0 و 1")
        config = db.query(TaxJurisdictionConfig).filter(
            TaxJurisdictionConfig.jurisdiction == data["jurisdiction"],
            TaxJurisdictionConfig.tax_type == data.get("tax_type", "vat"),
        ).first()
        if config:
            config.tax_rate = tax_rate
            config.is_active = data.get("is_active", config.is_active)
        else:
            config = TaxJurisdictionConfig(
                id=gen_uuid(),
                jurisdiction=data["jurisdiction"],
                tax_type=data.get("tax_type", "vat"),
                tax_rate=tax_rate,
                is_active=data.get("is_active", True),
            )
            db.add(config)
        db.commit()
        return {"id": config.id, "jurisdiction": config.jurisdiction, "tax_rate": config.tax_rate}

    @staticmethod
    def generate_tax_report(db: Session, data: dict) -> dict:
        period_start = data.get("period_start")
        period_end = data.get("period_end")
        jurisdiction = data.get("jurisdiction", "ALL")
        if isinstance(period_start, str):
            period_start = date.fromisoformat(period_start)
        if isinstance(period_end, str):
            period_end = date.fromisoformat(period_end)

        payments = db.query(PaymentLog).filter(
            PaymentLog.status == "completed",
            func.date(PaymentLog.created_at) >= period_start,
            func.date(PaymentLog.created_at) <= period_end,
        ).all()

        total_revenue = sum(p.amount_usd for p in payments)
        effective_rate = DEFAULT_TAX_RATES.get("default", 0.0)
        total_tax = total_revenue * effective_rate

        report = TaxReport(
            id=gen_uuid(),
            report_type=data.get("report_type", "vat"),
            jurisdiction=jurisdiction,
            period_start=period_start,
            period_end=period_end,
            total_tax=total_tax,
            report_data={"total_revenue": total_revenue, "payments_count": len(payments)},
            status="draft",
        )
        db.add(report)
        db.commit()
        return {"id": report.id, "period_start": period_start.isoformat(), "period_end": period_end.isoformat()}

    @staticmethod
    def get_tax_reports(db: Session, page: int = 1, per_page: int = 20) -> tuple[list, int]:
        q = db.query(TaxReport).order_by(desc(TaxReport.created_at))
        total = q.count()
        items = q.offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": r.id, "report_type": r.report_type,
                "jurisdiction": r.jurisdiction,
                "period_start": r.period_start.isoformat() if r.period_start else None,
                "period_end": r.period_end.isoformat() if r.period_end else None,
                "total_tax": r.total_tax, "status": r.status,
            }
            for r in items
        ], total

    @staticmethod
    def get_tax_exemptions(db: Session, page: int = 1, per_page: int = 20) -> tuple[list, int]:
        q = db.query(TaxExemptionCertificate).order_by(desc(TaxExemptionCertificate.created_at))
        total = q.count()
        items = q.offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": e.id, "user_id": e.user_id,
                "certificate_number": e.certificate_number,
                "exemption_type": e.exemption_type, "status": e.status,
                "valid_from": e.valid_from.isoformat() if e.valid_from else None,
                "valid_until": e.valid_until.isoformat() if e.valid_until else None,
            }
            for e in items
        ], total

    # ----- Provider agreement methods -----

    @staticmethod
    def get_agreements(db: Session) -> list[dict]:
        agreements = db.query(ProviderAgreement).filter(
            ProviderAgreement.is_active == True,
        ).all()
        return [
            {
                "id": a.id, "provider_name": a.provider_name,
                "commission_rate": a.commission_rate,
                "billing_cycle": a.billing_cycle,
                "terms": a.terms,
                "effective_date": a.effective_date.isoformat() if a.effective_date else None,
            }
            for a in agreements
        ]

    @staticmethod
    def upsert_agreement(db: Session, data: dict) -> dict:
        agreement = db.query(ProviderAgreement).filter(
            ProviderAgreement.provider_name == data["provider_name"],
        ).first()
        if agreement:
            agreement.commission_rate = data.get("commission_rate", agreement.commission_rate)
            agreement.billing_cycle = data.get("billing_cycle", agreement.billing_cycle)
            agreement.terms = data.get("terms", agreement.terms)
        else:
            agreement = ProviderAgreement(
                id=gen_uuid(),
                provider_name=data["provider_name"],
                commission_rate=data.get("commission_rate", 0.0),
                billing_cycle=data.get("billing_cycle", "monthly"),
                terms=data.get("terms"),
            )
            db.add(agreement)
        db.commit()
        return {"id": agreement.id, "provider_name": agreement.provider_name}

    # ----- Provider cost methods -----

    @staticmethod
    def get_costs(db: Session, provider_name: Optional[str] = None,
                  page: int = 1, per_page: int = 20) -> tuple[list, int]:
        q = db.query(ProviderCostTracking)
        if provider_name:
            q = q.filter(ProviderCostTracking.provider_name == provider_name)
        q = q.order_by(desc(ProviderCostTracking.cost_date))
        total = q.count()
        items = q.offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": c.id, "provider_name": c.provider_name,
                "service_type": c.service_type,
                "cost_per_unit": c.cost_per_unit,
                "units_consumed": c.units_consumed,
                "total_cost": c.total_cost,
                "currency": c.currency,
                "cost_date": c.cost_date.isoformat() if c.cost_date else None,
            }
            for c in items
        ], total

    @staticmethod
    def record_cost(db: Session, data: dict) -> dict:
        cost_per_unit = data.get("cost_per_unit", 0.0)
        units_consumed = data.get("units_consumed", 0)
        total_cost = data.get("total_cost", 0.0)
        if not isinstance(cost_per_unit, (int, float)) or cost_per_unit < 0:
            raise AppException(code="validation_error", message="cost_per_unit must be non-negative")
        if not isinstance(units_consumed, int) or units_consumed < 0:
            raise AppException(code="validation_error", message="units_consumed must be non-negative")
        if not isinstance(total_cost, (int, float)) or total_cost < 0:
            raise AppException(code="validation_error", message="total_cost must be non-negative")
        cost = ProviderCostTracking(
            id=gen_uuid(),
            provider_name=data["provider_name"],
            service_type=data.get("service_type"),
            cost_per_unit=cost_per_unit,
            units_consumed=units_consumed,
            total_cost=total_cost,
            currency=data.get("currency", "SAR"),
            cost_date=data.get("cost_date", datetime.now(timezone.utc).date()),
        )
        db.add(cost)
        db.commit()
        return {"id": cost.id, "total_cost": cost.total_cost}

    # ----- Settlement methods -----

    @staticmethod
    def get_settlements(db: Session, provider_name: Optional[str] = None,
                        page: int = 1, per_page: int = 20) -> tuple[list, int]:
        q = db.query(ProviderSettlement)
        if provider_name:
            q = q.filter(ProviderSettlement.provider_name == provider_name)
        q = q.order_by(desc(ProviderSettlement.settlement_period_start))
        total = q.count()
        items = q.offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": s.id, "provider_name": s.provider_name,
                "period_start": s.settlement_period_start.isoformat() if s.settlement_period_start else None,
                "period_end": s.settlement_period_end.isoformat() if s.settlement_period_end else None,
                "gross_amount": s.gross_amount,
                "commission_amount": s.commission_amount,
                "net_amount": s.net_amount,
                "status": s.status,
                "settlement_date": s.settlement_date.isoformat() if s.settlement_date else None,
            }
            for s in items
        ], total

    @staticmethod
    def create_settlement(db: Session, data: dict) -> dict:
        settlement = ProviderSettlement(
            id=gen_uuid(),
            provider_name=data["provider_name"],
            settlement_period_start=data.get("period_start", datetime.now(timezone.utc).date()),
            settlement_period_end=data.get("period_end", datetime.now(timezone.utc).date()),
            gross_amount=data.get("gross_amount", 0.0),
            commission_amount=data.get("commission_amount", 0.0),
            net_amount=data.get("net_amount", 0.0),
            status="pending",
        )
        db.add(settlement)
        db.commit()
        return {"id": settlement.id, "status": "pending"}

    # ----- Reconciliation methods -----

    @staticmethod
    def get_provider_reconciliations(db: Session, provider_name: Optional[str] = None,
                                     page: int = 1, per_page: int = 20) -> tuple[list, int]:
        q = db.query(ProviderReconciliation)
        if provider_name:
            q = q.filter(ProviderReconciliation.provider_name == provider_name)
        q = q.order_by(desc(ProviderReconciliation.reconciliation_date))
        total = q.count()
        items = q.offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": r.id, "provider_name": r.provider_name,
                "reconciliation_date": r.reconciliation_date.isoformat() if r.reconciliation_date else None,
                "period_start": r.period_start.isoformat() if r.period_start else None,
                "period_end": r.period_end.isoformat() if r.period_end else None,
                "our_count": r.our_count, "our_amount": r.our_amount,
                "provider_count": r.provider_count, "provider_amount": r.provider_amount,
                "variance_count": r.variance_count, "variance_amount": r.variance_amount,
                "status": r.status,
            }
            for r in items
        ], total

    # ----- Financial statements -----

    @staticmethod
    def get_financial_statements(db: Session, period: Optional[str] = None,
                                 page: int = 1, per_page: int = 20) -> tuple[list, int]:
        q = db.query(FinancialStatement)
        if period:
            q = q.filter(FinancialStatement.period == period)
        q = q.order_by(desc(FinancialStatement.period_start))
        total = q.count()
        items = q.offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": s.id, "statement_type": s.statement_type,
                "period": s.period,
                "period_start": s.period_start.isoformat() if s.period_start else None,
                "period_end": s.period_end.isoformat() if s.period_end else None,
                "total_revenue": s.total_revenue,
                "total_expenses": s.total_expenses,
                "net_income": s.net_income,
                "status": s.status,
            }
            for s in items
        ], total

    # ----- Operating metrics -----

    @staticmethod
    def get_operating_metrics(db: Session, period_from: Optional[date] = None,
                              period_to: Optional[date] = None) -> list[dict]:
        q = db.query(OperatingMetrics)
        if period_from:
            q = q.filter(OperatingMetrics.period_date >= period_from)
        if period_to:
            q = q.filter(OperatingMetrics.period_date <= period_to)
        items = q.order_by(desc(OperatingMetrics.period_date)).limit(90).all()
        return [
            {
                "period_date": m.period_date.isoformat() if m.period_date else None,
                "total_orders": m.total_orders,
                "successful_deliveries": m.successful_deliveries,
                "failed_deliveries": m.failed_deliveries,
                "total_messages": m.total_messages,
                "profit_margin": m.profit_margin,
                "active_users": m.active_users,
                "new_users": m.new_users,
            }
            for m in items
        ]

    # ----- GAAP Revenue Recognition (new) -----

    @staticmethod
    def recognize_revenue(db: Session, payment_log_id: str):
        payment = db.query(PaymentLog).filter(PaymentLog.id == payment_log_id).first()
        if not payment:
            return None

        existing = db.query(RevenueRecognition).filter(
            RevenueRecognition.id == payment_log_id,
        ).first()
        if existing:
            return existing

        if payment.amount_usd <= 100:
            recognized_now = payment.amount_usd
            deferred_amount = 0.0
        else:
            recognized_now = float(payment.amount_usd) * 0.7
            deferred_amount = float(payment.amount_usd) * 0.3
            schedule = DeferredRevenueSchedule(
                id=gen_uuid(),
                recognition_id=payment_log_id,
                scheduled_date=datetime.now(timezone.utc).date(),
                amount=deferred_amount,
            )
            db.add(schedule)

        recognition = RevenueRecognition(
            id=gen_uuid(),
            order_id=payment.id,
            user_id=payment.user_id,
            total_amount=payment.amount_usd,
            recognized_amount=recognized_now,
            recognition_method="at_point_of_sale" if payment.amount_usd <= 100 else "deferred",
            recognition_date=datetime.now(timezone.utc),
        )
        db.add(recognition)
        db.commit()
        return recognition

    @staticmethod
    def get_period_revenue(db: Session, period_start: date, period_end: date) -> dict:
        recognized = db.query(
            func.sum(RevenueRecognition.recognized_amount),
        ).filter(
            RevenueRecognition.recognition_date >= period_start,
            RevenueRecognition.recognition_date <= period_end,
        ).scalar() or 0

        deferred = db.query(
            func.sum(DeferredRevenueSchedule.amount),
        ).filter(
            DeferredRevenueSchedule.scheduled_date >= period_start,
            DeferredRevenueSchedule.scheduled_date <= period_end,
        ).scalar() or 0

        return {
            "period_start": period_start.isoformat(),
            "period_end": period_end.isoformat(),
            "recognized": float(recognized),
            "deferred": float(deferred),
            "total": float(recognized) + float(deferred),
        }

    @staticmethod
    def get_user_lifetime_value(db: Session, user_id: str) -> dict:
        payments = db.query(func.sum(PaymentLog.amount_usd)).filter(
            PaymentLog.user_id == user_id,
            PaymentLog.status == "completed",
        ).scalar() or 0

        first_payment = db.query(PaymentLog.created_at).filter(
            PaymentLog.user_id == user_id,
            PaymentLog.status == "completed",
        ).order_by(PaymentLog.created_at.asc()).first()

        payment_count = db.query(func.count(PaymentLog.id)).filter(
            PaymentLog.user_id == user_id,
            PaymentLog.status == "completed",
        ).scalar() or 0

        return {
            "user_id": user_id,
            "total_payments_usd": float(payments),
            "payment_count": payment_count,
            "average_payment_usd": float(payments) / payment_count if payment_count else 0,
            "first_payment_at": first_payment[0].isoformat() if first_payment and first_payment[0] else None,
        }

    @staticmethod
    def get_mrr(db: Session) -> float:
        now = datetime.now(timezone.utc)
        month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        total = db.query(func.sum(PaymentLog.amount_usd)).filter(
            PaymentLog.created_at >= month_start,
            PaymentLog.status == "completed",
        ).scalar() or 0
        return float(total)
