import re
from datetime import datetime, timezone
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

BASE_URL = "https://api.smspool.net"

SERVICE_ID_MAP = {
    "telegram": "907", "whatsapp": "1012", "google": "395", "facebook": "329",
    "instagram": "457", "twitter": "948", "tiktok": "924", "discord": "273",
    "snapchat": "846", "uber": "951", "amazon": "39", "netflix": "630",
    "linkedin": "523", "microsoft": "1072", "apple": "48",
    "airbnb": "28", "signal": "829", "viber": "978", "line": "522",
    "wechat": "1004", "steam": "868", "yahoo": "1034", "tinder": "926",
}
ID_TO_SERVICE: dict[str, str] = {v: k for k, v in SERVICE_ID_MAP.items()}


class SmsPoolProvider(BaseProvider):
    supports_voice: bool = False
    supports_rentals: bool = True

    def __init__(self):
        super().__init__()
        settings = get_settings()
        self.api_key = settings.smspool_api_key
        self._enabled = bool(self.api_key)
        self._client: Optional[httpx.AsyncClient] = None

    def _client_instance(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            headers = {
                "Accept": "application/json",
                "Authorization": f"Bearer {self.api_key}",
            }
            self._client = httpx.AsyncClient(
                base_url=BASE_URL, timeout=10, headers=headers
            )
        return self._client

    @property
    def name(self) -> str:
        return "smspool"

    def _check_enabled(self) -> bool:
        return self._enabled

    async def _post(
        self, path: str, data: dict[str, Any] | None = None
    ) -> httpx.Response:
        client = self._client_instance()
        payload = dict(data or {})
        resp = await client.post(path, data=payload)

        if resp.status_code == 422:
            try:
                err_data = resp.json()
            except Exception:
                err_data = {}
            err_type = (err_data.get("type", "") or "").upper()
            err_msg = err_data.get("message", resp.text)
            if "OUT_OF_STOCK" in err_type:
                raise RuntimeError(f"SMSPool out of stock: {err_msg}")
            if "BALANCE_ERROR" in err_type:
                raise RuntimeError(f"SMSPool insufficient balance: {err_msg}")
            if "PRICE_NOT_FOUND" in err_type:
                raise RuntimeError(f"SMSPool price not found: {err_msg}")
            raise RuntimeError(f"SMSPool unprocessable: {err_msg}")

        if resp.status_code == 400:
            try:
                err_data = resp.json()
            except Exception:
                err_data = {}
            err_msg = err_data.get("message", resp.text)
            raise RuntimeError(f"SMSPool bad request: {err_msg}")

        if resp.status_code in (401, 403):
            raise RuntimeError("SMSPool invalid API key")

        if resp.status_code == 404:
            try:
                err_data = resp.json()
            except Exception:
                err_data = {}
            err_msg = err_data.get("message", "Resource not found")
            raise RuntimeError(f"SMSPool not found: {err_msg}")

        resp.raise_for_status()
        return resp

    async def _get(
        self, path: str, params: dict[str, Any] | None = None
    ) -> httpx.Response:
        client = self._client_instance()
        resp = await client.get(path, params=params)

        if resp.status_code in (401, 403):
            raise RuntimeError("SMSPool invalid API key")

        if resp.status_code == 404:
            try:
                err_data = resp.json()
            except Exception:
                err_data = {}
            err_msg = err_data.get("message", "Resource not found")
            raise RuntimeError(f"SMSPool not found: {err_msg}")

        resp.raise_for_status()
        return resp

    def _resolve_service(self, service: str) -> str:
        return SERVICE_ID_MAP.get(service.lower(), service)

    # ==================== Base Interface ====================

    async def purchase_number(
        self,
        service: str,
        country: str,
        pool: str = "",
        max_price: str = "",
        pricing_option: str = "",
        quantity: str = "1",
        areacode: str = "",
        exclude: str = "",
        create_token: str = "",
        activation_type: str = "",
        carrier: str = "",
        phonenumber: str = "",
    ) -> PurchaseResult:
        if not self.enabled:
            raise RuntimeError("SMSPool provider is not configured")
        service_id = self._resolve_service(service)
        data: dict[str, Any] = {
            "key": self.api_key,
            "service": service_id,
            "country": country,
            "quantity": quantity,
        }
        if pool:
            data["pool"] = pool
        if max_price:
            data["max_price"] = max_price
        if pricing_option:
            data["pricing_option"] = pricing_option
        if areacode:
            data["areacode"] = areacode
        if exclude:
            data["exclude"] = exclude
        if create_token:
            data["create_token"] = create_token
        if activation_type:
            data["activation_type"] = activation_type
        if carrier:
            data["carrier"] = carrier
        if phonenumber:
            data["phonenumber"] = phonenumber
        resp = await self._post("/purchase/sms", data)
        data_resp = resp.json()
        order_id = str(data_resp.get("order_id", ""))
        phone = data_resp.get("number", "") or data_resp.get("phonenumber", "")
        if phone and not phone.startswith("+"):
            phone = f"+{phone}"
        return PurchaseResult(
            phone_number=phone,
            order_id=order_id,
            cost=float(data_resp.get("cost", 0)),
            provider="smspool",
            metadata={
                "order_id": order_id,
                "service": service_id,
                "country": country,
                "raw_response": data_resp,
            },
        )

    async def check_sms(self, order_id: str) -> Optional[MessageResult]:
        if not self.enabled:
            return None
        try:
            resp = await self._post("/sms/check", {
                "key": self.api_key,
                "orderid": order_id,
            })
            data = resp.json()
            status = data.get("status", 1)
            if status in (2, 3):
                sms_text = (
                    data.get("sms")
                    or data.get("message")
                    or data.get("text")
                    or ""
                )
                if sms_text:
                    code_match = re.search(r"(\d{4,8})", sms_text)
                    code = code_match.group(1) if code_match else sms_text
                    return MessageResult(
                        text=sms_text,
                        code=code,
                        metadata={
                            "status": status,
                            "resend": data.get("resend", 0),
                            "expiration": data.get("expiration"),
                            "time_left": data.get("time_left"),
                        },
                    )
            return None
        except Exception as e:
            logger.warning(f"SMSPool check_sms failed for {order_id}: {e}")
            return None

    async def cancel(self, order_id: str) -> bool:
        if not self.enabled:
            return False
        try:
            resp = await self._post("/sms/cancel", {
                "key": self.api_key,
                "orderid": order_id,
            })
            data = resp.json()
            success = data.get("success", 0)
            return success == 1 or success is True
        except Exception as e:
            logger.warning(f"SMSPool cancel failed for {order_id}: {e}")
            return False

    async def get_balance(self) -> float:
        if not self.enabled:
            return 0.0
        try:
            resp = await self._post("/request/balance", {"key": self.api_key})
            data = resp.json()
            return float(data.get("balance", 0))
        except Exception as e:
            logger.warning(f"SMSPool get_balance failed: {e}")
            return 0.0

    async def get_services(self, country: str = "") -> list[ServicePrice]:
        try:
            if country:
                resp = await self._post("/sms/all_stock", {
                    "key": self.api_key, "country": country,
                })
                data = resp.json()
                entries = data[0] if (isinstance(data, list) and len(data) > 0 and isinstance(data[0], list)) else data

                svc_map: dict[int, dict] = {}
                for entry in entries:
                    sid = entry["service"]
                    if sid not in svc_map:
                        svc_map[sid] = {
                            "name": entry["service_name"],
                            "stock": 0,
                            "min_price": float("inf"),
                        }
                    svc_map[sid]["stock"] += entry["stock"]
                    price = float(entry.get("price", "0") or "0")
                    if price < svc_map[sid]["min_price"]:
                        svc_map[sid]["min_price"] = price

                result = []
                for sid, info in svc_map.items():
                    cost = info["min_price"] if info["min_price"] != float("inf") else 0.0
                    result.append(ServicePrice(
                        service_id=str(sid),
                        service_name=info["name"],
                        cost=cost,
                        count=info["stock"],
                        metadata={},
                    ))
                return result

            resp = await self._get("/service/retrieve_all")
            items = resp.json()
            if not isinstance(items, list):
                return []
            return [
                ServicePrice(
                    service_id=str(item["ID"]),
                    service_name=item["name"],
                    cost=0.0, count=0,
                    metadata={},
                )
                for item in items
            ]
        except Exception as e:
            logger.warning(f"SMSPool get_services failed: {e}")
            return []

    async def get_countries(self) -> list[dict]:
        try:
            resp = await self._get("/country/retrieve_all")
            data = resp.json()
            if not isinstance(data, list):
                return []
            return [
                {
                    "code": c.get("short_name", ""),
                    "name": c.get("name", ""),
                    "id": c.get("ID", ""),
                }
                for c in data
            ]
        except Exception as e:
            logger.warning(f"SMSPool get_countries failed: {e}")
            return []

    async def get_price(self, service: str, country: str, pool: str = "") -> float:
        if not self.enabled:
            return 999999.0
        try:
            data: dict[str, Any] = {
                "key": self.api_key,
                "service": self._resolve_service(service),
                "country": country,
            }
            if pool:
                data["pool"] = pool
            resp = await self._post("/request/price", data)
            data = resp.json()
            return float(data.get("price", 999999.0))
        except Exception:
            return 999999.0

    # ==================== SMS Endpoints ====================

    async def activate_sms(self, order_id: str) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/sms/activate", {
                "key": self.api_key,
                "orderid": order_id,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool activate_sms failed for {order_id}: {e}")
            return {}

    async def resend_sms(self, order_id: str) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/sms/resend", {
                "key": self.api_key,
                "orderid": order_id,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool resend_sms failed for {order_id}: {e}")
            return {}

    async def reactivate_sms(self, order_id: str) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/sms/reactivate", {
                "key": self.api_key,
                "orderid": order_id,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool reactivate_sms failed for {order_id}: {e}")
            return {}

    async def check_resend_sms(self, order_id: str) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/sms/check_resend", {
                "key": self.api_key,
                "orderid": order_id,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool check_resend_sms failed for {order_id}: {e}")
            return {}

    async def cancel_all_sms(self) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/sms/cancel_all", {
                "key": self.api_key,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool cancel_all_sms failed: {e}")
            return {}

    async def get_sms_stock(
        self, country: str, service: str, pool: str = ""
    ) -> list[dict]:
        if not self.enabled:
            return []
        try:
            data: dict[str, Any] = {
                "key": self.api_key,
                "country": country,
                "service": self._resolve_service(service),
            }
            if pool:
                data["pool"] = pool
            resp = await self._post("/sms/stock", data)
            items = resp.json()
            return items if isinstance(items, list) else []
        except Exception as e:
            logger.warning(f"SMSPool get_sms_stock failed: {e}")
            return []

    async def get_all_sms_stock(
        self, country: str, service: str, pool: str = ""
    ) -> list[dict]:
        if not self.enabled:
            return []
        try:
            data: dict[str, Any] = {
                "key": self.api_key,
                "country": country,
                "service": self._resolve_service(service),
            }
            if pool:
                data["pool"] = pool
            resp = await self._post("/sms/all_stock", data)
            items = resp.json()
            return items if isinstance(items, list) else []
        except Exception as e:
            logger.warning(f"SMSPool get_all_sms_stock failed: {e}")
            return []

    async def clear_sms_cache(self) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/sms/clear_cache", {})
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool clear_sms_cache failed: {e}")
            return {}

    # ==================== Request Endpoints ====================

    async def get_active_orders(self) -> list[dict]:
        if not self.enabled:
            return []
        try:
            resp = await self._post("/request/active", {
                "key": self.api_key,
            })
            data = resp.json()
            return data if isinstance(data, list) else []
        except Exception as e:
            logger.warning(f"SMSPool get_active_orders failed: {e}")
            return []

    async def get_order_history(
        self, start: str = "0", length: str = "10", search: str = ""
    ) -> list[dict]:
        if not self.enabled:
            return []
        try:
            data: dict[str, Any] = {
                "key": self.api_key,
                "start": start,
                "length": length,
            }
            if search:
                data["search"] = search
            resp = await self._post("/request/history", data)
            items = resp.json()
            return items if isinstance(items, list) else []
        except Exception as e:
            logger.warning(f"SMSPool get_order_history failed: {e}")
            return []

    async def get_success_rates(self, service: str) -> list[dict]:
        if not self.enabled:
            return []
        try:
            resp = await self._post("/request/success_rate", {
                "key": self.api_key,
                "service": self._resolve_service(service),
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool get_success_rates failed: {e}")
            return []

    async def get_suggested_countries(self, service: str) -> list[dict]:
        if not self.enabled:
            return []
        try:
            resp = await self._post("/request/suggested_countries", {
                "key": self.api_key,
                "service": self._resolve_service(service),
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool get_suggested_countries failed: {e}")
            return []

    async def get_areacodes(
        self, service: str, country: str, pool: str = ""
    ) -> list[dict]:
        if not self.enabled:
            return []
        try:
            data: dict[str, Any] = {
                "key": self.api_key,
                "service": self._resolve_service(service),
                "country": country,
            }
            if pool:
                data["pool"] = pool
            resp = await self._post("/request/areacodes", data)
            items = resp.json()
            return items if isinstance(items, list) else []
        except Exception as e:
            logger.warning(f"SMSPool get_areacodes failed: {e}")
            return []

    async def get_pricing(
        self,
        country: str = "",
        service: str = "",
        pool: str = "",
        max_price: str = "",
    ) -> list[dict]:
        if not self.enabled:
            return []
        try:
            data: dict[str, Any] = {"key": self.api_key}
            if country:
                data["country"] = country
            if service:
                data["service"] = self._resolve_service(service)
            if pool:
                data["pool"] = pool
            if max_price:
                data["max_price"] = max_price
            resp = await self._post("/request/pricing", data)
            items = resp.json()
            return items if isinstance(items, list) else []
        except Exception as e:
            logger.warning(f"SMSPool get_pricing failed: {e}")
            return []

    async def archive_sms(self) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/request/archive", {
                "key": self.api_key,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool archive_sms failed: {e}")
            return {}

    # ==================== Pool Endpoints ====================

    async def get_suggested_pools(
        self, service: str, country: str = "", web: str = ""
    ) -> list[dict]:
        if not self.enabled:
            return []
        try:
            data: dict[str, Any] = {
                "key": self.api_key,
                "service": self._resolve_service(service),
            }
            if country:
                data["country"] = country
            if web:
                data["web"] = web
            resp = await self._post("/pool/retrieve_valid", data)
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool get_suggested_pools failed: {e}")
            return []

    async def get_pool_list(self) -> list[dict]:
        if not self.enabled:
            return []
        try:
            resp = await self._post("/pool/retrieve_all", {"key": self.api_key})
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool get_pool_list failed: {e}")
            return []

    # ==================== Rental Endpoints ====================

    async def get_rental_ids(self, type_filter: str = "") -> dict:
        if not self.enabled:
            return {}
        try:
            data: dict[str, Any] = {"key": self.api_key}
            if type_filter:
                data["type"] = type_filter
            resp = await self._post("/rental/retrieve_all", data)
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool get_rental_ids failed: {e}")
            return {}

    async def order_rental(
        self,
        rental_id: int,
        days: int,
        service_id: str = "",
        create_token: int = 0,
    ) -> dict:
        if not self.enabled:
            return {}
        try:
            data: dict[str, Any] = {
                "key": self.api_key,
                "id": rental_id,
                "days": days,
            }
            if service_id:
                data["service_id"] = service_id
            if create_token:
                data["create_token"] = create_token
            resp = await self._post("/purchase/rental", data)
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool order_rental failed: {e}")
            return {}

    async def refund_rental(self, rental_code: str) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/rental/refund", {
                "key": self.api_key,
                "rental_code": rental_code,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool refund_rental failed: {e}")
            return {}

    async def reset_rental(self, rental_code: str) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/rental/reset", {
                "key": self.api_key,
                "rental_code": rental_code,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool reset_rental failed: {e}")
            return {}

    async def extend_rental(self, rental_code: str, days: int) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/rental/extend", {
                "key": self.api_key,
                "rental_code": rental_code,
                "days": days,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool extend_rental failed: {e}")
            return {}

    async def auto_extend_rental(self, rental_code: str) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/rental/auto_extend", {
                "key": self.api_key,
                "rental_code": rental_code,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool auto_extend_rental failed: {e}")
            return {}

    async def get_rental_history(self) -> list[dict]:
        if not self.enabled:
            return []
        try:
            resp = await self._post("/rental/history", {
                "key": self.api_key,
            })
            items = resp.json()
            return items if isinstance(items, list) else []
        except Exception as e:
            logger.warning(f"SMSPool get_rental_history failed: {e}")
            return []

    async def get_rental_messages(self, rental_code: str) -> list[dict]:
        if not self.enabled:
            return []
        try:
            resp = await self._post("/rental/retrieve_messages", {
                "key": self.api_key,
                "rental_code": rental_code,
            })
            items = resp.json()
            return items if isinstance(items, list) else []
        except Exception as e:
            logger.warning(f"SMSPool get_rental_messages failed: {e}")
            return []

    async def get_rental_status(self, rental_code: str) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/rental/retrieve_status", {
                "key": self.api_key,
                "rental_code": rental_code,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool get_rental_status failed: {e}")
            return {}

    async def get_active_rentals(self) -> list[dict]:
        if not self.enabled:
            return []
        try:
            resp = await self._post("/rental/retrieve", {
                "key": self.api_key,
            })
            items = resp.json()
            return items if isinstance(items, list) else []
        except Exception as e:
            logger.warning(f"SMSPool get_active_rentals failed: {e}")
            return []

    async def get_rental_pricing(self, rental_id: int) -> list[dict]:
        if not self.enabled:
            return []
        try:
            resp = await self._post("/rental/retrieve_pricing", {
                "key": self.api_key,
                "id": rental_id,
            })
            items = resp.json()
            return items if isinstance(items, list) else []
        except Exception as e:
            logger.warning(f"SMSPool get_rental_pricing failed: {e}")
            return []

    async def get_rental_services(self, rental_id: int) -> list[dict]:
        if not self.enabled:
            return []
        try:
            resp = await self._post("/rental/retrieve_services", {
                "key": self.api_key,
                "rental": rental_id,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool get_rental_services failed: {e}")
            return []

    async def get_rental_stock(self, rental_id: int, days: int) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/rental/stock", {
                "key": self.api_key,
                "id": rental_id,
                "days": days,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool get_rental_stock failed: {e}")
            return {}

    async def get_rental_info(self, rental_code: str) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/rental/info", {
                "key": self.api_key,
                "rental_code": rental_code,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool get_rental_info failed: {e}")
            return {}

    # ==================== eSIM Endpoints ====================

    async def purchase_esim(self, plan: int) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/esim/purchase", {
                "key": self.api_key,
                "plan": plan,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool purchase_esim failed: {e}")
            return {}

    async def esim_profile(self, transaction_id: str) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/esim/profile", {
                "key": self.api_key,
                "transactionId": transaction_id,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool esim_profile failed: {e}")
            return {}

    async def esim_topup(self, transaction_id: str, plan: int) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/esim/topup", {
                "key": self.api_key,
                "transactionId": transaction_id,
                "plan": plan,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool esim_topup failed: {e}")
            return {}

    async def esim_topup_plans(self, plan: int) -> list[dict]:
        if not self.enabled:
            return []
        try:
            resp = await self._post("/esim/topup_plans", {
                "key": self.api_key,
                "plan": plan,
            })
            items = resp.json()
            return items if isinstance(items, list) else []
        except Exception as e:
            logger.warning(f"SMSPool esim_topup_plans failed: {e}")
            return []

    async def esim_pricing(
        self, start: str = "0", length: str = "10", search: str = ""
    ) -> list[dict]:
        if not self.enabled:
            return []
        try:
            data: dict[str, Any] = {
                "key": self.api_key,
                "start": start,
                "length": length,
            }
            if search:
                data["Search"] = search
            resp = await self._post("/esim/pricing", data)
            items = resp.json()
            return items if isinstance(items, list) else []
        except Exception as e:
            logger.warning(f"SMSPool esim_pricing failed: {e}")
            return []

    async def esim_plans(self, country: str) -> list[dict]:
        if not self.enabled:
            return []
        try:
            resp = await self._post("/esim/plans", {
                "key": self.api_key,
                "country": country,
            })
            items = resp.json()
            return items if isinstance(items, list) else []
        except Exception as e:
            logger.warning(f"SMSPool esim_plans failed: {e}")
            return []

    async def esim_history(
        self, start: str = "0", length: str = "10", search: str = ""
    ) -> list[dict]:
        if not self.enabled:
            return []
        try:
            data: dict[str, Any] = {
                "key": self.api_key,
                "start": start,
                "length": length,
            }
            if search:
                data["search"] = search
            resp = await self._post("/esim/history", data)
            items = resp.json()
            return items if isinstance(items, list) else []
        except Exception as e:
            logger.warning(f"SMSPool esim_history failed: {e}")
            return []

    async def esim_delete(self, transaction_id: str) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/esim/delete", {
                "key": self.api_key,
                "transactionId": transaction_id,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool esim_delete failed: {e}")
            return {}

    # ==================== Voucher Endpoints ====================

    async def generate_voucher(self, amount: str, quantity: str = "") -> dict:
        if not self.enabled:
            return {}
        try:
            data: dict[str, Any] = {
                "key": self.api_key,
                "amount": amount,
            }
            if quantity:
                data["quantity"] = quantity
            resp = await self._post("/voucher/generate", data)
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool generate_voucher failed: {e}")
            return {}

    async def retrieve_vouchers(self) -> list[dict]:
        if not self.enabled:
            return []
        try:
            resp = await self._post("/voucher/retrieve", {
                "key": self.api_key,
            })
            items = resp.json()
            return items if isinstance(items, list) else []
        except Exception as e:
            logger.warning(f"SMSPool retrieve_vouchers failed: {e}")
            return []

    async def delete_voucher(self, voucher: str) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/voucher/delete", {
                "key": self.api_key,
                "voucher": voucher,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool delete_voucher failed: {e}")
            return {}

    # ==================== Carrier Endpoints ====================

    async def carrier_lookup(self, phonenumber: str) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/carrier/paid_lookup", {
                "key": self.api_key,
                "phonenumber": phonenumber,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool carrier_lookup failed: {e}")
            return {}

    # ==================== Preorder Endpoints ====================

    async def get_preorders(self) -> list[dict]:
        if not self.enabled:
            return []
        try:
            resp = await self._post("/preorder/retrieve", {
                "key": self.api_key,
            })
            items = resp.json()
            return items if isinstance(items, list) else []
        except Exception as e:
            logger.warning(f"SMSPool get_preorders failed: {e}")
            return []

    async def check_preorder(self, order_id: str) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/preorder/check", {
                "key": self.api_key,
                "orderid": order_id,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool check_preorder failed: {e}")
            return {}

    async def cancel_preorder(self, order_id: str) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/preorder/cancel", {
                "key": self.api_key,
                "orderid": order_id,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool cancel_preorder failed: {e}")
            return {}

    async def create_preorder(
        self,
        service: str,
        country: str,
        pool: str = "",
        areacode: str = "",
        max_price: str = "",
    ) -> dict:
        if not self.enabled:
            return {}
        try:
            data: dict[str, Any] = {
                "key": self.api_key,
                "service": self._resolve_service(service),
                "country": country,
            }
            if pool:
                data["pool"] = pool
            if areacode:
                data["areacode"] = areacode
            if max_price:
                data["max_price"] = max_price
            resp = await self._post("/preorder/create", data)
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool create_preorder failed: {e}")
            return {}

    async def get_preorder_price(
        self, service: str, country: str, pool: str = ""
    ) -> dict:
        if not self.enabled:
            return {}
        try:
            data: dict[str, Any] = {
                "key": self.api_key,
                "service": self._resolve_service(service),
                "country": country,
            }
            if pool:
                data["pool"] = pool
            resp = await self._post("/preorder/price", data)
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool get_preorder_price failed: {e}")
            return {}

    # ==================== Business Endpoints ====================

    async def get_business_users(self) -> list[dict]:
        if not self.enabled:
            return []
        try:
            resp = await self._get("/business/users")
            items = resp.json()
            return items if isinstance(items, list) else []
        except Exception as e:
            logger.warning(f"SMSPool get_business_users failed: {e}")
            return []

    async def create_business_user(
        self, username: str, password: str
    ) -> dict:
        if not self.enabled:
            return {}
        try:
            resp = await self._post("/business/create", {
                "key": self.api_key,
                "username": username,
                "password": password,
            })
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool create_business_user failed: {e}")
            return {}

    async def update_business_user(
        self,
        user_id: int,
        password: str = "",
        balance: str = "",
        active: str = "",
    ) -> dict:
        if not self.enabled:
            return {}
        try:
            data: dict[str, Any] = {"key": self.api_key, "id": user_id}
            if password:
                data["password"] = password
            if balance:
                data["balance"] = balance
            if active:
                data["active"] = active
            resp = await self._post("/business/user/update", data)
            return resp.json()
        except Exception as e:
            logger.warning(f"SMSPool update_business_user failed: {e}")
            return {}

    async def get_business_user_history(self, user_id: int) -> list[dict]:
        if not self.enabled:
            return []
        try:
            resp = await self._post("/business/user/history", {
                "key": self.api_key,
                "id": user_id,
            })
            items = resp.json()
            return items if isinstance(items, list) else []
        except Exception as e:
            logger.warning(f"SMSPool get_business_user_history failed: {e}")
            return []

    # ==================== Service & Country Info ====================

    async def get_all_services(self, country: str = "") -> list[dict]:
        try:
            params: dict[str, Any] = {}
            if country:
                params["country"] = country
            resp = await self._get("/service/retrieve_all", params)
            items = resp.json()
            return items if isinstance(items, list) else []
        except Exception as e:
            logger.warning(f"SMSPool get_all_services failed: {e}")
            return []

    async def get_all_countries(self) -> list[dict]:
        try:
            resp = await self._get("/country/retrieve_all")
            data = resp.json()
            return data if isinstance(data, list) else []
        except Exception as e:
            logger.warning(f"SMSPool get_all_countries failed: {e}")
            return []

    async def close(self):
        if self._client:
            await self._client.aclose()
            self._client = None
