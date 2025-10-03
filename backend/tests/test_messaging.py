from __future__ import annotations

from bson import ObjectId
import pytest


pytestmark = pytest.mark.asyncio


async def test_direct_and_group_messaging_flow(client, create_user, test_db):
    alice = await create_user(
        email="alice@example.com",
        username="alice",
        full_name="Alice",
    )
    bob = await create_user(
        email="bob@example.com",
        username="bob",
        full_name="Bob",
    )

    alice_headers = {"Authorization": f"Bearer {alice['tokens']['access_token']}"}

    direct_chat_response = await client.post(
        "/api/messaging/chats/direct",
        headers=alice_headers,
        json={"other_user_id": bob["user"]["_id"]},
    )
    assert direct_chat_response.status_code == 201
    direct_chat = direct_chat_response.json()
    direct_chat_id = direct_chat["_id"]

    group_chat_response = await client.post(
        "/api/messaging/chats/group",
        headers=alice_headers,
        json={"member_ids": [bob["user"]["_id"]], "name": "Project"},
    )
    assert group_chat_response.status_code == 201

    send_response = await client.post(
        f"/api/messaging/chats/{direct_chat_id}/messages",
        headers=alice_headers,
        json={"chat_id": direct_chat_id, "content": "Hey Bob!"},
    )
    assert send_response.status_code == 201
    message = send_response.json()
    message_id = message["_id"]

    chats_response = await client.get("/api/messaging/chats", headers=alice_headers)
    assert chats_response.status_code == 200
    assert any(chat["_id"] == direct_chat_id for chat in chats_response.json())

    list_messages = await client.get(
        f"/api/messaging/chats/{direct_chat_id}/messages",
        headers=alice_headers,
    )
    assert list_messages.status_code == 200
    assert any(item["_id"] == message_id for item in list_messages.json())

    edit_response = await client.patch(
        f"/api/messaging/chats/{direct_chat_id}/messages/{message_id}",
        headers=alice_headers,
        json={"content": "Updated message"},
    )
    assert edit_response.status_code == 200
    assert edit_response.json()["content"] == "Updated message"

    mark_seen_response = await client.post(
        f"/api/messaging/chats/{direct_chat_id}/messages/{message_id}/seen",
        headers=alice_headers,
    )
    assert mark_seen_response.status_code == 204

    message_doc = await test_db.messages.find_one({"_id": ObjectId(message_id)})
    assert message_doc is not None
    assert alice["user"]["_id"] in {str(item) for item in message_doc.get("seen_by", [])}

    mark_chat_seen_response = await client.post(
        f"/api/messaging/chats/{direct_chat_id}/seen",
        headers=alice_headers,
    )
    assert mark_chat_seen_response.status_code == 204

    delete_response = await client.delete(
        f"/api/messaging/chats/{direct_chat_id}/messages/{message_id}",
        headers=alice_headers,
    )
    assert delete_response.status_code == 204

    message_doc = await test_db.messages.find_one({"_id": ObjectId(message_id)})
    assert message_doc["content"] is None
    assert message_doc["type"] == "system"

    resend_response = await client.post(
        f"/api/messaging/chats/{direct_chat_id}/messages",
        headers=alice_headers,
        json={"chat_id": direct_chat_id, "content": "Second message"},
    )
    assert resend_response.status_code == 201
    second_message = resend_response.json()

    delete_everyone_response = await client.delete(
        f"/api/messaging/chats/{direct_chat_id}/messages/{second_message['_id']}",
        headers=alice_headers,
        params={"for_everyone": "true"},
    )
    assert delete_everyone_response.status_code == 204
    removed = await test_db.messages.find_one({"_id": ObjectId(second_message["_id"])})
    assert removed is None
