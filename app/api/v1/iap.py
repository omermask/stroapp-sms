import asyncio
import base64
import json

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.idempotency import IdempotencyService
from app.core.logging import get_logger
from app.core.response import success_response
from app.domain.models import AuditLog, PaymentLog, Transaction, User, gen_uuid
from app.services.audit_service import AuditService
from app.services.iap_receipt_validator import _get_apple_root_certs
from app.services.iap_service import IAPService, IAP_PRODUCTS
from app.services.webhook_service import WebhookService

logger = get_logger(__name__)

router = APIRouter(prefix="/user/iap", tags=["IAP"])
rtdn_router = APIRouter(prefix="/webhooks/google-play", tags=["GooglePlay-Webhooks"])


@router.get("/products")
async def list_products(
    request: Request,
    _user: User = Depends(get_current_user),
):
    products = []
    for pid, info in IAP_PRODUCTS.items():
        products.append({
            "product_id": pid,
            "coins": info["coins"],
            "amount_usd": info["usd"],
        })
    return success_response(
        {"provider": "google_play", "products": products},
        request_id=getattr(request.state, "request_id", ""),
    )


class GooglePlayVerifyRequest(BaseModel):
    product_id: str
    purchase_token: str


@router.post("/google-verify")
async def google_play_verify(
    body: GooglePlayVerifyRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    idempotency_key = request.headers.get("Idempotency-Key") or request.headers.get("x-idempotency-key")
    if idempotency_key:
        idem = IdempotencyService(db)
        cached = idem.get_response(idempotency_key)
        if cached:
            return success_response(cached, request_id=getattr(request.state, "request_id", ""))
        if not idem.check_and_set(idempotency_key):
            raise AppException("IDEMPOTENCY_ERROR", "تم استخدام هذا المفتاح مسبقاً", 409)

    ip = request.client.host if request.client else ""
    request_id_val = getattr(request.state, "request_id", "")
    svc = IAPService(db)
    result = await svc.process_google_receipt(
        current_user.id, body.product_id, body.purchase_token,
        ip=ip, request_id=request_id_val,
    )
    if not result.get("success"):
        raise AppException("VALIDATION_ERROR", result.get("error", "فشل التحقق"), status_code=400)

    AuditService.log(db, current_user.id, "iap.deposit", "payment", None,
                     {"provider": "google_play", "product_id": body.product_id,
                      "coins": result.get("coins"), "transaction_id": result.get("transaction_id")},
                     ip, request_id_val)
    if idempotency_key:
        idem.set_response(idempotency_key, result)
    return success_response(result, request_id=request_id_val)


class PubSubMessage(BaseModel):
    message: dict
    subscription: str


@rtdn_router.post("/rtdn")
async def google_play_rtdn(
    body: PubSubMessage,
    request: Request,
    db: Session = Depends(get_db),
    token: str = "",
):
    settings = get_settings()
    if settings.google_play_rtdn_token and token != settings.google_play_rtdn_token:
        logger.warning("RTDN request with invalid token")
        return {"error": "unauthorized"}

    try:
        raw_data = body.message.get("data", "")
        decoded = base64.b64decode(raw_data).decode("utf-8")
        notification = json.loads(decoded)
    except Exception as e:
        logger.error(f"Failed to decode RTDN message: {e}")
        return {"error": "invalid_message"}

    notif_type = notification.get("oneTimeProductNotification") or notification.get("subscriptionNotification")
    if not notif_type:
        logger.debug(f"Ignoring non-purchase RTDN: {list(notification.keys())}")
        return {"status": "ignored"}

    purchase_token = notif_type.get("purchaseToken")
    sku = notif_type.get("sku")
    notification_type = notif_type.get("notificationType")
    package_name = notification.get("packageName")

    if package_name and package_name != "com.stroapp.sms":
        logger.warning(f"RTDN for unknown package: {package_name}")
        return {"status": "ignored"}

    if notification_type == 2:
        log = db.query(PaymentLog).with_for_update().filter(
            PaymentLog.reference == purchase_token,
            PaymentLog.provider == "google_play",
            PaymentLog.status == "completed",
        ).first()
        if not log:
            logger.warning(f"RTDN refund: no completed PaymentLog for token={purchase_token}")
            return {"status": "not_found"}

        user = db.query(User).filter(User.id == log.user_id).with_for_update().first()
        if not user:
            return {"status": "error", "reason": "user_not_found"}

        coins_before = user.coins
        user.coins -= log.coins
        log.status = "refunded"
        tx = Transaction(
            id=gen_uuid(), user_id=user.id, amount=-log.coins,
            type="refund", description=f"Google Play refund ({sku})",
            reference=purchase_token,
            coins_before=coins_before, coins_after=user.coins,
        )
        db.add(tx)
        db.commit()

        AuditService.log(db, user.id, "iap.refund", "payment", log.id,
                        {"product_id": sku, "coins": log.coins, "purchase_token": purchase_token},
                        "", "")
        logger.info(f"RTDN refund processed: user={user.id} sku={sku} coins={log.coins}")

        try:
            ws = WebhookService(db)
            asyncio.ensure_future(ws.dispatch_event("user.deposit", {
                "user_id": user.id, "amount": -log.coins,
                "provider": "google_play", "reference": purchase_token,
            }, user.id))
        except Exception as e:
            logger.warning(f"RTDN webhook dispatch failed: {e}")

    return {"status": "ok"}


apple_webhook_router = APIRouter(prefix="/webhooks/apple", tags=["Apple-Webhooks"])


class AppStoreNotification(BaseModel):
    signedPayload: str


@apple_webhook_router.post("/notifications")
async def apple_store_notifications(
    body: AppStoreNotification,
    request: Request,
    db: Session = Depends(get_db),
):
    from appstoreserverlibrary.signed_data_verifier import SignedDataVerifier, VerificationException
    from appstoreserverlibrary.models.Environment import Environment as AppleEnv
    from appstoreserverlibrary.models.NotificationTypeV2 import NotificationTypeV2

    request_id_val = getattr(request.state, "request_id", "")
    settings = get_settings()
    bundle_id = settings.apple_bundle_id or "com.stroapp.sms"
    app_apple_id = settings.apple_app_apple_id

    last_error = None
    for env in [AppleEnv.SANDBOX, AppleEnv.PRODUCTION]:
        if env == AppleEnv.PRODUCTION and not app_apple_id:
            continue
        try:
            verifier = SignedDataVerifier(
                root_certificates=_get_apple_root_certs(),
                enable_online_checks=True,
                environment=env,
                bundle_id=bundle_id,
                app_apple_id=app_apple_id,
            )
            decoded = await asyncio.to_thread(
                verifier.verify_and_decode_notification,
                body.signedPayload,
            )
            last_error = None
            break
        except VerificationException as e:
            last_error = str(e)
            continue
        except Exception as e:
            last_error = str(e)
            continue

    if last_error:
        logger.warning(f"Apple notification verification failed: {last_error}")
        return {"status": "verification_failed"}

    notif_type = decoded.notificationType
    if notif_type == NotificationTypeV2.TEST:
        logger.info("Apple test notification received OK")
        return {"status": "ok"}

    if notif_type in (NotificationTypeV2.REFUND, NotificationTypeV2.REFUND_REVERSED):
        signed_txn = decoded.data.signedTransactionInfo if decoded.data else None
        if not signed_txn:
            return {"status": "ignored", "reason": "no_transaction_info"}

        try:
            verifier = SignedDataVerifier(
                root_certificates=_get_apple_root_certs(),
                enable_online_checks=True,
                environment=AppleEnv.PRODUCTION if decoded.data.environment == AppleEnv.PRODUCTION else AppleEnv.SANDBOX,
                bundle_id=bundle_id,
                app_apple_id=app_apple_id,
            )
            txn_decoded = await asyncio.to_thread(
                verifier.verify_and_decode_signed_transaction,
                signed_txn,
            )
        except Exception as e:
            logger.error(f"Failed to decode transaction in notification: {e}")
            return {"status": "verification_failed"}

        transaction_id = txn_decoded.transactionId
        log = db.query(PaymentLog).with_for_update().filter(
            PaymentLog.reference == transaction_id,
            PaymentLog.status == "completed",
        ).first()
        if not log:
            logger.warning(f"Apple refund: no completed PaymentLog for txn={transaction_id}")
            return {"status": "not_found"}

        user = db.query(User).filter(User.id == log.user_id).with_for_update().first()
        if not user:
            return {"status": "error", "reason": "user_not_found"}

        if notif_type == NotificationTypeV2.REFUND:
            coins_before = user.coins
            user.coins -= log.coins
            log.status = "refunded"
            tx = Transaction(
                id=gen_uuid(), user_id=user.id, amount=-log.coins,
                type="refund", description=f"Apple App Store refund ({txn_decoded.productId})",
                reference=transaction_id,
                coins_before=coins_before, coins_after=user.coins,
            )
            db.add(tx)
            db.commit()
            logger.info(f"Apple refund: user={user.id} product={txn_decoded.productId} coins={log.coins}")

            AuditService.log(db, user.id, "iap.refund", "payment", log.id,
                            {"product_id": txn_decoded.productId, "coins": log.coins,
                             "transaction_id": transaction_id, "source": "apple_notification"},
                            "", request_id_val)

            try:
                ws = WebhookService(db)
                asyncio.ensure_future(ws.dispatch_event("user.deposit", {
                    "user_id": user.id, "amount": -log.coins,
                    "provider": "apple_iap", "reference": transaction_id,
                }, user.id))
            except Exception as e:
                logger.warning(f"Apple refund webhook dispatch failed: {e}")

        elif notif_type == NotificationTypeV2.REFUND_REVERSED:
            if log.status == "refunded":
                user.coins += log.coins
                log.status = "completed"
                tx = Transaction(
                    id=gen_uuid(), user_id=user.id, amount=log.coins,
                    type="deposit", description=f"Apple refund reversal ({txn_decoded.productId})",
                    reference=transaction_id,
                    coins_before=max(user.coins - log.coins, 0), coins_after=user.coins,
                )
                db.add(tx)
                db.commit()
                logger.info(f"Apple refund reversed: user={user.id} product={txn_decoded.productId} coins={log.coins}")

    return {"status": "ok"}
