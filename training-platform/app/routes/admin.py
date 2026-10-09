from __future__ import annotations

from pathlib import Path

from fastapi import APIRouter, Depends, Form, HTTPException, Query, Request
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from starlette.responses import RedirectResponse

from ..config import settings
from ..deps import current_user, get_db
from ..export import build_export
from sqlalchemy import func

from .. import training
from ..models import (
    ContactMessage,
    DeletionRequest,
    NotifySignup,
    Recording,
    RecordingVote,
    TrainingJob,
    User,
)
from ..notifications import notify_users
from ..web import check_csrf, msg, render

router = APIRouter()
RECORDINGS_PER_PAGE = 50


def require_admin(request: Request, db: Session):
    user = current_user(request, db)
    if user is None:
        return RedirectResponse("/login", status_code=303)
    if not user.is_admin:
        return RedirectResponse("/dashboard", status_code=303)
    return None


def dashboard_stats(db: Session) -> dict:
    """Counts for the admin dashboard."""
    minutes = {g: 0.0 for g in training.VOICE_GROUPS}
    clips = {g: 0 for g in training.VOICE_GROUPS}
    for rec in db.query(Recording).filter(Recording.status == "accepted").all():
        g = training.voice_group(rec)
        minutes[g] += (rec.audio_duration_ms or 0) / 60000
        clips[g] += 1
    contributors = db.query(func.count(func.distinct(Recording.user_id))).scalar() or 0
    latest_job = db.query(TrainingJob).order_by(TrainingJob.id.desc()).first()
    manifest = training.read_manifest()
    return {
        "awaiting_review": db.query(Recording)
        .filter(Recording.status.in_(("pending", "flagged")))
        .count(),
        "accepted_minutes": {g: round(m, 1) for g, m in minutes.items()},
        "accepted_clips": clips,
        "accepted_total_minutes": round(sum(minutes.values()), 1),
        "volunteers": db.query(User).count(),
        "contributors": int(contributors),
        "unread_messages": db.query(ContactMessage)
        .filter(ContactMessage.read_at.is_(None))
        .count(),
        "beta_waiting": db.query(NotifySignup)
        .filter(
            NotifySignup.wants_beta.is_(True),
            NotifySignup.play_added_at.is_(None),
            NotifySignup.testflight_added_at.is_(None),
        )
        .count(),
        "notify_total": db.query(NotifySignup).count(),
        "open_deletions": db.query(DeletionRequest)
        .filter(DeletionRequest.status == "open")
        .count(),
        "latest_job": latest_job,
        "model_version": (manifest or {}).get("version"),
    }


def _export_root() -> Path:
    return Path(settings.media_dir).resolve() / "export"


@router.get("/admin")
def admin_dashboard(
    request: Request,
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    status: str = Query(""),
):
    blocked = require_admin(request, db)
    if blocked is not None:
        return blocked
    if status not in ("", "pending", "accepted", "rejected", "flagged"):
        status = ""

    counts = {
        status: db.query(Recording)
        .filter(Recording.status == status)
        .count()
        for status in ("pending", "accepted", "rejected", "flagged")
    }
    query = db.query(Recording)
    if status:
        query = query.filter(Recording.status == status)
    total_recordings = query.count()
    total_pages = max(
        1, (total_recordings + RECORDINGS_PER_PAGE - 1) // RECORDINGS_PER_PAGE
    )
    page = min(page, total_pages)
    recordings = (
        query
        .order_by(Recording.id.desc())
        .offset((page - 1) * RECORDINGS_PER_PAGE)
        .limit(RECORDINGS_PER_PAGE)
        .all()
    )
    owners = {
        u.id: u
        for u in db.query(User)
        .filter(User.id.in_({r.user_id for r in recordings} or {0}))
        .all()
    }
    votes = {}
    if recordings:
        for rid, verdict, n in (
            db.query(RecordingVote.recording_id, RecordingVote.verdict, func.count())
            .filter(RecordingVote.recording_id.in_([r.id for r in recordings]))
            .group_by(RecordingVote.recording_id, RecordingVote.verdict)
            .all()
        ):
            votes.setdefault(rid, {})[verdict] = n
    manifest = _export_root() / "manifest.jsonl"
    exported = (
        sum(1 for _ in manifest.open(encoding="utf-8"))
        if manifest.is_file()
        else 0
    )
    flash = request.session.pop("flash", None)
    return render(
        request,
        "admin.html",
        counts=counts,
        recordings=recordings,
        total_recordings=total_recordings,
        page=page,
        total_pages=total_pages,
        status_filter=status,
        owners=owners,
        votes=votes,
        group_of=training.voice_group,
        stats=dashboard_stats(db),
        exported=exported,
        flash=flash,
        admin_section="dashboard",
    )


@router.post("/admin/recordings/{recording_id}/decision")
def decide_recording(
    recording_id: int,
    request: Request,
    db: Session = Depends(get_db),
    verdict: str = Form(""),
    csrf: str = Form(""),
    page: int = Form(1),
    status_filter: str = Form(""),
):
    blocked = require_admin(request, db)
    if blocked is not None:
        return blocked
    check_csrf(request, csrf)

    if verdict not in ("accept", "reject"):
        raise HTTPException(status_code=400, detail="Invalid admin decision.")

    admin_user = current_user(request, db)
    rec = db.get(Recording, recording_id)
    if admin_user is None:
        return RedirectResponse("/login", status_code=303)
    if rec is None:
        raise HTTPException(status_code=404, detail="Recording not found.")
    if rec.status not in ("pending", "accepted", "rejected", "flagged"):
        raise HTTPException(status_code=409, detail="Unsupported recording status.")

    vote = (
        db.query(RecordingVote)
        .filter(
            RecordingVote.recording_id == recording_id,
            RecordingVote.user_id == admin_user.id,
        )
        .first()
    )
    if vote is None:
        vote = RecordingVote(
            recording_id=recording_id,
            user_id=admin_user.id,
            verdict=verdict,
        )
        db.add(vote)
    else:
        vote.verdict = verdict

    old_status = rec.status
    rec.status = "accepted" if verdict == "accept" else "rejected"
    db.commit()
    if rec.status != old_status:
        notify_owner_of_decision(db, rec)
    request.session["flash"] = msg(request, "admin_decision_saved")
    suffix = f"&status={status_filter}" if status_filter in ("pending", "accepted", "rejected", "flagged") else ""
    return RedirectResponse(
        f"/admin?page={max(page, 1)}{suffix}",
        status_code=303,
    )


def notify_owner_of_decision(db: Session, rec: Recording) -> None:
    """Tell the volunteer their recording was accepted or rejected."""
    if rec.status not in ("accepted", "rejected"):
        return
    ref = f"{rec.surah}:{rec.ayah}" + (
        f"-{rec.ayah_end}" if rec.ayah_end and rec.ayah_end > rec.ayah else ""
    )
    notify_users(
        db,
        [rec.user_id],
        "recording_accepted" if rec.status == "accepted" else "recording_rejected",
        {"ref": ref},
        "/dashboard",
    )


@router.post("/admin/flagged/{recording_id}/restore")
def restore_flagged(
    recording_id: int,
    request: Request,
    db: Session = Depends(get_db),
    csrf: str = Form(""),
    page: int = Form(1),
):
    blocked = require_admin(request, db)
    if blocked is not None:
        return blocked
    check_csrf(request, csrf)

    rec = db.get(Recording, recording_id)
    if rec is not None and rec.status == "flagged":
        rec.status = "pending"
        db.commit()
    return RedirectResponse(f"/admin?page={max(page, 1)}", status_code=303)


@router.post("/admin/flagged/{recording_id}/reject")
def reject_flagged(
    recording_id: int,
    request: Request,
    db: Session = Depends(get_db),
    csrf: str = Form(""),
):
    blocked = require_admin(request, db)
    if blocked is not None:
        return blocked
    check_csrf(request, csrf)

    rec = db.get(Recording, recording_id)
    if rec is not None and rec.status == "flagged":
        rec.status = "rejected"
        db.commit()
        notify_owner_of_decision(db, rec)
    return RedirectResponse("/admin", status_code=303)


@router.post("/admin/export")
def export_accepted(
    request: Request,
    db: Session = Depends(get_db),
    csrf: str = Form(""),
):
    blocked = require_admin(request, db)
    if blocked is not None:
        return blocked
    check_csrf(request, csrf)

    result = build_export(db)
    request.session["flash"] = (
        msg(request, "admin_export_done").replace("{n}", str(result["count"]))
        if result["count"]
        else msg(request, "admin_export_none")
    )
    return RedirectResponse("/admin", status_code=303)


@router.get("/admin/manifest.jsonl")
def download_manifest(request: Request, db: Session = Depends(get_db)):
    blocked = require_admin(request, db)
    if blocked is not None:
        return blocked
    manifest = _export_root() / "manifest.jsonl"
    if not manifest.is_file():
        return RedirectResponse("/admin", status_code=303)
    return FileResponse(manifest, media_type="application/x-ndjson", filename="manifest.jsonl")
