from typing import Optional

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import User
from app.services.audit_service import AuditService
from app.services.reconciliation_service import ReconciliationService

router = APIRouter(prefix="/admin/reconciliation", tags=["Admin Reconciliation"])


class RunReconciliation(BaseModel):
    date_from: Optional[str] = None
    date_to: Optional[str] = None
    source: str = "auto"


class ResolveAlert(BaseModel):
    notes: str = ""


@router.post("/run")
async def run_reconciliation(
    body: RunReconciliation,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = ReconciliationService.reconcile_orders(db, body.date_from, body.date_to, body.source)

    AuditService.log(db, admin_user.id, "reconciliation.run", "reconciliation", "",
                    {"source": body.source})
    return success_response(result)


@router.get("/logs")
async def get_logs(
    type: Optional[str] = Query(None, alias="type"),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = ReconciliationService.get_logs(db, type, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/alerts")
async def get_alerts(
    severity: Optional[str] = None,
    resolved: Optional[bool] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = ReconciliationService.get_alerts(db, severity, resolved, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.post("/alerts/{alert_id}/resolve")
async def resolve_alert(
    alert_id: str,
    body: ResolveAlert,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = ReconciliationService.resolve_alert(db, alert_id, admin_user.id, body.notes)
    if not result:
        raise AppException(code="not_found", message="التنبيه غير موجود", status_code=404)

    AuditService.log(db, admin_user.id, "reconciliation.alert.resolve", "reconciliation_alert", alert_id, {})
    return success_response(result)
