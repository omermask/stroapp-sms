from datetime import date, datetime
from typing import Optional

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.exceptions import AppException
from app.core.response import success_response
from app.domain.models import User
from app.services.audit_service import AuditService
from app.services.revenue_service import RevenueService

router = APIRouter(prefix="/admin/financial", tags=["Admin Financial"])


class AdjustRevenue(BaseModel):
    recognition_id: Optional[str] = None
    adjustment_type: str = "correction"
    amount: float = 0
    currency: str = "SAR"
    reason: Optional[str] = None


class UpsertTaxConfig(BaseModel):
    jurisdiction: str
    tax_type: str = "vat"
    tax_rate: float = 0.0
    is_active: bool = True


class GenerateTaxReport(BaseModel):
    period_start: str
    period_end: str
    jurisdiction: str = "ALL"
    report_type: str = "vat"


class UpsertAgreement(BaseModel):
    provider_name: str
    commission_rate: float = 0.0
    billing_cycle: str = "monthly"
    terms: Optional[str] = None


class RecordCost(BaseModel):
    provider_name: str
    service_type: Optional[str] = None
    cost_per_unit: float = 0.0
    units_consumed: int = 0
    total_cost: float = 0.0
    currency: str = "SAR"
    cost_date: Optional[date] = None


class CreateSettlement(BaseModel):
    provider_name: str
    period_start: Optional[date] = None
    period_end: Optional[date] = None
    gross_amount: float = 0.0
    commission_amount: float = 0.0
    net_amount: float = 0.0


@router.get("/revenue")
async def get_revenue_summary(
    start_date: date = Query(...),
    end_date: date = Query(...),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = RevenueService.get_revenue_summary(db, start_date, end_date)
    return success_response(result)


@router.get("/revenue/details")
async def get_revenue_details(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = RevenueService.get_revenue_details(db, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.post("/revenue/adjust")
async def adjust_revenue(
    body: AdjustRevenue,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    data = body.model_dump()
    data["approved_by"] = admin_user.id
    result = RevenueService.adjust_revenue(db, data)

    AuditService.log(db, admin_user.id, "revenue.adjust", "revenue", result.get("id", ""),
                    {"adjustment_type": data["adjustment_type"], "amount": data["amount"]})
    return success_response(result)


@router.get("/revenue/adjustments")
async def get_adjustments(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = RevenueService.get_adjustments(db, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/tax/configs")
async def get_tax_configs(
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = RevenueService.get_tax_configs(db)
    return success_response(result)


@router.put("/tax/configs")
async def upsert_tax_config(
    body: UpsertTaxConfig,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = RevenueService.upsert_tax_config(db, body.model_dump())

    AuditService.log(db, admin_user.id, "tax.config.upsert", "tax_config", result.get("id", ""),
                    {"jurisdiction": body.jurisdiction, "tax_rate": body.tax_rate})
    return success_response(result)


@router.post("/tax/reports")
async def generate_tax_report(
    body: GenerateTaxReport,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = RevenueService.generate_tax_report(db, body.model_dump())
    return success_response(result)


@router.get("/tax/reports")
async def get_tax_reports(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = RevenueService.get_tax_reports(db, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/tax/exemptions")
async def get_tax_exemptions(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = RevenueService.get_tax_exemptions(db, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/providers/agreements")
async def get_agreements(
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = RevenueService.get_agreements(db)
    return success_response(result)


@router.put("/providers/agreements")
async def upsert_agreement(
    body: UpsertAgreement,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = RevenueService.upsert_agreement(db, body.model_dump())
    return success_response(result)


@router.get("/providers/costs")
async def get_costs(
    provider_name: Optional[str] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = RevenueService.get_costs(db, provider_name, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.post("/providers/costs")
async def record_cost(
    body: RecordCost,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    data = body.model_dump()
    data["recorded_by"] = admin_user.id
    result = RevenueService.record_cost(db, data)

    AuditService.log(db, admin_user.id, "cost.record", "provider_cost", result.get("id", ""),
                    {"provider_name": body.provider_name, "total_cost": body.total_cost})
    return success_response(result)


@router.get("/providers/settlements")
async def get_settlements(
    provider_name: Optional[str] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = RevenueService.get_settlements(db, provider_name, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.post("/providers/settlements")
async def create_settlement(
    body: CreateSettlement,
    admin_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    if body.gross_amount < 0 or body.commission_amount < 0 or body.net_amount < 0:
        raise AppException("VALIDATION_ERROR", "المبالغ يجب أن تكون غير سالبة", 400)
    if body.period_start and body.period_end and body.period_start > body.period_end:
        raise AppException("VALIDATION_ERROR", "period_start يجب أن يكون قبل period_end", 400)
    result = RevenueService.create_settlement(db, body.model_dump())

    AuditService.log(db, admin_user.id, "settlement.create", "settlement", result.get("id", ""),
                    {"provider_name": body.provider_name, "gross_amount": body.gross_amount})
    return success_response(result)


@router.get("/providers/reconciliations")
async def get_provider_reconciliations(
    provider_name: Optional[str] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = RevenueService.get_provider_reconciliations(db, provider_name, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/statements")
async def get_financial_statements(
    period: Optional[str] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = RevenueService.get_financial_statements(db, period, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/metrics")
async def get_operating_metrics(
    period_from: Optional[date] = None,
    period_to: Optional[date] = None,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = RevenueService.get_operating_metrics(db, period_from, period_to)
    return success_response(result)
