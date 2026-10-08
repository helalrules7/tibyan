from __future__ import annotations

import re
import ssl
from email.message import EmailMessage
import smtplib

from .config import settings

_EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def valid_email(value: str) -> bool:
    return bool(_EMAIL_RE.match(value))


def send_mail(subject: str, body: str) -> bool:
    """Send via the configured SMTP; return False when it is not set up."""
    if not settings.smtp_host:
        return False
    if not settings.smtp_from or not settings.smtp_to:
        raise ValueError("SMTP_FROM and SMTP_TO are required when SMTP is enabled.")
    if bool(settings.smtp_user) != bool(settings.smtp_pass):
        raise ValueError("SMTP_USER and SMTP_PASS must be configured together.")

    msg = EmailMessage()
    msg["Subject"] = subject
    msg["From"] = settings.smtp_from
    msg["To"] = settings.smtp_to
    msg.set_content(body)

    if settings.smtp_port == 465:
        with smtplib.SMTP_SSL(
            settings.smtp_host,
            settings.smtp_port,
            timeout=20,
            context=ssl.create_default_context(),
        ) as server:
            if settings.smtp_user:
                server.login(settings.smtp_user, settings.smtp_pass)
            server.send_message(msg)
    else:
        with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=20) as server:
            server.ehlo()
            server.starttls(context=ssl.create_default_context())
            server.ehlo()
            if settings.smtp_user:
                server.login(settings.smtp_user, settings.smtp_pass)
            server.send_message(msg)
    return True
