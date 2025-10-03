from __future__ import annotations

from bson import ObjectId
import pytest


pytestmark = pytest.mark.asyncio


async def test_admin_user_management(client, create_user, test_db):
    admin = await create_user(
        email="admin@example.com",
        username="admin_user",
        full_name="Admin User",
    )
    await test_db.users.update_one(
        {"_id": ObjectId(admin["user"]["_id"])},
        {"$set": {"is_admin": True}},
    )

    member = await create_user(
        email="member@example.com",
        username="member_user",
        full_name="Member User",
    )

    admin_headers = {"Authorization": f"Bearer {admin['tokens']['access_token']}"}
    member_headers = {"Authorization": f"Bearer {member['tokens']['access_token']}"}

    list_response = await client.get("/api/admin/users", headers=admin_headers)
    assert list_response.status_code == 200
    users = list_response.json()
    assert any(user["username"] == member["username"] for user in users)

    update_response = await client.patch(
        f"/api/admin/users/{member['user']['_id']}",
        headers=admin_headers,
        json={"role": "QA", "is_active": False},
    )
    assert update_response.status_code == 200
    updated_member = update_response.json()
    assert updated_member["role"] == "QA"
    assert updated_member["is_active"] is False

    forbidden_response = await client.get("/api/admin/users", headers=member_headers)
    assert forbidden_response.status_code == 403
