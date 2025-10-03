from __future__ import annotations

from typing import List, Optional

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.utils import to_object_id
from app.repositories.base import BaseRepository
from app.schemas.notification import NotificationInDB


class NotificationRepository(BaseRepository[NotificationInDB]):
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        super().__init__(db, "notifications")

    async def create_notification(self, notification: NotificationInDB) -> NotificationInDB:
        data = notification.model_dump(by_alias=True, exclude_none=True)
        result = await self.collection.insert_one(data)
        notification.id = result.inserted_id
        return notification

    async def list_for_user(self, user_id: str | ObjectId, *, limit: int = 50, skip: int = 0) -> tuple[List[NotificationInDB], int]:
        query = {"recipient_id": to_object_id(user_id)}
        cursor = self.collection.find(query).sort([("created_at", -1)]).skip(skip).limit(limit)
        documents = await cursor.to_list(length=limit)
        total = await self.collection.count_documents(query)
        return [NotificationInDB(**doc) for doc in documents], total

    async def mark_as_read(self, notification_id: str | ObjectId) -> None:
        await self.collection.update_one(
            {"_id": to_object_id(notification_id)},
            {"$set": {"read": True}},
        )

    async def mark_all_as_read(self, user_id: str | ObjectId) -> int:
        result = await self.collection.update_many(
            {"recipient_id": to_object_id(user_id), "read": False},
            {"$set": {"read": True}},
        )
        return result.modified_count

    async def unread_count(self, user_id: str | ObjectId) -> int:
        return await self.collection.count_documents({"recipient_id": to_object_id(user_id), "read": False})
