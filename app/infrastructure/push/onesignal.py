import httpx

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)


class OneSignalClient:
    BASE_URL = "https://onesignal.com/api/v1"

    def __init__(self):
        settings = get_settings()
        self.app_id = settings.onesignal_app_id or ""
        self.api_key = settings.onesignal_api_key or ""
        self._configured = bool(self.app_id and self.api_key)

    def is_configured(self) -> bool:
        return self._configured

    async def send_notification(self, player_ids: list[str], title: str, body: str,
                                 data: dict = None, ttl: int = 86400) -> dict:
        if not self._configured:
            return {"success": False, "error": "OneSignal not configured"}
        payload = {
            "app_id": self.app_id,
            "include_player_ids": player_ids,
            "headings": {"en": title, "ar": title},
            "contents": {"en": body, "ar": body},
            "data": data or {},
            "ttl": ttl,
            "priority": 10,
        }
        try:
            async with httpx.AsyncClient(timeout=15) as client:
                resp = await client.post(
                    f"{self.BASE_URL}/notifications",
                    json=payload,
                    headers={"Authorization": f"Basic {self.api_key}"},
                )
                result = resp.json()
                if resp.status_code == 200:
                    logger.info(f"OneSignal sent: {result.get('id', 'unknown')}")
                    return {"success": True, "id": result.get("id"), "recipients": result.get("recipients", 0)}
                logger.warning(f"OneSignal error: {resp.status_code} {result}")
                return {"success": False, "error": result.get("errors", ["unknown"])[0]}
        except Exception as e:
            logger.error(f"OneSignal request failed: {e}")
            return {"success": False, "error": str(e)}

    async def send_to_segment(self, segment: str, title: str, body: str, data: dict = None) -> dict:
        if not self._configured:
            return {"success": False, "error": "OneSignal not configured"}
        payload = {
            "app_id": self.app_id,
            "included_segments": [segment],
            "headings": {"en": title, "ar": title},
            "contents": {"en": body, "ar": body},
            "data": data or {},
        }
        try:
            async with httpx.AsyncClient(timeout=15) as client:
                resp = await client.post(
                    f"{self.BASE_URL}/notifications",
                    json=payload,
                    headers={"Authorization": f"Basic {self.api_key}"},
                )
                return resp.json()
        except Exception as e:
            logger.error(f"OneSignal segment send failed: {e}")
            return {"success": False, "error": str(e)}

    async def get_device(self, player_id: str) -> dict:
        if not self._configured:
            return {}
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.get(
                    f"{self.BASE_URL}/players/{player_id}",
                    headers={"Authorization": f"Basic {self.api_key}"},
                )
                return resp.json()
        except Exception as e:
            logger.error(f"OneSignal get device failed: {e}")
            return {}


onesignal_client = OneSignalClient()
