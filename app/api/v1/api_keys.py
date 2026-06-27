import hashlib
import secrets

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_mfa
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import APIKey, User, gen_uuid

router = APIRouter(prefix="/user/api-keys", tags=["API Keys"])


class APIKeyCreate(BaseModel):
    name: str


def generate_api_key() -> tuple[str, str, str]:
    raw = f"nsk_{secrets.token_hex(24)}"
    prefix = raw[:11]
    key_hash = hashlib.sha256(raw.encode()).hexdigest()
    return raw, prefix, key_hash


@router.get("")
async def list_api_keys(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    keys = db.query(APIKey).filter(
        APIKey.user_id == current_user.id,
    ).order_by(APIKey.created_at.desc()).all()
    return success_response([
        {
            "id": k.id,
            "name": k.name,
            "prefix": k.prefix,
            "is_active": k.is_active,
            "last_used_at": k.last_used_at.isoformat() if k.last_used_at else None,
            "created_at": k.created_at.isoformat() if k.created_at else None,
        }
        for k in keys
    ], request_id=getattr(request.state, "request_id", ""))


@router.post("")
async def create_api_key(
    body: APIKeyCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    _mfa: User = Depends(require_mfa),
):
    raw, prefix, key_hash = generate_api_key()
    api_key = APIKey(
        id=gen_uuid(),
        user_id=current_user.id,
        name=body.name,
        key_hash=key_hash,
        prefix=prefix,
    )
    db.add(api_key)
    db.commit()
    return success_response({
        "id": api_key.id,
        "name": api_key.name,
        "prefix": prefix,
        "key": raw,
    }, request_id=getattr(request.state, "request_id", ""))


@router.delete("/{key_id}")
async def delete_api_key(
    key_id: str,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    _mfa: User = Depends(require_mfa),
):
    api_key = db.query(APIKey).filter(
        APIKey.id == key_id,
        APIKey.user_id == current_user.id,
    ).first()
    if not api_key:
        raise AppException("NOT_FOUND", "المفتاح غير موجود", 404)
    db.delete(api_key)
    db.commit()
    return success_response({"deleted": True}, request_id=getattr(request.state, "request_id", ""))
