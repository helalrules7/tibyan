from __future__ import annotations

import os
import unittest
from datetime import datetime, timedelta, timezone
from unittest import mock

from starlette.requests import Request

from app.routes.pages import index


def make_request(lang: str = "ar") -> Request:
    return Request(
        {
            "type": "http",
            "method": "GET",
            "path": "/",
            "headers": [(b"host", b"altibyan.app"), (b"cookie", f"lang={lang}".encode())],
            "query_string": b"",
            "server": ("altibyan.app", 80),
            "scheme": "https",
            "client": ("127.0.0.1", 1234),
            "root_path": "",
            "session": {},
        }
    )


def render_at(offset: timedelta, lang: str = "ar") -> str:
    target = (datetime.now(timezone.utc) + offset).replace(microsecond=0)
    with mock.patch.dict(os.environ, {"LAUNCH_AT": target.isoformat()}):
        return index(make_request(lang), db=None).body.decode()


class LaunchCountdownTests(unittest.TestCase):
    def test_default_target_in_page(self):
        from app.routes.pages import launch_state
        with mock.patch.dict(os.environ, {"LAUNCH_AT": "", "LAUNCH_FORCE": ""}):
            state = launch_state()
        self.assertEqual(state["launch_iso"], "2026-11-26T00:00:00+02:00")
        self.assertEqual(state["launch_phase"], "live")

    def test_before_launch(self):
        body = render_at(timedelta(days=30))
        self.assertIn('role="timer"', body)
        self.assertIn("الإطلاق ليلة ٢٧ رجب ١٤٤٨", body)
        self.assertIn("ليلة ٢٧ رجب ·", body)
        for label in ("يوم", "ساعة", "دقيقة", "ثانية"):
            self.assertIn(f'class="cd-label">{label}<', body)
        self.assertNotIn('class="countdown last24"', body)
        self.assertIn('data-prelaunch>', body)  # notify button visible
        self.assertIn('<p class="launched" data-launched hidden>', body)
        self.assertNotIn(">قريبًا<", body)

    def test_last_24_hours_hides_days(self):
        body = render_at(timedelta(hours=5))
        self.assertIn('class="countdown last24"', body)
        self.assertIn('data-prelaunch>', body)

    def test_after_launch(self):
        body = render_at(timedelta(minutes=-1))
        # after the launch the home is the redesigned page, with the stores
        self.assertIn('id="get"', body)
        self.assertNotIn('data-launch=', body)
        self.assertIn("play.google.com/store/apps/details?id=app.tibyan.tibyan", body)
        self.assertNotIn("apps.apple.com/app/id6818990351", body)  # iOS/Mac: «قريبًا» until Apple approves
        self.assertIn("apps.microsoft.com/detail/9N944SZ21PTS", body)
        self.assertIn('href="/download"', body)

    def test_english(self):
        body = render_at(timedelta(days=3), lang="en")
        self.assertIn("Launching on the night of 27 Rajab 1448", body)
        for label in ("days", "hours", "minutes", "seconds"):
            self.assertIn(f'class="cd-label">{label}<', body)
        live = render_at(timedelta(seconds=-5), lang="en")
        self.assertIn("Get Tibyan", live)
