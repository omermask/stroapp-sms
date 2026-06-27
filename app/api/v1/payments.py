from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.idempotency import IdempotencyService
from app.core.response import success_response
from app.domain.models import AuditLog, User
from app.services.audit_service import AuditService
from app.services.payment_service import PaymentService

router = APIRouter(prefix="/user/payments", tags=["Payments"])


class GooglePayRequest(BaseModel):
    payment_token: str
    product_id: str


class ApplePayRequest(BaseModel):
    payment_token: str
    product_id: str


class AppleIAPRequest(BaseModel):
    transaction_id: str
    product_id: str


class RefundRequest(BaseModel):
    log_id: str


@router.get("/products")
async def list_products(
    request: Request,
    provider: str = "google_pay",
    db: Session = Depends(get_db),
    _user: User = Depends(get_current_user),
):
    svc = PaymentService(db)
    products = svc.get_products(provider)
    return success_response(
        {"provider": provider, "products": products},
        request_id=getattr(request.state, "request_id", ""),
    )


@router.post("/google-pay")
async def google_pay(
    body: GooglePayRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    idempotency_key = request.headers.get("Idempotency-Key") or request.headers.get("x-idempotency-key")
    if idempotency_key:
        idem = IdempotencyService(db)
        cached = idem.get_response(idempotency_key)
        if cached:
            return success_response(cached, request_id=getattr(request.state, "request_id", ""))
        if not idem.check_and_set(idempotency_key):
            raise AppException("IDEMPOTENCY_ERROR", "تم استخدام هذا المفتاح مسبقاً", 409)

    ip = request.client.host if request.client else ""
    request_id_val = getattr(request.state, "request_id", "")
    svc = PaymentService(db)
    result = await svc.process_google_pay(current_user, body.payment_token, body.product_id)
    AuditService.log(db, current_user.id, "payment.deposit", "payment", None, {"provider": "google_pay", "product_id": body.product_id, "amount_usd": result.get("amount_usd"), "coins": result.get("coins"), "reference": result.get("reference")}, ip, request_id_val)
    if idempotency_key:
        idem.set_response(idempotency_key, result)
    return success_response(result, request_id=request_id_val)


@router.post("/apple-pay")
async def apple_pay(
    body: ApplePayRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    idempotency_key = request.headers.get("Idempotency-Key") or request.headers.get("x-idempotency-key")
    if idempotency_key:
        idem = IdempotencyService(db)
        cached = idem.get_response(idempotency_key)
        if cached:
            return success_response(cached, request_id=getattr(request.state, "request_id", ""))
        if not idem.check_and_set(idempotency_key):
            raise AppException("IDEMPOTENCY_ERROR", "تم استخدام هذا المفتاح مسبقاً", 409)

    ip = request.client.host if request.client else ""
    request_id_val = getattr(request.state, "request_id", "")
    svc = PaymentService(db)
    result = await svc.process_apple_pay(current_user, body.payment_token, body.product_id)
    AuditService.log(db, current_user.id, "payment.deposit", "payment", None, {"provider": "apple_pay", "product_id": body.product_id, "amount_usd": result.get("amount_usd"), "coins": result.get("coins"), "reference": result.get("reference")}, ip, request_id_val)
    if idempotency_key:
        idem.set_response(idempotency_key, result)
    return success_response(result, request_id=request_id_val)


@router.post("/iap/apple")
async def apple_iap(
    body: AppleIAPRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    idempotency_key = request.headers.get("Idempotency-Key") or request.headers.get("x-idempotency-key")
    if idempotency_key:
        idem = IdempotencyService(db)
        cached = idem.get_response(idempotency_key)
        if cached:
            return success_response(cached, request_id=getattr(request.state, "request_id", ""))
        if not idem.check_and_set(idempotency_key):
            raise AppException("IDEMPOTENCY_ERROR", "تم استخدام هذا المفتاح مسبقاً", 409)

    ip = request.client.host if request.client else ""
    request_id_val = getattr(request.state, "request_id", "")
    svc = PaymentService(db)
    result = await svc.process_apple_iap(current_user, body.transaction_id, body.product_id)
    AuditService.log(db, current_user.id, "payment.deposit", "payment", None, {"provider": "apple_iap", "product_id": body.product_id, "amount_usd": result.get("amount_usd"), "coins": result.get("coins"), "reference": result.get("reference")}, ip, request_id_val)
    if idempotency_key:
        idem.set_response(idempotency_key, result)
    return success_response(result, request_id=request_id_val)


@router.get("/history")
async def payment_history(
    request: Request,
    limit: int = Query(default=20, le=100),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = PaymentService(db)
    logs = svc.get_history(current_user.id, limit, offset)
    return success_response(logs, request_id=getattr(request.state, "request_id", ""))


@router.post("/refund")
async def refund_payment(
    body: RefundRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ip = request.client.host if request.client else ""
    request_id_val = getattr(request.state, "request_id", "")
    svc = PaymentService(db)
    result = svc.refund(current_user, body.log_id)
    AuditService.log(db, current_user.id, "payment.refund", "payment", body.log_id, {"coins_refunded": result.get("coins_refunded")}, ip, request_id_val)
    return success_response(result, request_id=request_id_val)
