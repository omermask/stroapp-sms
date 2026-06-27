import uuid
from datetime import datetime, timezone

import sqlalchemy as sa
from sqlalchemy import Column, DateTime, String, ForeignKey, Text, Float, Boolean, Integer, JSON, Date, Time, UniqueConstraint
from sqlalchemy.orm import relationship

from app.core.database import Base


def utcnow():
    return datetime.now(timezone.utc)


def gen_uuid():
    return str(uuid.uuid4())


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=gen_uuid)
    email = Column(String, unique=True, nullable=True)
    display_name = Column(String, nullable=True)
    photo_url = Column(String, nullable=True)

    google_id = Column(String, unique=True, nullable=True)
    apple_id = Column(String, unique=True, nullable=True)

    coins = Column(Integer, default=0, nullable=False)
    lifetime_coins = Column(Integer, default=0, nullable=False)
    temp_emails_used = Column(Integer, default=0, nullable=False)

    is_admin = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    is_banned = Column(Boolean, default=False)

    hashed_password = Column(String, nullable=True)
    avatar = Column(String, nullable=True)
    reset_token = Column(String, nullable=True)
    reset_token_expires = Column(DateTime(timezone=True), nullable=True)
    email_verified = Column(Boolean, default=False)
    email_verification_token = Column(String, nullable=True)

    mfa_secret = Column(String, nullable=True)
    mfa_enabled = Column(Boolean, default=False)
    tier = Column(String, default="freemium", nullable=False)
    tier_expires_at = Column(DateTime(timezone=True), nullable=True)
    onboarding_completed = Column(Boolean, default=False)
    onboarding_step = Column(Integer, default=0, nullable=False)
    marketing_consent = Column(Boolean, default=False)
    analytics_consent = Column(Boolean, default=False)
    data_sharing_consent = Column(Boolean, default=False)
    is_affiliate = Column(Boolean, default=False)

    last_login_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)

    transactions = relationship("Transaction", back_populates="user", order_by="Transaction.created_at.desc()")
    sms_orders = relationship("SMSOrder", back_populates="user", order_by="SMSOrder.created_at.desc()")
    temp_emails = relationship("TempEmail", back_populates="user")


class UserSettings(Base):
    __tablename__ = "user_settings"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, unique=True, index=True)
    language = Column(String, default="ar")
    timezone = Column(String, default="Asia/Riyadh")
    email_notifications = Column(Boolean, default=True)
    push_notifications = Column(Boolean, default=True)
    sms_notifications = Column(Boolean, default=True)
    dark_mode = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    amount = Column(Integer, nullable=False)
    type = Column(String, nullable=False)
    description = Column(String, nullable=True)
    reference = Column(String, unique=True, nullable=True)
    coins_before = Column(Integer, nullable=True)
    coins_after = Column(Integer, nullable=True)
    metadata_json = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)

    user = relationship("User", back_populates="transactions")


class SMSOrder(Base):
    __tablename__ = "sms_orders"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    service = Column(String, nullable=False)
    country = Column(String, nullable=False)
    provider = Column(String, nullable=False)
    phone_number = Column(String, nullable=True)
    type = Column(String, default="sms", nullable=False)
    status = Column(String, default="pending", nullable=False)
    cost_coins = Column(Integer, nullable=False)
    activation_id = Column(String, nullable=True)
    verification_code = Column(String, nullable=True)
    sms_text = Column(Text, nullable=True)
    sms_received_at = Column(DateTime(timezone=True), nullable=True)
    refunded = Column(Boolean, default=False)
    refund_transaction_id = Column(String, nullable=True)
    provider_response = Column(JSON, nullable=True)
    error_message = Column(String, nullable=True)
    call_duration = Column(Integer, nullable=True)
    audio_url = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)

    user = relationship("User", back_populates="sms_orders")


class Service(Base):
    __tablename__ = "services"

    id = Column(String, primary_key=True, default=gen_uuid)
    name = Column(String, unique=True, nullable=False)
    display_name = Column(String, nullable=True)
    category = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    metadata_json = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class Country(Base):
    __tablename__ = "countries"

    id = Column(String, primary_key=True, default=gen_uuid)
    code = Column(String, nullable=False)
    name = Column(String, nullable=False)
    service_id = Column(String, ForeignKey("services.id"), nullable=False)
    provider = Column(String, nullable=False)
    provider_cost = Column(Float, nullable=True)
    platform_price = Column(Float, nullable=True)
    currency = Column(String, default="RUB")
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class Provider(Base):
    __tablename__ = "providers"

    id = Column(String, primary_key=True, default=gen_uuid)
    name = Column(String, unique=True, nullable=False)
    display_name = Column(String, nullable=True)
    base_url = Column(String, nullable=True)
    api_key = Column(String, nullable=True)
    priority = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    supports_voice = Column(Boolean, default=False)
    supports_rentals = Column(Boolean, default=False)
    metadata_json = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class TempEmail(Base):
    __tablename__ = "temp_emails"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    email_address = Column(String, nullable=False)
    password = Column(String, nullable=False)
    token = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    messages_count = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=True)

    user = relationship("User", back_populates="temp_emails")


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=True, index=True)
    action = Column(String, nullable=False)
    resource_type = Column(String, nullable=True)
    resource_id = Column(String, nullable=True)
    details = Column(JSON, nullable=True)
    ip_address = Column(String, nullable=True)
    request_id = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class PaymentLog(Base):
    __tablename__ = "payment_logs"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    provider = Column(String, nullable=False)
    product_id = Column(String, nullable=False)
    amount_usd = Column(Float, nullable=False)
    coins = Column(Integer, nullable=False)
    reference = Column(String, unique=True, nullable=True)
    status = Column(String, nullable=False)
    error_message = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class PaymentProduct(Base):
    __tablename__ = "payment_products"

    id = Column(String, primary_key=True, default=gen_uuid)
    provider = Column(String, nullable=False)
    product_id = Column(String, nullable=False)
    amount_usd = Column(Float, nullable=False)
    coins = Column(Integer, nullable=False)
    label = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)

    __table_args__ = (
        sa.UniqueConstraint('provider', 'product_id', name='uq_payment_products_provider_product'),
    )


class Webhook(Base):
    __tablename__ = "webhooks"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    url = Column(String, nullable=False)
    secret = Column(String, nullable=True)
    events = Column(JSON, nullable=True)
    is_active = Column(Boolean, default=True)
    last_success_at = Column(DateTime(timezone=True), nullable=True)
    last_failure_at = Column(DateTime(timezone=True), nullable=True)
    consecutive_failures = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)

    events_list = relationship("WebhookEvent", back_populates="webhook", order_by="WebhookEvent.created_at.desc()")


class WebhookEvent(Base):
    __tablename__ = "webhook_events"

    id = Column(String, primary_key=True, default=gen_uuid)
    webhook_id = Column(String, ForeignKey("webhooks.id"), nullable=False, index=True)
    event = Column(String, nullable=False)
    payload = Column(JSON, nullable=True)
    status = Column(String, nullable=False)
    response_code = Column(Integer, nullable=True)
    response_body = Column(Text, nullable=True)
    error_message = Column(String, nullable=True)
    retry_count = Column(Integer, default=0)
    next_retry_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    completed_at = Column(DateTime(timezone=True), nullable=True)

    webhook = relationship("Webhook", back_populates="events_list")


class NumberRental(Base):
    __tablename__ = "number_rentals"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    service = Column(String, nullable=False)
    country = Column(String, nullable=False)
    provider = Column(String, nullable=False)
    phone_number = Column(String, nullable=True)
    activation_id = Column(String, nullable=True)
    status = Column(String, default="active", nullable=False)
    duration_hours = Column(Integer, nullable=False)
    cost_coins = Column(Integer, nullable=False)
    auto_extend = Column(Boolean, default=False)
    messages_count = Column(Integer, default=0)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    cancelled_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)

    user = relationship("User", backref="rentals")


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    type = Column(String, nullable=False)
    title = Column(String, nullable=False)
    body = Column(Text, nullable=True)
    data = Column(JSON, nullable=True)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)

    user = relationship("User", backref="notifications")


class Preset(Base):
    __tablename__ = "presets"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    name = Column(String, nullable=False)
    service = Column(String, nullable=False)
    country = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class APIKey(Base):
    __tablename__ = "api_keys"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    name = Column(String, nullable=False)
    key_hash = Column(String, nullable=False)
    prefix = Column(String, nullable=False)
    is_active = Column(Boolean, default=True)
    last_used_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class Referral(Base):
    __tablename__ = "referrals"

    id = Column(String, primary_key=True, default=gen_uuid)
    referrer_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    referred_id = Column(String, ForeignKey("users.id"), nullable=False, unique=True)
    code = Column(String, nullable=False)
    reward_coins = Column(Integer, default=0)
    status = Column(String, default="pending", nullable=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class ReferralCode(Base):
    __tablename__ = "referral_codes"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, unique=True)
    code = Column(String, unique=True, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class IdempotencyKey(Base):
    __tablename__ = "idempotency_keys"

    id = Column(String, primary_key=True, default=gen_uuid)
    key = Column(String, unique=True, nullable=False, index=True)
    response = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)


class DeviceFingerprint(Base):
    __tablename__ = "device_fingerprints"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=True, index=True)
    fingerprint_hash = Column(String, nullable=False, index=True)
    ip_address = Column(String, nullable=True)
    user_agent = Column(String, nullable=True)
    device_data = Column(JSON, nullable=True)
    risk_score = Column(Float, default=0.0)
    is_trusted = Column(Boolean, default=False)
    first_seen_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    last_seen_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)

    __table_args__ = (
        sa.UniqueConstraint('fingerprint_hash', 'user_id', name='uq_device_fingerprint'),
    )


class ActivityFeed(Base):
    __tablename__ = "activity_feed"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    activity_type = Column(String, nullable=False)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    metadata_json = Column(JSON, nullable=True)
    ip_address = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)

    user = relationship("User", backref="activities")


class BlacklistedToken(Base):
    __tablename__ = "blacklisted_tokens"

    id = Column(String, primary_key=True, default=gen_uuid)
    jti = Column(String, unique=True, nullable=False, index=True)
    token_type = Column(String, nullable=False)
    user_id = Column(String, ForeignKey("users.id"), nullable=True, index=True)
    reason = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)


class BlacklistedIP(Base):
    __tablename__ = "blacklisted_ips"

    id = Column(String, primary_key=True, default=gen_uuid)
    ip_address = Column(String, unique=True, nullable=False, index=True)
    reason = Column(String, nullable=True)
    blocked_by = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=True)


class LedgerEntry(Base):
    __tablename__ = "ledger_entries"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    currency = Column(String, nullable=False)
    amount = Column(Float, nullable=False)
    balance_before = Column(Float, nullable=False)
    balance_after = Column(Float, nullable=False)
    entry_type = Column(String, nullable=False)
    description = Column(String, nullable=True)
    reference_type = Column(String, nullable=True)
    reference_id = Column(String, nullable=True)
    exchange_rate = Column(Float, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)

    user = relationship("User", backref="ledger_entries")


class PnLReport(Base):
    __tablename__ = "pnl_reports"

    id = Column(String, primary_key=True, default=gen_uuid)
    period_start = Column(Date, nullable=False)
    period_end = Column(Date, nullable=False)
    total_revenue = Column(Float, default=0.0)
    total_cost = Column(Float, default=0.0)
    gross_profit = Column(Float, default=0.0)
    operating_expenses = Column(Float, default=0.0)
    net_profit = Column(Float, default=0.0)
    breakdown = Column(JSON, nullable=True)
    generated_by = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)

    __table_args__ = (
        sa.UniqueConstraint('period_start', 'period_end', name='uq_pnl_period'),
    )


class UserSession(Base):
    __tablename__ = "user_sessions"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    refresh_token = Column(String, unique=True, nullable=False)
    ip_address = Column(String, nullable=True)
    user_agent = Column(String, nullable=True)
    city = Column(String, nullable=True)
    country = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)


class FeatureFlag(Base):
    __tablename__ = "feature_flags"

    id = Column(String, primary_key=True, default=gen_uuid)
    name = Column(String, unique=True, nullable=False)
    enabled = Column(Boolean, default=False)
    strategy = Column(String, default="all_users", nullable=False)
    config = Column(JSON, nullable=True)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class ForwardingConfig(Base):
    __tablename__ = "forwarding_configs"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, unique=True, index=True)
    email_enabled = Column(Boolean, default=False)
    email_address = Column(String, nullable=True)
    webhook_enabled = Column(Boolean, default=False)
    webhook_url = Column(String, nullable=True)
    webhook_secret = Column(String, nullable=True)
    forward_all = Column(Boolean, default=True)
    forward_services = Column(JSON, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class SubscriptionTier(Base):
    __tablename__ = "subscription_tiers"

    id = Column(String, primary_key=True, default=gen_uuid)
    tier = Column(String, unique=True, nullable=False)
    name = Column(String, nullable=False)
    description = Column(String, nullable=True)
    price_monthly = Column(Integer, default=0)
    payment_required = Column(Boolean, default=False)
    quota_usd = Column(Float, default=0)
    has_api_access = Column(Boolean, default=False)
    api_key_limit = Column(Integer, default=0)
    daily_verification_limit = Column(Integer, default=20)
    monthly_verification_limit = Column(Integer, default=600)
    support_level = Column(String, default="community")
    features = Column(JSON, nullable=True)
    rate_limit_per_minute = Column(Integer, default=200)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class EmailTemplate(Base):
    __tablename__ = "email_templates"

    id = Column(String, primary_key=True, default=gen_uuid)
    name = Column(String, nullable=False)
    subject = Column(String, nullable=False)
    html_content = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class ConsentRecord(Base):
    __tablename__ = "consent_records"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    consent_type = Column(String, nullable=False)
    granted = Column(Boolean, nullable=False)
    ip_address = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class DeviceToken(Base):
    __tablename__ = "device_tokens"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    token = Column(String(500), nullable=False, unique=True, index=True)
    platform = Column(String(20), nullable=False)
    device_type = Column(String(50), nullable=True)
    device_name = Column(String(255), nullable=True)
    active = Column(Boolean, default=True, nullable=False, index=True)
    last_used_at = Column(DateTime(timezone=True), nullable=True)
    expires_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class AppSetting(Base):
    __tablename__ = "app_settings"

    id = Column(String, primary_key=True, default=gen_uuid)
    key = Column(String(100), nullable=False, unique=True, index=True)
    value = Column(String(500), nullable=True)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class Waitlist(Base):
    __tablename__ = "waitlist"

    id = Column(String, primary_key=True, default=gen_uuid)
    email = Column(String(255), nullable=False, unique=True, index=True)
    name = Column(String(100), nullable=True)
    is_notified = Column(Boolean, default=False)
    source = Column(String(50), default="landing_page")
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class PricingTemplate(Base):
    __tablename__ = "pricing_templates"

    id = Column(String, primary_key=True, default=gen_uuid)
    name = Column(String, unique=True, nullable=False)
    description = Column(Text, nullable=True)
    markup_multiplier = Column(Float, default=1.15)
    discount_percentage = Column(Float, default=0.0)
    region = Column(String, nullable=True)
    currency = Column(String, default="USD")
    is_active = Column(Boolean, default=False)
    is_promo = Column(Boolean, default=False)
    promo_code = Column(String, unique=True, nullable=True)
    promo_max_uses = Column(Integer, nullable=True)
    promo_used_count = Column(Integer, default=0)
    promo_expires_at = Column(DateTime(timezone=True), nullable=True)
    effective_date = Column(DateTime(timezone=True), nullable=False, default=utcnow)
    max_assignments = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "markup_multiplier": self.markup_multiplier,
            "discount_percentage": self.discount_percentage,
            "region": self.region,
            "currency": self.currency,
            "is_active": self.is_active,
            "is_promo": self.is_promo,
            "promo_code": self.promo_code,
            "promo_max_uses": self.promo_max_uses,
            "promo_used_count": self.promo_used_count,
            "promo_expires_at": self.promo_expires_at.isoformat() if self.promo_expires_at else None,
            "effective_date": self.effective_date.isoformat() if self.effective_date else None,
            "max_assignments": self.max_assignments,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }


class TierPricing(Base):
    __tablename__ = "tier_pricing"

    id = Column(String, primary_key=True, default=gen_uuid)
    template_id = Column(String, ForeignKey("pricing_templates.id", ondelete="CASCADE"), nullable=False)
    tier_name = Column(String, nullable=False)
    monthly_price = Column(Float, default=0.0)
    included_quota_usd = Column(Float, default=0.0)
    overage_rate = Column(Float, default=0.0)
    features = Column(JSON, default=list)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class PricingHistory(Base):
    __tablename__ = "pricing_history"

    id = Column(String, primary_key=True, default=gen_uuid)
    template_id = Column(String, ForeignKey("pricing_templates.id"), nullable=False)
    action = Column(String, nullable=False)
    changed_by = Column(String, nullable=False)
    notes = Column(Text, nullable=True)
    snapshot_before = Column(JSON, nullable=True)
    snapshot_after = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class UserPricingAssignment(Base):
    __tablename__ = "user_pricing_assignments"

    user_id = Column(String, ForeignKey("users.id"), primary_key=True)
    template_id = Column(String, ForeignKey("pricing_templates.id"), nullable=False)
    assigned_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=True)


class ServicePromotion(Base):
    __tablename__ = "service_promotions"

    id = Column(String, primary_key=True, default=gen_uuid)
    service = Column(String, nullable=False)
    country = Column(String, nullable=True)
    discount_percentage = Column(Float, nullable=False)
    original_price = Column(Float, nullable=False)
    promotional_price = Column(Float, nullable=False)
    max_uses = Column(Integer, nullable=True)
    used_count = Column(Integer, default=0)
    starts_at = Column(DateTime(timezone=True), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class PromoCodeUsage(Base):
    __tablename__ = "promo_code_usages"

    id = Column(String, primary_key=True, default=gen_uuid)
    template_id = Column(String, ForeignKey("pricing_templates.id"), nullable=False)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    order_id = Column(String, ForeignKey("sms_orders.id"), nullable=True)
    discount_amount = Column(Float, nullable=False)
    original_amount = Column(Float, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class AffiliateApplication(Base):
    __tablename__ = "affiliate_applications"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    program_type = Column(String, nullable=False)
    message = Column(Text, nullable=True)
    status = Column(String, default="pending")
    reviewed_by = Column(String, nullable=True)
    reviewed_at = Column(DateTime(timezone=True), nullable=True)
    rejection_reason = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class AffiliateCommission(Base):
    __tablename__ = "affiliate_commissions"

    id = Column(String, primary_key=True, default=gen_uuid)
    affiliate_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    transaction_id = Column(String, ForeignKey("transactions.id"), nullable=True)
    order_id = Column(String, ForeignKey("sms_orders.id"), nullable=True)
    referred_user_id = Column(String, ForeignKey("users.id"), nullable=True)
    amount = Column(Float, nullable=False)
    commission_rate = Column(Float, nullable=False)
    status = Column(String, default="pending")
    payout_id = Column(String, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    paid_at = Column(DateTime(timezone=True), nullable=True)


class CommissionTier(Base):
    __tablename__ = "commission_tiers"

    id = Column(String, primary_key=True, default=gen_uuid)
    name = Column(String, unique=True, nullable=False)
    base_rate = Column(Float, nullable=False)
    bonus_rate = Column(Float, default=0.0)
    min_volume_usd = Column(Float, default=0.0)
    min_referrals = Column(Integer, default=0)
    requirements = Column(JSON, default=dict)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class PayoutRequest(Base):
    __tablename__ = "payout_requests"

    id = Column(String, primary_key=True, default=gen_uuid)
    affiliate_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    amount = Column(Float, nullable=False)
    currency = Column(String, default="USD")
    payment_method = Column(String, nullable=False)
    payment_details = Column(JSON, nullable=True)
    status = Column(String, default="pending")
    processed_by = Column(String, nullable=True)
    processed_at = Column(DateTime(timezone=True), nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class RevenueShare(Base):
    __tablename__ = "revenue_shares"

    id = Column(String, primary_key=True, default=gen_uuid)
    partner_id = Column(String, ForeignKey("users.id"), nullable=False)
    transaction_id = Column(String, ForeignKey("transactions.id"), nullable=True)
    revenue_amount = Column(Float, nullable=False)
    commission_rate = Column(Float, nullable=False)
    commission_amount = Column(Float, nullable=False)
    tier_name = Column(String, nullable=True)
    status = Column(String, default="pending")
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class ResellerAccount(Base):
    __tablename__ = "reseller_accounts"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, unique=True)
    tier = Column(String, default="basic")
    volume_discount = Column(Float, default=0.0)
    custom_markup = Column(Float, nullable=True)
    credit_limit = Column(Float, default=0.0)
    auto_topup_enabled = Column(Boolean, default=False)
    auto_topup_threshold = Column(Float, default=0.0)
    auto_topup_amount = Column(Float, default=0.0)
    total_purchased = Column(Float, default=0.0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "tier": self.tier,
            "volume_discount": self.volume_discount,
            "custom_markup": self.custom_markup,
            "credit_limit": self.credit_limit,
            "auto_topup_enabled": self.auto_topup_enabled,
            "auto_topup_threshold": self.auto_topup_threshold,
            "auto_topup_amount": self.auto_topup_amount,
            "total_purchased": self.total_purchased,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }


class SubAccount(Base):
    __tablename__ = "sub_accounts"

    id = Column(String, primary_key=True, default=gen_uuid)
    reseller_account_id = Column(String, ForeignKey("reseller_accounts.id"), nullable=False, index=True)
    name = Column(String, nullable=False)
    email = Column(String, nullable=False)
    coins = Column(Float, default=0.0)
    usage_limit = Column(Float, nullable=True)
    rate_multiplier = Column(Float, default=1.0)
    is_active = Column(Boolean, default=True)
    last_used_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=True)

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "reseller_account_id": self.reseller_account_id,
            "name": self.name,
            "email": self.email,
            "coins": self.coins,
            "usage_limit": self.usage_limit,
            "rate_multiplier": self.rate_multiplier,
            "is_active": self.is_active,
            "last_used_at": self.last_used_at.isoformat() if self.last_used_at else None,
            "created_at": self.created_at.isoformat(),
            "expires_at": self.expires_at.isoformat() if self.expires_at else None,
        }


class SubAccountTransaction(Base):
    __tablename__ = "sub_account_transactions"

    id = Column(String, primary_key=True, default=gen_uuid)
    sub_account_id = Column(String, ForeignKey("sub_accounts.id"), nullable=False)
    transaction_type = Column(String, nullable=False)
    amount = Column(Float, nullable=False)
    description = Column(String, nullable=True)
    reference = Column(String, unique=True, nullable=True)
    balance_before = Column(Float, nullable=False)
    balance_after = Column(Float, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class CreditAllocation(Base):
    __tablename__ = "credit_allocations"

    id = Column(String, primary_key=True, default=gen_uuid)
    reseller_account_id = Column(String, ForeignKey("reseller_accounts.id"), nullable=False)
    sub_account_id = Column(String, ForeignKey("sub_accounts.id"), nullable=False)
    amount = Column(Float, nullable=False)
    allocation_type = Column(String, default="manual")
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class BulkOperation(Base):
    __tablename__ = "bulk_operations"

    id = Column(String, primary_key=True, default=gen_uuid)
    reseller_account_id = Column(String, ForeignKey("reseller_accounts.id"), nullable=False)
    operation_type = Column(String, nullable=False)
    total_accounts = Column(Integer, default=0)
    processed_accounts = Column(Integer, default=0)
    failed_accounts = Column(Integer, default=0)
    status = Column(String, default="pending")
    config = Column(JSON, default=dict)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    completed_at = Column(DateTime(timezone=True), nullable=True)


class WhitelabelDomain(Base):
    __tablename__ = "whitelabel_domains"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    domain = Column(String, unique=True, nullable=False)
    verified = Column(Boolean, default=False)
    verification_token = Column(String, nullable=False)
    ssl_status = Column(String, default="pending")
    ssl_expires_at = Column(DateTime(timezone=True), nullable=True)
    is_active = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class WhitelabelBranding(Base):
    __tablename__ = "whitelabel_branding"

    user_id = Column(String, ForeignKey("users.id"), primary_key=True)
    company_name = Column(String, nullable=True)
    logo_url = Column(String, nullable=True)
    favicon_url = Column(String, nullable=True)
    primary_color = Column(String, default="#4F46E5")
    secondary_color = Column(String, default="#6366F1")
    accent_color = Column(String, default="#10B981")
    support_email = Column(String, nullable=True)
    support_phone = Column(String, nullable=True)
    website_url = Column(String, nullable=True)
    custom_css = Column(Text, nullable=True)
    custom_js = Column(Text, nullable=True)
    terms_url = Column(String, nullable=True)
    privacy_url = Column(String, nullable=True)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class WhitelabelEmailTemplate(Base):
    __tablename__ = "whitelabel_email_templates"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    template_name = Column(String, nullable=False)
    subject = Column(String, nullable=False)
    html_content = Column(Text, nullable=False)
    text_content = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    version = Column(Integer, default=1)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)
    __table_args__ = (sa.UniqueConstraint("user_id", "template_name", name="uq_user_template"),)


class EmailTemplateVersion(Base):
    __tablename__ = "email_template_versions"

    id = Column(String, primary_key=True, default=gen_uuid)
    template_id = Column(String, ForeignKey("whitelabel_email_templates.id", ondelete="CASCADE"), nullable=False)
    version_number = Column(Integer, nullable=False)
    subject = Column(String, nullable=False)
    html_content = Column(Text, nullable=False)
    text_content = Column(Text, nullable=True)
    created_by = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class EmailTemplateAnalytics(Base):
    __tablename__ = "email_template_analytics"

    template_id = Column(String, ForeignKey("whitelabel_email_templates.id", ondelete="CASCADE"), primary_key=True)
    sent_count = Column(Integer, default=0)
    delivered_count = Column(Integer, default=0)
    opened_count = Column(Integer, default=0)
    clicked_count = Column(Integer, default=0)
    bounced_count = Column(Integer, default=0)
    complained_count = Column(Integer, default=0)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class DailyUserSnapshot(Base):
    __tablename__ = "daily_user_snapshots"

    snapshot_date = Column(sa.Date, primary_key=True)
    total_users = Column(Integer, default=0)
    new_users = Column(Integer, default=0)
    active_users_24h = Column(Integer, default=0)
    active_users_7d = Column(Integer, default=0)
    active_users_30d = Column(Integer, default=0)
    total_verifications = Column(Integer, default=0)
    successful_verifications = Column(Integer, default=0)
    failed_verifications = Column(Integer, default=0)
    total_revenue = Column(Float, default=0.0)
    daily_revenue = Column(Float, default=0.0)
    refund_amount = Column(Float, default=0.0)
    freemium_count = Column(Integer, default=0)
    payg_count = Column(Integer, default=0)
    pro_count = Column(Integer, default=0)
    custom_count = Column(Integer, default=0)
    computed_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class UserAnalyticsSnapshot(Base):
    __tablename__ = "user_analytics_snapshots"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    snapshot_date = Column(sa.Date, nullable=False)
    total_verifications = Column(Integer, default=0)
    successful_verifications = Column(Integer, default=0)
    total_spent = Column(Float, default=0.0)
    avg_cost = Column(Float, default=0.0)
    success_rate = Column(Float, default=0.0)
    top_service = Column(String, nullable=True)
    top_country = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    __table_args__ = (sa.UniqueConstraint("user_id", "snapshot_date", name="uq_user_snapshot_date"),)


class VerificationStatistics(Base):
    __tablename__ = "verification_statistics"

    stat_date = Column(sa.Date, primary_key=True)
    total_verifications = Column(Integer, default=0)
    successful_verifications = Column(Integer, default=0)
    failed_verifications = Column(Integer, default=0)
    total_revenue = Column(Float, default=0.0)
    avg_cost = Column(Float, default=0.0)
    unique_users = Column(Integer, default=0)
    top_service = Column(String, nullable=True)
    top_country = Column(String, nullable=True)
    top_provider = Column(String, nullable=True)
    computed_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class CarrierAnalytics(Base):
    __tablename__ = "carrier_analytics"

    id = Column(String, primary_key=True, default=gen_uuid)
    verification_id = Column(String, ForeignKey("sms_orders.id"), nullable=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=True)
    requested_carrier = Column(String, nullable=True)
    normalized_carrier = Column(String, nullable=True)
    assigned_phone = Column(String, nullable=True)
    outcome = Column(String, nullable=True)
    exact_match = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class MonthlyTarget(Base):
    __tablename__ = "monthly_targets"

    month = Column(String, primary_key=True)
    target_new_users = Column(Integer, default=0)
    target_revenue = Column(Float, default=0.0)
    target_verifications = Column(Integer, default=0)
    target_success_rate = Column(Float, default=0.0)
    is_active = Column(Boolean, default=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class CustomReport(Base):
    __tablename__ = "custom_reports"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    report_name = Column(String, nullable=False)
    report_type = Column(String, nullable=False)
    filters = Column(JSON, default=dict)
    schedule = Column(String, nullable=True)
    next_run = Column(DateTime(timezone=True), nullable=True)
    enabled = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class ScheduledReport(Base):
    __tablename__ = "scheduled_reports"

    id = Column(String, primary_key=True, default=gen_uuid)
    report_id = Column(String, ForeignKey("custom_reports.id"), nullable=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    report_data = Column(JSON, nullable=True)
    file_path = Column(String, nullable=True)
    generated_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    sent_at = Column(DateTime(timezone=True), nullable=True)
    status = Column(String, default="generated")


class PurchaseOutcome(Base):
    __tablename__ = "purchase_outcomes"

    id = Column(String, primary_key=True, default=gen_uuid)
    verification_id = Column(String, ForeignKey("sms_orders.id"), nullable=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=True)
    service = Column(String, nullable=False)
    provider = Column(String, nullable=False)
    country = Column(String, nullable=False)
    assigned_code = Column(String, nullable=True)
    assigned_carrier = Column(String, nullable=True)
    carrier_type = Column(String, nullable=True)
    matched = Column(Boolean, default=False)
    sms_received = Column(Boolean, default=False)
    is_refunded = Column(Boolean, default=False)
    provider_cost = Column(Float, nullable=True)
    user_price = Column(Float, nullable=True)
    profit = Column(Float, nullable=True)
    latency_seconds = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class KYCProfile(Base):
    __tablename__ = "kyc_profiles"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, unique=True)
    status = Column(String, default="not_submitted")
    verification_level = Column(String, default="unverified")
    full_name = Column(String, nullable=True)
    date_of_birth = Column(Date, nullable=True)
    nationality = Column(String, nullable=True)
    phone_number = Column(String, nullable=True)
    address_line1 = Column(String, nullable=True)
    address_line2 = Column(String, nullable=True)
    city = Column(String, nullable=True)
    state = Column(String, nullable=True)
    postal_code = Column(String, nullable=True)
    country = Column(String, nullable=True)
    risk_score = Column(Integer, default=0)
    aml_status = Column(String, default="not_screened")
    notes = Column(Text, nullable=True)
    submitted_at = Column(DateTime(timezone=True), nullable=True)
    verified_at = Column(DateTime(timezone=True), nullable=True)
    verified_by = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class KYCDocument(Base):
    __tablename__ = "kyc_documents"

    id = Column(String, primary_key=True, default=gen_uuid)
    kyc_profile_id = Column(String, ForeignKey("kyc_profiles.id"), nullable=False)
    document_type = Column(String, nullable=False)
    file_path = Column(String, nullable=False)
    file_hash = Column(String, nullable=False)
    verification_status = Column(String, default="pending")
    confidence_score = Column(Float, nullable=True)
    extracted_data = Column(JSON, nullable=True)
    rejection_reason = Column(String, nullable=True)
    reviewed_by = Column(String, nullable=True)
    reviewed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class KYCVerificationLimit(Base):
    __tablename__ = "kyc_verification_limits"

    verification_level = Column(String, primary_key=True)
    daily_limit_coins = Column(Float, nullable=False)
    monthly_limit_coins = Column(Float, nullable=False)
    annual_limit_coins = Column(Float, nullable=False)
    max_single_transaction = Column(Float, nullable=False)
    allowed_services = Column(JSON, default=list)
    country_restrictions = Column(JSON, default=list)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class KYCAuditLog(Base):
    __tablename__ = "kyc_audit_logs"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    action = Column(String, nullable=False)
    old_status = Column(String, nullable=True)
    new_status = Column(String, nullable=True)
    admin_id = Column(String, nullable=True)
    reason = Column(Text, nullable=True)
    details = Column(JSON, nullable=True)
    ip_address = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class AMLScreening(Base):
    __tablename__ = "aml_screenings"

    id = Column(String, primary_key=True, default=gen_uuid)
    kyc_profile_id = Column(String, ForeignKey("kyc_profiles.id"), nullable=False)
    screening_type = Column(String, nullable=False)
    status = Column(String, default="pending")
    match_score = Column(Float, default=0.0)
    matches_found = Column(JSON, default=list)
    search_terms = Column(JSON, default=list)
    data_sources = Column(JSON, default=list)
    reviewed_by = Column(String, nullable=True)
    reviewed_at = Column(DateTime(timezone=True), nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class KYCSettings(Base):
    __tablename__ = "kyc_settings"

    setting_key = Column(String, primary_key=True)
    setting_value = Column(JSON, nullable=False)
    is_active = Column(Boolean, default=True)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class RevenueRecognition(Base):
    __tablename__ = "revenue_recognitions"

    id = Column(String, primary_key=True, default=gen_uuid)
    order_id = Column(String, ForeignKey("sms_orders.id"), nullable=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    total_amount = Column(Float, nullable=False, default=0)
    currency = Column(String, default="SAR")
    exchange_rate = Column(Float, default=1.0)
    recognized_amount = Column(Float, nullable=False, default=0)
    recognition_method = Column(String, default="at_point_of_sale")
    revenue_category = Column(String, default="sms_service")
    recognition_date = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class DeferredRevenueSchedule(Base):
    __tablename__ = "deferred_revenue_schedules"

    id = Column(String, primary_key=True, default=gen_uuid)
    recognition_id = Column(String, ForeignKey("revenue_recognitions.id"), nullable=False)
    scheduled_date = Column(Date, nullable=False)
    amount = Column(Float, nullable=False, default=0)
    recognized_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class RevenueAdjustment(Base):
    __tablename__ = "revenue_adjustments"

    id = Column(String, primary_key=True, default=gen_uuid)
    recognition_id = Column(String, ForeignKey("revenue_recognitions.id"), nullable=True)
    adjustment_type = Column(String, nullable=False, default="correction")
    amount = Column(Float, nullable=False, default=0)
    currency = Column(String, default="SAR")
    reason = Column(Text, nullable=True)
    approved_by = Column(String, nullable=True)
    adjustment_date = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class TaxJurisdictionConfig(Base):
    __tablename__ = "tax_jurisdiction_configs"

    id = Column(String, primary_key=True, default=gen_uuid)
    jurisdiction = Column(String, nullable=False)
    tax_type = Column(String, nullable=False, default="vat")
    tax_rate = Column(Float, nullable=False, default=0.0)
    is_active = Column(Boolean, default=True)
    effective_from = Column(Date, nullable=True)
    effective_to = Column(Date, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)
    __table_args__ = (UniqueConstraint("jurisdiction", "tax_type"),)


class TaxReport(Base):
    __tablename__ = "tax_reports"

    id = Column(String, primary_key=True, default=gen_uuid)
    report_type = Column(String, nullable=False, default="vat")
    jurisdiction = Column(String, nullable=False)
    period_start = Column(Date, nullable=False)
    period_end = Column(Date, nullable=False)
    total_tax = Column(Float, default=0.0)
    report_data = Column(JSON, nullable=True)
    status = Column(String, default="draft")
    submitted_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class TaxExemptionCertificate(Base):
    __tablename__ = "tax_exemption_certificates"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    certificate_number = Column(String, unique=True, nullable=False)
    exemption_type = Column(String, nullable=False)
    status = Column(String, default="active")
    valid_from = Column(Date, nullable=True)
    valid_until = Column(Date, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class ProviderSettlement(Base):
    __tablename__ = "provider_settlements"

    id = Column(String, primary_key=True, default=gen_uuid)
    provider_name = Column(String, nullable=False)
    settlement_period_start = Column(Date, nullable=False)
    settlement_period_end = Column(Date, nullable=False)
    gross_amount = Column(Float, default=0.0)
    commission_amount = Column(Float, default=0.0)
    net_amount = Column(Float, default=0.0)
    currency = Column(String, default="SAR")
    status = Column(String, default="pending")
    settlement_date = Column(Date, nullable=True)
    paid_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class ProviderCostTracking(Base):
    __tablename__ = "provider_cost_tracking"

    id = Column(String, primary_key=True, default=gen_uuid)
    provider_name = Column(String, nullable=False)
    service_type = Column(String, nullable=True)
    cost_per_unit = Column(Float, default=0.0)
    units_consumed = Column(Float, default=0)
    total_cost = Column(Float, default=0.0)
    currency = Column(String, default="SAR")
    cost_date = Column(Date, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class ProviderReconciliation(Base):
    __tablename__ = "provider_reconciliations"

    id = Column(String, primary_key=True, default=gen_uuid)
    provider_name = Column(String, nullable=False)
    reconciliation_date = Column(Date, nullable=False)
    period_start = Column(Date, nullable=False)
    period_end = Column(Date, nullable=False)
    our_count = Column(Integer, default=0)
    our_amount = Column(Float, default=0.0)
    provider_count = Column(Integer, default=0)
    provider_amount = Column(Float, default=0.0)
    variance_count = Column(Integer, default=0)
    variance_amount = Column(Float, default=0.0)
    status = Column(String, default="pending")
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class ProviderAgreement(Base):
    __tablename__ = "provider_agreements"

    id = Column(String, primary_key=True, default=gen_uuid)
    provider_name = Column(String, nullable=False)
    commission_rate = Column(Float, default=0.0)
    billing_cycle = Column(String, default="monthly")
    terms = Column(JSON, nullable=True)
    is_active = Column(Boolean, default=True)
    effective_date = Column(Date, nullable=True)
    termination_date = Column(Date, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class FinancialStatement(Base):
    __tablename__ = "financial_statements"

    id = Column(String, primary_key=True, default=gen_uuid)
    statement_type = Column(String, nullable=False)
    period = Column(String, nullable=False)
    period_start = Column(Date, nullable=False)
    period_end = Column(Date, nullable=False)
    total_revenue = Column(Float, default=0.0)
    total_expenses = Column(Float, default=0.0)
    net_income = Column(Float, default=0.0)
    status = Column(String, default="draft")
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class OperatingMetrics(Base):
    __tablename__ = "operating_metrics"

    id = Column(String, primary_key=True, default=gen_uuid)
    period_date = Column(Date, nullable=False)
    total_orders = Column(Integer, default=0)
    successful_deliveries = Column(Integer, default=0)
    failed_deliveries = Column(Integer, default=0)
    total_messages = Column(Integer, default=0)
    total_revenue_coins = Column(Float, default=0.0)
    total_cost_coins = Column(Float, default=0.0)
    profit_margin = Column(Float, default=0.0)
    active_users = Column(Integer, default=0)
    new_users = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    __table_args__ = (UniqueConstraint("period_date"),)


class Dispute(Base):
    __tablename__ = "disputes"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    order_id = Column(String, ForeignKey("sms_orders.id"), nullable=True)
    dispute_type = Column(String, default="billing")
    reason = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    status = Column(String, default="open")
    priority = Column(String, default="normal")
    resolution = Column(String, nullable=True)
    refund_amount = Column(Float, default=0.0)
    investigated_by = Column(String, nullable=True)
    resolved_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class DisputeComment(Base):
    __tablename__ = "dispute_comments"

    id = Column(String, primary_key=True, default=gen_uuid)
    dispute_id = Column(String, ForeignKey("disputes.id"), nullable=False)
    actor_id = Column(String, nullable=False)
    actor_type = Column(String, nullable=False, default="user")
    content = Column(Text, nullable=False)
    is_internal = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class DisputeAttachment(Base):
    __tablename__ = "dispute_attachments"

    id = Column(String, primary_key=True, default=gen_uuid)
    dispute_id = Column(String, ForeignKey("disputes.id"), nullable=False)
    file_name = Column(String, nullable=False)
    file_type = Column(String, nullable=True)
    file_url = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class DisputeTimeline(Base):
    __tablename__ = "dispute_timelines"

    id = Column(String, primary_key=True, default=gen_uuid)
    dispute_id = Column(String, ForeignKey("disputes.id"), nullable=False)
    status = Column(String, nullable=False)
    actor_id = Column(String, nullable=True)
    actor_type = Column(String, default="system")
    note = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class ReconciliationLog(Base):
    __tablename__ = "reconciliation_logs"

    id = Column(String, primary_key=True, default=gen_uuid)
    reconciliation_type = Column(String, nullable=False)
    source = Column(String, default="auto")
    status = Column(String, default="completed")
    summary = Column(JSON, nullable=True)
    discrepancies = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class BalanceMismatchAlert(Base):
    __tablename__ = "balance_mismatch_alerts"

    id = Column(String, primary_key=True, default=gen_uuid)
    alert_type = Column(String, nullable=False)
    severity = Column(String, default="low")
    description = Column(Text, nullable=True)
    expected_value = Column(Float, nullable=False)
    actual_value = Column(Float, nullable=False)
    variance = Column(Float, default=0.0)
    resolved_at = Column(DateTime(timezone=True), nullable=True)
    resolved_by = Column(String, nullable=True)
    resolution_notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class NotificationPreference(Base):
    __tablename__ = "notification_preferences"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, unique=True)
    push_enabled = Column(Boolean, default=True)
    email_enabled = Column(Boolean, default=True)
    sms_enabled = Column(Boolean, default=True)
    telegram_enabled = Column(Boolean, default=False)
    whatsapp_enabled = Column(Boolean, default=False)
    quiet_hours_start = Column(Time, nullable=True)
    quiet_hours_end = Column(Time, nullable=True)
    digest_frequency = Column(String, default="daily")
    categories = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class NotificationPreferenceDefaults(Base):
    __tablename__ = "notification_preference_defaults"

    category = Column(String, primary_key=True)
    push_enabled = Column(Boolean, default=True)
    email_enabled = Column(Boolean, default=True)
    sms_enabled = Column(Boolean, default=True)
    telegram_enabled = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class NotificationAnalytics(Base):
    __tablename__ = "notification_analytics"

    id = Column(String, primary_key=True, default=gen_uuid)
    event_type = Column(String, nullable=False)
    channel = Column(String, nullable=False)
    status = Column(String, nullable=False)
    latency_ms = Column(Integer, nullable=True)
    category = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class AdminNotification(Base):
    __tablename__ = "admin_notifications"

    id = Column(String, primary_key=True, default=gen_uuid)
    title = Column(String, nullable=False)
    message = Column(Text, nullable=True)
    notification_type = Column(String, default="info")
    audience_filter = Column(JSON, nullable=True)
    status = Column(String, default="draft")
    sent_count = Column(Integer, default=0)
    failed_count = Column(Integer, default=0)
    scheduled_at = Column(DateTime(timezone=True), nullable=True)
    sent_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class TelegramConnection(Base):
    __tablename__ = "telegram_connections"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, unique=True)
    chat_id = Column(String, unique=True, nullable=False)
    bot_token = Column(String, nullable=True)
    username = Column(String, nullable=True)
    first_name = Column(String, nullable=True)
    last_name = Column(String, nullable=True)
    language_code = Column(String, nullable=True)
    status = Column(String, default="active")
    connected_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    disconnected_at = Column(DateTime(timezone=True), nullable=True)


class TelegramForwardingRule(Base):
    __tablename__ = "telegram_forwarding_rules"

    id = Column(String, primary_key=True, default=gen_uuid)
    connection_id = Column(String, ForeignKey("telegram_connections.id"), nullable=False)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    source_type = Column(String, default="sms")
    filter_criteria = Column(JSON, default=dict)
    destination = Column(String, default="telegram")
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class SecurityScanResult(Base):
    __tablename__ = "security_scan_results"

    id = Column(String, primary_key=True, default=gen_uuid)
    scan_type = Column(String, nullable=False)
    status = Column(String, default="running")
    severity = Column(String, nullable=True)
    summary = Column(String, nullable=True)
    findings = Column(JSON, nullable=True)
    triggered_by = Column(String, default="system")
    started_at = Column(DateTime(timezone=True), nullable=False, default=utcnow)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "scan_type": self.scan_type,
            "status": self.status,
            "severity": self.severity,
            "summary": self.summary,
            "findings": self.findings,
            "triggered_by": self.triggered_by,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class BackupLog(Base):
    __tablename__ = "backup_logs"

    id = Column(String, primary_key=True, default=gen_uuid)
    filename = Column(String, nullable=False)
    file_path = Column(String, nullable=False)
    file_size = Column(Integer, default=0)
    status = Column(String, default="running")
    error_message = Column(Text, nullable=True)
    triggered_by = Column(String, default="system")
    notes = Column(Text, nullable=True)
    started_at = Column(DateTime(timezone=True), nullable=False, default=utcnow)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "filename": self.filename,
            "file_path": self.file_path,
            "file_size": self.file_size,
            "status": self.status,
            "error_message": self.error_message,
            "triggered_by": self.triggered_by,
            "notes": self.notes,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class DisasterRecoveryTest(Base):
    __tablename__ = "disaster_recovery_tests"

    id = Column(String, primary_key=True, default=gen_uuid)
    test_type = Column(String, nullable=False)
    status = Column(String, default="running")
    summary = Column(String, nullable=True)
    steps = Column(JSON, nullable=True)
    triggered_by = Column(String, default="system")
    started_at = Column(DateTime(timezone=True), nullable=False, default=utcnow)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "test_type": self.test_type,
            "status": self.status,
            "summary": self.summary,
            "steps": self.steps,
            "triggered_by": self.triggered_by,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class Invoice(Base):
    __tablename__ = "invoices"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    invoice_number = Column(String, unique=True, nullable=False)
    amount_usd = Column(Float, nullable=False)
    amount_coins = Column(Integer, nullable=False)
    status = Column(String, default="pending")
    items = Column(JSON, default=list)
    billing_address = Column(JSON, nullable=True)
    tax_amount = Column(Float, default=0.0)
    total_amount = Column(Float, nullable=False)
    currency = Column(String, default="USD")
    notes = Column(Text, nullable=True)
    paid_at = Column(DateTime(timezone=True), nullable=True)
    pdf_path = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class SupportTicket(Base):
    __tablename__ = "support_tickets"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    subject = Column(String, nullable=False)
    message = Column(Text, nullable=False)
    category = Column(String, default="general")
    priority = Column(String, default="normal")
    status = Column(String, default="open")
    assigned_to = Column(String, nullable=True)
    closed_by = Column(String, nullable=True)
    closed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)

    user = relationship("User", backref="support_tickets")


class SupportTicketReply(Base):
    __tablename__ = "support_ticket_replies"

    id = Column(String, primary_key=True, default=gen_uuid)
    ticket_id = Column(String, ForeignKey("support_tickets.id"), nullable=False, index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    message = Column(Text, nullable=False)
    is_admin = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)

    ticket = relationship("SupportTicket", backref="replies")


class SMSMessage(Base):
    __tablename__ = "sms_messages"

    id = Column(String, primary_key=True, default=gen_uuid)
    order_id = Column(String, ForeignKey("sms_orders.id"), nullable=True, index=True)
    rental_id = Column(String, ForeignKey("number_rentals.id"), nullable=True, index=True)
    phone_number = Column(String, nullable=False)
    sender = Column(String, nullable=True)
    text = Column(Text, nullable=False)
    received_at = Column(DateTime(timezone=True), nullable=False, default=utcnow)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class PriceSnapshot(Base):
    __tablename__ = "price_snapshots"

    id = Column(String, primary_key=True, default=gen_uuid)
    service = Column(String, nullable=False, index=True)
    country = Column(String, nullable=False)
    provider = Column(String, nullable=False)
    provider_price = Column(Float, nullable=False)
    platform_price = Column(Float, nullable=False)
    markup = Column(Float, nullable=False)
    currency = Column(String, default="USD")
    recorded_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class GeoIPCache(Base):
    __tablename__ = "geo_ip_cache"

    id = Column(String, primary_key=True, default=gen_uuid)
    ip_address = Column(String, unique=True, nullable=False, index=True)
    country = Column(String, nullable=True)
    city = Column(String, nullable=True)
    region = Column(String, nullable=True)
    isp = Column(String, nullable=True)
    is_proxy = Column(Boolean, default=False)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)


class CarrierLookupCache(Base):
    __tablename__ = "carrier_lookup_cache"

    id = Column(String, primary_key=True, default=gen_uuid)
    phone_number = Column(String, unique=True, nullable=False, index=True)
    carrier = Column(String, nullable=True)
    country_code = Column(String, nullable=True)
    network_type = Column(String, nullable=True)
    is_voip = Column(Boolean, default=False)
    is_prepaid = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)


class ServiceCountry(Base):
    """الخدمات المتوفرة في كل بلد مع السعر من كل مزوّد — يتم تحديثها دورياً"""
    __tablename__ = "service_countries"

    id = Column(String, primary_key=True, default=gen_uuid)
    service = Column(String, nullable=False, index=True)
    country_code = Column(String, nullable=False, index=True)
    provider = Column(String, nullable=False)
    provider_cost = Column(Float, nullable=False, default=0.0)
    available_count = Column(Integer, default=0)
    currency = Column(String, default="USD")
    is_active = Column(Boolean, default=True)
    last_synced_at = Column(DateTime(timezone=True), nullable=False, default=utcnow)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)

    __table_args__ = (
        UniqueConstraint("service", "country_code", "provider", name="uq_service_country_provider"),
    )


class SyncLog(Base):
    """سجل عمليات المزامنة الدورية للخدمات والبلدان والمخزون"""
    __tablename__ = "sync_logs"

    id = Column(String, primary_key=True, default=gen_uuid)
    sync_type = Column(String, nullable=False, index=True)  # services / stock / all
    status = Column(String, nullable=False, default="running")  # running / success / failed
    providers_synced = Column(JSON, default=list)
    services_count = Column(Integer, default=0)
    countries_count = Column(Integer, default=0)
    errors = Column(JSON, default=list)
    duration_seconds = Column(Float, nullable=True)
    triggered_by = Column(String, default="scheduler")  # scheduler / manual
    started_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class MarkupRule(Base):
    """قواعد الربح — يمكن تخصيصها لكل خدمة/دولة/رتبة مستخدم"""
    __tablename__ = "markup_rules"

    id = Column(String, primary_key=True, default=gen_uuid)
    service = Column(String, nullable=True, index=True)          # None = all services
    country_code = Column(String, nullable=True, index=True)      # None = all countries
    provider = Column(String, nullable=True)                      # None = all providers
    user_tier = Column(String, nullable=True)                     # None = all tiers
    markup_multiplier = Column(Float, nullable=False, default=1.20)
    priority = Column(Integer, default=0)                         # higher = wins
    is_active = Column(Boolean, default=True)
    description = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)
