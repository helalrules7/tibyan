from __future__ import annotations

import shutil
from pathlib import Path

from fastapi import APIRouter, Depends, File, Form, Request, UploadFile
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from starlette.responses import RedirectResponse

from .. import verses
from ..audio import convert_to_wav, validate_clip
from ..config import settings
from ..deps import current_user, get_db
from ..models import ClipReport, Recording, RecordingVote
from ..web import check_csrf, msg, render

router = APIRouter()

_AUDIO_EXT = {".wav", ".mp3", ".m4a", ".aac", ".ogg", ".webm", ".opus", ".flac"}


def media_root() -> Path:
    root = Path(settings.media_dir).resolve()
    (root / "tmp").mkdir(parents=True, exist_ok=True)
    (root / "recordings").mkdir(parents=True, exist_ok=True)
    return root


@router.get("/record")
def record_form(request: Request, db: Session = Depends(get_db)):
    if current_user(request, db) is None:
        return RedirectResponse("/login", status_code=303)
    flash = request.session.pop("flash", None)
    flash_error = request.session.pop("flash_error", None)
    return render(
        request,
        "record.html",
        flash=flash,
        flash_error=flash_error,
        verses_available=verses.verses_available(),
    )


@router.get("/api/surahs")
def api_surahs():
    return JSONResponse(
        [
            {"number": s["number"], "name_ar": s["name_ar"], "name_en": s["name_en"], "ayah_count": s["ayah_count"]}
            for s in verses.surahs()
        ]
    )


@router.get("/api/surah/{number}")
def api_surah(number: int):
    rows = verses.ayahs_of(number)
    surah = next((s for s in verses.surahs() if s["number"] == number), None)
    if surah is None:
        return JSONResponse({"error": "not_found"}, status_code=404)
    return JSONResponse(
        {
            "number": surah["number"],
            "name_ar": surah["name_ar"],
            "name_en": surah["name_en"],
            "ayahs": [{"number": a["number"], "text": a["text"]} for a in rows],
        }
    )


@router.post("/record")
def record_submit(
    request: Request,
    db: Session = Depends(get_db),
    surah: str = Form(""),
    ayah: str = Form(""),
    ayah_end: str = Form(""),
    gender: str = Form(""),
    age_bracket: str = Form(""),
    dialect: str = Form(""),
    native_language: str = Form(""),
    environment: str = Form(""),
    speed: str = Form(""),
    csrf: str = Form(""),
    audio: UploadFile = File(...),
):
    user = current_user(request, db)
    if user is None:
        return RedirectResponse("/login", status_code=303)
    check_csrf(request, csrf)

    def fail(message: str):
        request.session["flash_error"] = message
        return RedirectResponse("/record", status_code=303)

    if (
        not surah.isdigit()
        or not ayah.isdigit()
        or (ayah_end and not ayah_end.isdigit())
    ):
        return fail(msg(request, "err_pick_ayah"))

    surah_number = int(surah)
    ayah_start = int(ayah)
    ayah_end_number = int(ayah_end) if ayah_end else ayah_start
    if not verses.ayah_range_is_valid(surah_number, ayah_start, ayah_end_number):
        return fail(msg(request, "err_pick_ayah"))

    filename = audio.filename or "recording"
    ext = Path(filename).suffix.lower()
    if ext not in _AUDIO_EXT and audio.content_type not in {"audio/webm", "audio/ogg", "audio/mpeg", "audio/wav", "audio/mp4", "audio/x-m4a"}:
        return fail(msg(request, "err_audio_process") + " " + msg(request, "err_audio_missing"))

    root = media_root()
    tmp = root / "tmp" / f"{user.id}_{Path(filename).stem[:40]}{ext or '.bin'}"
    size = 0
    with tmp.open("wb") as out:
        while chunk := audio.file.read(1024 * 1024):
            size += len(chunk)
            if size > settings.max_upload_bytes:
                tmp.unlink(missing_ok=True)
                audio.file.close()
                return fail(msg(request, "err_audio_process"))
            out.write(chunk)
    audio.file.close()

    if size == 0:
        tmp.unlink(missing_ok=True)
        return fail(msg(request, "err_audio_missing"))

    rec = Recording(
        user_id=user.id,
        surah=surah_number,
        ayah=ayah_start,
        ayah_end=ayah_end_number,
        audio_path="",
        audio_duration_ms=0,
        audio_format="wav",
        gender=gender or None,
        age_bracket=age_bracket or None,
        dialect=(dialect.strip()[:64] or None),
        native_language=native_language or None,
        environment=environment or None,
        speed=speed or None,
        status="pending",
    )
    db.add(rec)
    db.commit()
    db.refresh(rec)

    final = root / "recordings" / f"{rec.id}.wav"
    try:
        convert_to_wav(tmp, final)
        duration_ms = validate_clip(final)
    except ValueError as exc:
        tmp.unlink(missing_ok=True)
        final.unlink(missing_ok=True)
        db.delete(rec)
        db.commit()
        key = str(exc)
        return fail(msg(request, "err_audio_process") + " " + msg(request, key if key.startswith("clip_") else "err_audio_process"))

    tmp.unlink(missing_ok=True)
    rec.audio_path = f"recordings/{rec.id}.wav"
    rec.audio_duration_ms = duration_ms
    db.commit()

    request.session["flash"] = msg(request, "success_recorded")
    return RedirectResponse("/record", status_code=303)


@router.post("/recordings/{recording_id}/delete")
def delete_recording(
    recording_id: int,
    request: Request,
    db: Session = Depends(get_db),
    csrf: str = Form(""),
):
    user = current_user(request, db)
    if user is None:
        return RedirectResponse("/login", status_code=303)
    check_csrf(request, csrf)

    rec = db.get(Recording, recording_id)
    if rec is None or rec.user_id != user.id:
        return RedirectResponse("/dashboard", status_code=303)

    db.query(RecordingVote).filter(
        RecordingVote.recording_id == recording_id
    ).delete()
    db.query(ClipReport).filter(
        ClipReport.recording_id == recording_id
    ).delete()
    path = media_root() / rec.audio_path
    db.delete(rec)
    db.commit()

    path.unlink(missing_ok=True)
    # Also drop any copy left in the training export from an earlier run.
    (media_root() / "export" / "wavs" / f"{recording_id}.wav").unlink(missing_ok=True)

    request.session["flash"] = msg(request, "rec_deleted")
    return RedirectResponse("/dashboard", status_code=303)
