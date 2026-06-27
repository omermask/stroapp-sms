from datetime import datetime, timezone, timedelta

from sqlalchemy.orm import Session

from app.domain.models import SMSOrder
from app.services.audit_service import AuditService


class FraudService:
    @staticmethod
    async def score_request(db: Session, user_id: str, ip: str, service: str) -> dict:
        score = 0
        reasons = []

        recent = db.query(SMSOrder).filter(
            SMSOrder.user_id == user_id,
            SMSOrder.created_at > datetime.now(timezone.utc) - timedelta(hours=1),
        ).count()
        if recent > 5:
            score += 20
            reasons.append("high_recent_attempts")

        failed = db.query(SMSOrder).filter(
            SMSOrder.user_id == user_id,
            SMSOrder.status == "expired",
            SMSOrder.created_at > datetime.now(timezone.utc) - timedelta(hours=24),
        ).count()
        if failed > 10:
            score += 30
            reasons.append("high_failure_rate")

        if recent > 20:
            score += 30
            reasons.append("abnormal_activity")

        if score > 50:
            AuditService.log(db, user_id, "fraud.high_score", "user", user_id,
                           {"score": score, "reasons": reasons, "service": service}, ip, "")

        return {"score": score, "reasons": reasons, "blocked": False}
