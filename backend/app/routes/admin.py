from __future__ import annotations

from fastapi import APIRouter, Depends, status

from app.core.dependencies import get_current_admin_user, get_user_repository
from app.schemas.user import AdminUserUpdate, UserInDB, UserPublic
from app.services.user_service import UserService

router = APIRouter(prefix="/admin", tags=["admin"])


def get_admin_user_service(users=Depends(get_user_repository)) -> UserService:
    return UserService(users)


@router.get("/users", response_model=list[UserPublic])
async def admin_list_users(
    limit: int = 100,
    offset: int = 0,
    service: UserService = Depends(get_admin_user_service),
    _: UserInDB = Depends(get_current_admin_user),
) -> list[UserPublic]:
    return await service.list_users(limit=limit, offset=offset)


@router.patch("/users/{user_id}", response_model=UserPublic)
async def admin_update_user(
    user_id: str,
    payload: AdminUserUpdate,
    service: UserService = Depends(get_admin_user_service),
    _: UserInDB = Depends(get_current_admin_user),
) -> UserPublic:
    return await service.admin_update_user(user_id, payload)
