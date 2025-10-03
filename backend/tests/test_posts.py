from __future__ import annotations

import pytest


pytestmark = pytest.mark.asyncio


async def test_post_lifecycle(client, create_user):
    author = await create_user(
        email="author@example.com",
        username="author",
        full_name="Author User",
    )
    headers = {"Authorization": f"Bearer {author['tokens']['access_token']}"}

    create_response = await client.post(
        "/api/posts",
        headers=headers,
        json={"content": "Hello team!", "tags": ["general"]},
    )
    assert create_response.status_code == 201
    post = create_response.json()
    post_id = post["_id"]

    list_response = await client.get("/api/posts", headers=headers)
    assert list_response.status_code == 200
    feed = list_response.json()
    assert any(item["_id"] == post_id for item in feed["items"])

    detail_response = await client.get(f"/api/posts/{post_id}", headers=headers)
    assert detail_response.status_code == 200
    assert detail_response.json()["content"] == "Hello team!"

    update_response = await client.patch(
        f"/api/posts/{post_id}",
        headers=headers,
        json={"content": "Hello updated team!"},
    )
    assert update_response.status_code == 200
    assert update_response.json()["content"] == "Hello updated team!"

    like_response = await client.post(f"/api/posts/{post_id}/like", headers=headers)
    assert like_response.status_code == 200
    assert like_response.json()["like_count"] == 1

    unlike_response = await client.post(f"/api/posts/{post_id}/unlike", headers=headers)
    assert unlike_response.status_code == 200
    assert unlike_response.json()["like_count"] == 0

    empty_comments = await client.get(f"/api/posts/{post_id}/comments", headers=headers)
    assert empty_comments.status_code == 200
    assert empty_comments.json() == []

    comment_response = await client.post(
        f"/api/posts/{post_id}/comments",
        headers=headers,
        json={"content": "Nice post!"},
    )
    assert comment_response.status_code == 201
    comment = comment_response.json()
    comment_id = comment["_id"]

    comments_after_create = await client.get(f"/api/posts/{post_id}/comments", headers=headers)
    assert comments_after_create.status_code == 200
    assert len(comments_after_create.json()) == 1

    update_comment_response = await client.patch(
        f"/api/posts/{post_id}/comments/{comment_id}",
        headers=headers,
        json={"content": "Updated comment"},
    )
    assert update_comment_response.status_code == 200
    assert update_comment_response.json()["content"] == "Updated comment"

    delete_comment_response = await client.delete(
        f"/api/posts/{post_id}/comments/{comment_id}",
        headers=headers,
    )
    assert delete_comment_response.status_code == 204

    delete_post_response = await client.delete(f"/api/posts/{post_id}", headers=headers)
    assert delete_post_response.status_code == 204

    missing_post = await client.get(f"/api/posts/{post_id}", headers=headers)
    assert missing_post.status_code == 404
