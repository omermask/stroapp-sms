from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.logging import get_logger
from app.core.response import success_response
from app.domain.models import Service, ServiceCountry

logger = get_logger(__name__)
from app.infrastructure.providers.router import ProviderRouter
from app.services.price_calculator import PriceCalculator

router = APIRouter(prefix="/services", tags=["Services"])
provider_router = ProviderRouter()

_SYNC_STALE_MINUTES = 90


def _is_stale(last_synced_at) -> bool:
    if not last_synced_at:
        return True
    delta = datetime.now(timezone.utc) - last_synced_at
    return delta.total_seconds() > _SYNC_STALE_MINUTES * 60


@router.get("")
async def list_services(
    request: Request,
    category: str = Query(default=None),
    limit: int = Query(default=10000, le=20000),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
):
    query = db.query(Service).filter(Service.is_active == True).order_by(Service.name)
    if category:
        query = query.filter(Service.category == category)
    services = query.offset(offset).limit(limit).all()

    if services:
        return success_response(
            [
                {
                    "id": s.id,
                    "name": s.name,
                    "display_name": s.display_name,
                    "category": s.category,
                }
                for s in services
            ],
            request_id=getattr(request.state, "request_id", ""),
        )

    db_services = (
        db.query(ServiceCountry.service)
        .filter(ServiceCountry.is_active == True)
        .distinct()
        .order_by(ServiceCountry.service)
        .all()
    )
    if db_services:
        return success_response(
            [
                {"id": row[0], "name": row[0], "display_name": row[0], "category": None}
                for row in db_services
            ],
            request_id=getattr(request.state, "request_id", ""),
        )

    provider_services = await provider_router.get_all_services()
    return success_response(
        [
            {
                "id": s["id"],
                "name": s["name"],
                "display_name": s["name"],
                "category": None,
            }
            for s in provider_services
        ],
        request_id=getattr(request.state, "request_id", ""),
    )


@router.get("/countries")
async def list_countries(
    request: Request,
    service: str = Query(default=None),
    provider: str = Query(default=None),
    limit: int = Query(default=100, le=500),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
):
    if service:
        calc = PriceCalculator(db)
        countries = calc.get_countries_for_service(service)
        if not _is_stale(None):
            pass
        if not countries:
            try:
                pr = ProviderRouter()
                services_for_country = await pr.get_all_services("")
                seen_codes: set = set()
                for p in pr.enabled_providers:
                    try:
                        all_services = await p.get_services("")
                        for svc in all_services:
                            ccode = svc.metadata.get("country", "") if svc.metadata else ""
                            if ccode and len(ccode) == 2:
                                seen_codes.add(ccode.upper())
                    except Exception as exc:
                        logger.exception("Failed to get services for country from provider: %s", exc)
                        continue
                countries = [
                    {"country_code": c, "provider": "", "min_cost": 0}
                    for c in seen_codes
                ]
            except Exception as exc:
                logger.exception("Failed to fetch countries from providers: %s", exc)

        return success_response(
            countries[:limit] if limit else countries,
            request_id=getattr(request.state, "request_id", ""),
        )

    codes = (
        db.query(ServiceCountry.country_code)
        .filter(ServiceCountry.is_active == True)
        .distinct()
        .order_by(ServiceCountry.country_code)
        .all()
    )
    result = [{"country_code": row[0]} for row in codes if row[0]]

    if not result:
        try:
            for p in provider_router.enabled_providers:
                try:
                    pcountries = await p.get_countries()
                    for c in pcountries:
                        code = (c.get("code") or c.get("short_name", "")).upper()
                        if code and len(code) == 2:
                            result.append({"country_code": code})
                except Exception as exc:
                    logger.exception("Failed to get countries from provider: %s", exc)
                    continue
        except Exception as exc:
            logger.exception("Failed to fetch countries from all providers: %s", exc)

    return success_response(
        result[offset:offset+limit] if limit else result,
        request_id=getattr(request.state, "request_id", ""),
    )


@router.get("/countries/{country_code}")
async def list_services_by_country(
    country_code: str,
    request: Request,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    calc = PriceCalculator(db)
    services = calc.get_services_with_prices(country_code.upper(), user)

    if not services:
        try:
            pr = ProviderRouter()
            for p in pr.enabled_providers:
                try:
                    pservices = await p.get_services(country_code.upper())
                    for svc in pservices:
                        services.append({
                            "service": svc.service_id,
                            "provider": p.name,
                            "provider_cost": svc.cost,
                            "cost_coins": max(1, round(svc.cost * 100 * 1.20)),
                        })
                except Exception as exc:
                    logger.exception("Failed to get live services for country: %s", exc)
                    continue
        except Exception as exc:
            logger.exception("Failed to fetch live services from providers: %s", exc)

    return success_response(
        services,
        request_id=getattr(request.state, "request_id", ""),
    )


@router.get("/categories")
async def list_categories(
    request: Request,
    db: Session = Depends(get_db),
):
    categories = (
        db.query(Service.category)
        .filter(Service.category.isnot(None), Service.is_active == True)
        .distinct()
        .all()
    )
    return success_response(
        [c[0] for c in categories if c[0]],
        request_id=getattr(request.state, "request_id", ""),
    )


@router.get("/{service}")
async def list_service_countries(
    service: str,
    request: Request,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    calc = PriceCalculator(db)
    countries = calc.get_countries_for_service(service)

    if not countries:
        try:
            for p in provider_router.enabled_providers:
                try:
                    pservices = await p.get_services("")
                    for svc in pservices:
                        if svc.service_id == service:
                            ccode = svc.metadata.get("country", "") if svc.metadata else ""
                            if ccode and len(ccode) == 2:
                                countries.append({
                                    "country_code": ccode.upper(),
                                    "provider": p.name,
                                    "min_cost": svc.cost,
                                })
                except Exception as exc:
                    logger.exception("Failed to get countries for service from provider: %s", exc)
                    continue
        except Exception as exc:
            logger.exception("Failed to fetch countries for service from providers: %s", exc)

    return success_response(
        countries,
        request_id=getattr(request.state, "request_id", ""),
    )
