import secrets
from typing import Optional

import httpx
import jwt
from fastapi import APIRouter, Depends, Query, Request
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.database import get_db
from app.core.logging import get_logger
from app.core.response import success_response
from app.core.security import create_access_token, create_refresh_token
from app.core.session_manager import SessionManager
from app.domain.models import User
from app.infrastructure.cache.cache_manager import cache
from app.services.auth_service import get_or_create_google_user
from app.services.audit_service import AuditService
from app.services.geoip_service import lookup as geoip_lookup

logger = get_logger(__name__)
router = APIRouter(prefix="/user/auth/google", tags=["Google OAuth"])


async def _store_oauth_state(state: str) -> None:
    await cache.set(f"oauth_state:{state}", True, ttl=600)


async def _validate_oauth_state(state: str) -> bool:
    result = await cache.get(f"oauth_state:{state}")
    if result:
        await cache.delete(f"oauth_state:{state}")
        return True
    return False


@router.get("/config")
async def google_config():
    settings = get_settings()
    return success_response({
        "client_id": settings.google_client_id,
        "enabled": bool(settings.google_client_id),
    })


@router.get("/login")
async def google_login(request: Request):
    settings = get_settings()
    if not settings.google_client_id:
        return {"error": "Google OAuth غير مضبوط"}
    state = secrets.token_urlsafe(32)
    await _store_oauth_state(state)
    redirect_uri = f"{settings.base_url}/stroapp/v1/user/auth/google/callback"
    params = {
        "client_id": settings.google_client_id,
        "redirect_uri": redirect_uri,
        "response_type": "code",
        "scope": "openid email profile",
        "state": state,
        "access_type": "offline",
        "prompt": "consent",
    }
    auth_url = f"https://accounts.google.com/o/oauth2/v2/auth?{'&'.join([f'{k}={v}' for k, v in params.items()])}"
    return RedirectResponse(url=auth_url)


@router.get("/callback")
async def google_callback(
    code: str = Query(...),
    state: str = Query(...),
    error: Optional[str] = Query(None),
    request: Request = None,
    db: Session = Depends(get_db),
):
    if error:
        return {"error": f"Google OAuth error: {error}"}
    if not await _validate_oauth_state(state):
        return {"error": "State غير صالح.可能 هجمة CSRF."}

    settings = get_settings()
    redirect_uri = f"{settings.base_url}/stroapp/v1/user/auth/google/callback"

    async with httpx.AsyncClient() as client:
        token_resp = await client.post(
            "https://oauth2.googleapis.com/token",
            data={
                "code": code,
                "client_id": settings.google_client_id,
                "client_secret": settings.google_client_secret,
                "redirect_uri": redirect_uri,
                "grant_type": "authorization_code",
            },
        )
        if token_resp.status_code != 200:
            return {"error": "فشل تبادل رمز Google"}
        token_data = token_resp.json()

    id_token = token_data.get("id_token")
    if not id_token:
        return {"error": "لم يتم استلام id_token من Google"}

    try:
        jwks_client = jwt.PyJWKClient("https://www.googleapis.com/oauth2/v3/certs", cache_keys=True)
        signing_key = jwks_client.get_signing_key_from_jwt(id_token)
        google_info = jwt.decode(
            id_token,
            key=signing_key.key,
            audience=settings.google_client_id,
            options={"verify_exp": True},
            algorithms=["RS256"],
        )
    except jwt.ExpiredSignatureError:
        return {"error": "انتهت صلاحية id_token"}
    except jwt.PyJWKClientError as e:
        logger.error(f"Failed to fetch Google signing key: {e}")
        return {"error": "فشل التحقق من توقيع Google"}
    except jwt.InvalidTokenError as e:
        logger.error(f"Google ID token verification failed: {e}")
        return {"error": "id_token غير صالح"}
    user, is_new = await get_or_create_google_user(db, google_info)
    refresh_token = create_refresh_token(user.id)
    ip = request.client.host if request and request.client else ""
    city, country = await geoip_lookup(ip)
    session = SessionManager.create_session(db, user.id, ip, request.headers.get("user-agent", ""), refresh_token, city=city, country=country)
    access_token = create_access_token(user.id, session.id)
    AuditService.log(db, user.id, "user.register" if is_new else "user.login",
                     "user", user.id, {"provider": "google", "email": user.email}, ip,
                     getattr(request.state, "request_id", ""))

    if user.is_admin:
        redirect_path = "/stroapp/v1/admin/login"
    else:
        redirect_path = "/stroapp/v1/user/login"

    from fastapi.responses import HTMLResponse
    from fastapi.responses import RedirectResponse as FastAPIRedirect

    response = FastAPIRedirect(url=f"{settings.base_url}{redirect_path}")
    response.set_cookie(
        key="access_token", value=access_token,
        httponly=True, secure=settings.base_url.startswith("https"),
        samesite="lax", max_age=3600, path="/",
    )
    response.set_cookie(
        key="refresh_token", value=refresh_token,
        httponly=True, secure=settings.base_url.startswith("https"),
        samesite="lax", max_age=86400 * 30, path="/",
    )
    return response
