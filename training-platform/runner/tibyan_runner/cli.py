"""tibyan-runner: check | poll | status"""
from __future__ import annotations

import argparse
import json
import os
import signal
import sys
import threading

from . import __version__
from .api import Api, ApiError
from .config import ENV_FILE, load
from .pipeline import Pipeline


def _check(cfg) -> int:
    ok = True
    print(f"tibyan-runner {__version__}")
    print(f"platform: {cfg.url}  runner name: {cfg.name}")
    print(f"home: {cfg.home}  env file: {ENV_FILE} ({'found' if ENV_FILE.is_file() else 'missing'})")
    if not cfg.token:
        print("TIBYAN_RUNNER_TOKEN: missing")
        ok = False
    else:
        try:
            print("platform:", Api(cfg, retries=1).ping())
        except Exception as exc:
            print("platform: FAILED", exc)
            ok = False
    for mod in ("torch", "nemo", "onnx", "onnxruntime", "sherpa_onnx"):
        try:
            m = __import__(mod)
            extra = ""
            if mod == "torch":
                extra = f" (MPS available: {m.backends.mps.is_available()})"
            print(f"{mod}: {getattr(m, '__version__', '?')}{extra}")
        except Exception as exc:  # optional for --fake
            print(f"{mod}: not available ({exc.__class__.__name__}); only --fake can run")
    return 0 if ok else 1


def _status(cfg) -> int:
    if not cfg.jobs_dir.is_dir():
        print("no local jobs")
        return 0
    for jd in sorted(cfg.jobs_dir.iterdir(), key=lambda p: int(p.name) if p.name.isdigit() else 0):
        st = jd / "state.json"
        state = json.loads(st.read_text()) if st.is_file() else {}
        stages = [k for k in ("trained", "exported", "metrics") if state.get(k)]
        print(f"job {jd.name}: done {stages or ['-']}; model.nemo {'yes' if (jd / 'model.nemo').is_file() else 'no'}")
    return 0


def _poll(cfg, args) -> int:
    if not cfg.token:
        print("TIBYAN_RUNNER_TOKEN is not set (see README).", file=sys.stderr)
        return 2
    if cfg.nice:
        try:
            os.nice(cfg.nice)  # keep the Mac responsive
        except OSError:
            pass
    stop = threading.Event()

    def handle(signum, _frame):
        if stop.is_set():
            print("second signal: exiting now", flush=True)
            os._exit(130)
        print(f"signal {signum}: finishing the current step, saving a checkpoint…", flush=True)
        stop.set()

    signal.signal(signal.SIGINT, handle)
    signal.signal(signal.SIGTERM, handle)

    api = Api(cfg)
    pipeline = Pipeline(cfg, api, stop, fake=args.fake, max_steps=args.max_steps)
    print(f"polling {cfg.url} as {cfg.name} every {cfg.poll_seconds}s"
          f"{' (FAKE trainer)' if args.fake else ''}", flush=True)
    while not stop.is_set():
        try:
            claimed = api.claim()
        except (ApiError, OSError) as exc:
            print(f"claim failed: {exc}", flush=True)
            claimed = {}
            if isinstance(exc, ApiError) and exc.status in (401, 403):
                return 3
        job = claimed.get("job")
        if job:
            result = pipeline.run(job)
            print(f"job {job['id']}: {result}", flush=True)
            if result == "paused":
                return 0
            if args.once:
                return 0 if result == "completed" else 1
            continue
        if args.once:
            print("no job queued", flush=True)
            return 0
        stop.wait(cfg.poll_seconds)
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="tibyan-runner", description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("check", help="check the token, the platform and the ML stack")
    sub.add_parser("status", help="show local job state")
    p = sub.add_parser("poll", help="claim and run jobs")
    p.add_argument("--once", action="store_true", help="run at most one job, then exit")
    p.add_argument("--fake", "--dry-run", dest="fake", action="store_true",
                   help="fake trainer: exercise the pipeline without NeMo (never approve its model)")
    p.add_argument("--max-steps", type=int, default=None,
                   help="stop training after N optimiser steps (smoke tests)")
    args = parser.parse_args(argv)
    cfg = load()
    if args.cmd == "check":
        return _check(cfg)
    if args.cmd == "status":
        return _status(cfg)
    return _poll(cfg, args)
