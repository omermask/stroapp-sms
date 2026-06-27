from fastapi import WebSocket

from app.core.logging import get_logger

logger = get_logger(__name__)


class WebSocketManager:
    _connections: dict[str, list[WebSocket]] = {}

    @classmethod
    async def connect(cls, user_id: str, websocket: WebSocket):
        await websocket.accept()
        if user_id not in cls._connections:
            cls._connections[user_id] = []
        cls._connections[user_id].append(websocket)

    @classmethod
    async def disconnect(cls, user_id: str, websocket: WebSocket):
        if user_id in cls._connections:
            cls._connections[user_id].remove(websocket)
            if not cls._connections[user_id]:
                del cls._connections[user_id]

    @classmethod
    async def broadcast(cls, user_id: str, data: dict):
        connections = cls._connections.get(user_id, [])
        for ws in connections:
            try:
                await ws.send_json(data)
            except Exception as e:
                logger.warning(f"WebSocket broadcast failed for user {user_id}: {e}")
                cls._connections[user_id] = [ws for ws in cls._connections.get(user_id, []) if ws.client_state.CONNECTED]
