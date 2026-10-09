"""Admin «requests & emails» page: notify-me signups (CSV), beta-join
requests (Play / TestFlight marks), contact messages (read / replied) and
data-deletion requests from /voice."""
from __future__ import annotations

import csv
import io

from fastapi import APIRouter, Depends, Form, Query, Request
from fastapi.responses import Response
from sqlalchemy.orm import Session
from starlette.responses import RedirectResponse

from ..deps import current_user, get_db
from ..models import ContactMessage, DeletionRequest, NotifySignup, Recording, User
from ..push import utcnow
from ..web import check_csrf, msg, render
from .admin import require_admin

router = APIRouter()
TABS = ("contact", "beta", "notify", "deletion")
LIMIT = 200


def _back(tab: str) -> RedirectResponse:
    return RedirectResponse(f"/admin/requests?tab={tab}", status_code=303)


@router.get("/admin/requests")
def requests_page(
    request: Request, db: Session = Depends(get_db), tab: str = Query("contact")
):
    blocked = require_admin(request, db)
    if blocked is not None:
        return blocked
    if tab not in TABS:
        tab = "contact"
    counts = {
        "contact": db.query(ContactMessage).filter(ContactMessage.read_at.is_(None)).count(),
        "beta": db.query(NotifySignup)
        .filter(
            NotifySignup.wants_beta.is_(True),
            NotifySignup.play_added_at.is_(None),
            NotifySignup.testflight_added_at.is_(None),
        )
        .count(),
        "notify": db.query(NotifySignup).count(),
        "deletion": db.query(DeletionRequest).filter(DeletionRequest.status == "open").count(),
    }
    context = {"tab": tab, "counts": counts}
    if tab == "contact":
        context["messages"] = (
            db.query(ContactMessage).order_by(ContactMessage.id.desc()).limit(LIMIT).all()
        )
    elif tab == "beta":
        context["signups"] = (
            db.query(NotifySignup)
            .filter(NotifySignup.wants_beta.is_(True))
            .order_by(NotifySignup.id.desc())
            .limit(LIMIT)
            .all()
        )
    elif tab == "notify":
        context["signups"] = (
            db.query(NotifySignup).order_by(NotifySignup.id.desc()).limit(LIMIT).all()
        )
    else:
        rows = db.query(DeletionRequest).order_by(DeletionRequest.id.desc()).limit(LIMIT).all()
        matches = {}
        for r in rows:
            user = db.get(User, r.user_id) if r.user_id else (
                db.query(User).filter(User.email == r.email).first()
            )
            if user is not None:
                matches[r.id] = {
                    "user_id": user.id,
                    "recordings": db.query(Recording).filter(Recording.user_id == user.id).count(),
                }
        context["deletions"] = rows
        context["matches"] = matches
    flash = request.session.pop("flash", None)
    return render(request, "admin_requests.html", flash=flash, admin_section="requests", **context)


@router.post("/admin/requests/contact/{message_id}")
def contact_state(
    message_id: int, request: Request, db: Session = Depends(get_db),
    state: str = Form(""), csrf: str = Form(""),
):
    blocked = require_admin(request, db)
    if blocked is not None:
        return blocked
    check_csrf(request, csrf)
    row = db.get(ContactMessage, message_id)
    if row is not None:
        now = utcnow()
        if state == "read":
            row.read_at = row.read_at or now
        elif state == "replied":
            row.read_at = row.read_at or now
            row.replied_at = now
        elif state == "unread":
            row.read_at = None
            row.replied_at = None
        db.commit()
    return _back("contact")


@router.post("/admin/requests/beta/{signup_id}")
def beta_mark(
    signup_id: int, request: Request, db: Session = Depends(get_db),
    platform: str = Form(""), value: str = Form("1"), csrf: str = Form(""),
):
    blocked = require_admin(request, db)
    if blocked is not None:
        return blocked
    check_csrf(request, csrf)
    row = db.get(NotifySignup, signup_id)
    if row is not None and platform in ("play", "testflight"):
        stamp = utcnow() if value == "1" else None
        if platform == "play":
            row.play_added_at = stamp
        else:
            row.testflight_added_at = stamp
        db.commit()
    return _back("beta")


@router.post("/admin/requests/deletion/{request_id}")
def deletion_state(
    request_id: int, request: Request, db: Session = Depends(get_db),
    state: str = Form(""), csrf: str = Form(""),
):
    blocked = require_admin(request, db)
    if blocked is not None:
        return blocked
    check_csrf(request, csrf)
    row = db.get(DeletionRequest, request_id)
    admin_user = current_user(request, db)
    if row is not None and state in ("open", "done", "declined"):
        row.status = state
        row.handled_at = None if state == "open" else utcnow()
        row.handled_by = None if state == "open" else admin_user.id
        db.commit()
        request.session["flash"] = msg(request, "req_saved")
    return _back("deletion")


def _cell(value) -> str:
    """CSV cell safe to open in a spreadsheet (no formula injection)."""
    text = "" if value is None else str(value)
    return "'" + text if text[:1] in ("=", "+", "-", "@", "\t", "\r") else text


@router.get("/admin/requests/notify.csv")
def notify_csv(request: Request, db: Session = Depends(get_db), beta: int = Query(0)):
    blocked = require_admin(request, db)
    if blocked is not None:
        return blocked
    query = db.query(NotifySignup).order_by(NotifySignup.id)
    if beta:
        query = query.filter(NotifySignup.wants_beta.is_(True))
    out = io.StringIO()
    writer = csv.writer(out)
    writer.writerow(["email", "lang", "wants_beta", "created_at", "play_added_at", "testflight_added_at"])
    for row in query.all():
        writer.writerow([
            _cell(row.email), row.lang, int(bool(row.wants_beta)), row.created_at,
            row.play_added_at or "", row.testflight_added_at or "",
        ])
    name = "tibyan-beta-requests.csv" if beta else "tibyan-notify-signups.csv"
    return Response(
        "﻿" + out.getvalue(),
        media_type="text/csv; charset=utf-8",
        headers={
            "Content-Disposition": f'attachment; filename="{name}"',
            "Cache-Control": "no-store",
        },
    )
