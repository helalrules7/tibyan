from __future__ import annotations

import json
from functools import lru_cache
from pathlib import Path

from .config import settings


@lru_cache(maxsize=1)
def verses_data() -> dict:
    path = Path(settings.verses_path)
    if not path.is_file():
        return {"surahs": [], "ayahs": []}
    return json.loads(path.read_text(encoding="utf-8"))


def surahs() -> list[dict]:
    return verses_data()["surahs"]


def ayahs_of(surah: int) -> list[dict]:
    return [a for a in verses_data()["ayahs"] if a["surah"] == surah]


def ayah_text(surah: int, number: int) -> str | None:
    return ayah_range_text(surah, number, number)


def ayah_range_is_valid(surah: int, start: int, end: int) -> bool:
    if start < 1 or end < start:
        return False
    numbers = {ayah["number"] for ayah in ayahs_of(surah)}
    return all(number in numbers for number in range(start, end + 1))


def ayah_range_text(surah: int, start: int, end: int) -> str | None:
    if not ayah_range_is_valid(surah, start, end):
        return None
    rows = {ayah["number"]: ayah["text"] for ayah in ayahs_of(surah)}
    return " ".join(rows[number] for number in range(start, end + 1))


def verses_available() -> bool:
    return bool(verses_data()["surahs"])
