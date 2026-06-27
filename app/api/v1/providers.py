from fastapi import APIRouter, Depends, Request

from app.core.dependencies import get_current_admin
from app.core.response import success_response
from app.domain.models import User
from app.infrastructure.providers import ProviderRouter

router = APIRouter(prefix="/providers", tags=["Providers"])
provider_router = ProviderRouter()


@router.get("")
async def list_providers(request: Request):
    providers = [
        {
            "name": p.name,
            "enabled": p.enabled,
        }
        for p in provider_router.all_providers
    ]
    return success_response(
        providers,
        request_id=getattr(request.state, "request_id", ""),
    )


@router.get("/balances")
async def get_balances(
    request: Request,
    _admin: User = Depends(get_current_admin),
):
    balances = await provider_router.get_balance_summary()
    return success_response(
        balances,
        request_id=getattr(request.state, "request_id", ""),
    )
