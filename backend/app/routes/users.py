from __future__ import annotations

from fastapi import APIRouter, Depends, Query, Response, status

from app.core.dependencies import get_current_active_user, get_user_repository
from app.schemas.user import UserInDB, UserListResponse, UserPasswordUpdate, UserPublic, UserSearchQuery, UserUpdate
from app.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["users"])


def get_user_service(users=Depends(get_user_repository)) -> UserService:
    return UserService(users)


@router.get("/me", response_model=UserPublic)
async def get_me(current_user: UserInDB = Depends(get_current_active_user)) -> UserPublic:
    return UserPublic(**current_user.model_dump())


@router.patch("/me", response_model=UserPublic)
async def update_me(
    payload: UserUpdate,
    service: UserService = Depends(get_user_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> UserPublic:
    return await service.update_profile(str(current_user.id), payload)


@router.post(
    "/me/password",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    response_model=None,
)
async def change_password(
    payload: UserPasswordUpdate,
    service: UserService = Depends(get_user_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> None:
    await service.change_password(str(current_user.id), payload.old_password, payload.new_password)


@router.get("", response_model=UserListResponse)
async def search_users(
    q: str | None = Query(default=None, description="Search query"),
    department: str | None = Query(default=None),
    limit: int = Query(default=20, le=100),
    offset: int = Query(default=0, ge=0),
    service: UserService = Depends(get_user_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> UserListResponse:
    payload = UserSearchQuery(query=q, department=department, limit=limit, offset=offset)
    return await service.search(payload)


@router.get("/{user_id}", response_model=UserPublic)
async def get_user(user_id: str, service: UserService = Depends(get_user_service), current_user: UserInDB = Depends(get_current_active_user)) -> UserPublic:
    return await service.get_user(user_id)
