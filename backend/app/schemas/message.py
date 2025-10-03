from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel
from pydantic import Field

from app.core.object_id import MongoModel, PyObjectId
from app.schemas.post import PostAttachment


class ChatType(str, Enum):
    DIRECT = "direct"
    GROUP = "group"


class ChatBase(BaseModel):
    name: Optional[str] = Field(default=None, max_length=128)
    type: ChatType = ChatType.DIRECT
    photo_url: Optional[str] = None
    member_ids: list[PyObjectId] = Field(default_factory=list)
    admin_ids: list[PyObjectId] = Field(default_factory=list)


class ChatCreate(BaseModel):
    member_ids: list[PyObjectId]
    name: Optional[str] = None
    photo_url: Optional[str] = None


class ChatUpdate(BaseModel):
    name: Optional[str] = Field(default=None, max_length=128)
    photo_url: Optional[str] = None
    add_member_ids: list[PyObjectId] = Field(default_factory=list)
    remove_member_ids: list[PyObjectId] = Field(default_factory=list)


class ChatInDB(MongoModel, ChatBase):
    id: PyObjectId | None = Field(default=None, alias="_id")
    created_by: PyObjectId
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class ChatSummary(ChatInDB):
    last_message_preview: Optional[str] = None
    last_message_at: Optional[datetime] = None
    unread_count: int = 0


class MessageType(str, Enum):
    TEXT = "text"
    IMAGE = "image"
    FILE = "file"
    SYSTEM = "system"


class MessageBase(BaseModel):
    content: Optional[str] = Field(default=None, max_length=4000)
    type: MessageType = MessageType.TEXT
    attachments: list[PostAttachment] = Field(default_factory=list)
    reply_to_id: Optional[PyObjectId] = None


class MessageCreate(MessageBase):
    chat_id: PyObjectId


class MessageUpdate(BaseModel):
    content: Optional[str] = Field(default=None, max_length=4000)


class MessageInDB(MongoModel, MessageBase):
    id: PyObjectId | None = Field(default=None, alias="_id")
    chat_id: PyObjectId
    sender_id: PyObjectId
    seen_by: list[PyObjectId] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    edited: bool = False


class MessagePublic(MessageInDB):
    sender: Optional[dict] = None


class TypingIndicator(BaseModel):
    chat_id: PyObjectId
    user_id: PyObjectId
    is_typing: bool


class MessageSearchQuery(BaseModel):
    chat_id: PyObjectId
    query: Optional[str] = None
    limit: int = 50
    before: Optional[datetime] = None
