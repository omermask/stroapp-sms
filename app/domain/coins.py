from sqlalchemy.orm import Session

from app.core.config import get_settings, get_app_setting


class CoinsEngine:
    @staticmethod
    def _get_rates(db: Session | None = None):
        s = get_settings()
        if db:
            return (
                get_app_setting(db, "coins_per_usd", s.coins_per_usd),
                get_app_setting(db, "default_markup", s.default_markup),
            )
        return s.coins_per_usd, s.default_markup

    @staticmethod
    def usd_to_coins(usd_amount: float, db: Session | None = None) -> int:
        coins_per_usd, _ = CoinsEngine._get_rates(db)
        return max(1, round(usd_amount * coins_per_usd))

    @staticmethod
    def coins_to_usd(coins: int, db: Session | None = None) -> float:
        coins_per_usd, _ = CoinsEngine._get_rates(db)
        return coins / coins_per_usd

    @staticmethod
    def apply_markup(provider_price: float, db: Session | None = None) -> float:
        _, default_markup = CoinsEngine._get_rates(db)
        return provider_price * default_markup

    @staticmethod
    def calculate_cost(provider_price: float, db: Session | None = None) -> int:
        return CoinsEngine.usd_to_coins(CoinsEngine.apply_markup(provider_price, db), db)

    @staticmethod
    def admin_profit(order_cost_coins: int, db: Session | None = None) -> int:
        _, markup = CoinsEngine._get_rates(db)
        if markup <= 1.0:
            return 0
        markup_rate = markup - 1.0
        return max(0, round(order_cost_coins * markup_rate / markup))
