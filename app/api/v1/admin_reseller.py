from datetime import datetime
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
from app.services.reseller_service import ResellerService

router = APIRouter(prefix="/admin/reseller", tags=["Admin Reseller"])


class CreateResellerAccount(BaseModel):
    user_id: str
    volume_discount: float = 0.0
    credit_limit: float = 0.0
    custom_markup: Optional[float] = None
    auto_topup_enabled: bool = False
    auto_topup_threshold: float = 0.0
    auto_topup_amount: float = 0.0
    tier: str = "basic"


class UpdateResellerAccount(BaseModel):
    tier: Optional[str] = None
    volume_discount: Optional[float] = None
    custom_markup: Optional[float] = None
    credit_limit: Optional[float] = None
    auto_topup_enabled: Optional[bool] = None
    auto_topup_threshold: Optional[float] = None
    auto_topup_amount: Optional[float] = None


class CreateSubAccount(BaseModel):
    reseller_account_id: str
    name: str
    email: str
    rate_multiplier: float = 1.0
    coins: float = 0.0
    usage_limit: Optional[float] = None
    expires_at: Optional[datetime] = None


class UpdateSubAccount(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    usage_limit: Optional[float] = None
    rate_multiplier: Optional[float] = None
    expires_at: Optional[datetime] = None


class AllocateCredit(BaseModel):
    reseller_account_id: str = ""
    sub_account_id: str
    amount: float
    allocation_type: str = "manual"
    notes: Optional[str] = None


class BulkAllocate(BaseModel):
    reseller_account_id: str
    sub_account_ids: list[str]
    amount: float
    notes: Optional[str] = None


@router.post("/accounts")
async def create_account(
    body: CreateResellerAccount,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = ResellerService.create_account(db, body.user_id, body.model_dump())

    AuditService.log(db, admin_user.id, "reseller.account.create", "reseller_account", result.get("id", ""),
                    {"user_id": body.user_id})
    return success_response(result)


@router.get("/accounts")
async def list_accounts(
    is_active: Optional[bool] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = ResellerService.list_accounts(db, page, per_page, is_active)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/accounts/{user_id}")
async def get_account(
    user_id: str,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = ResellerService.get_account(db, user_id)
    if not result:
        raise AppException(code="not_found", message="حساب الريسلر غير موجود", status_code=404)
    return success_response(result)


@router.put("/accounts/{user_id}")
async def update_account(
    user_id: str,
    body: UpdateResellerAccount,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = ResellerService.update_account(db, user_id, body.model_dump(exclude_none=True))
    if not result:
        raise AppException(code="not_found", message="حساب الريسلر غير موجود", status_code=404)
    return success_response(result)


@router.post("/accounts/{user_id}/toggle")
async def toggle_account(
    user_id: str,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = ResellerService.toggle_account(db, user_id)
    if not result:
        raise AppException(code="not_found", message="حساب الريسلر غير موجود", status_code=404)

    AuditService.log(db, admin_user.id, "reseller.account.toggle", "reseller_account", user_id, {})
    return success_response(result)


@router.post("/sub-accounts")
async def create_sub_account(
    body: CreateSubAccount,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = ResellerService.create_sub_account(db, body.reseller_account_id, body.model_dump())

    AuditService.log(db, admin_user.id, "reseller.sub_account.create", "sub_account", result.get("id", ""),
                    {"reseller_account_id": body.reseller_account_id, "name": body.name})
    return success_response(result)


@router.get("/sub-accounts")
async def list_sub_accounts(
    reseller_account_id: Optional[str] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = ResellerService.list_sub_accounts(db, reseller_account_id, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/sub-accounts/{sub_account_id}")
async def get_sub_account(
    sub_account_id: str,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = ResellerService.get_sub_account(db, sub_account_id)
    if not result:
        raise AppException(code="not_found", message="الحساب الفرعي غير موجود", status_code=404)
    return success_response(result)


@router.put("/sub-accounts/{sub_account_id}")
async def update_sub_account(
    sub_account_id: str,
    body: UpdateSubAccount,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = ResellerService.update_sub_account(db, sub_account_id, body.model_dump(exclude_none=True))
    if not result:
        raise AppException(code="not_found", message="الحساب الفرعي غير موجود", status_code=404)
    return success_response(result)


@router.post("/sub-accounts/{sub_account_id}/toggle")
async def toggle_sub_account(
    sub_account_id: str,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = ResellerService.toggle_sub_account(db, sub_account_id)
    if not result:
        raise AppException(code="not_found", message="الحساب الفرعي غير موجود", status_code=404)
    return success_response(result)


@router.post("/credit/allocate")
async def allocate_credit(
    body: AllocateCredit,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = ResellerService.allocate_credit(
        db, body.reseller_account_id, body.sub_account_id, body.amount,
        body.allocation_type, body.notes,
    )
    if "error" in result:
        raise AppException(code="not_found", message=result["error"], status_code=404)
    return success_response(result)


@router.get("/credit/history")
async def get_credit_history(
    sub_account_id: str = Query(...),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = ResellerService.get_credit_history(db, sub_account_id, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.post("/credit/bulk")
async def bulk_allocate(
    body: BulkAllocate,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = ResellerService.bulk_allocate(db, body.reseller_account_id, body.sub_account_ids, body.amount, body.notes)
    return success_response(result)


@router.get("/credit/bulk/{operation_id}")
async def get_bulk_operation(
    operation_id: str,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = ResellerService.get_bulk_operation(db, operation_id)
    if not result:
        raise AppException(code="not_found", message="العملية غير موجودة", status_code=404)
    return success_response(result)


@router.get("/transactions")
async def list_transactions(
    sub_account_id: str = Query(...),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = ResellerService.get_transactions(db, sub_account_id, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/analytics/{reseller_id}")
async def get_analytics(
    reseller_id: str,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = ResellerService.get_analytics(db, reseller_id)
    return success_response(result)
