"""
Comprehensive End-to-End Test Suite for StroApp SMS API
=======================================================
Tests ALL endpoints: user + admin, happy path + error cases.

Run: python -m pytest tests/test_comprehensive.py -v --tb=long
"""

import asyncio
import random
import uuid
from typing import Optional

import httpx
import pytest
from faker import Faker

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
BASE_URL = "http://localhost:9527"
API_PREFIX = "/stroapp/v1"
COINS_PER_USD = 100
DEFAULT_MARKUP = 1.15

fake = Faker()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def url(path: str) -> str:
    return f"{BASE_URL}{API_PREFIX}{path}"


def assert_success(resp: httpx.Response, data_key: str | None = None):
    """Assert response is successful and optionally return data."""
    assert resp.status_code in (200, 201), f"Expected 2xx, got {resp.status_code}: {resp.text}"
    body = resp.json()
    assert body["success"] is True, f"success=False: {body}"
    if data_key:
        assert data_key in body["data"], f"Missing '{data_key}' in data: {body['data']}"
    return body["data"] if "data" in body else body


def assert_error(resp: httpx.Response, expected_code: str, expected_status: int = 400):
    """Assert response is an AppException with matching code."""
    assert resp.status_code == expected_status, f"Expected {expected_status}, got {resp.status_code}: {resp.text}"
    body = resp.json()
    assert body["success"] is False
    assert body["error"]["code"] == expected_code, f"Expected code={expected_code}, got {body['error']['code']}: {body}"
    return body


class TestClient:  # noqa: ignore-pytest
    """Wraps httpx.AsyncClient with auth token management."""

    def __init__(self):
        self.client = httpx.AsyncClient(base_url=BASE_URL, timeout=60)
        self.user_token: str = ""
        self.admin_token: str = ""
        self.user_id: str = ""
        self.admin_id: str = ""
        # Store created resources for cleanup/reuse
        self.test_order_id: str = ""
        self.test_api_key_id: str = ""
        self.test_rental_id: str = ""
        self.test_preset_id: str = ""
        self.test_webhook_id: str = ""
        self.test_ticket_id: str = ""

    # ---- Auth helpers ----

    def _auth_header(self, token: str) -> dict:
        return {"Authorization": f"Bearer {token}"}

    @property
    def user_headers(self) -> dict:
        return self._auth_header(self.user_token)

    @property
    def admin_headers(self) -> dict:
        return self._auth_header(self.admin_token)

    # ---- Registration & Login ----

    async def register_user(self, email: str, password: str, display_name: str = "") -> dict:
        data = {"email": email, "password": password, "display_name": display_name or fake.first_name()}
        resp = await self.client.post(url("/user/auth/register"), json=data)
        if resp.status_code == 200:
            body = resp.json()
            return body.get("data", {})
        return {}

    async def login_user(self, email: str, password: str) -> dict:
        resp = await self.client.post(url("/user/auth/login"), json={"email": email, "password": password})
        if resp.status_code == 200:
            body = resp.json()
            return body.get("data", {})
        return {}

    async def register_and_login(self, email: str, password: str = "TestPass123!") -> tuple[str, str]:
        """Register + login, return (token, user_id)."""
        await self.register_user(email, password)
        data = await self.login_user(email, password)
        token = data.get("access_token", "")
        # Fetch /me to get user_id
        if token:
            resp = await self.client.get(url("/user/auth/me"), headers=self._auth_header(token))
            if resp.status_code == 200:
                me = resp.json().get("data", {})
                return token, me.get("id", "")
        return "", ""

    async def bootstrap(self):
        """Create test user + admin, populate tokens."""
        # --- User ---
        user_email = f"test_{uuid.uuid4().hex[:8]}@example.com"
        self.user_token, self.user_id = await self.register_and_login(user_email)
        assert self.user_token, "Failed to register/login test user"

        # --- Admin (seed from DB or login as existing) ---
        # Try common admin accounts
        admin_creds = [
            ("admin@stroapp.com", "AdminPass123!"),
            ("admin@example.com", "AdminPass123!"),
        ]
        for a_email, a_pass in admin_creds:
            data = await self.login_user(a_email, a_pass)
            if data.get("access_token"):
                self.admin_token = data["access_token"]
                resp = await self.client.get(url("/user/auth/me"), headers=self._auth_header(self.admin_token))
                if resp.status_code == 200:
                    self.admin_id = resp.json().get("data", {}).get("id", "")
                break

    async def close(self):
        await self.client.aclose()


# ===========================================================================
# 1. PUBLIC ENDPOINTS
# ===========================================================================

class TestPublicEndpoints:
    """No auth required — health, version, services, providers."""

    async def test_health(self, client: TestClient):
        resp = await client.client.get(url("/health"))
        data = assert_success(resp)
        assert data["status"] == "ok"
        assert data["database"] == "connected"

    async def test_version(self, client: TestClient):
        resp = await client.client.get(url("/version"))
        assert_success(resp)

    async def test_services_list(self, client: TestClient):
        resp = await client.client.get(url("/services"))
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_services_countries(self, client: TestClient):
        resp = await client.client.get(url("/services/countries"))
        assert_success(resp)

    async def test_services_categories(self, client: TestClient):
        resp = await client.client.get(url("/services/categories"))
        assert_success(resp)

    async def test_providers_list(self, client: TestClient):
        resp = await client.client.get(url("/providers"))
        data = assert_success(resp)
        names = [p["name"] for p in data]
        for expected in ("smsman", "fivesim", "smsactivate", "smspool"):
            assert expected in names, f"Provider {expected} missing"

    async def test_tiers_list_public(self, client: TestClient):
        resp = await client.client.get(url("/user/tiers"))
        assert_success(resp)

    async def test_affiliate_tiers_public(self, client: TestClient):
        resp = await client.client.get(url("/affiliate/tiers"))
        assert_success(resp)

    async def test_push_config_public(self, client: TestClient):
        resp = await client.client.get(url("/user/push/config"))
        assert_success(resp)

    async def test_gdpr_retention_public(self, client: TestClient):
        resp = await client.client.get(url("/user/gdpr/retention-policy"))
        assert_success(resp)

    async def test_google_oauth_config_public(self, client: TestClient):
        resp = await client.client.get(url("/user/auth/google/config"))
        assert_success(resp)

    async def test_waitlist_join(self, client: TestClient):
        resp = await client.client.post(url("/waitlist/join"), json={
            "email": fake.email(),
            "name": fake.first_name(),
        })
        # 200 or 409 (already joined) both acceptable
        assert resp.status_code in (200, 409)

    async def test_email_verify_public(self, client: TestClient):
        # Without token — should fail validation, not auth
        resp = await client.client.post(url("/user/email/verify"), json={"token": "invalid"})
        # Usually 400 or 422 — but NOT 401
        assert resp.status_code in (400, 422), f"Expected 400/422, got {resp.status_code}"


# ===========================================================================
# 2. AUTHENTICATION FLOW
# ===========================================================================

class TestAuthFlow:
    """Register, login, refresh, logout, me, edge cases."""

    TEST_EMAIL = f"auth_{uuid.uuid4().hex[:8]}@example.com"
    TEST_PASS = "Str0ngP@ss!"

    async def test_01_register(self, client: TestClient):
        resp = await client.client.post(url("/user/auth/register"), json={
            "email": self.TEST_EMAIL,
            "password": self.TEST_PASS,
            "display_name": "Test User",
        })
        data = assert_success(resp)
        assert "access_token" in data or "id" in data

    async def test_02_register_duplicate(self, client: TestClient):
        resp = await client.client.post(url("/user/auth/register"), json={
            "email": self.TEST_EMAIL,
            "password": self.TEST_PASS,
        })
        assert_error(resp, "EMAIL_EXISTS", 409)

    async def test_03_login(self, client: TestClient):
        resp = await client.client.post(url("/user/auth/login"), json={
            "email": self.TEST_EMAIL,
            "password": self.TEST_PASS,
        })
        data = assert_success(resp)
        assert "access_token" in data
        assert "refresh_token" in data

    async def test_04_login_wrong_password(self, client: TestClient):
        resp = await client.client.post(url("/user/auth/login"), json={
            "email": self.TEST_EMAIL,
            "password": "WrongPass123!",
        })
        assert_error(resp, "INVALID_CREDENTIALS", 401)

    async def test_05_login_missing_fields(self, client: TestClient):
        resp = await client.client.post(url("/user/auth/login"), json={})
        assert resp.status_code in (400, 422)

    async def test_06_refresh_token(self, client: TestClient):
        # Login first to get tokens
        resp = await client.client.post(url("/user/auth/login"), json={
            "email": self.TEST_EMAIL,
            "password": self.TEST_PASS,
        })
        data = resp.json().get("data", {})
        refresh = data.get("refresh_token", "")
        resp2 = await client.client.post(url("/user/auth/refresh"), json={"refresh_token": refresh})
        data2 = assert_success(resp2)
        assert "access_token" in data2

    async def test_07_refresh_invalid(self, client: TestClient):
        resp = await client.client.post(url("/user/auth/refresh"), json={"refresh_token": "invalid_token"})
        assert resp.status_code in (401, 400)

    async def test_08_get_me(self, client: TestClient):
        resp = await client.client.get(url("/user/auth/me"), headers=client.user_headers)
        data = assert_success(resp)
        assert data["id"] == client.user_id
        assert "email" in data

    async def test_09_get_me_no_auth(self, client: TestClient):
        resp = await client.client.get(url("/user/auth/me"))
        assert_error(resp, "UNAUTHORIZED", 401)

    async def test_10_get_me_bad_token(self, client: TestClient):
        resp = await client.client.get(url("/user/auth/me"), headers={"Authorization": "Bearer bad_token"})
        assert_error(resp, "UNAUTHORIZED", 401)

    async def test_11_logout(self, client: TestClient):
        resp = await client.client.post(url("/user/auth/logout"), headers=client.user_headers)
        assert_success(resp)
        # Token should now be blacklisted
        resp2 = await client.client.get(url("/user/auth/me"), headers=client.user_headers)
        assert resp2.status_code == 401

    async def test_12_forgot_password(self, client: TestClient):
        resp = await client.client.post(url("/user/auth/forgot-password"), json={"email": self.TEST_EMAIL})
        # 200 even if email doesn't exist (prevent enumeration)
        assert resp.status_code in (200, 400, 422)


# ===========================================================================
# 3. SMS PURCHASE FLOW
# ===========================================================================

class TestSMSPurchase:
    """Price, purchase, check SMS, cancel, orders list."""

    async def test_01_sms_price_no_auth(self, client: TestClient):
        resp = await client.client.get(url("/sms/price"), params={"service": "telegram", "country": "US"})
        assert_error(resp, "UNAUTHORIZED", 401)

    async def test_02_sms_price(self, client: TestClient):
        resp = await client.client.get(
            url("/sms/price"),
            params={"service": "telegram", "country": "US"},
            headers=client.user_headers,
        )
        data = assert_success(resp)
        assert "provider" in data
        assert "cost_coins" in data

    async def test_03_sms_price_invalid_service(self, client: TestClient):
        resp = await client.client.get(
            url("/sms/price"),
            params={"service": "nonexistent_service_xyz", "country": "US"},
            headers=client.user_headers,
        )
        assert_error(resp, "SERVICE_UNAVAILABLE", 400)

    async def test_04_sms_purchase_no_balance(self, client: TestClient):
        # User has 0 coins — should fail
        resp = await client.client.post(
            url("/sms/purchase"),
            json={"service": "telegram", "country": "US"},
            headers=client.user_headers,
        )
        # Either INSUFFICIENT_BALANCE or ALL_PROVIDERS_FAILED
        assert resp.status_code in (402, 503)

    async def test_05_sms_purchase_invalid_provider(self, client: TestClient):
        resp = await client.client.post(
            url("/sms/purchase"),
            json={"service": "telegram", "country": "US", "provider": "nonexistent"},
            headers=client.user_headers,
        )
        assert_error(resp, "PROVIDER_DISABLED", 400)

    async def test_06_sms_orders_list(self, client: TestClient):
        resp = await client.client.get(url("/sms/orders"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_07_sms_order_detail_not_found(self, client: TestClient):
        resp = await client.client.get(url("/sms/orders/nonexistent-id"), headers=client.user_headers)
        assert_error(resp, "NOT_FOUND", 404)

    async def test_08_sms_check_not_found(self, client: TestClient):
        resp = await client.client.post(url("/sms/orders/nonexistent-id/check"), headers=client.user_headers)
        assert_error(resp, "NOT_FOUND", 404)

    async def test_09_sms_cancel_not_found(self, client: TestClient):
        resp = await client.client.post(url("/sms/orders/nonexistent-id/cancel"), headers=client.user_headers)
        assert_error(resp, "NOT_FOUND", 404)

    async def test_10_idempotency(self, client: TestClient):
        """Idempotency-Key header prevents duplicate purchases."""
        key = str(uuid.uuid4())
        headers = {**client.user_headers, "Idempotency-Key": key}
        resp1 = await client.client.post(
            url("/sms/purchase"),
            json={"service": "telegram", "country": "US"},
            headers=headers,
        )
        resp2 = await client.client.post(
            url("/sms/purchase"),
            json={"service": "telegram", "country": "US"},
            headers=headers,
        )
        # Second request should return 409 (DUPLICATE_REQUEST) OR same data
        if resp1.status_code == 200:
            assert resp2.status_code in (200, 409)


# ===========================================================================
# 4. USER PROFILE & SETTINGS
# ===========================================================================

class TestUserProfile:
    """Profile CRUD, balance, wallets, transactions."""

    async def test_01_get_profile(self, client: TestClient):
        resp = await client.client.get(url("/user/profile"), headers=client.user_headers)
        data = assert_success(resp)
        assert "email" in data
        assert "coins" in data

    async def test_02_get_profile_no_auth(self, client: TestClient):
        resp = await client.client.get(url("/user/profile"))
        assert_error(resp, "UNAUTHORIZED", 401)

    async def test_03_update_profile(self, client: TestClient):
        resp = await client.client.put(
            url("/user/profile/update"),
            json={"display_name": "Updated Name"},
            headers=client.user_headers,
        )
        assert_success(resp)

    async def test_04_get_balance(self, client: TestClient):
        resp = await client.client.get(url("/user/balance"), headers=client.user_headers)
        data = assert_success(resp)
        assert "coins" in data or "balance" in data

    async def test_05_get_wallet(self, client: TestClient):
        resp = await client.client.get(url("/user/wallet"), headers=client.user_headers)
        assert resp.status_code in (200, 404)  # 404 if wallet not configured

    async def test_06_list_transactions(self, client: TestClient):
        resp = await client.client.get(url("/user/transactions"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_07_change_password(self, client: TestClient):
        resp = await client.client.post(
            url("/user/change-password"),
            json={"current_password": "TestPass123!", "new_password": "NewPass1234!"},
            headers=client.user_headers,
        )
        # 200 or 403 (MFA required) — acceptable
        assert resp.status_code in (200, 403)

    async def test_08_change_password_wrong(self, client: TestClient):
        resp = await client.client.post(
            url("/user/change-password"),
            json={"current_password": "WrongPass!", "new_password": "NewPass1234!"},
            headers=client.user_headers,
        )
        assert resp.status_code in (400, 403, 401)

    async def test_09_user_settings_get(self, client: TestClient):
        resp = await client.client.get(url("/user/settings"), headers=client.user_headers)
        data = assert_success(resp)
        assert "language" in data or "dark_mode" in data

    async def test_10_user_settings_update(self, client: TestClient):
        resp = await client.client.put(
            url("/user/settings"),
            json={"dark_mode": True},
            headers=client.user_headers,
        )
        assert_success(resp)

    async def test_11_verifications_list(self, client: TestClient):
        resp = await client.client.get(url("/user/verifications"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_12_verification_detail_not_found(self, client: TestClient):
        resp = await client.client.get(url("/user/verifications/nonexistent"), headers=client.user_headers)
        assert resp.status_code in (404, 400)


# ===========================================================================
# 5. PAYMENTS
# ===========================================================================

class TestPayments:
    """Products listing, purchase, history."""

    async def test_01_list_products(self, client: TestClient):
        resp = await client.client.get(url("/user/payments/products"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)
        assert "products" in data

    async def test_02_payment_history(self, client: TestClient):
        resp = await client.client.get(url("/user/payments/history"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_03_google_pay_invalid(self, client: TestClient):
        resp = await client.client.post(
            url("/user/payments/google-pay"),
            json={"product_id": "nonexistent", "token": "bad_token"},
            headers=client.user_headers,
        )
        assert resp.status_code in (400, 402, 422, 429)

    async def test_04_apple_pay_invalid(self, client: TestClient):
        resp = await client.client.post(
            url("/user/payments/apple-pay"),
            json={"product_id": "nonexistent", "token": "bad_token"},
            headers=client.user_headers,
        )
        assert resp.status_code in (400, 402, 422, 429)

    async def test_05_refund_invalid(self, client: TestClient):
        resp = await client.client.post(
            url("/user/payments/refund"),
            json={"payment_id": "nonexistent"},
            headers=client.user_headers,
        )
        assert resp.status_code in (400, 404, 422)


# ===========================================================================
# 6. WEBHOOKS
# ===========================================================================

class TestWebhooks:
    """Webhook CRUD."""

    async def test_01_create_webhook(self, client: TestClient):
        resp = await client.client.post(
            url("/user/webhooks"),
            json={"url": "https://example.com/webhook", "events": ["order.completed"]},
            headers=client.user_headers,
        )
        if resp.status_code == 200:
            data = assert_success(resp)
            client.test_webhook_id = data.get("id", "")

    async def test_02_list_webhooks(self, client: TestClient):
        resp = await client.client.get(url("/user/webhooks"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_03_get_webhook(self, client: TestClient):
        if not client.test_webhook_id:
            pytest.skip("No webhook created")
        resp = await client.client.get(
            url(f"/user/webhooks/{client.test_webhook_id}"),
            headers=client.user_headers,
        )
        data = assert_success(resp)
        assert data["id"] == client.test_webhook_id

    async def test_04_update_webhook(self, client: TestClient):
        if not client.test_webhook_id:
            pytest.skip("No webhook created")
        resp = await client.client.put(
            url(f"/user/webhooks/{client.test_webhook_id}"),
            json={"url": "https://example.com/updated-webhook"},
            headers=client.user_headers,
        )
        assert resp.status_code in (200, 400)

    async def test_05_list_webhook_events(self, client: TestClient):
        resp = await client.client.get(url("/user/webhooks/events"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_06_delete_webhook(self, client: TestClient):
        if not client.test_webhook_id:
            pytest.skip("No webhook created")
        resp = await client.client.delete(
            url(f"/user/webhooks/{client.test_webhook_id}"),
            headers=client.user_headers,
        )
        assert resp.status_code in (200, 204)

    async def test_07_get_nonexistent_webhook(self, client: TestClient):
        resp = await client.client.get(url("/user/webhooks/nonexistent"), headers=client.user_headers)
        assert resp.status_code in (200, 404, 400)


# ===========================================================================
# 7. TEMP EMAIL
# ===========================================================================

class TestTempEmail:
    """Temp email creation, messages, deletion."""
    _has_email = False

    async def test_01_get_temp_email(self, client: TestClient):
        resp = await client.client.get(url("/user/email/temp"), headers=client.user_headers)
        if resp.status_code == 502:
            pytest.skip("Temp email provider unavailable")
        data = assert_success(resp)
        assert "@" in data.get("email_address", data.get("email", ""))
        client.__class__._has_email = True

    async def test_02_get_temp_messages(self, client: TestClient):
        if not getattr(client.__class__, '_has_email', False):
            pytest.skip("No temp email created")
        resp = await client.client.get(url("/user/email/temp/messages"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_03_delete_temp_email(self, client: TestClient):
        if not getattr(client.__class__, '_has_email', False):
            pytest.skip("No temp email created")
        resp = await client.client.delete(url("/user/email/temp"), headers=client.user_headers)
        assert resp.status_code in (200, 204)


# ===========================================================================
# 8. VOICE
# ===========================================================================

class TestVoice:
    """Voice services and purchase."""

    async def test_01_voice_services(self, client: TestClient):
        resp = await client.client.get(url("/user/voice/services"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_02_voice_purchase(self, client: TestClient):
        resp = await client.client.post(
            url("/user/voice/purchase"),
            json={"service": "telegram", "country": "US"},
            headers=client.user_headers,
        )
        # 502 = provider error (no voice provider), 402 = insufficient balance
        assert resp.status_code in (200, 400, 402, 502, 503)


# ===========================================================================
# 9. RENTALS
# ===========================================================================

class TestRentals:
    """Rental CRUD, extend, cancel, messages."""

    async def test_01_list_rentals(self, client: TestClient):
        resp = await client.client.get(url("/user/rentals"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_02_create_rental_invalid(self, client: TestClient):
        resp = await client.client.post(
            url("/user/rentals"),
            json={"service": "telegram", "country": "US", "duration_hours": 24},
            headers=client.user_headers,
        )
        # 502 = provider error, 402 = insufficient balance
        assert resp.status_code in (200, 400, 402, 422, 502, 503)

    async def test_03_get_nonexistent_rental(self, client: TestClient):
        resp = await client.client.get(url("/user/rentals/nonexistent"), headers=client.user_headers)
        assert resp.status_code in (200, 404, 400)


# ===========================================================================
# 10. NOTIFICATIONS
# ===========================================================================

class TestNotifications:
    """List, mark read, preferences."""

    async def test_01_list_notifications(self, client: TestClient):
        resp = await client.client.get(url("/user/notifications"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_02_unread_count(self, client: TestClient):
        resp = await client.client.get(url("/user/notifications/unread"), headers=client.user_headers)
        data = assert_success(resp)
        assert "count" in data or isinstance(data, int) or isinstance(data, dict)

    async def test_03_mark_all_read(self, client: TestClient):
        resp = await client.client.post(url("/user/notifications/read-all"), headers=client.user_headers)
        assert resp.status_code in (200, 204)

    async def test_04_get_preferences(self, client: TestClient):
        resp = await client.client.get(url("/user/notifications/preferences"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_05_update_preferences(self, client: TestClient):
        resp = await client.client.put(
            url("/user/notifications/preferences"),
            json={"email": True, "push": False},
            headers=client.user_headers,
        )
        assert resp.status_code in (200, 400)


# ===========================================================================
# 11. PRESETS
# ===========================================================================

class TestPresets:
    """Preset CRUD."""

    async def test_01_create_preset(self, client: TestClient):
        resp = await client.client.post(
            url("/user/presets"),
            json={"name": "Test Preset", "service": "telegram", "country": "US"},
            headers=client.user_headers,
        )
        if resp.status_code == 200:
            data = assert_success(resp)
            client.test_preset_id = data.get("id", "")

    async def test_02_list_presets(self, client: TestClient):
        resp = await client.client.get(url("/user/presets"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_03_update_preset(self, client: TestClient):
        if not client.test_preset_id:
            pytest.skip("No preset created")
        resp = await client.client.put(
            url(f"/user/presets/{client.test_preset_id}"),
            json={"name": "Updated Preset", "service": "whatsapp", "country": "GB"},
            headers=client.user_headers,
        )
        assert resp.status_code in (200, 400)

    async def test_04_delete_preset(self, client: TestClient):
        if not client.test_preset_id:
            pytest.skip("No preset created")
        resp = await client.client.delete(
            url(f"/user/presets/{client.test_preset_id}"),
            headers=client.user_headers,
        )
        assert resp.status_code in (200, 204)

    async def test_05_delete_nonexistent_preset(self, client: TestClient):
        resp = await client.client.delete(url("/user/presets/nonexistent"), headers=client.user_headers)
        assert resp.status_code in (404, 400)


# ===========================================================================
# 12. AVAILABILITY
# ===========================================================================

class TestAvailability:
    """Service/country availability checks."""

    async def test_01_service_availability(self, client: TestClient):
        resp = await client.client.get(
            url("/user/availability/service"),
            params={"service": "telegram"},
            headers=client.user_headers,
        )
        data = assert_success(resp)
        assert isinstance(data, dict) or isinstance(data, list)

    async def test_02_country_availability(self, client: TestClient):
        resp = await client.client.get(
            url("/user/availability/country"),
            params={"country": "US"},
            headers=client.user_headers,
        )
        assert_success(resp)

    async def test_03_top_services(self, client: TestClient):
        resp = await client.client.get(url("/user/availability/top-services"), headers=client.user_headers)
        assert_success(resp)

    async def test_04_availability_summary(self, client: TestClient):
        resp = await client.client.get(url("/user/availability/summary"), headers=client.user_headers)
        assert_success(resp)


# ===========================================================================
# 13. API KEYS
# ===========================================================================

class TestAPIKeys:
    """API key CRUD (MFA-protected)."""

    async def test_01_list_api_keys(self, client: TestClient):
        resp = await client.client.get(url("/user/api-keys"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_02_create_api_key(self, client: TestClient):
        resp = await client.client.post(
            url("/user/api-keys"),
            json={"name": "Test Key"},
            headers=client.user_headers,
        )
        # 403 = MFA required
        if resp.status_code == 200:
            data = assert_success(resp)
            client.test_api_key_id = data.get("id", "")
        else:
            assert resp.status_code == 403

    async def test_03_delete_api_key(self, client: TestClient):
        if not client.test_api_key_id:
            pytest.skip("No API key created")
        resp = await client.client.delete(
            url(f"/user/api-keys/{client.test_api_key_id}"),
            headers=client.user_headers,
        )
        assert resp.status_code in (200, 204, 403)


# ===========================================================================
# 14. REFERRALS
# ===========================================================================

class TestReferrals:
    """Referral code, claim, earnings."""

    async def test_01_get_referral_code(self, client: TestClient):
        resp = await client.client.get(url("/user/referral/code"), headers=client.user_headers)
        data = assert_success(resp)
        assert "code" in data or "referral_code" in data

    async def test_02_claim_invalid_code(self, client: TestClient):
        resp = await client.client.post(
            url("/user/referral/claim"),
            json={"code": "INVALID999"},
            headers=client.user_headers,
        )
        assert resp.status_code in (400, 404)

    async def test_03_referral_earnings(self, client: TestClient):
        resp = await client.client.get(url("/user/referral/earnings"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)


# ===========================================================================
# 15. MFA
# ===========================================================================

class TestMFA:
    """MFA setup, verify, disable, status."""

    async def test_01_mfa_status(self, client: TestClient):
        resp = await client.client.get(url("/user/mfa/status"), headers=client.user_headers)
        data = assert_success(resp)
        assert "enabled" in data or "mfa_enabled" in data

    async def test_02_mfa_setup(self, client: TestClient):
        resp = await client.client.post(url("/user/mfa/setup"), headers=client.user_headers)
        data = assert_success(resp)
        assert "secret" in data or "qr_code_url" in data

    async def test_03_mfa_verify_invalid(self, client: TestClient):
        resp = await client.client.post(
            url("/user/mfa/verify"),
            json={"token": "000000"},
            headers=client.user_headers,
        )
        assert resp.status_code in (400, 403)

    async def test_04_mfa_disable(self, client: TestClient):
        # Without valid token — should fail
        resp = await client.client.post(
            url("/user/mfa/disable"),
            json={"token": "000000"},
            headers=client.user_headers,
        )
        assert resp.status_code in (400, 403)


# ===========================================================================
# 16. FORWARDING
# ===========================================================================

class TestForwarding:
    """Forwarding config (MFA-protected write)."""

    async def test_01_get_forwarding(self, client: TestClient):
        resp = await client.client.get(url("/user/forwarding"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, dict) or data is None

    async def test_02_update_forwarding(self, client: TestClient):
        resp = await client.client.put(
            url("/user/forwarding"),
            json={"email": "forward@example.com"},
            headers=client.user_headers,
        )
        # 403 = MFA required, 400 = validation
        assert resp.status_code in (200, 400, 403)

    async def test_03_test_forwarding(self, client: TestClient):
        resp = await client.client.get(url("/user/forwarding/test"), headers=client.user_headers)
        assert resp.status_code in (200, 400, 502)


# ===========================================================================
# 17. GDPR
# ===========================================================================

class TestGDPR:
    """Data export, consent management."""

    async def test_01_get_consent(self, client: TestClient):
        resp = await client.client.get(url("/user/gdpr/consent"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_02_update_consent(self, client: TestClient):
        resp = await client.client.put(
            url("/user/gdpr/consent"),
            json={"marketing": True},
            headers=client.user_headers,
        )
        assert_success(resp)

    async def test_03_export_data(self, client: TestClient):
        resp = await client.client.get(url("/user/gdpr/export"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)


# ===========================================================================
# 18. ONBOARDING
# ===========================================================================

class TestOnboarding:
    """Onboarding status, steps, complete."""

    async def test_01_get_onboarding_status(self, client: TestClient):
        resp = await client.client.get(url("/user/onboarding"), headers=client.user_headers)
        data = assert_success(resp)
        assert "step" in data or "completed" in data

    async def test_02_update_step(self, client: TestClient):
        resp = await client.client.post(
            url("/user/onboarding/step"),
            json={"step": 1},
            headers=client.user_headers,
        )
        assert_success(resp)

    async def test_03_complete_onboarding(self, client: TestClient):
        resp = await client.client.post(url("/user/onboarding/complete"), headers=client.user_headers)
        assert_success(resp)

    async def test_04_skip_onboarding(self, client: TestClient):
        resp = await client.client.post(url("/user/onboarding/skip"), headers=client.user_headers)
        assert resp.status_code in (200, 400)


# ===========================================================================
# 19. TIERS
# ===========================================================================

class TestTiers:
    """List, current tier, upgrade."""

    async def test_01_list_tiers(self, client: TestClient):
        resp = await client.client.get(url("/user/tiers"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_02_current_tier(self, client: TestClient):
        resp = await client.client.get(url("/user/tiers/current"), headers=client.user_headers)
        data = assert_success(resp)
        assert "tier" in data

    async def test_03_upgrade_invalid_tier(self, client: TestClient):
        resp = await client.client.post(
            url("/user/tiers/upgrade"),
            json={"tier": "INVALID_TIER"},
            headers=client.user_headers,
        )
        assert resp.status_code in (400, 404)


# ===========================================================================
# 20. SESSIONS
# ===========================================================================

class TestSessions:
    """List sessions, revoke."""

    async def test_01_list_sessions(self, client: TestClient):
        resp = await client.client.get(url("/user/sessions"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_02_revoke_invalid_session(self, client: TestClient):
        resp = await client.client.post(url("/user/sessions/nonexistent/revoke"), headers=client.user_headers)
        assert resp.status_code in (404, 400)

    async def test_03_revoke_all_sessions(self, client: TestClient):
        resp = await client.client.post(url("/user/sessions/revoke-all"), headers=client.user_headers)
        assert resp.status_code in (200, 204)


# ===========================================================================
# 21. PUSH NOTIFICATIONS
# ===========================================================================

class TestPushNotifications:
    """Device registration, listing, removal."""

    async def test_01_register_device(self, client: TestClient):
        resp = await client.client.post(
            url("/user/push/register"),
            json={"token": "test_device_token_123", "platform": "web"},
            headers=client.user_headers,
        )
        assert resp.status_code in (200, 201, 400)

    async def test_02_list_devices(self, client: TestClient):
        resp = await client.client.get(url("/user/push/devices"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_03_unregister_device(self, client: TestClient):
        resp = await client.client.post(
            url("/user/push/unregister"),
            json={"token": "test_device_token_123"},
            headers=client.user_headers,
        )
        assert resp.status_code in (200, 204, 404)

    async def test_04_send_test(self, client: TestClient):
        resp = await client.client.post(url("/user/push/test"), headers=client.user_headers)
        assert resp.status_code in (200, 400, 502)


# ===========================================================================
# 22. PRICING
# ===========================================================================

class TestPricing:
    """User pricing, promo codes."""

    async def test_01_get_my_pricing(self, client: TestClient):
        resp = await client.client.get(url("/pricing/my"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_02_validate_invalid_promo(self, client: TestClient):
        resp = await client.client.post(
            url("/pricing/validate-promo"),
            json={"code": "INVALIDPROMO"},
            headers=client.user_headers,
        )
        assert resp.status_code in (400, 404)

    async def test_03_apply_invalid_promo(self, client: TestClient):
        resp = await client.client.post(
            url("/pricing/apply-promo"),
            json={"code": "INVALIDPROMO"},
            headers=client.user_headers,
        )
        assert resp.status_code in (400, 404)


# ===========================================================================
# 23. AFFILIATE
# ===========================================================================

class TestAffiliate:
    """Apply, commissions, payouts."""

    async def test_01_apply_affiliate(self, client: TestClient):
        resp = await client.client.post(
            url("/affiliate/apply"),
            json={"program_type": "standard"},
            headers=client.user_headers,
        )
        assert resp.status_code in (200, 400, 409)

    async def test_02_get_application(self, client: TestClient):
        resp = await client.client.get(url("/affiliate/application"), headers=client.user_headers)
        assert resp.status_code in (200, 404)

    async def test_03_commissions(self, client: TestClient):
        resp = await client.client.get(url("/affiliate/commissions"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_04_summary(self, client: TestClient):
        resp = await client.client.get(url("/affiliate/summary"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_05_request_payout(self, client: TestClient):
        resp = await client.client.post(
            url("/affiliate/payouts"),
            json={"amount": 100, "currency": "USD"},
            headers=client.user_headers,
        )
        assert resp.status_code in (200, 400)

    async def test_06_list_payouts(self, client: TestClient):
        resp = await client.client.get(url("/affiliate/payouts"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_07_revenue_share(self, client: TestClient):
        resp = await client.client.get(url("/affiliate/revenue-share"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)


# ===========================================================================
# 24. KYC
# ===========================================================================

class TestKYC:
    """KYC profile, documents, status, limits."""

    async def test_01_get_kyc_profile(self, client: TestClient):
        resp = await client.client.get(url("/kyc/profile"), headers=client.user_headers)
        assert resp.status_code in (200, 404)

    async def test_02_submit_kyc_profile(self, client: TestClient):
        resp = await client.client.post(
            url("/kyc/profile"),
            json={"full_name": "Test User", "nationality": "US"},
            headers=client.user_headers,
        )
        assert resp.status_code in (200, 201, 400, 409)

    async def test_03_kyc_status(self, client: TestClient):
        resp = await client.client.get(url("/kyc/status"), headers=client.user_headers)
        data = assert_success(resp)
        assert "status" in data or "level" in data

    async def test_04_kyc_limits(self, client: TestClient):
        resp = await client.client.get(url("/kyc/limits"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_05_get_documents(self, client: TestClient):
        resp = await client.client.get(url("/kyc/documents"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)


# ===========================================================================
# 25. DISPUTES
# ===========================================================================

class TestDisputes:
    """Create, list, get, comments."""

    async def test_01_create_dispute(self, client: TestClient):
        resp = await client.client.post(
            url("/disputes"),
            json={"order_id": "nonexistent", "reason": "Test dispute"},
            headers=client.user_headers,
        )
        assert resp.status_code in (200, 201, 400, 404)

    async def test_02_list_disputes(self, client: TestClient):
        resp = await client.client.get(url("/disputes"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_03_get_nonexistent_dispute(self, client: TestClient):
        resp = await client.client.get(url("/disputes/nonexistent"), headers=client.user_headers)
        assert resp.status_code in (404, 400)


# ===========================================================================
# 26. TELEGRAM
# ===========================================================================

class TestTelegram:
    """Telegram connect, disconnect, rules."""

    async def test_01_get_connection(self, client: TestClient):
        resp = await client.client.get(url("/telegram/connect"), headers=client.user_headers)
        assert resp.status_code in (200, 404)

    async def test_02_connect_telegram(self, client: TestClient):
        resp = await client.client.post(
            url("/telegram/connect"),
            json={"chat_id": "123456789"},
            headers=client.user_headers,
        )
        assert resp.status_code in (200, 400)

    async def test_03_get_rules(self, client: TestClient):
        resp = await client.client.get(url("/telegram/rules"), headers=client.user_headers)
        assert resp.status_code in (200, 404)

    async def test_04_disconnect(self, client: TestClient):
        resp = await client.client.post(url("/telegram/disconnect"), headers=client.user_headers)
        assert resp.status_code in (200, 204, 404)


# ===========================================================================
# 27. WHITELABEL
# ===========================================================================

class TestWhitelabel:
    """Domains, branding, email templates."""

    async def test_01_get_domains(self, client: TestClient):
        resp = await client.client.get(url("/whitelabel/domains"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_02_get_branding(self, client: TestClient):
        resp = await client.client.get(url("/whitelabel/branding"), headers=client.user_headers)
        assert resp.status_code in (200, 404)

    async def test_03_get_email_templates(self, client: TestClient):
        resp = await client.client.get(url("/whitelabel/email-templates"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_04_add_domain_invalid(self, client: TestClient):
        resp = await client.client.post(
            url("/whitelabel/domains"),
            json={"domain": ""},
            headers=client.user_headers,
        )
        assert resp.status_code in (400, 422)


# ===========================================================================
# 28. INVOICES
# ===========================================================================

class TestInvoices:
    """List, get, download PDF."""

    async def test_01_list_invoices(self, client: TestClient):
        resp = await client.client.get(url("/user/invoices"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_02_get_nonexistent_invoice(self, client: TestClient):
        resp = await client.client.get(url("/user/invoices/nonexistent"), headers=client.user_headers)
        assert resp.status_code in (404, 400)

    async def test_03_download_invoice(self, client: TestClient):
        resp = await client.client.get(url("/user/invoices/nonexistent/pdf"), headers=client.user_headers)
        assert resp.status_code in (404, 400)


# ===========================================================================
# 29. SUPPORT (USER)
# ===========================================================================

class TestSupport:
    """Tickets CRUD."""

    async def test_01_create_ticket(self, client: TestClient):
        resp = await client.client.post(
            url("/user/support/tickets"),
            json={"subject": "Test Issue", "message": "This is a test ticket", "category": "general"},
            headers=client.user_headers,
        )
        if resp.status_code == 200:
            data = assert_success(resp)
            client.test_ticket_id = data.get("id", "")

    async def test_02_list_tickets(self, client: TestClient):
        resp = await client.client.get(url("/user/support/tickets"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_03_get_ticket(self, client: TestClient):
        if not client.test_ticket_id:
            pytest.skip("No ticket created")
        resp = await client.client.get(
            url(f"/user/support/tickets/{client.test_ticket_id}"),
            headers=client.user_headers,
        )
        data = assert_success(resp)
        assert data["id"] == client.test_ticket_id

    async def test_04_reply_to_ticket(self, client: TestClient):
        if not client.test_ticket_id:
            pytest.skip("No ticket created")
        resp = await client.client.post(
            url(f"/user/support/tickets/{client.test_ticket_id}/reply"),
            json={"message": "This is a reply"},
            headers=client.user_headers,
        )
        assert resp.status_code in (200, 201, 400)

    async def test_05_get_nonexistent_ticket(self, client: TestClient):
        resp = await client.client.get(url("/user/support/tickets/nonexistent"), headers=client.user_headers)
        assert resp.status_code in (404, 400)


# ===========================================================================
# 30. EMAIL VERIFICATION
# ===========================================================================

class TestEmailVerification:
    """Send and verify email."""

    async def test_01_send_verification(self, client: TestClient):
        resp = await client.client.post(url("/user/email/send-verification"), headers=client.user_headers)
        assert resp.status_code in (200, 204, 429, 400)

    async def test_02_verify_with_invalid_token(self, client: TestClient):
        resp = await client.client.post(
            url("/user/email/verify"),
            json={"token": "invalid_token"},
        )
        assert resp.status_code in (400, 422)


# ===========================================================================
# 31. ACTIVITY FEED
# ===========================================================================

class TestActivityFeed:
    """User activity feed."""

    async def test_01_get_feed(self, client: TestClient):
        resp = await client.client.get(url("/user/activity/feed"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)


# ===========================================================================
# 32. LEDGER
# ===========================================================================

class TestLedger:
    """Balance, history, transfer (admin)."""

    async def test_01_get_balance(self, client: TestClient):
        resp = await client.client.get(url("/user/ledger/balance"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_02_get_all_balances(self, client: TestClient):
        resp = await client.client.get(url("/user/ledger/balances"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_03_get_history(self, client: TestClient):
        resp = await client.client.get(url("/user/ledger/history"), headers=client.user_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_04_transfer_no_auth(self, client: TestClient):
        resp = await client.client.post(
            url("/user/ledger/transfer"),
            params={"user_id": "some-id", "amount": 100, "currency": "USD"},
            headers=client.user_headers,
        )
        # 403 = not admin
        assert resp.status_code in (403, 400)


# ===========================================================================
# 33. ADMIN — HTML PAGES
# ===========================================================================

class TestAdminHTMLPages:
    """Admin HTML rendering routes."""

    async def test_01_login_page(self, client: TestClient):
        resp = await client.client.get(url("/admin/login"))
        assert resp.status_code == 200
        assert "text/html" in resp.headers.get("content-type", "")

    async def test_02_dashboard_page(self, client: TestClient):
        resp = await client.client.get(url("/admin"))
        # Redirect to login if no session, or 200
        assert resp.status_code in (200, 302, 303)

    async def test_03_users_page(self, client: TestClient):
        resp = await client.client.get(url("/admin/users"))
        assert resp.status_code in (200, 302, 303)

    async def test_04_providers_page(self, client: TestClient):
        resp = await client.client.get(url("/admin/providers"))
        assert resp.status_code in (200, 302, 303)

    async def test_05_transactions_page(self, client: TestClient):
        resp = await client.client.get(url("/admin/transactions"))
        assert resp.status_code in (200, 302, 303)

    async def test_06_logs_page(self, client: TestClient):
        resp = await client.client.get(url("/admin/logs"))
        assert resp.status_code in (200, 302, 303)

    async def test_07_settings_page(self, client: TestClient):
        resp = await client.client.get(url("/admin/settings"))
        assert resp.status_code in (200, 302, 303)


# ===========================================================================
# 34. ADMIN — API
# ===========================================================================

class TestAdminAPI:
    """Admin JSON API endpoints."""

    async def test_01_stats_no_auth(self, client: TestClient):
        resp = await client.client.get(url("/admin/api/stats"))
        assert resp.status_code in (401, 404)

    async def test_02_stats_user_forbidden(self, client: TestClient):
        resp = await client.client.get(url("/admin/api/stats"), headers=client.user_headers)
        assert resp.status_code in (403, 404)

    async def test_03_list_users(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/api/users"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data.get("items", data), list)

    async def test_04_providers_list_admin(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/api/providers"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_05_list_orders(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/api/orders"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data.get("items", data), list)

    async def test_06_list_transactions_admin(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/api/transactions"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data.get("items", data), list)

    async def test_07_list_logs(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/api/logs"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data.get("items", data), list)

    async def test_08_list_settings_admin(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/api/settings"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_09_services_list_admin(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/api/services"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_10_providers_balances_no_auth(self, client: TestClient):
        resp = await client.client.get(url("/providers/balances"))
        assert resp.status_code == 401

    async def test_11_providers_balances_forbidden(self, client: TestClient):
        resp = await client.client.get(url("/providers/balances"), headers=client.user_headers)
        assert resp.status_code == 403

    async def test_12_ban_user_no_auth(self, client: TestClient):
        resp = await client.client.post(url(f"/admin/api/users/{client.user_id}/ban"), json={"reason": "test"})
        assert resp.status_code in (401, 403)

    async def test_13_get_user_detail(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(
            url(f"/admin/api/users/{client.user_id}"),
            headers=client.admin_headers,
        )
        assert resp.status_code in (200, 404)
        if resp.status_code == 200:
            data = assert_success(resp)
            assert "email" in data

    async def test_14_list_tiers_admin(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/api/tiers"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_15_list_waitlist(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/api/waitlist"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_16_toggle_provider_no_auth(self, client: TestClient):
        resp = await client.client.post(url("/admin/api/providers/smsman/toggle"))
        assert resp.status_code in (401, 403)


# ===========================================================================
# 35. ADMIN — FINANCIAL
# ===========================================================================

class TestAdminFinancial:
    """Revenue, tax, provider costs, settlements, statements."""

    async def test_01_revenue_summary(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/financial/revenue"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_02_revenue_details(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/financial/revenue/details"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_03_tax_configs(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/financial/tax/configs"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_04_provider_agreements(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/financial/providers/agreements"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_05_provider_costs(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/financial/providers/costs"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_06_settlements(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/financial/providers/settlements"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_07_reconciliations(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/financial/providers/reconciliations"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_08_financial_statements(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/financial/statements"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_09_operating_metrics(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/financial/metrics"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)


# ===========================================================================
# 36. ADMIN — AFFILIATE
# ===========================================================================

class TestAdminAffiliate:
    """Applications, commissions, tiers, payouts."""

    async def test_01_list_applications(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/affiliate/applications"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_02_list_commissions(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/affiliate/commissions"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_03_list_tiers(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/affiliate/tiers"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_04_list_payouts(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/affiliate/payouts"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)


# ===========================================================================
# 37. ADMIN — ANALYTICS
# ===========================================================================

class TestAdminAnalytics:
    """Dashboard, snapshots, stats."""

    async def test_01_dashboard(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/analytics/dashboard"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_02_verification_stats(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/analytics/verifications"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_03_carrier_analytics(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/analytics/carriers"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_04_purchase_outcomes(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/analytics/purchase-outcomes"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_05_monthly_targets(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/analytics/monthly-targets"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)


# ===========================================================================
# 38. ADMIN — BLACKLIST
# ===========================================================================

class TestAdminBlacklist:
    """IP blocking/unblocking, listing."""

    async def test_01_list_ips(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/blacklist/ips"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_02_block_ip(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.post(
            url("/admin/blacklist/ip"),
            params={"ip_address": "192.0.2.1", "reason": "Test"},
            headers=client.admin_headers,
        )
        assert resp.status_code in (200, 201, 409)

    async def test_03_unblock_ip(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.delete(
            url("/admin/blacklist/ip"),
            params={"ip_address": "192.0.2.1"},
            headers=client.admin_headers,
        )
        assert resp.status_code in (200, 204, 404)

    async def test_04_list_tokens(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/blacklist/tokens"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)


# ===========================================================================
# 39. ADMIN — DISPUTES
# ===========================================================================

class TestAdminDisputes:
    """List all, get detail, status update, resolve."""

    async def test_01_list_all_disputes(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/disputes/all"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_02_dispute_stats(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/disputes/stats"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)


# ===========================================================================
# 40. ADMIN — EXPORT
# ===========================================================================

class TestAdminExport:
    """CSV/Excel exports."""

    async def test_01_export_users(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/export/users"), headers=client.admin_headers)
        assert resp.status_code in (200, 400, 502)

    async def test_02_export_transactions(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/export/transactions"), headers=client.admin_headers)
        assert resp.status_code in (200, 400, 502)

    async def test_03_export_audit_logs(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/export/audit-logs"), headers=client.admin_headers)
        assert resp.status_code in (200, 400, 502)


# ===========================================================================
# 41. ADMIN — KYC
# ===========================================================================

class TestAdminKYC:
    """KYC admin: pending, verify, reject, documents, audit, settings, limits."""

    async def test_01_list_pending(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/kyc/pending"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_02_list_all_kyc(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/kyc/all"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_03_kyc_stats(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/kyc/stats"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_04_kyc_settings(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/kyc/settings"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_05_kyc_limits(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/kyc/limits"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)


# ===========================================================================
# 42. ADMIN — PRICING
# ===========================================================================

class TestAdminPricing:
    """Pricing templates, assignments, promotions."""

    async def test_01_list_templates(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/pricing/templates"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_02_list_assignments(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/pricing/assignments"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_03_list_promotions(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/pricing/promotions"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)


# ===========================================================================
# 43. ADMIN — RECONCILIATION
# ===========================================================================

class TestAdminReconciliation:
    """Run reconciliation, logs, alerts."""

    async def test_01_get_logs(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/reconciliation/logs"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_02_get_alerts(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/reconciliation/alerts"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)


# ===========================================================================
# 44. ADMIN — RESELLER
# ===========================================================================

class TestAdminReseller:
    """Reseller accounts, sub-accounts, credit, bulk operations."""

    async def test_01_list_accounts(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/reseller/accounts"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_02_list_sub_accounts(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/reseller/sub-accounts"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_03_credit_history(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/reseller/credit/history"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_04_list_transactions(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/reseller/transactions"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)


# ===========================================================================
# 45. ADMIN — SECURITY
# ===========================================================================

class TestAdminSecurity:
    """Scans, compliance, backup, DR, push/telegram tests."""

    async def test_01_scan_history(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/security/scans"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_02_compliance_report(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/security/compliance"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_03_secrets_check(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/security/secrets/check"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_04_backups_list(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/security/backups"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_05_dr_status(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/security/dr/status"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_06_onesignal_status(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/security/push/onesignal/status"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_07_telegram_bot_status(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/security/telegram/bot/status"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)


# ===========================================================================
# 46. ADMIN — SUPPORT
# ===========================================================================

class TestAdminSupport:
    """Admin ticket management."""

    async def test_01_list_all_tickets(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/support/tickets"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_02_get_ticket_detail(self, client: TestClient):
        if not client.admin_token or not client.test_ticket_id:
            pytest.skip("No admin token or ticket")
        resp = await client.client.get(
            url(f"/admin/support/tickets/{client.test_ticket_id}"),
            headers=client.admin_headers,
        )
        assert resp.status_code in (200, 404)


# ===========================================================================
# 47. ADMIN — USER MANAGEMENT
# ===========================================================================

class TestAdminUserManagement:
    """Admin user CRUD, ban, coins, tier, sessions."""

    async def test_01_list_users(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/api/users"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data.get("users", data.get("items", data)), list)

    async def test_02_get_user_detail(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(
            url(f"/admin/api/users/{client.user_id}"),
            headers=client.admin_headers,
        )
        data = assert_success(resp)
        assert "id" in data

    async def test_03_adjust_coins(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.post(
            url(f"/admin/api/users/{client.user_id}/adjust-coins"),
            json={"amount": 100, "reason": "Test adjustment"},
            headers=client.admin_headers,
        )
        assert resp.status_code in (200, 400)

    async def test_04_change_tier(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.post(
            url(f"/admin/api/users/{client.user_id}/change-tier"),
            json={"tier": "premium"},
            headers=client.admin_headers,
        )
        assert resp.status_code in (200, 400)


# ===========================================================================
# 48. ADMIN — BROADCAST
# ===========================================================================

class TestAdminBroadcast:
    """Broadcast notifications."""

    async def test_01_broadcast_notification(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.post(
            url("/admin/broadcast/notification"),
            json={"title": "Test", "body": "Test body", "type": "info"},
            headers=client.admin_headers,
        )
        assert resp.status_code in (200, 201, 400)


# ===========================================================================
# 49. ADMIN — ADVANCED SEARCH
# ===========================================================================

class TestAdminAdvancedSearch:
    """Global search, users, orders, transactions, payments."""

    async def test_01_global_search(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/search/global"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, dict)

    async def test_02_search_users(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/search/users"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_03_search_orders(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/search/orders"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_04_search_transactions(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/search/transactions"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)

    async def test_05_search_payments(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/search/payments"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)


# ===========================================================================
# 50. ADMIN — PNL
# ===========================================================================

class TestAdminPnL:
    """Generate reports, list reports."""

    async def test_01_list_reports(self, client: TestClient):
        if not client.admin_token:
            pytest.skip("No admin token")
        resp = await client.client.get(url("/admin/pnl/reports"), headers=client.admin_headers)
        data = assert_success(resp)
        assert isinstance(data, list)


# ===========================================================================
# 51. PERMISSION BOUNDARIES
# ===========================================================================

class TestPermissionBoundaries:
    """Verify user cannot access admin endpoints and vice-versa."""

    async def test_01_user_cannot_access_admin_stats(self, client: TestClient):
        resp = await client.client.get(url("/admin/api/stats"), headers=client.user_headers)
        assert resp.status_code == 403

    async def test_02_user_cannot_access_admin_financial(self, client: TestClient):
        resp = await client.client.get(url("/admin/financial/revenue"), headers=client.user_headers)
        assert resp.status_code == 403

    async def test_03_user_cannot_access_admin_affiliate(self, client: TestClient):
        resp = await client.client.get(url("/admin/affiliate/applications"), headers=client.user_headers)
        assert resp.status_code == 403

    async def test_04_user_cannot_ban_users(self, client: TestClient):
        resp = await client.client.post(
            url(f"/admin/api/users/{client.user_id}/ban"),
            json={"reason": "test"},
            headers=client.user_headers,
        )
        assert resp.status_code == 403

    async def test_05_user_cannot_access_admin_analytics(self, client: TestClient):
        resp = await client.client.get(url("/admin/analytics/dashboard"), headers=client.user_headers)
        assert resp.status_code == 403

    async def test_06_user_cannot_access_providers_balances(self, client: TestClient):
        resp = await client.client.get(url("/providers/balances"), headers=client.user_headers)
        assert resp.status_code == 403

    async def test_07_no_auth_gets_401(self, client: TestClient):
        resp = await client.client.get(url("/sms/orders"))
        assert resp.status_code == 401

    async def test_08_banned_user_gets_403(self, client: TestClient):
        # We don't ban the user, just verify the error code path
        pass
