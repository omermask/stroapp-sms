import hashlib
import json
from datetime import datetime, timezone

from fastapi import Request
from sqlalchemy.orm import Session
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.database import SessionLocal
from app.core.logging import get_logger
from app.domain.models import DeviceFingerprint, gen_uuid

logger = get_logger(__name__)


class DeviceFingerprintMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if request.url.path in ("/stroapp/v1/health", "/stroapp/metrics",
                                 "/stroapp/docs", "/stroapp/redoc"):
            return await call_next(request)

        user_agent = request.headers.get("user-agent", "")
        ip = request.client.host if request.client else ""
        accept_language = request.headers.get("accept-language", "")
        accept_encoding = request.headers.get("accept-encoding", "")

        raw = f"{user_agent}|{ip}|{accept_language}|{accept_encoding}"
        fp_hash = hashlib.sha256(raw.encode()).hexdigest()[:32]

        request.state.device_fingerprint = fp_hash
        request.state.device_fingerprint_raw = raw

        response = await call_next(request)

        try:
            if response.status_code < 400 and hasattr(request.state, "user_id") and request.state.user_id:
                db = SessionLocal()
                try:
                    existing = db.query(DeviceFingerprint).filter(
                        DeviceFingerprint.fingerprint_hash == fp_hash,
                    ).first()

                    if existing:
                        existing.last_seen_at = datetime.now(timezone.utc)
                    else:
                        fp = DeviceFingerprint(
                            id=gen_uuid(),
                            user_id=request.state.user_id,
                            fingerprint_hash=fp_hash,
                            ip_address=ip,
                            user_agent=user_agent,
                            device_data={
                                "accept_language": accept_language,
                                "accept_encoding": accept_encoding,
                            },
                            risk_score=0.0,
                        )
                        db.add(fp)
                    db.commit()
                except Exception as e:
                    logger.warning(f"Device fingerprint save failed: {e}")
                finally:
                    db.close()
        except Exception as e:
            logger.warning(f"Device fingerprint middleware error: {e}")

        return response
