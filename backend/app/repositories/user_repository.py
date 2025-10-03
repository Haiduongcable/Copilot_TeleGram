from __future__ import annotations

from datetime import datetime
from typing import Optional

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.utils import to_object_id
from app.repositories.base import BaseRepository
from app.schemas.user import UserInDB, UserStatus


class UserRepository(BaseRepository[UserInDB]):
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        super().__init__(db, "users")

    async def create_user(self, user: UserInDB) -> UserInDB:
        data = user.model_dump(by_alias=True, exclude_none=True)
        result = await self.collection.insert_one(data)
        user.id = result.inserted_id
        return user

    async def get_by_email(self, email: str) -> Optional[UserInDB]:
        document = await self.collection.find_one({"email": email})
        return UserInDB(**document) if document else None

    async def get_by_username(self, username: str) -> Optional[UserInDB]:
        document = await self.collection.find_one({"username": username})
        return UserInDB(**document) if document else None

    async def get_by_id(self, user_id: str | ObjectId) -> Optional[UserInDB]:
        document = await self.collection.find_one({"_id": to_object_id(user_id)})
        return UserInDB(**document) if document else None

    async def update_user(self, user_id: str | ObjectId, updates: dict) -> Optional[UserInDB]:
        updates["updated_at"] = datetime.utcnow()
        await self.collection.update_one({"_id": to_object_id(user_id)}, {"$set": updates})
        return await self.get_by_id(user_id)

    async def update_password(self, user_id: str | ObjectId, hashed_password: str) -> bool:
        result = await self.collection.update_one(
            {"_id": to_object_id(user_id)},
            {"$set": {"hashed_password": hashed_password, "updated_at": datetime.utcnow()}},
        )
        return result.modified_count > 0

    async def set_status(self, user_id: str | ObjectId, status: UserStatus) -> None:
        await self.collection.update_one(
            {"_id": to_object_id(user_id)},
            {"$set": {"status": status.value, "last_seen_at": datetime.utcnow()}},
        )

    async def record_login(self, user_id: str | ObjectId) -> None:
        await self.collection.update_one(
            {"_id": to_object_id(user_id)},
            {"$set": {"last_login_at": datetime.utcnow(), "last_seen_at": datetime.utcnow(), "status": UserStatus.ONLINE.value}},
        )

    async def search_users(self, query: str | None, department: str | None, *, skip: int, limit: int) -> tuple[list[UserInDB], int]:
        filters: dict = {}
        if query:
            filters["$or"] = [
                {"full_name": {"$regex": query, "$options": "i"}},
                {"username": {"$regex": query, "$options": "i"}},
                {"email": {"$regex": query, "$options": "i"}},
            ]
        if department:
            filters["department"] = department

        cursor = self.collection.find(filters).sort([("full_name", 1)]).skip(skip).limit(limit)
        documents = await cursor.to_list(length=limit)
        total = await self.collection.count_documents(filters)
        return [UserInDB(**doc) for doc in documents], total

    async def list_users(self, *, skip: int, limit: int) -> list[UserInDB]:
        cursor = self.collection.find({}).sort([("full_name", 1)]).skip(skip).limit(limit)
        documents = await cursor.to_list(length=limit)
        return [UserInDB(**doc) for doc in documents]

    async def push_storage_delta(self, user_id: str | ObjectId, delta_bytes: int) -> None:
        await self.collection.update_one(
            {"_id": to_object_id(user_id)},
            {"$inc": {"storage_used": delta_bytes}},
        )
