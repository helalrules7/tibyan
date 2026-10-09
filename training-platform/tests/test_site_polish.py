from __future__ import annotations

import unittest
from datetime import date

from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from starlette.middleware.sessions import SessionMiddleware

from app import stats
from app.config import settings
from app.db import Base, migrate_user_birth_year
from app.deps import get_db
from app.models import NotifySignup, Recording, User
from app.routes import auth, notify, pages
from app.routes.auth import may_be_minor, parse_birth_year
from app.security import hash_password
from test_platform_workflow import csrf_from

PASSWORD = "test-only-password-42"


class SitePolishTests(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine(
            "sqlite://",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )
        Base.metadata.create_all(self.engine)
        self.Session = sessionmaker(bind=self.engine, autoflush=False)
        self.app = FastAPI()
        self.app.add_middleware(SessionMiddleware, secret_key="test-only", https_only=False)
        for router in (pages.router, auth.router, notify.router):
            self.app.include_router(router)

        def override_get_db():
            db = self.Session()
            try:
                yield db
            finally:
                db.close()

        self.app.dependency_overrides[get_db] = override_get_db
        stats._cache.update(at=0.0, value=None)

    def tearDown(self):
        stats._cache.update(at=0.0, value=None)
        self.engine.dispose()

    def client(self, host="train.altibyan.app"):
        return TestClient(self.app, base_url=f"http://{host}")

    # -- registration: birth year only, no phone field --------------------
    def test_register_form_asks_year_only_and_no_phone(self):
        with self.client() as c:
            page = c.get("/register").text
        self.assertIn('name="birth_year"', page)
        self.assertNotIn('name="birth_date"', page)
        self.assertNotIn('name="phone"', page)

    def test_register_stores_year_not_full_date(self):
        with self.client() as c:
            form = c.get("/register")
            done = c.post("/register", data={
                "email": "year@example.test",
                "password": PASSWORD,
                "password_confirm": PASSWORD,
                "birth_year": "1990",
                "consent": "1",
                "csrf": csrf_from(form),
            }, follow_redirects=False)
        self.assertEqual(done.status_code, 303)
        with self.Session() as db:
            user = db.query(User).one()
            self.assertEqual(user.birth_year, 1990)
            self.assertIsNone(user.birth_date)
            self.assertIsNone(user.phone)

    def test_minor_year_requires_parental_consent(self):
        minor_year = str(date.today().year - 10)
        with self.client() as c:
            form = c.get("/register")
            refused = c.post("/register", data={
                "email": "kid@example.test",
                "password": PASSWORD,
                "password_confirm": PASSWORD,
                "birth_year": minor_year,
                "consent": "1",
                "csrf": csrf_from(form),
            }, follow_redirects=False)
            self.assertEqual(refused.status_code, 200)
            accepted = c.post("/register", data={
                "email": "kid@example.test",
                "password": PASSWORD,
                "password_confirm": PASSWORD,
                "birth_year": minor_year,
                "consent": "1",
                "parental": "1",
                "csrf": csrf_from(refused),
            }, follow_redirects=False)
        self.assertEqual(accepted.status_code, 303)
        with self.Session() as db:
            self.assertTrue(db.query(User).one().consent_parental)

    def test_year_rules(self):
        today = date(2026, 10, 9)
        self.assertTrue(may_be_minor(2010, today))
        self.assertTrue(may_be_minor(2008, today))  # may not be 18 yet
        self.assertFalse(may_be_minor(2007, today))
        self.assertIsNone(parse_birth_year("1990-01-01", today))
        self.assertIsNone(parse_birth_year("2027", today))
        self.assertEqual(parse_birth_year(" 1985 ", today), 1985)

    def test_birth_year_migration_is_additive(self):
        engine = create_engine("sqlite://", poolclass=StaticPool)
        with engine.begin() as conn:
            conn.execute(text("CREATE TABLE users (id INTEGER PRIMARY KEY, birth_date DATE, phone TEXT)"))
            conn.execute(text("INSERT INTO users VALUES (1, '1990-05-05', '0100')"))
        migrate_user_birth_year(engine)
        migrate_user_birth_year(engine)  # idempotent
        cols = {c["name"] for c in inspect(engine).get_columns("users")}
        self.assertIn("birth_year", cols)
        with engine.begin() as conn:
            row = conn.execute(text("SELECT birth_date, phone, birth_year FROM users")).one()
        self.assertEqual(tuple(row), ("1990-05-05", "0100", None))

    # -- home page counter and voice page ---------------------------------
    def test_training_home_shows_progress_and_needed_voices(self):
        with self.Session() as db:
            user = User(email="a@example.test", password_hash=hash_password(PASSWORD),
                        consent_ccby=True, consent_parental=False)
            db.add(user)
            db.commit()
            db.add_all([
                Recording(user_id=user.id, surah=1, ayah=1, audio_path="x",
                          audio_duration_ms=90_000, status="accepted"),
                Recording(user_id=user.id, surah=1, ayah=2, audio_path="y",
                          audio_duration_ms=60_000, status="rejected"),
            ])
            db.commit()
        with self.client() as c:
            page = c.get("/").text
        self.assertIn("1.5", page)  # rejected minutes are not counted
        self.assertIn(f"{settings.training_goal_minutes}", page)
        self.assertIn("أصوات النساء", page)
        self.assertIn('href="https://altibyan.app/"', page)
        self.assertIn('href="/voice"', page)

    def test_voice_page(self):
        with self.client() as c:
            page = c.get("/voice")
        self.assertEqual(page.status_code, 200)
        self.assertIn("CC BY 4.0", page.text)
        self.assertIn('id="delete"', page.text)

    # -- robots / sitemap / favicon -----------------------------------------
    def test_robots_and_sitemap_are_host_aware(self):
        with self.client() as c:
            robots = c.get("/robots.txt").text
            sitemap = c.get("/sitemap.xml")
        self.assertIn("Disallow: /admin", robots)
        self.assertIn("https://train.altibyan.app/sitemap.xml", robots)
        self.assertIn("https://train.altibyan.app/voice", sitemap.text)
        self.assertIn("application/xml", sitemap.headers["content-type"])
        with self.client("altibyan.app") as c:
            self.assertIn("https://altibyan.app/sitemap.xml", c.get("/robots.txt").text)
            self.assertIn("<loc>https://altibyan.app/</loc>", c.get("/sitemap.xml").text)
            icon = c.get("/favicon.ico")
        self.assertEqual(icon.status_code, 200)
        self.assertEqual(icon.headers["content-type"], "image/x-icon")

    # -- altibyan.app notify me ---------------------------------------------
    def test_notify_stores_email_once_and_beta_flag(self):
        with self.client("altibyan.app") as c:
            home = c.get("/")
            self.assertIn('action="/notify"', home.text)
            self.assertIn("https://train.altibyan.app/", home.text)
            token = csrf_from(home)
            first = c.post("/notify", data={"email": " Fan@Example.test ", "csrf": token},
                           follow_redirects=False)
            self.assertEqual(first.status_code, 303)
            self.assertIn("شكرًا", c.get("/").text)
            c.post("/notify", data={"email": "fan@example.test", "beta": "1", "csrf": token})
            c.post("/notify", data={"email": "bot@example.test", "website": "x", "csrf": token})
            c.post("/notify", data={"email": "not-an-email", "csrf": token})
        with self.Session() as db:
            rows = db.query(NotifySignup).all()
        self.assertEqual([r.email for r in rows], ["fan@example.test"])
        self.assertTrue(rows[0].wants_beta)

    def test_notify_requires_csrf(self):
        with self.client("altibyan.app") as c:
            c.get("/")
            response = c.post("/notify", data={"email": "x@example.test", "csrf": "bad"})
        self.assertEqual(response.status_code, 400)


if __name__ == "__main__":
    unittest.main()
