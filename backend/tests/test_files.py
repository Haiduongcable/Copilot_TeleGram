from __future__ import annotations

from pathlib import Path

from bson import ObjectId
import pytest


pytestmark = pytest.mark.asyncio


async def test_file_upload_and_deletion(client, create_user, test_db):
    user = await create_user(
        email="storage@example.com",
        username="storage_user",
        full_name="Storage User",
    )
    headers = {"Authorization": f"Bearer {user['tokens']['access_token']}"}

    upload_response = await client.post(
        "/api/files/upload",
        headers=headers,
        params={"attachment_type": "image"},
        files={"upload": ("hello.png", b"fake image data", "image/png")},
    )
    assert upload_response.status_code == 200
    payload = upload_response.json()
    metadata = payload["file"]
    file_id = metadata["_id"]

    stored_path = Path(metadata["path"])
    assert stored_path.exists()

    user_doc = await test_db.users.find_one({"_id": ObjectId(user["user"]["_id"])})
    assert user_doc is not None
    assert user_doc["storage_used"] == metadata["size"]

    delete_response = await client.delete(f"/api/files/{file_id}", headers=headers)
    assert delete_response.status_code == 204
    assert not stored_path.exists()

    user_doc = await test_db.users.find_one({"_id": ObjectId(user["user"]["_id"])})
    assert user_doc["storage_used"] == 0

    removed = await test_db.files.find_one({"_id": ObjectId(file_id)})
    assert removed is None
