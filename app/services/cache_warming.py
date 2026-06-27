from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.core.logging import get_logger
from app.domain.models import Service, Country, Provider
from app.infrastructure.cache.cache_manager import cache

logger = get_logger(__name__)


class CacheWarmingService:
    @staticmethod
    async def warm_all():
        logger.info("Starting cache warm-up")
        db = SessionLocal()
        try:
            await CacheWarmingService._warm_services(db)
            await CacheWarmingService._warm_countries(db)
            await CacheWarmingService._warm_providers(db)
            logger.info("Cache warm-up completed")
        except Exception as e:
            logger.error(f"Cache warm-up error: {e}")
        finally:
            db.close()

    @staticmethod
    async def _warm_services(db: Session):
        services = db.query(Service).filter(Service.is_active == True).all()
        key = cache.cache_key("services", "all")
        await cache.set(key, [s.to_dict() if hasattr(s, "to_dict") else {
            "id": s.id, "name": s.name, "display_name": s.display_name,
            "category": s.category, "is_active": s.is_active,
        } for s in services], ttl=cache.ttl_defaults["services"])
        logger.info(f"Warmed {len(services)} services")

    @staticmethod
    async def _warm_countries(db: Session):
        countries = db.query(Country).filter(Country.is_active == True).all()
        key = cache.cache_key("countries", "all")
        await cache.set(key, [c.to_dict() if hasattr(c, "to_dict") else {
            "id": c.id, "code": c.code, "name": c.name,
            "service_id": c.service_id, "provider": c.provider,
            "provider_cost": c.provider_cost, "platform_price": c.platform_price,
            "currency": c.currency, "is_active": c.is_active,
        } for c in countries], ttl=cache.ttl_defaults["countries"])
        logger.info(f"Warmed {len(countries)} countries")

    @staticmethod
    async def _warm_providers(db: Session):
        providers = db.query(Provider).filter(Provider.is_active == True).all()
        key = cache.cache_key("providers", "all")
        await cache.set(key, [p.to_dict() if hasattr(p, "to_dict") else {
            "id": p.id, "name": p.name, "display_name": p.display_name,
            "priority": p.priority, "is_active": p.is_active,
            "supports_voice": p.supports_voice, "supports_rentals": p.supports_rentals,
        } for p in providers], ttl=cache.ttl_defaults["provider"])
        logger.info(f"Warmed {len(providers)} providers")
