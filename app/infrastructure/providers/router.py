from typing import Optional

from app.core.logging import get_logger
from app.infrastructure.providers.base import BaseProvider, PurchaseResult
from app.infrastructure.providers.smsman import SmsManProvider
from app.infrastructure.providers.fivesim import FiveSimProvider
from app.infrastructure.providers.smsactivate import SmsActivateProvider
from app.infrastructure.providers.smspool import SmsPoolProvider

logger = get_logger(__name__)


class ProviderRouter:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self):
        if self._initialized:
            return
        self._initialized = True
        self._providers: dict[str, BaseProvider] = {}
        self._order: list[str] = []

        for provider_cls in [SmsManProvider, FiveSimProvider, SmsActivateProvider, SmsPoolProvider]:
            instance = provider_cls()
            self._providers[instance.name] = instance
            if instance.enabled:
                self._order.append(instance.name)

    @property
    def all_providers(self) -> list[BaseProvider]:
        return list(self._providers.values())

    @property
    def enabled_providers(self) -> list[BaseProvider]:
        return [self._providers[name] for name in self._order]

    async def purchase_with_fallback(
        self, service: str, country: str, preferred_provider: Optional[str] = None
    ) -> PurchaseResult:
        if preferred_provider:
            provider = self._providers.get(preferred_provider)
            if not provider:
                raise RuntimeError(f"Provider '{preferred_provider}' not found")
            if not provider.enabled:
                raise RuntimeError(f"Provider '{preferred_provider}' is disabled")
            result = await provider.purchase_number(service, country)
            logger.info(f"Purchase success via {provider.name}: {result.phone_number}")
            return result

        if not self._order:
            raise RuntimeError("No providers configured")

        last_error = None
        for name in self._order:
            provider = self._providers[name]
            try:
                result = await provider.purchase_number(service, country)
                logger.info(
                    f"Purchase success via {provider.name}: "
                    f"{result.phone_number} for {service}/{country}"
                )
                return result
            except Exception as e:
                logger.warning(f"Provider {provider.name} failed for {service}/{country}: {e}")
                last_error = e
                continue

        raise RuntimeError(f"All providers failed for {service}/{country}: {last_error}")

    async def get_all_services(self, country: str = "US") -> list[dict]:
        all_services = {}
        for p in self.enabled_providers:
            try:
                services = await p.get_services(country)
                for s in services:
                    sid = s.service_id
                    if sid not in all_services:
                        all_services[sid] = {
                            "id": sid,
                            "name": s.service_name,
                            "cost": s.cost,
                            "provider": p.name,
                        }
                    else:
                        if s.cost < all_services[sid]["cost"]:
                            all_services[sid].update({"cost": s.cost, "provider": p.name})
            except Exception:
                continue
        return list(all_services.values())

    async def get_provider(self, name: str) -> Optional[BaseProvider]:
        return self._providers.get(name)

    def toggle_provider(self, name: str) -> Optional[bool]:
        provider = self._providers.get(name)
        if not provider:
            return None
        new_state = not provider.enabled
        provider._enabled_override = new_state
        if new_state and provider.name not in self._order:
            self._order.append(provider.name)
        elif not new_state and provider.name in self._order:
            self._order.remove(provider.name)
        return new_state

    async def get_balance_summary(self) -> dict:
        summary = {}
        for name, p in self._providers.items():
            try:
                balance = await p.get_balance()
                summary[name] = {
                    "balance": balance,
                    "enabled": p.enabled,
                }
            except Exception as e:
                summary[name] = {
                    "balance": 0.0,
                    "enabled": p.enabled,
                    "error": str(e),
                }
        return summary
