from typing import Optional

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, get_current_admin
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import User
from app.services.ledger_service import LedgerService


class TransferRequest(BaseModel):
    to_user_id: str
    currency: str = "USD"
    amount: float
    description: str = ""

router = APIRouter(prefix="/user/ledger", tags=["Ledger"])


@router.get("/balance")
async def get_balance(
    request: Request,
    currency: str = Query(default="USD"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    balance = LedgerService.get_balance(db, current_user.id, currency)
    return success_response({"currency": currency, "balance": balance},
                           request_id=getattr(request.state, "request_id", ""))


@router.get("/balances")
async def get_all_balances(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    balances = LedgerService.get_all_balances(db, current_user.id)
    return success_response(balances, request_id=getattr(request.state, "request_id", ""))


@router.get("/history")
async def get_history(
    request: Request,
    currency: str = Query(default=None),
    limit: int = Query(default=100, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    entries = LedgerService.get_history(db, current_user.id, currency, limit, offset)
    return success_response([{
        "id": e.id, "currency": e.currency, "amount": e.amount,
        "balance_before": e.balance_before, "balance_after": e.balance_after,
        "entry_type": e.entry_type, "description": e.description,
        "reference_type": e.reference_type, "reference_id": e.reference_id,
        "created_at": e.created_at.isoformat() if e.created_at else None,
    } for e in entries], request_id=getattr(request.state, "request_id", ""))


@router.post("/transfer")
async def transfer(
    request: Request,
    body: TransferRequest,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    if body.amount <= 0:
        raise AppException("VALIDATION_ERROR", "المبلغ يجب أن يكون أكبر من صفر", 400)
    debit, credit = LedgerService.transfer(db, _admin.id, body.to_user_id,
                                            body.currency, body.amount, body.description)
    return success_response({
        "debit_id": debit.id,
        "credit_id": credit.id,
        "amount": body.amount,
        "currency": body.currency,
    }, request_id=getattr(request.state, "request_id", ""))
