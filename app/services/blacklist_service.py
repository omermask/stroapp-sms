from datetime import datetime, timezone, timedelta

from sqlalchemy.orm import Session

from app.domain.models import BlacklistedToken, BlacklistedIP, gen_uuid


class BlacklistService:
    @staticmethod
    def blacklist_token(db: Session, jti: str, token_type: str, user_id: str = "",
                        reason: str = "", expires_in_hours: int = 24):
        existing = db.query(BlacklistedToken).filter(BlacklistedToken.jti == jti).first()
        if existing:
            return existing
        entry = BlacklistedToken(
            id=gen_uuid(),
            jti=jti,
            token_type=token_type,
            user_id=user_id,
            reason=reason,
            expires_at=datetime.now(timezone.utc) + timedelta(hours=expires_in_hours),
        )
        db.add(entry)
        db.commit()
        return entry

    @staticmethod
    def is_token_blacklisted(db: Session, jti: str) -> bool:
        return db.query(BlacklistedToken).filter(
            BlacklistedToken.jti == jti,
            BlacklistedToken.expires_at > datetime.now(timezone.utc),
        ).first() is not None

    @staticmethod
    def cleanup_expired(db: Session):
        deleted = db.query(BlacklistedToken).filter(
            BlacklistedToken.expires_at <= datetime.now(timezone.utc),
        ).delete()
        db.commit()
        return deleted

    @staticmethod
    def blacklist_ip(db: Session, ip_address: str, reason: str = "",
                    blocked_by: str = "", expires_hours: int | None = None):
        existing = db.query(BlacklistedIP).filter(BlacklistedIP.ip_address == ip_address).first()
        if existing:
            return existing
        entry = BlacklistedIP(
            id=gen_uuid(),
            ip_address=ip_address,
            reason=reason,
            blocked_by=blocked_by,
            expires_at=datetime.now(timezone.utc) + timedelta(hours=expires_hours) if expires_hours else None,
        )
        db.add(entry)
        db.commit()
        return entry

    @staticmethod
    def is_ip_blacklisted(db: Session, ip_address: str) -> bool:
        now = datetime.now(timezone.utc)
        return db.query(BlacklistedIP).filter(
            BlacklistedIP.ip_address == ip_address,
            (BlacklistedIP.expires_at.is_(None) | (BlacklistedIP.expires_at > now)),
        ).first() is not None

    @staticmethod
    def remove_ip(db: Session, ip_address: str):
        db.query(BlacklistedIP).filter(BlacklistedIP.ip_address == ip_address).delete()
        db.commit()
