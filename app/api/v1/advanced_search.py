from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.response import success_response
from app.domain.models import User
from app.services.advanced_search_service import AdvancedSearchService

router = APIRouter(prefix="/admin/search", tags=["Admin Advanced Search"])


@router.get("/global")
async def global_search(
    request: Request,
    q: str = Query(..., min_length=2),
    limit: int = Query(default=5, ge=1, le=20),
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    results = AdvancedSearchService.global_search(db, q, limit)
    return success_response(results, request_id=getattr(request.state, "request_id", ""))


@router.get("/users")
async def search_users(
    request: Request,
    q: str = Query(..., min_length=2),
    limit: int = Query(default=20, ge=1, le=50),
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    results = AdvancedSearchService.search_users(db, q, limit)
    return success_response(results, request_id=getattr(request.state, "request_id", ""))


@router.get("/orders")
async def search_orders(
    request: Request,
    q: str = Query(..., min_length=2),
    limit: int = Query(default=20, ge=1, le=50),
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    results = AdvancedSearchService.search_orders(db, q, limit)
    return success_response(results, request_id=getattr(request.state, "request_id", ""))


@router.get("/transactions")
async def search_transactions(
    request: Request,
    q: str = Query(..., min_length=2),
    limit: int = Query(default=20, ge=1, le=50),
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    results = AdvancedSearchService.search_transactions(db, q, limit)
    return success_response(results, request_id=getattr(request.state, "request_id", ""))


@router.get("/payments")
async def search_payments(
    request: Request,
    q: str = Query(..., min_length=2),
    limit: int = Query(default=20, ge=1, le=50),
    db: Session = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    results = AdvancedSearchService.search_payments(db, q, limit)
    return success_response(results, request_id=getattr(request.state, "request_id", ""))
