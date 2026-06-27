from functools import lru_cache

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "StroApp SMS"
    version: str = "1.0.0"
    environment: str = "development"
    debug: bool = False

    database_url: str
    database_echo: bool = False

    redis_url: str = "redis://localhost:6379/0"

    secret_key: str
    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    jwt_expiration_hours: int = 24
    jwt_refresh_expiration_days: int = 30

    port: int = 9527
    base_url: str = "http://localhost:9527"
    allowed_hosts_raw: str = "*"  # N-5: يجب تحديد المضيفين المسموح بهم في بيئة الإنتاج (ALLOWED_HOSTS_RAW)
    cors_origins_raw: str = "http://localhost:9527,http://localhost:3000"

    smsman_api_key: str = ""
    fivesim_api_key: str = ""
    smsactivate_api_key: str = ""
    smspool_api_key: str = ""

    google_client_id: str = ""
    google_client_secret: str = ""
    apple_client_id: str = ""
    apple_private_key: str = ""
    apple_issuer_id: str = ""
    apple_key_id: str = ""
    apple_bundle_id: str = ""
    apple_app_apple_id: int = 0

    google_merchant_id: str = ""
    google_play_service_account_path: str = ""
    google_play_rtdn_token: str = ""
    apple_merchant_id: str = ""
    apple_merchant_cert_path: str = ""
    apple_merchant_key_path: str = ""
    apple_shared_secret: str = ""

    coins_per_usd: int = 100
    default_markup: float = 1.15

    temp_emails_per_month: int = 8

    sentry_dsn: str = ""
    sentry_environment: str = "production"
    sentry_traces_sample_rate: float = 0.2

    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_from: str = ""
    smtp_tls: bool = True

    turnstile_secret_key: str = ""

    fcm_server_key: str = ""
    fcm_vapid_key: str = ""
    fcm_service_account_json: str = ""

    onesignal_app_id: str = ""
    onesignal_api_key: str = ""
    telegram_bot_token: str = ""

    # M-5 FIX: استخدام مسار دائم بدلاً من /tmp (يُمسح عند إعادة التشغيل)
    # يمكن تغييره عبر متغير البيئة BACKUP_DIR
    backup_dir: str = "/var/lib/stroapp/backups"
    backup_retention_days: int = 30

    security_audit_cron: str = "0 3 * * 0"

    rate_limit_per_minute: int = 2000
    rate_limit_burst: int = 2000

    sms_polling_initial_interval: int = 5
    sms_polling_later_interval: int = 10
    sms_polling_max_minutes: int = 10
    sms_timeout: int = 300

    default_page_size: int = 20
    max_page_size: int = 100

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    @field_validator("secret_key", "jwt_secret_key")
    @classmethod
    def validate_key_length(cls, value):
        if not value:
            raise ValueError("secret_key and jwt_secret_key are required")
        if len(value) < 32:
            raise ValueError("Secret keys must be at least 32 characters long")
        return value

    @field_validator("database_url")
    @classmethod
    def validate_database_url(cls, value):
        if not value:
            raise ValueError("Database URL is required")
        if not value.startswith("postgresql"):
            raise ValueError("Only PostgreSQL is supported (postgresql://...)")
        return value

    @field_validator("base_url")
    @classmethod
    def validate_base_url(cls, value):
        if not value.startswith(("http://", "https://")):
            raise ValueError("Base URL must start with http:// or https://")
        return value

    @property
    def cors_origins(self) -> list[str]:
        origins = [h.strip() for h in self.cors_origins_raw.split(",") if h.strip()]
        if self.environment == "production":
            origins = [o for o in origins if o != "*"]
        return origins

    @property
    def allowed_hosts(self) -> list[str]:
        hosts = [h.strip() for h in self.allowed_hosts_raw.split(",") if h.strip()]
        # N-5 FIX: تحذير في حالة استخدام "*" في الإنتاج لمنع Host Header Injection
        if self.environment == "production" and "*" in hosts:
            import logging
            logging.getLogger(__name__).warning(
                "[SECURITY] ALLOWED_HOSTS_RAW is set to '*' in production. "
                "Set it to your actual domain(s) to prevent host header injection attacks."
            )
        return hosts


@lru_cache
def get_settings() -> Settings:
    return Settings()


def get_app_setting(db, key: str, default):
    """Read a setting from AppSetting table, falling back to default."""
    try:
        from app.domain.models import AppSetting
        row = db.query(AppSetting).filter(AppSetting.key == key).first()
        if row and row.value is not None:
            return type(default)(row.value)
    except Exception:
        pass
    return default
