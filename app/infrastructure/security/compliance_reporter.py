from datetime import date, datetime, timezone, timedelta

from sqlalchemy.orm import Session

from app.core.logging import get_logger
from app.domain.models import (
    AuditLog, KYCProfile, Dispute, ReconciliationLog,
    RevenueRecognition, BalanceMismatchAlert, gen_uuid,
)

logger = get_logger(__name__)


class ComplianceReporter:
    @staticmethod
    def generate_report(db: Session, start_date: date, end_date: date) -> dict:
        return {
            "audit_events": ComplianceReporter._audit_summary(db, start_date, end_date),
            "kyc_review": ComplianceReporter._kyc_summary(db, start_date, end_date),
            "dispute_activity": ComplianceReporter._dispute_summary(db, start_date, end_date),
            "financial_reconciliation": ComplianceReporter._reconciliation_summary(db, start_date, end_date),
            "revenue_recognition": ComplianceReporter._revenue_summary(db, start_date, end_date),
            "balance_alerts": ComplianceReporter._balance_alert_summary(db, start_date, end_date),
            "report_metadata": {
                "generated_at": datetime.now(timezone.utc).isoformat(),
                "period": f"{start_date} — {end_date}",
            },
        }

    @staticmethod
    def _audit_summary(db: Session, start_date: date, end_date: date) -> dict:
        total = db.query(AuditLog).filter(
            AuditLog.created_at >= datetime.combine(start_date, datetime.min.time(), tzinfo=timezone.utc),
            AuditLog.created_at <= datetime.combine(end_date, datetime.max.time(), tzinfo=timezone.utc),
        ).count()
        return {"total_events": total}

    @staticmethod
    def _kyc_summary(db: Session, start_date: date, end_date: date) -> dict:
        return {
            "pending": db.query(KYCProfile).filter(KYCProfile.status == "pending").count(),
            "verified": db.query(KYCProfile).filter(KYCProfile.status == "verified").count(),
            "rejected": db.query(KYCProfile).filter(KYCProfile.status == "rejected").count(),
        }

    @staticmethod
    def _dispute_summary(db: Session, start_date: date, end_date: date) -> dict:
        return {
            "open": db.query(Dispute).filter(Dispute.status == "open").count(),
            "resolved": db.query(Dispute).filter(Dispute.status == "resolved").count(),
            "escalated": db.query(Dispute).filter(Dispute.status == "escalated").count(),
        }

    @staticmethod
    def _reconciliation_summary(db: Session, start_date: date, end_date: date) -> dict:
        total = db.query(ReconciliationLog).filter(
            ReconciliationLog.created_at >= datetime.combine(start_date, datetime.min.time(), tzinfo=timezone.utc),
            ReconciliationLog.created_at <= datetime.combine(end_date, datetime.max.time(), tzinfo=timezone.utc),
        ).count()
        with_discrepancies = db.query(ReconciliationLog).filter(
            ReconciliationLog.status == "discrepancy_found",
        ).count()
        return {"total_runs": total, "discrepancies_found": with_discrepancies}

    @staticmethod
    def _revenue_summary(db: Session, start_date: date, end_date: date) -> dict:
        rows = db.query(RevenueRecognition).filter(
            RevenueRecognition.recognition_date >= start_date,
            RevenueRecognition.recognition_date <= end_date,
        ).all()
        gross = sum(r.total_amount for r in rows)
        net = sum(r.recognized_amount for r in rows)
        provider_cost = 0.0
        return {"total_transactions": len(rows), "gross_revenue": gross, "net_revenue": net, "provider_costs": provider_cost}

    @staticmethod
    def _balance_alert_summary(db: Session, start_date: date, end_date: date) -> dict:
        return {
            "open": db.query(BalanceMismatchAlert).filter(BalanceMismatchAlert.resolved_at.is_(None)).count(),
            "resolved": db.query(BalanceMismatchAlert).filter(BalanceMismatchAlert.resolved_at.is_not(None)).count(),
        }


compliance_reporter = ComplianceReporter()
