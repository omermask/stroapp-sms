from datetime import datetime, timezone, date
from decimal import Decimal
from typing import Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.logging import get_logger
from app.domain.models import TaxJurisdictionConfig, TaxReport, TaxExemptionCertificate, \
    PaymentLog, gen_uuid

logger = get_logger(__name__)

DEFAULT_TAX_RATES = {
    "SA": 0.15,
    "AE": 0.05,
    "EG": 0.14,
    "TR": 0.18,
    "US": 0.0,
    "GB": 0.20,
    "DE": 0.19,
    "FR": 0.20,
    "IN": 0.18,
    "CN": 0.13,
    "default": 0.0,
}


class TaxService:
    def __init__(self, db: Session):
        self.db = db

    def get_tax_rate(self, country_code: str, user_id: str = "") -> float:
        config = self.db.query(TaxJurisdictionConfig).filter(
            TaxJurisdictionConfig.country_code == country_code.upper(),
        ).first()

        if config:
            rate = config.tax_rate
        else:
            rate = DEFAULT_TAX_RATES.get(country_code.upper(), DEFAULT_TAX_RATES["default"])

        if user_id:
            exempt = self.db.query(TaxExemptionCertificate).filter(
                TaxExemptionCertificate.user_id == user_id,
                TaxExemptionCertificate.is_active == True,
                (TaxExemptionCertificate.expires_at.is_(None) |
                 (TaxExemptionCertificate.expires_at > datetime.now(timezone.utc))),
            ).first()
            if exempt:
                rate = 0.0

        return rate

    def calculate_tax(self, amount_usd: float, country_code: str,
                      user_id: str = "") -> dict:
        rate = self.get_tax_rate(country_code, user_id)
        tax_amount = amount_usd * rate
        return {
            "amount_usd": amount_usd,
            "tax_rate": rate,
            "tax_amount": tax_amount,
            "total_with_tax": amount_usd + tax_amount,
            "country_code": country_code,
            "is_exempt": rate == 0.0 and bool(user_id),
        }

    def generate_tax_report(self, period_start: date, period_end: date,
                            country_code: str = "") -> TaxReport:
        q = self.db.query(PaymentLog).filter(
            PaymentLog.status == "completed",
            func.date(PaymentLog.created_at) >= period_start,
            func.date(PaymentLog.created_at) <= period_end,
        )
        if country_code:
            q = q.filter(PaymentLog.provider == country_code)

        payments = q.all()
        total_revenue = sum(p.amount_usd for p in payments)
        rate = self.get_tax_rate(country_code) if country_code else DEFAULT_TAX_RATES["default"]
        total_tax = total_revenue * rate

        report = TaxReport(
            id=gen_uuid(),
            period_start=period_start,
            period_end=period_end,
            country_code=country_code or "ALL",
            total_revenue_usd=total_revenue,
            total_tax_usd=total_tax,
            effective_tax_rate=rate,
            transaction_count=len(payments),
            breakdown={"payment_count": len(payments), "average_tax": total_tax / len(payments) if payments else 0},
        )
        self.db.add(report)
        self.db.commit()
        return report

    def get_reports(self, limit: int = 12, offset: int = 0) -> list[TaxReport]:
        return self.db.query(TaxReport).order_by(
            TaxReport.period_start.desc()
        ).offset(offset).limit(limit).all()
