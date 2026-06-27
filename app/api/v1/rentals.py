from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.response import success_response
from app.domain.models import User, NumberRental
from app.services.rental_service import RentalService


class CreateRentalRequest(BaseModel):
    service: str
    country: str
    # C-3 FIX: التحقق من hours لمنع الحصول على رقم مجاناً (ساعات صفرية أو سالبة)
    hours: int = Field(..., ge=1, le=720, description="عدد الساعات (1-720)")
    auto_extend: bool = False


class ExtendRentalRequest(BaseModel):
    # C-3 FIX: نفس التحقق في طلبات التمديد
    hours: int = Field(..., ge=1, le=720, description="عدد ساعات التمديد (1-720)")

router = APIRouter(prefix="/user/rentals", tags=["Rentals"])


@router.get("")
async def list_rentals(
    request: Request,
    status: str = Query(default=""),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = RentalService(db)
    rentals = svc.get_user_rentals(current_user.id, status)
    return success_response([
        {
            "id": r.id,
            "service": r.service,
            "country": r.country,
            "provider": r.provider,
            "phone_number": r.phone_number,
            "status": r.status,
            "duration_hours": r.duration_hours,
            "cost_coins": r.cost_coins,
            "auto_extend": r.auto_extend,
            "messages_count": r.messages_count,
            "expires_at": r.expires_at.isoformat() if r.expires_at else None,
            "created_at": r.created_at.isoformat() if r.created_at else None,
        }
        for r in rentals
    ], request_id=getattr(request.state, "request_id", ""))


@router.post("")
async def create_rental(
    body: CreateRentalRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = RentalService(db)
    result = await svc.create_rental(current_user.id, body.service, body.country, body.hours, body.auto_extend)
    return success_response(result, request_id=getattr(request.state, "request_id", "") if request else "")


@router.get("/available-countries")
async def available_countries(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = RentalService(db)
    countries = await svc.get_available_countries()
    return success_response(countries, request_id=getattr(request.state, "request_id", ""))


@router.get("/available-services")
async def available_services(
    request: Request,
    country: str = Query(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = RentalService(db)
    services = await svc.get_available_services(country)
    return success_response(services, request_id=getattr(request.state, "request_id", ""))


@router.get("/{rental_id}")
async def get_rental(
    rental_id: str,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # M-2 FIX: استخدام query مباشرة بدلاً من تحميل جميع الإيجارات وتصفيتها في Python
    from app.core.exceptions import AppException
    rental = db.query(NumberRental).filter(
        NumberRental.id == rental_id,
        NumberRental.user_id == current_user.id,
    ).first()
    if not rental:
        raise AppException("NOT_FOUND", "الإيجار غير موجود", 404)
    return success_response({
        "id": rental.id,
        "service": rental.service,
        "country": rental.country,
        "provider": rental.provider,
        "phone_number": rental.phone_number,
        "status": rental.status,
        "duration_hours": rental.duration_hours,
        "cost_coins": rental.cost_coins,
        "auto_extend": rental.auto_extend,
        "messages_count": rental.messages_count,
        "expires_at": rental.expires_at.isoformat() if rental.expires_at else None,
        "created_at": rental.created_at.isoformat() if rental.created_at else None,
        "cancelled_at": rental.cancelled_at.isoformat() if rental.cancelled_at else None,
    }, request_id=getattr(request.state, "request_id", ""))


@router.post("/{rental_id}/extend")
async def extend_rental(
    rental_id: str,
    body: ExtendRentalRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = RentalService(db)
    result = await svc.extend_rental(rental_id, current_user.id, body.hours)
    return success_response(result, request_id=getattr(request.state, "request_id", "") if request else "")


@router.post("/{rental_id}/cancel")
async def cancel_rental(
    rental_id: str,
    request: Request = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = RentalService(db)
    result = await svc.cancel_rental(rental_id, current_user.id)
    return success_response(result, request_id=getattr(request.state, "request_id", "") if request else "")


@router.get("/{rental_id}/messages")
async def get_rental_messages(
    rental_id: str,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    svc = RentalService(db)
    messages = await svc.get_rental_messages(rental_id, current_user.id)
    return success_response(messages, request_id=getattr(request.state, "request_id", ""))
