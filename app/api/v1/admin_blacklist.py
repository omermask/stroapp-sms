from typing import Optional

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.response import success_response
from app.domain.models import User, BlacklistedIP, BlacklistedToken
from app.services.blacklist_service import BlacklistService


class BlockIPRequest(BaseModel):
    ip_address: str
    reason: str = ""
    expires_hours: Optional[int] = None


class UnblockIPRequest(BaseModel):
    ip_address: str


router = APIRouter(prefix="/admin/blacklist", tags=["Admin Blacklist"])


@router.post("/ip")
async def block_ip(
    request: Request,
    body: BlockIPRequest,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    entry = BlacklistService.blacklist_ip(db, body.ip_address, body.reason,
                                           _admin.email, body.expires_hours)
    return success_response({"id": entry.id, "ip_address": entry.ip_address},
                           request_id=getattr(request.state, "request_id", ""))


@router.delete("/ip")
async def unblock_ip(
    request: Request,
    body: UnblockIPRequest,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    BlacklistService.remove_ip(db, body.ip_address)
    return success_response({"message": "IP unblocked"},
                           request_id=getattr(request.state, "request_id", ""))

@router.get("/ips")
async def list_blocked_ips(
    request: Request,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    ips = db.query(BlacklistedIP).order_by(BlacklistedIP.created_at.desc()).all()
    return success_response([{
        "id": ip.id, "ip_address": ip.ip_address, "reason": ip.reason,
        "blocked_by": ip.blocked_by,
        "created_at": ip.created_at.isoformat() if ip.created_at else None,
        "expires_at": ip.expires_at.isoformat() if ip.expires_at else None,
    } for ip in ips], request_id=getattr(request.state, "request_id", ""))


@router.get("/tokens")
async def list_blacklisted_tokens(
    request: Request,
    limit: int = Query(default=50, ge=1, le=200),
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    tokens = db.query(BlacklistedToken).order_by(
        BlacklistedToken.created_at.desc()
    ).limit(limit).all()
    return success_response([{
        "id": t.id, "jti": t.jti, "token_type": t.token_type,
        "user_id": t.user_id, "reason": t.reason,
        "created_at": t.created_at.isoformat() if t.created_at else None,
    } for t in tokens], request_id=getattr(request.state, "request_id", ""))
