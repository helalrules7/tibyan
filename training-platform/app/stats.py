from __future__ import annotations

import logging
import time

from sqlalchemy import func
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from .config import settings
from .models import Recording

_CACHE_SECONDS = 60
_cache: dict = {"at": 0.0, "value": None}
logger = logging.getLogger(__name__)


def public_progress(db: Session | None) -> dict | None:
    """Minutes recorded and contributing volunteers, for the public counter.

    Rejected recordings are left out. Cached per worker for a minute so the
    home page never adds noticeable database load. Returns None (the
    counter is simply hidden) when the database is unavailable.
    """
    now = time.monotonic()
    if _cache["value"] is not None and now - _cache["at"] < _CACHE_SECONDS:
        return _cache["value"]

    if db is None:
        return None
    try:
        total_ms, volunteers = (
            db.query(
                func.coalesce(func.sum(Recording.audio_duration_ms), 0),
                func.count(func.distinct(Recording.user_id)),
            )
            .filter(Recording.status != "rejected")
            .one()
        )
    except SQLAlchemyError:
        logger.exception("Progress counter query failed.")
        return None
    minutes = int(total_ms or 0) / 60000
    goal = max(1, settings.training_goal_minutes)
    value = {
        "minutes": minutes,
        "minutes_label": f"{minutes:.1f}" if minutes < 10 else f"{minutes:.0f}",
        "volunteers": int(volunteers or 0),
        "goal": goal,
        "percent": min(100.0, round(minutes / goal * 100, 1)),
    }
    _cache.update(at=now, value=value)
    return value
