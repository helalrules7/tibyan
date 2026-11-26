from __future__ import annotations

import os
import tempfile
import threading
import unittest
from datetime import date
from unittest.mock import MagicMock, patch

from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, inspect
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from starlette.middleware.sessions import SessionMiddleware

from app import db as app_db
from app import ratelimit
from app.db import Base
from app.deps import get_db
from app.models import Notification, NotifySignup, User
from app.routes import admin_requests, auth, beta, notify, pages
from app.security import hash_password
from test_platform_workflow import csrf_from

PASSWORD = "test-only-password-42"
ROOT = "https://altibyan.app"


class LaunchFormsBase(unittest.TestCase):
    def setUp(self):
        ratelimit.reset()
        self.engine = create_engine(
            "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool
        )
        Base.metadata.create_all(self.engine)
        self.Session = sessionmaker(bind=self.engine, autoflush=False)
        self.app = FastAPI()
        self.app.add_middleware(SessionMiddleware, secret_key="test-only", https_only=False)
        for router in (pages.router, auth.router, notify.router, beta.router, admin_requests.router):
            self.app.include_router(router)

        def override_get_db():
            db = self.Session()
            try:
                yield db
            finally:
                db.close()

        self.app.dependency_overrides[get_db] = override_get_db
        self.mails = []
        for module, name in (
            (notify, "send_notify_confirmation"), (beta, "send_beta_confirmation"),
            (notify, "send_signup_alert"), (beta, "send_signup_alert"),
        ):
            p = patch.object(module, name, side_effect=lambda *a, _n=name: self.mails.append((_n, a)))
            p.start()
            self.addCleanup(p.stop)

    def tearDown(self):
        ratelimit.reset()
        self.engine.dispose()

    def client(self, ip="203.0.113.9"):
        return TestClient(self.app, base_url=ROOT, client=(ip, 50000))

    def rows(self):
        with self.Session() as db:
            return db.query(NotifySignup).order_by(NotifySignup.id).all()


class NotifyFormTests(LaunchFormsBase):
    def submit(self, c, **data):
        if not getattr(c, "csrf", None):
            c.csrf = csrf_from(c.get("/"))
        return c.post("/notify", data={"csrf": c.csrf, **data}, follow_redirects=False)

    def test_page_has_beta_button_not_checkbox(self):
        with self.client() as c:
            html = c.get("/").text
        self.assertIn('href="/download"', html)
        self.assertIn("انضم لاختبار النسخة التجريبية", html)
        self.assertNotIn('name="beta"', html)

    def test_missing_csrf_is_rejected(self):
        with self.client() as c:
            c.get("/")
            r = c.post("/notify", data={"email": "a@example.test"})
        self.assertEqual(r.status_code, 400)
        self.assertEqual(self.rows(), [])

    def test_valid_signup_stored_once_and_confirmed_once(self):
        with self.client() as c:
            r = self.submit(c, email="  Someone@Example.TEST ")
            self.assertEqual(r.status_code, 303)
            self.assertIn("تم تسجيل بريدك", c.get("/").text)
            self.submit(c, email="someone@example.test")
        rows = self.rows()
        self.assertEqual([r.email for r in rows], ["someone@example.test"])
        self.assertEqual(rows[0].lang, "ar")
        self.assertEqual(
            sorted(m[0] for m in self.mails), ["send_notify_confirmation", "send_signup_alert"]
        )

    def test_invalid_email_shows_error_and_keeps_value(self):
        with self.client() as c:
            self.submit(c, email="not-an-email")
            html = c.get("/").text
        self.assertIn("أدخل بريدًا إلكترونيًا صحيحًا", html)
        self.assertIn('value="not-an-email"', html)
        self.assertEqual(self.rows(), [])

    def test_honeypot_looks_ok_but_stores_nothing(self):
        with self.client() as c:
            self.submit(c, email="bot@example.test", website="http://spam")
            self.assertIn("تم تسجيل بريدك", c.get("/").text)
        self.assertEqual(self.rows(), [])
        self.assertEqual(self.mails, [])

    def test_rate_limit_gives_friendly_message(self):
        with self.client() as c:
            for i in range(5):
                self.submit(c, email=f"u{i}@example.test")
            self.submit(c, email="late@example.test")
            self.assertIn("محاولات كثيرة", c.get("/").text)
        self.assertEqual(len(self.rows()), 5)

    def test_nginx_429_redirect_shows_message(self):
        with self.client() as c:
            self.assertIn("محاولات كثيرة", c.get("/?n=busy").text)


class BetaRedirectTests(unittest.TestCase):
    """After the launch, /beta sends visitors to the download page."""

    def test_beta_redirects_to_download(self):
        from app.main import app
        c = TestClient(app, base_url=ROOT)
        for path, target in (("/beta", "/download"), ("/en/beta", "/en/download")):
            r = c.get(path, follow_redirects=False)
            self.assertEqual(r.status_code, 301, path)
            self.assertEqual(r.headers.get("location"), target, path)


class SignupAlertTests(unittest.TestCase):
    def test_alert_goes_to_every_configured_address(self):
        from app import launch_mail
        from app.config import settings

        saved = settings.signup_notify_emails
        settings.signup_notify_emails = "noreply@example.test, info@example.test"
        try:
            with patch.object(launch_mail, "send_mail", return_value=True) as sm:
                launch_mail.send_signup_alert("beta", "x@example.test", "ar", ["ios", "mac"])
            kwargs = sm.call_args.kwargs
            self.assertEqual(kwargs["to"], "noreply@example.test, info@example.test")
            self.assertIn("x@example.test", kwargs["body"])
            self.assertIn("ios, mac", kwargs["body"])
            self.assertIn("/admin/requests?tab=beta", kwargs["body"])
            settings.signup_notify_emails = ""
            with patch.object(launch_mail, "send_mail") as sm:
                launch_mail.send_signup_alert("notify", "x@example.test", "ar")
            sm.assert_not_called()
        finally:
            settings.signup_notify_emails = saved


class MigrationTests(unittest.TestCase):
    def setUp(self):
        fd, self.path = tempfile.mkstemp(suffix=".db")
        os.close(fd)
        os.unlink(self.path)
        self.engine = create_engine(f"sqlite:///{self.path}")

    def tearDown(self):
        self.engine.dispose()
        if os.path.exists(self.path):
            os.unlink(self.path)

    def test_run_migrations_is_idempotent(self):
        app_db.run_migrations(self.engine)
        app_db.run_migrations(self.engine)
        cols = {c["name"] for c in inspect(self.engine).get_columns("notify_signups")}
        self.assertTrue({"beta_platforms", "beta_requested_at"} <= cols)

    def test_concurrent_workers_do_not_crash(self):
        errors = []

        def worker():
            try:
                app_db.run_migrations(self.engine)
            except Exception as exc:  # pragma: no cover - reported below
                errors.append(exc)

        threads = [threading.Thread(target=worker) for _ in range(4)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()
        self.assertEqual(errors, [])

    def test_table_already_exists_1050_is_tolerated(self):
        real = Base.metadata.create_all
        calls = []

        def flaky(*args, **kwargs):
            calls.append(1)
            if len(calls) == 1:
                real(*args, **kwargs)
                raise OperationalError("CREATE TABLE x", {}, Exception(1050, "Table 'platform_settings' already exists"))
            return real(*args, **kwargs)

        with patch.object(Base.metadata, "create_all", side_effect=flaky):
            app_db.run_migrations(self.engine)
        self.assertEqual(len(calls), 2)

    def test_other_operational_errors_still_raise(self):
        err = OperationalError("CREATE TABLE x", {}, Exception(1045, "Access denied"))
        with patch.object(Base.metadata, "create_all", side_effect=err):
            with self.assertRaises(OperationalError):
                app_db.run_migrations(self.engine)

    def test_mysql_takes_and_releases_named_lock(self):
        bind = MagicMock()
        bind.dialect.name = "mysql"
        conn = bind.connect.return_value.__enter__.return_value
        conn.execute.return_value.scalar.return_value = 1
        with app_db.migration_lock(bind):
            pass
        sql = [str(call.args[0]) for call in conn.execute.call_args_list]
        self.assertIn("GET_LOCK", sql[0])
        self.assertIn("RELEASE_LOCK", sql[-1])

    def test_mysql_lock_timeout_raises(self):
        bind = MagicMock()
        bind.dialect.name = "mysql"
        conn = bind.connect.return_value.__enter__.return_value
        conn.execute.return_value.scalar.return_value = 0
        with self.assertRaises(RuntimeError):
            with app_db.migration_lock(bind):
                pass


if __name__ == "__main__":
    unittest.main()
