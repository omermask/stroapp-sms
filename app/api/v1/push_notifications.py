from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import DeviceToken, User
from app.services.push_notification_service import push_notification_service


class UnregisterDeviceRequest(BaseModel):
    token: str

router = APIRouter(prefix="/user/push", tags=["Push Notifications"])


class DeviceRegisterRequest(BaseModel):
    token: str
    platform: str
    device_type: str = None
    device_name: str = None


@router.post("/register")
async def register_device(
    body: DeviceRegisterRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    device = await push_notification_service.register_device(
        db, current_user.id, body.token, body.platform,
        body.device_type, body.device_name,
    )
    return success_response({
        "id": device.id,
        "token": device.token,
        "platform": device.platform,
        "device_type": device.device_type,
        "device_name": device.device_name,
        "active": device.active,
    }, request_id=getattr(request.state, "request_id", ""))


@router.post("/unregister")
async def unregister_device(
    body: UnregisterDeviceRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ok = await push_notification_service.unregister_device(db, current_user.id, body.token)
    if not ok:
        raise AppException("NOT_FOUND", "الجهاز غير موجود", 404)
    return success_response({"message": "تم إلغاء تسجيل الجهاز"},
                          request_id=getattr(request.state, "request_id", ""))


@router.get("/devices")
async def list_devices(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    devices = db.query(DeviceToken).filter(
        DeviceToken.user_id == current_user.id,
    ).order_by(DeviceToken.created_at.desc()).all()
    return success_response([
        {
            "id": d.id,
            "token": d.token[:20] + "...",
            "platform": d.platform,
            "device_type": d.device_type,
            "device_name": d.device_name,
            "active": d.active,
            "last_used_at": d.last_used_at.isoformat() if d.last_used_at else None,
            "expires_at": d.expires_at.isoformat() if d.expires_at else None,
            "created_at": d.created_at.isoformat() if d.created_at else None,
        }
        for d in devices
    ], request_id=getattr(request.state, "request_id", ""))


@router.delete("/devices/{device_id}")
async def remove_device(
    device_id: str,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    device = db.query(DeviceToken).filter(
        DeviceToken.id == device_id,
        DeviceToken.user_id == current_user.id,
    ).first()
    if not device:
        raise AppException("NOT_FOUND", "الجهاز غير موجود", 404)
    db.delete(device)
    db.commit()
    return success_response({"message": "تم حذف الجهاز"},
                          request_id=getattr(request.state, "request_id", ""))


@router.post("/test")
async def send_test(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await push_notification_service.send_to_user(
        db, current_user.id, "إشعار تجريبي",
        "إشعارات StroApp SMS تعمل بنجاح!",
        {"type": "test"},
    )
    return success_response(result, request_id=getattr(request.state, "request_id", ""))


@router.get("/config")
async def get_config(request: Request):
    from app.core.config import get_settings
    settings = get_settings()
    return success_response({
        "vapid_key": settings.fcm_vapid_key,
        "enabled": bool(settings.fcm_server_key),
    }, request_id=getattr(request.state, "request_id", ""))
