from __future__ import annotations

import pytest


pytestmark = pytest.mark.asyncio


@pytest.mark.asyncio
async def test_auth_flow(client, test_db):
    register_payload = {
        "email": "jane@example.com",
        "username": "jane",
        "full_name": "Jane Doe",
        "password": "SuperSecret1!",
    }

    print("register start")
    register_response = await client.post("/api/auth/register", json=register_payload)
    print("register done")
    assert register_response.status_code == 201
    user_data = register_response.json()
    assert user_data["email"] == register_payload["email"]

    print("login start")
    login_response = await client.post(
        "/api/auth/login",
        json={"email": register_payload["email"], "password": register_payload["password"]},
    )
    print("login done")
    assert login_response.status_code == 200
    login_payload = login_response.json()
    tokens = login_payload["tokens"]

    refresh_response = await client.post(
        "/api/auth/refresh",
        json={"refresh_token": tokens["refresh_token"]},
    )
    assert refresh_response.status_code == 200
    refreshed_tokens = refresh_response.json()
    assert refreshed_tokens["access_token"] != tokens["access_token"]
    assert refreshed_tokens["refresh_token"] != tokens["refresh_token"]

    bad_login = await client.post(
        "/api/auth/login",
        json={"email": register_payload["email"], "password": "wrong-pass"},
    )
    assert bad_login.status_code == 401

    headers = {"Authorization": f"Bearer {tokens['access_token']}"}
    logout_response = await client.post(
        "/api/auth/logout",
        headers=headers,
        json={"refresh_token": tokens["refresh_token"]},
    )
    assert logout_response.status_code == 204

    invalid_refresh = await client.post(
        "/api/auth/refresh",
        json={"refresh_token": tokens["refresh_token"]},
    )
    assert invalid_refresh.status_code == 401

    relogin = await client.post(
        "/api/auth/login",
        json={"email": register_payload["email"], "password": register_payload["password"]},
    )
    assert relogin.status_code == 200
    new_tokens = relogin.json()["tokens"]

    headers = {"Authorization": f"Bearer {new_tokens['access_token']}"}
    logout_all_response = await client.post("/api/auth/logout-all", headers=headers)
    assert logout_all_response.status_code == 204

    remaining_tokens = await test_db.refresh_tokens.count_documents({})
    assert remaining_tokens == 0
