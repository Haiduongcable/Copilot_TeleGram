from __future__ import annotations

from fastapi import APIRouter, Depends, Response, status

from app.core.dependencies import get_current_active_user, get_notification_repository
from app.schemas.notification import NotificationListResponse, NotificationPublic
from app.schemas.user import UserInDB
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/notifications", tags=["notifications"])


def get_notification_service(notifications=Depends(get_notification_repository)) -> NotificationService:
    return NotificationService(notifications)


@router.get("", response_model=NotificationListResponse)
async def list_notifications(
    limit: int = 50,
    offset: int = 0,
    service: NotificationService = Depends(get_notification_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> NotificationListResponse:
    return await service.list_notifications(str(current_user.id), limit=limit, offset=offset)


@router.post(
    "/{notification_id}/read",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    response_model=None,
)
async def mark_notification_read(
    notification_id: str,
    service: NotificationService = Depends(get_notification_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> None:
    await service.mark_read(notification_id, str(current_user.id))


@router.post(
    "/read-all",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    response_model=None,
)
async def mark_all_notifications_read(
    service: NotificationService = Depends(get_notification_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> None:
    await service.mark_all_read(str(current_user.id))


@router.get("/unread-count", response_model=int)
async def unread_count(
    service: NotificationService = Depends(get_notification_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> int:
    return await service.unread_count(str(current_user.id))
