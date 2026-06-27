from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, field_validator
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import Preset, User, gen_uuid
from app.services.audit_service import AuditService

router = APIRouter(prefix="/user/presets", tags=["Presets"])


class PresetCreate(BaseModel):
    name: str
    service: str
    country: str = None
    country_code: str = None

    @field_validator("country", "country_code", mode="before")
    @classmethod
    def resolve_country(cls, v, info):
        if info.field_name == "country" and v is None and info.data.get("country_code"):
            return info.data["country_code"]
        if info.field_name == "country_code" and v is None and info.data.get("country"):
            return None
        return v

    def model_post_init(self, __context):
        if not self.country:
            self.country = self.country_code


class PresetUpdate(BaseModel):
    name: str = None
    service: str = None
    country: str = None
    country_code: str = None

    @field_validator("country", "country_code", mode="before")
    @classmethod
    def resolve_country(cls, v, info):
        if info.field_name == "country" and v is None and info.data.get("country_code"):
            return info.data["country_code"]
        return v

    def model_post_init(self, __context):
        if not self.country:
            self.country = self.country_code


@router.get("")
async def list_presets(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    presets = db.query(Preset).filter(
        Preset.user_id == current_user.id,
    ).order_by(Preset.created_at.desc()).all()
    return success_response([
        {
            "id": p.id,
            "name": p.name,
            "service": p.service,
            "country": p.country,
            "created_at": p.created_at.isoformat() if p.created_at else None,
        }
        for p in presets
    ], request_id=getattr(request.state, "request_id", ""))


@router.post("")
async def create_preset(
    body: PresetCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    count = db.query(Preset).filter(Preset.user_id == current_user.id).count()
    if count >= 10:
        raise AppException("PRESET_LIMIT_REACHED", "لا يمكنك إضافة أكثر من 10 مفضلة", 429)
    existing = db.query(Preset).filter(
        Preset.user_id == current_user.id,
        Preset.service == body.service,
        Preset.country == body.country,
    ).first()
    if existing:
        raise AppException("DUPLICATE_PRESET", "هذه المفضلة موجودة بالفعل", 409)
    preset = Preset(
        id=gen_uuid(),
        user_id=current_user.id,
        name=body.name,
        service=body.service,
        country=body.country,
    )
    db.add(preset)
    db.commit()
    AuditService.log(db, current_user.id, "preset.create", "preset", preset.id,
                   {"name": body.name, "service": body.service, "country": body.country},
                   request.client.host if request.client else "",
                   getattr(request.state, "request_id", ""))
    return success_response({
        "id": preset.id,
        "name": preset.name,
        "service": preset.service,
        "country": preset.country,
    }, request_id=getattr(request.state, "request_id", ""))


@router.put("/{preset_id}")
async def update_preset(
    preset_id: str,
    body: PresetUpdate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    preset = db.query(Preset).filter(
        Preset.id == preset_id,
        Preset.user_id == current_user.id,
    ).first()
    if not preset:
        raise AppException("NOT_FOUND", "المفضلة غير موجودة", 404)
    if body.name is not None:
        preset.name = body.name
    if body.service is not None:
        preset.service = body.service
    if body.country is not None:
        preset.country = body.country
    db.commit()
    AuditService.log(db, current_user.id, "preset.update", "preset", preset.id,
                   {"name": preset.name}, request.client.host if request.client else "",
                   getattr(request.state, "request_id", ""))
    return success_response({
        "id": preset.id,
        "name": preset.name,
        "service": preset.service,
        "country": preset.country,
    }, request_id=getattr(request.state, "request_id", ""))


@router.delete("/{preset_id}")
async def delete_preset(
    preset_id: str,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    preset = db.query(Preset).filter(
        Preset.id == preset_id,
        Preset.user_id == current_user.id,
    ).first()
    if not preset:
        raise AppException("NOT_FOUND", "المفضلة غير موجودة", 404)
    db.delete(preset)
    db.commit()
    AuditService.log(db, current_user.id, "preset.delete", "preset", preset_id, {},
                   request.client.host if request.client else "",
                   getattr(request.state, "request_id", ""))
    return success_response({"deleted": True}, request_id=getattr(request.state, "request_id", ""))
