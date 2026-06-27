import asyncio
import base64
import os
from datetime import datetime, timezone
from functools import lru_cache
from pathlib import Path
from typing import Optional

import httpx

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)

APPLE_PRODUCTION = "https://buy.itunes.apple.com/verifyReceipt"
APPLE_SANDBOX = "https://sandbox.itunes.apple.com/verifyReceipt"


class _CircuitBreaker:
    def __init__(self, threshold: int = 5, reset_seconds: int = 60):
        self._failures = 0
        self._threshold = threshold
        self._reset_seconds = reset_seconds
        self._open_until = 0.0

    def __call__(self) -> bool:
        import time
        now = time.time()
        if now < self._open_until:
            return False
        return True

    def record_failure(self):
        import time
        self._failures += 1
        if self._failures >= self._threshold:
            self._open_until = time.time() + self._reset_seconds
            logger.warning(f"Apple API circuit breaker opened for {self._reset_seconds}s")

    def record_success(self):
        self._failures = 0
        self._open_until = 0.0


_apple_circuit_breaker = _CircuitBreaker()

PACKAGE_NAME = "com.stroapp.sms"


def _resolve_path(path: str) -> str:
    if os.path.isabs(path):
        return path
    return str(Path(__file__).resolve().parent.parent.parent / path)


def _build_androidpublisher_service():
    from google.oauth2 import service_account
    from googleapiclient.discovery import build

    settings = get_settings()
    raw = settings.google_play_service_account_path
    if not raw:
        raise RuntimeError("google_play_service_account_path is not configured")

    path = _resolve_path(raw)
    SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]
    creds = service_account.Credentials.from_service_account_file(path, scopes=SCOPES)
    return build("androidpublisher", "v3", credentials=creds)


async def _run_google_api(call):
    return await asyncio.to_thread(call.execute)


async def verify_apple_receipt(receipt_data: str, is_sandbox: bool = False) -> dict:
    settings = get_settings()
    url = APPLE_SANDBOX if is_sandbox else APPLE_PRODUCTION
    payload = {
        "receipt-data": receipt_data,
        "password": settings.apple_shared_secret or "",
        "exclude-old-transactions": True,
    }
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.post(url, json=payload)
            result = resp.json()
            status = result.get("status")
            if status == 21007 and not is_sandbox:
                return await verify_apple_receipt(receipt_data, is_sandbox=True)
            if status == 0:
                receipt = result.get("receipt", {})
                in_app = receipt.get("in_app", [])
                latest = in_app[-1] if in_app else {}
                return {
                    "valid": True,
                    "product_id": latest.get("product_id"),
                    "transaction_id": latest.get("transaction_id"),
                    "original_transaction_id": latest.get("original_transaction_id"),
                    "purchase_date": latest.get("purchase_date"),
                    "expires_date": latest.get("expires_date"),
                    "quantity": int(latest.get("quantity", 1)),
                    "environment": "Sandbox" if is_sandbox else "Production",
                }
            error_map = {21000: "إيصال غير صالح", 21002: "البيانات تالفة",
                         21003: "الإيصال غير مصرح به", 21004: "مفتاح سري غير متطابق",
                         21005: "انتهت صلاحية الخادم", 21006: "الإيصال منتهي",
                         21010: "تم رفض الوصول"}
            return {"valid": False, "error": error_map.get(status, f"خطأ غير معروف ({status})")}
    except Exception as e:
        logger.error(f"Apple receipt verification failed: {e}")
        return {"valid": False, "error": str(e)}


async def verify_google_play_receipt(product_id: str, purchase_token: str, package_name: str = None) -> dict:
    pkg = package_name or PACKAGE_NAME
    try:
        service = await asyncio.to_thread(_build_androidpublisher_service)
        call = service.purchases().products().get(
            packageName=pkg, productId=product_id, token=purchase_token
        )
        purchase = await _run_google_api(call)
        return {
            "valid": purchase.get("purchaseState") == 0,
            "product_id": product_id,
            "order_id": purchase.get("orderId"),
            "purchase_time": purchase.get("purchaseTimeMillis"),
            "consumption_state": purchase.get("consumptionState"),
            "acknowledgement_state": purchase.get("acknowledgementState"),
            "developer_payload": purchase.get("developerPayload"),
            "purchase_token": purchase_token,
            "quantity": purchase.get("quantity", 1),
        }
    except Exception as e:
        logger.error(f"Google Play receipt verification failed: {e}")
        return {"valid": False, "error": str(e)}


async def acknowledge_google_play_purchase(product_id: str, purchase_token: str, package_name: str = None,
                                            developer_payload: str = "") -> bool:
    pkg = package_name or PACKAGE_NAME
    try:
        service = await asyncio.to_thread(_build_androidpublisher_service)
        call = service.purchases().products().acknowledge(
            packageName=pkg, productId=product_id, token=purchase_token,
            body={"developerPayload": developer_payload},
        )
        await _run_google_api(call)
        return True
    except Exception as e:
        logger.error(f"Google Play acknowledge failed: {e}")
        return False


async def consume_google_play_purchase(product_id: str, purchase_token: str, package_name: str = None) -> dict:
    pkg = package_name or PACKAGE_NAME
    try:
        service = await asyncio.to_thread(_build_androidpublisher_service)
        call = service.purchases().products().consume(
            packageName=pkg, productId=product_id, token=purchase_token,
        )
        await _run_google_api(call)
        return {"success": True}
    except Exception as e:
        try:
            from googleapiclient.errors import HttpError
            if isinstance(e, HttpError) and e.resp.status == 400:
                logger.info(f"Google Play purchase already consumed: {purchase_token}")
                return {"success": True, "already_consumed": True}
        except (ImportError, AttributeError):
            error_str = str(e).lower()
            if "already" in error_str and "consum" in error_str:
                logger.info(f"Google Play purchase already consumed: {purchase_token}")
                return {"success": True, "already_consumed": True}
        logger.error(f"Google Play consume failed: {e}")
        return {"success": False, "error": str(e)}


async def verify_iap_receipt(provider: str, receipt_data: str, product_id: str = None) -> dict:
    if provider == "apple":
        return await verify_apple_receipt(receipt_data)
    elif provider == "google":
        return await verify_google_play_receipt(product_id or "", receipt_data)
    return {"valid": False, "error": f"مزود الدفع غير معروف: {provider}"}


APPLE_ROOT_CA_G3_BASE64 = "MIICQzCCAcmgAwIBAgIILcX8iNLFS5UwCgYIKoZIzj0EAwMwZzEbMBkGA1UEAwwSQXBwbGUgUm9vdCBDQSAtIEczMSYwJAYDVQQLDB1BcHBsZSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwHhcNMTQwNDMwMTgxOTA2WhcNMzkwNDMwMTgxOTA2WjBnMRswGQYDVQQDDBJBcHBsZSBSb290IENBIC0gRzMxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzB2MBAGByqGSM49AgEGBSuBBAAiA2IABJjpLz1AcqTtkyJygRMc3RCV8cWjTnHcFBbZDuWmBSp3ZHtfTjjTuxxEtX/1H7YyYl3J6YRbTzBPEVoA/VhYDKX1DyxNB0cTddqXl5dvMVztK517IDvYuVTZXpmkOlEKMaNCMEAwHQYDVR0OBBYEFLuw3qFYM4iapIqZ3r6966/ayySrMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMAoGCCqGSM49BAMDA2gAMGUCMQCD6cHEFl4aXTQY2e3v9GwOAEZLuN+yRhHFD/3meoyhpmvOwgPUnPWTxnS4at+qIxUCMG1mihDK1A3UT82NQz60imOlM27jbdoXt2QfyFMm+YhidDkLF1vLUagM6BgD56KyKA=="


def _get_apple_root_certs() -> list[bytes]:
    return [base64.b64decode(APPLE_ROOT_CA_G3_BASE64)]


@lru_cache(maxsize=1)
def _load_signing_key(key_path: str) -> bytes:
    with open(key_path, "rb") as f:
        return f.read()


async def verify_apple_transaction_v2(
    transaction_id: str,
    product_id: str,
    environment: Optional[str] = None,
) -> dict:
    if not _apple_circuit_breaker():
        return {"valid": False, "error": "خدمة Apple غير متاحة حالياً - حاول لاحقاً"}

    from appstoreserverlibrary.api_client import AppStoreServerAPIClient
    from appstoreserverlibrary.signed_data_verifier import SignedDataVerifier
    from appstoreserverlibrary.models.Environment import Environment as AppleEnv

    settings = get_settings()
    signing_key_path = _resolve_path(settings.apple_private_key) if settings.apple_private_key else ""

    if not signing_key_path or not settings.apple_key_id or not settings.apple_issuer_id:
        return {"valid": False, "error": "Apple Server API غير مهيأ - تأكد من key_id, issuer_id, ومسار المفتاح"}

    if not os.path.exists(signing_key_path):
        return {"valid": False, "error": f"ملف المفتاح الخاص غير موجود: {signing_key_path}"}

    signing_key = _load_signing_key(signing_key_path)
    bundle_id = settings.apple_bundle_id or "com.stroapp.sms"
    app_apple_id = settings.apple_app_apple_id

    environments_to_try = []
    if environment:
        env = AppleEnv.PRODUCTION if environment.lower() == "production" else AppleEnv.SANDBOX
        environments_to_try.append(env)
    else:
        environments_to_try = [AppleEnv.SANDBOX]
        if app_apple_id:
            environments_to_try.append(AppleEnv.PRODUCTION)

    last_error = None
    for env in environments_to_try:
        try:
            client = AppStoreServerAPIClient(
                signing_key=signing_key,
                key_id=settings.apple_key_id,
                issuer_id=settings.apple_issuer_id,
                bundle_id=bundle_id,
                environment=env,
            )
            response = await asyncio.to_thread(
                client.get_transaction_info,
                transaction_id,
            )
            signed_transaction = getattr(response, "signedTransactionInfo", None)
            if not signed_transaction:
                continue

            verifier = SignedDataVerifier(
                root_certificates=_get_apple_root_certs(),
                enable_online_checks=True,
                environment=env,
                bundle_id=bundle_id,
                app_apple_id=app_apple_id,
            )
            decoded = await asyncio.to_thread(
                verifier.verify_and_decode_signed_transaction,
                signed_transaction,
            )

            if decoded.productId != product_id:
                return {"valid": False, "error": "معرّف المنتج في المعاملة لا يتطابق مع المعرف المطلوب"}

            if decoded.revocationDate is not None:
                return {"valid": False, "error": "تم استرداد قيمة هذه المعاملة (مردودة)"}

            env_label = "Sandbox" if env == AppleEnv.SANDBOX else "Production"
            _apple_circuit_breaker.record_success()
            return {
                "valid": True,
                "product_id": decoded.productId,
                "transaction_id": decoded.transactionId,
                "original_transaction_id": decoded.originalTransactionId,
                "purchase_date": decoded.purchaseDate,
                "expires_date": decoded.expiresDate,
                "quantity": decoded.quantity or 1,
                "environment": env_label,
                "bundle_id": decoded.bundleId,
            }
        except Exception as e:
            last_error = str(e)
            logger.debug(f"Apple transaction verification failed for {env.name}: {e}")
            continue

    _apple_circuit_breaker.record_failure()
    return {"valid": False, "error": f"فشل التحقق من المعاملة: {last_error}"}
