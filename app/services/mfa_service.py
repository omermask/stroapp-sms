import base64

import pyotp
import qrcode
from io import BytesIO

from app.core.exceptions import AppException


class MFAService:
    @staticmethod
    def generate_secret() -> str:
        return pyotp.random_base32()

    @staticmethod
    def generate_qr_code(user_email: str, secret: str) -> str:
        uri = pyotp.totp.TOTP(secret).provisioning_uri(name=user_email, issuer_name="StroApp SMS")
        qr = qrcode.make(uri)
        buf = BytesIO()
        qr.save(buf, format="PNG")
        return base64.b64encode(buf.getvalue()).decode()

    @staticmethod
    def verify_token(secret: str, token: str) -> bool:
        return pyotp.TOTP(secret).verify(token, valid_window=1)

    @staticmethod
    def setup(user_email: str) -> dict:
        secret = MFAService.generate_secret()
        qr_code = MFAService.generate_qr_code(user_email, secret)
        return {"secret": secret, "qr_code": qr_code}

    @staticmethod
    def verify_and_enable(secret: str, token: str) -> bool:
        if not MFAService.verify_token(secret, token):
            raise AppException("INVALID_MFA_TOKEN", "رمز التحقق غير صحيح", 400)
        return True

    @staticmethod
    def verify_and_disable(user_mfa_secret: str, token: str) -> bool:
        if not MFAService.verify_token(user_mfa_secret, token):
            raise AppException("INVALID_MFA_TOKEN", "رمز التحقق غير صحيح", 400)
        return True
