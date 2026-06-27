import json
import re
from typing import Any, Optional

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

BASE_URL = "https://api.sms-activate.ae/stubs/handler_api.php"

SERVICE_ID_MAP = {
    "telegram": "3", "whatsapp": "5", "google": "9", "facebook": "7",
    "instagram": "11", "twitter": "12", "tiktok": "29", "discord": "28",
    "snapchat": "30", "uber": "13", "amazon": "26", "netflix": "31",
    "linkedin": "19", "microsoft": "10", "apple": "35",
    "coinbase": "42", "binance": "43", "airbnb": "33",
    "doordash": "48", "signal": "36", "viber": "4",
    "line": "22", "wechat": "6", "steam": "25",
    "kraken": "49", "cashapp": "37",
    "yahoo": "14", "tinder": "39", "kakao": "40",
    "vk": "1", "ok": "2", "olx": "24",
}

ID_TO_SERVICE: dict[str, str] = {v: k for k, v in SERVICE_ID_MAP.items()}

COUNTRY_ID_MAP = {
    "US": "12", "GB": "16", "DE": "25", "FR": "27", "IT": "24",
    "ES": "28", "IN": "29", "CA": "20",
    "BR": "33", "AU": "31", "JP": "60",
    "NG": "35", "ZA": "40", "EG": "30", "SA": "37",
    "AE": "38", "TR": "32", "PL": "15",
    "VN": "10", "PH": "5", "ID": "7", "MY": "8",
    "MX": "18", "PK": "34", "BD": "36",
    "TH": "21", "SG": "59", "HK": "14", "IL": "13",
    "KE": "9", "KZ": "3", "RU": "1", "NL": "26",
    "SE": "22", "NO": "96", "DK": "95", "FI": "97",
    "PT": "94", "GR": "98", "AT": "90", "CH": "91",
    "BE": "92", "IE": "93", "CZ": "82",
    "HU": "84", "BG": "87", "RO": "88", "HR": "85",
    "LT": "79", "UA": "2",
    "CL": "99", "CO": "100", "PE": "101", "AR": "19",
    "MA": "41", "DZ": "42", "TN": "47",
    "GH": "43", "CM": "44", "CI": "45", "SN": "46",
}

ID_TO_COUNTRY: dict[str, str] = {v: k for k, v in COUNTRY_ID_MAP.items()}

RUB_TO_USD = 0.011


class SmsActivateProvider(BaseProvider):
    def __init__(self):
        super().__init__()
        settings = get_settings()
        self.api_key = settings.smsactivate_api_key
        self._enabled = bool(self.api_key)
        self._client: Optional[httpx.AsyncClient] = None

    def _client_instance(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(timeout=10)
        return self._client

    @property
    def name(self) -> str:
        return "smsactivate"

    def _check_enabled(self) -> bool:
        return self._enabled

    async def _request(self, params: dict) -> str:
        if not self.enabled:
            raise RuntimeError("SMS-Activate provider is not configured")
        params["api_key"] = self.api_key
        client = self._client_instance()
        resp = await client.get(BASE_URL, params=params)
        if resp.status_code >= 500:
            raise RuntimeError(f"SMS-Activate server error: {resp.status_code}")
        text = resp.text.strip()
        if text.startswith("BAD_KEY"):
            raise RuntimeError("SMS-Activate invalid API key")
        if text.startswith("NO_BALANCE"):
            raise RuntimeError("SMS-Activate insufficient balance")
        if text.startswith("NO_NUMBERS"):
            raise RuntimeError("SMS-Activate no numbers available")
        if text.startswith("BAD_ACTION"):
            raise RuntimeError(f"SMS-Activate bad action: {params.get('action')}")
        if text.startswith("BANNED"):
            raise RuntimeError(f"SMS-Activate account banned until {text.split(':')[1]}")
        if text.startswith("ERROR_SQL"):
            raise RuntimeError("SMS-Activate database error")
        if text.startswith("BAD_SERVICE"):
            raise RuntimeError(f"SMS-Activate bad service: {params.get('service')}")
        if text.startswith("NO_ACTIVATION"):
            raise RuntimeError("SMS-Activate activation not found")
        if text.startswith("WRONG_ACTIVATION_ID"):
            raise RuntimeError("SMS-Activate invalid activation ID")
        if text.startswith("OPERATORS_NOT_FOUND"):
            raise RuntimeError("SMS-Activate operators not found")
        if text.startswith("OUT_OF_STOCK"):
            raise RuntimeError("SMS-Activate country out of stock")
        if text.startswith("NO_ID_RENT"):
            raise RuntimeError("SMS-Activate rent ID not found")
        if text.startswith("INVALID_PHONE"):
            raise RuntimeError("SMS-Activate invalid phone/rent ID")
        if text.startswith("WRONG_EXCEPTION_PHONE"):
            raise RuntimeError("SMS-Activate incorrect phone exclusion prefixes")
        if text.startswith("NO_BALANCE_FORWARD"):
            raise RuntimeError("SMS-Activate insufficient funds for call forwarding")
        if text.startswith("CHANNELS_LIMIT"):
            raise RuntimeError("SMS-Activate account blocked (channels limit)")
        if text.startswith("EARLY_CANCEL_DENIED"):
            raise RuntimeError("SMS-Activate cannot cancel within first 2 minutes")
        if text.startswith("WRONG_SERVICE"):
            raise RuntimeError(f"SMS-Activate wrong service: {params.get('service')}")
        if text.startswith("WRONG_MAX_PRICE"):
            parts = text.split(":")
            raise RuntimeError(f"SMS-Activate max price too low, minimum: {parts[1] if len(parts) > 1 else 'unknown'}")
        if text.startswith("WRONG_ADDITIONAL_SERVICE"):
            raise RuntimeError("SMS-Activate invalid additional service (forwarding only)")
        if text.startswith("WRONG_SECURITY"):
            raise RuntimeError("SMS-Activate security error — activation not redirecting or completed")
        if text.startswith("REPEAT_ADDITIONAL_SERVICE"):
            raise RuntimeError("SMS-Activate additional service already purchased")
        if text.startswith("RENEW_ACTIVATION_NOT_AVAILABLE"):
            raise RuntimeError("SMS-Activate number not available for additional activation")
        if text.startswith("NEW_ACTIVATION_IMPOSSIBLE"):
            raise RuntimeError("SMS-Activate cannot create additional activation")
        if text.startswith("SIM_OFFLINE"):
            raise RuntimeError("SMS-Activate SIM card offline")
        if text.startswith("NO_CALL"):
            raise RuntimeError("SMS-Activate no call received")
        if text.startswith("PARSE_COUNT_EXCEED"):
            raise RuntimeError("SMS-Activate voice parse limit exceeded (max 4)")
        if text.startswith("BAD_STATUS"):
            raise RuntimeError(f"SMS-Activate bad status: {params.get('status')}")
        if text.startswith("BAD_DATA"):
            raise RuntimeError(f"SMS-Activate bad data: {params.get('productId')}")
        if text.startswith("INCORECT_STATUS"):
            raise RuntimeError("SMS-Activate missing or incorrect status")
        if text.startswith("CANT_CANCEL"):
            raise RuntimeError("SMS-Activate cannot cancel rent (more than 20 min)")
        if text.startswith("ALREADY_FINISH"):
            raise RuntimeError("SMS-Activate rent already finished")
        if text.startswith("ALREADY_CANCEL"):
            raise RuntimeError("SMS-Activate rent already canceled")
        if text.startswith("ACCOUNT_INACTIVE"):
            raise RuntimeError("SMS-Activate account not active")
        if text.startswith("SERVER_ERROR"):
            raise RuntimeError("SMS-Activate server error")
        if text.startswith("ORDER_ALREADY_EXISTS"):
            raise RuntimeError("SMS-Activate order already exists (duplicate orderId)")
        if text.startswith("INVALID_ACTIVATION_ID"):
            raise RuntimeError("SMS-Activate invalid activation ID")
        if text.startswith("INVALID_TIME"):
            raise RuntimeError("SMS-Activate invalid rental time")
        if text.startswith("MAX_HOURS_EXCEED"):
            raise RuntimeError("SMS-Activate maximum rental hours exceeded")
        if text.startswith("RENT_DIE"):
            raise RuntimeError("SMS-Activate rent cannot be extended — number expired")
        return text

    async def _request_json(self, params: dict) -> dict:
        text = await self._request(params)
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            return {}

    # ──────────────────────────────────────────────
    # Balance — action=getBalance / getBalanceAndCashBack
    # ──────────────────────────────────────────────

    async def get_balance(self) -> float:
        try:
            text = await self._request({"action": "getBalance"})
            match = re.match(r"ACCESS_BALANCE:\s*([\d.]+)", text)
            if match:
                return float(match.group(1)) * RUB_TO_USD
            return 0.0
        except Exception as e:
            logger.warning(f"SMS-Activate get_balance failed: {e}")
            return 0.0

    async def get_balance_and_cashback(self) -> dict:
        try:
            text = await self._request({"action": "getBalanceAndCashBack"})
            match = re.match(r"ACCESS_BALANCE:\s*([\d.]+)", text)
            balance = float(match.group(1)) if match else 0.0
            return {"balance": balance, "balance_usd": balance * RUB_TO_USD}
        except Exception as e:
            logger.warning(f"SMS-Activate get_balance_and_cashback failed: {e}")
            return {"balance": 0.0, "balance_usd": 0.0}

    # ──────────────────────────────────────────────
    # Numbers Status — action=getNumbersStatus
    # ──────────────────────────────────────────────

    async def get_numbers_status(self, country: str, operator: str = "") -> dict:
        country_id = COUNTRY_ID_MAP.get(country.upper(), country)
        params: dict[str, Any] = {"action": "getNumbersStatus", "country": country_id}
        if operator:
            params["operator"] = operator
        try:
            text = await self._request(params)
            return json.loads(text) if text.startswith("{") else {}
        except Exception as e:
            logger.warning(f"SMS-Activate get_numbers_status failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Top Countries — action=getTopCountriesByService / getTopCountriesByServiceRank
    # ──────────────────────────────────────────────

    async def get_top_countries_by_service(self, service: str, free_price: bool = False) -> list[dict]:
        try:
            sid = SERVICE_ID_MAP.get(service.lower(), service)
            params: dict[str, Any] = {"action": "getTopCountriesByService", "service": sid}
            if free_price:
                params["freePrice"] = "true"
            text = await self._request(params)
            data = json.loads(text) if text.startswith("{") else {}
            return list(data.values()) if isinstance(data, dict) else []
        except Exception as e:
            logger.warning(f"SMS-Activate get_top_countries_by_service failed: {e}")
            return []

    async def get_top_countries_by_service_rank(self, service: str, free_price: bool = False) -> list[dict]:
        try:
            sid = SERVICE_ID_MAP.get(service.lower(), service)
            params: dict[str, Any] = {"action": "getTopCountriesByServiceRank", "service": sid}
            if free_price:
                params["freePrice"] = "true"
            text = await self._request(params)
            data = json.loads(text) if text.startswith("{") else {}
            return list(data.values()) if isinstance(data, dict) else []
        except Exception as e:
            logger.warning(f"SMS-Activate get_top_countries_by_service_rank failed: {e}")
            return []

    # ──────────────────────────────────────────────
    # Operators — action=getOperators
    # ──────────────────────────────────────────────

    async def get_operators(self, country: str = "") -> dict:
        try:
            params: dict[str, Any] = {"action": "getOperators"}
            if country:
                params["country"] = COUNTRY_ID_MAP.get(country.upper(), country)
            data = await self._request_json(params)
            if "countryOperators" in data:
                return data["countryOperators"]
            return data
        except Exception as e:
            logger.warning(f"SMS-Activate get_operators failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Active Activations — action=getActiveActivations
    # ──────────────────────────────────────────────

    async def get_active_activations(self) -> list[dict]:
        try:
            data = await self._request_json({"action": "getActiveActivations"})
            if "activeActivations" in data:
                return data["activeActivations"]
            return []
        except Exception as e:
            logger.warning(f"SMS-Activate get_active_activations failed: {e}")
            return []

    # ──────────────────────────────────────────────
    # Purchase (V1) — action=getNumber
    # ──────────────────────────────────────────────

    async def purchase_number(
        self,
        service: str,
        country: str,
        operator: str = "",
        max_price: Optional[float] = None,
        forward: bool = False,
        ref: str = "",
        use_cashback: bool = False,
        activation_type: int = 0,
        language: str = "",
        phone_exception: str = "",
        user_id: str = "",
    ) -> PurchaseResult:
        service_id = SERVICE_ID_MAP.get(service.lower())
        if not service_id:
            raise ValueError(f"Service {service} not supported by SMS-Activate")
        country_id = COUNTRY_ID_MAP.get(country.upper())
        if not country_id:
            raise ValueError(f"Country {country} not supported by SMS-Activate")

        params: dict[str, Any] = {
            "action": "getNumber",
            "service": service_id,
            "country": country_id,
        }
        if operator:
            params["operator"] = operator
        if forward:
            params["forward"] = "1"
        if ref:
            params["ref"] = ref
        if use_cashback:
            params["useCashBack"] = "true"
        if activation_type:
            params["activationType"] = str(activation_type)
        if language:
            params["language"] = language
        if phone_exception:
            params["phoneException"] = phone_exception
        if max_price is not None:
            params["maxPrice"] = str(max_price)
        if user_id:
            params["userId"] = user_id

        text = await self._request(params)
        match = re.match(r"ACCESS_NUMBER:(\d+):(\d+)", text)
        if not match:
            raise RuntimeError(f"SMS-Activate unexpected response: {text}")

        activation_id = match.group(1)
        phone_number = match.group(2)
        if not phone_number.startswith("+"):
            phone_number = f"+{phone_number}"

        return PurchaseResult(
            phone_number=phone_number,
            order_id=activation_id,
            cost=0.0,
            provider="smsactivate",
            metadata={
                "activation_id": activation_id,
                "service_id": service_id,
                "country_id": country_id,
                "operator": operator or "",
            },
        )

    # ──────────────────────────────────────────────
    # Purchase V2 — action=getNumberV2
    # ──────────────────────────────────────────────

    async def get_number_v2(
        self,
        service: str,
        country: str,
        operator: str = "",
        max_price: Optional[float] = None,
        forward: bool = False,
        ref: str = "",
        activation_type: int = 0,
        language: str = "",
        phone_exception: str = "",
        order_id: str = "",
        user_id: str = "",
    ) -> dict:
        service_id = SERVICE_ID_MAP.get(service.lower())
        if not service_id:
            raise ValueError(f"Service {service} not supported by SMS-Activate")
        country_id = COUNTRY_ID_MAP.get(country.upper())
        if not country_id:
            raise ValueError(f"Country {country} not supported by SMS-Activate")

        params: dict[str, Any] = {
            "action": "getNumberV2",
            "service": service_id,
            "country": country_id,
        }
        if operator:
            params["operator"] = operator
        if forward:
            params["forward"] = "1"
        if ref:
            params["ref"] = ref
        if activation_type:
            params["activationType"] = str(activation_type)
        if language:
            params["language"] = language
        if phone_exception:
            params["phoneException"] = phone_exception
        if max_price is not None:
            params["maxPrice"] = str(max_price)
        if order_id:
            params["orderId"] = order_id
        if user_id:
            params["userId"] = user_id

        try:
            return await self._request_json(params)
        except Exception as e:
            logger.warning(f"SMS-Activate get_number_v2 failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Multi-Service Number — action=getMultiServiceNumber
    # ──────────────────────────────────────────────

    async def get_multi_service_number(
        self,
        services: list[str],
        country: str,
        forward: str = "",
        operator: str = "",
        ref: str = "",
    ) -> list[dict]:
        try:
            country_id = COUNTRY_ID_MAP.get(country.upper(), country)
            sid_list = [SERVICE_ID_MAP.get(s.lower(), s) for s in services]
            params: dict[str, Any] = {
                "action": "getMultiServiceNumber",
                "multiService": ",".join(sid_list),
                "country": country_id,
            }
            if forward:
                params["multiForward"] = forward
            if operator:
                params["operator"] = operator
            if ref:
                params["ref"] = ref
            text = await self._request(params)
            if text.startswith("{"):
                data = json.loads(text)
                if isinstance(data, dict) and "phone" in data:
                    return [data]
                if isinstance(data, list):
                    return data
            if text.startswith("NO_NUMBERS"):
                raise RuntimeError("SMS-Activate no numbers available for multi-service")
            if text.startswith("NO_BALANCE"):
                raise RuntimeError("SMS-Activate insufficient balance")
            return []
        except RuntimeError:
            raise
        except Exception as e:
            logger.warning(f"SMS-Activate get_multi_service_number failed: {e}")
            return []

    # ──────────────────────────────────────────────
    # Set Status — action=setStatus
    #   status: 1=send SMS, 3=request new code, 6=finish, 8=cancel
    # ──────────────────────────────────────────────

    async def set_status(self, order_id: str, status: int, forward: str = "") -> str:
        params: dict[str, Any] = {
            "action": "setStatus",
            "id": order_id,
            "status": str(status),
        }
        if forward:
            params["forward"] = forward
        text = await self._request(params)
        return text

    async def cancel(self, order_id: str) -> bool:
        try:
            text = await self.set_status(order_id, 8)
            return "ACCESS" in text or "ALREADY" in text
        except Exception as e:
            logger.warning(f"SMS-Activate cancel failed for {order_id}: {e}")
            return False

    async def finish_activation(self, order_id: str) -> bool:
        try:
            text = await self.set_status(order_id, 6)
            return "ACCESS" in text
        except Exception as e:
            logger.warning(f"SMS-Activate finish_activation failed for {order_id}: {e}")
            return False

    async def send_sms(self, order_id: str) -> str:
        return await self.set_status(order_id, 1)

    async def request_new_code(self, order_id: str) -> str:
        return await self.set_status(order_id, 3)

    # ──────────────────────────────────────────────
    # Get Status — action=getStatus / getStatusV2
    # ──────────────────────────────────────────────

    async def check_sms(self, order_id: str) -> Optional[MessageResult]:
        try:
            text = await self._request({
                "action": "getStatus",
                "id": order_id,
            })
            if text.startswith("STATUS_WAIT_CODE"):
                return None
            if text.startswith("STATUS_CANCEL"):
                return None
            match = re.match(r"STATUS_OK:\s*(.+)", text)
            if match:
                sms_code = match.group(1).strip()
                return MessageResult(
                    text=sms_code,
                    code=sms_code,
                )
            return None
        except Exception as e:
            logger.warning(f"SMS-Activate check_sms failed for {order_id}: {e}")
            return None

    async def get_status_v2(self, order_id: str) -> dict:
        try:
            return await self._request_json({
                "action": "getStatusV2",
                "id": order_id,
            })
        except Exception as e:
            logger.warning(f"SMS-Activate get_status_v2 failed for {order_id}: {e}")
            return {}

    # ──────────────────────────────────────────────
    # History — action=getHistory
    # ──────────────────────────────────────────────

    async def get_history(
        self,
        start: Optional[int] = None,
        end: Optional[int] = None,
        offset: int = 0,
        limit: int = 50,
    ) -> list[dict]:
        try:
            params: dict[str, Any] = {
                "action": "getHistory",
                "offset": str(offset),
                "limit": str(min(limit, 100)),
            }
            if start is not None:
                params["start"] = str(start)
            if end is not None:
                params["end"] = str(end)
            data = await self._request_json(params)
            if isinstance(data, list):
                return data
            return []
        except Exception as e:
            logger.warning(f"SMS-Activate get_history failed: {e}")
            return []

    # ──────────────────────────────────────────────
    # TOP 10 Countries — action=getListOfTopCountriesByService
    # ──────────────────────────────────────────────

    async def get_list_of_top_countries_by_service(self, service: str, length: int = 10, page: int = 1) -> list[dict]:
        try:
            sid = SERVICE_ID_MAP.get(service.lower(), service)
            data = await self._request_json({
                "action": "getListOfTopCountriesByService",
                "service": sid,
                "length": str(length),
                "page": str(page),
            })
            if isinstance(data, list):
                return data
            return []
        except Exception as e:
            logger.warning(f"SMS-Activate get_list_of_top_countries_by_service failed: {e}")
            return []

    # ──────────────────────────────────────────────
    # Incoming Call Status — action=getIncomingCallStatus
    # ──────────────────────────────────────────────

    async def get_incoming_call_status(self, activation_id: str) -> dict:
        try:
            return await self._request_json({
                "action": "getIncomingCallStatus",
                "activationId": activation_id,
            })
        except Exception as e:
            logger.warning(f"SMS-Activate get_incoming_call_status failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Prices — action=getPrices / getPricesExtended / getPricesVerification
    # ──────────────────────────────────────────────

    async def get_services(self, country: str) -> list[ServicePrice]:
        country_id = COUNTRY_ID_MAP.get(country.upper())
        if not country_id:
            return []
        try:
            text = await self._request({
                "action": "getPrices",
                "country": country_id,
            })
            data = self._parse_json(text)
            if not isinstance(data, dict):
                return []
            result = []
            for service_id_str, countries_data in data.items():
                if not isinstance(countries_data, dict):
                    continue
                for cid_str, price_info in countries_data.items():
                    if not isinstance(price_info, dict):
                        continue
                    if cid_str != country_id:
                        continue
                    cost_str = price_info.get("cost", "0")
                    count = price_info.get("count", 0)
                    try:
                        cost_rub = float(cost_str)
                    except (ValueError, TypeError):
                        cost_rub = 0.0
                    cost_usd = cost_rub * RUB_TO_USD
                    service_name = ID_TO_SERVICE.get(service_id_str, f"service_{service_id_str}")
                    result.append(ServicePrice(
                        service_id=service_name,
                        service_name=service_name.replace("_", " ").title(),
                        cost=cost_usd,
                        count=int(count) if isinstance(count, (int, float)) else 0,
                        metadata={"service_id": service_id_str, "country_id": cid_str},
                    ))
            return result
        except Exception as e:
            logger.warning(f"SMS-Activate get_services failed: {e}")
            return []

    async def get_prices(self, service: str = "", country: str = "") -> dict:
        params: dict[str, Any] = {"action": "getPrices"}
        if service:
            params["service"] = SERVICE_ID_MAP.get(service.lower(), service)
        if country:
            params["country"] = COUNTRY_ID_MAP.get(country.upper(), country)
        try:
            text = await self._request(params)
            return self._parse_json(text)
        except Exception as e:
            logger.warning(f"SMS-Activate get_prices failed: {e}")
            return {}

    async def get_prices_extended(self, service: str = "", country: str = "", free_price: bool = False) -> dict:
        params: dict[str, Any] = {"action": "getPricesExtended"}
        if service:
            params["service"] = SERVICE_ID_MAP.get(service.lower(), service)
        if country:
            params["country"] = COUNTRY_ID_MAP.get(country.upper(), country)
        if free_price:
            params["freePrice"] = "true"
        try:
            text = await self._request(params)
            return self._parse_json(text)
        except Exception as e:
            logger.warning(f"SMS-Activate get_prices_extended failed: {e}")
            return {}

    async def get_prices_verification(self, service: str = "") -> dict:
        params: dict[str, Any] = {"action": "getPricesVerification"}
        if service:
            params["service"] = SERVICE_ID_MAP.get(service.lower(), service)
        try:
            text = await self._request(params)
            return self._parse_json(text)
        except Exception as e:
            logger.warning(f"SMS-Activate get_prices_verification failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Directories — action=getCountries / getServicesList
    # ──────────────────────────────────────────────

    async def get_countries(self) -> list[dict]:
        try:
            text = await self._request({"action": "getCountries"})
            data = self._parse_json(text)
            if not isinstance(data, dict):
                return []
            result = []
            for name, info in data.items():
                if not isinstance(info, dict):
                    continue
                cid = info.get("id", 0)
                country_code = ID_TO_COUNTRY.get(str(cid), "")
                result.append({
                    "id": int(cid),
                    "code": country_code,
                    "name": name.replace("_", " ").title(),
                    "eng": info.get("eng", name),
                    "rus": info.get("rus", ""),
                    "chn": info.get("chn", ""),
                    "visible": info.get("visible", 1),
                    "retry": info.get("retry", 0),
                    "rent": info.get("rent", 0),
                    "multiService": info.get("multiService", 0),
                })
            return result
        except Exception as e:
            logger.warning(f"SMS-Activate get_countries failed: {e}")
            return []

    async def get_services_list(self, country: str = "", lang: str = "en") -> list[dict]:
        try:
            params: dict[str, Any] = {"action": "getServicesList", "lang": lang}
            if country:
                params["country"] = COUNTRY_ID_MAP.get(country.upper(), country)
            data = await self._request_json(params)
            if "services" in data and isinstance(data["services"], list):
                return data["services"]
            return []
        except Exception as e:
            logger.warning(f"SMS-Activate get_services_list failed: {e}")
            return []

    # ──────────────────────────────────────────────
    # Additional Service — action=getAdditionalService
    # ──────────────────────────────────────────────

    async def get_additional_service(self, service: str, parent_activation_id: str) -> dict:
        try:
            sid = SERVICE_ID_MAP.get(service.lower(), service)
            text = await self._request({
                "action": "getAdditionalService",
                "service": sid,
                "id": parent_activation_id,
            })
            match = re.match(r"ADDITIONAL:(\d+):(\d+)", text)
            if match:
                return {
                    "activation_id": match.group(1),
                    "phone": match.group(2),
                }
            return {"text": text}
        except Exception as e:
            logger.warning(f"SMS-Activate get_additional_service failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Extra Activation (Reactivate) — action=getExtraActivation / checkExtraActivation
    # ──────────────────────────────────────────────

    async def get_extra_activation(self, activation_id: str) -> dict:
        try:
            text = await self._request({
                "action": "getExtraActivation",
                "activationId": activation_id,
            })
            match = re.match(r"ACCESS_NUMBER:(\d+):(\d+)", text)
            if match:
                return {
                    "activation_id": match.group(1),
                    "phone": match.group(2),
                }
            return {"text": text}
        except Exception as e:
            logger.warning(f"SMS-Activate get_extra_activation failed: {e}")
            return {}

    async def check_extra_activation(self, activation_id: str) -> dict:
        try:
            return await self._request_json({
                "action": "checkExtraActivation",
                "activationId": activation_id,
            })
        except Exception as e:
            logger.warning(f"SMS-Activate check_extra_activation failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Repeated Voice Parsing — action=parseCall
    # ──────────────────────────────────────────────

    async def parse_call(self, activation_id: str, new_lang: str = "") -> dict:
        try:
            params: dict[str, Any] = {
                "action": "parseCall",
                "id": activation_id,
            }
            if new_lang:
                params["newLang"] = new_lang
            return await self._request_json(params)
        except Exception as e:
            logger.warning(f"SMS-Activate parse_call failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Rent API — action=getRentServicesAndCountries
    # ──────────────────────────────────────────────

    async def get_rent_services_and_countries(
        self,
        time: int = 2,
        operator: str = "",
        country: str = "",
        incoming_call: bool = False,
        currency: str = "",
    ) -> dict:
        try:
            params: dict[str, Any] = {"action": "getRentServicesAndCountries", "rent_time": str(time)}
            if operator:
                params["operator"] = operator
            if country:
                params["country"] = COUNTRY_ID_MAP.get(country.upper(), country)
            if incoming_call:
                params["incomingCall"] = "true"
            if currency:
                params["currency"] = currency
            return await self._request_json(params)
        except Exception as e:
            logger.warning(f"SMS-Activate get_rent_services_and_countries failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Rent Number — action=getRentNumber
    # ──────────────────────────────────────────────

    async def get_rent_number(
        self,
        service: str,
        country: str = "",
        time: int = 2,
        operator: str = "",
        url: str = "",
        incoming_call: bool = False,
    ) -> dict:
        try:
            sid = SERVICE_ID_MAP.get(service.lower(), service)
            params: dict[str, Any] = {
                "action": "getRentNumber",
                "service": sid,
                "rent_time": str(time),
            }
            if country:
                params["country"] = COUNTRY_ID_MAP.get(country.upper(), country)
            if operator:
                params["operator"] = operator
            if url:
                params["url"] = url
            if incoming_call:
                params["incomingCall"] = "true"
            return await self._request_json(params)
        except Exception as e:
            logger.warning(f"SMS-Activate get_rent_number failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Rent Status — action=getRentStatus
    # ──────────────────────────────────────────────

    async def get_rent_status(self, rent_id: str, page: int = 1, size: int = 10) -> dict:
        try:
            return await self._request_json({
                "action": "getRentStatus",
                "id": rent_id,
                "page": str(page),
                "size": str(size),
            })
        except Exception as e:
            logger.warning(f"SMS-Activate get_rent_status failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Set Rent Status — action=setRentStatus
    # ──────────────────────────────────────────────

    async def set_rent_status(self, rent_id: str, status: int) -> dict:
        try:
            return await self._request_json({
                "action": "setRentStatus",
                "id": rent_id,
                "status": str(status),
            })
        except Exception as e:
            logger.warning(f"SMS-Activate set_rent_status failed: {e}")
            return {}

    async def finish_rent(self, rent_id: str) -> dict:
        return await self.set_rent_status(rent_id, 1)

    async def cancel_rent(self, rent_id: str) -> dict:
        return await self.set_rent_status(rent_id, 2)

    # ──────────────────────────────────────────────
    # Rent List — action=getRentList
    # ──────────────────────────────────────────────

    async def get_rent_list(self, page: int = 1, length: int = 10) -> dict:
        try:
            return await self._request_json({
                "action": "getRentList",
                "page": str(page),
                "length": str(length),
            })
        except Exception as e:
            logger.warning(f"SMS-Activate get_rent_list failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Continue Rent — action=continueRentNumber
    # ──────────────────────────────────────────────

    async def continue_rent_number(self, rent_id: str, time: int = 2) -> dict:
        try:
            return await self._request_json({
                "action": "continueRentNumber",
                "id": rent_id,
                "rent_time": str(time),
            })
        except Exception as e:
            logger.warning(f"SMS-Activate continue_rent_number failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Continue Rent Price (deprecated) — action=getContinueRentPriceNumber
    # ──────────────────────────────────────────────

    async def get_continue_rent_price(self, rent_id: str, time: int = 2, currency: str = "") -> dict:
        try:
            params: dict[str, Any] = {
                "action": "getContinueRentPriceNumber",
                "id": rent_id,
                "rent_time": str(time),
            }
            if currency:
                params["currency"] = currency
            return await self._request_json(params)
        except Exception as e:
            logger.warning(f"SMS-Activate get_continue_rent_price failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Continue Rent Info — action=continueRentInfo
    # ──────────────────────────────────────────────

    async def continue_rent_info(self, rent_id: str, hours: int = 2, need_history: bool = False) -> dict:
        try:
            params: dict[str, Any] = {
                "action": "continueRentInfo",
                "id": rent_id,
                "hours": str(hours),
            }
            if need_history:
                params["needHistory"] = "true"
            return await self._request_json(params)
        except Exception as e:
            logger.warning(f"SMS-Activate continue_rent_info failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Partner API — action=buyPartnerProduct
    # ──────────────────────────────────────────────

    async def buy_partner_product(self, product_id: str) -> dict:
        try:
            return await self._request_json({
                "action": "buyPartnerProduct",
                "productId": product_id,
            })
        except Exception as e:
            logger.warning(f"SMS-Activate buy_partner_product failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Helpers
    # ──────────────────────────────────────────────

    def _parse_json(self, text: str):
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            return {}

    async def close(self):
        if self._client:
            await self._client.aclose()
            self._client = None
