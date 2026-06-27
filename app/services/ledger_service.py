from datetime import datetime, timezone
from decimal import Decimal
from typing import Any

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.domain.models import LedgerEntry, gen_uuid


class LedgerService:
    @staticmethod
    def record_entry(db: Session, user_id: str, currency: str, amount: float,
                     entry_type: str, description: str = "",
                     reference_type: str = "", reference_id: str = "",
                     exchange_rate: float | None = None) -> LedgerEntry:
        last = db.query(func.max(LedgerEntry.balance_after)).filter(
            LedgerEntry.user_id == user_id,
            LedgerEntry.currency == currency,
        ).scalar() or 0.0

        balance_before = float(last)
        balance_after = balance_before + amount

        entry = LedgerEntry(
            id=gen_uuid(),
            user_id=user_id,
            currency=currency,
            amount=amount,
            balance_before=balance_before,
            balance_after=balance_after,
            entry_type=entry_type,
            description=description,
            reference_type=reference_type,
            reference_id=reference_id,
            exchange_rate=exchange_rate,
        )
        db.add(entry)
        db.commit()
        return entry

    @staticmethod
    def get_balance(db: Session, user_id: str, currency: str) -> float:
        balance = db.query(func.max(LedgerEntry.balance_after)).filter(
            LedgerEntry.user_id == user_id,
            LedgerEntry.currency == currency,
        ).scalar()
        return float(balance) if balance else 0.0

    @staticmethod
    def get_all_balances(db: Session, user_id: str) -> dict[str, float]:
        rows = db.query(
            LedgerEntry.currency,
            func.max(LedgerEntry.balance_after),
        ).filter(
            LedgerEntry.user_id == user_id,
        ).group_by(LedgerEntry.currency).all()
        return {row[0]: float(row[1]) for row in rows}

    @staticmethod
    def get_history(db: Session, user_id: str, currency: str | None = None,
                    limit: int = 100, offset: int = 0) -> list[LedgerEntry]:
        q = db.query(LedgerEntry).filter(LedgerEntry.user_id == user_id)
        if currency:
            q = q.filter(LedgerEntry.currency == currency)
        return q.order_by(LedgerEntry.created_at.desc()).offset(offset).limit(limit).all()

    @staticmethod
    def transfer(db: Session, from_user_id: str, to_user_id: str,
                 currency: str, amount: float, description: str = "") -> tuple[LedgerEntry, LedgerEntry]:
        debit = LedgerService.record_entry(
            db, from_user_id, currency, -amount, "transfer",
            description=f"Transfer out: {description}",
            reference_type="transfer",
        )
        credit = LedgerService.record_entry(
            db, to_user_id, currency, amount, "transfer",
            description=f"Transfer in: {description}",
            reference_type="transfer",
        )
        return debit, credit
