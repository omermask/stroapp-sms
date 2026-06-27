import asyncio
from datetime import datetime, timezone

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.logging import get_logger
from app.domain.models import PaymentLog, Transaction, User, gen_uuid
from app.services.audit_service import AuditService
from app.services.iap_receipt_validator import (
    consume_google_play_purchase,
    verify_iap_receipt,
)

logger = get_logger(__name__)

IAP_PRODUCTS = {
    "coins_100": {"coins": 100, "usd": 1.99},
    "coins_500": {"coins": 500, "usd": 4.99},
    "coins_1000": {"coins": 1000, "usd": 9.99},
    "coins_2500": {"coins": 2500, "usd": 19.99},
    "coins_5000": {"coins": 5000, "usd": 39.99},
    "coins_10000": {"coins": 10000, "usd": 79.99},
}


class IAPService:
    def __init__(self, db: Session):
        self.db = db

    async def process_apple_receipt(self, user_id: str, receipt_data: str,
                                     ip: str = "", request_id: str = "") -> dict:
        result = await verify_iap_receipt("apple", receipt_data)
        if not result.get("valid"):
            AuditService.log(self.db, user_id, "iap.receipt_failed", "iap", "",
                            {"provider": "apple", "error": result.get("error")}, ip, request_id)
            return {"success": False, "error": result.get("error", "فشل التحقق من الإيصال")}

        product_id = result.get("product_id", "")
        product = IAP_PRODUCTS.get(product_id)
        if not product:
            product = IAP_PRODUCTS.get("coins_1000")

        coins = product["coins"]
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            return {"success": False, "error": "المستخدم غير موجود"}

        user.coins += coins
        user.lifetime_coins += coins
        txn = Transaction(
            id=gen_uuid(), user_id=user_id, amount=coins,
            type="credit", description=f"شحن عبر Apple Pay ({product_id})",
            reference=result.get("transaction_id", ""),
            coins_before=user.coins - coins, coins_after=user.coins,
        )
        self.db.add(txn)
        self.db.commit()

        AuditService.log(self.db, user_id, "iap.purchase", "iap", "",
                        {"provider": "apple", "product_id": product_id, "coins": coins}, ip, request_id)
        logger.info(f"Apple IAP: user={user_id} product={product_id} coins={coins}")
        return {"success": True, "coins": coins, "transaction_id": txn.id}

    async def process_google_receipt(self, user_id: str, product_id: str, purchase_token: str,
                                      ip: str = "", request_id: str = "") -> dict:
        existing = self.db.query(PaymentLog).filter(
            PaymentLog.reference == purchase_token,
            PaymentLog.provider == "google_play",
        ).first()
        if existing:
            if existing.status == "completed":
                user = self.db.query(User).filter(User.id == user_id).first()
                coins = existing.coins
                return {"success": True, "coins": coins, "transaction_id": existing.id,
                        "already_redeemed": True}
            return {"success": False, "error": "هذا الشراء قيد المعالجة بالفعل"}

        result = await verify_iap_receipt("google", purchase_token, product_id)
        if not result.get("valid"):
            AuditService.log(self.db, user_id, "iap.receipt_failed", "iap", "",
                            {"provider": "google", "error": result.get("error")}, ip, request_id)
            return {"success": False, "error": result.get("error", "فشل التحقق من الإيصال")}

        product = IAP_PRODUCTS.get(product_id)
        if not product:
            return {"success": False, "error": "المنتج غير معروف"}

        consume_result = await consume_google_play_purchase(product_id, purchase_token)
        if not consume_result.get("success"):
            return {"success": False, "error": "فشل تأكيد الشراء لدى Google"}

        self.db.execute(
            text("SELECT coins FROM users WHERE id = :uid FOR UPDATE"),
            {"uid": user_id},
        )

        double_check = self.db.query(PaymentLog).filter(
            PaymentLog.reference == purchase_token,
            PaymentLog.provider == "google_play",
        ).first()
        if double_check:
            if double_check.status == "completed":
                user = self.db.query(User).filter(User.id == user_id).first()
                return {"success": True, "coins": double_check.coins,
                        "already_redeemed": True}

        from app.services.revenue_service import RevenueService
        from app.services.webhook_service import WebhookService

        coins = product["coins"]
        order_id = result.get("order_id", "")
        user = self.db.query(User).filter(User.id == user_id).with_for_update().first()
        if not user:
            return {"success": False, "error": "المستخدم غير موجود"}

        coins_before = user.coins
        user.coins += coins
        user.lifetime_coins += coins

        log = PaymentLog(
            id=gen_uuid(),
            user_id=user_id,
            provider="google_play",
            product_id=product_id,
            amount_usd=product["usd"],
            coins=coins,
            reference=purchase_token,
            status="completed",
        )
        self.db.add(log)
        txn = Transaction(
            id=gen_uuid(), user_id=user_id, amount=coins,
            type="deposit", description=f"شحن عبر Google Play ({product_id})",
            reference=purchase_token,
            coins_before=coins_before, coins_after=user.coins,
        )
        self.db.add(txn)

        try:
            RevenueService.get_tax_configs(self.db)
            RevenueService.recognize_revenue(self.db, log.id)
        except Exception:
            self.db.rollback()
            raise

        AuditService.log(self.db, user_id, "iap.purchase", "iap", "",
                        {"provider": "google", "product_id": product_id, "coins": coins,
                         "order_id": order_id, "purchase_token": purchase_token}, ip, request_id)
        logger.info(f"Google Play IAP: user={user_id} product={product_id} coins={coins}")

        try:
            ws = WebhookService(self.db)
            asyncio.ensure_future(ws.dispatch_event("user.deposit", {
                "user_id": user.id,
                "amount": coins,
                "provider": "google_play",
                "reference": purchase_token,
            }, user.id))
        except Exception as e:
            logger.warning(f"Webhook dispatch failed for Google Play IAP: {e}")

        return {"success": True, "coins": coins, "transaction_id": txn.id}

    @staticmethod
    def get_products() -> dict:
        return IAP_PRODUCTS
