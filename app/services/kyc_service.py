import os
from datetime import date, datetime, timezone
from typing import Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.domain.models import (
    AMLScreening,
    KYCAuditLog,
    KYCDocument,
    KYCProfile,
    KYCSettings,
    KYCVerificationLimit,
    SMSOrder,
    User,
    gen_uuid,
)


class KYCService:
    SCREENING_KEYWORDS = {
        "sanctions": ["iran", "north korea", "syria", "cuba", "crimea"],
        "pep": ["minister", "president", "ambassador", "governor"],
        "adverse_media": ["fraud", "money laundering", "terrorism"],
    }

    @staticmethod
    def get_profile(db: Session, user_id: str) -> Optional[dict]:
        profile = db.query(KYCProfile).filter(KYCProfile.user_id == user_id).first()
        if not profile:
            return None
        return KYCService._profile_to_dict(profile)

    @staticmethod
    def submit_profile(db: Session, user_id: str, data: dict, ip_address: str = "") -> dict:
        profile = db.query(KYCProfile).filter(KYCProfile.user_id == user_id).first()
        if profile and profile.status in ("verified", "pending"):
            raise AppException("KYC_STATUS", f"ملف KYC حالته: {profile.status}")

        if not profile:
            profile = KYCProfile(user_id=user_id)
            db.add(profile)

        profile.full_name = data.get("full_name")
        profile.date_of_birth = data.get("date_of_birth")
        profile.nationality = data.get("nationality")
        profile.phone_number = data.get("phone_number")
        profile.address_line1 = data.get("address_line1")
        profile.address_line2 = data.get("address_line2")
        profile.city = data.get("city")
        profile.state = data.get("state")
        profile.postal_code = data.get("postal_code")
        profile.country = data.get("country")
        profile.status = "pending"
        profile.submitted_at = datetime.now(timezone.utc)

        KYCService._log_audit(db, user_id, "submitted", None, "pending", details=data, ip_address=ip_address)
        db.commit()
        db.refresh(profile)
        return KYCService._profile_to_dict(profile)

    @staticmethod
    def update_profile(db: Session, user_id: str, data: dict) -> Optional[dict]:
        profile = db.query(KYCProfile).filter(KYCProfile.user_id == user_id).first()
        if not profile:
            return None
        if profile.status == "verified":
            raise AppException("KYC_VERIFIED", "لا يمكن تعديل ملف KYC بعد اعتماده")

        updatable = ["full_name", "date_of_birth", "nationality", "phone_number",
                     "address_line1", "address_line2", "city", "state", "postal_code", "country"]
        for key in updatable:
            if key in data:
                setattr(profile, key, data[key])

        if profile.status in ("rejected", "suspended"):
            profile.status = "pending"
            profile.submitted_at = datetime.now(timezone.utc)

        db.commit()
        db.refresh(profile)
        return KYCService._profile_to_dict(profile)

    @staticmethod
    def verify_profile(db: Session, profile_id: str, admin_id: str, level: str = "basic") -> Optional[dict]:
        profile = db.query(KYCProfile).filter(KYCProfile.id == profile_id).first()
        if not profile:
            return None

        old_status = profile.status
        profile.status = "verified"
        profile.verification_level = level
        profile.verified_at = datetime.now(timezone.utc)
        profile.verified_by = admin_id

        KYCService._log_audit(db, profile.user_id, "verified", old_status, "verified",
                              details={"level": level, "admin_id": admin_id}, admin_id=admin_id)
        db.commit()
        return KYCService._profile_to_dict(profile)

    @staticmethod
    def reject_profile(db: Session, profile_id: str, admin_id: str, reason: str = "") -> Optional[dict]:
        profile = db.query(KYCProfile).filter(KYCProfile.id == profile_id).first()
        if not profile:
            return None

        old_status = profile.status
        profile.status = "rejected"
        profile.notes = reason

        KYCService._log_audit(db, profile.user_id, "rejected", old_status, "rejected",
                              details={"reason": reason}, admin_id=admin_id, reason=reason)
        db.commit()
        return KYCService._profile_to_dict(profile)

    @staticmethod
    def suspend_profile(db: Session, profile_id: str, admin_id: str, reason: str = "") -> Optional[dict]:
        profile = db.query(KYCProfile).filter(KYCProfile.id == profile_id).first()
        if not profile:
            return None

        old_status = profile.status
        profile.status = "suspended"
        profile.notes = reason

        KYCService._log_audit(db, profile.user_id, "suspended", old_status, "suspended",
                              details={"reason": reason}, admin_id=admin_id, reason=reason)
        db.commit()
        return KYCService._profile_to_dict(profile)

    @staticmethod
    def run_aml_screening(db: Session, profile_id: str) -> dict:
        profile = db.query(KYCProfile).filter(KYCProfile.id == profile_id).first()
        if not profile:
            raise AppException("NOT_FOUND", "ملف KYC غير موجود", 404)

        score = 0
        matches = []
        full_text = f"{profile.full_name or ''} {profile.nationality or ''} {profile.country or ''}".lower()

        for category, keywords in KYCService.SCREENING_KEYWORDS.items():
            for kw in keywords:
                if kw in full_text:
                    score += 15
                    matches.append({"category": category, "term": kw, "severity": "medium"})

        screening = AMLScreening(
            id=gen_uuid(),
            kyc_profile_id=profile.id,
            screening_type="initial",
            status="completed",
            match_score=score,
            matches_found=matches,
            search_terms={"name": profile.full_name, "nationality": profile.nationality},
        )
        db.add(screening)

        if score > 50:
            profile.aml_status = "failed"
            profile.risk_score = min(100, (profile.risk_score or 0) + score)
        elif score > 20:
            profile.aml_status = "pending_review"
        else:
            profile.aml_status = "passed"

        db.commit()
        return {
            "match_score": score,
            "matches_found": matches,
            "status": screening.status,
            "aml_status": profile.aml_status,
        }

    @staticmethod
    def get_limits(db: Session, user_id: str) -> dict:
        profile = db.query(KYCProfile).filter(KYCProfile.user_id == user_id).first()
        level = profile.verification_level if profile and profile.status == "verified" else "unverified"

        limits = db.query(KYCVerificationLimit).filter(
            KYCVerificationLimit.verification_level == level
        ).first()

        today = date.today()
        month_start = today.replace(day=1)

        today_total = db.query(func.coalesce(func.sum(SMSOrder.cost_coins), 0)).filter(
            SMSOrder.user_id == user_id,
            func.date(SMSOrder.created_at) == today,
        ).scalar() or 0

        month_total = db.query(func.coalesce(func.sum(SMSOrder.cost_coins), 0)).filter(
            SMSOrder.user_id == user_id,
            func.date(SMSOrder.created_at) >= month_start,
        ).scalar() or 0

        return {
            "verification_level": level,
            "limits": {
                "daily_limit_coins": limits.daily_limit_coins if limits else 1000,
                "monthly_limit_coins": limits.monthly_limit_coins if limits else 10000,
                "max_single_transaction": limits.max_single_transaction if limits else 500,
            },
            "usage": {
                "today_used": today_total,
                "month_used": month_total,
            },
        }

    @staticmethod
    def check_limits(db: Session, user_id: str, amount_coins: float) -> bool:
        profile = db.query(KYCProfile).filter(KYCProfile.user_id == user_id).first()
        level = profile.verification_level if profile and profile.status == "verified" else "unverified"

        limits = db.query(KYCVerificationLimit).filter(
            KYCVerificationLimit.verification_level == level
        ).first()
        if not limits:
            return True

        today = date.today()
        month_start = today.replace(day=1)

        today_total = db.query(func.coalesce(func.sum(SMSOrder.cost_coins), 0)).filter(
            SMSOrder.user_id == user_id,
            func.date(SMSOrder.created_at) == today,
        ).scalar() or 0

        month_total = db.query(func.coalesce(func.sum(SMSOrder.cost_coins), 0)).filter(
            SMSOrder.user_id == user_id,
            func.date(SMSOrder.created_at) >= month_start,
        ).scalar() or 0

        if (today_total + amount_coins) > limits.daily_limit_coins:
            raise AppException("KYC_DAILY_LIMIT", "تجاوزت الحد اليومي المسموح")
        if (month_total + amount_coins) > limits.monthly_limit_coins:
            raise AppException("KYC_MONTHLY_LIMIT", "تجاوزت الحد الشهري المسموح")
        return True

    @staticmethod
    def get_pending(db: Session, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(KYCProfile).filter(KYCProfile.status == "pending")
        total = query.count()
        items = query.order_by(KYCProfile.submitted_at.asc()).offset((page - 1) * per_page).limit(per_page).all()
        return [KYCService._profile_to_dict(p) for p in items], total

    @staticmethod
    def get_all(db: Session, status: Optional[str] = None, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(KYCProfile)
        if status:
            query = query.filter(KYCProfile.status == status)
        total = query.count()
        items = query.order_by(KYCProfile.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
        return [KYCService._profile_to_dict(p) for p in items], total

    @staticmethod
    def get_profile_by_id(db: Session, profile_id: str) -> Optional[dict]:
        profile = db.query(KYCProfile).filter(KYCProfile.id == profile_id).first()
        if not profile:
            return None
        result = KYCService._profile_to_dict(profile)
        documents = db.query(KYCDocument).filter(KYCDocument.kyc_profile_id == profile_id).all()
        result["documents"] = [
            {
                "id": d.id,
                "document_type": d.document_type,
                "verification_status": d.verification_status,
                "confidence_score": d.confidence_score,
                "rejection_reason": d.rejection_reason,
                "created_at": d.created_at.isoformat(),
            }
            for d in documents
        ]
        screenings = db.query(AMLScreening).filter(AMLScreening.kyc_profile_id == profile_id).order_by(AMLScreening.created_at.desc()).all()
        result["aml_screenings"] = [
            {
                "id": s.id,
                "screening_type": s.screening_type,
                "status": s.status,
                "match_score": s.match_score,
                "matches_found": s.matches_found,
            }
            for s in screenings
        ]
        return result

    @staticmethod
    def get_documents(db: Session, profile_id: str) -> list[dict]:
        docs = db.query(KYCDocument).filter(KYCDocument.kyc_profile_id == profile_id).all()
        return [
            {
                "id": d.id,
                "document_type": d.document_type,
                "file_path": d.file_path,
                "verification_status": d.verification_status,
                "confidence_score": d.confidence_score,
                "rejection_reason": d.rejection_reason,
                "created_at": d.created_at.isoformat(),
            }
            for d in docs
        ]

    @staticmethod
    def upload_document(db: Session, user_id: str, document_type: str, file_path: str, file_hash: str) -> dict:
        profile = db.query(KYCProfile).filter(KYCProfile.user_id == user_id).first()
        if not profile:
            raise AppException("NOT_FOUND", "يجب إنشاء ملف KYC أولاً", 404)

        valid_types = {"passport", "national_id", "drivers_license", "proof_of_address", "selfie"}
        if document_type not in valid_types:
            raise AppException("VALIDATION_ERROR", f"نوع المستند غير صالح. الأنواع المسموحة: {', '.join(valid_types)}", 400)

        allowed_exts = {".jpg", ".jpeg", ".png", ".pdf", ".tiff", ".tif"}
        ext = os.path.splitext(file_path)[1].lower()
        if ext not in allowed_exts:
            raise AppException("VALIDATION_ERROR", "امتداد الملف غير مسموح. استخدم: JPG, PNG, PDF", 400)

        normalized = os.path.normpath(file_path)
        if normalized.startswith(("/", "..")):
            raise AppException("VALIDATION_ERROR", "مسار الملف غير صالح", 400)

        if not file_hash or len(file_hash) < 32:
            raise AppException("VALIDATION_ERROR", "تجزئة الملف غير صالحة", 400)

        doc = KYCDocument(
            id=gen_uuid(),
            kyc_profile_id=profile.id,
            document_type=document_type,
            file_path=file_path,
            file_hash=file_hash,
        )
        db.add(doc)

        KYCService._log_audit(db, user_id, "document_uploaded", None, None,
                              details={"document_type": document_type, "file_hash": file_hash})
        db.commit()
        db.refresh(doc)
        return {"id": doc.id, "document_type": doc.document_type, "verification_status": doc.verification_status}

    @staticmethod
    def get_audit_logs(db: Session, profile_id: str, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        profile = db.query(KYCProfile).filter(KYCProfile.id == profile_id).first()
        if not profile:
            return [], 0
        query = db.query(KYCAuditLog).filter(KYCAuditLog.user_id == profile.user_id)
        total = query.count()
        items = query.order_by(KYCAuditLog.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": log.id,
                "action": log.action,
                "old_status": log.old_status,
                "new_status": log.new_status,
                "admin_id": log.admin_id,
                "reason": log.reason,
                "details": log.details,
                "ip_address": log.ip_address,
                "created_at": log.created_at.isoformat(),
            }
            for log in items
        ], total

    @staticmethod
    def get_stats(db: Session) -> dict:
        total = db.query(func.count(KYCProfile.id)).scalar() or 0
        pending = db.query(func.count(KYCProfile.id)).filter(KYCProfile.status == "pending").scalar() or 0
        verified = db.query(func.count(KYCProfile.id)).filter(KYCProfile.status == "verified").scalar() or 0
        rejected = db.query(func.count(KYCProfile.id)).filter(KYCProfile.status == "rejected").scalar() or 0
        aml_failed = db.query(func.count(KYCProfile.id)).filter(KYCProfile.aml_status == "failed").scalar() or 0

        return {
            "total": total,
            "pending": pending,
            "verified": verified,
            "rejected": rejected,
            "aml_failed": aml_failed,
            "completion_rate": round((verified / total * 100) if total > 0 else 0, 2),
        }

    @staticmethod
    def get_settings(db: Session) -> list[dict]:
        settings = db.query(KYCSettings).all()
        return [
            {"setting_key": s.setting_key, "setting_value": s.setting_value, "is_active": s.is_active}
            for s in settings
        ]

    @staticmethod
    def update_setting(db: Session, key: str, value: dict) -> dict:
        setting = db.query(KYCSettings).filter(KYCSettings.setting_key == key).first()
        if not setting:
            setting = KYCSettings(setting_key=key, setting_value=value)
            db.add(setting)
        else:
            setting.setting_value = value
        db.commit()
        return {"setting_key": key, "setting_value": value}

    @staticmethod
    def get_all_limits(db: Session) -> list[dict]:
        limits = db.query(KYCVerificationLimit).order_by(KYCVerificationLimit.verification_level).all()
        return [
            {
                "verification_level": l.verification_level,
                "daily_limit_coins": l.daily_limit_coins,
                "monthly_limit_coins": l.monthly_limit_coins,
                "annual_limit_coins": l.annual_limit_coins,
                "max_single_transaction": l.max_single_transaction,
                "allowed_services": l.allowed_services,
                "country_restrictions": l.country_restrictions,
            }
            for l in limits
        ]

    @staticmethod
    def update_limit(db: Session, level: str, data: dict) -> dict:
        limit = db.query(KYCVerificationLimit).filter(KYCVerificationLimit.verification_level == level).first()
        updatable = ["daily_limit_coins", "monthly_limit_coins", "annual_limit_coins",
                     "max_single_transaction", "allowed_services", "country_restrictions"]
        if not limit:
            limit = KYCVerificationLimit(verification_level=level)
            db.add(limit)
        for key in updatable:
            if key in data:
                setattr(limit, key, data[key])
        db.commit()
        result = {"verification_level": level}
        for key in updatable:
            result[key] = getattr(limit, key)
        return result

    @staticmethod
    def _profile_to_dict(profile: KYCProfile) -> dict:
        user = None
        return {
            "id": profile.id,
            "user_id": profile.user_id,
            "status": profile.status,
            "verification_level": profile.verification_level,
            "full_name": profile.full_name,
            "date_of_birth": profile.date_of_birth.isoformat() if profile.date_of_birth else None,
            "nationality": profile.nationality,
            "phone_number": profile.phone_number,
            "address_line1": profile.address_line1,
            "city": profile.city,
            "country": profile.country,
            "risk_score": profile.risk_score,
            "aml_status": profile.aml_status,
            "notes": profile.notes,
            "submitted_at": profile.submitted_at.isoformat() if profile.submitted_at else None,
            "verified_at": profile.verified_at.isoformat() if profile.verified_at else None,
            "created_at": profile.created_at.isoformat(),
        }

    @staticmethod
    def _log_audit(db: Session, user_id: str, action: str, old_status: Optional[str],
                   new_status: Optional[str], admin_id: str = "", reason: str = "",
                   details: Optional[dict] = None, ip_address: str = ""):
        log = KYCAuditLog(
            id=gen_uuid(),
            user_id=user_id,
            action=action,
            old_status=old_status,
            new_status=new_status,
            admin_id=admin_id or None,
            reason=reason or None,
            details=details or {},
            ip_address=ip_address or None,
        )
        db.add(log)
