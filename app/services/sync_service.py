import asyncio
import re
import time
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.dialects.postgresql import insert as pg_insert

from app.core.database import SessionLocal
from app.core.logging import get_logger
from app.domain.models import (
    Service,
    ServiceCountry,
    SyncLog,
    MarkupRule,
    gen_uuid,
)
from app.infrastructure.providers.base import ServicePrice
from app.infrastructure.providers.router import ProviderRouter

logger = get_logger(__name__)
provider_router = ProviderRouter()

ISO_COUNTRY_OVERRIDES: dict[str, str] = {
    "الولايات المتحدة": "US",
    "United States": "US",
    "USA": "US",
    "المملكة المتحدة": "GB",
    "United Kingdom": "GB",
    "ألمانيا": "DE",
    "Germany": "DE",
    "فرنسا": "FR",
    "France": "FR",
    "الهند": "IN",
    "India": "IN",
    "روسيا": "RU",
    "Russia": "RU",
    "السعودية": "SA",
    "Saudi Arabia": "SA",
    "الإمارات": "AE",
    "UAE": "AE",
    "مصر": "EG",
    "Egypt": "EG",
    "تركيا": "TR",
    "Turkey": "TR",
}


def _normalize_country_name(name: str) -> str:
    name_clean = name.strip().title()
    if name_clean in ISO_COUNTRY_OVERRIDES:
        return ISO_COUNTRY_OVERRIDES[name_clean]
    if len(name_clean) == 2 and name_clean.isalpha():
        return name_clean.upper()
    return name_clean


def _canonical_service_id(svc: ServicePrice) -> str:
    """Derive a canonical service ID from service_name, falling back to service_id."""
    name = (svc.service_name or "").strip()
    if name:
        s = name.lower().strip()
        s = re.sub(r'[^a-z0-9]', '_', s)
        s = re.sub(r'_+', '_', s)
        s = s.strip('_')
        if s:
            return s
    return svc.service_id


def _get_markup(
    db: Session,
    service: str,
    country_code: str,
    provider: str,
    user_tier: Optional[str] = None,
) -> float:
    rules = (
        db.query(MarkupRule)
        .filter(MarkupRule.is_active == True)
        .order_by(MarkupRule.priority.desc())
        .all()
    )
    for rule in rules:
        if rule.service and rule.service != service:
            continue
        if rule.country_code and rule.country_code != country_code:
            continue
        if rule.provider and rule.provider != provider:
            continue
        if rule.user_tier and rule.user_tier != user_tier:
            continue
        return rule.markup_multiplier
    default = (
        db.query(MarkupRule)
        .filter(
            MarkupRule.service.is_(None),
            MarkupRule.country_code.is_(None),
            MarkupRule.provider.is_(None),
            MarkupRule.user_tier.is_(None),
            MarkupRule.is_active == True,
        )
        .first()
    )
    return default.markup_multiplier if default else 1.20


def _upsert_service_country(
    db: Session,
    service: str,
    country_code: str,
    provider: str,
    provider_cost: float,
    available_count: int = 0,
    currency: str = "USD",
):
    now = datetime.now(timezone.utc)
    stmt = pg_insert(ServiceCountry).values(
        id=gen_uuid(),
        service=service,
        country_code=country_code,
        provider=provider,
        provider_cost=provider_cost,
        available_count=available_count,
        currency=currency,
        last_synced_at=now,
        created_at=now,
        updated_at=now,
    )
    stmt = stmt.on_conflict_do_update(
        constraint="uq_service_country_provider",
        set_={
            "provider_cost": stmt.excluded.provider_cost,
            "available_count": stmt.excluded.available_count,
            "currency": stmt.excluded.currency,
            "last_synced_at": stmt.excluded.last_synced_at,
            "updated_at": stmt.excluded.updated_at,
        },
    )
    db.execute(stmt)


def _upsert_service(db: Session, name: str, display_name: str):
    now = datetime.now(timezone.utc)
    stmt = pg_insert(Service).values(
        id=gen_uuid(),
        name=name,
        display_name=display_name,
        is_active=True,
        created_at=now,
        updated_at=now,
    )
    stmt = stmt.on_conflict_do_update(
        constraint="services_name_key",
        set_={
            "display_name": stmt.excluded.display_name,
            "updated_at": stmt.excluded.updated_at,
        },
    )
    db.execute(stmt)


class SyncService:
    def __init__(self):
        self._running = False

    async def sync_all(self, triggered_by: str = "scheduler") -> dict:
        if self._running:
            return {"status": "already_running"}
        self._running = True
        log = self._create_log("all", triggered_by)
        start = time.monotonic()
        errors: list[str] = []
        providers_done: list[str] = []
        total_services = 0
        total_countries = 0

        try:
            for provider in provider_router.enabled_providers:
                try:
                    svc_count, ctry_count = await self._sync_provider(provider)
                    total_services += svc_count
                    total_countries += ctry_count
                    providers_done.append(provider.name)
                except Exception as e:
                    msg = f"[{provider.name}] {e}"
                    logger.warning(f"Sync failed for {provider.name}: {e}")
                    errors.append(msg)

            self._finalize_log(log, "success", providers_done, total_services, total_countries, errors, start)
            return {
                "status": "success",
                "providers": providers_done,
                "services_count": total_services,
                "countries_count": total_countries,
                "errors": errors,
                "duration": time.monotonic() - start,
            }
        except Exception as e:
            self._finalize_log(log, "failed", providers_done, total_services, total_countries, errors, start)
            return {"status": "failed", "error": str(e)}
        finally:
            self._running = False

    async def sync_services(self, triggered_by: str = "scheduler") -> dict:
        return await self.sync_all(triggered_by)

    async def sync_stock(self, triggered_by: str = "scheduler") -> dict:
        if self._running:
            return {"status": "already_running"}
        self._running = True
        log = self._create_log("stock", triggered_by)
        start = time.monotonic()
        errors: list[str] = []
        providers_done: list[str] = []
        total_updated = 0

        try:
            db = SessionLocal()
            try:
                records = db.query(ServiceCountry).filter(ServiceCountry.is_active == True).all()
            finally:
                db.close()

            for provider in provider_router.enabled_providers:
                try:
                    count = await self._sync_stock_for_provider(provider, records)
                    total_updated += count
                    providers_done.append(provider.name)
                except Exception as e:
                    msg = f"[{provider.name}] {e}"
                    logger.warning(f"Stock sync failed for {provider.name}: {e}")
                    errors.append(msg)

            self._finalize_log(log, "success", providers_done, total_updated, 0, errors, start, stock=True)
            return {
                "status": "success",
                "providers": providers_done,
                "updated_count": total_updated,
                "errors": errors,
                "duration": time.monotonic() - start,
            }
        except Exception as e:
            self._finalize_log(log, "failed", providers_done, total_updated, 0, errors, start)
            return {"status": "failed", "error": str(e)}
        finally:
            self._running = False

    async def _sync_provider(self, provider) -> tuple[int, int]:
        service_count = 0
        country_set: set[str] = set()
        db = SessionLocal()
        try:
            countries = await provider.get_countries()
            for c in countries:
                code = _normalize_country_name(c.get("code", "") or c.get("name", ""))
                if not code or len(code) != 2:
                    continue
                country_set.add(code)
                try:
                    services = await provider.get_services(code)
                except Exception:
                    continue
                for svc in services:
                    canonical = _canonical_service_id(svc)
                    _upsert_service_country(
                        db,
                        service=canonical,
                        country_code=code,
                        provider=provider.name,
                        provider_cost=svc.cost,
                        available_count=svc.count if hasattr(svc, "count") else 0,
                    )
                    service_count += 1
                    _upsert_service(
                        db,
                        name=canonical,
                        display_name=svc.service_name or canonical,
                    )

            try:
                all_services = await provider.get_services("")
                now = datetime.now(timezone.utc)
                for svc in all_services:
                    canonical = _canonical_service_id(svc)
                    ccode_raw = svc.metadata.get("country", "") if svc.metadata else ""
                    ccode = _normalize_country_name(str(ccode_raw))
                    if ccode and len(ccode) == 2:
                        country_set.add(ccode)
                        _upsert_service_country(
                            db,
                            service=canonical,
                            country_code=ccode,
                            provider=provider.name,
                            provider_cost=svc.cost,
                            available_count=svc.count if hasattr(svc, "count") else 0,
                        )
                        service_count += 1

                    _upsert_service(
                        db,
                        name=canonical,
                        display_name=svc.service_name or canonical,
                    )
            except Exception:
                pass

            db.commit()
        except Exception:
            db.rollback()
            raise
        finally:
            db.close()

        return service_count, len(country_set)

    async def _sync_stock_for_provider(self, provider, records: list[ServiceCountry]) -> int:
        updated = 0
        provider_records = [r for r in records if r.provider == provider.name]
        if not provider_records:
            return 0

        db = SessionLocal()
        try:
            for record in provider_records:
                try:
                    services = await provider.get_services(record.country_code)
                    for svc in services:
                        if svc.service_id == record.service:
                            record.available_count = svc.count if hasattr(svc, "count") else 0
                            record.last_synced_at = datetime.now(timezone.utc)
                            updated += 1
                            break
                except Exception:
                    continue

            db.commit()
        except Exception:
            db.rollback()
            raise
        finally:
            db.close()

        return updated

    def _create_log(self, sync_type: str, triggered_by: str) -> SyncLog:
        db = SessionLocal()
        try:
            log = SyncLog(
                id=gen_uuid(),
                sync_type=sync_type,
                status="running",
                triggered_by=triggered_by,
                started_at=datetime.now(timezone.utc),
                created_at=datetime.now(timezone.utc),
            )
            db.add(log)
            db.commit()
            db.refresh(log)
            return log
        finally:
            db.close()

    def _finalize_log(
        self,
        log: SyncLog,
        status: str,
        providers: list[str],
        services_count: int,
        countries_count: int,
        errors: list[str],
        start: float,
        stock: bool = False,
    ):
        db = SessionLocal()
        try:
            fresh = db.query(SyncLog).filter(SyncLog.id == log.id).first()
            if fresh:
                fresh.status = status
                fresh.providers_synced = providers
                fresh.services_count = services_count if not stock else 0
                fresh.countries_count = countries_count if not stock else 0
                fresh.errors = errors
                fresh.duration_seconds = time.monotonic() - start
                fresh.completed_at = datetime.now(timezone.utc)
                db.commit()
        except Exception:
            db.rollback()
        finally:
            db.close()


class SyncOrchestrator:
    """يدير المزامنة الدورية حسب جدول زمني"""

    def __init__(self):
        self._task: Optional[asyncio.Task] = None
        self._service = SyncService()

    async def run_forever(self, interval_seconds: int = 3600):
        logger.info(f"SyncOrchestrator started — interval={interval_seconds}s")
        while True:
            try:
                logger.info("Starting scheduled sync_all...")
                result = await self._service.sync_all(triggered_by="scheduler")
                logger.info(f"Sync complete: {result.get('status')} — {result.get('services_count', 0)} services")

                await asyncio.sleep(interval_seconds)

                logger.info("Starting scheduled stock sync...")
                stock_result = await self._service.sync_stock(triggered_by="scheduler")
                logger.info(f"Stock sync complete: {stock_result.get('status')} — {stock_result.get('updated_count', 0)} updated")

            except asyncio.CancelledError:
                logger.info("SyncOrchestrator cancelled")
                break
            except Exception as e:
                logger.error(f"SyncOrchestrator error: {e}")
                await asyncio.sleep(60)

    def start(self, interval_seconds: int = 3600):
        if self._task is None or self._task.done():
            self._task = asyncio.create_task(self.run_forever(interval_seconds))
            logger.info("SyncOrchestrator task created")

    def stop(self):
        if self._task and not self._task.done():
            self._task.cancel()
            logger.info("SyncOrchestrator stopped")
