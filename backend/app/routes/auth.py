from __future__ import annotations

from fastapi import APIRouter, Depends, Request, Response, status

from app.core.dependencies import get_current_active_user, get_refresh_token_repository, get_user_repository
from app.schemas.auth import AuthResponse, LoginRequest, RefreshTokenRequest, TokenPair
from app.schemas.user import UserCreate, UserPublic, UserInDB
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


def get_auth_service(
    users=Depends(get_user_repository),
    refresh_tokens=Depends(get_refresh_token_repository),
) -> AuthService:
    return AuthService(users, refresh_tokens)


@router.post("/register", response_model=UserPublic, status_code=status.HTTP_201_CREATED)
async def register_user(payload: UserCreate, service: AuthService = Depends(get_auth_service)) -> UserPublic:
    return await service.register_user(payload)


@router.post("/login", response_model=AuthResponse)
async def login(payload: LoginRequest, request: Request, service: AuthService = Depends(get_auth_service)) -> AuthResponse:
    user = await service.authenticate_user(payload)
    tokens = await service.create_tokens(user, user_agent=request.headers.get("user-agent"))
    return AuthResponse(tokens=tokens, user=UserPublic(**user.model_dump()))


@router.post("/refresh", response_model=TokenPair)
async def refresh_tokens(payload: RefreshTokenRequest, service: AuthService = Depends(get_auth_service)) -> TokenPair:
    return await service.refresh_tokens_pair(payload.refresh_token)


@router.post(
    "/logout",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    response_model=None,
)
async def logout(
    payload: RefreshTokenRequest,
    service: AuthService = Depends(get_auth_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> None:
    await service.revoke_refresh_token(payload.refresh_token)


@router.post(
    "/logout-all",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    response_model=None,
)
async def logout_all(
    service: AuthService = Depends(get_auth_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> None:
    await service.revoke_all_tokens(str(current_user.id))
