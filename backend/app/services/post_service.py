from __future__ import annotations

from datetime import datetime
from typing import Optional

from bson import ObjectId
from fastapi import HTTPException, status

from app.core.utils import to_object_id
from app.repositories.post_repository import PostRepository
from app.repositories.user_repository import UserRepository
from app.schemas.post import (
    CommentCreate,
    CommentInDB,
    CommentPublic,
    CommentUpdate,
    FeedResponse,
    PostCreate,
    PostInDB,
    PostPublic,
    PostUpdate,
)


class PostService:
    def __init__(self, posts: PostRepository, users: UserRepository) -> None:
        self.posts = posts
        self.users = users

    async def create_post(self, author_id: str, payload: PostCreate) -> PostPublic:
        post = PostInDB(author_id=to_object_id(author_id), **payload.model_dump())
        created = await self.posts.create_post(post)
        return await self._enrich_post(created)

    async def update_post(self, post_id: str, user_id: str, payload: PostUpdate) -> PostPublic:
        post = await self.posts.get_post(post_id)
        if not post:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")
        if str(post.author_id) != user_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Cannot edit this post")
        updates = payload.model_dump(exclude_none=True)
        updated = await self.posts.update_post(post_id, updates)
        return await self._enrich_post(updated)

    async def delete_post(self, post_id: str, user_id: str) -> None:
        post = await self.posts.get_post(post_id)
        if not post:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")
        if str(post.author_id) != user_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Cannot delete this post")
        await self.posts.delete_post(post_id)

    async def like_post(self, post_id: str, user_id: str) -> PostPublic:
        await self.posts.like_post(post_id, user_id)
        post = await self.posts.get_post(post_id)
        if not post:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")
        return await self._enrich_post(post)

    async def unlike_post(self, post_id: str, user_id: str) -> PostPublic:
        await self.posts.unlike_post(post_id, user_id)
        post = await self.posts.get_post(post_id)
        if not post:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")
        return await self._enrich_post(post)

    async def add_comment(self, post_id: str, author_id: str, payload: CommentCreate) -> CommentPublic:
        post = await self.posts.get_post(post_id)
        if not post:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")
        comment = CommentInDB(post_id=post.id, author_id=to_object_id(author_id), **payload.model_dump())
        created = await self.posts.add_comment(comment)
        return await self._enrich_comment(created)

    async def update_comment(self, comment_id: str, user_id: str, payload: CommentUpdate) -> CommentPublic:
        updates = payload.model_dump(exclude_none=True)
        if not updates:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No updates provided")
        updated = await self.posts.update_comment(comment_id, updates)
        if not updated or str(updated.author_id) != user_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Comment not found")
        return await self._enrich_comment(updated)

    async def delete_comment(self, comment_id: str, user_id: str) -> None:
        deleted = await self.posts.delete_comment(comment_id, user_id)
        if not deleted:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Comment not found")

    async def list_feed(self, *, limit: int = 20, offset: int = 0, department: Optional[str] = None) -> FeedResponse:
        posts = await self.posts.list_feed(skip=offset, limit=limit, department=department)
        items = [await self._enrich_post(p) for p in posts]
        total = await self.posts.collection.count_documents({})
        next_cursor = None
        if len(items) == limit:
            next_cursor = str(items[-1].created_at.timestamp())
        return FeedResponse(items=items, total=total, next_cursor=next_cursor)

    async def get_post(self, post_id: str) -> PostPublic:
        post = await self.posts.get_post(post_id)
        if not post:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")
        return await self._enrich_post(post)

    async def list_comments(self, post_id: str, *, limit: int = 50, offset: int = 0) -> list[CommentPublic]:
        comments = await self.posts.list_comments(post_id, skip=offset, limit=limit)
        return [await self._enrich_comment(c) for c in comments]

    async def _enrich_post(self, post: PostInDB | None) -> PostPublic:
        if not post:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")
        comment_count = await self.posts.comments_count(post.id)
        like_count = len(post.like_user_ids)
        author = await self.users.get_by_id(post.author_id)
        return PostPublic(
            **post.model_dump(),
            comment_count=comment_count,
            like_count=like_count,
        )

    async def _enrich_comment(self, comment: CommentInDB) -> CommentPublic:
        author = await self.users.get_by_id(comment.author_id)
        author_public = None
        if author:
            author_public = {
                "id": str(author.id),
                "full_name": author.full_name,
                "avatar_url": author.avatar_url,
                "username": author.username,
            }
        return CommentPublic(**comment.model_dump(), author=author_public)
