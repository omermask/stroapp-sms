import logging

from app.core.config import get_settings

logger = logging.getLogger(__name__)


def init_sentry():
    settings = get_settings()
    if not settings.sentry_dsn:
        return
    try:
        import sentry_sdk  # lazy import — sentry_sdk can crash on Python 3.14
        sentry_sdk.init(
            dsn=settings.sentry_dsn,
            environment=settings.sentry_environment,
            traces_sample_rate=settings.sentry_traces_sample_rate,
            send_default_pii=False,
        )
        logger.info("Sentry initialized successfully")
    except Exception as e:
        logger.warning(f"Failed to initialize Sentry: {e}")
