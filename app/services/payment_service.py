import asyncio
import base64
import hashlib
import json
import uuid
from datetime import datetime, timezone
from typing import Any, Optional

import httpx
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.exceptions import AppException
from app.core.logging import get_logger
from app.domain.coins import CoinsEngine
from app.domain.models import PaymentLog, PaymentProduct, User, Transaction, gen_uuid
from app.services.revenue_service import RevenueService
from app.services.webhook_service import WebhookService

logger = get_logger(__name__)

PRODUCTS_BY_PROVIDER = {
    "google_pay": [
        {"product_id": "coins_100", "amount_usd": 1.0, "label": "100 Coins"},
        {"product_id": "coins_500", "amount_usd": 5.0, "label": "500 Coins"},
        {"product_id": "coins_1000", "amount_usd": 10.0, "label": "1000 Coins"},
        {"product_id": "coins_2500", "amount_usd": 25.0, "label": "2500 Coins"},
        {"product_id": "coins_5000", "amount_usd": 50.0, "label": "5000 Coins"},
        {"product_id": "coins_10000", "amount_usd": 100.0, "label": "10000 Coins"},
    ],
    "apple_pay": [
        {"product_id": "coins_100", "amount_usd": 1.0, "label": "100 Coins"},
        {"product_id": "coins_500", "amount_usd": 5.0, "label": "500 Coins"},
        {"product_id": "coins_1000", "amount_usd": 10.0, "label": "1000 Coins"},
        {"product_id": "coins_2500", "amount_usd": 25.0, "label": "2500 Coins"},
        {"product_id": "coins_5000", "amount_usd": 50.0, "label": "5000 Coins"},
        {"product_id": "coins_10000", "amount_usd": 100.0, "label": "10000 Coins"},
    ],
}


class PaymentService:
    def __init__(self, db: Session):
        self.db = db
        self.settings = get_settings()

    def get_products(self, provider: str) -> list[dict]:
        return PRODUCTS_BY_PROVIDER.get(provider, [])

    def seed_products(self):
        for provider, products in PRODUCTS_BY_PROVIDER.items():
            for p in products:
                existing = self.db.query(PaymentProduct).filter(
                    PaymentProduct.product_id == p["product_id"],
                    PaymentProduct.provider == provider,
                ).first()
                if not existing:
                    product = PaymentProduct(
                        id=gen_uuid(),
                        provider=provider,
                        product_id=p["product_id"],
                        amount_usd=p["amount_usd"],
                        coins=CoinsEngine.usd_to_coins(p["amount_usd"], self.db),
                        label=p["label"],
                        is_active=True,
                    )
                    self.db.add(product)
        self.db.commit()

    async def process_google_pay(self, user: User, payment_token: str, product_id: str) -> dict:
        product = self.db.query(PaymentProduct).filter(
            PaymentProduct.product_id == product_id,
            PaymentProduct.provider == "google_pay",
            PaymentProduct.is_active == True,
        ).first()
        if not product:
            raise AppException("VALIDATION_ERROR", "المنتج غير صالح", status_code=400)

        verification = await self._verify_google_payment(payment_token, product.amount_usd)
        if not verification:
            raise AppException("PROVIDER_ERROR", "فشل التحقق من Google Pay", status_code=502)

        return self._credit_user(user, product, "google_pay", verification.get("transaction_id"))

    async def process_apple_pay(self, user: User, payment_token: str, product_id: str) -> dict:
        product = self.db.query(PaymentProduct).filter(
            PaymentProduct.product_id == product_id,
            PaymentProduct.provider == "apple_pay",
            PaymentProduct.is_active == True,
        ).first()
        if not product:
            raise AppException("VALIDATION_ERROR", "المنتج غير صالح", status_code=400)

        verification = await self._verify_apple_payment(payment_token, product.amount_usd)
        if not verification:
            raise AppException("PROVIDER_ERROR", "فشل التحقق من Apple Pay", status_code=502)

        return self._credit_user(user, product, "apple_pay", verification.get("transaction_id"))

    async def process_apple_iap(self, user: User, transaction_id: str, product_id: str) -> dict:
        product = self.db.query(PaymentProduct).filter(
            PaymentProduct.product_id == product_id,
            PaymentProduct.provider == "apple_pay",
            PaymentProduct.is_active == True,
        ).first()
        if not product:
            raise AppException("VALIDATION_ERROR", "المنتج غير صالح", status_code=400)

        from app.services.iap_receipt_validator import verify_apple_transaction_v2

        verification = await verify_apple_transaction_v2(
            transaction_id=transaction_id,
            product_id=product_id,
        )
        if not verification.get("valid"):
            raise AppException(
                "PROVIDER_ERROR",
                verification.get("error", "فشل التحقق من معاملة App Store"),
                status_code=502,
            )

        existing = self.db.query(PaymentLog).filter(
            PaymentLog.provider == "apple_iap",
            PaymentLog.reference == transaction_id,
        ).first()
        if existing:
            if existing.status == "completed":
                user = self.db.query(User).filter(User.id == user.id).first()
                return self._payment_response(existing, user)
            raise AppException("DUPLICATE_REQUEST", "هذه المعاملة قيد المعالجة بالفعل", status_code=409)

        return self._credit_user(user, product, "apple_iap", transaction_id)

    async def _verify_google_payment(self, payment_token: str, expected_amount: float) -> Optional[dict]:
        if not self.settings.google_merchant_id:
            raise AppException("CONFIG_ERROR", "Google Pay غير مفعل", status_code=503)

        try:
            async with httpx.AsyncClient() as client:
                resp = await client.post(
                    "https://payments.googleapis.com/payments/s2s/v1/verify",
                    json={"paymentToken": payment_token, "merchantId": self.settings.google_merchant_id},
                    timeout=15,
                )
                if resp.status_code != 200:
                    logger.error(f"Google Pay verification failed: {resp.text}")
                    return None
                data = resp.json()
                if abs(float(data.get("amount", 0)) - expected_amount) > 0.01:
                    logger.error(f"Google Pay amount mismatch: {data.get('amount')} vs {expected_amount}")
                    return None
                return {"transaction_id": data.get("transactionId", str(uuid.uuid4())), "amount": float(data.get("amount", 0))}
        except Exception as e:
            logger.error(f"Google Pay API error: {e}")
            return None

    async def _verify_apple_payment(self, payment_token: str, expected_amount: float) -> Optional[dict]:
        if not self.settings.apple_merchant_id:
            raise AppException("CONFIG_ERROR", "Apple Pay غير مفعل", status_code=503)

        try:
            token = json.loads(payment_token)
            pd = token.get("paymentData", {})
            header = pd.get("header", {})
            version = pd.get("version", "")
            if version != "EC_v1":
                logger.error(f"Unsupported Apple Pay version: {version}")
                return None

            if not self.settings.apple_merchant_key_path or not self.settings.apple_merchant_cert_path:
                logger.error("Apple Pay merchant key or cert not configured")
                return None

            from cryptography.hazmat.primitives import serialization, hashes
            from cryptography.hazmat.primitives.asymmetric import ec
            from cryptography.hazmat.primitives.kdf.hkdf import HKDF
            from cryptography.hazmat.primitives.ciphers.aead import AESGCM

            with open(self.settings.apple_merchant_key_path, "rb") as f:
                merchant_key = serialization.load_pem_private_key(f.read(), password=None)

            epk_bytes = base64.b64decode(header["ephemeralPublicKey"])
            epk = ec.EllipticCurvePublicKey.from_encoded_point(ec.SECP256R1(), epk_bytes)
            shared = merchant_key.exchange(ec.ECDH(), epk)
            hkdf = HKDF(algorithm=hashes.SHA256(), length=16, salt=epk_bytes, info=b"Apple Pay")
            sym_key = hkdf.derive(shared)

            encrypted = base64.b64decode(pd["data"])
            nonce = encrypted[:12]
            ct = encrypted[12:]
            app_data = header.get("applicationData", "")
            aad = app_data.encode() if app_data else None
            aesgcm = AESGCM(sym_key)
            plaintext = aesgcm.decrypt(nonce, ct, aad)

            logger.info(f"Apple Pay token decrypted successfully")

            return {
                "transaction_id": token.get("transactionIdentifier", str(uuid.uuid4())),
                "amount": expected_amount,
            }
        except json.JSONDecodeError:
            logger.error("Apple Pay: invalid token JSON")
            return None
        except Exception as e:
            logger.error(f"Apple Pay verification failed: {e}")
            return None

    def _credit_user(self, user: User, product: PaymentProduct, provider: str, reference: Optional[str]) -> dict:
        self.db.execute(
            text("SELECT coins FROM users WHERE id = :uid FOR UPDATE"),
            {"uid": user.id},
        )
        self.db.refresh(user)
        lock_ref = reference or gen_uuid()
        lock_key = int(hashlib.sha256(f"payment_ref:{lock_ref}".encode()).hexdigest()[:16], 16) % (2**63)
        lock_result = self.db.execute(
            text("SELECT pg_try_advisory_xact_lock(:key)"),
            {"key": lock_key},
        ).scalar()
        if not lock_result:
            raise AppException("CONCURRENCY_ERROR", "الدفعة قيد المعالجة", status_code=429)

        existing = None
        if reference:
            existing = self.db.query(PaymentLog).filter(PaymentLog.reference == reference).first()
        if existing:
            if existing.status == "completed":
                return self._payment_response(existing, user)
            raise AppException("DUPLICATE_REQUEST", "الدفعة قيد المعالجة بالفعل", status_code=409)

        coins_before = user.coins
        user.coins += product.coins
        user.lifetime_coins += product.coins
        coins_after = user.coins

        log = PaymentLog(
            id=gen_uuid(),
            user_id=user.id,
            provider=provider,
            product_id=product.product_id,
            amount_usd=product.amount_usd,
            coins=product.coins,
            reference=reference or gen_uuid(),
            status="completed",
        )
        self.db.add(log)

        tx = Transaction(
            id=gen_uuid(),
            user_id=user.id,
            amount=product.coins,
            type="deposit",
            description=f"Deposit via {provider} ({product.product_id})",
            reference=reference,
            coins_before=coins_before,
            coins_after=coins_after,
        )
        self.db.add(tx)

        try:
            RevenueService.get_tax_configs(self.db)
            RevenueService.recognize_revenue(self.db, log.id)
            self.db.commit()
        except Exception:
            self.db.rollback()
            raise

        self.db.refresh(user)
        logger.info(f"Payment credited: user={user.id} provider={provider} coins={product.coins} ref={reference}")

        try:
            ws = WebhookService(self.db)
            asyncio.ensure_future(ws.dispatch_event("user.deposit", {
                "user_id": user.id,
                "amount": product.coins,
                "provider": provider,
                "reference": reference,
            }, user.id))
        except Exception as e:
            logger.warning(f"Webhook dispatch failed for deposit: {e}")

        return self._payment_response(log, user)

    def get_history(self, user_id: str, limit: int = 20, offset: int = 0) -> list[dict]:
        logs = self.db.query(PaymentLog).filter(
            PaymentLog.user_id == user_id,
        ).order_by(PaymentLog.created_at.desc()).offset(offset).limit(limit).all()
        return [
            {
                "id": log.id,
                "provider": log.provider,
                "product_id": log.product_id,
                "amount_usd": log.amount_usd,
                "coins": log.coins,
                "reference": log.reference,
                "status": log.status,
                "created_at": log.created_at.isoformat() if log.created_at else None,
            }
            for log in logs
        ]

    def refund(self, user: User, log_id: str) -> dict:
        self.db.execute(
            text("SELECT coins FROM users WHERE id = :uid FOR UPDATE"),
            {"uid": user.id},
        )
        self.db.refresh(user)
        log = self.db.query(PaymentLog).filter(
            PaymentLog.id == log_id,
            PaymentLog.user_id == user.id,
        ).with_for_update().first()
        if not log:
            raise AppException("NOT_FOUND", "سجل الدفع غير موجود", status_code=404)
        if log.status != "completed":
            raise AppException("VALIDATION_ERROR", "الدفعة مستردة بالفعل أو لم تكتمل", status_code=400)
        if user.coins < log.coins:
            raise AppException("INSUFFICIENT_BALANCE", "لا يمكن الاسترداد: الرصيد غير كافٍ", status_code=402)

        coins_before = user.coins
        user.coins -= log.coins
        log.status = "refunded"

        tx = Transaction(
            id=gen_uuid(),
            user_id=user.id,
            amount=-log.coins,
            type="refund",
            description=f"Refund for payment {log_id} via {log.provider}",
            reference=log.reference,
            coins_before=coins_before,
            coins_after=user.coins,
        )
        self.db.add(tx)
        self.db.commit()
        self.db.refresh(user)
        logger.info(f"Payment refunded: user={user.id} log={log_id} coins={log.coins}")
        return {"status": "refunded", "coins_refunded": log.coins, "new_balance": user.coins}

    def _payment_response(self, log: PaymentLog, user: User) -> dict:
        return {
            "status": "completed",
            "provider": log.provider,
            "amount_usd": log.amount_usd,
            "coins": log.coins,
            "reference": log.reference,
            "new_balance": user.coins,
        }
