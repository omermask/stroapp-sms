import hashlib
import logging
import re
import secrets
from datetime import datetime, timezone, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, EmailStr, field_validator
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.exceptions import AppException
from app.core.response import success_response
from app.core.security import create_access_token, create_refresh_token, hash_password, verify_password, verify_token
from app.domain.models import AuditLog, Referral, ReferralCode, User, gen_uuid
from app.services.auth_service import (
    get_or_create_apple_user,
    get_or_create_google_user,
    verify_apple_token,
    verify_google_token,
)
from app.services.audit_service import AuditService
from app.core.session_manager import SessionManager
from app.core.turnstile import verify_turnstile
from app.services.blacklist_service import BlacklistService
from app.services.geoip_service import lookup as geoip_lookup

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/user/auth", tags=["Auth"])


def process_referral_code(db: Session, code: str | None, referred_user_id: str, request: Request | None = None):
    if not code:
        return
    code_record = db.query(ReferralCode).filter(ReferralCode.code == code).first()
    if not code_record:
        return
    if code_record.user_id == referred_user_id:
        return
    existing = db.query(Referral).filter(Referral.referred_id == referred_user_id).first()
    if existing:
        return
    referral = Referral(
        id=gen_uuid(),
        referrer_id=code_record.user_id,
        referred_id=referred_user_id,
        code=code,
        status="pending",
    )
    db.add(referral)
    db.commit()
    ip = request.client.host if request and request.client else ""
    AuditService.log(db, referred_user_id, "referral.create", "referral", referral.id,
                   {"referrer_id": code_record.user_id, "code": code}, ip,
                   getattr(request.state, "request_id", ""))


class GoogleAuthRequest(BaseModel):
    id_token: str
    ref: Optional[str] = None


class AppleAuthRequest(BaseModel):
    identity_token: str
    ref: Optional[str] = None


class RefreshRequest(BaseModel):
    refresh_token: str


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    display_name: Optional[str] = None
    turnstile_token: str = ""
    ref: Optional[str] = None

    @field_validator("password")
    @classmethod
    def password_complexity(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("كلمة المرور يجب أن تكون 8 أحرف على الأقل")
        if not re.search(r"[A-Z]", v):
            raise ValueError("كلمة المرور يجب أن تحتوي على حرف كبير واحد على الأقل")
        if not re.search(r"[a-z]", v):
            raise ValueError("كلمة المرور يجب أن تحتوي على حرف صغير واحد على الأقل")
        if not re.search(r"\d", v):
            raise ValueError("كلمة المرور يجب أن تحتوي على رقم واحد على الأقل")
        return v


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str


@router.post("/google")
async def google_signin(
    body: GoogleAuthRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    google_info = await verify_google_token(body.id_token)
    if not google_info:
        raise AppException("VALIDATION_ERROR", "رمز Google غير صالح", status_code=401)
    user, is_new = await get_or_create_google_user(db, google_info)
    if is_new and body.ref:
        process_referral_code(db, body.ref, user.id, request)
    refresh_token = create_refresh_token(user.id)
    ip = request.client.host if request.client else ""
    city, country = await geoip_lookup(ip)
    session = SessionManager.create_session(db, user.id, ip, request.headers.get("user-agent", ""), refresh_token, city=city, country=country)
    access_token = create_access_token(user.id, session.id)
    action = "user.register" if is_new else "user.login"
    AuditService.log(db, user.id, action, "user", user.id, {"provider": "google", "email": user.email, "is_new": is_new}, ip, getattr(request.state, "request_id", ""))
    return success_response(
        {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "user": {
                "id": user.id,
                "email": user.email,
                "display_name": user.display_name,
                "photo_url": user.photo_url,
                "coins": user.coins,
            },
        },
        request_id=getattr(request.state, "request_id", ""),
    )


@router.post("/apple")
async def apple_signin(
    body: AppleAuthRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    apple_info = await verify_apple_token(body.identity_token)
    if not apple_info:
        raise AppException("VALIDATION_ERROR", "رمز Apple غير صالح", status_code=401)
    user, is_new = await get_or_create_apple_user(db, apple_info)
    if is_new and body.ref:
        process_referral_code(db, body.ref, user.id, request)
    refresh_token = create_refresh_token(user.id)
    ip = request.client.host if request.client else ""
    city, country = await geoip_lookup(ip)
    session = SessionManager.create_session(db, user.id, ip, request.headers.get("user-agent", ""), refresh_token, city=city, country=country)
    access_token = create_access_token(user.id, session.id)
    action = "user.register" if is_new else "user.login"
    AuditService.log(db, user.id, action, "user", user.id, {"provider": "apple", "email": user.email, "is_new": is_new}, ip, getattr(request.state, "request_id", ""))
    return success_response(
        {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "user": {
                "id": user.id,
                "email": user.email,
                "display_name": user.display_name,
                "photo_url": user.photo_url,
                "coins": user.coins,
            },
        },
        request_id=getattr(request.state, "request_id", ""),
    )


@router.post("/refresh")
async def refresh_token(
    body: RefreshRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    payload = verify_token(body.refresh_token, expected_type="refresh")
    if not payload:
        raise AppException("TOKEN_INVALID", "رمز التحديث غير صالح أو منتهي الصلاحية", status_code=401)
    session = SessionManager.get_session(db, body.refresh_token)
    if not session:
        raise AppException("SESSION_EXPIRED", "انتهت صلاحية الجلسة", status_code=401)
    user = db.query(User).filter(User.id == payload["sub"]).first()
    if not user:
        raise AppException("USER_NOT_FOUND", "المستخدم غير موجود", status_code=401)
    new_refresh = create_refresh_token(user.id)
    ip = request.client.host if request and request.client else ""
    city, country = await geoip_lookup(ip)
    session = SessionManager.rotate_session(db, body.refresh_token, user.id, ip, request.headers.get("user-agent", ""), new_refresh, city=city, country=country)
    new_access = create_access_token(user.id, session.id)
    return success_response(
        {
            "access_token": new_access,
            "refresh_token": new_refresh,
            "token_type": "bearer",
        },
        request_id=getattr(request.state, "request_id", ""),
    )


@router.post("/logout")
async def logout(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    auth_header = request.headers.get("Authorization", "")
    refresh_from_session = None
    if auth_header.startswith("Bearer "):
        token = auth_header[7:]
        payload = verify_token(token)
        if payload:
            BlacklistService.blacklist_token(db, payload.get("jti", ""), "access", current_user.id, "logout")
    refresh_from_session = request.headers.get("x-refresh-token", "")
    if refresh_from_session:
        SessionManager.invalidate_session(db, refresh_from_session)
    return success_response(
        {"message": "تم تسجيل الخروج بنجاح"},
        request_id=getattr(request.state, "request_id", ""),
    )


@router.post("/register")
async def register(
    body: RegisterRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    if not await verify_turnstile(body.turnstile_token):
        raise AppException("VALIDATION_ERROR", "فشل التحقق الأمني، يرجى المحاولة مرة أخرى", 400)
    existing = db.query(User).filter(User.email == body.email).first()
    if existing:
        raise AppException("EMAIL_EXISTS", "البريد الإلكتروني مستخدم بالفعل", 409)
    user = User(
        id=gen_uuid(),
        email=body.email,
        hashed_password=hash_password(body.password),
        display_name=body.display_name or body.email.split("@")[0],
        coins=0,
    )
    db.add(user)
    db.commit()
    process_referral_code(db, body.ref, user.id, request)
    refresh_token = create_refresh_token(user.id)
    ip = request.client.host if request and request.client else ""
    city, country = await geoip_lookup(ip)
    session = SessionManager.create_session(db, user.id, ip, request.headers.get("user-agent", "") if request else "", refresh_token, city=city, country=country)
    access_token = create_access_token(user.id, session.id)
    AuditService.log(db, user.id, "user.register", "user", user.id,
                   {"provider": "email", "email": body.email}, ip,
                   getattr(request.state, "request_id", ""))
    return success_response(
        {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "user": {
                "id": user.id,
                "email": user.email,
                "display_name": user.display_name,
                "photo_url": user.photo_url,
                "coins": user.coins,
            },
        },
        request_id=getattr(request.state, "request_id", ""),
    )


@router.post("/login")
async def login(
    body: LoginRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.email == body.email).first()
    _DUMMY_HASH = "$2b$12$KIXjdummyhashfortimingreasonsonlyXXXXXXXXXXXXXXXXXXXX"
    hash_to_verify = user.hashed_password if user else _DUMMY_HASH
    is_valid_password = verify_password(body.password, hash_to_verify or "")
    if not user or not is_valid_password:
        raise AppException("INVALID_CREDENTIALS", "البريد الإلكتروني أو كلمة المرور غير صحيحة", 401)
    if user.is_banned:
        raise AppException("FORBIDDEN", "الحساب محظور", 403)
    if not user.is_active:
        raise AppException("FORBIDDEN", "الحساب غير نشط", 403)
    refresh_token = create_refresh_token(user.id)
    ip = request.client.host if request and request.client else ""
    city, country = await geoip_lookup(ip)
    session = SessionManager.create_session(db, user.id, ip, request.headers.get("user-agent", "") if request else "", refresh_token, city=city, country=country)
    access_token = create_access_token(user.id, session.id)
    AuditService.log(db, user.id, "user.login", "user", user.id,
                   {"provider": "email"}, ip,
                   getattr(request.state, "request_id", ""))
    return success_response(
        {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "user": {
                "id": user.id,
                "email": user.email,
                "display_name": user.display_name,
                "photo_url": user.photo_url,
                "coins": user.coins,
            },
        },
        request_id=getattr(request.state, "request_id", ""),
    )


@router.post("/forgot-password")
async def forgot_password(
    body: ForgotPasswordRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.email == body.email).first()
    if user:
        token = secrets.token_urlsafe(32)
        token_hash = hashlib.sha256(token.encode()).hexdigest()
        user.reset_token = token_hash
        user.reset_token_expires = datetime.now(timezone.utc) + timedelta(hours=1)
        db.commit()
        AuditService.log(db, user.id, "user.forgot_password", "user", user.id, {},
                       request.client.host if request and request.client else "",
                       getattr(request.state, "request_id", ""))
        reset_link = f"{get_settings().base_url}/reset-password?token={token}"
        from app.services.email_sender import EmailSender
        sent = await EmailSender().send(
            to=user.email,
            subject="إعادة تعيين كلمة المرور - StroApp",
            html_body=f"""
            <html dir="rtl">
            <body style="font-family: Arial; padding: 20px;">
                <h2>إعادة تعيين كلمة المرور</h2>
                <p>لقد تلقينا طلباً لإعادة تعيين كلمة المرور لحسابك في StroApp.</p>
                <p>اضغط على الرابط أدناه لإعادة تعيين كلمة المرور:</p>
                <p><a href="{reset_link}" style="display: inline-block; padding: 12px 24px; background: #4CAF50; color: white; text-decoration: none; border-radius: 4px;">إعادة تعيين كلمة المرور</a></p>
                <p>إذا لم تطلب إعادة تعيين كلمة المرور، يمكنك تجاهل هذا البريد.</p>
                <p>الرابط صالح لمدة ساعة واحدة.</p>
            </body>
            </html>
            """,
            text_body=f"لإعادة تعيين كلمة المرور، افتح الرابط: {reset_link}\n\nالرابط صالح لمدة ساعة واحدة.",
        )
        if not sent:
            logger.warning(f"Could not send password reset email to {user.email}")
    return success_response(
        {"message": "إذا كان البريد الإلكتروني مسجلاً، سيتم إرسال رابط إعادة تعيين كلمة المرور"},
        request_id=getattr(request.state, "request_id", ""),
    )


@router.post("/reset-password")
async def reset_password(
    body: ResetPasswordRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    # M-6 FIX: توحيد سياسة التحقق من كلمة المرور لتتطابق مع متطلبات التسجيل
    if len(body.new_password) < 8:
        raise AppException("VALIDATION_ERROR", "كلمة المرور يجب أن تكون 8 أحرف على الأقل", 400)
    if not re.search(r"[A-Z]", body.new_password):
        raise AppException("VALIDATION_ERROR", "كلمة المرور يجب أن تحتوي على حرف كبير واحد على الأقل", 400)
    if not re.search(r"[a-z]", body.new_password):
        raise AppException("VALIDATION_ERROR", "كلمة المرور يجب أن تحتوي على حرف صغير واحد على الأقل", 400)
    if not re.search(r"\d", body.new_password):
        raise AppException("VALIDATION_ERROR", "كلمة المرور يجب أن تحتوي على رقم واحد على الأقل", 400)
    token_hash = hashlib.sha256(body.token.encode()).hexdigest()
    user = db.query(User).filter(
        User.reset_token == token_hash,
        User.reset_token_expires > datetime.now(timezone.utc),
    ).first()
    if not user:
        raise AppException("INVALID_TOKEN", "الرابط غير صالح أو منتهي الصلاحية", 400)
    user.hashed_password = hash_password(body.new_password)
    user.reset_token = None
    user.reset_token_expires = None
    SessionManager.invalidate_all_sessions(db, user.id)
    db.commit()
    AuditService.log(db, user.id, "user.reset_password", "user", user.id, {},
                   request.client.host if request and request.client else "",
                   getattr(request.state, "request_id", ""))
    return success_response(
        {"message": "تم إعادة تعيين كلمة المرور بنجاح"},
        request_id=getattr(request.state, "request_id", ""),
    )


@router.get("/me")
async def get_me(
    request: Request,
    current_user: User = Depends(get_current_user),
):
    return success_response(
        {
            "id": current_user.id,
            "email": current_user.email,
            "display_name": current_user.display_name,
            "photo_url": current_user.photo_url,
            "coins": current_user.coins,
            "created_at": current_user.created_at.isoformat() if current_user.created_at else None,
        },
        request_id=getattr(request.state, "request_id", ""),
    )
