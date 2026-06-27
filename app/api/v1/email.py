from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.response import success_response
from app.domain.models import User
from app.services.email_service import EmailService

router = APIRouter(prefix="/user/email", tags=["Email"])


@router.get("/temp")
async def get_temp_email(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = EmailService(db)
    try:
        result = await svc.get_or_create_temp_email(current_user.id)
        return success_response(result, request_id=getattr(request.state, "request_id", ""))
    finally:
        await svc.close()


@router.get("/temp/messages")
async def get_temp_email_messages(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = EmailService(db)
    try:
        messages = await svc.get_messages(current_user.id)
        return success_response(messages, request_id=getattr(request.state, "request_id", ""))
    finally:
        await svc.close()


@router.delete("/temp")
async def delete_temp_email(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = EmailService(db)
    try:
        result = await svc.delete_temp_email(current_user.id)
        return success_response(result, request_id=getattr(request.state, "request_id", ""))
    finally:
        await svc.close()
