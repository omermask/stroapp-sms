from fastapi import APIRouter, Depends, Query, Request
from fastapi.responses import Response
from sqlalchemy.orm import Session

from app.core.config import get_settings, get_app_setting
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import Invoice, PaymentLog, Transaction, User
from app.services.invoice_service import InvoiceService

router = APIRouter(prefix="/user/invoices", tags=["Invoices"])


@router.get("")
async def list_invoices(
    request: Request,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = InvoiceService(db)
    invoices = svc.get_user_invoices(current_user.id, limit, offset)
    return success_response([{
        "id": inv.id, "invoice_number": inv.invoice_number,
        "amount_usd": inv.amount_usd, "amount_coins": inv.amount_coins,
        "status": inv.status, "total_amount": inv.total_amount,
        "created_at": inv.created_at.isoformat() if inv.created_at else None,
        "paid_at": inv.paid_at.isoformat() if inv.paid_at else None,
    } for inv in invoices], request_id=getattr(request.state, "request_id", ""))


@router.post("/create-from-transaction/{transaction_id}")
async def create_invoice_from_transaction(
    request: Request,
    transaction_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    tx = db.query(Transaction).filter(
        Transaction.id == transaction_id,
        Transaction.user_id == current_user.id,
    ).first()
    if not tx:
        raise AppException("NOT_FOUND", "المعاملة غير موجودة", 404)

    coins_per_usd = get_app_setting(db, "coins_per_usd", get_settings().coins_per_usd) or 100
    usd_amount = tx.amount / float(coins_per_usd) if tx.amount else 0.0

    svc = InvoiceService(db)
    items = [{
        "description": tx.description or tx.type,
        "amount": round(usd_amount, 2),
        "reference": tx.reference or tx.id,
    }]
    inv = svc.create_invoice(
        user_id=current_user.id,
        items=items,
        notes=f"Transaction: {tx.id}",
    )
    if tx.type == "deposit" and tx.amount > 0:
        svc.mark_paid(inv.id)

    inv = svc.get_invoice(inv.id)
    return success_response({
        "id": inv.id, "invoice_number": inv.invoice_number,
        "amount_usd": inv.amount_usd, "amount_coins": inv.amount_coins,
        "status": inv.status, "items": inv.items,
        "tax_amount": inv.tax_amount, "total_amount": inv.total_amount,
        "created_at": inv.created_at.isoformat() if inv.created_at else None,
        "paid_at": inv.paid_at.isoformat() if inv.paid_at else None,
    }, request_id=getattr(request.state, "request_id", ""))


@router.get("/{invoice_id}")
async def get_invoice(
    request: Request,
    invoice_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = InvoiceService(db)
    inv = svc.get_invoice(invoice_id)
    if not inv or inv.user_id != current_user.id:
        raise AppException("NOT_FOUND", "الفاتورة غير موجودة", 404)
    return success_response({
        "id": inv.id, "invoice_number": inv.invoice_number,
        "amount_usd": inv.amount_usd, "amount_coins": inv.amount_coins,
        "status": inv.status, "items": inv.items,
        "billing_address": inv.billing_address,
        "tax_amount": inv.tax_amount, "total_amount": inv.total_amount,
        "currency": inv.currency, "notes": inv.notes,
        "created_at": inv.created_at.isoformat() if inv.created_at else None,
        "paid_at": inv.paid_at.isoformat() if inv.paid_at else None,
    }, request_id=getattr(request.state, "request_id", ""))


@router.get("/{invoice_id}/pdf")
async def download_invoice_pdf(
    request: Request,
    invoice_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = InvoiceService(db)
    inv = svc.get_invoice(invoice_id)
    if not inv or inv.user_id != current_user.id:
        raise AppException("NOT_FOUND", "الفاتورة غير موجودة", 404)

    pdf_bytes = svc.generate_pdf(invoice_id)
    if not pdf_bytes:
        raise AppException("PDF_ERROR", "تعذر إنشاء ملف PDF", 500)

    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="invoice_{inv.invoice_number}.pdf"'},
    )
