import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Optional

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)


class EmailSender:
    def __init__(self):
        self.settings = get_settings()

    def is_configured(self) -> bool:
        return bool(self.settings.smtp_host and self.settings.smtp_port and self.settings.smtp_user)

    async def send(
        self,
        to: str,
        subject: str,
        html_body: str,
        text_body: Optional[str] = None,
    ) -> bool:
        if not self.is_configured():
            logger.warning(f"Email not configured, cannot send to {to}")
            return False

        msg = MIMEMultipart("alternative")
        msg["From"] = self.settings.smtp_from or self.settings.smtp_user
        msg["To"] = to
        msg["Subject"] = subject
        msg.attach(MIMEText(text_body or html_body, "plain"))
        msg.attach(MIMEText(html_body, "html"))

        try:
            import ssl

            ctx = ssl.create_default_context()
            with smtplib.SMTP(self.settings.smtp_host, self.settings.smtp_port, timeout=15) as server:
                if self.settings.smtp_tls:
                    server.starttls(context=ctx)
                if self.settings.smtp_user and self.settings.smtp_password:
                    server.login(self.settings.smtp_user, self.settings.smtp_password)
                server.send_message(msg)
            logger.info(f"Email sent to {to}: {subject}")
            return True
        except Exception as e:
            logger.error(f"Failed to send email to {to}: {e}")
            return False
