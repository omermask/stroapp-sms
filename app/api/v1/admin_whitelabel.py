from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.response import success_response
from app.domain.models import User
from app.services.whitelabel_service import WhitelabelService

router = APIRouter(prefix="/admin/whitelabel", tags=["Admin Whitelabel"])


@router.get("/domains")
async def list_domains(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = WhitelabelService.list_all_domains(db, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})
