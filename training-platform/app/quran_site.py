"""Read-only access to the website reader's database (tools/build_site_quran.py).

The texts are verbatim copies of the app's own content database. Nothing here
writes, edits or generates Quran or tafsir text.
"""
from __future__ import annotations

import re
import sqlite3
from functools import lru_cache
from pathlib import Path

from .config import settings

# Arabic marks stripped from a search query so it matches Tanzil Simple Clean.
_MARKS = re.compile(r"[ؐ-ًؚ-ٰٟۖ-ۭـ]")
_ALEF = str.maketrans({"أ": "ا", "إ": "ا", "آ": "ا", "ٱ": "ا"})


def _path() -> Path:
    return Path(settings.quran_db_path)


def available() -> bool:
    return _path().is_file()


def _db() -> sqlite3.Connection:
    con = sqlite3.connect(f"file:{_path()}?mode=ro", uri=True, check_same_thread=False)
    con.row_factory = sqlite3.Row
    return con


@lru_cache(maxsize=1)
def surahs() -> list[dict]:
    if not available():
        return []
    with _db() as con:
        return [dict(r) for r in con.execute(
            "SELECT id, name_ar, name_en, revelation, ayah_count, start_page FROM surah ORDER BY id")]


@lru_cache(maxsize=1)
def reciters() -> list[dict]:
    if not available():
        return []
    with _db() as con:
        return [dict(r) for r in con.execute("SELECT id, name_ar, name_en, folder_url, credit FROM reciter ORDER BY id")]


@lru_cache(maxsize=1)
def credits() -> dict[str, dict]:
    if not available():
        return {}
    with _db() as con:
        return {r["key"]: {"line": r["line"], "url": r["url"]} for r in con.execute("SELECT key, line, url FROM credit")}


@lru_cache(maxsize=128)
def surah(number: int) -> dict | None:
    meta = next((s for s in surahs() if s["id"] == number), None)
    if meta is None:
        return None
    with _db() as con:
        rows = con.execute(
            "SELECT number, text, page, juz FROM ayah WHERE surah = ? ORDER BY number", (number,)
        ).fetchall()
    ayahs = [{"n": r["number"], "t": r["text"], "p": r["page"], "j": r["juz"]} for r in rows]
    return {**meta, "basmala": basmala() if number not in (1, 9) else None, "ayahs": ayahs}


@lru_cache(maxsize=1)
def basmala() -> str:
    """The basmala line shown above a surah: the source's own text of 1:1,
    without its verse-number mark (the last character). Never typed here."""
    with _db() as con:
        text = con.execute("SELECT text FROM ayah WHERE surah = 1 AND number = 1").fetchone()["text"]
    return text[:-1].rstrip()


@lru_cache(maxsize=2048)
def tafsir(surah_no: int, ayah_no: int) -> str | None:
    if not available():
        return None
    with _db() as con:
        row = con.execute("SELECT text FROM tafsir WHERE surah = ? AND ayah = ?", (surah_no, ayah_no)).fetchone()
    return row["text"] if row else None


@lru_cache(maxsize=256)
def timing(reciter: int, surah_no: int) -> list[list[int]]:
    if not available():
        return []
    with _db() as con:
        return [[r["ayah"], r["start_ms"], r["end_ms"]] for r in con.execute(
            "SELECT ayah, start_ms, end_ms FROM timing WHERE reciter = ? AND surah = ? ORDER BY ayah",
            (reciter, surah_no))]


def audio_url(reciter: dict, surah_no: int) -> str:
    folder = reciter["folder_url"]
    return folder.replace("{surah}", str(surah_no)) if "{surah}" in folder else f"{folder}{surah_no:03d}.mp3"


def normalize(query: str) -> str:
    return " ".join(_MARKS.sub("", query).translate(_ALEF).split())


def search(query: str, limit: int = 20) -> list[dict]:
    q = normalize(query)
    if len(q) < 2 or not available():
        return []
    like = "%" + q.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%"
    with _db() as con:
        rows = con.execute(
            "SELECT a.surah, a.number, a.text, s.name_ar, s.name_en FROM ayah a JOIN surah s ON s.id = a.surah "
            "WHERE replace(replace(replace(replace(a.text_search,'أ','ا'),'إ','ا'),'آ','ا'),'ٱ','ا') LIKE ? ESCAPE '\\' "
            "ORDER BY a.surah, a.number LIMIT ?", (like, limit)).fetchall()
    return [{"s": r["surah"], "n": r["number"], "t": r["text"],
             "name_ar": r["name_ar"], "name_en": r["name_en"]} for r in rows]
