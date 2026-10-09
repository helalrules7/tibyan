"""One job, end to end, resumable: every finished stage is recorded in
jobs/<id>/state.json, so a restarted runner continues where it stopped.

    dataset -> base model -> train -> export -> evaluate -> upload -> complete
"""
from __future__ import annotations

import hashlib
import json
import shutil
import threading
import time
import traceback
from pathlib import Path

from .api import Api, ApiError
from .config import Config
from .metrics import score


class ServerStop(Exception):
    """The platform said stop (job cancelled or taken over)."""


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


class Reporter:
    """Buffers log lines and progress; flushes to the platform at most every
    10 s (and every 30 s as a heartbeat). Sets `stop` if the platform says
    the job should stop."""

    def __init__(self, api: Api, job_id: int, stop: threading.Event, log_file: Path):
        self.api, self.job_id, self.stop = api, job_id, stop
        self.server_stop = threading.Event()
        self.lines: list[str] = []
        self.progress: float | None = None
        self.stage: str | None = None
        self.last_flush = 0.0
        self.lock = threading.Lock()
        self.log_file = log_file
        self._alive = True
        self._beat = threading.Thread(target=self._heartbeat, daemon=True)
        self._beat.start()

    def __call__(self, progress, stage, lines=()):
        stamp = time.strftime("%H:%M:%S")
        with self.lock:
            if progress is not None:
                self.progress = progress
            if stage:
                self.stage = stage
            for line in lines:
                text = f"{stamp} {line}"
                self.lines.append(text)
                print(f"[job {self.job_id}] {text}", flush=True)
                with self.log_file.open("a", encoding="utf-8") as f:
                    f.write(text + "\n")
        if time.time() - self.last_flush > 10 or stage:
            self.flush()

    def flush(self):
        with self.lock:
            lines, self.lines = self.lines[:200], self.lines[200:]
            progress, stage = self.progress, self.stage
        try:
            resp = self.api.progress(self.job_id, progress, stage, lines)
            self.last_flush = time.time()
            if resp.get("stop"):
                self.server_stop.set()
                self.stop.set()
        except Exception as exc:  # keep training through a network blip
            with self.lock:
                self.lines = lines + self.lines
            print(f"[job {self.job_id}] progress report failed: {exc}", flush=True)

    def _heartbeat(self):
        while self._alive:
            time.sleep(30)
            if self._alive:
                self.flush()

    def close(self):
        self._alive = False
        self.flush()


class Pipeline:
    def __init__(self, cfg: Config, api: Api, stop: threading.Event, fake: bool = False,
                 max_steps: int | None = None):
        self.cfg, self.api, self.stop, self.fake, self.max_steps = cfg, api, stop, fake, max_steps

    # ---- state ----
    def _state(self, jd: Path) -> dict:
        p = jd / "state.json"
        return json.loads(p.read_text()) if p.is_file() else {}

    def _save(self, jd: Path, state: dict) -> None:
        p = jd / "state.json"
        tmp = p.with_suffix(".tmp")
        tmp.write_text(json.dumps(state, indent=1))
        tmp.replace(p)

    def _check_stop(self, rep: Reporter):
        if rep.server_stop.is_set():
            raise ServerStop()
        if self.stop.is_set():
            raise KeyboardInterrupt()

    # ---- run ----
    def run(self, job: dict) -> str:
        jd = self.cfg.jobs_dir / str(job["id"])
        jd.mkdir(parents=True, exist_ok=True)
        (jd / "job.json").write_text(json.dumps(job, indent=1))
        state = self._state(jd)
        rep = Reporter(self.api, job["id"], self.stop, jd / "runner.log")
        try:
            result = self._run(job, jd, state, rep)
            return result
        except ServerStop:
            rep(None, None, ["platform asked to stop; cleaning up"])
            self._cleanup_audio(jd)
            return "stopped-by-server"
        except KeyboardInterrupt:
            rep(None, "paused", ["runner stopped locally; will resume this job"])
            return "paused"
        except Exception as exc:
            tb = traceback.format_exc()
            (jd / "error.txt").write_text(tb)
            rep(None, "failed", [f"error: {exc}"])
            rep.flush()
            try:
                self.api.fail(job["id"], f"{exc}\n\n{tb[-3000:]}")
            except ApiError as api_exc:
                print(f"could not report failure: {api_exc}", flush=True)
            self._cleanup_audio(jd)
            return "failed"
        finally:
            rep.close()

    def _cleanup_audio(self, jd: Path):
        # Volunteer audio never stays on the Mac after a job ends.
        shutil.rmtree(jd / "audio", ignore_errors=True)

    def _run(self, job: dict, jd: Path, state: dict, rep: Reporter) -> str:
        mode = "fake trainer (NOT a real model)" if self.fake else "NeMo fine-tune"
        rep(0.01, "starting", [f"job {job['id']} on {self.cfg.name}: {mode}; params {job['params']}"])

        # 1. dataset (re-fetched on every run: recordings deleted since drop out)
        dataset = self.api.dataset(job["id"])
        (jd / "dataset.json").write_text(json.dumps(dataset, ensure_ascii=False))
        entries = dataset["train"] + dataset["eval"]
        rep(0.02, "downloading data", [
            f"dataset: {len(dataset['train'])} train, {len(dataset['eval'])} eval "
            f"(dropped since snapshot: {dataset['dropped']})"])
        audio = jd / "audio"
        have = state.setdefault("audio", {})
        for n, e in enumerate(entries, 1):
            self._check_stop(rep)
            dest = audio / f"{e['id']}.wav"
            if dest.is_file() and have.get(str(e["id"])) == sha256_file(dest):
                continue
            try:
                have[str(e["id"])] = self.api.download(e["audio"], dest)
            except ApiError as exc:
                if exc.status == 410:  # deleted by its owner meanwhile
                    rep(None, None, [f"recording {e['id']} no longer available; skipped"])
                    continue
                raise
            if n % 20 == 0:
                self._save(jd, state)
                rep(0.02 + 0.08 * n / len(entries), None, [f"downloaded {n}/{len(entries)}"])
        self._save(jd, state)
        dataset["train"] = [e for e in dataset["train"] if (audio / f"{e['id']}.wav").is_file()]
        dataset["eval"] = [e for e in dataset["eval"] if (audio / f"{e['id']}.wav").is_file()]
        if not dataset["train"]:
            raise RuntimeError("no training audio available")

        out = jd / "out"
        # 2-3. base model + training
        if not state.get("trained"):
            self._check_stop(rep)
            if self.fake:
                from . import fake

                fake.train(jd, job, dataset, rep, self.stop)
            else:
                from . import nemo_train

                base = self._base_model(job, rep)
                try:
                    nemo_train.train(jd, job, dataset, base, rep, self.stop,
                                     device_pref=self.cfg.device, threads=self.cfg.threads,
                                     max_steps=self.max_steps)
                except nemo_train.Stopped:
                    self._check_stop(rep)
                    raise KeyboardInterrupt()
            state["trained"] = True
            self._save(jd, state)

        # 4. export
        if not state.get("exported"):
            self._check_stop(rep)
            if not self.fake:
                from . import nemo_train

                rep(0.74, "exporting int8 ONNX", ["exporting the CTC branch and quantising to int8"])
                nemo_train.export_ctc_int8(jd / "model.nemo", out,
                                           source=f"tibyan-training-job-{job['id']}")
            state["exported"] = True
            self._save(jd, state)

        # 5. evaluate on the fixed held-out set, current model vs candidate
        if not state.get("metrics"):
            self._check_stop(rep)
            rep(0.85, "evaluating", [f"evaluating on {len(dataset['eval'])} held-out clips"])
            if self.fake:
                from . import fake

                metrics = fake.evaluate(jd, job, dataset, rep)
            else:
                metrics = self._evaluate(job, jd, dataset, rep)
            metrics["train"] = {
                "clips": len(dataset["train"]),
                "minutes": round(sum(e["duration"] for e in dataset["train"]) / 60, 2),
            }
            metrics["runner"] = {"name": self.cfg.name, "device": self.cfg.device,
                                 "fake": self.fake, "max_steps": self.max_steps}
            state["metrics"] = metrics
            self._save(jd, state)
            (out / "metrics.json").write_text(json.dumps(metrics, ensure_ascii=False, indent=1))
            all_cur = metrics.get("current", {}).get("groups", {}).get("all", {})
            all_new = metrics.get("candidate", {}).get("groups", {}).get("all", {})
            rep(None, None, [f"WER current {all_cur.get('wer')}% -> new {all_new.get('wer')}%; "
                             f"CER {all_cur.get('cer')}% -> {all_new.get('cer')}%"])

        # 6. upload (resumable) + complete
        files = {}
        for name in ("model.int8.onnx", "tokens.txt", "metrics.json"):
            self._check_stop(rep)
            path = out / name
            files[name] = {"sha256": sha256_file(path), "bytes": path.stat().st_size}
            rep(0.95, f"uploading {name}", [f"uploading {name} ({files[name]['bytes']} bytes)"])
            self.api.upload(job["id"], name, path, int(job.get("chunk_bytes", 16 << 20)))
        (out / "SHA256SUMS").write_text(
            "".join(f"{f['sha256']}  {n}\n" for n, f in files.items()))
        resp = self.api.complete(job["id"], state["metrics"], files)
        rep(1.0, None, [f"complete: job is now {resp.get('status')}"])
        self._cleanup_audio(jd)
        return "completed"

    def _base_model(self, job: dict, rep: Reporter) -> Path:
        base = job["base_model"]
        if base["kind"] == "job":
            path = self.cfg.jobs_dir / str(base["job_id"]) / "model.nemo"
            if not path.is_file():
                raise RuntimeError(f"base model of job {base['job_id']} is not on this Mac ({path})")
            return path
        dest = self.cfg.cache_dir / f"{base['sha256']}.nemo"
        if not dest.is_file() or sha256_file(dest) != base["sha256"]:
            rep(0.11, "downloading base model", [f"downloading {base['url']}"])
            self.api.download(base["url"], dest, expect_sha=base["sha256"], auth=False)
        return dest

    def _current_model(self, job: dict, rep: Reporter) -> Path | None:
        cur = job.get("current_model")
        if not cur:
            return None
        folder = self.cfg.cache_dir / f"model-v{cur['version']}"
        for f in cur["files"]:
            dest = folder / f["name"]
            if not dest.is_file() or dest.stat().st_size != f["bytes"]:
                rep(None, None, [f"downloading current model v{cur['version']} {f['name']}"])
                self.api.download(f["url"], dest, expect_sha=f["sha256"], auth=False)
        return folder

    def _evaluate(self, job: dict, jd: Path, dataset: dict, rep: Reporter) -> dict:
        from . import nemo_train

        items = dataset["eval"]
        metrics: dict = {"eval_set": job.get("eval_set")}
        cur = self._current_model(job, rep)
        if cur is not None:
            hyps = nemo_train.transcribe_sherpa(cur / "model.int8.onnx", cur / "tokens.txt",
                                                items, jd / "audio", self.cfg.threads, self.stop)
            metrics["current"] = {"version": job["current_model"]["version"], **score(items, hyps)}
            rep(0.9, None, ["scored the current model"])
        out = jd / "out"
        hyps = nemo_train.transcribe_sherpa(out / "model.int8.onnx", out / "tokens.txt",
                                            items, jd / "audio", self.cfg.threads, self.stop)
        metrics["candidate"] = score(items, hyps)
        return metrics
