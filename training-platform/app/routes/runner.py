"""Authenticated API for the training runner (Ahmed's Mac).

Every endpoint needs `Authorization: Bearer <RUNNER_TOKEN>`. Audio is only
served for recordings in the job's frozen snapshot or evaluation set, only
while that job is running, and only if the recording is still accepted.
"""
from __future__ import annotations

import json
import re
import secrets
from datetime import timedelta
from pathlib import Path

from fastapi import APIRouter, Depends, Request
from fastapi.responses import FileResponse, JSONResponse
from sqlalchemy.orm import Session

from .. import training
from ..config import settings
from ..deps import get_db
from ..models import Recording, TrainingJob, TrainingJobLog
from ..notifications import notify_admins
from ..push import utcnow

router = APIRouter(prefix="/api/runner")

_NAME_RE = re.compile(r"^[A-Za-z0-9._-]{1,64}$")
MAX_LOG_LINES = 200
MAX_LOG_CHARS = 2000


def require_runner(request: Request) -> str:
    token = settings.runner_token
    if not token:
        raise _http(503, "runner_api_disabled")
    header = request.headers.get("authorization", "")
    sent = header[7:] if header.lower().startswith("bearer ") else ""
    if not sent or not secrets.compare_digest(sent.encode(), token.encode()):
        raise _http(401, "invalid_token")
    name = request.headers.get("x-runner-name", "runner")
    return name if _NAME_RE.match(name) else "runner"


def _http(status: int, error: str):
    from fastapi import HTTPException

    return HTTPException(status_code=status, detail=error)


def _job_or_404(db: Session, job_id: int) -> TrainingJob:
    job = db.get(TrainingJob, job_id)
    if job is None:
        raise _http(404, "job_not_found")
    return job


def _running(job: TrainingJob, runner: str) -> None:
    if job.status != "running":
        raise _http(409, f"job_is_{job.status}")
    if job.runner and job.runner != runner:
        raise _http(409, "claimed_by_another_runner")


def _payload(job: TrainingJob) -> dict:
    base = {"kind": "nvidia-base", "url": settings.base_model_url,
            "sha256": settings.base_model_sha256}
    if job.base_model.startswith("job:"):
        base = {"kind": "job", "job_id": int(job.base_model[4:])}
    current = training.current_model_info()
    return {
        "id": job.id,
        "status": job.status,
        "model_name": settings.model_name,
        "base_model": base,
        "params": training.job_params(job),
        "eval_set": job.eval_set_id,
        "train_count": job.train_count,
        "dataset_url": f"/api/runner/jobs/{job.id}/dataset",
        "current_model": current,
        "chunk_bytes": settings.runner_chunk_bytes,
        "required_files": list(training.REQUIRED_FILES),
    }


def _log(db: Session, job: TrainingJob, lines: list[str]) -> None:
    for line in lines[:MAX_LOG_LINES]:
        db.add(TrainingJobLog(job_id=job.id, line=str(line)[:MAX_LOG_CHARS]))


@router.get("/ping")
def ping(runner: str = Depends(require_runner)):
    return {"ok": True, "runner": runner}


@router.post("/claim")
def claim(runner: str = Depends(require_runner), db: Session = Depends(get_db)):
    """Resume this runner's running job, else take the oldest queued job,
    else take over a running job whose runner went silent."""
    job = (
        db.query(TrainingJob)
        .filter(TrainingJob.status == "running", TrainingJob.runner == runner)
        .order_by(TrainingJob.id)
        .first()
    )
    resumed = job is not None
    if job is None:
        job = (
            db.query(TrainingJob)
            .filter(TrainingJob.status == "queued")
            .order_by(TrainingJob.id)
            .first()
        )
    if job is None:
        cutoff = utcnow() - timedelta(seconds=settings.runner_stale_seconds)
        job = (
            db.query(TrainingJob)
            .filter(TrainingJob.status == "running", TrainingJob.heartbeat_at < cutoff)
            .order_by(TrainingJob.id)
            .first()
        )
        resumed = job is not None
    if job is None:
        return JSONResponse({"job": None})

    training.transition(job, "running")
    if not resumed or job.claimed_at is None:
        job.claimed_at = utcnow()
    if job.compared_version is None:
        current = training.current_model_info()
        job.compared_version = current["version"] if current else None
    job.runner = runner
    job.heartbeat_at = utcnow()
    job.stage = job.stage or "claimed"
    _log(db, job, [f"{'resumed' if resumed else 'claimed'} by {runner}"])
    db.commit()
    db.refresh(job)
    return {"job": _payload(job), "resumed": resumed}


@router.get("/jobs/{job_id}")
def job_info(job_id: int, runner: str = Depends(require_runner), db: Session = Depends(get_db)):
    return _payload(_job_or_404(db, job_id))


@router.post("/jobs/{job_id}/progress")
async def progress(
    job_id: int, request: Request, runner: str = Depends(require_runner),
    db: Session = Depends(get_db),
):
    job = _job_or_404(db, job_id)
    if job.status != "running":
        # Tell the runner to stop (cancelled by an admin, or taken over).
        return {"status": job.status, "stop": True}
    if job.runner and job.runner != runner:
        return {"status": "claimed_by_another_runner", "stop": True}
    try:
        body = await request.json()
    except ValueError:
        body = {}
    if "progress" in body:
        try:
            job.progress = max(0.0, min(1.0, float(body["progress"])))
        except (TypeError, ValueError):
            pass
    if body.get("stage"):
        job.stage = str(body["stage"])[:64]
    lines = body.get("logs") or []
    if isinstance(lines, list):
        _log(db, job, lines)
    job.heartbeat_at = utcnow()
    db.commit()
    return {"status": job.status, "stop": False}


@router.get("/jobs/{job_id}/dataset")
def dataset(job_id: int, runner: str = Depends(require_runner), db: Session = Depends(get_db)):
    job = _job_or_404(db, job_id)
    _running(job, runner)
    return training.dataset_entries(db, job)


@router.get("/jobs/{job_id}/audio/{recording_id}")
def audio(
    job_id: int, recording_id: int, runner: str = Depends(require_runner),
    db: Session = Depends(get_db),
):
    job = _job_or_404(db, job_id)
    _running(job, runner)
    if recording_id not in training.allowed_audio_ids(db, job):
        raise _http(403, "not_in_dataset")
    rec = db.get(Recording, recording_id)
    if rec is None or rec.status != "accepted" or not rec.audio_path:
        raise _http(410, "no_longer_available")
    path = Path(settings.media_dir).resolve() / rec.audio_path
    if not path.is_file():
        raise _http(410, "no_longer_available")
    return FileResponse(
        path,
        media_type="audio/wav",
        headers={"X-Sha256": training.sha256_file(path), "Cache-Control": "no-store"},
    )


def _upload_path(job: TrainingJob, name: str) -> Path:
    if name not in training.ALLOWED_FILES:
        raise _http(400, "file_not_allowed")
    folder = training.upload_dir(job.id)
    folder.mkdir(parents=True, exist_ok=True)
    return folder / name


@router.get("/jobs/{job_id}/files/{name}")
def file_size(job_id: int, name: str, runner: str = Depends(require_runner),
              db: Session = Depends(get_db)):
    job = _job_or_404(db, job_id)
    _running(job, runner)
    path = _upload_path(job, name)
    return {"name": name, "size": path.stat().st_size if path.is_file() else 0}


@router.put("/jobs/{job_id}/files/{name}")
async def upload_chunk(
    job_id: int, name: str, request: Request, offset: int = 0,
    runner: str = Depends(require_runner), db: Session = Depends(get_db),
):
    """Append one chunk at `offset`. A mismatched offset returns 409 with
    the stored size so an interrupted upload resumes where it stopped."""
    job = _job_or_404(db, job_id)
    _running(job, runner)
    path = _upload_path(job, name)
    size = path.stat().st_size if path.is_file() else 0
    if offset == 0 and size:
        path.unlink()
        size = 0
    if offset != size:
        return JSONResponse({"error": "offset_mismatch", "size": size}, status_code=409)
    written = 0
    with path.open("ab") as out:
        async for chunk in request.stream():
            written += len(chunk)
            if written > settings.runner_chunk_bytes + 1024 or size + written > settings.runner_max_file_bytes:
                out.truncate(size)
                return JSONResponse({"error": "too_large", "size": size}, status_code=413)
            out.write(chunk)
    job.heartbeat_at = utcnow()
    db.commit()
    return {"name": name, "size": size + written}


@router.post("/jobs/{job_id}/complete")
async def complete(
    job_id: int, request: Request, runner: str = Depends(require_runner),
    db: Session = Depends(get_db),
):
    job = _job_or_404(db, job_id)
    _running(job, runner)
    try:
        body = await request.json()
        metrics = body["metrics"]
        declared = body["files"]
        assert isinstance(metrics, dict) and isinstance(declared, dict)
    except (ValueError, KeyError, AssertionError, TypeError):
        raise _http(400, "invalid_body")

    verified = {}
    for name in training.REQUIRED_FILES:
        meta = declared.get(name) or {}
        path = training.upload_dir(job.id) / name
        if not path.is_file():
            raise _http(409, f"missing_{name}")
        size = path.stat().st_size
        digest = training.sha256_file(path)
        if size != meta.get("bytes") or digest != meta.get("sha256"):
            raise _http(409, f"checksum_mismatch_{name}")
        verified[name] = {"bytes": size, "sha256": digest}

    job.metrics = json.dumps(metrics, ensure_ascii=False)[:200_000]
    job.files = json.dumps(verified)
    job.progress = 1.0
    job.stage = "awaiting approval"
    job.finished_at = utcnow()
    job.heartbeat_at = utcnow()
    training.transition(job, "review")
    _log(db, job, ["results uploaded and verified; awaiting admin approval"])
    db.commit()
    notify_admins(db, "training_done", {"job": job.id}, f"/admin/training/{job.id}")
    return {"status": job.status}


@router.post("/jobs/{job_id}/fail")
async def fail(
    job_id: int, request: Request, runner: str = Depends(require_runner),
    db: Session = Depends(get_db),
):
    job = _job_or_404(db, job_id)
    _running(job, runner)
    try:
        body = await request.json()
    except ValueError:
        body = {}
    job.error = str(body.get("error") or "unknown error")[:5000]
    job.finished_at = utcnow()
    training.transition(job, "failed")
    _log(db, job, [f"failed: {job.error[:500]}"])
    db.commit()
    notify_admins(db, "training_failed", {"job": job.id}, f"/admin/training/{job.id}")
    return {"status": job.status}
