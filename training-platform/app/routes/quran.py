"""JSON for the live reader on altibyan.app (read-only, cacheable)."""
from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import JSONResponse

from .. import quran_site

router = APIRouter(prefix="/api/quran")
CACHE = {"Cache-Control": "public, max-age=86400"}


def _need_db() -> None:
    if not quran_site.available():
        raise HTTPException(status_code=503, detail="reader data is not installed")


@router.get("/surah/{number}")
def surah(number: int):
    _need_db()
    data = quran_site.surah(number)
    if data is None:
        raise HTTPException(status_code=404, detail="no such surah")
    return JSONResponse(data, headers=CACHE)


@router.get("/tafsir/{surah_no}/{ayah_no}")
def tafsir(surah_no: int, ayah_no: int):
    _need_db()
    text = quran_site.tafsir(surah_no, ayah_no)
    if text is None:
        raise HTTPException(status_code=404, detail="no such verse")
    return JSONResponse({"text": text}, headers=CACHE)


@router.get("/timing/{reciter}/{surah_no}")
def timing(reciter: int, surah_no: int):
    _need_db()
    who = next((r for r in quran_site.reciters() if r["id"] == reciter), None)
    if who is None or not 1 <= surah_no <= 114:
        raise HTTPException(status_code=404, detail="no such recitation")
    return JSONResponse(
        {"url": quran_site.audio_url(who, surah_no), "ayahs": quran_site.timing(reciter, surah_no)}, headers=CACHE)


@router.get("/search")
def search(q: str = Query("", max_length=80)):
    _need_db()
    return JSONResponse({"q": quran_site.normalize(q), "results": quran_site.search(q)},
                        headers={"Cache-Control": "public, max-age=3600"})
