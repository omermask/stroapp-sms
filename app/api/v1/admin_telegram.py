from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.response import success_response
from app.domain.models import User
from app.services.telegram_service import TelegramService

router = APIRouter(prefix="/admin/telegram", tags=["Admin Telegram"])


@router.get("/connections")
async def list_connections(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = TelegramService.get_all_connections(db, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})
