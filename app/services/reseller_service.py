from datetime import datetime, timezone
from typing import Optional

from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.domain.models import (
    BulkOperation,
    CreditAllocation,
    ResellerAccount,
    SubAccount,
    SubAccountTransaction,
    User,
    gen_uuid,
)


class ResellerService:
    @staticmethod
    def create_account(db: Session, user_id: str, data: dict) -> dict:
        existing = db.query(ResellerAccount).filter(ResellerAccount.user_id == user_id).first()
        if existing:
            return {"id": existing.id, "message": "حساب الريسلر موجود بالفعل"}

        volume_discount = data.get("volume_discount", 0.0)
        if not isinstance(volume_discount, (int, float)) or volume_discount < 0 or volume_discount > 1:
            raise AppException(code="validation_error", message="volume_discount يجب أن يكون بين 0 و 1")
        credit_limit = data.get("credit_limit", 0.0)
        if not isinstance(credit_limit, (int, float)) or credit_limit < 0:
            raise AppException(code="validation_error", message="credit_limit يجب أن يكون قيمة موجبة")
        custom_markup = data.get("custom_markup")
        if custom_markup is not None and (not isinstance(custom_markup, (int, float)) or custom_markup < 1.0):
            raise AppException(code="validation_error", message="custom_markup يجب أن يكون >= 1.0")
        auto_topup_threshold = data.get("auto_topup_threshold", 0.0)
        if not isinstance(auto_topup_threshold, (int, float)) or auto_topup_threshold < 0:
            raise AppException(code="validation_error", message="auto_topup_threshold يجب أن يكون قيمة موجبة")
        auto_topup_amount = data.get("auto_topup_amount", 0.0)
        if not isinstance(auto_topup_amount, (int, float)) or auto_topup_amount < 0:
            raise AppException(code="validation_error", message="auto_topup_amount يجب أن يكون قيمة موجبة")

        account = ResellerAccount(
            id=gen_uuid(),
            user_id=user_id,
            tier=data.get("tier", "basic"),
            volume_discount=volume_discount,
            custom_markup=custom_markup,
            credit_limit=credit_limit,
            auto_topup_enabled=data.get("auto_topup_enabled", False),
            auto_topup_threshold=auto_topup_threshold,
            auto_topup_amount=auto_topup_amount,
        )
        db.add(account)
        db.commit()
        db.refresh(account)
        return account.to_dict()

    @staticmethod
    def get_account(db: Session, user_id: str) -> Optional[dict]:
        account = db.query(ResellerAccount).filter(ResellerAccount.user_id == user_id).first()
        if not account:
            return None
        result = account.to_dict()
        sub_count = db.query(SubAccount).filter(SubAccount.reseller_account_id == account.id).count()
        result["sub_accounts_count"] = sub_count
        return result

    @staticmethod
    def list_accounts(db: Session, page: int = 1, per_page: int = 20, is_active: Optional[bool] = None) -> tuple[list[dict], int]:
        query = db.query(ResellerAccount)
        if is_active is not None:
            query = query.filter(ResellerAccount.is_active == is_active)
        total = query.count()
        accounts = query.order_by(ResellerAccount.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
        result = []
        for a in accounts:
            d = a.to_dict()
            user = db.query(User).filter(User.id == a.user_id).first()
            d["user_email"] = user.email if user else None
            d["sub_accounts_count"] = db.query(SubAccount).filter(SubAccount.reseller_account_id == a.id).count()
            result.append(d)
        return result, total

    @staticmethod
    def update_account(db: Session, user_id: str, data: dict) -> Optional[dict]:
        account = db.query(ResellerAccount).filter(ResellerAccount.user_id == user_id).first()
        if not account:
            return None

        updatable = ["tier", "volume_discount", "custom_markup", "credit_limit",
                     "auto_topup_enabled", "auto_topup_threshold", "auto_topup_amount"]
        for key in updatable:
            if key in data:
                if key == "volume_discount":
                    val = data[key]
                    if not isinstance(val, (int, float)) or val < 0 or val > 1:
                        raise AppException(code="validation_error", message="volume_discount يجب أن يكون بين 0 و 1")
                elif key == "credit_limit":
                    val = data[key]
                    if not isinstance(val, (int, float)) or val < 0:
                        raise AppException(code="validation_error", message="credit_limit يجب أن يكون قيمة موجبة")
                elif key == "custom_markup":
                    val = data[key]
                    if val is not None and (not isinstance(val, (int, float)) or val < 1.0):
                        raise AppException(code="validation_error", message="custom_markup يجب أن يكون >= 1.0")
                elif key in ("auto_topup_threshold", "auto_topup_amount"):
                    val = data[key]
                    if not isinstance(val, (int, float)) or val < 0:
                        raise AppException(code="validation_error", message=f"{key} يجب أن يكون قيمة موجبة")
                setattr(account, key, data[key])

        db.commit()
        db.refresh(account)
        return account.to_dict()

    @staticmethod
    def toggle_account(db: Session, user_id: str) -> Optional[dict]:
        account = db.query(ResellerAccount).filter(ResellerAccount.user_id == user_id).first()
        if not account:
            return None
        account.is_active = not account.is_active
        db.commit()
        db.refresh(account)
        return {"user_id": account.user_id, "is_active": account.is_active}

    @staticmethod
    def create_sub_account(db: Session, reseller_account_id: str, data: dict) -> dict:
        rate_multiplier = data.get("rate_multiplier", 1.0)
        if not isinstance(rate_multiplier, (int, float)) or rate_multiplier < 0.1 or rate_multiplier > 100:
            raise AppException(code="validation_error", message="rate_multiplier يجب أن يكون بين 0.1 و 100")
        coins = data.get("coins", 0.0)
        if not isinstance(coins, (int, float)) or coins < 0:
            raise AppException(code="validation_error", message="coins يجب أن يكون قيمة موجبة")
        usage_limit = data.get("usage_limit")
        if usage_limit is not None and (not isinstance(usage_limit, (int, float)) or usage_limit < 0):
            raise AppException(code="validation_error", message="usage_limit يجب أن يكون قيمة موجبة")
        sub = SubAccount(
            id=gen_uuid(),
            reseller_account_id=reseller_account_id,
            name=data["name"],
            email=data["email"],
            coins=coins,
            usage_limit=usage_limit,
            rate_multiplier=rate_multiplier,
            expires_at=data.get("expires_at"),
        )
        db.add(sub)
        db.flush()

        if data.get("coins", 0) > 0:
            db.add(SubAccountTransaction(
                id=gen_uuid(),
                sub_account_id=sub.id,
                transaction_type="credit",
                amount=data["coins"],
                description="الرصيد الابتدائي",
                reference=gen_uuid(),
                balance_before=0,
                balance_after=data["coins"],
            ))

        db.commit()
        db.refresh(sub)
        return sub.to_dict()

    @staticmethod
    def get_sub_account(db: Session, sub_account_id: str) -> Optional[dict]:
        sub = db.query(SubAccount).filter(SubAccount.id == sub_account_id).first()
        if not sub:
            return None
        return sub.to_dict()

    @staticmethod
    def list_sub_accounts(db: Session, reseller_account_id: Optional[str] = None, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(SubAccount)
        if reseller_account_id:
            query = query.filter(SubAccount.reseller_account_id == reseller_account_id)
        total = query.count()
        items = query.order_by(SubAccount.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
        return [s.to_dict() for s in items], total

    @staticmethod
    def update_sub_account(db: Session, sub_account_id: str, data: dict) -> Optional[dict]:
        sub = db.query(SubAccount).filter(SubAccount.id == sub_account_id).first()
        if not sub:
            return None
        updatable = ["name", "email", "usage_limit", "rate_multiplier", "expires_at"]
        for key in updatable:
            if key in data:
                if key == "rate_multiplier":
                    val = data[key]
                    if not isinstance(val, (int, float)) or val < 0.1 or val > 100:
                        raise AppException(code="validation_error", message="rate_multiplier يجب أن يكون بين 0.1 و 100")
                elif key == "usage_limit":
                    val = data[key]
                    if val is not None and (not isinstance(val, (int, float)) or val < 0):
                        raise AppException(code="validation_error", message="usage_limit يجب أن يكون قيمة موجبة")
                setattr(sub, key, data[key])
        db.commit()
        db.refresh(sub)
        return sub.to_dict()

    @staticmethod
    def toggle_sub_account(db: Session, sub_account_id: str) -> Optional[dict]:
        sub = db.query(SubAccount).filter(SubAccount.id == sub_account_id).first()
        if not sub:
            return None
        sub.is_active = not sub.is_active
        db.commit()
        return {"id": sub.id, "is_active": sub.is_active}

    @staticmethod
    def allocate_credit(db: Session, reseller_account_id: str, sub_account_id: str, amount: float, allocation_type: str = "manual", notes: Optional[str] = None) -> dict:
        # M-3 FIX: التحقق من قيمة المبلغ — منع القيم الصفرية والسالبة التصحيحية غير المصرح بها
        if amount == 0:
            return {"error": "يجب أن يكون المبلغ أكبر من صفر"}
        if abs(amount) > 10_000_000:
            return {"error": "المبلغ يتجاوز الحد المسموح"}
        # C-2 FIX: قفل صف الحساب الفرعي لمنع Race Condition عند التحديث المتزامن
        sub = db.query(SubAccount).filter(
            SubAccount.id == sub_account_id
        ).with_for_update().first()
        if not sub:
            return {"error": "الحساب الفرعي غير موجود"}
        # H-5 FIX: التحقق من ملكية الحساب الفرعي لمنع التعدي على حسابات غيره
        if sub.reseller_account_id != reseller_account_id:
            return {"error": "ليس لديك صلاحية لتعديل هذا الحساب"}

        balance_before = sub.coins
        sub.coins += amount

        db.add(CreditAllocation(
            id=gen_uuid(),
            reseller_account_id=reseller_account_id,
            sub_account_id=sub_account_id,
            amount=amount,
            allocation_type=allocation_type,
            notes=notes,
        ))
        db.add(SubAccountTransaction(
            id=gen_uuid(),
            sub_account_id=sub_account_id,
            transaction_type="credit" if amount > 0 else "debit",
            amount=amount,
            description=notes or "تعديل الرصيد",
            reference=gen_uuid(),
            balance_before=balance_before,
            balance_after=sub.coins,
        ))
        db.commit()
        return {
            "sub_account_id": sub_account_id,
            "amount": amount,
            "balance_before": balance_before,
            "balance_after": sub.coins,
        }

    @staticmethod
    def get_credit_history(db: Session, sub_account_id: str, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(CreditAllocation).filter(CreditAllocation.sub_account_id == sub_account_id)
        total = query.count()
        items = query.order_by(CreditAllocation.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": c.id,
                "reseller_account_id": c.reseller_account_id,
                "amount": c.amount,
                "allocation_type": c.allocation_type,
                "notes": c.notes,
                "created_at": c.created_at.isoformat(),
            }
            for c in items
        ], total

    @staticmethod
    def bulk_allocate(db: Session, reseller_account_id: str, sub_account_ids: list[str], amount: float, notes: Optional[str] = None) -> dict:
        op = BulkOperation(
            id=gen_uuid(),
            reseller_account_id=reseller_account_id,
            operation_type="credit_allocation",
            total_accounts=len(sub_account_ids),
            config={"sub_account_ids": sub_account_ids, "amount": amount, "notes": notes},
        )
        db.add(op)
        db.flush()

        processed = 0
        failed = 0
        for sub_id in sub_account_ids:
            result = ResellerService.allocate_credit(db, reseller_account_id, sub_id, amount, "bulk", notes)
            if "error" in result:
                failed += 1
            else:
                processed += 1

        op.processed_accounts = processed
        op.failed_accounts = failed
        op.status = "completed"
        op.completed_at = datetime.now(timezone.utc)
        db.commit()

        return {
            "operation_id": op.id,
            "status": "completed",
            "total": op.total_accounts,
            "processed": processed,
            "failed": failed,
        }

    @staticmethod
    def get_bulk_operation(db: Session, operation_id: str) -> Optional[dict]:
        op = db.query(BulkOperation).filter(BulkOperation.id == operation_id).first()
        if not op:
            return None
        return {
            "id": op.id,
            "operation_type": op.operation_type,
            "total_accounts": op.total_accounts,
            "processed_accounts": op.processed_accounts,
            "failed_accounts": op.failed_accounts,
            "status": op.status,
            "config": op.config,
            "created_at": op.created_at.isoformat(),
            "completed_at": op.completed_at.isoformat() if op.completed_at else None,
        }

    @staticmethod
    def get_transactions(db: Session, sub_account_id: str, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(SubAccountTransaction).filter(SubAccountTransaction.sub_account_id == sub_account_id)
        total = query.count()
        items = query.order_by(SubAccountTransaction.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": t.id,
                "transaction_type": t.transaction_type,
                "amount": t.amount,
                "description": t.description,
                "reference": t.reference,
                "balance_before": t.balance_before,
                "balance_after": t.balance_after,
                "created_at": t.created_at.isoformat(),
            }
            for t in items
        ], total

    @staticmethod
    def get_analytics(db: Session, reseller_id: str) -> dict:
        account = db.query(ResellerAccount).filter(ResellerAccount.user_id == reseller_id).first()
        if not account:
            return {}
        subs = db.query(SubAccount).filter(SubAccount.reseller_account_id == account.id).all()
        total_subs = len(subs)
        active_subs = sum(1 for s in subs if s.is_active)
        total_coins = sum(s.coins for s in subs)
        return {
            "reseller_id": reseller_id,
            "total_purchased": account.total_purchased,
            "credit_limit": account.credit_limit,
            "volume_discount": account.volume_discount,
            "custom_markup": account.custom_markup,
            "total_sub_accounts": total_subs,
            "active_sub_accounts": active_subs,
            "total_coins_distributed": total_coins,
        }
