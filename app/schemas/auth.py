from pydantic import BaseModel, EmailStr, Field


class LoginRequest(BaseModel):
    email: str = Field(..., description="البريد الإلكتروني")
    password: str = Field(..., min_length=8, description="كلمة المرور")


class RegisterRequest(BaseModel):
    email: str = Field(..., description="البريد الإلكتروني")
    password: str = Field(..., min_length=8, description="كلمة المرور")
    display_name: str = Field(default="", max_length=100, description="الاسم المعروض")


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str = Field(..., min_length=8)


class MFASetupResponse(BaseModel):
    secret: str
    qr_code_url: str


class MFAVerifyRequest(BaseModel):
    token: str


class MFALoginRequest(BaseModel):
    email: str
    password: str
    mfa_token: str
