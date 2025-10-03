from datetime import datetime

from pydantic import BaseModel


class HealthResponse(BaseModel):
    status: str
    timestamp: datetime


class MetricsResponse(BaseModel):
    total_users: int
    posts_today: int
    messages_today: int
    storage_used_mb: float
    uptime_seconds: float
