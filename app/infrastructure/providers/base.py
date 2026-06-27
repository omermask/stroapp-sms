from dataclasses import dataclass, field
from typing import Optional

from app.infrastructure.providers.circuit_breaker import CircuitBreakerRegistry


@dataclass
class PurchaseResult:
    phone_number: str
    order_id: str
    cost: float
    provider: str
    expires_at: Optional[str] = None
    metadata: dict = field(default_factory=dict)
    error_message: Optional[str] = None


@dataclass
class MessageResult:
    text: str
    code: str
    received_at: Optional[str] = None
    metadata: dict = field(default_factory=dict)


@dataclass
class ServicePrice:
    service_id: str
    service_name: str
    cost: float
    count: int = 0
    metadata: dict = field(default_factory=dict)


class BaseProvider:
    _enabled_override: Optional[bool] = None
    supports_voice: bool = False
    supports_rentals: bool = False

    def __init__(self):
        self._cb = CircuitBreakerRegistry.get(name=self.__class__.__name__)
        self._wrap_with_circuit_breaker()

    def _wrap_with_circuit_breaker(self):
        for method_name in ['purchase_number', 'check_sms', 'cancel', 'get_balance', 'get_services', 'get_countries', 'get_price']:
            original = getattr(self, method_name, None)
            if original is not None:
                method = getattr(type(self), method_name, None)
                if method is not None and method is not getattr(BaseProvider, method_name, None):
                    cb = self._cb
                    fn = original
                    async def wrapper(*args, _fn=fn, _cb=cb, **kwargs):
                        return await _cb.execute(_fn, *args, **kwargs)
                    setattr(self, method_name, wrapper)

    @property
    def name(self) -> str:
        raise NotImplementedError

    @property
    def enabled(self) -> bool:
        if self._enabled_override is not None:
            return self._enabled_override
        return self._check_enabled()

    def _check_enabled(self) -> bool:
        raise NotImplementedError

    async def purchase_number(self, service: str, country: str) -> PurchaseResult:
        raise NotImplementedError

    async def purchase(self, service: str, country: str) -> PurchaseResult:
        return await self.purchase_number(service, country)

    async def check_sms(self, order_id: str) -> Optional[MessageResult]:
        raise NotImplementedError

    async def check_messages(self, order_id: str) -> list[MessageResult]:
        result = await self.check_sms(order_id)
        return [result] if result else []

    async def cancel(self, order_id: str) -> bool:
        raise NotImplementedError

    async def get_balance(self) -> float:
        raise NotImplementedError

    async def get_services(self, country: str) -> list[ServicePrice]:
        raise NotImplementedError

    async def get_price(self, service: str, country: str) -> float:
        try:
            services = await self.get_services(country)
            for s in services:
                if s.service_id == service.lower():
                    return s.cost
            return 999999.0
        except Exception:
            return 999999.0

    async def get_countries(self) -> list[dict]:
        raise NotImplementedError

    async def close(self):
        pass
