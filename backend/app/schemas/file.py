from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.core.object_id import MongoModel, PyObjectId
from app.schemas.post import AttachmentType


class FileMetadata(MongoModel):
    id: PyObjectId | None = Field(default=None, alias="_id")
    owner_id: PyObjectId
    filename: str
    original_filename: str
    path: str
    url: str
    content_type: str
    size: int
    attachment_type: AttachmentType
    thumbnail_url: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)


class FileUploadResponse(BaseModel):
    file: FileMetadata
