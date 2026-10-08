from __future__ import annotations

import random
from pathlib import Path

from fastapi import APIRouter, Depends, Form, Request
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from starlette.responses import RedirectResponse

from .. import verses
from ..config import settings
from ..deps import current_user, get_db
from ..models import ClipReport, Recording, RecordingVote
from ..web import check_csrf, msg, render

router = APIRouter()

ACCEPTS_TO_ADMIT = 2
REJECTS_TO_DROP = 2


def media_root() -> Path:
    return Path(settings.media_dir).resolve()


def _status_label(request: Request, status: str) -> str:
    return msg(request, f"status_{status}")


def _pick_for_review(db: Session, user_id: int) -> Recording | None:
    voted_ids = [
        row[0]
        for row in db.query(RecordingVote.recording_id)
        .filter(RecordingVote.user_id == user_id)
        .all()
    ]
    query = db.query(Recording).filter(
        Recording.status == "pending",
        Recording.user_id != user_id,
    )
    if voted_ids:
        query = query.filter(~Recording.id.in_(voted_ids))
    candidates = query.order_by(Recording.id.desc()).limit(50).all()
    if not candidates:
        return None
    return random.choice(candidates)


@router.get("/validate")
def validate_form(request: Request, db: Session = Depends(get_db)):
    user = current_user(request, db)
    if user is None:
        return RedirectResponse("/login", status_code=303)
    clip = _pick_for_review(db, user.id)
    if clip is None:
        return render(request, "validate.html", clip=None)
    flash = request.session.pop("flash", None)
    return render(
        request,
        "validate.html",
        clip=clip,
        text=verses.ayah_range_text(
            clip.surah, clip.ayah, clip.ayah_end or clip.ayah
        ) or "",
        surah_name=next(
            (s["name_ar"] for s in verses.surahs() if s["number"] == clip.surah),
            "",
        ),
        flash=flash,
    )


@router.get("/recordings/{recording_id}/audio")
def recording_audio(recording_id: int, request: Request, db: Session = Depends(get_db)):
    user = current_user(request, db)
    if user is None:
        return RedirectResponse("/login", status_code=303)
    rec = db.get(Recording, recording_id)
    if rec is None:
        return RedirectResponse("/validate", status_code=303)
    path = media_root() / rec.audio_path
    if not path.is_file():
        return RedirectResponse("/validate", status_code=303)
    return FileResponse(path, media_type="audio/wav")


@router.post("/validate/{recording_id}")
def submit_vote(
    recording_id: int,
    request: Request,
    db: Session = Depends(get_db),
    verdict: str = Form(""),
    csrf: str = Form(""),
):
    user = current_user(request, db)
    if user is None:
        return RedirectResponse("/login", status_code=303)
    check_csrf(request, csrf)

    if verdict not in ("accept", "reject"):
        return RedirectResponse("/validate", status_code=303)

    rec = db.get(Recording, recording_id)
    if (
        rec is None
        or rec.status != "pending"
        or rec.user_id == user.id
    ):
        return RedirectResponse("/validate", status_code=303)

    already = (
        db.query(RecordingVote)
        .filter(
            RecordingVote.recording_id == recording_id,
            RecordingVote.user_id == user.id,
        )
        .first()
    )
    if already is not None:
        return RedirectResponse("/validate", status_code=303)

    db.add(
        RecordingVote(
            recording_id=recording_id,
            user_id=user.id,
            verdict=verdict,
        )
    )
    db.flush()

    accepts = (
        db.query(RecordingVote)
        .filter(
            RecordingVote.recording_id == recording_id,
            RecordingVote.verdict == "accept",
        )
        .count()
    )
    rejects = (
        db.query(RecordingVote)
        .filter(
            RecordingVote.recording_id == recording_id,
            RecordingVote.verdict == "reject",
        )
        .count()
    )
    if accepts >= ACCEPTS_TO_ADMIT:
        rec.status = "accepted"
    elif rejects >= REJECTS_TO_DROP:
        rec.status = "rejected"
    db.commit()

    request.session["flash"] = msg(request, "validate_thanks")
    return RedirectResponse("/validate", status_code=303)


@router.post("/validate/{recording_id}/report")
def submit_report(
    recording_id: int,
    request: Request,
    db: Session = Depends(get_db),
    reason: str = Form(""),
    csrf: str = Form(""),
):
    user = current_user(request, db)
    if user is None:
        return RedirectResponse("/login", status_code=303)
    check_csrf(request, csrf)

    rec = db.get(Recording, recording_id)
    if rec is None or rec.user_id == user.id:
        return RedirectResponse("/validate", status_code=303)

    db.add(
        ClipReport(
            recording_id=recording_id,
            user_id=user.id,
            reason=reason.strip()[:500] or None,
        )
    )
    if rec.status == "pending":
        rec.status = "flagged"
    db.commit()

    request.session["flash"] = msg(request, "validate_report_sent")
    return RedirectResponse("/validate", status_code=303)
