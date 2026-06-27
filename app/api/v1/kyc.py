from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import User
from app.services.kyc_service import KYCService

router = APIRouter(prefix="/kyc", tags=["KYC"])


class KYCProfileSubmit(BaseModel):
    full_name: str | None = None
    date_of_birth: str | None = None
    nationality: str | None = None
    phone_number: str | None = None
    address_line1: str | None = None
    address_line2: str | None = None
    city: str | None = None
    state: str | None = None
    postal_code: str | None = None
    country: str | None = None


class KYCDocumentUpload(BaseModel):
    document_type: str
    file_path: str
    file_hash: str


def _get_ip(request: Request) -> str:
    forwarded = request.headers.get("x-forwarded-for", "")
    return forwarded.split(",")[0].strip() if forwarded else (request.client.host if request.client else "")


@router.get("/profile")
async def get_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = KYCService.get_profile(db, current_user.id)
    if not result:
        raise AppException(code="not_found", message="لم يتم إنشاء ملف KYC بعد", status_code=404)
    return success_response(result)


@router.post("/profile")
async def submit_profile(
    body: KYCProfileSubmit,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = KYCService.submit_profile(db, current_user.id, body.model_dump(exclude_none=True), _get_ip(request))
    return success_response(result)


@router.put("/profile")
async def update_profile(
    body: KYCProfileSubmit,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = KYCService.update_profile(db, current_user.id, body.model_dump(exclude_none=True))
    if not result:
        raise AppException(code="not_found", message="لم يتم إنشاء ملف KYC بعد", status_code=404)
    return success_response(result)


@router.post("/documents/upload")
async def upload_document(
    body: KYCDocumentUpload,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not body.document_type or not body.file_path or not body.file_hash:
        raise AppException(code="validation_error", message="document_type و file_path و file_hash مطلوبون")
    result = KYCService.upload_document(db, current_user.id, body.document_type, body.file_path, body.file_hash)
    return success_response(result)


@router.get("/documents")
async def get_documents(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    profile = KYCService.get_profile(db, current_user.id)
    if not profile:
        raise AppException(code="not_found", message="لم يتم إنشاء ملف KYC بعد", status_code=404)
    docs = KYCService.get_documents(db, profile["id"])
    return success_response(docs)


@router.get("/status")
async def get_status(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    profile = KYCService.get_profile(db, current_user.id)
    if not profile:
        return success_response({"status": "not_submitted", "verification_level": "unverified"})
    return success_response({
        "status": profile["status"],
        "verification_level": profile["verification_level"],
        "aml_status": profile["aml_status"],
    })


@router.get("/limits")
async def get_limits(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = KYCService.get_limits(db, current_user.id)
    return success_response(result)
