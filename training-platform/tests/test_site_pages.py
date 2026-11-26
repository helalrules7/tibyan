"""Info pages of altibyan.app: /features, /about, /sources, /changelog,
/help and /press, in Arabic and under /en."""
from __future__ import annotations

import unittest

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app import analytics, changelog, site_sources
from app.db import Base
from app.deps import get_db
from app.main import app
from app.routes.pages import LOCALIZED, SITE_PAGES

ROOT = "https://altibyan.app"


class SitePagesTests(unittest.TestCase):
    def setUp(self):
        engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
        Base.metadata.create_all(engine)
        Session = sessionmaker(bind=engine)

        def _db():
            db = Session()
            try:
                yield db
            finally:
                db.close()

        app.dependency_overrides[get_db] = _db
        analytics.session_factory = Session
        analytics.reset_cache()
        self.client = TestClient(app, base_url=ROOT)

    def tearDown(self):
        # Let queued page-view writes finish before another test swaps the DB.
        analytics._executor.submit(lambda: None).result()
        app.dependency_overrides.clear()

    def get(self, path):
        r = self.client.get(path, follow_redirects=False)
        self.assertEqual(r.status_code, 200, path)
        return r.text

    def test_every_page_in_both_languages(self):
        sitemap = self.client.get("/sitemap.xml").text
        for path in SITE_PAGES:
            self.assertIn(path, LOCALIZED)
            self.client.cookies.clear()  # an /en visit pins English
            ar = self.get(path)
            en = self.get("/en" + path)
            self.assertIn('lang="ar" dir="rtl"', ar)
            self.assertIn('lang="en" dir="ltr"', en)
            self.assertIn(f'hreflang="en" href="{ROOT}/en{path}"', ar)
            self.assertIn(f'<link rel="canonical" href="{ROOT}/en{path}">', en)
            self.assertIn(f"<loc>{ROOT}{path}</loc>", sitemap)
            self.assertIn(f"<loc>{ROOT}/en{path}</loc>", sitemap)
            for html in (ar, en):
                for banned in ("شعبة", "Shu'bah", "تبرع", "donat", "Donat"):
                    self.assertNotIn(banned, html, (path, banned))

    def test_training_host_redirects_to_root(self):
        client = TestClient(app, base_url="https://train.altibyan.app")
        r = client.get("/features", follow_redirects=False)
        self.assertEqual(r.status_code, 301)
        self.assertEqual(r.headers["location"], f"{ROOT}/features")

    def test_features_lists_editions_without_shubah(self):
        html = self.get("/features")
        for name in ("الطبعة الحديثة", "الطبعة القديمة", "الشمرلي", "ورش", "قالون", "الدوري"):
            self.assertIn(name, html)

    def test_sources_come_from_app_credits(self):
        keys = [s["key"] for _, items in site_sources.SOURCES for s in items]
        self.assertEqual(len(keys), len(set(keys)))
        html = self.get("/sources")
        self.assertIn("مجمع الملك فهد لطباعة المصحف الشريف", html)
        self.assertIn("mp3quran.net", html)
        self.assertIn("Tanzil Project", self.get("/en/sources"))

    def test_changelog_newest_first(self):
        versions = [r["version"] for r in changelog.releases()]
        self.assertEqual(versions[0], "1.0.1")
        self.assertEqual(versions[-1], "0.5.0")
        html = self.get("/changelog")
        self.assertLess(html.index('id="v1.0.1"'), html.index('id="v0.5.0"'))
        self.assertNotIn("testflight", html.lower())
        self.assertNotIn("Android Auto", html)

    def test_help_has_no_money_and_lists_live_stores_only(self):
        html = self.get("/help")
        self.assertIn("train.altibyan.app", html)
        self.assertIn("play.google.com", html)
        self.assertNotIn("apps.apple.com", html)

    def test_home_and_footer_link_the_pages(self):
        home = self.get("/")
        self.assertIn('href="/features"', home)
        for path in SITE_PAGES:
            self.assertIn(f'href="{ROOT}{path}"', home)
        self.assertIn(f'href="{ROOT}/en/press"', self.get("/en/"))
