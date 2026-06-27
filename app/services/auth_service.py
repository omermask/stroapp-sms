from datetime import datetime, timezone
from typing import Optional

import httpx
import jwt
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.logging import get_logger
from app.domain.models import User, gen_uuid

logger = get_logger(__name__)

APPLE_KEYS_URL = "https://appleid.apple.com/auth/keys"
APPLE_ISS = "https://appleid.apple.com"


def _now():
    return datetime.now(timezone.utc)


def _get_provider_user(db: Session, field: str, value: str) -> Optional[User]:
    return db.query(User).filter(getattr(User, field) == value).first()


async def verify_google_token(id_token: str) -> Optional[dict]:
    async with httpx.AsyncClient() as client:
        resp = await client.get(
            "https://oauth2.googleapis.com/tokeninfo",
            params={"id_token": id_token},
        )
        if resp.status_code != 200:
            logger.warning(f"Google token verification failed: {resp.text}")
            return None
        return resp.json()


async def verify_apple_token(identity_token: str) -> Optional[dict]:
    settings = get_settings()
    if not settings.apple_client_id:
        logger.warning("Apple client ID not configured")
        return None

    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(APPLE_KEYS_URL)
            if resp.status_code != 200:
                logger.warning(f"Failed to fetch Apple keys: {resp.status_code}")
                return None
            keys = resp.json().get("keys", [])

        header = jwt.get_unverified_header(identity_token)
        kid = header.get("kid")
        alg = header.get("alg", "RS256")

        matching_key = None
        for key in keys:
            if key.get("kid") == kid:
                matching_key = key
                break

        if not matching_key:
            logger.warning(f"Apple key with kid={kid} not found")
            return None

        public_key = jwt.algorithms.RSAAlgorithm.from_jwk(
            str(matching_key)
        )

        payload = jwt.decode(
            identity_token,
            public_key,
            algorithms=[alg],
            audience=settings.apple_client_id,
            issuer=APPLE_ISS,
        )

        return payload

    except jwt.ExpiredSignatureError:
        logger.warning("Apple token expired")
        return None
    except jwt.InvalidTokenError as e:
        logger.warning(f"Apple token invalid: {e}")
        return None
    except Exception as e:
        logger.error(f"Apple token verification error: {e}")
        return None


def _create_user(db: Session, provider_field: str, provider_id: str,
                 email: str = "", name: str = "", picture: str = "") -> User:
    user = User(
        id=gen_uuid(),
        email=email or None,
        display_name=name or None,
        photo_url=picture or None,
        **{provider_field: provider_id},
        coins=0,
        lifetime_coins=0,
        email_verified=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def _update_existing_user(db: Session, user: User, **kwargs):
    for key, value in kwargs.items():
        setattr(user, key, value)
    user.last_login_at = _now()
    db.commit()
    db.refresh(user)
    return user


async def get_or_create_google_user(db: Session, google_info: dict) -> tuple[User, bool]:
    google_id = google_info.get("sub")
    email = google_info.get("email", "")
    name = google_info.get("name", "")
    picture = google_info.get("picture", "")

    user = _get_provider_user(db, "google_id", google_id)
    if user:
        return _update_existing_user(db, user, email_verified=True), False

    if email:
        user = _get_provider_user(db, "email", email)
        if user:
            return _update_existing_user(db, user, google_id=google_id, email_verified=True), False

    return _create_user(db, "google_id", google_id, email, name, picture), True


async def get_or_create_apple_user(db: Session, apple_info: dict) -> tuple[User, bool]:
    apple_id = apple_info.get("sub")
    email = apple_info.get("email", "")

    user = _get_provider_user(db, "apple_id", apple_id)
    if user:
        return _update_existing_user(db, user, email_verified=True), False

    if email:
        user = _get_provider_user(db, "email", email)
        if user:
            return _update_existing_user(db, user, apple_id=apple_id, email_verified=True), False

    return _create_user(db, "apple_id", apple_id, email), True
