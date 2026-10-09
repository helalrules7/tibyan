from __future__ import annotations

import json

from fastapi import APIRouter, Depends, Form, Request
from fastapi.responses import FileResponse, JSONResponse
from sqlalchemy.orm import Session
from starlette.responses import RedirectResponse

from .. import push
from ..config import settings
from ..deps import current_user, get_db
from ..i18n import get_lang
from ..models import Notification, PushSubscription
from ..notifications import notify_users, render_text, unread_count
from ..push import utcnow
from ..templating import STATIC_DIR
from ..web import check_csrf, msg, render

router = APIRouter()
PAGE_SIZE = 50


def _json_user(request: Request, db: Session):
    user = current_user(request, db)
    if user is None:
        return None, JSONResponse({"error": "login_required"}, status_code=401)
    return user, None


def _json_csrf(request: Request) -> None:
    check_csrf(request, request.headers.get("x-csrf-token", ""))


@router.get("/notifications")
def notifications_page(request: Request, db: Session = Depends(get_db)):
    user = current_user(request, db)
    if user is None:
        return RedirectResponse("/login", status_code=303)
    lang = get_lang(request)
    rows = (
        db.query(Notification)
        .filter(Notification.user_id == user.id)
        .order_by(Notification.id.desc())
        .limit(PAGE_SIZE)
        .all()
    )
    items = []
    for n in rows:
        title, body = render_text(lang, n.kind, json.loads(n.data or "{}"))
        items.append(
            {"id": n.id, "title": title, "body": body, "unread": n.read_at is None,
             "created_at": n.created_at}
        )
    subs = db.query(PushSubscription).filter(PushSubscription.user_id == user.id).count()
    flash = request.session.pop("flash", None)
    return render(
        request,
        "notifications.html",
        user=user,
        items=items,
        unread=sum(1 for i in items if i["unread"]),
        push_enabled=push.enabled(),
        push_count=subs,
        flash=flash,
    )


@router.get("/notifications/{notification_id}/open")
def open_notification(notification_id: int, request: Request, db: Session = Depends(get_db)):
    user = current_user(request, db)
    if user is None:
        return RedirectResponse("/login", status_code=303)
    n = db.get(Notification, notification_id)
    if n is None or n.user_id != user.id:
        return RedirectResponse("/notifications", status_code=303)
    if n.read_at is None:
        n.read_at = utcnow()
        db.commit()
    url = n.url or "/notifications"
    if not url.startswith("/") or url.startswith("//"):
        url = "/notifications"
    return RedirectResponse(url, status_code=303)


@router.post("/notifications/read-all")
def read_all(request: Request, db: Session = Depends(get_db), csrf: str = Form("")):
    user = current_user(request, db)
    if user is None:
        return RedirectResponse("/login", status_code=303)
    check_csrf(request, csrf)
    db.query(Notification).filter(
        Notification.user_id == user.id, Notification.read_at.is_(None)
    ).update({Notification.read_at: utcnow()}, synchronize_session=False)
    db.commit()
    return RedirectResponse("/notifications", status_code=303)


@router.get("/api/notifications/unread")
def api_unread(request: Request, db: Session = Depends(get_db)):
    user, error = _json_user(request, db)
    if error:
        return error
    return JSONResponse(
        {"count": unread_count(db, user.id), "admin": bool(user.is_admin)},
        headers={"Cache-Control": "no-store"},
    )


# ---------- Web Push -----------------------------------------------------

@router.get("/api/push/key")
def push_key():
    return JSONResponse({"enabled": push.enabled(), "publicKey": settings.vapid_public_key or None})


@router.post("/api/push/subscribe")
async def push_subscribe(request: Request, db: Session = Depends(get_db)):
    user, error = _json_user(request, db)
    if error:
        return error
    _json_csrf(request)
    if not push.enabled():
        return JSONResponse({"error": "push_disabled"}, status_code=503)
    try:
        body = await request.json()
        sub = body.get("subscription") or body
        endpoint = str(sub["endpoint"])
        p256dh = str(sub["keys"]["p256dh"])
        auth = str(sub["keys"]["auth"])
    except (ValueError, KeyError, TypeError, AttributeError):
        return JSONResponse({"error": "invalid_subscription"}, status_code=400)
    if (
        not endpoint.startswith("https://")
        or len(endpoint) > 2000
        or not 20 <= len(p256dh) <= 255
        or not 8 <= len(auth) <= 64
    ):
        return JSONResponse({"error": "invalid_subscription"}, status_code=400)

    digest = push.endpoint_hash(endpoint)
    row = db.query(PushSubscription).filter(PushSubscription.endpoint_hash == digest).first()
    if row is None:
        row = PushSubscription(endpoint_hash=digest, endpoint=endpoint, user_id=user.id)
        db.add(row)
    # A browser endpoint belongs to whoever subscribed it last.
    row.user_id = user.id
    row.p256dh = p256dh
    row.auth = auth
    row.lang = get_lang(request)
    row.failures = 0
    row.user_agent = (request.headers.get("user-agent") or "")[:255] or None
    db.commit()
    return JSONResponse({"ok": True})


@router.post("/api/push/unsubscribe")
async def push_unsubscribe(request: Request, db: Session = Depends(get_db)):
    user, error = _json_user(request, db)
    if error:
        return error
    _json_csrf(request)
    try:
        body = await request.json()
        endpoint = str(body["endpoint"])
    except (ValueError, KeyError, TypeError):
        return JSONResponse({"error": "invalid"}, status_code=400)
    removed = (
        db.query(PushSubscription)
        .filter(
            PushSubscription.endpoint_hash == push.endpoint_hash(endpoint),
            PushSubscription.user_id == user.id,
        )
        .delete(synchronize_session=False)
    )
    db.commit()
    return JSONResponse({"ok": True, "removed": removed})


@router.post("/api/push/test")
def push_test(request: Request, db: Session = Depends(get_db)):
    """Send the signed-in user a test notification (in-app + push)."""
    user, error = _json_user(request, db)
    if error:
        return error
    _json_csrf(request)
    subs = db.query(PushSubscription).filter(PushSubscription.user_id == user.id).count()
    notify_users(db, [user.id], "test", {}, "/notifications")
    return JSONResponse({"ok": True, "subscriptions": subs, "push": push.enabled()})


@router.post("/notifications/test")
def push_test_form(request: Request, db: Session = Depends(get_db), csrf: str = Form("")):
    user = current_user(request, db)
    if user is None:
        return RedirectResponse("/login", status_code=303)
    check_csrf(request, csrf)
    notify_users(db, [user.id], "test", {}, "/notifications")
    request.session["flash"] = msg(request, "notif_test_sent")
    return RedirectResponse("/notifications", status_code=303)


# ---------- PWA files (root scope) ---------------------------------------

@router.get("/sw.js")
def service_worker():
    return FileResponse(
        f"{STATIC_DIR}/sw.js",
        media_type="text/javascript",
        headers={"Cache-Control": "no-cache", "Service-Worker-Allowed": "/"},
    )


@router.get("/manifest.webmanifest")
def web_manifest(request: Request):
    lang = get_lang(request)
    ar = lang == "ar"
    data = {
        "name": "تبيان — تدريب نموذج التسميع" if ar else "Tibyan — recitation training",
        "short_name": "تدريب تبيان" if ar else "Tibyan Train",
        "lang": lang,
        "dir": "rtl" if ar else "ltr",
        "start_url": "/dashboard",
        "scope": "/",
        "display": "standalone",
        "background_color": "#F7EDDE",
        "theme_color": "#3A2B20",
        "icons": [
            {"src": "/static/icon-192.png", "sizes": "192x192", "type": "image/png"},
            {"src": "/static/icon-512.png", "sizes": "512x512", "type": "image/png"},
            {"src": "/static/icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable"},
        ],
    }
    return JSONResponse(data, media_type="application/manifest+json",
                        headers={"Cache-Control": "public, max-age=3600"})
