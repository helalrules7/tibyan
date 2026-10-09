"""Admin training pages: freeze the evaluation set, start a job, follow it
live, and approve & publish (or reject / cancel / retry / roll back)."""
from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, Form, Request
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from starlette.responses import RedirectResponse

from .. import training
from ..config import settings
from ..deps import current_user, get_db
from ..models import EvalSetItem, Recording, TrainingJob, TrainingJobLog
from ..push import utcnow
from ..web import check_csrf, msg, render
from .admin import require_admin

router = APIRouter()
logger = logging.getLogger(__name__)
LOG_LINES = 300


def _flash(request: Request, key: str, extra: str = "") -> None:
    request.session["flash"] = msg(request, key) + (f" ({extra})" if extra else "")


@router.get("/admin/training")
def training_page(request: Request, db: Session = Depends(get_db)):
    blocked = require_admin(request, db)
    if blocked is not None:
        return blocked
    eval_set = training.active_eval_set(db)
    eval_recs = []
    if eval_set is not None:
        ids = training.eval_ids(db, eval_set.id)
        eval_recs = (
            db.query(Recording)
            .filter(Recording.id.in_(ids or {0}), Recording.status == "accepted")
            .all()
        )
    candidates = training.training_candidates(db, eval_set.id if eval_set else None)
    jobs = db.query(TrainingJob).order_by(TrainingJob.id.desc()).limit(50).all()
    bases = [j for j in jobs if j.status in ("published", "rolled_back")]
    flash = request.session.pop("flash", None)
    error = request.session.pop("flash_error", None)
    return render(
        request,
        "admin_training.html",
        admin_section="training",
        eval_set=eval_set,
        eval_summary=training.group_summary(eval_recs),
        eval_count=len(eval_recs),
        eval_items=(
            db.query(EvalSetItem).filter(EvalSetItem.eval_set_id == eval_set.id).count()
            if eval_set else 0
        ),
        train_summary=training.group_summary(candidates),
        train_count=len(candidates),
        accepted_total=db.query(Recording).filter(Recording.status == "accepted").count(),
        jobs=jobs,
        bases=bases,
        defaults=training.DEFAULT_PARAMS,
        runner_ready=bool(settings.runner_token),
        manifest=training.read_manifest(),
        min_eval=settings.eval_min_recordings,
        eval_fraction=int(settings.eval_fraction * 100),
        flash=flash,
        flash_error=error,
    )


@router.post("/admin/training/eval-set")
def freeze_eval(request: Request, db: Session = Depends(get_db), csrf: str = Form("")):
    blocked = require_admin(request, db)
    if blocked is not None:
        return blocked
    check_csrf(request, csrf)
    if training.active_eval_set(db) is not None:
        request.session["flash_error"] = msg(request, "train_eval_exists")
        return RedirectResponse("/admin/training", status_code=303)
    try:
        training.freeze_eval_set(db, current_user(request, db).id)
        _flash(request, "train_eval_frozen")
    except ValueError:
        request.session["flash_error"] = msg(request, "train_eval_too_few")
    return RedirectResponse("/admin/training", status_code=303)


@router.post("/admin/training/jobs")
def start_job(
    request: Request,
    db: Session = Depends(get_db),
    csrf: str = Form(""),
    base_model: str = Form("nvidia-base"),
    epochs: str = Form(""),
    learning_rate: str = Form(""),
    batch_size: str = Form(""),
    max_duration_s: str = Form(""),
    freeze_encoder: str = Form(""),
    seed: str = Form(""),
    note: str = Form(""),
):
    blocked = require_admin(request, db)
    if blocked is not None:
        return blocked
    check_csrf(request, csrf)
    params = {
        "epochs": epochs, "learning_rate": learning_rate, "batch_size": batch_size,
        "max_duration_s": max_duration_s, "freeze_encoder": freeze_encoder or "0", "seed": seed,
    }
    try:
        job = training.create_job(db, current_user(request, db).id, base_model, params, note)
    except ValueError as exc:
        request.session["flash_error"] = msg(request, f"train_err_{exc}") if str(exc) in (
            "no_eval_set", "no_data", "base_model"
        ) else msg(request, "train_err_params") + f" ({exc})"
        return RedirectResponse("/admin/training", status_code=303)
    return RedirectResponse(f"/admin/training/{job.id}", status_code=303)


def _comparison(metrics: dict | None) -> list[dict]:
    """Rows of current-vs-candidate WER/CER per voice group."""
    if not metrics:
        return []
    cur = (metrics.get("current") or {}).get("groups", {})
    new = (metrics.get("candidate") or {}).get("groups", {})
    rows = []
    for group in ("all", *training.VOICE_GROUPS):
        c, n = cur.get(group), new.get(group)
        if not c and not n:
            continue
        row = {"group": group, "n": (n or c or {}).get("n", 0)}
        for k in ("wer", "cer"):
            cv = (c or {}).get(k)
            nv = (n or {}).get(k)
            row[f"cur_{k}"] = cv
            row[f"new_{k}"] = nv
            row[f"delta_{k}"] = None if cv is None or nv is None else round(nv - cv, 2)
        rows.append(row)
    return rows


@router.get("/admin/training/{job_id}")
def job_page(job_id: int, request: Request, db: Session = Depends(get_db)):
    blocked = require_admin(request, db)
    if blocked is not None:
        return blocked
    job = db.get(TrainingJob, job_id)
    if job is None:
        return RedirectResponse("/admin/training", status_code=303)
    logs = _logs(db, job.id)
    metrics = training.job_metrics(job)
    manifest = training.read_manifest() or {}
    flash = request.session.pop("flash", None)
    error = request.session.pop("flash_error", None)
    return render(
        request,
        "admin_training_job.html",
        admin_section="training",
        job=job,
        params=training.job_params(job),
        logs=logs,
        metrics=metrics,
        comparison=_comparison(metrics),
        files=training.job_files(job),
        serving_version=str(manifest.get("version")) if manifest else None,
        flash=flash,
        flash_error=error,
    )


def _logs(db: Session, job_id: int, after: int = 0) -> list[TrainingJobLog]:
    query = db.query(TrainingJobLog).filter(TrainingJobLog.job_id == job_id)
    if after:
        return query.filter(TrainingJobLog.id > after).order_by(TrainingJobLog.id).limit(LOG_LINES).all()
    rows = query.order_by(TrainingJobLog.id.desc()).limit(LOG_LINES).all()
    return list(reversed(rows))


@router.get("/admin/training/{job_id}/status.json")
def job_status(job_id: int, request: Request, db: Session = Depends(get_db), after: int = 0):
    user = current_user(request, db)
    if user is None or not user.is_admin:
        return JSONResponse({"error": "forbidden"}, status_code=403)
    job = db.get(TrainingJob, job_id)
    if job is None:
        return JSONResponse({"error": "not_found"}, status_code=404)
    heartbeat_age = (
        int((utcnow() - job.heartbeat_at).total_seconds()) if job.heartbeat_at else None
    )
    return JSONResponse(
        {
            "status": job.status,
            "status_label": msg(request, f"job_{job.status}"),
            "progress": round(job.progress or 0, 4),
            "stage": job.stage,
            "heartbeat_age": heartbeat_age,
            "logs": [{"id": l.id, "line": l.line} for l in _logs(db, job.id, after)],
        },
        headers={"Cache-Control": "no-store"},
    )


@router.post("/admin/training/{job_id}/action")
def job_action(
    job_id: int, request: Request, db: Session = Depends(get_db),
    action: str = Form(""), csrf: str = Form(""), confirm: str = Form(""),
):
    blocked = require_admin(request, db)
    if blocked is not None:
        return blocked
    check_csrf(request, csrf)
    job = db.get(TrainingJob, job_id)
    if job is None:
        return RedirectResponse("/admin/training", status_code=303)
    admin_user = current_user(request, db)
    back = RedirectResponse(f"/admin/training/{job.id}", status_code=303)
    try:
        if action == "publish":
            if confirm != "yes":
                request.session["flash_error"] = msg(request, "job_confirm_needed")
                return back
            version = training.publish_job(job)
            job.decided_by = admin_user.id
            db.add(TrainingJobLog(job_id=job.id, line=f"approved and published as version {version} by admin {admin_user.id}"))
            db.commit()
            _flash(request, "job_published", version)
        elif action == "reject":
            training.transition(job, "rejected")
            job.decided_by = admin_user.id
            job.decided_at = utcnow()
            training.discard_uploads(job)
            db.add(TrainingJobLog(job_id=job.id, line=f"rejected by admin {admin_user.id}; uploads discarded"))
            db.commit()
            _flash(request, "job_rejected_msg")
        elif action == "cancel":
            training.transition(job, "cancelled")
            job.finished_at = utcnow()
            db.add(TrainingJobLog(job_id=job.id, line=f"cancelled by admin {admin_user.id}"))
            db.commit()
            _flash(request, "job_cancelled_msg")
        elif action == "retry":
            training.transition(job, "queued")
            job.error = None
            job.progress = 0.0
            job.stage = None
            job.runner = None
            db.add(TrainingJobLog(job_id=job.id, line=f"re-queued by admin {admin_user.id}"))
            db.commit()
            _flash(request, "job_requeued")
        elif action == "rollback":
            if confirm != "yes":
                request.session["flash_error"] = msg(request, "job_confirm_needed")
                return back
            version = training.rollback_job(job)
            job.decided_by = admin_user.id
            db.add(TrainingJobLog(job_id=job.id, line=f"rolled back to version {version} by admin {admin_user.id}"))
            db.commit()
            _flash(request, "job_rolled_back_msg", version)
        else:
            request.session["flash_error"] = msg(request, "job_bad_action")
    except training.InvalidTransition as exc:
        db.rollback()
        request.session["flash_error"] = msg(request, "job_bad_action") + f" ({exc})"
    except RuntimeError as exc:
        db.rollback()
        logger.exception("Training action %s failed for job %s.", action, job_id)
        request.session["flash_error"] = msg(request, "job_action_failed") + f" ({exc})"
    return back
