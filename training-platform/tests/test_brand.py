"""Brand system: tokens, digit font, logo, error pages, e-mails, Facebook link."""
from __future__ import annotations

import re
import unittest
from email.message import EmailMessage
from pathlib import Path
from unittest.mock import patch

from fastapi import HTTPException
from fastapi.testclient import TestClient

from app import mail
from app.email_brand import branded
from app.main import app
from app.templating import FACEBOOK_URL, INSTAGRAM_URL, TIKTOK_URL, YOUTUBE_URL

STATIC = Path(__file__).resolve().parent.parent / "app" / "static"
REPO = STATIC.parent.parent.parent
HTML = {"accept": "text/html,application/xhtml+xml"}


@app.get("/__test_boom")
def _boom():
    raise RuntimeError("test 500")


@app.get("/__test_busy")
def _busy():
    raise HTTPException(status_code=429)


class TokenTests(unittest.TestCase):
    def test_digits_face_is_digit_only_and_listed_first(self):
        css = (STATIC / "tokens.css").read_text()
        faces = re.findall(r"@font-face\s*{[^}]*'TibyanDigits'[^}]*}", css)
        self.assertEqual(len(faces), 4)
        for face in faces:
            self.assertIn("IBMPlexSansArabic", face)
            self.assertIn("unicode-range: U+0030-0039, U+0660-0669, U+06F0-06F9;", face)
        self.assertIn("--font-ui: 'TibyanDigits', 'Tibyan'", css)

    def test_palette_matches_the_app_handasi_look(self):
        css = (STATIC / "tokens.css").read_text()
        for value in ("#0F6660", "#F6F1E8", "#9A7428", "#55BDB2", "#0E1A1B", "#D9B266"):
            self.assertIn(value, css)
        self.assertIn("prefers-color-scheme: dark", css)
        self.assertIn("prefers-reduced-motion: reduce", css)

    def test_component_css_reads_tokens_only(self):
        for name in ("style.css", "player.css"):
            css = (STATIC / name).read_text()
            self.assertNotIn("@font-face", css, name)
            self.assertNotIn(":root", css, name)
        # The old brown palette is gone.
        for name in ("style.css", "player.css", "coming-soon.css"):
            self.assertNotIn("#3A2B20", (STATIC / name).read_text(), name)

    def test_logo_is_the_app_logo_unchanged(self):
        self.assertEqual(
            (STATIC / "brand" / "tibyan-logo.svg").read_bytes(),
            (REPO / "assets" / "brand" / "tibyan_logo.svg").read_bytes(),
        )

    def test_icon_set_exists(self):
        for name in ("favicon.ico", "favicon.svg", "favicon-32.png", "apple-touch-icon.png",
                     "icon-192.png", "icon-512.png", "icon-maskable-192.png", "icon-maskable-512.png",
                     "share.png", "coming-soon-share.png", "brand/logo-cream.png", "brand/pattern.svg"):
            self.assertTrue((STATIC / name).is_file(), name)


class PageTests(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app, raise_server_exceptions=False)

    def test_training_pages_link_tokens_logo_and_facebook(self):
        body = self.client.get("/login").text
        self.assertIn("/static/tokens.css", body)
        self.assertIn('class="logo-mark"', body)
        self.assertIn(f'href="{FACEBOOK_URL}" target="_blank" rel="noopener"', body)
        self.assertIn(f'href="{INSTAGRAM_URL}" target="_blank" rel="noopener"', body)
        self.assertIn(f'href="{TIKTOK_URL}" target="_blank" rel="noopener"', body)
        self.assertIn(f'href="{YOUTUBE_URL}" target="_blank" rel="noopener"', body)
        self.assertIn('"sameAs": ["https://www.facebook.com/tibyanapp/", '
                      '"https://www.instagram.com/tibyanapp/", '
                      '"https://www.tiktok.com/@altibyanapp", '
                      '"https://www.youtube.com/@altibyanApp"]', body)

    def test_root_site_has_follow_line_and_footer_link(self):
        root = TestClient(app, base_url="https://altibyan.app")
        for path in ("/",):
            body = root.get(path).text
            self.assertIn('class="follow-line"', body, path)
            self.assertEqual(body.count(f'href="{FACEBOOK_URL}"'), 2, path)
            self.assertEqual(body.count(f'href="{INSTAGRAM_URL}"'), 2, path)
            self.assertEqual(body.count(f'href="{TIKTOK_URL}"'), 2, path)
            self.assertEqual(body.count(f'href="{YOUTUBE_URL}"'), 2, path)
            self.assertIn(YOUTUBE_URL + '"]', body, path)
            self.assertIn(f'<meta property="og:see_also" content="{YOUTUBE_URL}">', body, path)
            self.assertIn(f'<meta property="og:see_also" content="{TIKTOK_URL}">', body, path)
            self.assertIn("sameAs", body, path)

    def test_manifest_has_maskable_icons_and_brand_colours(self):
        data = self.client.get("/manifest.webmanifest").json()
        self.assertEqual(data["theme_color"], "#0F6660")
        purposes = {i["src"]: i.get("purpose") for i in data["icons"]}
        self.assertEqual(purposes["/static/icon-maskable-512.png"], "maskable")

    def test_branded_404_for_browsers_json_for_apis(self):
        r = self.client.get("/no-such-page", headers=HTML)
        self.assertEqual(r.status_code, 404)
        self.assertIn("error-card", r.text)
        self.assertIn("الصفحة غير موجودة", r.text)
        r = self.client.get("/no-such-page")
        self.assertEqual(r.json(), {"detail": "Not Found"})

    def test_branded_429_and_500(self):
        r = self.client.get("/__test_busy", headers=HTML)
        self.assertEqual(r.status_code, 429)
        self.assertIn("طلبات كثيرة", r.text)
        r = self.client.get("/__test_boom", headers=HTML)
        self.assertEqual(r.status_code, 500)
        self.assertIn("error-card", r.text)
        self.assertNotIn("test 500", r.text)


class EmailTests(unittest.TestCase):
    def test_branded_email_has_logo_footer_and_escapes(self):
        text, html = branded("ar", "عنوان", "سطر <b>\n\n1. افتح https://example.com/x\n2. ثبّت")
        self.assertIn(FACEBOOK_URL, text)
        self.assertIn('dir="rtl"', html)
        self.assertIn("logo-cream.png", html)
        self.assertIn(FACEBOOK_URL, html)
        self.assertIn(INSTAGRAM_URL, text)
        self.assertIn(INSTAGRAM_URL, html)
        self.assertIn(TIKTOK_URL, text)
        self.assertIn(TIKTOK_URL, html)
        self.assertIn(YOUTUBE_URL, text)
        self.assertIn(YOUTUBE_URL, html)
        self.assertIn("&lt;b&gt;", html)
        self.assertIn('href="https://example.com/x"', html)

    def test_send_mail_adds_html_alternative(self):
        sent: list[EmailMessage] = []

        class FakeSMTP:
            def __init__(self, *a, **k): pass
            def __enter__(self): return self
            def __exit__(self, *a): return False
            def ehlo(self): pass
            def starttls(self, **k): pass
            def login(self, *a): pass
            def send_message(self, m): sent.append(m)

        with patch.object(mail.settings, "smtp_host", "smtp.test"), \
             patch.object(mail.settings, "smtp_from", "a@test"), \
             patch.object(mail.smtplib, "SMTP", FakeSMTP):
            self.assertTrue(mail.send_mail("s", "plain", to="b@test", html="<p>x</p>"))
        msg = sent[0]
        self.assertEqual(msg.get_content_type(), "multipart/alternative")
        self.assertEqual([p.get_content_type() for p in msg.iter_parts()], ["text/plain", "text/html"])


if __name__ == "__main__":
    unittest.main()
