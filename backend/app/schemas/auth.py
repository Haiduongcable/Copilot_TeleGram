from datetime import datetime
from typing import Optional

from pydantic import BaseModel
from pydantic import EmailStr

from app.schemas.user import UserPublic


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    refresh_expires_in: int


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class TokenPayload(BaseModel):
    sub: str
    exp: int
    type: str


class Session(BaseModel):
    id: str
    user_id: str
    created_at: datetime
    expires_at: datetime
    user_agent: Optional[str] = None


class AuthResponse(BaseModel):
    tokens: TokenPair
    user: UserPublic
