import json
from datetime import datetime, timezone
from typing import Any, Optional

from redis.asyncio import Redis

from app.core.config import get_settings

WEBHOOK_STREAM = "webhooks:deliver"
WEBHOOK_DLQ = "webhooks:failed"
CONSUMER_GROUP = "webhook-workers"
MAX_RETRIES = 5


def _serialize(obj: Any) -> str:
    if isinstance(obj, datetime):
        return obj.isoformat()
    return str(obj)


class WebhookQueue:
    def __init__(self, redis: Optional[Redis] = None):
        self.redis = redis or Redis.from_url(get_settings().redis_url, decode_responses=True)

    async def ensure_group(self):
        try:
            await self.redis.xgroup_create(WEBHOOK_STREAM, CONSUMER_GROUP, id="0", mkstream=True)
        except Exception:
            pass

    async def enqueue(self, webhook_id: str, event: str, payload: dict) -> str:
        body = json.dumps({"webhook_id": webhook_id, "event": event, "payload": payload}, default=_serialize)
        msg_id = await self.redis.xadd(WEBHOOK_STREAM, {"data": body}, maxlen=10000)
        return msg_id

    async def dequeue(self, count: int = 10, block_ms: int = 1000) -> list[dict]:
        results = await self.redis.xreadgroup(
            CONSUMER_GROUP, "worker-1", {WEBHOOK_STREAM: ">"}, count=count, block=block_ms
        )
        if not results:
            return []
        messages = []
        for stream_name, entries in results:
            for msg_id, fields in entries:
                messages.append({"id": msg_id, "data": json.loads(fields.get("data", "{}"))})
        return messages

    async def acknowledge(self, msg_id: str):
        await self.redis.xack(WEBHOOK_STREAM, CONSUMER_GROUP, msg_id)

    async def dead_letter(self, msg_id: str, reason: str):
        entry = await self.redis.xrange(WEBHOOK_STREAM, msg_id, msg_id)
        if entry:
            _, fields = entry[0]
            await self.redis.xadd(WEBHOOK_DLQ, {**fields, "error": reason, "original_id": msg_id}, maxlen=5000)
        await self.redis.xack(WEBHOOK_STREAM, CONSUMER_GROUP, msg_id)

    async def get_pending_count(self) -> int:
        info = await self.redis.xpending(WEBHOOK_STREAM, CONSUMER_GROUP)
        return info.get("pending", 0) if info else 0

    async def get_dlq_count(self) -> int:
        return await self.redis.xlen(WEBHOOK_DLQ)

    async def close(self):
        await self.redis.close()
