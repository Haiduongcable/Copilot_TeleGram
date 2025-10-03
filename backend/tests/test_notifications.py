from __future__ import annotations

import pytest


pytestmark = pytest.mark.asyncio


async def test_notification_lifecycle(client, create_user):
    sender = await create_user(
        email="notify-sender@example.com",
        username="notify_sender",
        full_name="Notify Sender",
    )
    recipient = await create_user(
        email="notify-recipient@example.com",
        username="notify_recipient",
        full_name="Notify Recipient",
    )

    sender_headers = {"Authorization": f"Bearer {sender['tokens']['access_token']}"}
    recipient_headers = {"Authorization": f"Bearer {recipient['tokens']['access_token']}"}

    chat_response = await client.post(
        "/api/messaging/chats/direct",
        headers=sender_headers,
        json={"other_user_id": recipient["user"]["_id"]},
    )
    assert chat_response.status_code == 201
    chat_id = chat_response.json()["_id"]

    send_response = await client.post(
        f"/api/messaging/chats/{chat_id}/messages",
        headers=sender_headers,
        json={"chat_id": chat_id, "content": "Ping"},
    )
    assert send_response.status_code == 201

    list_response = await client.get("/api/notifications", headers=recipient_headers)
    assert list_response.status_code == 200
    notifications = list_response.json()
    assert notifications["total"] == 1
    notification = notifications["items"][0]
    assert notification["read"] is False

    unread_response = await client.get("/api/notifications/unread-count", headers=recipient_headers)
    assert unread_response.status_code == 200
    assert unread_response.json() == 1

    mark_read = await client.post(
        f"/api/notifications/{notification['_id']}/read",
        headers=recipient_headers,
    )
    assert mark_read.status_code == 204

    after_read = await client.get("/api/notifications", headers=recipient_headers)
    assert after_read.status_code == 200
    assert after_read.json()["items"][0]["read"] is True

    # trigger another notification to exercise mark-all
    await client.post(
        f"/api/messaging/chats/{chat_id}/messages",
        headers=sender_headers,
        json={"chat_id": chat_id, "content": "Second ping"},
    )

    mark_all = await client.post("/api/notifications/read-all", headers=recipient_headers)
    assert mark_all.status_code == 204

    final_unread = await client.get("/api/notifications/unread-count", headers=recipient_headers)
    assert final_unread.status_code == 200
    assert final_unread.json() == 0
