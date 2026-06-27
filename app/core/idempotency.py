from datetime import datetime, timezone, timedelta

from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.domain.models import IdempotencyKey, gen_uuid


class IdempotencyService:
    def __init__(self, db: Session):
        self.db = db

    def check_and_set(self, key: str, ttl: int = 86400) -> bool:
        record = IdempotencyKey(
            id=gen_uuid(),
            key=key,
            expires_at=datetime.now(timezone.utc) + timedelta(seconds=ttl),
        )
        self.db.add(record)
        try:
            self.db.commit()
            return True
        except IntegrityError:
            self.db.rollback()
            return False

    def get_response(self, key: str):
        """استرجاع الاستجابة المخزنة — يتحقق من صلاحية المفتاح."""
        record = self.db.query(IdempotencyKey).filter(
            IdempotencyKey.key == key,
            IdempotencyKey.expires_at > datetime.now(timezone.utc),
        ).first()
        if record:
            return record.response
        return None

    def set_response(self, key: str, response: dict):
        self.db.query(IdempotencyKey).filter(
            IdempotencyKey.key == key
        ).update({"response": response})
        self.db.commit()

    @staticmethod
    def cleanup_expired(db: Session) -> int:
        """حذف المفاتيح المنتهية الصلاحية — يُستدعى من مهمة خلفية دورية."""
        deleted = db.query(IdempotencyKey).filter(
            IdempotencyKey.expires_at <= datetime.now(timezone.utc),
        ).delete()
        db.commit()
        return deleted
