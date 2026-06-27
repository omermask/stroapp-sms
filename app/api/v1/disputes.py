from typing import Optional

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import User
from app.services.dispute_service import DisputeService

router = APIRouter(prefix="/disputes", tags=["Disputes"])


class CreateDispute(BaseModel):
    order_id: Optional[str] = None
    reason: str = "other"
    dispute_type: str = "billing"
    description: str = ""
    priority: str = "normal"


class AddComment(BaseModel):
    content: str


@router.post("")
async def create_dispute(
    body: CreateDispute,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = DisputeService.create_dispute(db, current_user.id, body.model_dump())
    return success_response(result)


@router.get("")
async def list_my_disputes(
    status: Optional[str] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    items, total = DisputeService.get_user_disputes(db, current_user.id, status, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/{dispute_id}")
async def get_dispute(
    dispute_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = DisputeService.get_dispute_detail(db, dispute_id, current_user.id)
    if not result:
        raise AppException(code="not_found", message="النزاع غير موجود", status_code=404)
    return success_response(result)


@router.post("/{dispute_id}/comments")
async def add_comment(
    dispute_id: str,
    body: AddComment,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not body.content.strip():
        raise AppException(code="validation_error", message="محتوى التعليق مطلوب")
    result = DisputeService.add_comment(db, dispute_id, current_user.id, "user", body.content)
    return success_response(result)
