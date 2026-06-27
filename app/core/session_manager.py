from datetime import datetime, timezone, timedelta
from typing import Optional

from sqlalchemy.orm import Session

from app.domain.models import UserSession, gen_uuid


class SessionManager:
    @staticmethod
    def create_session(
        db: Session, user_id: str, ip_address: str,
        user_agent: str, refresh_token: str, expires_days: int = 30,
        city: Optional[str] = None, country: Optional[str] = None,
    ) -> UserSession:
        session = UserSession(
            id=gen_uuid(),
            user_id=user_id,
            refresh_token=refresh_token,
            ip_address=ip_address,
            user_agent=user_agent,
            city=city,
            country=country,
            expires_at=datetime.now(timezone.utc) + timedelta(days=expires_days),
        )
        db.add(session)
        db.commit()
        return session

    @staticmethod
    def get_session(db: Session, refresh_token: str) -> UserSession:
        return db.query(UserSession).filter(
            UserSession.refresh_token == refresh_token,
            UserSession.is_active == True,
            UserSession.expires_at > datetime.now(timezone.utc),
        ).first()

    @staticmethod
    def invalidate_session(db: Session, refresh_token: str):
        db.query(UserSession).filter(
            UserSession.refresh_token == refresh_token,
        ).update({"is_active": False})
        db.commit()

    @staticmethod
    def rotate_session(db: Session, old_refresh: str, user_id: str, ip_address: str,
                       user_agent: str, new_refresh: str,
                       city: Optional[str] = None, country: Optional[str] = None) -> UserSession:
        db.query(UserSession).filter(
            UserSession.refresh_token == old_refresh,
        ).update({"is_active": False})
        session = UserSession(
            id=gen_uuid(),
            user_id=user_id,
            refresh_token=new_refresh,
            ip_address=ip_address,
            user_agent=user_agent,
            city=city,
            country=country,
            expires_at=datetime.now(timezone.utc) + timedelta(days=30),
        )
        db.add(session)
        db.commit()
        return session

    @staticmethod
    def invalidate_all_sessions(db: Session, user_id: str):
        db.query(UserSession).filter(
            UserSession.user_id == user_id,
            UserSession.is_active == True,
        ).update({"is_active": False})
        db.commit()

    @staticmethod
    def invalidate_all_except(db: Session, user_id: str, keep_refresh: str):
        db.query(UserSession).filter(
            UserSession.user_id == user_id,
            UserSession.is_active == True,
            UserSession.refresh_token != keep_refresh,
        ).update({"is_active": False})
        db.commit()

    @staticmethod
    def get_user_sessions(db: Session, user_id: str) -> list[UserSession]:
        return db.query(UserSession).filter(
            UserSession.user_id == user_id,
        ).order_by(UserSession.created_at.desc()).all()
