"""A fake trainer for --fake / --dry-run: exercises the whole job
pipeline (claim, dataset download, progress, resumable upload, metrics,
complete) without NeMo or PyTorch. The "model" is random bytes and must
never be approved; its metrics come from synthetic transcripts."""
from __future__ import annotations

import hashlib
import json
import time
from pathlib import Path

from .metrics import score


def train(job_dir: Path, job: dict, dataset: dict, report, stop) -> None:
    epochs = int(job["params"].get("epochs", 1))
    for epoch in range(1, epochs + 1):
        if stop.is_set():
            raise KeyboardInterrupt
        time.sleep(0.2)
        report(0.1 + 0.6 * epoch / epochs, "training (fake)",
               [f"[fake] epoch {epoch}/{epochs} loss {1.0 / epoch:.3f}"])
    out = job_dir / "out"
    out.mkdir(parents=True, exist_ok=True)
    seed = hashlib.sha256(f"fake-{job['id']}".encode()).digest()
    (out / "model.int8.onnx").write_bytes(b"FAKE-NOT-A-MODEL" + seed * 64)
    (out / "tokens.txt").write_text("<unk> 0\n<blk> 1\n", encoding="utf-8")


def evaluate(job_dir: Path, job: dict, dataset: dict, report) -> dict:
    def drop(text: str, every: int) -> str:
        words = text.split()
        return " ".join(w for i, w in enumerate(words) if (i + 1) % every)

    items = dataset["eval"]
    current = {e["id"]: drop(e["text"], 5) for e in items}
    candidate = {e["id"]: drop(e["text"], 8) for e in items}
    return {
        "fake": True,
        "current": {"version": (job.get("current_model") or {}).get("version"), **score(items, current)},
        "candidate": score(items, candidate),
    }
