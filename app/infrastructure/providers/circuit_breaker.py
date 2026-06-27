import asyncio
import time
from enum import Enum
from typing import Any, Callable

from app.core.logging import get_logger

logger = get_logger(__name__)


class CircuitState(str, Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"


class CircuitBreaker:
    def __init__(self, name: str, failure_threshold: int = 5,
                 recovery_timeout: float = 60.0, half_open_max_requests: int = 3):
        self.name = name
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.half_open_max_requests = half_open_max_requests

        self.state = CircuitState.CLOSED
        self.failure_count = 0
        self.success_count = 0
        self.last_failure_time = 0.0
        self.half_open_requests = 0
        self.total_failures = 0
        self.total_successes = 0

    def record_success(self):
        self.success_count += 1
        self.total_successes += 1
        if self.state == CircuitState.HALF_OPEN:
            self.half_open_requests += 1
            if self.half_open_requests >= self.half_open_max_requests:
                self.state = CircuitState.CLOSED
                self.failure_count = 0
                self.half_open_requests = 0
                logger.info(f"Circuit [{self.name}] → CLOSED (recovered)")
        elif self.state == CircuitState.CLOSED:
            self.failure_count = max(0, self.failure_count - 1)

    def record_failure(self):
        self.failure_count += 1
        self.total_failures += 1
        self.last_failure_time = time.monotonic()

        if self.state == CircuitState.HALF_OPEN:
            self.state = CircuitState.OPEN
            self.half_open_requests = 0
            logger.warning(f"Circuit [{self.name}] → OPEN (half-open test failed)")
        elif self.state == CircuitState.CLOSED and self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN
            logger.warning(f"Circuit [{self.name}] → OPEN ({self.failure_count} failures)")

    def can_execute(self) -> bool:
        if self.state == CircuitState.CLOSED:
            return True
        if self.state == CircuitState.OPEN:
            elapsed = time.monotonic() - self.last_failure_time
            if elapsed >= self.recovery_timeout:
                self.state = CircuitState.HALF_OPEN
                self.half_open_requests = 0
                logger.info(f"Circuit [{self.name}] → HALF_OPEN (allow test)")
                return True
            return False
        if self.state == CircuitState.HALF_OPEN:
            return self.half_open_requests < self.half_open_max_requests
        return False

    async def execute(self, func: Callable, *args, **kwargs) -> Any:
        if not self.can_execute():
            raise CircuitBreakerOpenError(f"Circuit [{self.name}] is OPEN")
        try:
            result = await func(*args, **kwargs) if asyncio.iscoroutinefunction(func) else func(*args, **kwargs)
            self.record_success()
            return result
        except Exception as e:
            self.record_failure()
            raise

    def get_status(self) -> dict:
        return {
            "name": self.name,
            "state": self.state.value,
            "failure_count": self.failure_count,
            "failure_threshold": self.failure_threshold,
            "total_failures": self.total_failures,
            "total_successes": self.total_successes,
            "success_rate": (self.total_successes / (self.total_successes + self.total_failures) * 100)
            if (self.total_successes + self.total_failures) > 0 else 100.0,
        }


class CircuitBreakerOpenError(Exception):
    pass


class CircuitBreakerRegistry:
    _breakers: dict[str, CircuitBreaker] = {}

    @classmethod
    def get(cls, name: str, failure_threshold: int = 5,
            recovery_timeout: float = 60.0) -> CircuitBreaker:
        if name not in cls._breakers:
            cls._breakers[name] = CircuitBreaker(name, failure_threshold, recovery_timeout)
        return cls._breakers[name]

    @classmethod
    def get_all_status(cls) -> list[dict]:
        return [b.get_status() for b in cls._breakers.values()]

    @classmethod
    def reset(cls, name: str):
        if name in cls._breakers:
            del cls._breakers[name]

    @classmethod
    def reset_all(cls):
        for b in cls._breakers.values():
            b.state = CircuitState.CLOSED
            b.failure_count = 0
            b.half_open_requests = 0
