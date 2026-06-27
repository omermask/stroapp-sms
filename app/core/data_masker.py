import re
from typing import Any


_sensitive_keys = re.compile(
    r"(password|secret|token|api_key|api\.key|private_key|access_key|"
    r"credit_card|ssn|authorization|cookie)", re.IGNORECASE
)

_jwt_re = re.compile(r"eyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+")
_uuid_re = re.compile(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")


def mask_value(value: str) -> str:
    if not value:
        return value
    if len(value) <= 8:
        return "***"
    return value[:4] + "****" + value[-4:]


def mask_deep(data: Any) -> Any:
    if isinstance(data, dict):
        return {
            k: mask_value(v) if _sensitive_keys.search(k) and isinstance(v, str) else mask_deep(v)
            for k, v in data.items()
        }
    if isinstance(data, list):
        return [mask_deep(v) for v in data]
    return data


def sanitize_log_message(message: str) -> str:
    message = _jwt_re.sub("[JWT_REDACTED]", message)
    message = _uuid_re.sub("[UUID_REDACTED]", message)
    message = re.sub(r'(["\"])[A-Za-z0-9+/]{40,}={0,2}\1', r'\1[KEY_REDACTED]\1', message)
    return message


def mask_headers(headers: dict) -> dict:
    sensitive = {"authorization", "x-api-key", "cookie", "set-cookie", "x-csrf-token"}
    return {
        k: "***" if k.lower() in sensitive else v
        for k, v in headers.items()
    }
