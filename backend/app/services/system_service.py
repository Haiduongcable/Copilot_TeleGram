from __future__ import annotations

from datetime import datetime, timedelta

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.schemas.system import MetricsResponse


class SystemService:
    def __init__(self, db: AsyncIOMotorDatabase, started_at: datetime) -> None:
        self.db = db
        self.started_at = started_at

    async def get_metrics(self) -> MetricsResponse:
        now = datetime.utcnow()
        start_of_day = datetime(now.year, now.month, now.day)
        total_users = await self.db.users.count_documents({})
        posts_today = await self.db.posts.count_documents({"created_at": {"$gte": start_of_day}})
        messages_today = await self.db.messages.count_documents({"created_at": {"$gte": start_of_day}})
        storage_agg = await self.db.users.aggregate([
            {"$group": {"_id": None, "total": {"$sum": "$storage_used"}}}
        ]).to_list(length=1)
        storage_used = storage_agg[0]["total"] if storage_agg else 0
        return MetricsResponse(
            total_users=total_users,
            posts_today=posts_today,
            messages_today=messages_today,
            storage_used_mb=round(storage_used / (1024 * 1024), 2),
            uptime_seconds=(now - self.started_at).total_seconds(),
        )
