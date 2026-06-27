import copy

from sqlalchemy.orm import Session

from app.core.logging import get_logger
from app.domain.models import AuditLog, gen_uuid

logger = get_logger(__name__)

SENSITIVE_KEYS = {"token", "access_token", "refresh_token", "password", "secret",
                   "api_key", "authorization", "jwt", "reset_token", "id_token",
                   "identity_token", "turnstile_token"}


def _mask_sensitive_data(data: dict) -> dict:
    masked = copy.deepcopy(data)
    if isinstance(masked, dict):
        for key in masked:
            if any(sk in key.lower() for sk in SENSITIVE_KEYS):
                masked[key] = "***MASKED***"
    return masked


class AuditService:
    @staticmethod
    def log(
        db: Session,
        user_id: str,
        action: str,
        resource_type: str = "",
        resource_id: str = "",
        details: dict | None = None,
        ip_address: str = "",
        request_id: str = "",
    ):
        try:
            safe_details = _mask_sensitive_data(details or {})
            log = AuditLog(
                id=gen_uuid(),
                user_id=user_id,
                action=action,
                resource_type=resource_type,
                resource_id=resource_id,
                details=safe_details,
                ip_address=ip_address,
                request_id=request_id,
            )
            db.add(log)
            db.commit()
        except Exception as e:
            logger.error(f"Audit log failed: action={action} user={user_id} error={e}")
