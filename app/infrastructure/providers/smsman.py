from datetime import datetime, timedelta, timezone
from typing import Optional

import httpx

from app.core.config import get_settings
from app.core.logging import get_logger
from app.infrastructure.providers.base import (
    BaseProvider,
    MessageResult,
    PurchaseResult,
    ServicePrice,
)

logger = get_logger(__name__)

BASE_URL_RU = "http://api.sms-man.ru/control"
BASE_URL_COM = "https://api.sms-man.com/control"

SERVICE_MAP = {
    "whatsapp": "6", "telegram": "3", "google": "122", "facebook": "124",
    "instagram": "5", "twitter": "125", "tiktok": "165", "discord": "162",
    "snapchat": "189", "uber": "126", "amazon": "176", "netflix": "156",
    "linkedin": "148", "microsoft": "133", "apple": "297",
    "coinbase": "239", "binance": "1282", "airbnb": "134", "doordash": "320",
    "signal": "624", "viber": "121", "line": "135", "wechat": "2",
    "steam": "142", "kraken": "2979", "cashapp": "1535",
    "yahoo": "136", "tinder": "143", "kakao": "146",
    "vk": "1", "ok": "4", "olx": "129", "gett": "128", "aol": "147",
}

SERVICE_BY_ID: dict[str, str] = {v: k for k, v in SERVICE_MAP.items()}

COUNTRY_MAP = {
    "US": "5", "GB": "100", "DE": "123", "FR": "155", "IT": "163", "ES": "135",
    "IN": "14", "CA": "13", "CN": "3", "BR": "150", "AU": "185", "JP": "231",
    "NG": "103", "ZA": "113", "EG": "105", "SA": "133", "AE": "172", "TR": "140",
    "PL": "12", "RO": "11", "VN": "10", "PH": "8", "ID": "7", "MY": "6",
    "MX": "18", "PK": "16", "BD": "17", "TH": "132", "SG": "270", "HK": "99",
    "IL": "98", "KE": "96", "KZ": "2", "RU": "1",
}

RUB_TO_USD = 0.011


class SmsManProvider(BaseProvider):
    def __init__(self):
        super().__init__()
        settings = get_settings()
        self.api_key = settings.smsman_api_key
        self._enabled = bool(self.api_key)
        self._client: Optional[httpx.AsyncClient] = None

    def _client_instance(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(
                timeout=10,
                params={"token": self.api_key},
            )
        return self._client

    @property
    def name(self) -> str:
        return "smsman"

    def _check_enabled(self) -> bool:
        return self._enabled

    async def _request(self, path: str, params: Optional[dict] = None) -> dict:
        if not self.enabled:
            raise RuntimeError("SMS-Man provider is not configured")
        urls = [f"{BASE_URL_COM}{path}", f"{BASE_URL_RU}{path}"]
        last_error = None
        for url in urls:
            try:
                resp = await self._client_instance().get(url, params=params)
                resp.raise_for_status()
                return resp.json()
            except (httpx.ConnectError, httpx.TimeoutException) as e:
                last_error = e
                continue
            except httpx.HTTPStatusError as e:
                if e.response.status_code >= 500:
                    last_error = e
                    continue
                raise
        raise last_error or RuntimeError(f"SMS-Man all URLs failed for {path}")

    async def purchase_number(self, service: str, country: str) -> PurchaseResult:
        country_id = COUNTRY_MAP.get(country.upper())
        if not country_id:
            raise ValueError(f"Country {country} not supported by SMS-Man")

        service_id = SERVICE_MAP.get(service.lower())
        if not service_id:
            raise ValueError(f"Service {service} not supported by SMS-Man")

        data = await self._request("/get-number", params={
            "country_id": country_id,
            "application_id": service_id,
        })

        error_code = data.get("error_code")
        if error_code == "balance":
            raise RuntimeError("SMS-Man insufficient balance")
        if error_code == "no_numbers":
            raise RuntimeError(f"SMS-Man no numbers for {country}/{service}")

        request_id = data.get("request_id")
        phone_number = data.get("number")

        # SMS-Man returns cost in RUB
        cost_str = data.get("cost", "0")
        try:
            cost_rub = float(cost_str)
        except (ValueError, TypeError):
            cost_rub = 0.0
        cost_usd = cost_rub * RUB_TO_USD

        if not phone_number or not request_id:
            raise RuntimeError(f"SMS-Man malformed response: {data}")

        phone = f"+{phone_number}" if not phone_number.startswith("+") else phone_number

        return PurchaseResult(
            phone_number=phone,
            order_id=request_id,
            cost=cost_usd,
            provider="smsman",
            expires_at=(datetime.now(timezone.utc) + timedelta(minutes=20)).isoformat(),
            metadata={"request_id": request_id, "country_id": country_id, "service_id": service_id},
        )

    async def check_sms(self, order_id: str) -> Optional[MessageResult]:
        try:
            data = await self._request("/get-sms", params={"request_id": order_id})
            if "sms_code" in data and data["sms_code"]:
                code = data["sms_code"]
                return MessageResult(
                    text=code,
                    code=code,
                    received_at=datetime.now(timezone.utc).isoformat(),
                )
            return None
        except Exception as e:
            logger.warning(f"SMS-Man check_sms failed for {order_id}: {e}")
            return None

    async def cancel(self, order_id: str) -> bool:
        try:
            await self._request("/set-status", params={
                "request_id": order_id, "status": "reject",
            })
            return True
        except Exception as e:
            logger.warning(f"SMS-Man cancel failed for {order_id}: {e}")
            return False

    async def get_balance(self) -> float:
        try:
            data = await self._request("/get-balance")
            balance_rub = float(data.get("balance", 0.0))
            return balance_rub * RUB_TO_USD
        except Exception as e:
            logger.warning(f"SMS-Man get_balance failed: {e}")
            return 0.0

    async def get_services(self, country: str) -> list[ServicePrice]:
        country_id = COUNTRY_MAP.get(country.upper())
        if not country_id:
            return []

        try:
            data = await self._request("/get-prices", params={"country_id": country_id})
            result = []
            for app_id_str, info in data.items():
                cost_str = info.get("cost", "0")
                try:
                    cost_rub = float(cost_str)
                except (ValueError, TypeError):
                    cost_rub = 0.0
                cost_usd = cost_rub * RUB_TO_USD

                service_name = SERVICE_BY_ID.get(app_id_str)
                if not service_name:
                    service_name = info.get("application", str(app_id_str)).lower().replace(" ", "_")

                result.append(ServicePrice(
                    service_id=service_name,
                    service_name=info.get("application", f"Service {app_id_str}"),
                    cost=cost_usd,
                    count=info.get("count", 0),
                    metadata={"app_id": app_id_str, "country_id": country_id},
                ))
            return result
        except Exception as e:
            logger.warning(f"SMS-Man get_services failed: {e}")
            return []

    async def get_countries(self) -> list[dict]:
        try:
            data = await self._request("/countries")
            result = []
            for cid, info in data.items():
                result.append({
                    "id": int(cid),
                    "code": info.get("code", ""),
                    "name": info.get("title", ""),
                })
            return result
        except Exception as e:
            logger.warning(f"SMS-Man get_countries failed: {e}")
            return []

    async def close(self):
        if self._client:
            await self._client.aclose()
            self._client = None
