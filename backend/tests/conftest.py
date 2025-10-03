from __future__ import annotations

from collections.abc import AsyncIterator, Awaitable, Callable
from typing import Any

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from mongomock_motor import AsyncMongoMockClient

from app.config import settings
from app.core.dependencies import get_db
from app.db import mongo
from app.services.realtime import connection_manager


@pytest.fixture
def mongo_client() -> AsyncIterator[AsyncMongoMockClient]:
    client = AsyncMongoMockClient()
    try:
        print("mongo_client fixture: yield client")
        yield client
    finally:
        print("mongo_client fixture: close client")
        client.close()


@pytest.fixture
def test_db(mongo_client: AsyncMongoMockClient):
    return mongo_client["test_db"]


@pytest.fixture
def media_dir(tmp_path, monkeypatch):
    directory = tmp_path / "media"
    directory.mkdir(parents=True, exist_ok=True)
    monkeypatch.setattr(settings, "media_base_path", directory)
    return directory


@pytest.fixture
def app(mongo_client: AsyncMongoMockClient, test_db, media_dir, monkeypatch):
    from app.main import app as fastapi_app

    print("app fixture: configuring mongo patch")
    monkeypatch.setattr(mongo, "_client", mongo_client, raising=False)
    monkeypatch.setattr(mongo, "get_client", lambda: mongo_client)
    monkeypatch.setattr(mongo, "get_database", lambda: test_db)

    async def override_get_db() -> Any:
        return test_db

    fastapi_app.dependency_overrides[get_db] = override_get_db

    print("app fixture: returning app")
    yield fastapi_app

    fastapi_app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def client(app) -> AsyncIterator[AsyncClient]:
    print("client fixture: startup")
    await app.router.startup()
    print("client fixture: startup complete")
    transport = ASGITransport(app=app)
    try:
        print("client fixture: creating AsyncClient")
        async with AsyncClient(transport=transport, base_url="http://test") as async_client:
            print("client fixture: yielding client")
            yield async_client
    finally:
        print("client fixture: shutdown")
        await app.router.shutdown()
        print("client fixture: shutdown complete")


@pytest_asyncio.fixture
async def create_user(client: AsyncClient) -> Callable[..., Awaitable[dict[str, Any]]]:
    async def _create_user(
        *,
        email: str,
        username: str,
        password: str = "Password123!",
        full_name: str = "Test User",
    ) -> dict[str, Any]:
        payload = {
            "email": email,
            "username": username,
            "full_name": full_name,
            "password": password,
        }
        register_response = await client.post("/api/auth/register", json=payload)
        assert register_response.status_code == 201, register_response.text

        login_response = await client.post(
            "/api/auth/login",
            json={"email": email, "password": password},
        )
        assert login_response.status_code == 200, login_response.text
        data = login_response.json()
        user = data["user"]
        tokens = data["tokens"]

        return {
            "user": user,
            "tokens": tokens,
            "email": email,
            "username": username,
            "password": password,
        }

    return _create_user


@pytest.fixture(autouse=True)
def reset_connections() -> AsyncIterator[None]:
    connection_manager._connections.clear()
    yield
    connection_manager._connections.clear()
