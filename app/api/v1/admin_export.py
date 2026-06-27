import csv
import io
from datetime import date

from fastapi import APIRouter, Depends, Query, Request
from fastapi.responses import StreamingResponse
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.exceptions import AppException
from app.domain.models import User, SMSOrder, Transaction, PaymentLog, AuditLog

router = APIRouter(prefix="/admin/export", tags=["Admin Export"])


def _require_admin(_admin: User):
    pass


def _safe_csv(val):
    """Prevent CSV injection by prefixing dangerous leading characters."""
    if val is None:
        return ""
    s = str(val)
    if s and s[0] in ("=", "+", "-", "@", "\t", "\n", "\r"):
        return "'" + s
    return s


MAX_EXPORT_ROWS = 100_000


@router.get("/users")
async def export_users(
    request: Request,
    format: str = Query(default="csv"),
    limit: int = Query(default=10000, le=MAX_EXPORT_ROWS),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    users = db.query(User).order_by(User.created_at.desc()).offset(offset).limit(limit).all()
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["ID", "Email", "Display Name", "Coins", "Tier", "Is Admin",
                     "Is Banned", "Email Verified", "MFA Enabled", "Created At"])
    for u in users:
        writer.writerow([u.id, _safe_csv(u.email), _safe_csv(u.display_name), u.coins,
                         u.tier, u.is_admin, u.is_banned, u.email_verified,
                         u.mfa_enabled, u.created_at.isoformat() if u.created_at else ""])
    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=users_export.csv"},
    )


@router.get("/transactions")
async def export_transactions(
    request: Request,
    start_date: date = Query(default=None),
    end_date: date = Query(default=None),
    limit: int = Query(default=10000, le=MAX_EXPORT_ROWS),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    q = db.query(Transaction)
    if start_date and end_date:
        q = q.filter(func.date(Transaction.created_at) >= start_date,
                     func.date(Transaction.created_at) <= end_date)

    txns = q.order_by(Transaction.created_at.desc()).offset(offset).limit(limit).all()
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["ID", "User ID", "Amount", "Type", "Description", "Reference",
                     "Coins Before", "Coins After", "Created At"])
    for t in txns:
        writer.writerow([t.id, t.user_id, t.amount, _safe_csv(t.type),
                         _safe_csv(t.description), _safe_csv(t.reference),
                         t.coins_before, t.coins_after,
                         t.created_at.isoformat() if t.created_at else ""])
    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=transactions_export.csv"},
    )


@router.get("/payments")
async def export_payments(
    request: Request,
    start_date: date = Query(default=None),
    end_date: date = Query(default=None),
    status: str = Query(default=""),
    limit: int = Query(default=10000, le=MAX_EXPORT_ROWS),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    q = db.query(PaymentLog)
    if status:
        q = q.filter(PaymentLog.status == status)
    if start_date and end_date:
        q = q.filter(func.date(PaymentLog.created_at) >= start_date,
                     func.date(PaymentLog.created_at) <= end_date)

    payments = q.order_by(PaymentLog.created_at.desc()).offset(offset).limit(limit).all()
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["ID", "User ID", "Provider", "Product ID", "Amount USD",
                     "Coins", "Reference", "Status", "Created At"])
    for p in payments:
        writer.writerow([p.id, p.user_id, _safe_csv(p.provider), p.product_id,
                         p.amount_usd, p.coins, _safe_csv(p.reference),
                         _safe_csv(p.status),
                         p.created_at.isoformat() if p.created_at else ""])
    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=payments_export.csv"},
    )


@router.get("/audit-logs")
async def export_audit_logs(
    request: Request,
    start_date: date = Query(default=None),
    end_date: date = Query(default=None),
    action: str = Query(default=""),
    limit: int = Query(default=10000, le=MAX_EXPORT_ROWS),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    q = db.query(AuditLog)
    if action:
        q = q.filter(AuditLog.action == action)
    if start_date and end_date:
        q = q.filter(func.date(AuditLog.created_at) >= start_date,
                     func.date(AuditLog.created_at) <= end_date)

    logs = q.order_by(AuditLog.created_at.desc()).offset(offset).limit(limit).all()
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["ID", "User ID", "Action", "Resource Type", "Resource ID",
                     "IP Address", "Request ID", "Created At"])
    for l in logs:
        writer.writerow([l.id, l.user_id, _safe_csv(l.action),
                         _safe_csv(l.resource_type), _safe_csv(l.resource_id),
                         _safe_csv(l.ip_address), _safe_csv(l.request_id),
                         l.created_at.isoformat() if l.created_at else ""])
    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=audit_logs_export.csv"},
    )
