from __future__ import annotations

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

from app.config import settings
from app.core.security import TokenError, decode_token
from app.db.mongo import get_database
from app.repositories.file_repository import FileRepository
from app.repositories.message_repository import ChatRepository, MessageRepository
from app.repositories.notification_repository import NotificationRepository
from app.repositories.post_repository import PostRepository
from app.repositories.token_repository import RefreshTokenRepository
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserInDB


oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.api_prefix}/auth/login")


async def get_db():
    return get_database()


def get_user_repository(db=Depends(get_db)) -> UserRepository:
    return UserRepository(db)


def get_post_repository(db=Depends(get_db)) -> PostRepository:
    return PostRepository(db)


def get_refresh_token_repository(db=Depends(get_db)) -> RefreshTokenRepository:
    return RefreshTokenRepository(db)


def get_chat_repository(db=Depends(get_db)) -> ChatRepository:
    return ChatRepository(db)


def get_message_repository(db=Depends(get_db)) -> MessageRepository:
    return MessageRepository(db)


def get_notification_repository(db=Depends(get_db)) -> NotificationRepository:
    return NotificationRepository(db)


def get_file_repository(db=Depends(get_db)) -> FileRepository:
    return FileRepository(db)


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    users: UserRepository = Depends(get_user_repository),
) -> UserInDB:
    try:
        payload = decode_token(token)
    except TokenError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    user_id: str = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    user = await users.get_by_id(user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    return user


async def get_current_active_user(current_user: UserInDB = Depends(get_current_user)) -> UserInDB:
    if not current_user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Inactive user")
    return current_user


async def get_current_admin_user(current_user: UserInDB = Depends(get_current_active_user)) -> UserInDB:
    if not current_user.is_admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Requires admin privileges")
    return current_user
