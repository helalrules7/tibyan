from __future__ import annotations

import logging
import smtplib

from fastapi import APIRouter, Depends, Form, Request
from sqlalchemy.orm import Session
from starlette.responses import RedirectResponse

from ..deps import get_db
from ..mail import send_mail, valid_email
from ..models import ContactMessage
from ..web import check_csrf, msg, render

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("/contact")
def contact_form(request: Request):
    flash = request.session.pop("flash", None)
    return render(request, "contact.html", errors={}, old={}, flash=flash)


@router.post("/contact")
def contact_submit(
    request: Request,
    db: Session = Depends(get_db),
    name: str = Form(""),
    email: str = Form(""),
    subject: str = Form(""),
    message: str = Form(""),
    csrf: str = Form(""),
):
    check_csrf(request, csrf)

    old = {"name": name, "email": email, "subject": subject, "message": message}
    errors = {}

    name = name.strip()
    email = email.strip().lower()
    subject = subject.strip()[:200]
    message = message.strip()

    if not name:
        errors["name"] = msg(request, "err_contact_name")
    if not valid_email(email):
        errors["email"] = msg(request, "err_contact_email")
    if not message:
        errors["message"] = msg(request, "err_contact_message")

    if errors:
        return render(request, "contact.html", errors=errors, old=old)

    db_message = ContactMessage(
        name=name,
        email=email,
        subject=subject or None,
        message=message[:5000],
    )
    db.add(db_message)
    db.commit()
    db.refresh(db_message)

    # Keep the saved message even if notification delivery is unavailable.
    try:
        sent = send_mail(
            subject=f"[Tibyan Training] {subject or 'Contact'} — {name}",
            body=f"From: {name} <{email}>\n\n{message}",
        )
        if not sent:
            logger.warning("SMTP is not configured; contact message %s was saved only.", db_message.id)
    except (OSError, smtplib.SMTPException, ValueError):
        logger.exception("Failed to send contact message %s by email.", db_message.id)

    request.session["flash"] = msg(request, "contact_sent")
    return RedirectResponse("/contact", status_code=303)
