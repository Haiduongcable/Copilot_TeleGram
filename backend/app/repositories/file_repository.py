from __future__ import annotations

from typing import List, Optional

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.utils import to_object_id
from app.repositories.base import BaseRepository
from app.schemas.file import FileMetadata


class FileRepository(BaseRepository[FileMetadata]):
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        super().__init__(db, "files")

    async def create_file(self, metadata: FileMetadata) -> FileMetadata:
        data = metadata.model_dump(by_alias=True, exclude_none=True)
        result = await self.collection.insert_one(data)
        metadata.id = result.inserted_id
        return metadata

    async def list_user_files(self, user_id: str | ObjectId) -> List[FileMetadata]:
        cursor = self.collection.find({"owner_id": to_object_id(user_id)}).sort([("created_at", -1)])
        documents = await cursor.to_list(length=None)
        return [FileMetadata(**doc) for doc in documents]

    async def delete_file(self, file_id: str | ObjectId, user_id: str | ObjectId) -> bool:
        result = await self.collection.delete_one({"_id": to_object_id(file_id), "owner_id": to_object_id(user_id)})
        return result.deleted_count > 0

    async def get_file(self, file_id: str | ObjectId) -> Optional[FileMetadata]:
        document = await self.collection.find_one({"_id": to_object_id(file_id)})
        return FileMetadata(**document) if document else None
