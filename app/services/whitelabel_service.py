import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy.orm import Session

from app.domain.models import (
    EmailTemplateAnalytics,
    EmailTemplateVersion,
    WhitelabelBranding,
    WhitelabelDomain,
    WhitelabelEmailTemplate,
    gen_uuid,
)


class WhitelabelService:
    @staticmethod
    def add_domain(db: Session, user_id: str, domain: str) -> dict:
        existing = db.query(WhitelabelDomain).filter(WhitelabelDomain.domain == domain).first()
        if existing:
            return {"error": "النطاق موجود بالفعل"}
        token = uuid.uuid4().hex
        record = WhitelabelDomain(
            id=gen_uuid(),
            user_id=user_id,
            domain=domain,
            verification_token=token,
        )
        db.add(record)
        db.commit()
        db.refresh(record)
        return {
            "id": record.id,
            "domain": record.domain,
            "verification_token": token,
            "verification_record": f"_sms-active-verify={token}",
        }

    @staticmethod
    def verify_domain(db: Session, domain_id: str) -> Optional[dict]:
        record = db.query(WhitelabelDomain).filter(WhitelabelDomain.id == domain_id).first()
        if not record:
            return None
        record.verified = True
        record.is_active = True
        db.commit()
        return {"id": record.id, "domain": record.domain, "verified": True}

    @staticmethod
    def get_user_domains(db: Session, user_id: str) -> list[dict]:
        domains = db.query(WhitelabelDomain).filter(WhitelabelDomain.user_id == user_id).order_by(WhitelabelDomain.created_at.desc()).all()
        return [
            {
                "id": d.id,
                "domain": d.domain,
                "verified": d.verified,
                "ssl_status": d.ssl_status,
                "is_active": d.is_active,
                "created_at": d.created_at.isoformat(),
            }
            for d in domains
        ]

    @staticmethod
    def toggle_domain(db: Session, domain_id: str) -> Optional[dict]:
        record = db.query(WhitelabelDomain).filter(WhitelabelDomain.id == domain_id).first()
        if not record:
            return None
        record.is_active = not record.is_active
        db.commit()
        return {"id": record.id, "is_active": record.is_active}

    @staticmethod
    def get_branding(db: Session, user_id: str) -> Optional[dict]:
        branding = db.query(WhitelabelBranding).filter(WhitelabelBranding.user_id == user_id).first()
        if not branding:
            return None
        return {
            "company_name": branding.company_name,
            "logo_url": branding.logo_url,
            "favicon_url": branding.favicon_url,
            "primary_color": branding.primary_color,
            "secondary_color": branding.secondary_color,
            "accent_color": branding.accent_color,
            "support_email": branding.support_email,
            "support_phone": branding.support_phone,
            "website_url": branding.website_url,
            "custom_css": branding.custom_css,
            "custom_js": branding.custom_js,
            "terms_url": branding.terms_url,
            "privacy_url": branding.privacy_url,
        }

    @staticmethod
    def upsert_branding(db: Session, user_id: str, data: dict) -> dict:
        # C-3 FIX: إزالة custom_js منهاياً (تسبب Stored XSS)
        # وتنظيف custom_css من أي تعليقات حقنية محتملة
        import re
        branding = db.query(WhitelabelBranding).filter(WhitelabelBranding.user_id == user_id).first()
        if not branding:
            branding = WhitelabelBranding(user_id=user_id)
            db.add(branding)

        # custom_js محظور نهائياً — Stored XSS vector
        if "custom_js" in data:
            data.pop("custom_js")

        updatable = [
            "company_name", "logo_url", "favicon_url", "primary_color",
            "secondary_color", "accent_color", "support_email", "support_phone",
            "website_url", "custom_css", "terms_url", "privacy_url",
        ]
        for key in updatable:
            if key in data:
                value = data[key]
                # تنظيف custom_css: منع حقن الجافا سكريبت
                if key == "custom_css" and value:
                    if re.search(r"<\s*script|javascript\s*:", value, re.IGNORECASE):
                        continue  # تجاهل القيمة المشبوهة
                setattr(branding, key, value)

        db.commit()
        db.refresh(branding)
        return {
            "company_name": branding.company_name,
            "primary_color": branding.primary_color,
            "support_email": branding.support_email,
            "updated_at": branding.updated_at.isoformat(),
        }

    @staticmethod
    def get_email_templates(db: Session, user_id: str) -> list[dict]:
        templates = db.query(WhitelabelEmailTemplate).filter(
            WhitelabelEmailTemplate.user_id == user_id,
        ).order_by(WhitelabelEmailTemplate.template_name).all()
        return [
            {
                "id": t.id,
                "template_name": t.template_name,
                "subject": t.subject,
                "is_active": t.is_active,
                "version": t.version,
                "updated_at": t.updated_at.isoformat(),
            }
            for t in templates
        ]

    @staticmethod
    def get_email_template(db: Session, template_id: str) -> Optional[dict]:
        t = db.query(WhitelabelEmailTemplate).filter(WhitelabelEmailTemplate.id == template_id).first()
        if not t:
            return None
        versions = db.query(EmailTemplateVersion).filter(
            EmailTemplateVersion.template_id == template_id,
        ).order_by(EmailTemplateVersion.version_number.desc()).all()
        analytics = db.query(EmailTemplateAnalytics).filter(
            EmailTemplateAnalytics.template_id == template_id,
        ).first()
        return {
            "id": t.id,
            "template_name": t.template_name,
            "subject": t.subject,
            "html_content": t.html_content,
            "text_content": t.text_content,
            "is_active": t.is_active,
            "version": t.version,
            "created_at": t.created_at.isoformat(),
            "updated_at": t.updated_at.isoformat(),
            "versions": [
                {
                    "id": v.id,
                    "version_number": v.version_number,
                    "subject": v.subject,
                    "created_by": v.created_by,
                    "created_at": v.created_at.isoformat(),
                }
                for v in versions
            ],
            "analytics": {
                "sent_count": analytics.sent_count if analytics else 0,
                "delivered_count": analytics.delivered_count if analytics else 0,
                "opened_count": analytics.opened_count if analytics else 0,
                "clicked_count": analytics.clicked_count if analytics else 0,
                "bounced_count": analytics.bounced_count if analytics else 0,
            },
        }

    @staticmethod
    def upsert_email_template(db: Session, user_id: str, data: dict, changed_by: str) -> dict:
        template_name = data.get("template_name", "")
        existing = db.query(WhitelabelEmailTemplate).filter(
            WhitelabelEmailTemplate.user_id == user_id,
            WhitelabelEmailTemplate.template_name == template_name,
        ).first()

        if existing:
            old_version = existing.version
            existing.subject = data.get("subject", existing.subject)
            existing.html_content = data.get("html_content", existing.html_content)
            existing.text_content = data.get("text_content", existing.text_content)
            existing.version = old_version + 1
            db.add(EmailTemplateVersion(
                id=gen_uuid(),
                template_id=existing.id,
                version_number=old_version + 1,
                subject=existing.subject,
                html_content=existing.html_content,
                text_content=existing.text_content,
                created_by=changed_by,
            ))
            db.commit()
            db.refresh(existing)
            return {"id": existing.id, "version": existing.version, "message": "تم تحديث القالب"}

        template = WhitelabelEmailTemplate(
            id=gen_uuid(),
            user_id=user_id,
            template_name=template_name,
            subject=data["subject"],
            html_content=data["html_content"],
            text_content=data.get("text_content"),
            version=1,
        )
        db.add(template)
        db.flush()

        db.add(EmailTemplateVersion(
            id=gen_uuid(),
            template_id=template.id,
            version_number=1,
            subject=template.subject,
            html_content=template.html_content,
            text_content=template.text_content,
            created_by=changed_by,
        ))
        db.add(EmailTemplateAnalytics(template_id=template.id))
        db.commit()
        db.refresh(template)
        return {"id": template.id, "version": 1, "message": "تم إنشاء القالب"}

    @staticmethod
    def toggle_email_template(db: Session, template_id: str) -> Optional[dict]:
        t = db.query(WhitelabelEmailTemplate).filter(WhitelabelEmailTemplate.id == template_id).first()
        if not t:
            return None
        t.is_active = not t.is_active
        db.commit()
        return {"id": t.id, "is_active": t.is_active}

    @staticmethod
    def revert_template_version(db: Session, template_id: str, version_number: int) -> Optional[dict]:
        t = db.query(WhitelabelEmailTemplate).filter(WhitelabelEmailTemplate.id == template_id).first()
        if not t:
            return None
        version = db.query(EmailTemplateVersion).filter(
            EmailTemplateVersion.template_id == template_id,
            EmailTemplateVersion.version_number == version_number,
        ).first()
        if not version:
            return None
        t.subject = version.subject
        t.html_content = version.html_content
        t.text_content = version.text_content
        t.version = version_number
        db.commit()
        return {"id": t.id, "version": t.version, "message": "تم استعادة الإصدار"}

    @staticmethod
    def list_all_domains(db: Session, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        query = db.query(WhitelabelDomain)
        total = query.count()
        items = query.order_by(WhitelabelDomain.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": d.id,
                "user_id": d.user_id,
                "domain": d.domain,
                "verified": d.verified,
                "ssl_status": d.ssl_status,
                "is_active": d.is_active,
                "created_at": d.created_at.isoformat(),
            }
            for d in items
        ], total
