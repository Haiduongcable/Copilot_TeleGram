from __future__ import annotations

from datetime import datetime

from fastapi import APIRouter, Body, Depends, Query, Response, status

from app.core.dependencies import (
    get_chat_repository,
    get_current_active_user,
    get_message_repository,
    get_notification_repository,
)
from app.services.message_service import MessageService
from app.schemas.message import ChatCreate, ChatInDB, ChatSummary, MessageCreate, MessagePublic, MessageUpdate
from app.schemas.user import UserInDB

router = APIRouter(prefix="/messaging", tags=["messaging"])


def get_message_service(
    chats=Depends(get_chat_repository),
    messages=Depends(get_message_repository),
    notifications=Depends(get_notification_repository),
) -> MessageService:
    return MessageService(chats, messages, notifications)


@router.post("/chats/direct", response_model=ChatInDB, status_code=status.HTTP_201_CREATED)
async def create_direct_chat(
    other_user_id: str = Body(..., embed=True),
    service: MessageService = Depends(get_message_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> ChatInDB:
    return await service.get_or_create_direct_chat(str(current_user.id), other_user_id)


@router.post("/chats/group", response_model=ChatInDB, status_code=status.HTTP_201_CREATED)
async def create_group_chat(
    payload: ChatCreate,
    service: MessageService = Depends(get_message_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> ChatInDB:
    return await service.create_group_chat(str(current_user.id), payload)


@router.get("/chats", response_model=list[ChatSummary])
async def list_chats(
    limit: int = Query(default=50, le=100),
    service: MessageService = Depends(get_message_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> list[ChatSummary]:
    return await service.list_user_chats(str(current_user.id), limit=limit)


@router.get("/chats/{chat_id}/messages", response_model=list[MessagePublic])
async def list_messages(
    chat_id: str,
    limit: int = Query(default=50, le=100),
    before: datetime | None = Query(default=None),
    service: MessageService = Depends(get_message_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> list[MessagePublic]:
    return await service.list_messages(chat_id, str(current_user.id), limit=limit, before=before)


@router.post("/chats/{chat_id}/messages", response_model=MessagePublic, status_code=status.HTTP_201_CREATED)
async def send_message(
    chat_id: str,
    payload: MessageCreate,
    service: MessageService = Depends(get_message_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> MessagePublic:
    message_payload = MessageCreate(**payload.model_dump(exclude={"chat_id"}), chat_id=chat_id)
    return await service.send_message(str(current_user.id), message_payload)


@router.patch("/chats/{chat_id}/messages/{message_id}", response_model=MessagePublic)
async def edit_message(
    chat_id: str,
    message_id: str,
    payload: MessageUpdate,
    service: MessageService = Depends(get_message_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> MessagePublic:
    return await service.edit_message(message_id, str(current_user.id), payload)


@router.delete(
    "/chats/{chat_id}/messages/{message_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    response_model=None,
)
async def delete_message(
    chat_id: str,
    message_id: str,
    for_everyone: bool = Query(default=False),
    service: MessageService = Depends(get_message_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> None:
    await service.delete_message(message_id, str(current_user.id), for_everyone=for_everyone)


@router.post(
    "/chats/{chat_id}/messages/{message_id}/seen",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    response_model=None,
)
async def mark_seen(
    chat_id: str,
    message_id: str,
    service: MessageService = Depends(get_message_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> None:
    await service.mark_seen(chat_id, str(current_user.id), message_id)


@router.post(
    "/chats/{chat_id}/seen",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    response_model=None,
)
async def mark_chat_seen(
    chat_id: str,
    service: MessageService = Depends(get_message_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> None:
    await service.mark_seen(chat_id, str(current_user.id))
