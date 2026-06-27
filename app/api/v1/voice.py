from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.response import success_response
from app.domain.models import User
from app.services.voice_service import VoiceService


class VoicePurchaseRequest(BaseModel):
    service: str
    country: str

router = APIRouter(prefix="/user/voice", tags=["Voice"])


@router.get("/services")
async def voice_services(
    request: Request,
    current_user: User = Depends(get_current_user),
):
    svc = VoiceService(None)
    services = await svc.get_voice_services()
    return success_response(services, request_id=getattr(request.state, "request_id", ""))


@router.post("/purchase")
async def voice_purchase(
    body: VoicePurchaseRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ip = request.client.host if request and request.client else ""
    request_id_val = getattr(request.state, "request_id", "")
    svc = VoiceService(db)
    result = await svc.purchase_voice(
        user=current_user,
        service=body.service,
        country=body.country,
        ip_address=ip,
        request_id=request_id_val,
    )
    return success_response(result, request_id=request_id_val)
