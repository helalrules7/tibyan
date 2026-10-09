"""Training jobs: dataset snapshots, the fixed evaluation set, the job state
machine, and publishing an approved model to the public mirror.

Job states
    queued -> running -> review -> published -> rolled_back
                     \\-> failed -> queued (admin retry)
    queued/running -> cancelled ; review -> rejected

A model reaches the mirror ONLY through publish_job(), which the admin
panel calls after an explicit "Approve & publish".
"""
from __future__ import annotations

import hashlib
import json
import os
import shutil
from pathlib import Path

from sqlalchemy.orm import Session

from .config import settings
from .models import EvalSet, EvalSetItem, Recording, TrainingJob
from .push import utcnow

STATES = (
    "queued",
    "running",
    "review",
    "published",
    "rejected",
    "failed",
    "cancelled",
    "rolled_back",
)
TRANSITIONS: dict[str, set[str]] = {
    "queued": {"running", "cancelled"},
    "running": {"running", "review", "failed", "cancelled", "queued"},
    "review": {"published", "rejected"},
    "published": {"rolled_back"},
    "failed": {"queued"},
    "rejected": set(),
    "cancelled": set(),
    "rolled_back": set(),
}
ACTIVE_STATES = ("queued", "running")

REQUIRED_FILES = ("model.int8.onnx", "tokens.txt")
ALLOWED_FILES = REQUIRED_FILES + ("metrics.json", "train-summary.json")

DEFAULT_PARAMS = {
    "epochs": 5,
    "learning_rate": 3e-5,
    "batch_size": 4,
    "max_duration_s": 30.0,
    "freeze_encoder": False,
    "text_norm": "plain",
    "seed": 42,
}
PARAM_LIMITS = {
    "epochs": (1, 100),
    "learning_rate": (1e-7, 1e-2),
    "batch_size": (1, 64),
    "max_duration_s": (2.0, 60.0),
    "seed": (0, 2**31 - 1),
}
TEXT_NORMS = ("plain",)

VOICE_GROUPS = ("men", "women", "children", "unspecified")
VOLUNTEER_CREDIT = "متطوعو تبيان / Tibyan volunteers"


class InvalidTransition(Exception):
    pass


def transition(job: TrainingJob, new: str) -> None:
    if new not in STATES:
        raise InvalidTransition(f"unknown state {new}")
    if new not in TRANSITIONS.get(job.status, set()):
        raise InvalidTransition(f"{job.status} -> {new} is not allowed")
    job.status = new


def voice_group(rec: Recording) -> str:
    if rec.age_bracket == "under_18":
        return "children"
    if rec.gender == "male":
        return "men"
    if rec.gender == "female":
        return "women"
    return "unspecified"


def clean_params(raw: dict) -> dict:
    """Validate hyperparameters; unknown keys are dropped."""
    out = dict(DEFAULT_PARAMS)
    for key, (lo, hi) in PARAM_LIMITS.items():
        if key in raw and raw[key] not in (None, ""):
            caster = float if isinstance(DEFAULT_PARAMS[key], float) else int
            try:
                value = caster(raw[key])
            except (TypeError, ValueError):
                raise ValueError(key)
            if not lo <= value <= hi:
                raise ValueError(key)
            out[key] = value
    if "freeze_encoder" in raw:
        out["freeze_encoder"] = str(raw["freeze_encoder"]).lower() in ("1", "true", "on", "yes")
    if raw.get("text_norm"):
        if raw["text_norm"] not in TEXT_NORMS:
            raise ValueError("text_norm")
        out["text_norm"] = raw["text_norm"]
    return out


# ---------- evaluation set ----------------------------------------------

def active_eval_set(db: Session) -> EvalSet | None:
    return db.query(EvalSet).order_by(EvalSet.id.desc()).first()


def eval_ids(db: Session, eval_set_id: int | None) -> set[int]:
    if eval_set_id is None:
        return set()
    return {
        row[0]
        for row in db.query(EvalSetItem.recording_id)
        .filter(EvalSetItem.eval_set_id == eval_set_id)
        .all()
    }


def _stable_key(rec_id: int) -> str:
    return hashlib.sha256(f"tibyan-eval-{rec_id}".encode()).hexdigest()


def freeze_eval_set(db: Session, admin_id: int | None, fraction: float | None = None) -> EvalSet:
    """Freeze a held-out set from accepted recordings, stratified by voice
    group: about `fraction` of each group (at least one from any group with
    two or more recordings), chosen by a stable hash so it is reproducible.
    """
    fraction = settings.eval_fraction if fraction is None else fraction
    if not 0 < fraction < 1:
        raise ValueError("fraction")
    accepted = db.query(Recording).filter(Recording.status == "accepted").all()
    if len(accepted) < settings.eval_min_recordings:
        raise ValueError("too_few")
    by_group: dict[str, list[Recording]] = {}
    for rec in accepted:
        by_group.setdefault(voice_group(rec), []).append(rec)
    chosen: list[int] = []
    for recs in by_group.values():
        if len(recs) < 2:
            continue
        n = max(1, round(len(recs) * fraction))
        recs = sorted(recs, key=lambda r: _stable_key(r.id))
        chosen.extend(r.id for r in recs[:n])
    if not chosen:
        raise ValueError("too_few")
    count = db.query(EvalSet).count()
    eval_set = EvalSet(name=f"eval-{count + 1}", created_by=admin_id)
    db.add(eval_set)
    db.flush()
    for rid in sorted(chosen):
        db.add(EvalSetItem(eval_set_id=eval_set.id, recording_id=rid))
    db.commit()
    db.refresh(eval_set)
    return eval_set


def group_summary(recs: list[Recording]) -> dict:
    out = {g: {"n": 0, "minutes": 0.0} for g in VOICE_GROUPS}
    for rec in recs:
        g = out[voice_group(rec)]
        g["n"] += 1
        g["minutes"] += (rec.audio_duration_ms or 0) / 60000
    for g in out.values():
        g["minutes"] = round(g["minutes"], 1)
    return out


# ---------- jobs ---------------------------------------------------------

def training_candidates(db: Session, eval_set_id: int | None) -> list[Recording]:
    held_out = eval_ids(db, eval_set_id)
    return [
        r
        for r in db.query(Recording)
        .filter(Recording.status == "accepted")
        .order_by(Recording.id)
        .all()
        if r.id not in held_out
    ]


def create_job(
    db: Session,
    admin_id: int | None,
    base_model: str,
    params: dict,
    note: str = "",
) -> TrainingJob:
    eval_set = active_eval_set(db)
    if eval_set is None:
        raise ValueError("no_eval_set")
    if base_model != "nvidia-base":
        if not base_model.startswith("job:") or not base_model[4:].isdigit():
            raise ValueError("base_model")
        parent = db.get(TrainingJob, int(base_model[4:]))
        if parent is None or parent.status not in ("published", "rolled_back", "review"):
            raise ValueError("base_model")
    train = training_candidates(db, eval_set.id)
    if not train:
        raise ValueError("no_data")
    job = TrainingJob(
        status="queued",
        base_model=base_model,
        params=json.dumps(clean_params(params)),
        dataset=json.dumps({"train": [r.id for r in train]}),
        eval_set_id=eval_set.id,
        train_count=len(train),
        train_ms=sum(r.audio_duration_ms or 0 for r in train),
        note=(note or "").strip()[:255] or None,
        created_by=admin_id,
    )
    db.add(job)
    db.commit()
    db.refresh(job)
    return job


def job_params(job: TrainingJob) -> dict:
    return json.loads(job.params or "{}")


def job_train_ids(job: TrainingJob) -> list[int]:
    return list(json.loads(job.dataset or "{}").get("train", []))


def job_metrics(job: TrainingJob) -> dict | None:
    return json.loads(job.metrics) if job.metrics else None


def is_fake(job: TrainingJob) -> bool:
    """Results from `tibyan-runner poll --fake` are pipeline tests only."""
    m = job_metrics(job) or {}
    return bool(m.get("fake") or (m.get("runner") or {}).get("fake"))


def job_files(job: TrainingJob) -> dict:
    return json.loads(job.files) if job.files else {}


def job_dir(job_id: int) -> Path:
    return Path(settings.media_dir).resolve() / "training" / "jobs" / str(job_id)


def upload_dir(job_id: int) -> Path:
    return job_dir(job_id) / "files"


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def dataset_entries(db: Session, job: TrainingJob) -> dict:
    """Train + eval entries the runner may download. Only recordings that
    are still accepted (an owner may have deleted one since the snapshot)."""
    from . import verses

    def entry(rec: Recording) -> dict | None:
        path = Path(settings.media_dir).resolve() / rec.audio_path
        if not rec.audio_path or not path.is_file():
            return None
        text = verses.ayah_range_text(rec.surah, rec.ayah, rec.ayah_end or rec.ayah)
        if not text:
            return None
        return {
            "id": rec.id,
            "audio": f"/api/runner/jobs/{job.id}/audio/{rec.id}",
            "bytes": path.stat().st_size,
            "duration": round((rec.audio_duration_ms or 0) / 1000, 3),
            "text": text,
            "group": voice_group(rec),
        }

    def load(ids) -> tuple[list[dict], int]:
        ids = list(ids)
        if not ids:
            return [], 0
        rows = {
            r.id: r
            for r in db.query(Recording).filter(Recording.id.in_(ids)).all()
            if r.status == "accepted"
        }
        out = [e for e in (entry(rows[i]) for i in sorted(ids) if i in rows) if e]
        return out, len(ids) - len(out)

    train, train_dropped = load(job_train_ids(job))
    held_out, eval_dropped = load(eval_ids(db, job.eval_set_id))
    return {
        "job": job.id,
        "eval_set": job.eval_set_id,
        "text_source": "verses.json (exported verbatim from content.db)",
        "train": train,
        "eval": held_out,
        "dropped": {"train": train_dropped, "eval": eval_dropped},
    }


def allowed_audio_ids(db: Session, job: TrainingJob) -> set[int]:
    return set(job_train_ids(job)) | eval_ids(db, job.eval_set_id)


# ---------- the public mirror -------------------------------------------

def model_root() -> Path:
    return Path(settings.mirror_dir).resolve() / settings.model_name


def read_manifest() -> dict | None:
    path = model_root() / "manifest.json"
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None


def current_model_info() -> dict | None:
    manifest = read_manifest()
    if not manifest:
        return None
    return {
        "version": str(manifest.get("version")),
        "files": manifest.get("files", []),
    }


def _write_atomic(path: Path, data: str) -> None:
    tmp = path.with_name(f".{path.name}.tmp")
    tmp.write_text(data, encoding="utf-8")
    os.replace(tmp, path)


def _chown_like(target: Path, reference: Path) -> None:
    """Running as root in the container: hand files to the mirror owner."""
    if not hasattr(os, "chown"):
        return
    try:
        st = reference.stat()
        if os.geteuid() != 0:
            return
        for p in [target, *target.rglob("*")] if target.is_dir() else [target]:
            os.chown(p, st.st_uid, st.st_gid)
    except OSError:
        pass


def _license_text(job: TrainingJob, version: str, metrics: dict | None) -> str:
    base = (
        "the official NVIDIA checkpoint"
        if job.base_model == "nvidia-base"
        else f"Tibyan training job {job.base_model[4:]}"
    )
    return f"""Arabic speech recognition model used by Tibyan's audio tasmee
Version {version} (Tibyan training job {job.id})
==============================================================

This version is a fine-tune of:

  "STT Ar FastConformer Hybrid Transducer-CTC Large PCD" (v1.0)
  nvidia/stt_ar_fastconformer_hybrid_large_pcd_v1.0
  https://huggingface.co/nvidia/stt_ar_fastconformer_hybrid_large_pcd_v1.0
  Copyright NVIDIA Corporation, licensed under the Creative Commons
  Attribution 4.0 International licence (CC BY 4.0):
  https://creativecommons.org/licenses/by/4.0/

Starting point: {base}.

Fine-tuned on recitations donated under CC BY 4.0 by
{VOLUNTEER_CREDIT}
through https://train.altibyan.app ({job.train_count} recordings,
{round((job.train_ms or 0) / 60000, 1)} minutes).

Changes made by Tibyan: the CTC branch was fine-tuned on the volunteer
recordings above, exported to ONNX for sherpa-onnx and quantised to
8 bits (onnxruntime quantize_dynamic, QUInt8), as in ../convert/.
NVIDIA does not endorse Tibyan or these changes.

The adapted files are shared under the same licence, CC BY 4.0
(full text in ../LICENSE.txt). No warranty: see Section 5 of the
licence.
"""


def _update_top_sums(root: Path, version: str | None = None, version_sums=()) -> None:
    """Keep the model's top-level SHA256SUMS in step with manifest.json and
    list the new version's files next to the older ones."""
    sums_path = root / "SHA256SUMS"
    lines = []
    if sums_path.is_file():
        lines = [
            ln
            for ln in sums_path.read_text(encoding="utf-8").splitlines()
            if ln.strip()
            and not ln.endswith("  manifest.json")
            and not (version_sums and f"  {version}/" in ln)
        ]
    lines += [f"{digest}  {version}/{name}" for digest, name in version_sums]
    lines.append(f"{sha256_file(root / 'manifest.json')}  manifest.json")
    _write_atomic(sums_path, "\n".join(lines) + "\n")


def publish_job(job: TrainingJob) -> str:
    """Copy an approved job's model into a new mirror version and point
    manifest.json at it. The previous manifest is kept as
    manifest.v<old>.json and its version directory stays for rollback.
    """
    if job.status != "review":
        raise InvalidTransition(f"{job.status} cannot be published")
    if is_fake(job):
        raise RuntimeError("a fake-trainer (dry-run) result can never be published")
    root = model_root()
    manifest = read_manifest()
    if manifest is None:
        raise RuntimeError("mirror manifest.json is missing")
    files = job_files(job)
    src = upload_dir(job.id)
    for name in REQUIRED_FILES:
        meta = files.get(name)
        path = src / name
        if not meta or not path.is_file():
            raise RuntimeError(f"{name} is missing")
        if path.stat().st_size != meta["bytes"] or sha256_file(path) != meta["sha256"]:
            raise RuntimeError(f"{name} does not match its checksum")

    old_version = str(manifest.get("version"))
    numeric = [int(p.name) for p in root.iterdir() if p.is_dir() and p.name.isdigit()]
    if old_version.isdigit():
        numeric.append(int(old_version))
    version = str(max(numeric + [0]) + 1)

    stage = root / f".{version}.staging"
    if stage.exists():
        shutil.rmtree(stage)
    stage.mkdir()
    sums = []
    for name in REQUIRED_FILES:
        shutil.copyfile(src / name, stage / name)
        sums.append((files[name]["sha256"], name))
    (stage / "LICENSE.txt").write_text(
        _license_text(job, version, job_metrics(job)), encoding="utf-8"
    )
    sums.append((sha256_file(stage / "LICENSE.txt"), "LICENSE.txt"))
    (stage / "SHA256SUMS").write_text(
        "".join(f"{d}  {n}\n" for d, n in sums), encoding="utf-8"
    )
    # Verify the staged copy against SHA256SUMS before it becomes visible.
    for digest, name in sums:
        if sha256_file(stage / name) != digest:
            shutil.rmtree(stage)
            raise RuntimeError(f"staged {name} failed SHA256SUMS")
    final = root / version
    os.rename(stage, final)

    backup = root / f"manifest.v{old_version}.json"
    if not backup.exists():
        shutil.copyfile(root / "manifest.json", backup)
    base_url = f"{settings.mirror_base_url.rstrip('/')}/{settings.model_name}/{version}"
    new_manifest = dict(manifest)
    new_manifest["version"] = version
    new_manifest["attribution"] = (
        "Arabic FastConformer by NVIDIA (nvidia/stt_ar_fastconformer_hybrid_large_pcd_v1.0), "
        f"CC BY 4.0; CTC branch fine-tuned on recitations by {VOLUNTEER_CREDIT} "
        "(CC BY 4.0), exported to ONNX and quantised to int8 by Tibyan."
    )
    new_manifest["files"] = [
        {
            "name": name,
            "url": f"{base_url}/{name}",
            "sha256": files[name]["sha256"],
            "bytes": files[name]["bytes"],
        }
        for name in REQUIRED_FILES
    ]
    _write_atomic(
        root / "manifest.json",
        json.dumps(new_manifest, ensure_ascii=False, indent=2) + "\n",
    )
    _update_top_sums(root, version, [(d, n) for d, n in sums])
    for path in (final, root / "manifest.json", backup, root / "SHA256SUMS"):
        _chown_like(path, root)

    transition(job, "published")
    job.published_version = version
    job.previous_version = old_version
    job.decided_at = utcnow()
    return version


def rollback_job(job: TrainingJob) -> str:
    """Point manifest.json back at the version this job replaced."""
    if job.status != "published":
        raise InvalidTransition(f"{job.status} cannot be rolled back")
    root = model_root()
    manifest = read_manifest() or {}
    if str(manifest.get("version")) != str(job.published_version):
        raise RuntimeError("this job's version is not the one being served")
    backup = root / f"manifest.v{job.previous_version}.json"
    if not backup.is_file():
        raise RuntimeError(f"{backup.name} is missing")
    previous = json.loads(backup.read_text(encoding="utf-8"))
    for f in previous.get("files", []):
        local = root / str(previous.get("version")) / f["name"]
        if not local.is_file() or sha256_file(local) != f["sha256"]:
            raise RuntimeError(f"version {previous.get('version')} files are not intact")
    # Keep the replaced manifest too, so it can be inspected later.
    current_copy = root / f"manifest.v{job.published_version}.json"
    if not current_copy.exists():
        shutil.copyfile(root / "manifest.json", current_copy)
        _chown_like(current_copy, root)
    _write_atomic(
        root / "manifest.json",
        json.dumps(previous, ensure_ascii=False, indent=2) + "\n",
    )
    _update_top_sums(root)
    _chown_like(root / "manifest.json", root)
    _chown_like(root / "SHA256SUMS", root)
    transition(job, "rolled_back")
    job.decided_at = utcnow()
    return str(previous.get("version"))


def discard_uploads(job: TrainingJob) -> None:
    shutil.rmtree(upload_dir(job.id), ignore_errors=True)
