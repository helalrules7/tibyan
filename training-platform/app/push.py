"""Web Push (VAPID) delivery.

Sending happens on a small background thread pool so a request never waits
on a push service. Subscriptions the push service reports as gone (404/410)
are deleted; other failures are counted and logged without the payload.
"""
from __future__ import annotations

import hashlib
import json
import logging
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone

from .config import settings

logger = logging.getLogger(__name__)
_pool = ThreadPoolExecutor(max_workers=2, thread_name_prefix="webpush")

# Tests replace this with a fake to capture deliveries.
_sender = None


def utcnow() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


def enabled() -> bool:
    return bool(settings.vapid_public_key and settings.vapid_private_key)


def endpoint_hash(endpoint: str) -> str:
    return hashlib.sha256(endpoint.encode("utf-8")).hexdigest()


def _send_one(sub: dict, payload: dict) -> int:
    """Deliver one push; return the HTTP status (0 = network error)."""
    if _sender is not None:
        return _sender(sub, payload)
    from pywebpush import WebPushException, webpush

    try:
        response = webpush(
            subscription_info={
                "endpoint": sub["endpoint"],
                "keys": {"p256dh": sub["p256dh"], "auth": sub["auth"]},
            },
            data=json.dumps(payload, ensure_ascii=False),
            vapid_private_key=settings.vapid_private_key,
            vapid_claims={"sub": settings.vapid_subject},
            ttl=24 * 3600,
            timeout=15,
        )
        return getattr(response, "status_code", 201) or 201
    except WebPushException as exc:
        status = getattr(getattr(exc, "response", None), "status_code", 0) or 0
        logger.warning("Web push failed (status %s) for subscription %s.", status, sub["id"])
        return status
    except Exception:  # network errors, malformed keys
        logger.exception("Web push failed for subscription %s.", sub["id"])
        return 0


def _deliver(subs: list[dict], payloads: dict[str, dict]) -> dict:
    """Send to each subscription in its language; prune dead endpoints."""
    from .db import SessionLocal
    from .models import PushSubscription

    results = {"sent": 0, "failed": 0, "removed": 0}
    outcomes: list[tuple[int, int]] = []
    for sub in subs:
        payload = payloads.get(sub["lang"]) or payloads.get("ar") or next(iter(payloads.values()))
        status = _send_one(sub, payload)
        outcomes.append((sub["id"], status))
        if 200 <= status < 300:
            results["sent"] += 1
        elif status in (404, 410):
            results["removed"] += 1
        else:
            results["failed"] += 1

    try:
        db = _session_factory() if _session_factory else SessionLocal()
        try:
            for sub_id, status in outcomes:
                row = db.get(PushSubscription, sub_id)
                if row is None:
                    continue
                if 200 <= status < 300:
                    row.failures = 0
                    row.last_success_at = utcnow()
                elif status in (404, 410):
                    db.delete(row)
                else:
                    row.failures = (row.failures or 0) + 1
            db.commit()
        finally:
            db.close()
    except Exception:
        logger.exception("Could not record web push outcomes.")
    return results


# Tests point this at their own sessionmaker.
_session_factory = None
# Tests set this to True to deliver inline instead of on the thread pool.
synchronous = False


def send(subs: list[dict], payloads: dict[str, dict]):
    """Queue delivery. `subs` are plain dicts (no ORM objects cross threads)."""
    if not subs or not enabled():
        return None
    if synchronous:
        return _deliver(subs, payloads)
    return _pool.submit(_deliver, subs, payloads)


def subscription_dicts(rows) -> list[dict]:
    return [
        {
            "id": r.id,
            "endpoint": r.endpoint,
            "p256dh": r.p256dh,
            "auth": r.auth,
            "lang": r.lang or "ar",
        }
        for r in rows
    ]
