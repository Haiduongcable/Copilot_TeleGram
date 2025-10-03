from __future__ import annotations

import secrets
from pathlib import Path

import aiofiles
from fastapi import HTTPException, UploadFile, status

from app.config import settings
from app.repositories.file_repository import FileRepository
from app.repositories.user_repository import UserRepository
from app.schemas.file import FileMetadata
from app.schemas.post import AttachmentType


class FileService:
    def __init__(self, files: FileRepository, users: UserRepository) -> None:
        self.files = files
        self.users = users

    async def save_upload(self, owner_id: str, upload: UploadFile, attachment_type: AttachmentType) -> FileMetadata:
        if not upload.filename:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid filename")

        limits = {
            AttachmentType.IMAGE: settings.image_max_bytes,
            AttachmentType.FILE: settings.file_max_bytes,
        }
        size_limit = limits.get(attachment_type, settings.file_max_bytes)

        user = await self.users.get_by_id(owner_id)
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

        relative_dir = Path(owner_id)
        storage_dir = settings.media_base_path / relative_dir
        storage_dir.mkdir(parents=True, exist_ok=True)

        random_prefix = secrets.token_hex(8)
        safe_name = f"{random_prefix}_{upload.filename}"
        file_path = storage_dir / safe_name

        size = 0
        async with aiofiles.open(file_path, "wb") as out_file:
            while True:
                chunk = await upload.read(1024 * 1024)
                if not chunk:
                    break
                size += len(chunk)
                if size > size_limit:
                    await out_file.close()
                    file_path.unlink(missing_ok=True)
                    raise HTTPException(status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, detail="File too large")
                await out_file.write(chunk)

        await upload.seek(0)

        if user.storage_used + size > settings.per_user_storage_quota_bytes:
            file_path.unlink(missing_ok=True)
            raise HTTPException(status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, detail="Storage quota exceeded")

        relative_path = Path(settings.media_base_url.strip("/")) / relative_dir / safe_name
        metadata = FileMetadata(
            owner_id=user.id,
            filename=safe_name,
            original_filename=upload.filename,
            path=str(file_path),
            url=f"/{relative_path}",
            content_type=upload.content_type or "application/octet-stream",
            size=size,
            attachment_type=attachment_type,
        )
        metadata = await self.files.create_file(metadata)
        await self.users.push_storage_delta(owner_id, size)
        return metadata

    async def delete_file(self, owner_id: str, file_id: str) -> None:
        file = await self.files.get_file(file_id)
        if not file or str(file.owner_id) != owner_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="File not found")
        path = Path(file.path)
        if path.exists():
            path.unlink()
        deleted = await self.files.delete_file(file_id, owner_id)
        if deleted:
            await self.users.push_storage_delta(owner_id, -file.size)
