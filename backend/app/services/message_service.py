from __future__ import annotations

from datetime import datetime
from typing import List, Optional

from bson import ObjectId
from fastapi import HTTPException, status

from app.core.utils import to_object_id
from app.repositories.message_repository import ChatRepository, MessageRepository
from app.repositories.notification_repository import NotificationRepository
from app.schemas.message import ChatCreate, ChatInDB, ChatSummary, ChatType, MessageCreate, MessageInDB, MessagePublic, MessageUpdate
from app.schemas.notification import NotificationInDB, NotificationType
from app.services.realtime import connection_manager


class MessageService:
    def __init__(
        self,
        chats: ChatRepository,
        messages: MessageRepository,
        notifications: NotificationRepository | None,
    ) -> None:
        self.chats = chats
        self.messages = messages
        self.notifications = notifications

    async def get_or_create_direct_chat(self, requester_id: str, other_user_id: str) -> ChatInDB:
        chat = await self.chats.find_direct_chat(requester_id, other_user_id)
        if chat:
            return chat
        payload = ChatCreate(member_ids=[to_object_id(requester_id), to_object_id(other_user_id)])
        chat = ChatInDB(
            created_by=to_object_id(requester_id),
            type=ChatType.DIRECT,
            member_ids=payload.member_ids,
            admin_ids=[to_object_id(requester_id)],
        )
        return await self.chats.create_chat(chat)

    async def create_group_chat(self, requester_id: str, payload: ChatCreate) -> ChatInDB:
        members = set(payload.member_ids + [to_object_id(requester_id)])
        chat = ChatInDB(
            name=payload.name,
            photo_url=payload.photo_url,
            created_by=to_object_id(requester_id),
            type=ChatType.GROUP,
            member_ids=list(members),
            admin_ids=[to_object_id(requester_id)],
        )
        return await self.chats.create_chat(chat)

    async def list_user_chats(self, user_id: str, limit: int = 50) -> List[ChatSummary]:
        chats = await self.chats.list_user_chats(user_id, limit=limit)
        summaries: List[ChatSummary] = []
        for chat in chats:
            last_message = await self.messages.collection.find({"chat_id": chat.id}).sort("created_at", -1).limit(1).to_list(length=1)
            last_message_at = last_message[0]["created_at"] if last_message else None
            preview = last_message[0].get("content") if last_message else None
            unread = await self.messages.count_unread(chat.id, user_id)
            summaries.append(
                ChatSummary(
                    **chat.model_dump(),
                    last_message_at=last_message_at,
                    last_message_preview=preview,
                    unread_count=unread,
                )
            )
        return summaries

    async def send_message(self, sender_id: str, payload: MessageCreate) -> MessagePublic:
        chat = await self.chats.get_chat(payload.chat_id)
        if not chat or to_object_id(sender_id) not in chat.member_ids:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not a member of this chat")
        message = MessageInDB(
            chat_id=chat.id,
            sender_id=to_object_id(sender_id),
            content=payload.content,
            type=payload.type,
            attachments=payload.attachments,
            reply_to_id=payload.reply_to_id,
        )
        created = await self.messages.create_message(message)
        await self.chats.update_chat(chat.id, {"updated_at": datetime.utcnow()})
        await self._notify_chat_members(chat, created, sender_id)
        payload = MessagePublic(**created.model_dump())
        await connection_manager.broadcast(
            str(chat.id),
            {"event": "message:new", "data": payload.model_dump(by_alias=True)},
        )
        return payload

    async def edit_message(self, message_id: str, user_id: str, payload: MessageUpdate) -> MessagePublic:
        message = await self.messages.get_message(message_id)
        if not message or str(message.sender_id) != user_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Message not found")
        updated = await self.messages.update_message(message_id, payload.model_dump(exclude_none=True))
        response = MessagePublic(**updated.model_dump())
        await connection_manager.broadcast(
            str(message.chat_id),
            {"event": "message:updated", "data": response.model_dump(by_alias=True)},
        )
        return response

    async def delete_message(self, message_id: str, user_id: str, *, for_everyone: bool = False) -> None:
        message = await self.messages.get_message(message_id)
        if not message or (not for_everyone and str(message.sender_id) != user_id):
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Message not found")
        if for_everyone and str(message.sender_id) != user_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Cannot delete message for everyone")
        await self.messages.delete_message(message_id, for_everyone)
        await connection_manager.broadcast(
            str(message.chat_id),
            {"event": "message:deleted", "data": {"id": str(message.id), "for_everyone": for_everyone}},
        )

    async def mark_seen(self, chat_id: str, user_id: str, message_id: Optional[str] = None) -> None:
        if message_id:
            await self.messages.mark_as_seen(message_id, user_id)
        else:
            # mark all messages
            async for doc in self.messages.collection.find({"chat_id": to_object_id(chat_id)}):
                await self.messages.mark_as_seen(doc["_id"], user_id)

    async def list_messages(self, chat_id: str, user_id: str, limit: int = 50, before: Optional[datetime] = None) -> List[MessagePublic]:
        chat = await self.chats.get_chat(chat_id)
        if not chat or to_object_id(user_id) not in chat.member_ids:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not a member of this chat")
        messages = await self.messages.list_messages(chat_id, limit=limit, before=before)
        return [MessagePublic(**m.model_dump()) for m in messages]

    async def _notify_chat_members(self, chat: ChatInDB, message: MessageInDB, sender_id: str) -> None:
        recipients = [member for member in chat.member_ids if str(member) != sender_id]
        if not recipients or self.notifications is None:
            return
        for recipient in recipients:
            notification = NotificationInDB(
                recipient_id=recipient,
                type=NotificationType.MESSAGE,
                data={"chat_id": str(chat.id), "message_id": str(message.id)},
            )
            await self.notifications.create_notification(notification)
