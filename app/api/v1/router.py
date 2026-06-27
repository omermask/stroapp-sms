from fastapi import APIRouter

from app.api.v1.auth import router as auth_router
from app.api.v1.health import router as health_router
from app.api.v1.providers import router as providers_router
from app.api.v1.purchase import router as purchase_router
from app.api.v1.services import router as services_router
from app.api.v1.user import router as user_router
from app.api.v1.payments import router as payments_router
from app.api.v1.webhooks import router as webhooks_router
from app.api.v1.email import router as email_router
from app.api.v1.voice import router as voice_router
from app.api.v1.rentals import router as rentals_router
from app.api.v1.notifications import router as notifications_router
from app.api.v1.ws import router as ws_router
from app.api.v1.presets import router as presets_router
from app.api.v1.availability import router as availability_router
from app.api.v1.api_keys import router as api_keys_router
from app.api.v1.referrals import router as referrals_router
from app.api.v1.mfa import router as mfa_router
from app.api.v1.forwarding import router as forwarding_router
from app.api.v1.gdpr import router as gdpr_router
from app.api.v1.onboarding import router as onboarding_router
from app.api.v1.tiers import router as tiers_router
from app.api.v1.sessions import router as sessions_router
from app.api.v1.push_notifications import router as push_router
from app.api.v1.waitlist import router as waitlist_router
from app.api.v1.pricing import router as pricing_router
from app.api.v1.affiliate import router as affiliate_router
from app.api.v1.whitelabel import router as whitelabel_router
from app.api.v1.kyc import router as kyc_router
from app.api.v1.disputes import router as disputes_router
from app.api.v1.telegram import router as telegram_router
from app.api.v1.google_oauth import router as google_oauth_router
from app.api.v1.iap import router as iap_router
from app.api.v1.iap import rtdn_router as google_play_rtdn_router
from app.api.v1.iap import apple_webhook_router
from app.api.v1.activity_feed import router as activity_feed_router
from app.api.v1.advanced_search import router as advanced_search_router
from app.api.v1.email_verification import router as email_verification_router
from app.api.v1.user_settings import router as user_settings_router
from app.api.v1.invoices import router as invoices_router
from app.api.v1.support import router as support_router

router = APIRouter(prefix="/stroapp/v1")

router.include_router(health_router)
router.include_router(auth_router)
router.include_router(services_router)
router.include_router(purchase_router)
router.include_router(payments_router)
router.include_router(webhooks_router)
router.include_router(user_router)
router.include_router(providers_router)
router.include_router(email_router)
router.include_router(voice_router)
router.include_router(rentals_router)
router.include_router(notifications_router)
router.include_router(ws_router)
router.include_router(presets_router)
router.include_router(availability_router)
router.include_router(api_keys_router)
router.include_router(referrals_router)
router.include_router(mfa_router)
router.include_router(forwarding_router)
router.include_router(gdpr_router)
router.include_router(onboarding_router)
router.include_router(tiers_router)
router.include_router(sessions_router)
router.include_router(push_router)
router.include_router(waitlist_router)
router.include_router(pricing_router)
router.include_router(affiliate_router)
router.include_router(whitelabel_router)
router.include_router(kyc_router)
router.include_router(disputes_router)
router.include_router(telegram_router)
router.include_router(google_oauth_router)
router.include_router(iap_router)
router.include_router(google_play_rtdn_router)
router.include_router(apple_webhook_router)
router.include_router(activity_feed_router)
router.include_router(advanced_search_router)
router.include_router(email_verification_router)
router.include_router(user_settings_router)
router.include_router(invoices_router)
router.include_router(support_router)
