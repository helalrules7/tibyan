"""Runner settings from the environment, optionally loaded from
~/.config/tibyan-runner/env (KEY=VALUE lines, keep it chmod 600)."""
from __future__ import annotations

import os
import socket
from dataclasses import dataclass
from pathlib import Path

ENV_FILE = Path(os.environ.get("TIBYAN_RUNNER_ENV_FILE", "~/.config/tibyan-runner/env")).expanduser()


def _load_env_file() -> None:
    if not ENV_FILE.is_file():
        return
    for line in ENV_FILE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


@dataclass
class Config:
    url: str
    token: str
    name: str
    home: Path
    nice: int
    device: str
    poll_seconds: int
    threads: int

    @property
    def jobs_dir(self) -> Path:
        return self.home / "jobs"

    @property
    def cache_dir(self) -> Path:
        return self.home / "cache"


def load() -> Config:
    _load_env_file()
    host = socket.gethostname().split(".")[0].lower() or "mac"
    home = Path(
        os.environ.get("TIBYAN_RUNNER_HOME", "~/Library/Application Support/tibyan-runner")
    ).expanduser()
    cpus = os.cpu_count() or 4
    return Config(
        url=os.environ.get("TIBYAN_RUNNER_URL", "https://train.altibyan.app").rstrip("/"),
        token=os.environ.get("TIBYAN_RUNNER_TOKEN", ""),
        name="".join(c for c in os.environ.get("TIBYAN_RUNNER_NAME", host) if c.isalnum() or c in "._-")[:64] or "mac",
        home=home,
        nice=int(os.environ.get("TIBYAN_RUNNER_NICE", "10")),
        device=os.environ.get("TIBYAN_RUNNER_DEVICE", "auto"),
        poll_seconds=int(os.environ.get("TIBYAN_RUNNER_POLL_SECONDS", "120")),
        # Leave half the cores to Ahmed.
        threads=int(os.environ.get("TIBYAN_RUNNER_THREADS", str(max(1, cpus // 2)))),
    )
