from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.exceptions import AppException
from app.core.logging import get_logger
from app.core.response import success_response
from app.domain.models import MarkupRule, ServiceCountry, SyncLog, User, gen_uuid
from app.infrastructure.providers.router import ProviderRouter
from app.services.sync_service import SyncOrchestrator, SyncService

logger = get_logger(__name__)
router = APIRouter(prefix="/admin/sync", tags=["Admin Sync"])
sync_service = SyncService()
sync_orchestrator = SyncOrchestrator()
provider_router = ProviderRouter()


class SyncTriggerRequest(BaseModel):
    sync_type: str = "all"


class OrchestratorStartRequest(BaseModel):
    interval: int = 3600


class MarkupRuleCreate(BaseModel):
    service: str | None = None
    country_code: str | None = None
    provider: str | None = None
    user_tier: str | None = None
    markup_multiplier: float = 1.20
    priority: int = 0
    description: str | None = None


class MarkupRuleUpdate(BaseModel):
    markup_multiplier: float | None = None
    priority: int | None = None
    is_active: bool | None = None
    description: str | None = None


@router.post("/trigger")
async def trigger_sync(
    request: Request,
    body: SyncTriggerRequest,
    _admin: User = Depends(get_current_admin),
):
    if body.sync_type == "stock":
        result = await sync_service.sync_stock(triggered_by="manual")
    else:
        result = await sync_service.sync_all(triggered_by="manual")
    return success_response(
        result,
        request_id=getattr(request.state, "request_id", ""),
    )


@router.get("/status")
async def sync_status(
    request: Request,
    limit: int = Query(20, le=100),
    _admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    logs = (
        db.query(SyncLog)
        .order_by(SyncLog.created_at.desc())
        .limit(limit)
        .all()
    )
    return success_response(
        [
            {
                "id": l.id,
                "sync_type": l.sync_type,
                "status": l.status,
                "providers_synced": l.providers_synced,
                "services_count": l.services_count,
                "countries_count": l.countries_count,
                "errors": l.errors,
                "duration_seconds": l.duration_seconds,
                "triggered_by": l.triggered_by,
                "started_at": l.started_at.isoformat() if l.started_at else None,
                "completed_at": l.completed_at.isoformat() if l.completed_at else None,
            }
            for l in logs
        ],
        request_id=getattr(request.state, "request_id", ""),
    )


@router.get("/orchestrator")
async def orchestrator_status(
    request: Request,
    _admin: User = Depends(get_current_admin),
):
    task = sync_orchestrator._task
    return success_response(
        {
            "running": task is not None and not task.done(),
            "cancelled": task is not None and task.cancelled() if hasattr(task, "cancelled") else False,
        },
        request_id=getattr(request.state, "request_id", ""),
    )


@router.post("/orchestrator/start")
async def start_orchestrator(
    request: Request,
    body: OrchestratorStartRequest,
    _admin: User = Depends(get_current_admin),
):
    sync_orchestrator.start(interval_seconds=body.interval)
    return success_response(
        {"interval_seconds": body.interval, "status": "started"},
        request_id=getattr(request.state, "request_id", ""),
    )


@router.post("/orchestrator/stop")
async def stop_orchestrator(
    request: Request,
    _admin: User = Depends(get_current_admin),
):
    sync_orchestrator.stop()
    return success_response(
        {"status": "stopped"},
        request_id=getattr(request.state, "request_id", ""),
    )


@router.get("/markup-rules")
async def list_markup_rules(
    request: Request,
    _admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    rules = (
        db.query(MarkupRule)
        .order_by(MarkupRule.priority.desc(), MarkupRule.created_at.desc())
        .all()
    )
    return success_response(
        [
            {
                "id": r.id,
                "service": r.service,
                "country_code": r.country_code,
                "provider": r.provider,
                "user_tier": r.user_tier,
                "markup_multiplier": r.markup_multiplier,
                "priority": r.priority,
                "is_active": r.is_active,
                "description": r.description,
                "created_at": r.created_at.isoformat() if r.created_at else None,
            }
            for r in rules
        ],
        request_id=getattr(request.state, "request_id", ""),
    )


@router.post("/markup-rules")
async def create_markup_rule(
    body: MarkupRuleCreate,
    request: Request,
    _admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    if body.markup_multiplier < 1.0:
        body.markup_multiplier = 1.0
    rule = MarkupRule(
        id=gen_uuid(),
        service=body.service,
        country_code=body.country_code.upper() if body.country_code else None,
        provider=body.provider,
        user_tier=body.user_tier,
        markup_multiplier=body.markup_multiplier,
        priority=body.priority,
        description=body.description,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db.add(rule)
    db.commit()
    db.refresh(rule)
    return success_response(
        {
            "id": rule.id,
            "service": rule.service,
            "country_code": rule.country_code,
            "provider": rule.provider,
            "markup_multiplier": rule.markup_multiplier,
            "priority": rule.priority,
            "is_active": rule.is_active,
        },
        request_id=getattr(request.state, "request_id", ""),
    )


@router.put("/markup-rules/{rule_id}")
async def update_markup_rule(
    rule_id: str,
    body: MarkupRuleUpdate,
    request: Request,
    _admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    rule = db.query(MarkupRule).filter(MarkupRule.id == rule_id).first()
    if not rule:
        raise AppException("NOT_FOUND", "القاعدة غير موجودة", 404)

    if body.markup_multiplier is not None:
        rule.markup_multiplier = max(1.0, body.markup_multiplier)
    if body.priority is not None:
        rule.priority = body.priority
    if body.is_active is not None:
        rule.is_active = body.is_active
    if body.description is not None:
        rule.description = body.description
    rule.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(rule)
    return success_response(
        {
            "id": rule.id,
            "service": rule.service,
            "markup_multiplier": rule.markup_multiplier,
            "is_active": rule.is_active,
        },
        request_id=getattr(request.state, "request_id", ""),
    )


@router.delete("/markup-rules/{rule_id}")
async def delete_markup_rule(
    rule_id: str,
    request: Request,
    _admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    rule = db.query(MarkupRule).filter(MarkupRule.id == rule_id).first()
    if not rule:
        raise AppException("NOT_FOUND", "القاعدة غير موجودة", 404)
    db.delete(rule)
    db.commit()
    return success_response(
        {"deleted": True},
        request_id=getattr(request.state, "request_id", ""),
    )


@router.get("/service-countries")
async def list_provider_services(
    request: Request,
    service: str = Query(default=None),
    country_code: str = Query(default=None),
    provider: str = Query(default=None),
    limit: int = Query(100, le=500),
    offset: int = Query(0, ge=0),
    _admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    q = db.query(ServiceCountry).filter(ServiceCountry.is_active == True)
    if service:
        q = q.filter(ServiceCountry.service == service)
    if country_code:
        q = q.filter(ServiceCountry.country_code == country_code.upper())
    if provider:
        q = q.filter(ServiceCountry.provider == provider)
    total = q.count()
    records = q.order_by(ServiceCountry.service, ServiceCountry.country_code).offset(offset).limit(limit).all()
    return success_response(
        {
            "total": total,
            "items": [
                {
                    "id": r.id,
                    "service": r.service,
                    "country_code": r.country_code,
                    "provider": r.provider,
                    "provider_cost": r.provider_cost,
                    "available_count": r.available_count,
                    "last_synced_at": r.last_synced_at.isoformat() if r.last_synced_at else None,
                }
                for r in records
            ],
        },
        request_id=getattr(request.state, "request_id", ""),
    )
