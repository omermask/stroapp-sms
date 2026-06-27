import base64
import json
from datetime import datetime, timezone

from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)


class SecretsManager:
    SALT = b"stroapp-salt-v1"

    def __init__(self):
        settings = get_settings()
        self._fernet = self._init_fernet(settings.secret_key)

    @staticmethod
    def _init_fernet(secret_key: str) -> Fernet:
        kdf = PBKDF2HMAC(algorithm=hashes.SHA256(), length=32, salt=SecretsManager.SALT, iterations=600000)
        key = base64.urlsafe_b64encode(kdf.derive(secret_key.encode()))
        return Fernet(key)

    def encrypt(self, plain_text: str) -> str:
        return self._fernet.encrypt(plain_text.encode()).decode()

    def decrypt(self, encrypted: str) -> str:
        try:
            return self._fernet.decrypt(encrypted.encode()).decode()
        except Exception as e:
            logger.error(f"Decryption failed: {e}")
            return ""

    def encrypt_json(self, data: dict) -> str:
        return self._fernet.encrypt(json.dumps(data).encode()).decode()

    def decrypt_json(self, encrypted: str) -> dict:
        try:
            return json.loads(self._fernet.decrypt(encrypted.encode()).decode())
        except Exception as e:
            logger.error(f"JSON decryption failed: {e}")
            return {}


secrets_manager = SecretsManager()
