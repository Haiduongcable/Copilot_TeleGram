from __future__ import annotations

from typing import Optional

from fastapi import HTTPException, status

from app.core.security import hash_password, verify_password
from app.core.utils import to_object_id
from app.repositories.user_repository import UserRepository
from app.schemas.user import AdminUserUpdate, UserInDB, UserListResponse, UserPublic, UserSearchQuery, UserUpdate


class UserService:
    def __init__(self, users: UserRepository) -> None:
        self.users = users

    async def get_user(self, user_id: str) -> UserPublic:
        user = await self.users.get_by_id(user_id)
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        return UserPublic(**user.model_dump())

    async def update_profile(self, user_id: str, payload: UserUpdate) -> UserPublic:
        updates = {k: v for k, v in payload.model_dump(exclude_none=True).items()}
        user = await self.users.update_user(user_id, updates)
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        return UserPublic(**user.model_dump())

    async def admin_update_user(self, user_id: str, payload: AdminUserUpdate) -> UserPublic:
        updates = payload.model_dump(exclude_none=True)
        if not updates:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No updates provided")
        user = await self.users.update_user(user_id, updates)
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        return UserPublic(**user.model_dump())

    async def change_password(self, user_id: str, old_password: str, new_password: str) -> None:
        user = await self.users.get_by_id(user_id)
        if not user or not verify_password(old_password, user.hashed_password):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid password")
        await self.users.update_password(user_id, hash_password(new_password))

    async def search(self, query: UserSearchQuery) -> UserListResponse:
        items, total = await self.users.search_users(
            query=query.query,
            department=query.department,
            skip=query.offset,
            limit=query.limit,
        )
        return UserListResponse(items=[UserPublic(**i.model_dump()) for i in items], total=total)

    async def list_users(self, limit: int = 50, offset: int = 0) -> list[UserPublic]:
        users = await self.users.list_users(skip=offset, limit=limit)
        return [UserPublic(**u.model_dump()) for u in users]

    async def set_status(self, user_id: str, status_value: str) -> None:
        from app.schemas.user import UserStatus

        try:
            status_enum = UserStatus(status_value)
        except ValueError as exc:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid status") from exc
        await self.users.set_status(user_id, status_enum)
