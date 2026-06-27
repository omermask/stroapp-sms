#!/usr/bin/env bash
set -euo pipefail

echo "=== StroApp Security Audit ==="
echo "Date: $(date -u)"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

check() {
    local name="$1"
    local result="$2"
    if [ "$result" -eq 0 ]; then
        echo "  [PASS] $name"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
        echo "  [FAIL] $name"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
    fi
}

echo "--- File Permissions ---"
stat -c "%a %n" .env 2>/dev/null && check ".env permissions" $([ "$(stat -c '%a' .env 2>/dev/null)" -le 600 ] && echo 0 || echo 1) || echo "  [INFO] .env not found"
stat -c "%a %n" main.py 2>/dev/null && check "main.py permissions" $([ "$(stat -c '%a' main.py 2>/dev/null)" -le 755 ] && echo 0 || echo 1) || echo "  [INFO] main.py not found"

echo ""
echo "--- Git Exposure ---"
if git rev-parse --git-dir > /dev/null 2>&1; then
    ENV_IN_GIT=$(git ls-files --cached --modified --others .env 2>/dev/null | wc -l)
    check ".env not tracked in git" $([ "$ENV_IN_GIT" -eq 0 ] && echo 0 || echo 1)
else
    echo "  [INFO] Not a git repository"
fi

echo ""
echo "--- Dependencies ---"
if command -v pip-audit &>/dev/null; then
    pip-audit --quiet 2>/dev/null && check "pip-audit" 0 || check "pip-audit" 1
else
    echo "  [INFO] pip-audit not installed (pip install pip-audit)"
fi

echo ""
echo "--- Secret Key Strength ---"
if [ -f .env ]; then
    KEY_LEN=$(grep -E '^SECRET_KEY=' .env | cut -d= -f2 | tr -d '"' | wc -c || echo 0)
    check "SECRET_KEY length >= 32" $([ "$KEY_LEN" -ge 32 ] && echo 0 || echo 1)
else
    echo "  [INFO] .env not found"
fi

echo ""
echo "=== Results: $CHECKS_PASSED passed, $CHECKS_FAILED failed ==="
exit $CHECKS_FAILED
