from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.response import success_response
from app.domain.models import Waitlist, gen_uuid

router = APIRouter(prefix="/waitlist", tags=["Waitlist"])


class WaitlistJoinRequest(BaseModel):
    email: EmailStr
    name: str = None
    source: str = "landing_page"


@router.post("/join")
async def join_waitlist(
    body: WaitlistJoinRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    existing = db.query(Waitlist).filter(Waitlist.email == body.email.lower()).first()
    if existing:
        return success_response({"message": "البريد الإلكتروني مسجل بالفعل في قائمة الانتظار"},
                              request_id=getattr(request.state, "request_id", ""))
    entry = Waitlist(
        id=gen_uuid(), email=body.email.lower(),
        name=body.name, source=body.source,
    )
    db.add(entry)
    db.commit()
    return success_response({"message": "تم التسجيل في قائمة الانتظار بنجاح"},
                          request_id=getattr(request.state, "request_id", ""))
