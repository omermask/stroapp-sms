from typing import Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.domain.models import (
    BalanceMismatchAlert,
    ReconciliationLog,
    SMSOrder,
    gen_uuid,
)


class ReconciliationService:
    @staticmethod
    def reconcile_orders(db: Session, date_from: str, date_to: str, source: str = "auto") -> dict:
        orders = db.query(SMSOrder).filter(
            func.date(SMSOrder.created_at) >= date_from,
            func.date(SMSOrder.created_at) <= date_to,
        ).all()

        total_count = len(orders)
        total_amount = sum(o.cost_coins or 0 for o in orders)
        delivered = sum(1 for o in orders if o.status == "delivered")
        failed = sum(1 for o in orders if o.status == "failed")

        log = ReconciliationLog(
            id=gen_uuid(),
            reconciliation_type="daily_orders",
            source=source,
            status="completed",
            summary={
                "total_orders": total_count,
                "total_amount": total_amount,
                "delivered": delivered,
                "failed": failed,
                "date_from": date_from,
                "date_to": date_to,
            },
        )
        db.add(log)
        db.commit()
        return {
            "log_id": log.id,
            "total_orders": total_count,
            "total_amount": total_amount,
            "delivered": delivered,
            "failed": failed,
        }

    @staticmethod
    def get_logs(db: Session, rec_type: Optional[str] = None, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(ReconciliationLog)
        if rec_type:
            query = query.filter(ReconciliationLog.reconciliation_type == rec_type)
        query = query.order_by(ReconciliationLog.created_at.desc())
        total = query.count()
        items = query.offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": log.id,
                "reconciliation_type": log.reconciliation_type,
                "source": log.source,
                "status": log.status,
                "summary": log.summary,
                "discrepancies": log.discrepancies,
                "created_at": log.created_at.isoformat(),
            }
            for log in items
        ], total

    @staticmethod
    def get_alerts(db: Session, severity: Optional[str] = None, resolved: Optional[bool] = None,
                   page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(BalanceMismatchAlert)
        if severity:
            query = query.filter(BalanceMismatchAlert.severity == severity)
        if resolved is not None:
            query = query.filter(BalanceMismatchAlert.resolved_at.is_(None) if not resolved else BalanceMismatchAlert.resolved_at.isnot(None))
        query = query.order_by(BalanceMismatchAlert.created_at.desc())
        total = query.count()
        items = query.offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": a.id,
                "alert_type": a.alert_type,
                "severity": a.severity,
                "description": a.description,
                "expected_value": a.expected_value,
                "actual_value": a.actual_value,
                "variance": a.variance,
                "resolved_at": a.resolved_at.isoformat() if a.resolved_at else None,
                "resolved_by": a.resolved_by,
                "resolution_notes": a.resolution_notes,
                "created_at": a.created_at.isoformat(),
            }
            for a in items
        ], total

    @staticmethod
    def resolve_alert(db: Session, alert_id: str, admin_id: str, notes: str = "") -> Optional[dict]:
        alert = db.query(BalanceMismatchAlert).filter(BalanceMismatchAlert.id == alert_id).first()
        if not alert:
            return None
        alert.resolved_at = db.query(func.now()).scalar()
        alert.resolved_by = admin_id
        alert.resolution_notes = notes
        db.commit()
        return {"id": alert.id, "resolved": True, "resolved_by": admin_id}

    @staticmethod
    def report_balance_issue(db: Session, alert_type: str, severity: str, description: str,
                             expected_value: float, actual_value: float) -> dict:
        alert = BalanceMismatchAlert(
            id=gen_uuid(),
            alert_type=alert_type,
            severity=severity,
            description=description,
            expected_value=expected_value,
            actual_value=actual_value,
            variance=expected_value - actual_value,
        )
        db.add(alert)
        db.commit()
        return {"id": alert.id, "variance": alert.variance, "severity": severity}
