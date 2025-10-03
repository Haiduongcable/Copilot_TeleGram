from __future__ import annotations

from datetime import datetime, timedelta
from typing import Optional

from fastapi import HTTPException, status

from app.config import settings
from app.core.security import create_access_token, create_refresh_token, decode_token, hash_password, verify_password
from app.repositories.token_repository import RefreshTokenRepository
from app.repositories.user_repository import UserRepository
from app.schemas.auth import LoginRequest, TokenPair
from app.schemas.user import UserCreate, UserInDB, UserPublic


class AuthService:
    def __init__(self, users: UserRepository, refresh_tokens: RefreshTokenRepository) -> None:
        self.users = users
        self.refresh_tokens = refresh_tokens

    async def register_user(self, payload: UserCreate) -> UserPublic:
        existing_email = await self.users.get_by_email(payload.email)
        if existing_email:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")

        existing_username = await self.users.get_by_username(payload.username)
        if existing_username:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Username already taken")

        user_data = payload.model_dump()
        raw_password = user_data.pop("password")
        user = UserInDB(**user_data, hashed_password=hash_password(raw_password))
        created = await self.users.create_user(user)
        return UserPublic(**created.model_dump())

    async def authenticate_user(self, login: LoginRequest) -> UserInDB:
        user = await self.users.get_by_email(login.email)
        if not user or not verify_password(login.password, user.hashed_password):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect email or password")
        await self.users.record_login(user.id)
        return user

    async def create_tokens(self, user: UserInDB, *, user_agent: Optional[str] = None) -> TokenPair:
        access_token = create_access_token(str(user.id))
        refresh_token = create_refresh_token(str(user.id))
        expires_in = settings.access_token_expire_minutes * 60
        refresh_expires_in = settings.refresh_token_expire_minutes * 60
        await self.refresh_tokens.store_token(
            user_id=user.id,
            token=refresh_token,
            expires_at=datetime.utcnow() + timedelta(minutes=settings.refresh_token_expire_minutes),
            user_agent=user_agent,
        )
        return TokenPair(
            access_token=access_token,
            refresh_token=refresh_token,
            expires_in=expires_in,
            refresh_expires_in=refresh_expires_in,
        )

    async def refresh_tokens_pair(self, refresh_token: str) -> TokenPair:
        token_doc = await self.refresh_tokens.get_token(refresh_token)
        if not token_doc:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

        payload = decode_token(refresh_token, refresh=True)
        user_id = payload["sub"]
        user = await self.users.get_by_id(user_id)
        if not user:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid user")

        # rotate refresh token
        await self.refresh_tokens.revoke_token(refresh_token)
        return await self.create_tokens(user)

    async def revoke_refresh_token(self, refresh_token: str) -> None:
        await self.refresh_tokens.revoke_token(refresh_token)

    async def revoke_all_tokens(self, user_id: str) -> int:
        return await self.refresh_tokens.revoke_all_for_user(user_id)
