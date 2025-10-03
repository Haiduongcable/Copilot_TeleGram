from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Any, Optional

from pydantic import BaseModel
from pydantic import Field

from app.core.object_id import MongoModel, PyObjectId


class NotificationType(str, Enum):
    MESSAGE = "message"
    COMMENT = "comment"
    LIKE = "like"
    MENTION = "mention"
    GROUP_ADDED = "group_added"
    SYSTEM = "system"


class NotificationBase(BaseModel):
    type: NotificationType
    data: dict[str, Any] = Field(default_factory=dict)


class NotificationInDB(MongoModel, NotificationBase):
    id: PyObjectId | None = Field(default=None, alias="_id")
    recipient_id: PyObjectId
    read: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)
    read_at: Optional[datetime] = None


class NotificationPublic(NotificationInDB):
    pass


class NotificationListResponse(BaseModel):
    items: list[NotificationPublic]
    total: int
