from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel
from pydantic import Field

from app.core.object_id import MongoModel, PyObjectId


class AttachmentType(str, Enum):
    IMAGE = "image"
    FILE = "file"


class PostAttachment(BaseModel):
    id: PyObjectId | None = Field(default=None, alias="_id")
    filename: str
    url: str
    content_type: str
    size: int
    type: AttachmentType = AttachmentType.FILE
    thumbnail_url: Optional[str] = None


class PostBase(BaseModel):
    content: str = Field(..., min_length=1, max_length=4000)
    tags: list[str] = Field(default_factory=list)
    department: Optional[str] = None
    pinned: bool = False


class PostCreate(PostBase):
    attachments: list[PostAttachment] = Field(default_factory=list)


class PostUpdate(BaseModel):
    content: Optional[str] = Field(default=None, min_length=1, max_length=4000)
    tags: Optional[list[str]] = None
    pinned: Optional[bool] = None


class PostInDB(MongoModel, PostBase):
    id: PyObjectId | None = Field(default=None, alias="_id")
    author_id: PyObjectId
    attachments: list[PostAttachment] = Field(default_factory=list)
    like_user_ids: list[PyObjectId] = Field(default_factory=list)
    share_parent_id: Optional[PyObjectId] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class CommentBase(BaseModel):
    content: str = Field(..., min_length=1, max_length=2000)
    parent_comment_id: Optional[PyObjectId] = None
    mentions: list[PyObjectId] = Field(default_factory=list)


class CommentCreate(CommentBase):
    pass


class CommentUpdate(BaseModel):
    content: Optional[str] = Field(default=None, min_length=1, max_length=2000)


class CommentInDB(MongoModel, CommentBase):
    id: PyObjectId | None = Field(default=None, alias="_id")
    post_id: PyObjectId
    author_id: PyObjectId
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class PostPublic(PostInDB):
    comment_count: int = 0
    like_count: int = 0


class CommentPublic(CommentInDB):
    author: Optional[dict] = None


class FeedResponse(BaseModel):
    items: list[PostPublic]
    total: int
    next_cursor: Optional[str] = None
