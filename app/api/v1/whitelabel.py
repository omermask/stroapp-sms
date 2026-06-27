from typing import Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import User
from app.services.whitelabel_service import WhitelabelService

router = APIRouter(prefix="/whitelabel", tags=["Whitelabel"])


class AddDomain(BaseModel):
    domain: str


class UpsertBranding(BaseModel):
    company_name: Optional[str] = None
    logo_url: Optional[str] = None
    favicon_url: Optional[str] = None
    primary_color: Optional[str] = None
    secondary_color: Optional[str] = None
    accent_color: Optional[str] = None
    support_email: Optional[str] = None
    support_phone: Optional[str] = None
    website_url: Optional[str] = None
    custom_css: Optional[str] = None
    terms_url: Optional[str] = None
    privacy_url: Optional[str] = None


class UpsertEmailTemplate(BaseModel):
    template_name: str
    subject: str
    html_content: str
    text_content: Optional[str] = None


@router.post("/domains")
async def add_domain(
    body: AddDomain,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not body.domain:
        raise AppException(code="validation_error", message="domain مطلوب")
    result = WhitelabelService.add_domain(db, current_user.id, body.domain)
    if "error" in result:
        raise AppException(code="duplicate", message=result["error"])
    return success_response(result)


@router.post("/domains/{domain_id}/verify")
async def verify_domain(
    domain_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = WhitelabelService.verify_domain(db, domain_id)
    if not result:
        raise AppException(code="not_found", message="النطاق غير موجود", status_code=404)
    return success_response(result)


@router.get("/domains")
async def get_domains(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    domains = WhitelabelService.get_user_domains(db, current_user.id)
    return success_response(domains)


@router.post("/domains/{domain_id}/toggle")
async def toggle_domain(
    domain_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = WhitelabelService.toggle_domain(db, domain_id)
    if not result:
        raise AppException(code="not_found", message="النطاق غير موجود", status_code=404)
    return success_response(result)


@router.get("/branding")
async def get_branding(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = WhitelabelService.get_branding(db, current_user.id)
    if not result:
        raise AppException(code="not_found", message="لم يتم إعداد العلامة التجارية بعد", status_code=404)
    return success_response(result)


@router.put("/branding")
async def upsert_branding(
    body: UpsertBranding,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = WhitelabelService.upsert_branding(db, current_user.id, body.model_dump(exclude_none=True))
    return success_response(result)


@router.get("/email-templates")
async def get_email_templates(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    templates = WhitelabelService.get_email_templates(db, current_user.id)
    return success_response(templates)


@router.get("/email-templates/{template_id}")
async def get_email_template(
    template_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = WhitelabelService.get_email_template(db, template_id)
    if not result:
        raise AppException(code="not_found", message="قالب البريد غير موجود", status_code=404)
    return success_response(result)


@router.post("/email-templates")
async def upsert_email_template(
    body: UpsertEmailTemplate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = WhitelabelService.upsert_email_template(db, current_user.id, body.model_dump(), current_user.id)
    return success_response(result)


@router.post("/email-templates/{template_id}/toggle")
async def toggle_email_template(
    template_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = WhitelabelService.toggle_email_template(db, template_id)
    if not result:
        raise AppException(code="not_found", message="القالب غير موجود", status_code=404)
    return success_response(result)


@router.post("/email-templates/{template_id}/revert/{version_number}")
async def revert_template(
    template_id: str,
    version_number: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = WhitelabelService.revert_template_version(db, template_id, version_number)
    if not result:
        raise AppException(code="not_found", message="القالب أو الإصدار غير موجود", status_code=404)
    return success_response(result)
