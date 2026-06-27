from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy import func, desc
from sqlalchemy.orm import Session

from app.core.config import get_settings, get_app_setting
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.logging import get_logger
from app.core.response import success_response
from app.domain.models import SMSOrder, User, Service
from app.infrastructure.providers import ProviderRouter

logger = get_logger(__name__)

router = APIRouter(prefix="/user/availability", tags=["Availability"])
provider_router = ProviderRouter()


@router.get("/service")
async def service_availability(
    service: str = Query(...),
    country: str = Query(default="US"),
    request: Request = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    results = {}
    coins_per_usd = get_app_setting(db, "coins_per_usd", get_settings().coins_per_usd)
    default_markup = get_app_setting(db, "default_markup", get_settings().default_markup)
    for provider in provider_router.enabled_providers:
        try:
            price = await provider.get_price(service, country)
            markup = default_markup
            results[provider.name] = {
                "available": True,
                "price": price,
                "price_with_markup": round(price * markup, 4),
                "cost_coins": int(price * markup * coins_per_usd),
            }
        except Exception:
            results[provider.name] = {"available": False, "price": None, "price_with_markup": None, "cost_coins": None}
    return success_response(results, request_id=getattr(request.state, "request_id", "") if request else "")


@router.get("/country")
async def country_availability(
    country: str = Query(...),
    request: Request = None,
    current_user: User = Depends(get_current_user),
):
    results = {}
    services = await provider_router.get_all_services(country)
    for svc in services:
        name = svc.get("id", svc.get("name", ""))
        provider_name = svc.get("provider", "")
        try:
            price = await provider_router.get_provider(provider_name).get_price(name, country)
            results[name] = {"available": True, "price": price}
        except Exception as e:
            logger.warning(f"Failed to check availability for {name}: {e}")
    return success_response(results, request_id=getattr(request.state, "request_id", "") if request else "")


@router.get("/top-services")
async def top_services(
    limit: int = Query(default=10, le=50),
    request: Request = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    rows = db.query(
        SMSOrder.service, func.count(SMSOrder.id).label("count")
    ).group_by(SMSOrder.service).order_by(desc("count")).limit(limit).all()
    return success_response(
        [{"service": r.service, "count": r.count} for r in rows],
        request_id=getattr(request.state, "request_id", "") if request else "",
    )


@router.get("/summary")
async def availability_summary(
    request: Request = None,
    current_user: User = Depends(get_current_user),
):
    total_providers = len(provider_router.enabled_providers)
    active_count = 0
    total_balance = 0.0
    for p in provider_router.enabled_providers:
        try:
            balance = await p.get_balance()
            active_count += 1
            total_balance += balance
        except Exception as e:
            logger.warning(f"Failed to get balance for {p.name}: {e}")
    return success_response({
        "total_providers": total_providers,
        "active_providers": active_count,
        "total_balance": total_balance,
        "status": "healthy" if active_count > 0 else "degraded",
    }, request_id=getattr(request.state, "request_id", "") if request else "")
