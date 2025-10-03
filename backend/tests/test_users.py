from __future__ import annotations

import pytest


pytestmark = pytest.mark.asyncio


async def test_user_profile_and_search_flow(client, create_user):
    primary = await create_user(
        email="primary@example.com",
        username="primary",
        full_name="Primary User",
        password="PrimaryPass123!",
    )
    headers = {"Authorization": f"Bearer {primary['tokens']['access_token']}"}

    me_response = await client.get("/api/users/me", headers=headers)
    assert me_response.status_code == 200
    me_data = me_response.json()
    assert me_data["email"] == primary["email"]

    update_response = await client.patch(
        "/api/users/me",
        headers=headers,
        json={"full_name": "Primary Updated", "department": "Engineering"},
    )
    assert update_response.status_code == 200
    updated = update_response.json()
    assert updated["full_name"] == "Primary Updated"
    assert updated["department"] == "Engineering"

    password_change = await client.post(
        "/api/users/me/password",
        headers=headers,
        json={"old_password": primary["password"], "new_password": "FreshPass456!"},
    )
    assert password_change.status_code == 204

    failed_login = await client.post(
        "/api/auth/login",
        json={"email": primary["email"], "password": primary["password"]},
    )
    assert failed_login.status_code == 401

    new_login = await client.post(
        "/api/auth/login",
        json={"email": primary["email"], "password": "FreshPass456!"},
    )
    assert new_login.status_code == 200
    primary_tokens = new_login.json()["tokens"]
    headers = {"Authorization": f"Bearer {primary_tokens['access_token']}"}

    secondary = await create_user(
        email="secondary@example.com",
        username="secondary",
        full_name="Secondary User",
    )
    secondary_headers = {"Authorization": f"Bearer {secondary['tokens']['access_token']}"}
    await client.patch(
        "/api/users/me",
        headers=secondary_headers,
        json={"department": "Design"},
    )

    search_response = await client.get(
        "/api/users",
        headers=headers,
        params={"q": "secondary", "limit": 10},
    )
    assert search_response.status_code == 200
    search_data = search_response.json()
    assert search_data["total"] >= 1

    department_response = await client.get(
        "/api/users",
        headers=headers,
        params={"department": "Design", "limit": 10},
    )
    assert department_response.status_code == 200
    department_data = department_response.json()
    assert any(item["username"] == secondary["username"] for item in department_data["items"])

    secondary_id = secondary["user"]["_id"]
    detail_response = await client.get(f"/api/users/{secondary_id}", headers=headers)
    assert detail_response.status_code == 200
    assert detail_response.json()["username"] == secondary["username"]

    unauthenticated = await client.get("/api/users/me")
    assert unauthenticated.status_code == 401
