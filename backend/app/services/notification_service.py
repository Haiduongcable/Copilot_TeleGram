from __future__ import annotations

from fastapi import HTTPException, status

from app.core.utils import to_object_id
from app.repositories.notification_repository import NotificationRepository
from app.schemas.notification import NotificationListResponse, NotificationPublic


class NotificationService:
    def __init__(self, notifications: NotificationRepository) -> None:
        self.notifications = notifications

    async def list_notifications(self, user_id: str, limit: int = 50, offset: int = 0) -> NotificationListResponse:
        items, total = await self.notifications.list_for_user(user_id, limit=limit, skip=offset)
        return NotificationListResponse(items=[NotificationPublic(**i.model_dump()) for i in items], total=total)

    async def mark_read(self, notification_id: str, user_id: str) -> None:
        notification = await self.notifications.collection.find_one({"_id": to_object_id(notification_id)})
        if not notification or str(notification["recipient_id"]) != user_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
        await self.notifications.mark_as_read(notification_id)

    async def mark_all_read(self, user_id: str) -> int:
        return await self.notifications.mark_all_as_read(user_id)

    async def unread_count(self, user_id: str) -> int:
        return await self.notifications.unread_count(user_id)
