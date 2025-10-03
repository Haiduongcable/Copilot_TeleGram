from __future__ import annotations

from datetime import datetime

from fastapi import APIRouter, Depends, Request

from app.core.dependencies import get_db
from app.schemas.system import HealthResponse, MetricsResponse
from app.services.system_service import SystemService

router = APIRouter(tags=["system"])


@router.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    return HealthResponse(status="ok", timestamp=datetime.utcnow())


@router.get("/metrics", response_model=MetricsResponse)
async def metrics(request: Request, db=Depends(get_db)) -> MetricsResponse:
    started_at: datetime = getattr(request.app.state, "started_at", datetime.utcnow())
    service = SystemService(db, started_at)
    return await service.get_metrics()
