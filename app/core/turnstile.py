import httpx

from app.core.config import get_settings


async def verify_turnstile(token: str) -> bool:
    settings = get_settings()
    if not settings.turnstile_secret_key:
        return True
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(
                "https://challenges.cloudflare.com/turnstile/v0/siteverify",
                data={"secret": settings.turnstile_secret_key, "response": token},
            )
            result = resp.json()
            return result.get("success", False)
    except Exception:
        return False
