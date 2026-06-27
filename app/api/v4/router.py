from fastapi import APIRouter

from app.api.v4.admin import router as admin_v4_router

from app.api.v1.admin_support import router as admin_support_router
from app.api.v1.admin_broadcast import router as admin_broadcast_router
from app.api.v1.admin_pricing import router as admin_pricing_router
from app.api.v1.admin_affiliate import router as admin_affiliate_router
from app.api.v1.admin_reseller import router as admin_reseller_router
from app.api.v1.admin_analytics import router as admin_analytics_router
from app.api.v1.admin_kyc import router as admin_kyc_router
from app.api.v1.admin_financial import router as admin_financial_router
from app.api.v1.admin_disputes import router as admin_disputes_router
from app.api.v1.admin_reconciliation import router as admin_reconciliation_router
from app.api.v1.admin_security import router as admin_security_router
from app.api.v1.admin_telegram import router as admin_telegram_router
from app.api.v1.admin_blacklist import router as admin_blacklist_router
from app.api.v1.admin_whitelabel import router as admin_whitelabel_router
from app.api.v1.admin_export import router as admin_export_router
from app.api.v1.admin_sync import router as admin_sync_router
from app.api.v1.pnl_routes import router as pnl_router
from app.api.v1.ledger_routes import router as ledger_router

router = APIRouter(prefix="/stroapp/v4")

# v4 clean admin API (JSON-only, Pydantic bodies, no HTML templates)
router.include_router(admin_v4_router)

# All v1 admin sub-modules (these already return JSON via success_response)
router.include_router(admin_support_router)
router.include_router(admin_broadcast_router)
router.include_router(admin_pricing_router)
router.include_router(admin_affiliate_router)
router.include_router(admin_reseller_router)
router.include_router(admin_whitelabel_router)
router.include_router(admin_analytics_router)
router.include_router(admin_kyc_router)
router.include_router(admin_financial_router)
router.include_router(admin_disputes_router)
router.include_router(admin_reconciliation_router)
router.include_router(admin_security_router)
router.include_router(admin_telegram_router)
router.include_router(admin_blacklist_router)
router.include_router(admin_export_router)
router.include_router(admin_sync_router)
router.include_router(pnl_router)
router.include_router(ledger_router)
