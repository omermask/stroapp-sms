from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.domain.models import EmailTemplate, gen_uuid

DEFAULT_TEMPLATES = {
    "welcome": {
        "subject": "مرحباً بك في StroApp SMS",
        "html": """<!DOCTYPE html><html dir="rtl"><body style="font-family: Arial; background: #0f172a; color: #e2e8f0; padding: 40px;">
<div style="max-width: 600px; margin: auto; background: #1e293b; border-radius: 12px; padding: 32px;">
<h1 style="color: #3b82f6; text-align: center;">مرحباً بك {{name}}</h1>
<p>شكراً لانضمامك إلى StroApp SMS! يمكنك الآن البدء في استخدام خدمات التحقق عبر الرسائل النصية.</p>
<p>رصيدك الحالي: <strong>{{coins}} كوين</strong></p>
<div style="text-align: center; margin: 24px 0;">
<a href="{{base_url}}" style="background: #3b82f6; color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none;">ابدأ الآن</a>
</div>
<p style="color: #94a3b8; font-size: 12px; text-align: center;">© {{year}} StroApp SMS</p>
</div></body></html>""",
    },
    "password_reset": {
        "subject": "إعادة تعيين كلمة المرور",
        "html": """<!DOCTYPE html><html dir="rtl"><body style="font-family: Arial; background: #0f172a; color: #e2e8f0; padding: 40px;">
<div style="max-width: 600px; margin: auto; background: #1e293b; border-radius: 12px; padding: 32px;">
<h1 style="color: #3b82f6; text-align: center;">إعادة تعيين كلمة المرور</h1>
<p>لقد تلقينا طلباً لإعادة تعيين كلمة المرور الخاصة بحسابك.</p>
<div style="text-align: center; margin: 24px 0;">
<a href="{{reset_url}}" style="background: #3b82f6; color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none;">إعادة تعيين كلمة المرور</a>
</div>
<p>إذا لم تطلب هذا، يمكنك تجاهل هذا البريد الإلكتروني.</p>
<p style="color: #94a3b8; font-size: 12px; text-align: center;">© {{year}} StroApp SMS</p>
</div></body></html>""",
    },
    "verification_code": {
        "subject": "رمز التحقق الخاص بك",
        "html": """<!DOCTYPE html><html dir="rtl"><body style="font-family: Arial; background: #0f172a; color: #e2e8f0; padding: 40px;">
<div style="max-width: 600px; margin: auto; background: #1e293b; border-radius: 12px; padding: 32px; text-align: center;">
<h1 style="color: #3b82f6;">رمز التحقق</h1>
<div style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #22d3ee; margin: 24px 0;">{{code}}</div>
<p>الخدمة: {{service}}</p>
<p style="color: #94a3b8; font-size: 12px;">{{year}} StroApp SMS</p>
</div></body></html>""",
    },
}


class EmailTemplateService:
    _jinja_env = None

    @classmethod
    def _get_env(cls):
        if cls._jinja_env is None:
            import jinja2
            cls._jinja_env = jinja2.Environment(autoescape=jinja2.select_autoescape(default_for_string=True, enabled_extensions=("html", "htm")))
        return cls._jinja_env

    @staticmethod
    def get_template(db: Session, name: str) -> dict:
        record = db.query(EmailTemplate).filter(
            EmailTemplate.name == name,
            EmailTemplate.is_active == True,
        ).first()
        if record:
            return {"subject": record.subject, "html": record.html_content}
        default = DEFAULT_TEMPLATES.get(name)
        if default:
            return default
        raise AppException("TEMPLATE_NOT_FOUND", f"قالب البريد '{name}' غير موجود", 404)

    @staticmethod
    def render(db: Session, template_name: str, variables: dict) -> tuple[str, str]:
        template = EmailTemplateService.get_template(db, template_name)
        if not template:
            template = DEFAULT_TEMPLATES.get(template_name, DEFAULT_TEMPLATES["welcome"])
        env = EmailTemplateService._get_env()
        rendered = env.from_string(template["html"]).render(**variables, year=datetime.now(timezone.utc).year)
        subject = env.from_string(template["subject"]).render(**variables)
        return subject, rendered

    @staticmethod
    def save_template(db: Session, name: str, subject: str, html_content: str):
        record = db.query(EmailTemplate).filter(EmailTemplate.name == name).first()
        if not record:
            record = EmailTemplate(id=gen_uuid(), name=name)
            db.add(record)
        record.subject = subject
        record.html_content = html_content
        db.commit()

    @staticmethod
    def seed_templates(db: Session):
        for name, cfg in DEFAULT_TEMPLATES.items():
            existing = db.query(EmailTemplate).filter(EmailTemplate.name == name).first()
            if not existing:
                db.add(EmailTemplate(
                    id=gen_uuid(), name=name,
                    subject=cfg["subject"],
                    html_content=cfg["html"],
                ))
        db.commit()
