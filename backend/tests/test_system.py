from __future__ import annotations

import pytest


pytestmark = pytest.mark.asyncio


async def test_system_health_and_metrics(client, create_user):
    user = await create_user(
        email="metrics@example.com",
        username="metrics_user",
        full_name="Metrics User",
    )
    colleague = await create_user(
        email="metrics-colleague@example.com",
        username="metrics_colleague",
        full_name="Metrics Colleague",
    )

    headers = {"Authorization": f"Bearer {user['tokens']['access_token']}"}

    await client.post(
        "/api/posts",
        headers=headers,
        json={"content": "Metrics post", "tags": ["status"]},
    )

    chat_response = await client.post(
        "/api/messaging/chats/direct",
        headers=headers,
        json={"other_user_id": colleague["user"]["_id"]},
    )
    chat_id = chat_response.json()["_id"]

    await client.post(
        f"/api/messaging/chats/{chat_id}/messages",
        headers=headers,
        json={"chat_id": chat_id, "content": "Metrics message"},
    )

    health_response = await client.get("/api/health")
    assert health_response.status_code == 200
    assert health_response.json()["status"] == "ok"

    metrics_response = await client.get("/api/metrics")
    assert metrics_response.status_code == 200
    metrics = metrics_response.json()
    assert metrics["total_users"] >= 2
    assert metrics["posts_today"] >= 1
    assert metrics["messages_today"] >= 1
    assert metrics["uptime_seconds"] >= 0
