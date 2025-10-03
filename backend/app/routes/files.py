from __future__ import annotations

from fastapi import APIRouter, Depends, File, Response, UploadFile, status

from app.core.dependencies import get_current_active_user, get_file_repository, get_user_repository
from app.schemas.file import FileUploadResponse
from app.schemas.post import AttachmentType
from app.schemas.user import UserInDB
from app.services.file_service import FileService

router = APIRouter(prefix="/files", tags=["files"])


def get_file_service(
    files=Depends(get_file_repository),
    users=Depends(get_user_repository),
) -> FileService:
    return FileService(files, users)


@router.post("/upload", response_model=FileUploadResponse)
async def upload_file(
    attachment_type: AttachmentType,
    upload: UploadFile = File(...),
    service: FileService = Depends(get_file_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> FileUploadResponse:
    metadata = await service.save_upload(str(current_user.id), upload, attachment_type)
    return FileUploadResponse(file=metadata)


@router.delete(
    "/{file_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    response_model=None,
)
async def delete_file(
    file_id: str,
    service: FileService = Depends(get_file_service),
    current_user: UserInDB = Depends(get_current_active_user),
) -> None:
    await service.delete_file(str(current_user.id), file_id)
