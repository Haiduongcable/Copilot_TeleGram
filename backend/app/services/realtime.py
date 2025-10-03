from __future__ import annotations

import asyncio
from collections import defaultdict
from typing import Any, Dict, Set

from fastapi import WebSocket


class ConnectionManager:
    def __init__(self) -> None:
        self._connections: Dict[str, Set[WebSocket]] = defaultdict(set)
        self._lock = asyncio.Lock()

    async def connect(self, chat_id: str, websocket: WebSocket) -> None:
        await websocket.accept()
        async with self._lock:
            self._connections[chat_id].add(websocket)

    async def disconnect(self, chat_id: str, websocket: WebSocket) -> None:
        async with self._lock:
            connections = self._connections.get(chat_id)
            if connections and websocket in connections:
                connections.remove(websocket)
            if connections and not connections:
                self._connections.pop(chat_id, None)

    async def broadcast(self, chat_id: str, message: dict[str, Any]) -> None:
        connections = list(self._connections.get(chat_id, []))
        for websocket in connections:
            try:
                await websocket.send_json(message)
            except RuntimeError:
                await self.disconnect(chat_id, websocket)

    async def send_personal_message(self, websocket: WebSocket, message: dict[str, Any]) -> None:
        await websocket.send_json(message)


connection_manager = ConnectionManager()
