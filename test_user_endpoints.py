import asyncio
import httpx
import sys
import random
import string

BASE = "http://localhost:9527/stroapp/v1"
TOKEN = None
REFRESH_TOKEN = None
USER_ID = None
TEST_EMAIL = f"test_{random.randint(10000, 99999)}@test.com"
TEST_PASSWORD = "StrongP@ss123"

results = {"pass": 0, "fail": 0, "errors": []}
created_ids = {}


async def test(name: str, method: str, path: str, **kwargs):
    global TOKEN
    url = f"{BASE}{path}"
    headers = kwargs.pop("headers", {})
    if TOKEN:
        headers["Authorization"] = f"Bearer {TOKEN}"
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.request(method, url, headers=headers, **kwargs)
            sc = resp.status_code
            if sc >= 500:
                raise Exception(f"HTTP {sc}: {resp.text[:300]}")
            results["pass"] += 1
            try:
                data = resp.json() if resp.text.strip() else {}
            except Exception:
                data = {}
            if isinstance(data, dict):
                inner = data.get("data")
                if isinstance(inner, dict):
                    for key in ("id", "order_id", "ticket_id", "webhook_id", "rule_id", "device_id", "secret"):
                        if inner.get(key):
                            return inner
                return data
            return data or {}
    except Exception as e:
        results["fail"] += 1
        msg = f"{method} {path}: {e}"
        results["errors"].append(msg)
        print(f"  ✗ {msg}")
        return {}


async def main():
    global TOKEN, REFRESH_TOKEN, USER_ID

    print("=" * 70)
    print("📋 StroApp User Endpoints Test Suite")
    print("=" * 70)
    print(f"Test User: {TEST_EMAIL}\n")

    # ── 1. REGISTER ──
    print("─── 1. التسجيل (Register) ───")
    r = await test("register", "POST", "/user/auth/register",
                   data={"email": TEST_EMAIL, "password": TEST_PASSWORD, "display_name": "Test User"})
    if r:
        print(f"  ✓ register: {TEST_EMAIL}")

    # ── 2. LOGIN ──
    print("\n─── 2. تسجيل الدخول (Login) ───")
    r = await test("login", "POST", "/user/auth/login",
                   data={"email": TEST_EMAIL, "password": TEST_PASSWORD})
    if r and r.get("data"):
        TOKEN = r["data"].get("access_token", "")
        REFRESH_TOKEN = r["data"].get("refresh_token", "")
        USER_ID = r["data"].get("user", {}).get("id", "")
        print(f"  ✓ login: token={TOKEN[:20]}...")

    if not TOKEN:
        print("✗ فشل تسجيل الدخول، إلغاء باقي الاختبارات")
        return

    # ── 3. AUTH ENDPOINTS ──
    print("\n─── 3. المصادقة (Auth) ───")
    await test("google config", "GET", "/user/auth/google/config")
    await test("refresh", "POST", "/user/auth/refresh",
               json={"refresh_token": REFRESH_TOKEN})
    await test("auth me", "GET", "/user/auth/me")
    await test("google signin invalid", "POST", "/user/auth/google",
               json={"id_token": "invalid"})
    await test("apple signin invalid", "POST", "/user/auth/apple",
               json={"identity_token": "invalid"})

    # ── 4. USER PROFILE ──
    print("\n─── 4. الملف الشخصي (Profile) ───")
    r = await test("profile", "GET", "/user/profile")
    if r and r.get("data"):
        created_ids["profile"] = r["data"]
    await test("update profile", "PUT", "/user/profile/update",
               data={"display_name": "Test Updated"})
    await test("balance", "GET", "/user/balance")
    await test("wallet", "GET", "/user/wallet")
    await test("transactions", "GET", "/user/transactions")

    # ── 5. SERVICES ──
    print("\n─── 5. الخدمات (Services) ───")
    r = await test("list services", "GET", "/services")
    data_field = r.get("data") if isinstance(r, dict) else r
    services = data_field if isinstance(data_field, list) else (data_field or [])
    svc_name = services[0]["name"] if services and isinstance(services[0], dict) else "telegram"
    print(f"  using service: {svc_name}")
    await test("countries", "GET", "/services/countries")
    await test("categories", "GET", "/services/categories")

    # ── 6. SMS ──
    print("\n─── 6. الشراء والطلبات (SMS) ───")
    await test("sms price", "GET", "/sms/price?service=telegram&country=US")
    await test("sms price all", "GET", "/sms/price/all?service=telegram&country=US")
    await test("orders list", "GET", "/sms/orders")

    # purchase (likely fails without real provider, but tests the flow)
    r = await test("purchase", "POST", "/sms/purchase",
                   json={"service": "telegram", "country": "US", "provider": "fivesim"})
    if r and r.get("data"):
        oid = r["data"].get("id") or r["data"].get("order_id")
        if oid:
            created_ids["order"] = oid
            await test("get order", "GET", f"/sms/orders/{oid}")
            await test("check order", "POST", f"/sms/orders/{oid}/check")

    # ── 7. VERIFICATIONS ──
    print("\n─── 7. التوثيقات (Verifications) ───")
    await test("verifications list", "GET", "/user/verifications")
    await test("verification not found", "GET", "/user/verifications/nonexistent")

    # ── 8. USER SERVICES ──
    print("\n─── 8. خدمات المستخدم ───")
    r = await test("user services countries", "GET", f"/user/services/{svc_name}/countries")
    await test("user service price", "GET", f"/user/services/{svc_name}/price?country=US")
    await test("user purchase", "POST", "/user/services/purchase",
               data={"service": "telegram", "country": "US", "provider": "fivesim"})
    await test("coins refund", "POST", "/user/coins/refund",
               data={"order_id": "nonexistent"})

    # ── 9. PROVIDERS ──
    print("\n─── 9. المزودين (Providers) ───")
    await test("list providers", "GET", "/providers")

    # ── 10. MFA ──
    print("\n─── 10. التحقق بخطوتين (MFA) ───")
    r = await test("mfa setup", "POST", "/user/mfa/setup")
    if r and r.get("data") and r["data"].get("secret"):
        secret = r["data"]["secret"]
        import pyotp
        totp = pyotp.TOTP(secret)
        valid_token = totp.now()
        await test("mfa verify", "POST", "/user/mfa/verify",
                   data={"token": valid_token})
        await test("mfa status", "GET", "/user/mfa/status")
        await test("mfa disable", "POST", "/user/mfa/disable",
                   data={"token": valid_token})

    # ── 11. SESSIONS ──
    print("\n─── 11. الجلسات (Sessions) ───")
    r = await test("list sessions", "GET", "/user/sessions")

    # ── 12. NOTIFICATIONS ──
    print("\n─── 12. الإشعارات (Notifications) ───")
    await test("list notifications", "GET", "/user/notifications")
    await test("unread count", "GET", "/user/notifications/unread")
    await test("read all", "POST", "/user/notifications/read-all")
    await test("preferences get", "GET", "/user/notifications/preferences")
    await test("preferences update", "PUT", "/user/notifications/preferences",
               json={"push_enabled": True, "email_enabled": False})

    # ── 13. WEBHOOKS ──
    print("\n─── 13. Webhooks ───")
    await test("webhook events", "GET", "/user/webhooks/events")
    r = await test("create webhook", "POST", "/user/webhooks",
                   json={"url": "https://example.com/webhook", "events": ["sms.completed"]})
    wh_id = ((r or {}).get("data") or {}).get("id")
    if wh_id:
        created_ids["webhook"] = wh_id
        await test("list webhooks", "GET", "/user/webhooks")
        await test("get webhook", "GET", f"/user/webhooks/{wh_id}")
        await test("update webhook", "PUT", f"/user/webhooks/{wh_id}",
                   json={"is_active": False})
        await test("webhook events list", "GET", f"/user/webhooks/{wh_id}/events")
        await test("delete webhook", "DELETE", f"/user/webhooks/{wh_id}")

    # ── 14. FORWARDING ──
    print("\n─── 14. التحويلات (Forwarding) ───")
    await test("get forwarding", "GET", "/user/forwarding")
    await test("test forwarding", "GET", "/user/forwarding/test")

    # ── 15. PUSH NOTIFICATIONS ──
    print("\n─── 15. إشعارات Push ───")
    await test("push config", "GET", "/user/push/config")
    r = await test("register push", "POST", "/user/push/register",
                   json={"token": "test_token_123", "platform": "android"})
    dev_id = ((r or {}).get("data") or {}).get("id")
    if dev_id:
        await test("list devices", "GET", "/user/push/devices")
        await test("delete device", "DELETE", f"/user/push/devices/{dev_id}")
    await test("push test", "POST", "/user/push/test")

    # ── 16. TELEGRAM ──
    print("\n─── 16. تلغرام (Telegram) ───")
    await test("telegram status", "GET", "/telegram/connect")
    r = await test("telegram connect", "POST", "/telegram/connect",
                   json={"chat_id": "123456", "bot_token": "123:test"})
    if r and r.get("data"):
        await test("telegram rules", "GET", "/telegram/rules")
        r2 = await test("create rule", "POST", "/telegram/rules",
                        json={"source_type": "sms", "filter_criteria": {}})
        rule_id = ((r2 or {}).get("data") or {}).get("id")
        if rule_id:
            await test("toggle rule", "PUT", f"/telegram/rules/{rule_id}/toggle",
                       json={"active": False})
            await test("delete rule", "DELETE", f"/telegram/rules/{rule_id}")
    await test("telegram disconnect", "POST", "/telegram/disconnect")

    # ── 17. API KEYS ──
    print("\n─── 17. مفاتيح API ───")
    await test("list api keys", "GET", "/user/api-keys")
    r = await test("create api key", "POST", "/user/api-keys",
                   json={"name": "test-key"})
    key_id = ((r or {}).get("data") or {}).get("id")
    if key_id:
        await test("delete api key", "DELETE", f"/user/api-keys/{key_id}")

    # ── 18. REFERRALS ──
    print("\n─── 18. الإحالة (Referral) ───")
    await test("referral code", "GET", "/user/referral/code")
    await test("referral earnings", "GET", "/user/referral/earnings")
    await test("claim invalid", "POST", "/user/referral/claim",
               json={"code": "INVALID"})

    # ── 19. TIERS ──
    print("\n─── 19. المستويات (Tiers) ───")
    await test("list tiers", "GET", "/user/tiers")
    await test("current tier", "GET", "/user/tiers/current")
    await test("upgrade tier", "POST", "/user/tiers/upgrade",
               data={"tier": "payg"})

    # ── 20. PRESETS ──
    print("\n─── 20. المفضلة (Presets) ───")
    await test("list presets", "GET", "/user/presets")
    r = await test("create preset", "POST", "/user/presets",
                   json={"name": "Test", "service": svc_name, "country": "US"})
    preset_id = ((r or {}).get("data") or {}).get("id")
    if preset_id:
        await test("update preset", "PUT", f"/user/presets/{preset_id}",
                   json={"name": "Updated"})
        await test("delete preset", "DELETE", f"/user/presets/{preset_id}")

    # ── 21. AVAILABILITY ──
    print("\n─── 21. التوفر (Availability) ───")
    await test("service availability", "GET", f"/user/availability/service?service={svc_name}&country=US")
    await test("country availability", "GET", "/user/availability/country?country=US")
    await test("top services", "GET", "/user/availability/top-services")
    await test("summary", "GET", "/user/availability/summary")

    # ── 22. RENTALS ──
    print("\n─── 22. الإيجارات (Rentals) ───")
    await test("list rentals", "GET", "/user/rentals")

    # ── 23. VOICE ──
    print("\n─── 23. الصوت (Voice) ───")
    await test("voice services", "GET", "/user/voice/services")
    await test("voice purchase", "POST", "/user/voice/purchase",
               data={"service": "google", "country": "US"})

    # ── 24. TEMP EMAIL ──
    print("\n─── 24. البريد المؤقت ───")
    r = await test("temp email", "GET", "/user/email/temp")
    if r and r.get("data"):
        await test("temp messages", "GET", "/user/email/temp/messages")
        await test("delete temp", "DELETE", "/user/email/temp")

    # ── 25. EMAIL VERIFICATION ──
    print("\n─── 25. توثيق البريد ───")
    await test("send verification", "POST", "/user/email/send-verification")
    await test("verify invalid", "POST", "/user/email/verify",
               data={"token": "invalid"})

    # ── 26. SETTINGS ──
    print("\n─── 26. الإعدادات ───")
    await test("get settings", "GET", "/user/settings")
    await test("update settings", "PUT", "/user/settings?language=ar&timezone=Asia/Riyadh")

    # ── 27. ONBOARDING ──
    print("\n─── 27. الإعداد الأولي ───")
    await test("onboarding status", "GET", "/user/onboarding")
    await test("onboarding step", "POST", "/user/onboarding/step", data={"step": 3})
    await test("onboarding complete", "POST", "/user/onboarding/complete")

    # ── 28. RENTALS ──
    print("\n─── 28. الإيجارات ───")
    await test("create rental", "POST", "/user/rentals",
               data={"service": svc_name, "country": "US", "hours": 1, "auto_extend": 0})

    # ── 29. GDPR ──
    print("\n─── 29. الخصوصية (GDPR) ───")
    await test("gdpr consent", "GET", "/user/gdpr/consent")
    await test("gdpr retention", "GET", "/user/gdpr/retention-policy")
    await test("gdpr export", "GET", "/user/gdpr/export")

    # ── 30. ACTIVITY ──
    print("\n─── 30. النشاط (Activity) ───")
    await test("activity feed", "GET", "/user/activity/feed")

    # ── 31. PRICING ──
    print("\n─── 31. التسعير ───")
    await test("my pricing", "GET", "/pricing/my")
    await test("validate promo", "POST", "/pricing/validate-promo",
               json={"code": "INVALID"})
    await test("apply promo", "POST", "/pricing/apply-promo",
               json={"code": "INVALID"})

    # ── 32. AFFILIATE ──
    print("\n─── 32. التسويق بالعمولة ───")
    await test("affiliate apply", "POST", "/affiliate/apply",
               json={"message": "I want to join"})
    await test("affiliate status", "GET", "/affiliate/application")
    await test("affiliate commissions", "GET", "/affiliate/commissions")
    await test("affiliate summary", "GET", "/affiliate/summary")
    await test("affiliate tiers", "GET", "/affiliate/tiers")
    await test("affiliate payouts", "GET", "/affiliate/payouts")
    await test("affiliate revenue", "GET", "/affiliate/revenue-share")

    # ── 33. KYC ──
    print("\n─── 33. التحقق من الهوية (KYC) ───")
    await test("kyc profile", "GET", "/kyc/profile")
    await test("kyc status", "GET", "/kyc/status")
    await test("kyc limits", "GET", "/kyc/limits")

    # ── 34. DISPUTES ──
    print("\n─── 34. النزاعات (Disputes) ───")
    r = await test("create dispute", "POST", "/disputes",
                   json={"reason": "test", "description": "testing", "dispute_type": "other"})
    dis_id = ((r or {}).get("data") or {}).get("id")
    if dis_id:
        await test("list disputes", "GET", "/disputes")
        await test("get dispute", "GET", f"/disputes/{dis_id}")
        await test("dispute comment", "POST", f"/disputes/{dis_id}/comments",
                   json={"content": "test comment"})

    # ── 35. SUPPORT ──
    print("\n─── 35. الدعم (Support) ───")
    r = await test("create ticket", "POST", "/user/support/tickets",
                   json={"subject": "Test", "message": "Testing support ticket"})
    tkt_id = ((r or {}).get("data") or {}).get("id")
    if tkt_id:
        created_ids["ticket"] = tkt_id
        await test("list tickets", "GET", "/user/support/tickets")
        await test("get ticket", "GET", f"/user/support/tickets/{tkt_id}")
        await test("reply ticket", "POST", f"/user/support/tickets/{tkt_id}/reply",
                   data={"message": "Thanks!"})
        await test("close ticket", "POST", f"/user/support/tickets/{tkt_id}/close")

    # ── 36. INVOICES ──
    print("\n─── 36. الفواتير ───")
    await test("list invoices", "GET", "/user/invoices")
    await test("get invoice not found", "GET", "/user/invoices/nonexistent")

    # ── 37. LEDGER ──
    print("\n─── 37. دفتر الأستاذ (Ledger) ───")
    await test("ledger balance", "GET", "/user/ledger/balance")
    await test("ledger balances", "GET", "/user/ledger/balances")
    await test("ledger history", "GET", "/user/ledger/history")

    # ── 38. PAYMENTS ──
    print("\n─── 38. المدفوعات ───")
    await test("payment products", "GET", "/user/payments/products?provider=google_pay")
    await test("payment history", "GET", "/user/payments/history")

    # ── 39. IAP ──
    print("\n─── 39. مشتريات التطبيق ───")
    await test("iap products", "GET", "/user/iap/products")

    # ── 40. WHITELABEL ──
    print("\n─── 40. العلامة البيضاء ───")
    await test("whitelabel branding", "GET", "/whitelabel/branding")
    await test("whitelabel domains", "GET", "/whitelabel/domains")
    await test("whitelabel templates", "GET", "/whitelabel/email-templates")

    # ── 41. health/version ──
    print("\n─── 41. الصحة والإصدار ───")
    await test("health", "GET", "/health")
    await test("version", "GET", "/version")

    # ── 42. PUBLIC ──
    print("\n─── 42. النهايات العامة ───")
    old_token = TOKEN
    TOKEN = None
    await test("services no auth", "GET", "/services")
    await test("categories no auth", "GET", "/services/categories")
    await test("providers no auth", "GET", "/providers")
    TOKEN = old_token

    # ── 43. LOGOUT ──
    print("\n─── 43. تسجيل الخروج ───")
    await test("logout", "POST", "/user/auth/logout")

    # ── 44. ACCESS AFTER LOGOUT ──
    print("\n─── 44. الوصول بعد الخروج ───")
    await test("access after logout", "GET", "/user/profile")

    # ── FINAL RESULTS ──
    print("\n" + "=" * 75)
    print(f"📊 النتائج النهائية")
    print("=" * 75)
    print(f"  ✅ نجح: {results['pass']}")
    print(f"  ❌ فشل: {results['fail']}")
    if results['errors']:
        print(f"\n⚠️  الأخطاء ({len(results['errors'])}):")
        for i, err in enumerate(results['errors'], 1):
            print(f"  {i}. {err}")
    print("=" * 75)


if __name__ == "__main__":
    asyncio.run(main())
