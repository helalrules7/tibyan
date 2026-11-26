from __future__ import annotations

import unittest

from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from starlette.middleware.sessions import SessionMiddleware

from app.db import Base
from app.deps import get_db
from app.routes import beta, contact, pages

ROOT = "altibyan.app"
TRAIN = "train.altibyan.app"


class PrivacyPageTests(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine(
            "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool
        )
        Base.metadata.create_all(self.engine)
        Session = sessionmaker(bind=self.engine, autoflush=False)
        self.app = FastAPI()
        self.app.add_middleware(SessionMiddleware, secret_key="test-only", https_only=False)
        for router in (pages.router, beta.router, contact.router):
            self.app.include_router(router)

        def override_get_db():
            db = Session()
            try:
                yield db
            finally:
                db.close()

        self.app.dependency_overrides[get_db] = override_get_db

    def tearDown(self):
        self.engine.dispose()

    def client(self, host=ROOT):
        return TestClient(self.app, base_url=f"http://{host}")

    def test_arabic_policy(self):
        with self.client() as c:
            r = c.get("/privacy")
        self.assertEqual(r.status_code, 200)
        page = r.text
        self.assertIn('lang="ar" dir="rtl"', page)
        self.assertIn("سياسة الخصوصية", page)
        self.assertIn('class="policy-summary"', page)
        self.assertIn("info@altibyan.app", page)
        self.assertIn('<time datetime="2026-11-09">', page)
        self.assertIn('id="group-khatma"', page)
        self.assertIn('href="/privacy/en"', page)
        self.assertIn('rel="canonical" href="https://altibyan.app/privacy"', page)
        # the facts the policy must state
        for fact in ("لا يُرسل شيء إلا إن وافقت", "CC BY 4.0", "GlitchTip", "errors.altibyan.app", "١٢ شهرًا", "ولي الأمر"):
            self.assertIn(fact, page)

    def test_english_policy(self):
        with self.client() as c:
            r = c.get("/privacy/en")
        self.assertEqual(r.status_code, 200)
        page = r.text
        self.assertIn('lang="en" dir="ltr"', page)
        self.assertIn("Privacy policy", page)
        self.assertIn("off by default", page)
        self.assertIn("9 November 2026", page)
        self.assertIn("Ahmed Mohamed Mohamed Helal", page)  # AppGallery requires the developer name
        self.assertIn('href="/privacy"', page)

    def test_language_cookie_does_not_change_the_url_language(self):
        with self.client() as c:
            c.cookies.set("lang", "en")
            self.assertIn('lang="ar"', c.get("/privacy").text)

    def test_training_host_redirects_to_root(self):
        with self.client(TRAIN) as c:
            r = c.get("/privacy", follow_redirects=False)
            self.assertEqual(r.status_code, 301)
            self.assertEqual(r.headers["location"], "https://altibyan.app/privacy")
            r = c.get("/privacy/en", follow_redirects=False)
            self.assertEqual(r.headers["location"], "https://altibyan.app/privacy/en")

    def test_footer_links_on_both_sites(self):
        with self.client() as c:
            for path in ("/", "/beta", "/privacy"):
                with self.subTest(path=path):
                    self.assertIn('href="https://altibyan.app/privacy"', c.get(path).text)
        with self.client(TRAIN) as c:
            for path in ("/voice", "/contact"):
                with self.subTest(path=path):
                    self.assertIn('href="https://altibyan.app/privacy"', c.get(path).text)
            c.cookies.set("lang", "en")
            self.assertIn('href="https://altibyan.app/privacy/en"', c.get("/contact").text)

    def test_forms_carry_the_consent_line(self):
        with self.client() as c:
            home = c.get("/").text
            self.assertIn("بالضغط على الزر توافق على", home)
            c.cookies.set("lang", "en")
            self.assertIn("you agree to the", c.get("/").text)

    def test_sitemap_lists_policy(self):
        with self.client() as c:
            body = c.get("/sitemap.xml").text
        self.assertIn("https://altibyan.app/privacy</loc>", body)
        self.assertIn("https://altibyan.app/privacy/en</loc>", body)


if __name__ == "__main__":
    unittest.main()
