from __future__ import annotations

import unittest
from datetime import date, timedelta
from unittest.mock import patch

from fastapi import FastAPI, Request
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from starlette.middleware.sessions import SessionMiddleware

from app import analytics, releases
from app.db import Base
from app.deps import get_db
from app.models import DailyDownload, DailyPageView, DailyVisitor, User, VisitSalt
from app.routes import admin_requests, auth, beta, pages
from app.security import hash_password

ROOT = "https://altibyan.app"
UA = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) Safari/604.1"
UA2 = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Firefox/140.0"


class CountersBase(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
        Base.metadata.create_all(self.engine)
        self.Session = sessionmaker(bind=self.engine, autoflush=False)
        analytics.session_factory = self.Session
        analytics.reset_cache()
        app = FastAPI()
        app.add_middleware(SessionMiddleware, secret_key="test-only", https_only=False)

        @app.middleware("http")
        async def count(request: Request, call_next):
            response = await call_next(request)
            analytics.count_page(request, response)
            return response

        for r in (pages.router, auth.router, beta.router, admin_requests.router):
            app.include_router(r)

        def override():
            db = self.Session()
            try:
                yield db
            finally:
                db.close()

        app.dependency_overrides[get_db] = override
        self.app = app
        self.client = TestClient(app, base_url=ROOT)

    def tearDown(self):
        analytics.wait()
        analytics.session_factory = None
        analytics.reset_cache()

    def get(self, path, ua=UA, ip=None, **kw):
        headers = {"user-agent": ua, "accept": "text/html"}
        if ip:
            headers["cf-connecting-ip"] = ip
        r = self.client.get(path, headers=headers, follow_redirects=False, **kw)
        analytics.wait()
        return r

    def rows(self, model):
        with self.Session() as db:
            return db.query(model).all()


class DownloadCounterTest(CountersBase):
    def test_counts_each_platform_per_day(self):
        for p in ("android", "android", "windows", "windows-zip", "macos"):
            self.assertEqual(self.get(f"/download/{p}").status_code, 302)
        got = {r.platform: r.count for r in self.rows(DailyDownload)}
        self.assertEqual(got, {"android": 2, "windows": 1, "windows-zip": 1, "macos": 1})
        self.assertEqual({r.day for r in self.rows(DailyDownload)}, {analytics.today()})

    def test_head_bots_and_unknown_not_counted(self):
        self.client.head("/download/android", headers={"user-agent": UA}, follow_redirects=False)
        self.get("/download/android", ua="Googlebot/2.1")
        self.get("/download/android", ua="curl/8.4")
        self.get("/download/android", ua="")
        self.assertEqual(self.get("/download/nope").status_code, 404)
        self.assertEqual(self.rows(DailyDownload), [])

    def test_redirect_survives_db_failure(self):
        analytics.session_factory = lambda: (_ for _ in ()).throw(RuntimeError("db down"))
        with patch.object(analytics, "_write_download", side_effect=RuntimeError):
            self.assertEqual(self.get("/download/android").status_code, 302)

    def test_new_day_new_row(self):
        with patch.object(analytics, "today", return_value=date(2026, 11, 7)):
            self.get("/download/android")
        self.get("/download/android")
        self.assertEqual(sorted(r.day for r in self.rows(DailyDownload)), [date(2026, 11, 7), analytics.today()])


class VisitCounterTest(CountersBase):
    def test_views_and_unique_visitors(self):
        self.get("/", ip="203.0.113.5")
        self.get("/", ip="203.0.113.5")
        self.get("/privacy", ip="203.0.113.5")
        self.get("/", ip="203.0.113.9", ua=UA2)
        views = {r.path: r.count for r in self.rows(DailyPageView)}
        self.assertEqual(views, {"/": 3, "/privacy": 1})
        visitors = self.rows(DailyVisitor)
        self.assertEqual(len(visitors), 2)
        for v in visitors:
            self.assertEqual(len(v.visitor_hash), 64)
            self.assertNotIn("203.0.113", v.visitor_hash)

    def test_ignored(self):
        self.get("/", ua="Mozilla/5.0 (compatible; bingbot/2.0)")
        self.get("/", ua="facebookexternalhit/1.1")
        self.client.head("/", headers={"user-agent": UA})
        self.get("/static/favicon.svg")
        self.get("/no-such-page")
        TestClient(self.app, base_url="https://train.altibyan.app").get("/", headers={"user-agent": UA})
        analytics.wait()
        self.assertEqual(self.rows(DailyPageView), [])
        self.assertEqual(self.rows(DailyVisitor), [])

    def test_salt_rotates_and_old_salt_dropped(self):
        old = date.today() - timedelta(days=1)
        with patch.object(analytics, "today", return_value=old):
            self.get("/", ip="203.0.113.5")
        self.get("/", ip="203.0.113.5")
        salts = self.rows(VisitSalt)
        self.assertEqual([s.day for s in salts], [analytics.today()])
        hashes = [v.visitor_hash for v in self.rows(DailyVisitor)]
        self.assertEqual(len(set(hashes)), 2)  # same visitor, unlinkable across days


class PublicTotalsTest(CountersBase):
    def seed(self):
        with self.Session() as db:
            db.add(DailyDownload(day=date(2026, 11, 7), platform="android", count=1200))
            db.add(DailyDownload(day=date(2026, 11, 8), platform="windows", count=34))
            for i in range(5):
                db.add(DailyVisitor(day=date(2026, 11, 8), visitor_hash=f"{i:064d}"))
            db.commit()

    def test_home_shows_arabic_digits(self):
        self.seed()
        html = self.client.get("/", headers={"user-agent": UA}).text
        self.assertIn('class="x-totals"', html)
        self.assertIn("<b>١٬٢٣٤</b> تحميل", html)
        self.assertIn("<b>٥</b> زيارة", html)

    def test_home_english(self):
        self.seed()
        self.client.cookies.set("lang", "en")
        html = self.client.get("/", headers={"user-agent": UA}).text
        self.assertIn('lang="en"', html)
        self.assertIn("<b>1,234</b> downloads", html)

    def test_totals_cached(self):
        self.seed()
        with self.Session() as db:
            self.assertEqual(analytics.public_totals(db), {"visits": 5, "downloads": 1234})
            db.add(DailyDownload(day=date(2026, 11, 9), platform="android", count=1))
            db.commit()
            self.assertEqual(analytics.public_totals(db)["downloads"], 1234)
            analytics._cache["at"] -= analytics.CACHE_SECONDS + 1
            self.assertEqual(analytics.public_totals(db)["downloads"], 1235)

    def test_arabic_digits(self):
        self.assertEqual(analytics.arabic_digits(0), "٠")
        self.assertEqual(analytics.arabic_digits(1234567), "١٬٢٣٤٬٥٦٧")


class AdminStatsTest(CountersBase):
    def test_admin_table_and_access(self):
        with self.Session() as db:
            db.add(User(email="admin@example.com", password_hash=hash_password("test-only-password-42"),
                        is_admin=True, consent_ccby=True))
            db.add(DailyDownload(day=date(2026, 11, 8), platform="android", count=7))
            db.commit()
        r = self.client.get("/admin/requests?tab=stats", follow_redirects=False)
        self.assertNotEqual(r.status_code, 200)
        from test_platform_workflow import csrf_from
        train = TestClient(self.app, base_url="https://train.altibyan.app")
        csrf = csrf_from(train.get("/login"))
        train.post("/login", data={"identifier": "admin@example.com", "email": "admin@example.com",
                                         "password": "test-only-password-42", "csrf": csrf},
                   )
        html = train.get("/admin/requests?tab=stats").text
        self.assertIn('class="stats-table"', html)
        self.assertIn("2026-11-08", html)
        self.assertIn(">android<", html)
