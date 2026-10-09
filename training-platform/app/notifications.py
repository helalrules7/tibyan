"""Notification fan-out: one in-app row per recipient plus a Web Push to
each of their subscribed browsers.

Events (kind -> recipients):
  admins:     new_recording, beta_request, contact_message,
              deletion_request, training_done, training_failed
  volunteers: recording_accepted, recording_rejected (the owner only)
"""
from __future__ import annotations

import json
import logging

from sqlalchemy.orm import Session

from . import push
from .i18n import t
from .models import Notification, PushSubscription, User

logger = logging.getLogger(__name__)

ADMIN_KINDS = {
    "new_recording",
    "beta_request",
    "contact_message",
    "deletion_request",
    "training_done",
    "training_failed",
}
VOLUNTEER_KINDS = {"recording_accepted", "recording_rejected"}
KINDS = ADMIN_KINDS | VOLUNTEER_KINDS | {"test"}


def render_text(lang: str, kind: str, data: dict | None) -> tuple[str, str]:
    """(title, body) for a notification in one language."""
    data = data or {}
    title = t(lang, f"notif_{kind}_title")
    body = t(lang, f"notif_{kind}_body")
    for key, value in data.items():
        body = body.replace("{" + key + "}", str(value))
        title = title.replace("{" + key + "}", str(value))
    return title, body


def _safe_url(url: str | None) -> str:
    # Only same-site paths; never an absolute or protocol-relative URL.
    if not url or not url.startswith("/") or url.startswith("//"):
        return "/notifications"
    return url[:255]


def notify_users(
    db: Session,
    user_ids: list[int],
    kind: str,
    data: dict | None = None,
    url: str | None = None,
) -> int:
    """Store a notification for each user and queue their pushes.

    Commits the session. Never raises: a notification problem must not
    break the action that triggered it.
    """
    if kind not in KINDS:
        raise ValueError(f"Unknown notification kind: {kind}")
    user_ids = sorted({int(u) for u in user_ids if u is not None})
    if not user_ids:
        return 0
    url = _safe_url(url)
    try:
        payload_data = json.dumps(data or {}, ensure_ascii=False)
        for uid in user_ids:
            db.add(Notification(user_id=uid, kind=kind, data=payload_data, url=url))
        db.commit()
        subs = (
            db.query(PushSubscription)
            .filter(PushSubscription.user_id.in_(user_ids))
            .all()
        )
        if subs and push.enabled():
            payloads = {}
            for lang in ("ar", "en"):
                title, body = render_text(lang, kind, data)
                payloads[lang] = {
                    "title": title,
                    "body": body,
                    "url": url,
                    "tag": kind,
                    "lang": lang,
                }
            push.send(push.subscription_dicts(subs), payloads)
    except Exception:
        logger.exception("Notification fan-out failed for %s.", kind)
        try:
            db.rollback()
        except Exception:
            pass
        return 0
    return len(user_ids)


def admin_ids(db: Session) -> list[int]:
    return [row[0] for row in db.query(User.id).filter(User.is_admin.is_(True)).all()]


def notify_admins(db: Session, kind: str, data: dict | None = None, url: str | None = None) -> int:
    return notify_users(db, admin_ids(db), kind, data, url)


def unread_count(db: Session, user_id: int) -> int:
    return (
        db.query(Notification)
        .filter(Notification.user_id == user_id, Notification.read_at.is_(None))
        .count()
    )
