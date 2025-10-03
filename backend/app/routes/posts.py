from __future__ import annotations

from fastapi import APIRouter, Depends, Query, Response, status

from app.core.dependencies import get_current_active_user, get_post_repository, get_user_repository
from app.schemas.post import CommentCreate, CommentPublic, CommentUpdate, FeedResponse, PostCreate, PostPublic, PostUpdate
from app.schemas.user import UserInDB
from app.services.post_service import PostService

router = APIRouter(prefix="/posts", tags=["posts"])


def get_post_service(
    posts=Depends(get_post_repository),
    users=Depends(get_user_repository),
) -> PostService:
    return PostService(posts, users)


@router.post("", response_model=PostPublic, status_code=status.HTTP_201_CREATED)
async def create_post(
    payload: PostCreate,
    service: PostService = Depends(get_post_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> PostPublic:
    return await service.create_post(str(current_user.id), payload)


@router.get("", response_model=FeedResponse)
async def list_posts(
    department: str | None = Query(default=None),
    limit: int = Query(default=20, le=50),
    offset: int = Query(default=0, ge=0),
    service: PostService = Depends(get_post_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> FeedResponse:
    return await service.list_feed(limit=limit, offset=offset, department=department)


@router.get("/{post_id}", response_model=PostPublic)
async def get_post(post_id: str, service: PostService = Depends(get_post_service), current_user: UserInDB = Depends(get_current_active_user)) -> PostPublic:
    return await service.get_post(post_id)


@router.patch("/{post_id}", response_model=PostPublic)
async def update_post(
    post_id: str,
    payload: PostUpdate,
    service: PostService = Depends(get_post_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> PostPublic:
    return await service.update_post(post_id, str(current_user.id), payload)


@router.delete(
    "/{post_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    response_model=None,
)
async def delete_post(
    post_id: str,
    service: PostService = Depends(get_post_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> None:
    await service.delete_post(post_id, str(current_user.id))


@router.post("/{post_id}/like", response_model=PostPublic)
async def like_post(
    post_id: str,
    service: PostService = Depends(get_post_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> PostPublic:
    return await service.like_post(post_id, str(current_user.id))


@router.post("/{post_id}/unlike", response_model=PostPublic)
async def unlike_post(
    post_id: str,
    service: PostService = Depends(get_post_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> PostPublic:
    return await service.unlike_post(post_id, str(current_user.id))


@router.get("/{post_id}/comments", response_model=list[CommentPublic])
async def list_comments(
    post_id: str,
    limit: int = Query(default=50, le=100),
    offset: int = Query(default=0, ge=0),
    service: PostService = Depends(get_post_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> list[CommentPublic]:
    return await service.list_comments(post_id, limit=limit, offset=offset)


@router.post("/{post_id}/comments", response_model=CommentPublic, status_code=status.HTTP_201_CREATED)
async def add_comment(
    post_id: str,
    payload: CommentUpdate,
    service: PostService = Depends(get_post_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> CommentPublic:
    return await service.add_comment(post_id, str(current_user.id), payload)


@router.patch("/{post_id}/comments/{comment_id}", response_model=CommentPublic)
async def update_comment(
    post_id: str,
    comment_id: str,
    payload: CommentCreate,
    service: PostService = Depends(get_post_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> CommentPublic:
    return await service.update_comment(comment_id, str(current_user.id), payload)


@router.delete(
    "/{post_id}/comments/{comment_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    response_model=None,
)
async def delete_comment(
    post_id: str,
    comment_id: str,
    service: PostService = Depends(get_post_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> None:
    await service.delete_comment(comment_id, str(current_user.id))
