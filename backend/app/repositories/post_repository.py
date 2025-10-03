from __future__ import annotations

from datetime import datetime
from typing import Optional

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.utils import to_object_id
from app.repositories.base import BaseRepository
from app.schemas.post import CommentInDB, PostInDB


class PostRepository(BaseRepository[PostInDB]):
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        super().__init__(db, "posts")
        self.comments = db["comments"]

    async def create_post(self, post: PostInDB) -> PostInDB:
        data = post.model_dump(by_alias=True, exclude_none=True)
        result = await self.collection.insert_one(data)
        post.id = result.inserted_id
        return post

    async def get_post(self, post_id: str | ObjectId) -> Optional[PostInDB]:
        document = await self.collection.find_one({"_id": to_object_id(post_id)})
        return PostInDB(**document) if document else None

    async def update_post(self, post_id: str | ObjectId, updates: dict) -> Optional[PostInDB]:
        updates["updated_at"] = datetime.utcnow()
        await self.collection.update_one({"_id": to_object_id(post_id)}, {"$set": updates})
        return await self.get_post(post_id)

    async def delete_post(self, post_id: str | ObjectId) -> bool:
        result = await self.collection.delete_one({"_id": to_object_id(post_id)})
        await self.comments.delete_many({"post_id": to_object_id(post_id)})
        return result.deleted_count > 0

    async def list_feed(self, *, skip: int, limit: int, department: Optional[str] = None, author_ids: Optional[list[ObjectId]] = None) -> list[PostInDB]:
        filters: dict = {}
        if department:
            filters["department"] = department
        if author_ids:
            filters["author_id"] = {"$in": author_ids}

        cursor = self.collection.find(filters).sort([("pinned", -1), ("created_at", -1)]).skip(skip).limit(limit)
        documents = await cursor.to_list(length=limit)
        return [PostInDB(**doc) for doc in documents]

    async def like_post(self, post_id: str | ObjectId, user_id: str | ObjectId) -> None:
        await self.collection.update_one(
            {"_id": to_object_id(post_id)},
            {"$addToSet": {"like_user_ids": to_object_id(user_id)}},
        )

    async def unlike_post(self, post_id: str | ObjectId, user_id: str | ObjectId) -> None:
        await self.collection.update_one(
            {"_id": to_object_id(post_id)},
            {"$pull": {"like_user_ids": to_object_id(user_id)}},
        )

    async def add_comment(self, comment: CommentInDB) -> CommentInDB:
        data = comment.model_dump(by_alias=True, exclude_none=True)
        result = await self.comments.insert_one(data)
        comment.id = result.inserted_id
        return comment

    async def update_comment(self, comment_id: str | ObjectId, updates: dict) -> Optional[CommentInDB]:
        updates["updated_at"] = datetime.utcnow()
        await self.comments.update_one({"_id": to_object_id(comment_id)}, {"$set": updates})
        document = await self.comments.find_one({"_id": to_object_id(comment_id)})
        return CommentInDB(**document) if document else None

    async def delete_comment(self, comment_id: str | ObjectId, user_id: str | ObjectId) -> bool:
        result = await self.comments.delete_one({"_id": to_object_id(comment_id), "author_id": to_object_id(user_id)})
        return result.deleted_count > 0

    async def list_comments(self, post_id: str | ObjectId, *, skip: int = 0, limit: int = 50) -> list[CommentInDB]:
        cursor = self.comments.find({"post_id": to_object_id(post_id)}).sort([("created_at", 1)]).skip(skip).limit(limit)
        documents = await cursor.to_list(length=limit)
        return [CommentInDB(**doc) for doc in documents]

    async def comments_count(self, post_id: str | ObjectId) -> int:
        return await self.comments.count_documents({"post_id": to_object_id(post_id)})
