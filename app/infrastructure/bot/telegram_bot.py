import httpx

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)


class TelegramBotClient:
    def __init__(self, bot_token: str = ""):
        settings = get_settings()
        self._token = bot_token or settings.telegram_bot_token or ""
        self._configured = bool(self._token)
        if self._configured:
            self._api_url = f"https://api.telegram.org/bot{self._token}"
        else:
            self._api_url = ""

    def is_configured(self) -> bool:
        return self._configured

    async def set_webhook(self, url: str, secret_token: str = "") -> bool:
        if not self._configured:
            return False
        payload = {"url": url}
        if secret_token:
            payload["secret_token"] = secret_token
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.post(f"{self._api_url}/setWebhook", json=payload)
                return resp.status_code == 200
        except Exception as e:
            logger.error(f"Telegram setWebhook failed: {e}")
            return False

    async def delete_webhook(self) -> bool:
        if not self._configured:
            return False
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.post(f"{self._api_url}/deleteWebhook")
                return resp.status_code == 200
        except Exception as e:
            logger.error(f"Telegram deleteWebhook failed: {e}")
            return False

    async def get_webhook_info(self) -> dict:
        if not self._configured:
            return {}
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.get(f"{self._api_url}/getWebhookInfo")
                return resp.json().get("result", {})
        except Exception as e:
            logger.error(f"Telegram getWebhookInfo failed: {e}")
            return {}

    async def send_message(self, chat_id: str, text: str, parse_mode: str = "HTML") -> dict:
        if not self._configured:
            return {"success": False, "error": "Telegram bot not configured"}
        payload = {"chat_id": chat_id, "text": text, "parse_mode": parse_mode}
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.post(f"{self._api_url}/sendMessage", json=payload)
                result = resp.json()
                if resp.status_code == 200 and result.get("ok"):
                    return {"success": True, "message_id": result["result"]["message_id"]}
                return {"success": False, "error": result.get("description", "unknown")}
        except Exception as e:
            logger.error(f"Telegram sendMessage failed: {e}")
            return {"success": False, "error": str(e)}

    async def get_me(self) -> dict:
        if not self._configured:
            return {}
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.get(f"{self._api_url}/getMe")
                return resp.json().get("result", {})
        except Exception as e:
            logger.error(f"Telegram getMe failed: {e}")
            return {}
