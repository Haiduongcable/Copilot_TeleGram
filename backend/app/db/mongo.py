from __future__ import annotations

import logging
from typing import Optional

from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

from app.config import settings

logger = logging.getLogger(__name__)

_client: Optional[AsyncIOMotorClient] = None


def get_client() -> AsyncIOMotorClient:
    global _client
    if _client is None:
        logger.info("Connecting to MongoDB at %s", settings.mongodb_uri)
        _client = AsyncIOMotorClient(settings.mongodb_uri)
    return _client


def get_database() -> AsyncIOMotorDatabase:
    return get_client()[settings.mongo_db_name]


async def close_client() -> None:
    global _client
    if _client is not None:
        _client.close()
        _client = None


async def init_indexes() -> None:
    """Create MongoDB indexes used by the application."""

    db = get_database()

    await db.users.create_index("email", unique=True)
    await db.users.create_index("username", unique=True)
    await db.users.create_index([("department", 1)])

    await db.posts.create_index([("created_at", -1)])
    await db.posts.create_index([("author_id", 1), ("created_at", -1)])
    await db.posts.create_index([("tags", 1)])

    await db.comments.create_index([("post_id", 1), ("created_at", 1)])
    await db.comments.create_index([("author_id", 1)])

    await db.chats.create_index([("members", 1)])
    await db.messages.create_index([("chat_id", 1), ("created_at", 1)])

    await db.notifications.create_index([("recipient_id", 1), ("created_at", -1)])
    await db.notifications.create_index([("read", 1)])

    await db.refresh_tokens.create_index("token", unique=True)
    await db.refresh_tokens.create_index("user_id")
    await db.refresh_tokens.create_index("expires_at", expireAfterSeconds=0)
