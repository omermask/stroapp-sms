from datetime import datetime, timezone, timedelta

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.domain.models import SMSOrder, User, AuditLog, BlacklistedIP, DeviceFingerprint
from app.services.blacklist_service import BlacklistService


class FraudDetectionService:
    MAX_ORDERS_PER_HOUR = 20
    MAX_FAILED_LOGINS_PER_HOUR = 10
    MAX_ACCOUNTS_PER_IP = 5
    MAX_CHARGEBACKS_PER_MONTH = 3

    @staticmethod
    def check_purchase_fraud(db: Session, user_id: str, ip_address: str,
                             device_fingerprint: str = "") -> dict:
        flags = []
        risk_score = 0

        now = datetime.now(timezone.utc)
        one_hour_ago = now - timedelta(hours=1)

        orders_last_hour = db.query(func.count(SMSOrder.id)).filter(
            SMSOrder.user_id == user_id,
            SMSOrder.created_at >= one_hour_ago,
        ).scalar() or 0

        if orders_last_hour > FraudDetectionService.MAX_ORDERS_PER_HOUR:
            flags.append("high_order_velocity")
            risk_score += 30

        distinct_users = db.query(func.count(func.distinct(SMSOrder.user_id))).filter(
            SMSOrder.created_at >= one_hour_ago,
        ).scalar() or 0

        if distinct_users > FraudDetectionService.MAX_ACCOUNTS_PER_IP:
            flags.append("high_user_velocity")
            risk_score += 25

        if device_fingerprint:
            fp_devices = db.query(func.count(DeviceFingerprint.id)).filter(
                DeviceFingerprint.fingerprint_hash == device_fingerprint,
                DeviceFingerprint.first_seen_at >= one_hour_ago,
            ).scalar() or 0
            if fp_devices > 3:
                flags.append("device_fingerprint_abuse")
                risk_score += 20

        is_blocked = BlacklistService.is_ip_blacklisted(db, ip_address)
        if is_blocked:
            flags.append("ip_blacklisted")
            risk_score = 100

        return {
            "risk_score": min(risk_score, 100),
            "flags": flags,
            "is_high_risk": risk_score >= 50,
            "is_blocked": is_blocked,
        }

    @staticmethod
    def check_login_fraud(db: Session, ip_address: str, user_id: str = "") -> dict:
        now = datetime.now(timezone.utc)
        one_hour_ago = now - timedelta(hours=1)

        failed_logins = db.query(func.count(AuditLog.id)).filter(
            AuditLog.action == "user.login_failed",
            AuditLog.ip_address == ip_address,
            AuditLog.created_at >= one_hour_ago,
        ).scalar() or 0

        flags = []
        risk_score = 0

        if failed_logins > FraudDetectionService.MAX_FAILED_LOGINS_PER_HOUR:
            flags.append("brute_force_attempt")
            risk_score += 40

        if failed_logins > FraudDetectionService.MAX_FAILED_LOGINS_PER_HOUR * 2:
            BlacklistService.blacklist_ip(db, ip_address, "Brute force detected", "system", 24)
            flags.append("auto_blacklisted")
            risk_score = 100

        return {"risk_score": min(risk_score, 100), "flags": flags,
                "is_high_risk": risk_score >= 50}
