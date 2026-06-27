from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.response import success_response
from app.domain.models import User
from app.services.activity_service import ActivityService

router = APIRouter(prefix="/user/activity", tags=["Activity Feed"])


@router.get("/feed")
async def get_activity_feed(
    request: Request,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    activity_type: str = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    activities = ActivityService.get_user_activities(
        db, current_user.id, limit, offset, activity_type,
    )
    return success_response(
        [{
            "id": a.id, "activity_type": a.activity_type,
            "title": a.title, "description": a.description,
            "metadata": a.metadata_json,
            "created_at": a.created_at.isoformat() if a.created_at else None,
        } for a in activities],
        request_id=getattr(request.state, "request_id", ""),
    )
