from __future__ import annotations

import os
from datetime import datetime
from pathlib import Path

from fastapi.templating import Jinja2Templates

_templates_dir = Path(__file__).parent / "templates"
_static_dir = Path(__file__).parent / "static"

templates = Jinja2Templates(directory=str(_templates_dir))
STATIC_DIR = str(_static_dir)

# Official Facebook page (footer, follow lines, sameAs, e-mails).
FACEBOOK_URL = "https://www.facebook.com/tibyanapp/"
templates.env.globals["facebook_url"] = FACEBOOK_URL
# Official Instagram page (same places as Facebook).
INSTAGRAM_URL = "https://www.instagram.com/tibyanapp/"
templates.env.globals["instagram_url"] = INSTAGRAM_URL
# Official TikTok account (same places as Facebook).
TIKTOK_URL = "https://www.tiktok.com/@altibyanapp"
templates.env.globals["tiktok_url"] = TIKTOK_URL
# Official YouTube channel (same places as Facebook).
YOUTUBE_URL = "https://www.youtube.com/@altibyanApp"
templates.env.globals["youtube_url"] = YOUTUBE_URL
# Bump when CSS/JS/brand assets change so browsers refetch them.
templates.env.globals["asset_v"] = "launch2"

from .analytics import arabic_digits  # noqa: E402

templates.env.filters["ar_digits"] = arabic_digits

# Public launch moment (Cairo, after Maghrib, night of 27 Rajab 1448).
# The one place it lives; LAUNCH_AT (ISO 8601 with offset) overrides it.
LAUNCH_AT_DEFAULT = "2026-11-26T00:00:00+02:00"


def launch_at() -> datetime:
    return datetime.fromisoformat(os.environ.get("LAUNCH_AT") or LAUNCH_AT_DEFAULT)
