import html
import re
from typing import Any


SERVICE_NAME_RE = re.compile(r"^[a-zA-Z0-9_\-\.]{1,50}$")
EMAIL_RE = re.compile(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")


def sanitize_html(value: str) -> str:
    return html.escape(value, quote=True)


def sanitize_deep(value: Any) -> Any:
    if isinstance(value, str):
        return html.escape(value, quote=True)
    if isinstance(value, dict):
        return {k: sanitize_deep(v) for k, v in value.items()}
    if isinstance(value, list):
        return [sanitize_deep(v) for v in value]
    return value


def validate_service_name(name: str) -> bool:
    return bool(SERVICE_NAME_RE.match(name))


def validate_email(email: str) -> bool:
    return bool(EMAIL_RE.match(email))


_script_pattern = re.compile(r"<script[^>]*?>.*?</script>", re.IGNORECASE | re.DOTALL)
_javascript_uri = re.compile(r"javascript\s*:", re.IGNORECASE)


def strip_script_tags(value: str) -> str:
    value = _script_pattern.sub("", value)
    value = _javascript_uri.sub("", value)
    return value


def sanitize_response_data(data: Any) -> Any:
    if isinstance(data, str):
        return strip_script_tags(sanitize_html(data))
    if isinstance(data, dict):
        return {k: sanitize_response_data(v) for k, v in data.items()}
    if isinstance(data, list):
        return [sanitize_response_data(v) for v in data]
    if isinstance(data, (int, float, bool)) or data is None:
        return data
    return str(data)
