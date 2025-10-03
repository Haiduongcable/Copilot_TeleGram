from __future__ import annotations

from datetime import datetime
from typing import Optional

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.utils import to_object_id
from app.repositories.base import BaseRepository


class RefreshTokenRepository(BaseRepository[dict]):
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        super().__init__(db, "refresh_tokens")

    async def store_token(self, user_id: str | ObjectId, token: str, expires_at: datetime, user_agent: str | None) -> None:
        await self.collection.insert_one(
            {
                "user_id": to_object_id(user_id),
                "token": token,
                "expires_at": expires_at,
                "user_agent": user_agent,
                "created_at": datetime.utcnow(),
            }
        )

    async def revoke_token(self, token: str) -> None:
        await self.collection.delete_one({"token": token})

    async def revoke_all_for_user(self, user_id: str | ObjectId) -> int:
        result = await self.collection.delete_many({"user_id": to_object_id(user_id)})
        return result.deleted_count

    async def is_token_valid(self, token: str) -> bool:
        return await self.collection.count_documents({"token": token}) > 0

    async def get_active_tokens(self, user_id: str | ObjectId) -> list[dict]:
        cursor = self.collection.find({"user_id": to_object_id(user_id)})
        return await cursor.to_list(length=None)

    async def get_token(self, token: str) -> Optional[dict]:
        return await self.collection.find_one({"token": token})
