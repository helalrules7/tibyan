"""Launch switch (LAUNCH_FORCE, admin ?preview=), app/stores.py and the
/en/ prefix on altibyan.app."""
from __future__ import annotations

import os
import unittest
from datetime import datetime, timedelta, timezone
from unittest import mock

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app import analytics, stores
from app.db import Base
from app.deps import get_db
from app.main import app
from app.models import User
from app.routes.pages import launch_state, localized_path

ROOT = "https://altibyan.app"
FUTURE = (datetime.now(timezone.utc) + timedelta(days=30)).replace(microsecond=0).isoformat()


class StoresTests(unittest.TestCase):
    def test_registry(self):
        keys = [s.key for s in stores.STORES]
        self.assertEqual(keys, ["google-play", "app-store", "mac-app-store", "microsoft-store", "appgallery"])
        self.assertIn("id=app.tibyan.tibyan", stores.get("google-play").url)
        self.assertIn("6818990351", stores.get("app-store").url)
        self.assertEqual(stores.get("microsoft-store").url, "https://apps.microsoft.com/detail/9N944SZ21PTS")
        # Apple stores show «قريبًا» until the iOS/Mac release; the rest are live.
        self.assertEqual([s.key for s in stores.STORES if not s.live], ["app-store", "mac-app-store"])

    def test_direct_downloads_use_counted_redirect(self):
        for key in ("apk", "windows-setup", "linux-appimage"):
            self.assertTrue(stores.get(key).url.startswith("/download/"), key)
        self.assertIn("apt.altibyan.app/setup.sh", stores.APT_SETUP)

    def test_detect_os(self):
        cases = {
            "Mozilla/5.0 (Linux; Android 14; Pixel 8)": "android",
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)": "ios",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64)": "windows",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0)": "macos",
            "Mozilla/5.0 (X11; Ubuntu; Linux x86_64)": "linux",
            "": None,
        }
        for ua, want in cases.items():
            self.assertEqual(stores.detect_os(ua), want, ua)


class LaunchSwitchTests(unittest.TestCase):
    def test_force_env(self):
        with mock.patch.dict(os.environ, {"LAUNCH_AT": FUTURE, "LAUNCH_FORCE": "live"}):
            self.assertEqual(launch_state()["launch_phase"], "live")
        with mock.patch.dict(os.environ, {"LAUNCH_AT": "2020-01-01T00:00:00+00:00", "LAUNCH_FORCE": "before"}):
            self.assertEqual(launch_state()["launch_phase"], "before")
        with mock.patch.dict(os.environ, {"LAUNCH_AT": FUTURE, "LAUNCH_FORCE": "nonsense"}):
            self.assertEqual(launch_state()["launch_phase"], "before")

    def test_switch_moment(self):
        at = datetime(2026, 11, 25, 22, 0, tzinfo=timezone.utc)  # 00:00 Cairo, 26 Nov
        with mock.patch.dict(os.environ, {"LAUNCH_AT": "", "LAUNCH_FORCE": ""}):
            self.assertEqual(launch_state(at - timedelta(seconds=1))["launch_phase"], "last24")
            self.assertEqual(launch_state(at)["launch_phase"], "live")


class SiteTests(unittest.TestCase):
    def setUp(self):
        engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
        Base.metadata.create_all(engine)
        self.Session = sessionmaker(bind=engine)

        def _db():
            db = self.Session()
            try:
                yield db
            finally:
                db.close()

        app.dependency_overrides[get_db] = _db
        analytics.session_factory = self.Session
        analytics.reset_cache()
        self.client = TestClient(app, base_url=ROOT)
        self.env = mock.patch.dict(os.environ, {"LAUNCH_AT": FUTURE, "LAUNCH_FORCE": ""})
        self.env.start()

    def tearDown(self):
        self.env.stop()
        app.dependency_overrides.clear()

    def live(self, html):
        return 'class="hero-downloads" data-launched aria-label' in html and 'hero-downloads" data-launched aria-label="تحميل تبيان" hidden' not in html

    def test_home_before_and_forced_live(self):
        html = self.client.get("/").text
        self.assertIn('data-prelaunch>', html)
        self.assertIn('aria-label="تحميل تبيان" hidden', html)
        with mock.patch.dict(os.environ, {"LAUNCH_FORCE": "live"}):
            html = self.client.get("/").text
        self.assertNotIn('aria-label="تحميل تبيان" hidden', html)
        self.assertNotIn("data-launch=", html)  # no timer to flip it back
        self.assertIn("AppGallery", html)
        self.assertIn("قريبًا", html)

    def test_preview_needs_admin(self):
        html = self.client.get("/?preview=live").text
        self.assertIn('aria-label="تحميل تبيان" hidden', html)
        db = self.Session()
        admin = User(email="a@example.com", password_hash="x", is_admin=True)
        db.add(admin)
        db.commit()
        uid = admin.id
        db.close()
        with mock.patch("app.routes.pages.current_user", lambda request, db: db.get(User, uid)):
            html = self.client.get("/?preview=live").text
        self.assertNotIn('aria-label="تحميل تبيان" hidden', html)

    def test_download_page(self):
        r = self.client.get("/download", headers={"user-agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64)"})
        self.assertEqual(r.status_code, 200)
        html = r.text
        self.assertIn(stores.APT_SETUP.replace("|", "|"), html.replace("&#124;", "|"))
        self.assertIn("sudo apt install tibyan", html)
        self.assertIn('class="dl-item is-mine" data-os="linux"', html)
        self.assertNotIn("تجريبي", html)
        self.assertIn('hreflang="en" href="https://altibyan.app/en/download"', html)

    def test_download_redirects_still_work(self):
        r = self.client.get("/download/android", follow_redirects=False)
        self.assertEqual(r.status_code, 302)
        r = self.client.get("/download/linux-appimage", follow_redirects=False)
        self.assertEqual(r.status_code, 302)

    def test_linux_arch_patterns(self):
        import fnmatch
        from app import releases
        names = ["tibyan-linux-arm64.tar.gz", "tibyan-linux-x64.tar.gz", "tibyan-0.8.6-aarch64.appimage",
                 "tibyan-0.8.6-x86_64.appimage", "tibyan_0.8.6-52_arm64.deb", "tibyan_0.8.6-52_amd64.deb"]
        def pick(platform):
            for pat in releases.PATTERNS[platform]:
                hit = next((n for n in names if fnmatch.fnmatch(n, pat)), None)
                if hit:
                    return hit
        self.assertEqual(pick("linux"), "tibyan-linux-x64.tar.gz")  # never the arm64 tarball
        self.assertEqual(pick("linux-arm64"), "tibyan-linux-arm64.tar.gz")
        self.assertEqual(pick("linux-arm64-appimage"), "tibyan-0.8.6-aarch64.appimage")
        self.assertEqual(pick("linux-appimage"), "tibyan-0.8.6-x86_64.appimage")
        self.assertEqual(pick("linux-arm64-deb"), "tibyan_0.8.6-52_arm64.deb")
        html = self.client.get("/download").text
        for href in ("/download/linux-arm64-appimage", "/download/linux-arm64-deb", "/download/linux-arm64"):
            self.assertIn(f'href="{href}"', html)

    def test_en_prefix(self):
        r = self.client.get("/en/")
        self.assertEqual(r.status_code, 200)
        self.assertIn('lang="en"', r.text)
        self.assertIn('rel="canonical" href="https://altibyan.app/en/"', r.text)
        self.assertIn('hreflang="ar" href="https://altibyan.app/"', r.text)
        self.assertIn('lang="en"', self.client.get("/en/download").text)
        self.assertIn('lang="en"', self.client.get("/en/beta").text)
        self.assertEqual(self.client.get("/en", follow_redirects=False).headers["location"], "/en/")

    def test_bare_path_is_arabic_and_old_cookie_redirects(self):
        fresh = TestClient(app, base_url=ROOT)
        self.assertIn('lang="ar"', fresh.get("/download").text)
        fresh.cookies.set("lang", "en")
        r = fresh.get("/download?x=1", follow_redirects=False)
        self.assertEqual((r.status_code, r.headers["location"]), (302, "/en/download?x=1"))

    def test_lang_toggle_goes_to_prefix(self):
        r = self.client.get("/lang/en", headers={"referer": f"{ROOT}/download"}, follow_redirects=False)
        self.assertEqual(r.headers["location"], "/en/download")
        r = self.client.get("/lang/ar", headers={"referer": f"{ROOT}/en/"}, follow_redirects=False)
        self.assertEqual(r.headers["location"], "/")
        self.assertEqual(localized_path("/privacy", "en"), "/privacy")

    def test_training_host_keeps_cookie(self):
        train = TestClient(app, base_url="https://train.altibyan.app")
        train.cookies.set("lang", "en")
        r = train.get("/", follow_redirects=False)
        self.assertEqual(r.status_code, 200)
        self.assertIn('lang="en"', r.text)


if __name__ == "__main__":
    unittest.main()
