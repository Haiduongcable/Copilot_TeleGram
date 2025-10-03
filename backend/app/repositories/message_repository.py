from __future__ import annotations

from datetime import datetime
from typing import Optional

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.utils import to_object_id
from app.repositories.base import BaseRepository
from app.schemas.message import ChatInDB, ChatType, MessageInDB


class ChatRepository(BaseRepository[ChatInDB]):
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        super().__init__(db, "chats")

    async def create_chat(self, chat: ChatInDB) -> ChatInDB:
        data = chat.model_dump(by_alias=True, exclude_none=True)
        result = await self.collection.insert_one(data)
        chat.id = result.inserted_id
        return chat

    async def get_chat(self, chat_id: str | ObjectId) -> Optional[ChatInDB]:
        document = await self.collection.find_one({"_id": to_object_id(chat_id)})
        return ChatInDB(**document) if document else None

    async def find_direct_chat(self, user_a: str | ObjectId, user_b: str | ObjectId) -> Optional[ChatInDB]:
        query = {
            "type": ChatType.DIRECT.value,
            "member_ids": {"$all": [to_object_id(user_a), to_object_id(user_b)], "$size": 2},
        }
        document = await self.collection.find_one(query)
        return ChatInDB(**document) if document else None

    async def update_chat(self, chat_id: str | ObjectId, updates: dict) -> Optional[ChatInDB]:
        updates["updated_at"] = datetime.utcnow()
        await self.collection.update_one({"_id": to_object_id(chat_id)}, {"$set": updates})
        return await self.get_chat(chat_id)

    async def add_members(self, chat_id: str | ObjectId, member_ids: list[str | ObjectId]) -> None:
        await self.collection.update_one(
            {"_id": to_object_id(chat_id)},
            {"$addToSet": {"member_ids": {"$each": [to_object_id(i) for i in member_ids]}}},
        )

    async def remove_members(self, chat_id: str | ObjectId, member_ids: list[str | ObjectId]) -> None:
        await self.collection.update_one(
            {"_id": to_object_id(chat_id)},
            {"$pull": {"member_ids": {"$in": [to_object_id(i) for i in member_ids]}}},
        )

    async def list_user_chats(self, user_id: str | ObjectId, limit: int = 50) -> list[ChatInDB]:
        cursor = self.collection.find({"member_ids": to_object_id(user_id)}).sort([("updated_at", -1)]).limit(limit)
        documents = await cursor.to_list(length=limit)
        return [ChatInDB(**doc) for doc in documents]


class MessageRepository(BaseRepository[MessageInDB]):
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        super().__init__(db, "messages")

    async def create_message(self, message: MessageInDB) -> MessageInDB:
        data = message.model_dump(by_alias=True, exclude_none=True)
        result = await self.collection.insert_one(data)
        message.id = result.inserted_id
        return message

    async def list_messages(self, chat_id: str | ObjectId, *, limit: int = 50, before: Optional[datetime] = None) -> list[MessageInDB]:
        filters: dict = {"chat_id": to_object_id(chat_id)}
        if before:
            filters["created_at"] = {"$lt": before}
        cursor = self.collection.find(filters).sort([("created_at", -1)]).limit(limit)
        documents = await cursor.to_list(length=limit)
        return [MessageInDB(**doc) for doc in documents]

    async def get_message(self, message_id: str | ObjectId) -> Optional[MessageInDB]:
        document = await self.collection.find_one({"_id": to_object_id(message_id)})
        return MessageInDB(**document) if document else None

    async def update_message(self, message_id: str | ObjectId, updates: dict) -> Optional[MessageInDB]:
        updates["updated_at"] = datetime.utcnow()
        updates["edited"] = True
        await self.collection.update_one({"_id": to_object_id(message_id)}, {"$set": updates})
        return await self.get_message(message_id)

    async def delete_message(self, message_id: str | ObjectId, for_everyone: bool = False) -> bool:
        if for_everyone:
            result = await self.collection.delete_one({"_id": to_object_id(message_id)})
            return result.deleted_count > 0
        result = await self.collection.update_one(
            {"_id": to_object_id(message_id)},
            {"$set": {"content": None, "attachments": [], "type": "system"}},
        )
        return result.modified_count > 0

    async def mark_as_seen(self, message_id: str | ObjectId, user_id: str | ObjectId) -> None:
        await self.collection.update_one(
            {"_id": to_object_id(message_id)},
            {"$addToSet": {"seen_by": to_object_id(user_id)}},
        )

    async def count_unread(self, chat_id: str | ObjectId, user_id: str | ObjectId) -> int:
        return await self.collection.count_documents(
            {"chat_id": to_object_id(chat_id), "seen_by": {"$ne": to_object_id(user_id)}},
        )
