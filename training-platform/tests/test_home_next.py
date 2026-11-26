"""The redesigned home (/next) and the reader API behind it."""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

from fastapi.testclient import TestClient

from app import quran_site
from app.config import settings
from app.main import app

REPO = Path(__file__).resolve().parents[2]
CONTENT = REPO / "assets" / "db" / "content.db"
ROOT = "https://altibyan.app"


def _clear():
    for f in (quran_site.surahs, quran_site.reciters, quran_site.credits, quran_site.surah,
              quran_site.tafsir, quran_site.timing, quran_site.basmala):
        f.cache_clear()


@unittest.skipUnless(CONTENT.is_file(), "the app content database is not in this checkout")
class ReaderTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        sys.path.insert(0, str(REPO / "training-platform" / "tools"))
        import build_site_quran

        cls.tmp = tempfile.TemporaryDirectory()
        cls.old = settings.quran_db_path
        settings.quran_db_path = str(build_site_quran.build(CONTENT, Path(cls.tmp.name) / "q.db"))
        _clear()
        cls.c = TestClient(app, base_url=ROOT)

    @classmethod
    def tearDownClass(cls):
        settings.quran_db_path = cls.old
        _clear()
        cls.tmp.cleanup()

    def test_page_has_a_working_reader_and_is_not_indexed(self):
        for path in ("/next", "/en/next"):
            html = self.c.get(path).text
            self.assertIn('data-reader', html, path)
            self.assertIn('name="robots" content="noindex"', html, path)
            self.assertEqual(html.count('class="x-ayah"'), 7, path)  # Al-Fatiha, rendered on the server
            self.assertIn('data-reciter="1"', html, path)
            self.assertIn("play.google.com/store/apps/details?id=app.tibyan.tibyan", html, path)
            self.assertNotIn("apps.apple.com", html, path)  # «قريبًا» until Apple releases

    def test_surah_is_verbatim_from_the_app_database(self):
        import sqlite3

        d = self.c.get("/api/quran/surah/112").json()
        src = sqlite3.connect(CONTENT)
        want = [r[0] for r in src.execute("SELECT display_text FROM ayah WHERE surah = 112 ORDER BY number")]
        first = src.execute("SELECT display_text FROM ayah WHERE surah = 1 AND number = 1").fetchone()[0]
        self.assertEqual([a["t"] for a in d["ayahs"]], want)
        self.assertTrue(first.startswith(d["basmala"]))
        self.assertEqual(len(first) - len(d["basmala"]), 2)  # only the space and the verse mark are left out
        self.assertIsNone(self.c.get("/api/quran/surah/1").json()["basmala"])
        self.assertIsNone(self.c.get("/api/quran/surah/9").json()["basmala"])
        self.assertEqual(self.c.get("/api/quran/surah/115").status_code, 404)

    def test_tafsir_timing_and_search(self):
        import sqlite3

        src = sqlite3.connect(CONTENT)
        want = src.execute("SELECT text FROM commentary WHERE source_id = 7 AND surah = 2 AND ayah = 255").fetchone()[0]
        self.assertEqual(self.c.get("/api/quran/tafsir/2/255").json()["text"], want)
        self.assertEqual(self.c.get("/api/quran/tafsir/2/999").status_code, 404)
        t = self.c.get("/api/quran/timing/1/112").json()
        self.assertTrue(t["url"].endswith("/112.mp3"))
        self.assertEqual([a[0] for a in t["ayahs"]][-4:], [1, 2, 3, 4])
        self.assertEqual(self.c.get("/api/quran/timing/999/1").status_code, 404)
        hits = self.c.get("/api/quran/search", params={"q": "الصَّابِرِينَ"}).json()
        self.assertEqual(hits["q"], "الصابرين")
        self.assertTrue(hits["results"] and all("name_ar" in r for r in hits["results"]))
        self.assertEqual(self.c.get("/api/quran/search", params={"q": "ا"}).json()["results"], [])

    def test_missing_database_hides_the_reader(self):
        keep, settings.quran_db_path = settings.quran_db_path, "/nonexistent/q.db"
        _clear()
        try:
            html = self.c.get("/next").text
            self.assertNotIn("data-reader", html)
            self.assertIn('id="get"', html)
            self.assertEqual(self.c.get("/api/quran/surah/1").status_code, 503)
        finally:
            settings.quran_db_path = keep
            _clear()
