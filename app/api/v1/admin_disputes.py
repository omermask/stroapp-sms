from typing import Optional

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import User
from app.services.dispute_service import DisputeService

router = APIRouter(prefix="/admin/disputes", tags=["Admin Disputes"])


class UpdateDisputeStatus(BaseModel):
    status: str = ""
    note: str = ""


class ResolveDispute(BaseModel):
    resolution: str = ""
    note: str = ""
    refund_amount: float = 0


class AddAdminComment(BaseModel):
    content: str
    is_internal: bool = False


@router.get("/all")
async def list_all(
    status: Optional[str] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = DisputeService.get_all_disputes(db, status, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/{dispute_id}")
async def get_dispute(
    dispute_id: str,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = DisputeService.get_dispute_detail(db, dispute_id)
    if not result:
        raise AppException(code="not_found", message="النزاع غير موجود", status_code=404)
    return success_response(result)


@router.post("/{dispute_id}/status")
async def update_status(
    dispute_id: str,
    body: UpdateDisputeStatus,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = DisputeService.update_status(db, dispute_id, admin_user.id, body.status, body.note)
    if not result:
        raise AppException(code="not_found", message="النزاع غير موجود", status_code=404)
    return success_response(result)


@router.post("/{dispute_id}/resolve")
async def resolve_dispute(
    dispute_id: str,
    body: ResolveDispute,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = DisputeService.resolve_dispute(db, dispute_id, admin_user.id,
                                            body.resolution,
                                            body.note,
                                            body.refund_amount)
    if not result:
        raise AppException(code="not_found", message="النزاع غير موجود", status_code=404)
    return success_response(result)


@router.post("/{dispute_id}/comments")
async def add_admin_comment(
    dispute_id: str,
    body: AddAdminComment,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    if not body.content.strip():
        raise AppException(code="validation_error", message="محتوى التعليق مطلوب")
    result = DisputeService.add_comment(
        db, dispute_id, admin_user.id, "admin", body.content, body.is_internal,
    )
    return success_response(result)


@router.get("/stats")
async def get_stats(
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = DisputeService.get_stats(db)
    return success_response(result)
