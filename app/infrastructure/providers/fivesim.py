import asyncio
import time
from datetime import datetime, timezone
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

BASE_URL = "https://5sim.net/v1"
REQ_INTERVAL = 0.5

SERVICE_NAME_MAP = {
    "telegram": "telegram", "whatsapp": "whatsapp", "google": "google",
    "facebook": "facebook", "instagram": "instagram", "twitter": "twitter",
    "tiktok": "tiktok", "discord": "discord", "snapchat": "snapchat",
    "uber": "uber", "amazon": "amazon", "netflix": "netflix",
    "linkedin": "linkedin", "microsoft": "microsoft", "apple": "apple",
    "coinbase": "coinbase", "binance": "binance", "airbnb": "airbnb",
    "doordash": "doordash", "signal": "signal", "viber": "viber",
    "line": "line", "wechat": "wechat", "steam": "steam",
    "kraken": "kraken", "cashapp": "cashapp", "yahoo": "yahoo",
    "tinder": "tinder", "kakao": "kakao", "vk": "vkontakte",
    "ok": "odnoklassniki", "olx": "olx",
}

FIVESIM_SERVICE_BY_NAME: dict[str, str] = {v: k for k, v in SERVICE_NAME_MAP.items()}

COUNTRY_NAME_MAP = {
    "US": "usa", "GB": "united_kingdom", "DE": "germany", "FR": "france",
    "IT": "italy", "ES": "spain", "IN": "india", "CA": "canada",
    "BR": "brazil", "AU": "australia", "JP": "japan",
    "NG": "nigeria", "ZA": "south_africa", "EG": "egypt", "SA": "saudi_arabia",
    "AE": "united_arab_emirates", "TR": "turkey", "PL": "poland",
    "VN": "vietnam", "PH": "philippines", "ID": "indonesia",
    "MY": "malaysia", "MX": "mexico", "PK": "pakistan", "BD": "bangladesh",
    "TH": "thailand", "SG": "singapore", "HK": "hong_kong", "IL": "israel",
    "KE": "kenya", "KZ": "kazakhstan", "RU": "russia", "NL": "netherlands",
    "SE": "sweden", "NO": "norway", "DK": "denmark", "FI": "finland",
    "PT": "portugal", "GR": "greece", "AT": "austria", "CH": "switzerland",
    "BE": "belgium", "IE": "ireland", "CZ": "czech_republic",
    "HU": "hungary", "BG": "bulgaria", "HR": "croatia", "LT": "lithuania",
    "UA": "ukraine", "RO": "romania", "RS": "serbia",
    "CL": "chile", "CO": "colombia", "PE": "peru", "AR": "argentina",
    "MA": "morocco", "DZ": "algeria", "TN": "tunisia",
    "GH": "ghana",
}


class FiveSimProvider(BaseProvider):
    def __init__(self):
        super().__init__()
        settings = get_settings()
        self.api_key = settings.fivesim_api_key
        self._enabled = bool(self.api_key)
        self._client: Optional[httpx.AsyncClient] = None
        self._last_req: float = 0.0

    def _client_instance(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            headers = {
                "Accept": "application/json",
                "User-Agent": "Mozilla/5.0",
            }
            if self.api_key:
                headers["Authorization"] = f"Bearer {self.api_key}"
            self._client = httpx.AsyncClient(base_url=BASE_URL, timeout=15, headers=headers)
        return self._client

    async def _throttle(self):
        now = time.monotonic()
        gap = now - self._last_req
        if gap < REQ_INTERVAL:
            await asyncio.sleep(REQ_INTERVAL - gap)
        self._last_req = time.monotonic()

    @property
    def name(self) -> str:
        return "fivesim"

    def _check_enabled(self) -> bool:
        return self._enabled

    # ──────────────────────────────────────────────
    # User Profile & Balance
    # ──────────────────────────────────────────────

    async def get_balance(self) -> float:
        """GET /user/profile -> balance"""
        if not self.enabled:
            return 0.0
        try:
            await self._throttle()
            client = self._client_instance()
            resp = await client.get("/user/profile")
            resp.raise_for_status()
            data = resp.json()
            return float(data.get("balance", 0))
        except Exception as e:
            logger.warning(f"5SIM get_balance failed: {e}")
            return 0.0

    async def get_profile(self) -> dict:
        """GET /user/profile full response"""
        if not self.enabled:
            return {}
        try:
            client = self._client_instance()
            resp = await client.get("/user/profile")
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.warning(f"5SIM get_profile failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Orders History — GET /user/orders
    # ──────────────────────────────────────────────

    async def get_orders(
        self,
        category: str = "activation",
        limit: int = 15,
        offset: int = 0,
        order: str = "id",
        reverse: bool = True,
    ) -> dict:
        if not self.enabled:
            return {"Data": [], "Total": 0}
        try:
            client = self._client_instance()
            resp = await client.get("/user/orders", params={
                "category": category, "limit": limit,
                "offset": offset, "order": order,
                "reverse": str(reverse).lower(),
            })
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.warning(f"5SIM get_orders failed: {e}")
            return {"Data": [], "Total": 0}

    # ──────────────────────────────────────────────
    # Payments History — GET /user/payments
    # ──────────────────────────────────────────────

    async def get_payments(
        self, limit: int = 15, offset: int = 0,
        order: str = "id", reverse: bool = True,
    ) -> dict:
        if not self.enabled:
            return {"Data": [], "Total": 0}
        try:
            client = self._client_instance()
            resp = await client.get("/user/payments", params={
                "limit": limit, "offset": offset,
                "order": order, "reverse": str(reverse).lower(),
            })
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.warning(f"5SIM get_payments failed: {e}")
            return {"Data": [], "Total": 0}

    # ──────────────────────────────────────────────
    # Price Limits — GET/POST/DELETE /user/max-prices
    # ──────────────────────────────────────────────

    async def get_max_prices(self) -> list[dict]:
        if not self.enabled:
            return []
        try:
            client = self._client_instance()
            resp = await client.get("/user/max-prices")
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.warning(f"5SIM get_max_prices failed: {e}")
            return []

    async def set_max_price(self, product_name: str, price: int) -> dict:
        if not self.enabled:
            return {}
        try:
            client = self._client_instance()
            resp = await client.post(
                "/user/max-prices",
                json={"product_name": product_name, "price": price},
            )
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.warning(f"5SIM set_max_price failed: {e}")
            return {}

    async def delete_max_price(self, product_name: str) -> bool:
        if not self.enabled:
            return False
        try:
            client = self._client_instance()
            resp = await client.request(
                "DELETE", "/user/max-prices",
                json={"product_name": product_name},
            )
            return resp.status_code == 200
        except Exception as e:
            logger.warning(f"5SIM delete_max_price failed: {e}")
            return False

    # ──────────────────────────────────────────────
    # Products & Prices (Guest endpoints)
    # ──────────────────────────────────────────────

    async def get_guest_products(self, country: str, operator: str = "any") -> dict:
        country_name = COUNTRY_NAME_MAP.get(country.upper())
        if not country_name:
            return {}
        try:
            client = self._client_instance()
            resp = await client.get(f"/guest/products/{country_name}/{operator}")
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.warning(f"5SIM get_guest_products failed: {e}")
            return {}

    async def get_prices(self, country: str = "", product: str = "") -> dict:
        if not self.enabled:
            return {}
        params = {}
        if country:
            cn = COUNTRY_NAME_MAP.get(country.upper())
            if cn:
                params["country"] = cn
        if product:
            pn = SERVICE_NAME_MAP.get(product.lower())
            if pn:
                params["product"] = pn
        try:
            await self._throttle()
            client = self._client_instance()
            resp = await client.get("/guest/prices", params=params)
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.warning(f"5SIM get_prices failed: {e}")
            return {}

    async def get_prices_by_country(self, country: str) -> dict:
        return await self.get_prices(country=country)

    async def get_prices_by_product(self, product: str) -> dict:
        return await self.get_prices(product=product)

    async def get_prices_by_country_product(self, country: str, product: str) -> dict:
        return await self.get_prices(country=country, product=product)

    # ──────────────────────────────────────────────
    # Purchase — GET /user/buy/activation/{country}/{operator}/{product}
    # ──────────────────────────────────────────────

    async def purchase_number(
        self,
        service: str,
        country: str,
        operator: str = "any",
        max_price: Optional[float] = None,
        forwarding: bool = False,
        forwarding_number: str = "",
        reuse: bool = False,
        voice: bool = False,
        ref: str = "",
    ) -> PurchaseResult:
        if not self.enabled:
            raise RuntimeError("5SIM provider is not configured")

        product = SERVICE_NAME_MAP.get(service.lower())
        if not product:
            raise ValueError(f"Service {service} not supported by 5SIM")

        await self._throttle()
        country_name = COUNTRY_NAME_MAP.get(country.upper())
        if not country_name:
            raise ValueError(f"Country {country} not supported by 5SIM")

        client = self._client_instance()
        params = {}
        if max_price is not None:
            params["maxPrice"] = max_price
        if forwarding:
            params["forwarding"] = "1"
        if forwarding_number:
            params["number"] = forwarding_number
        if reuse:
            params["reuse"] = "1"
        if voice:
            params["voice"] = "1"
        if ref:
            params["ref"] = ref

        resp = await client.get(
            f"/user/buy/activation/{country_name}/{operator}/{product}",
            params=params if params else None,
        )

        if resp.status_code == 400:
            err = resp.text.lower()
            if "no free phones" in err or "no_numbers" in err:
                raise RuntimeError(f"5SIM no numbers for {country}/{service}")
            if "not enough user balance" in err:
                raise RuntimeError("5SIM insufficient balance")
            if "not enough rating" in err:
                raise RuntimeError("5SIM rating too low")
            if "select country" in err:
                raise RuntimeError(f"5SIM bad country: {country}")
            if "select operator" in err:
                raise RuntimeError(f"5SIM bad operator: {operator}")
            if "bad country" in err:
                raise RuntimeError(f"5SIM bad country: {country}")
            if "bad operator" in err:
                raise RuntimeError(f"5SIM bad operator: {operator}")
            if "no product" in err:
                raise RuntimeError(f"5SIM no product: {service}")
            if "server offline" in err:
                raise RuntimeError("5SIM server offline")
            raise RuntimeError(f"5SIM purchase error: {resp.text}")
        if resp.status_code == 401:
            raise RuntimeError("5SIM invalid API key")
        resp.raise_for_status()

        data = resp.json()
        phone = data.get("phone", "")
        if phone and not phone.startswith("+"):
            phone = f"+{phone}"

        return PurchaseResult(
            phone_number=phone,
            order_id=str(data.get("id", "")),
            cost=float(data.get("price", 0)),
            provider="fivesim",
            expires_at=data.get("expires"),
            metadata={
                "id": data.get("id"),
                "product": product,
                "country": country_name,
                "operator": data.get("operator", ""),
                "status": data.get("status", ""),
                "forwarding": data.get("forwarding", False),
                "forwarding_number": data.get("forwarding_number", ""),
            },
        )

    # ──────────────────────────────────────────────
    # Buy Hosting Number — GET /user/buy/hosting/{country}/{operator}/{product}
    # ──────────────────────────────────────────────

    async def buy_hosting_number(
        self,
        service: str,
        country: str,
        operator: str = "any",
        max_price: Optional[float] = None,
    ) -> dict:
        if not self.enabled:
            raise RuntimeError("5SIM provider is not configured")
        product = SERVICE_NAME_MAP.get(service.lower())
        if not product:
            raise ValueError(f"Service {service} not supported by 5SIM")
        country_name = COUNTRY_NAME_MAP.get(country.upper())
        if not country_name:
            raise ValueError(f"Country {country} not supported by 5SIM")

        await self._throttle()
        client = self._client_instance()
        params = {}
        if max_price is not None:
            params["maxPrice"] = max_price

        resp = await client.get(
            f"/user/buy/hosting/{country_name}/{operator}/{product}",
            params=params if params else None,
        )
        if resp.status_code == 400:
            err = resp.text.lower()
            if "no free phones" in err:
                raise RuntimeError(f"5SIM no hosting numbers for {country}/{service}")
            raise RuntimeError(f"5SIM hosting purchase error: {resp.text}")
        resp.raise_for_status()
        return resp.json()

    # ──────────────────────────────────────────────
    # Re-use / Re-buy Number — GET /user/reuse/{product}/{number}
    # ──────────────────────────────────────────────

    async def reuse_number(self, product: str, phone_number: str) -> dict:
        if not self.enabled:
            raise RuntimeError("5SIM provider is not configured")
        await self._throttle()
        client = self._client_instance()
        resp = await client.get(f"/user/reuse/{product}/{phone_number}")
        if resp.status_code == 400:
            err = resp.text.lower()
            if "no free phones" in err:
                raise RuntimeError(f"5SIM no free phones for reuse")
            if "reuse not possible" in err or "reuse false" in err:
                raise RuntimeError("5SIM reuse not possible for this number")
            if "reuse expired" in err:
                raise RuntimeError("5SIM reuse period expired")
            raise RuntimeError(f"5SIM reuse error: {resp.text}")
        resp.raise_for_status()
        return resp.json()

    # ──────────────────────────────────────────────
    # Check Order (Get SMS) — GET /user/check/{id}
    # ──────────────────────────────────────────────

    async def check_sms(self, order_id: str) -> Optional[MessageResult]:
        if not self.enabled:
            return None
        try:
            await self._throttle()
            client = self._client_instance()
            resp = await client.get(f"/user/check/{order_id}")
            if resp.status_code == 404:
                return None
            resp.raise_for_status()
            data = resp.json()
            sms_list = data.get("sms", [])
            if sms_list:
                sms = sms_list[0]
                code = sms.get("code", "")
                text = sms.get("text", code)
                return MessageResult(
                    text=text,
                    code=code,
                    received_at=sms.get("date"),
                    metadata={
                        "sender": sms.get("sender", ""),
                        "id": sms.get("id"),
                        "created_at": sms.get("created_at"),
                    },
                )
            return None
        except Exception as e:
            logger.warning(f"5SIM check_sms failed for {order_id}: {e}")
            return None

    # ──────────────────────────────────────────────
    # SMS Inbox (for rented numbers) — GET /user/sms/inbox/{id}
    # ──────────────────────────────────────────────

    async def get_sms_inbox(self, order_id: str) -> dict:
        if not self.enabled:
            return {"Data": [], "Total": 0}
        try:
            client = self._client_instance()
            resp = await client.get(f"/user/sms/inbox/{order_id}")
            if resp.status_code == 404:
                return {"Data": [], "Total": 0}
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.warning(f"5SIM get_sms_inbox failed: {e}")
            return {"Data": [], "Total": 0}

    # ──────────────────────────────────────────────
    # Finish Order — GET /user/finish/{id}
    # ──────────────────────────────────────────────

    async def finish_order(self, order_id: str) -> dict:
        if not self.enabled:
            return {}
        try:
            client = self._client_instance()
            resp = await client.get(f"/user/finish/{order_id}")
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.warning(f"5SIM finish_order failed for {order_id}: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Cancel Order — GET /user/cancel/{id}
    # ──────────────────────────────────────────────

    async def cancel(self, order_id: str) -> bool:
        if not self.enabled:
            return False
        try:
            client = self._client_instance()
            resp = await client.get(f"/user/cancel/{order_id}")
            if resp.status_code == 400:
                err = resp.text.lower()
                if "order not found" in err:
                    logger.warning(f"5SIM order {order_id} not found for cancel")
                    return False
                if "order expired" in err:
                    logger.warning(f"5SIM order {order_id} already expired")
                    return False
                if "order has sms" in err:
                    logger.warning(f"5SIM order {order_id} has SMS — cannot cancel")
                    return False
                if "hosting order" in err:
                    logger.warning(f"5SIM order {order_id} is hosting — cannot cancel")
                    return False
            resp.raise_for_status()
            return True
        except Exception as e:
            logger.warning(f"5SIM cancel failed for {order_id}: {e}")
            return False

    # ──────────────────────────────────────────────
    # Ban Order — GET /user/ban/{id}
    # ──────────────────────────────────────────────

    async def ban_order(self, order_id: str) -> dict:
        if not self.enabled:
            return {}
        try:
            client = self._client_instance()
            resp = await client.get(f"/user/ban/{order_id}")
            if resp.status_code == 400:
                err = resp.text.lower()
                if "order not found" in err:
                    raise RuntimeError(f"5SIM order {order_id} not found")
                if "order expired" in err:
                    raise RuntimeError(f"5SIM order {order_id} already expired")
                if "order has sms" in err:
                    raise RuntimeError(f"5SIM order {order_id} has SMS — status is final")
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.warning(f"5SIM ban_order failed for {order_id}: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Guest Notifications — GET /guest/flash/{lang}
    # ──────────────────────────────────────────────

    async def get_notifications(self, lang: str = "en") -> str:
        try:
            client = self._client_instance()
            resp = await client.get(f"/guest/flash/{lang}")
            resp.raise_for_status()
            data = resp.json()
            return data.get("text", "")
        except Exception as e:
            logger.warning(f"5SIM get_notifications failed: {e}")
            return ""

    # ──────────────────────────────────────────────
    # Services (prices with available quantity) — GET /guest/prices
    # ──────────────────────────────────────────────

    async def get_services(self, country: str) -> list[ServicePrice]:
        country_name = COUNTRY_NAME_MAP.get(country.upper())
        if not country_name:
            return []
        try:
            await self._throttle()
            client = self._client_instance()
            resp = await client.get("/guest/prices", params={"country": country_name})
            resp.raise_for_status()
            data = resp.json()
            result = []
            for country_key, products in data.items():
                if country_key != country_name:
                    continue
                for product_name, operators in products.items():
                    if "any" in operators:
                        cost = float(operators["any"].get("cost", 0))
                    else:
                        first_op = next(iter(operators.values()), {})
                        cost = float(first_op.get("cost", 0))
                    count = sum(op.get("count", 0) for op in operators.values())
                    rate = max(
                        (op.get("rate", 0) or 0) for op in operators.values()
                    )
                    service_key = FIVESIM_SERVICE_BY_NAME.get(product_name, product_name)
                    result.append(ServicePrice(
                        service_id=service_key,
                        service_name=product_name.replace("_", " ").title(),
                        cost=cost,
                        count=count,
                        metadata={
                            "product": product_name,
                            "country": country_name,
                            "rate": rate,
                        },
                    ))
            return result
        except Exception as e:
            logger.warning(f"5SIM get_services failed: {e}")
            return []

    # ──────────────────────────────────────────────
    # Countries — GET /guest/countries
    # ──────────────────────────────────────────────

    async def get_countries(self) -> list[dict]:
        try:
            await self._throttle()
            client = self._client_instance()
            resp = await client.get("/guest/countries")
            resp.raise_for_status()
            data = resp.json()
            if isinstance(data, dict):
                result = []
                for country_key, info in data.items():
                    iso = info.get("iso", {})
                    code = next(iter(iso.keys()), country_key).upper() if iso else country_key.upper()
                    name = info.get("text_en", country_key).replace("_", " ").title()
                    result.append({"code": code, "name": name})
                return result
            if isinstance(data, list):
                return [
                    {"code": c.upper(), "name": c.replace("_", " ").title()}
                    for c in data if isinstance(c, str)
                ]
            return []
        except Exception as e:
            logger.warning(f"5SIM get_countries failed: {e}")
            return []

    # ──────────────────────────────────────────────
    # Vendor Stats — GET /user/vendor
    # ──────────────────────────────────────────────

    async def get_vendor_stats(self) -> dict:
        if not self.enabled:
            return {}
        try:
            client = self._client_instance()
            resp = await client.get("/user/vendor")
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.warning(f"5SIM get_vendor_stats failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Vendor Wallets — GET /vendor/wallets
    # ──────────────────────────────────────────────

    async def get_vendor_wallets(self) -> dict:
        if not self.enabled:
            return {}
        try:
            client = self._client_instance()
            resp = await client.get("/vendor/wallets")
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.warning(f"5SIM get_vendor_wallets failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Vendor Orders — GET /vendor/orders
    # ──────────────────────────────────────────────

    async def get_vendor_orders(
        self, limit: int = 15, offset: int = 0,
        order: str = "id", reverse: bool = True,
    ) -> dict:
        if not self.enabled:
            return {"Data": [], "Total": 0}
        try:
            client = self._client_instance()
            resp = await client.get("/vendor/orders", params={
                "limit": limit, "offset": offset,
                "order": order, "reverse": str(reverse).lower(),
            })
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.warning(f"5SIM get_vendor_orders failed: {e}")
            return {"Data": [], "Total": 0}

    # ──────────────────────────────────────────────
    # Vendor Payments — GET /vendor/payments
    # ──────────────────────────────────────────────

    async def get_vendor_payments(
        self, limit: int = 15, offset: int = 0,
        order: str = "id", reverse: bool = True,
    ) -> dict:
        if not self.enabled:
            return {"Data": [], "Total": 0}
        try:
            client = self._client_instance()
            resp = await client.get("/vendor/payments", params={
                "limit": limit, "offset": offset,
                "order": order, "reverse": str(reverse).lower(),
            })
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.warning(f"5SIM get_vendor_payments failed: {e}")
            return {"Data": [], "Total": 0}

    # ──────────────────────────────────────────────
    # Vendor Withdraw — POST /vendor/withdraw
    # ──────────────────────────────────────────────

    async def vendor_withdraw(self, amount: float, wallet: str = "", comment: str = "") -> dict:
        if not self.enabled:
            return {}
        try:
            client = self._client_instance()
            payload: dict[str, object] = {"amount": amount}
            if wallet:
                payload["wallet"] = wallet
            if comment:
                payload["comment"] = comment
            resp = await client.post("/vendor/withdraw", json=payload)
            if resp.status_code == 400:
                err = resp.text.lower()
                if "insufficient balance" in err:
                    raise RuntimeError("5SIM vendor insufficient balance")
                if "amount too low" in err:
                    raise RuntimeError("5SIM withdraw amount too low")
                if "amount too high" in err:
                    raise RuntimeError("5SIM withdraw amount too high")
                if "min amount" in err:
                    raise RuntimeError("5SIM withdraw below minimum amount")
                raise RuntimeError(f"5SIM vendor withdraw error: {resp.text}")
            resp.raise_for_status()
            return resp.json()
        except RuntimeError:
            raise
        except Exception as e:
            logger.warning(f"5SIM vendor_withdraw failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Vendor Prices — GET /vendor/prices
    # ──────────────────────────────────────────────

    async def get_vendor_prices(self, product: str = "", country: str = "") -> dict:
        if not self.enabled:
            return {}
        params = {}
        if product:
            pn = SERVICE_NAME_MAP.get(product.lower())
            if pn:
                params["product"] = pn
        if country:
            cn = COUNTRY_NAME_MAP.get(country.upper())
            if cn:
                params["country"] = cn
        try:
            client = self._client_instance()
            resp = await client.get("/vendor/prices", params=params if params else None)
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.warning(f"5SIM get_vendor_prices failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Vendor Create Price — PUT /vendor/prices
    # ──────────────────────────────────────────────

    async def create_vendor_price(
        self, product: str, country: str, operator: str = "any",
        price: float = 0, qty: int = 0,
    ) -> dict:
        if not self.enabled:
            return {}
        try:
            client = self._client_instance()
            product_name = SERVICE_NAME_MAP.get(product.lower(), product)
            country_name = COUNTRY_NAME_MAP.get(country.upper(), country)
            resp = await client.put(
                "/vendor/prices",
                json={
                    "product": product_name,
                    "country": country_name,
                    "operator": operator,
                    "price": price,
                    "qty": qty,
                },
            )
            if resp.status_code == 400:
                err = resp.text.lower()
                if "already exists" in err:
                    raise RuntimeError("5SIM vendor price already exists — use POST to update")
                if "bad product" in err:
                    raise RuntimeError(f"5SIM bad product: {product}")
                if "bad country" in err:
                    raise RuntimeError(f"5SIM bad country: {country}")
                raise RuntimeError(f"5SIM create vendor price error: {resp.text}")
            resp.raise_for_status()
            return resp.json()
        except RuntimeError:
            raise
        except Exception as e:
            logger.warning(f"5SIM create_vendor_price failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Vendor Change Price — POST /vendor/prices
    # ──────────────────────────────────────────────

    async def change_vendor_price(
        self, product: str, country: str, operator: str = "any",
        price: float = 0, qty: int = 0,
    ) -> dict:
        if not self.enabled:
            return {}
        try:
            client = self._client_instance()
            product_name = SERVICE_NAME_MAP.get(product.lower(), product)
            country_name = COUNTRY_NAME_MAP.get(country.upper(), country)
            resp = await client.post(
                "/vendor/prices",
                json={
                    "product": product_name,
                    "country": country_name,
                    "operator": operator,
                    "price": price,
                    "qty": qty,
                },
            )
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.warning(f"5SIM change_vendor_price failed: {e}")
            return {}

    # ──────────────────────────────────────────────
    # Vendor Toggle Price — POST /vendor/prices/disable
    # ──────────────────────────────────────────────

    async def toggle_vendor_price(
        self, product: str, country: str, operator: str = "any",
        disabled: bool = True,
    ) -> dict:
        if not self.enabled:
            return {}
        try:
            client = self._client_instance()
            product_name = SERVICE_NAME_MAP.get(product.lower(), product)
            country_name = COUNTRY_NAME_MAP.get(country.upper(), country)
            resp = await client.post(
                "/vendor/prices/disable",
                json={
                    "product": product_name,
                    "country": country_name,
                    "operator": operator,
                    "disable": int(disabled),
                },
            )
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.warning(f"5SIM toggle_vendor_price failed: {e}")
            return {}

    async def close(self):
        if self._client:
            await self._client.aclose()
            self._client = None
