import json

from starlette.types import ASGIApp, Receive, Scope, Send

from app.core.sanitizer import sanitize_response_data


class XSSProtectionMiddleware:
    def __init__(self, app: ASGIApp):
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        body_chunks: list[bytes] = []
        content_type = ""
        start_message: dict | None = None

        async def send_wrapper(message: dict) -> None:
            nonlocal content_type, start_message
            if message["type"] == "http.response.start":
                start_message = message
                for name, value in message.get("headers", []):
                    if name.lower() == b"content-type":
                        content_type = value.decode("utf-8", errors="replace")
                        break
                return
            if message["type"] == "http.response.body":
                body_chunks.append(message.get("body", b""))
                if message.get("more_body", False):
                    return
                if start_message and "application/json" in content_type:
                    body = b"".join(body_chunks)
                    try:
                        data = json.loads(body)
                        sanitized = sanitize_response_data(data)
                        new_body = json.dumps(sanitized, ensure_ascii=False).encode("utf-8")
                        headers = list(start_message.get("headers", []))
                        for i, (name, _) in enumerate(headers):
                            if name.lower() == b"content-length":
                                headers[i] = (name, str(len(new_body)).encode())
                                break
                        start_message["headers"] = headers
                        await send(start_message)
                        message["body"] = new_body
                        await send(message)
                        return
                    except (json.JSONDecodeError, Exception):
                        pass
                if start_message:
                    await send(start_message)
                await send(message)

        await self.app(scope, receive, send_wrapper)
