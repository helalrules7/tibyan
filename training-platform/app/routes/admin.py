from __future__ import annotations

from pathlib import Path

from fastapi import APIRouter, Depends, Form, HTTPException, Query, Request
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from starlette.responses import RedirectResponse

from ..config import settings
from ..deps import current_user, get_db
from ..export import build_export
from ..models import ContactMessage, Recording, RecordingVote
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


def _export_root() -> Path:
    return Path(settings.media_dir).resolve() / "export"


@router.get("/admin")
def admin_dashboard(
    request: Request,
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
):
    blocked = require_admin(request, db)
    if blocked is not None:
        return blocked

    counts = {
        status: db.query(Recording)
        .filter(Recording.status == status)
        .count()
        for status in ("pending", "accepted", "rejected", "flagged")
    }
    total_recordings = db.query(Recording).count()
    total_pages = max(
        1, (total_recordings + RECORDINGS_PER_PAGE - 1) // RECORDINGS_PER_PAGE
    )
    page = min(page, total_pages)
    recordings = (
        db.query(Recording)
        .order_by(Recording.id.desc())
        .offset((page - 1) * RECORDINGS_PER_PAGE)
        .limit(RECORDINGS_PER_PAGE)
        .all()
    )
    messages = (
        db.query(ContactMessage)
        .order_by(ContactMessage.id.desc())
        .limit(20)
        .all()
    )
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
        messages=messages,
        exported=exported,
        flash=flash,
    )


@router.post("/admin/recordings/{recording_id}/decision")
def decide_recording(
    recording_id: int,
    request: Request,
    db: Session = Depends(get_db),
    verdict: str = Form(""),
    csrf: str = Form(""),
    page: int = Form(1),
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

    rec.status = "accepted" if verdict == "accept" else "rejected"
    db.commit()
    request.session["flash"] = msg(request, "admin_decision_saved")
    return RedirectResponse(
        f"/admin?page={max(page, 1)}",
        status_code=303,
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
