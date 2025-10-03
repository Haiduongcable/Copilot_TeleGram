from __future__ import annotations

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.core.security import TokenError, decode_token
from app.db.mongo import get_database
from app.repositories.message_repository import ChatRepository, MessageRepository
from app.services.realtime import connection_manager

router = APIRouter()


@router.websocket("/ws/chats/{chat_id}")
async def chat_websocket(websocket: WebSocket, chat_id: str) -> None:
    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=4401)
        return
    try:
        payload = decode_token(token)
    except TokenError:
        await websocket.close(code=4401)
        return
    user_id = payload.get("sub")
    if not user_id:
        await websocket.close(code=4401)
        return

    db = get_database()
    chat_repo = ChatRepository(db)
    message_repo = MessageRepository(db)

    chat = await chat_repo.get_chat(chat_id)
    if not chat or all(str(member) != user_id for member in getattr(chat, "member_ids", [])):
        await websocket.close(code=4403)
        return

    await connection_manager.connect(chat_id, websocket)
    try:
        await connection_manager.send_personal_message(websocket, {"event": "connected", "data": {"chat_id": chat_id}})
        while True:
            data = await websocket.receive_json()
            event = data.get("event")
            if event == "ping":
                await connection_manager.send_personal_message(websocket, {"event": "pong"})
            elif event == "typing":
                payload = {
                    "event": "typing",
                    "data": {
                        "user_id": user_id,
                        "is_typing": bool(data.get("data", {}).get("is_typing", True)),
                    },
                }
                await connection_manager.broadcast(chat_id, payload)
            elif event == "seen":
                payload_data = data.get("data", {})
                message_id = payload_data.get("message_id")
                if message_id:
                    await message_repo.mark_as_seen(message_id, user_id)
                    await connection_manager.broadcast(
                        chat_id,
                        {"event": "message:seen", "data": {"user_id": user_id, "message_id": message_id}},
                    )
                else:
                    async for doc in message_repo.collection.find({"chat_id": chat.id}):
                        await message_repo.mark_as_seen(doc["_id"], user_id)
                    await connection_manager.broadcast(
                        chat_id,
                        {"event": "message:seen_all", "data": {"user_id": user_id}},
                    )
            else:
                await connection_manager.send_personal_message(websocket, {"event": "error", "message": "Unknown event"})
    except WebSocketDisconnect:
        await connection_manager.disconnect(chat_id, websocket)
    except Exception:
        await connection_manager.disconnect(chat_id, websocket)
        await websocket.close(code=1011)
