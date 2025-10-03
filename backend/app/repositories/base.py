from __future__ import annotations

from typing import Any, Generic, Iterable, Optional, TypeVar

from motor.motor_asyncio import AsyncIOMotorCollection, AsyncIOMotorDatabase

T = TypeVar("T")


class BaseRepository(Generic[T]):
    def __init__(self, db: AsyncIOMotorDatabase, collection_name: str) -> None:
        self.db = db
        self.collection: AsyncIOMotorCollection = db[collection_name]

    async def insert_one(self, document: dict[str, Any]) -> Any:
        result = await self.collection.insert_one(document)
        return result.inserted_id

    async def find_one(self, query: dict[str, Any], projection: Optional[dict[str, Any]] = None) -> Optional[dict[str, Any]]:
        return await self.collection.find_one(query, projection)

    async def update_one(self, query: dict[str, Any], update: dict[str, Any]) -> bool:
        result = await self.collection.update_one(query, update)
        return result.modified_count > 0

    async def delete_one(self, query: dict[str, Any]) -> bool:
        result = await self.collection.delete_one(query)
        return result.deleted_count > 0

    async def find_many(self, query: dict[str, Any], *, skip: int = 0, limit: int = 20, sort: Iterable[tuple[str, int]] | None = None) -> list[dict[str, Any]]:
        cursor = self.collection.find(query)
        if sort:
            cursor = cursor.sort(list(sort))
        if skip:
            cursor = cursor.skip(skip)
        if limit:
            cursor = cursor.limit(limit)
        return await cursor.to_list(length=limit)

    async def count_documents(self, query: dict[str, Any]) -> int:
        return await self.collection.count_documents(query)
