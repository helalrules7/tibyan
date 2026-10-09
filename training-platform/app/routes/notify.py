from __future__ import annotations

from fastapi import APIRouter, Depends, Form, Request
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from starlette.responses import RedirectResponse

from ..deps import get_db
from ..i18n import get_lang
from ..mail import valid_email
from ..models import NotifySignup
from ..notifications import notify_admins
from ..web import check_csrf

router = APIRouter()


@router.post("/notify")
def notify_submit(
    request: Request,
    db: Session = Depends(get_db),
    email: str = Form(""),
    beta: bool = Form(False),
    website: str = Form(""),
    csrf: str = Form(""),
):
    """Store an address that wants launch news (and optionally the beta).

    nginx rate-limits this path; `website` is a honeypot that people never
    fill in, so bots get the same thank-you without anything being stored.
    """
    check_csrf(request, csrf)
    email = email.strip().lower()[:255]

    if website:
        request.session["notify"] = "ok"
    elif not valid_email(email):
        request.session["notify"] = "invalid"
    else:
        existing = db.query(NotifySignup).filter(NotifySignup.email == email).first()
        new_beta = False
        if existing is None:
            db.add(NotifySignup(email=email, lang=get_lang(request), wants_beta=beta))
            try:
                db.commit()
                new_beta = beta
            except IntegrityError:
                db.rollback()
        elif beta and not existing.wants_beta:
            existing.wants_beta = True
            db.commit()
            new_beta = True
        if new_beta:
            notify_admins(db, "beta_request", {}, "/admin/requests?tab=beta")
        request.session["notify"] = "ok"

    return RedirectResponse("/#notify", status_code=303)
