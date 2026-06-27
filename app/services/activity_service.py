from datetime import datetime, timezone
from typing import Any

from sqlalchemy.orm import Session

from app.domain.models import ActivityFeed, gen_uuid


class ActivityService:
    @staticmethod
    def log(db: Session, user_id: str, activity_type: str, title: str,
            description: str = "", metadata_json: dict | None = None,
            ip_address: str = ""):
        entry = ActivityFeed(
            id=gen_uuid(),
            user_id=user_id,
            activity_type=activity_type,
            title=title,
            description=description,
            metadata_json=metadata_json,
            ip_address=ip_address,
        )
        db.add(entry)
        db.commit()
        return entry

    @staticmethod
    def get_user_activities(db: Session, user_id: str, limit: int = 50,
                            offset: int = 0, activity_type: str | None = None) -> list[ActivityFeed]:
        q = db.query(ActivityFeed).filter(ActivityFeed.user_id == user_id)
        if activity_type:
            q = q.filter(ActivityFeed.activity_type == activity_type)
        return q.order_by(ActivityFeed.created_at.desc()).offset(offset).limit(limit).all()

    @staticmethod
    def get_recent_global(db: Session, limit: int = 20) -> list[ActivityFeed]:
        return db.query(ActivityFeed).order_by(ActivityFeed.created_at.desc()).limit(limit).all()

    @staticmethod
    def cleanup_old(db: Session, days: int = 90):
        cutoff = datetime.now(timezone.utc).replace(tzinfo=None)
        from datetime import timedelta
        cutoff = cutoff - timedelta(days=days)
        deleted = db.query(ActivityFeed).filter(ActivityFeed.created_at < cutoff).delete()
        db.commit()
        return deleted
