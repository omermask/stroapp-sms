from datetime import date

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.response import success_response
from app.domain.models import User
from app.services.pnl_service import PnLService


class GenerateReportRequest(BaseModel):
    period_start: date
    period_end: date


router = APIRouter(prefix="/admin/pnl", tags=["Admin PnL"])


@router.post("/generate")
async def generate_report(
    request: Request,
    body: GenerateReportRequest,
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    report = PnLService.generate_report(db, body.period_start, body.period_end, _admin.email)
    return success_response({
        "id": report.id,
        "period_start": str(report.period_start),
        "period_end": str(report.period_end),
        "total_revenue": report.total_revenue,
        "total_cost": report.total_cost,
        "gross_profit": report.gross_profit,
        "operating_expenses": report.operating_expenses,
        "net_profit": report.net_profit,
        "breakdown": report.breakdown,
        "created_at": report.created_at.isoformat() if report.created_at else None,
    }, request_id=getattr(request.state, "request_id", ""))


@router.get("/reports")
async def list_reports(
    request: Request,
    limit: int = Query(default=12, ge=1, le=52),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    reports = PnLService.get_reports(db, limit, offset)
    return success_response([{
        "id": r.id,
        "period_start": str(r.period_start),
        "period_end": str(r.period_end),
        "total_revenue": r.total_revenue,
        "net_profit": r.net_profit,
        "created_at": r.created_at.isoformat() if r.created_at else None,
    } for r in reports], request_id=getattr(request.state, "request_id", ""))
