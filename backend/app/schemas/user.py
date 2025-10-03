from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel
from pydantic import EmailStr, Field

from app.core.object_id import MongoModel, PyObjectId


class UserStatus(str, Enum):
    OFFLINE = "offline"
    ONLINE = "online"
    AWAY = "away"
    DO_NOT_DISTURB = "dnd"


class UserBase(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=32)
    full_name: str = Field(..., min_length=1, max_length=128)
    department: Optional[str] = Field(default=None, max_length=64)
    role: Optional[str] = Field(default=None, max_length=64)
    bio: Optional[str] = Field(default=None, max_length=512)
    avatar_url: Optional[str] = None
    status: UserStatus = UserStatus.OFFLINE
    status_message: Optional[str] = Field(default=None, max_length=140)


class UserCreate(UserBase):
    password: str = Field(..., min_length=8, max_length=128)


class UserUpdate(BaseModel):
    full_name: Optional[str] = Field(default=None, min_length=1, max_length=128)
    department: Optional[str] = Field(default=None, max_length=64)
    role: Optional[str] = Field(default=None, max_length=64)
    bio: Optional[str] = Field(default=None, max_length=512)
    avatar_url: Optional[str] = None
    status: Optional[UserStatus] = None
    status_message: Optional[str] = Field(default=None, max_length=140)


class AdminUserUpdate(UserUpdate):
    is_active: Optional[bool] = None
    is_admin: Optional[bool] = None


class UserPasswordUpdate(BaseModel):
    old_password: str
    new_password: str = Field(..., min_length=8, max_length=128)


class UserInDB(MongoModel, UserBase):
    id: PyObjectId | None = Field(default=None, alias="_id")
    hashed_password: str
    is_active: bool = True
    is_admin: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    last_login_at: Optional[datetime] = None
    last_seen_at: Optional[datetime] = None
    storage_used: int = 0


class UserPublic(MongoModel, UserBase):
    id: PyObjectId | None = Field(default=None, alias="_id")
    created_at: datetime
    updated_at: datetime
    last_seen_at: Optional[datetime] = None
    storage_used: int = 0
    is_active: bool = True
    is_admin: bool = False


class UserListResponse(BaseModel):
    items: list[UserPublic]
    total: int


class UserSearchQuery(BaseModel):
    query: Optional[str] = None
    department: Optional[str] = None
    limit: int = 20
    offset: int = 0
