from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_user_id_from_token
from app.domain.models import User
from app.websocket.manager import WebSocketManager

router = APIRouter(tags=["WebSocket"])


@router.websocket("/ws/notifications")
async def websocket_notifications(
    websocket: WebSocket,
    token: str = Query(""),
    db: Session = Depends(get_db),
):
    token_str = token
    if not token_str:
        cookies = websocket.cookies or {}
        token_str = cookies.get("admin_token", "") or cookies.get("access_token", "")
    auth_header = websocket.headers.get("authorization", "")
    if not token_str and auth_header.startswith("Bearer "):
        token_str = auth_header[7:]
    if not token_str:
        await websocket.close(code=4001)
        return
    user_id = get_user_id_from_token(token_str)
    if not user_id:
        await websocket.close(code=4001)
        return
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        await websocket.close(code=4001)
        return
    await WebSocketManager.connect(user_id, websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        pass
    finally:
        await WebSocketManager.disconnect(user_id, websocket)
