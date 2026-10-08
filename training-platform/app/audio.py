from __future__ import annotations

import json
import subprocess
from pathlib import Path

from .config import settings


def run_ffmpeg(args: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(
        [settings.ffmpeg_bin, "-hide_banner", "-loglevel", "error", "-y", *args],
        capture_output=True,
        timeout=120,
    )


def run_ffprobe(args: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(
        [settings.ffprobe_bin, "-hide_banner", "-loglevel", "error", *args],
        capture_output=True,
        timeout=60,
    )


def probe_duration_ms(path: Path) -> int:
    proc = run_ffprobe([
        "-v", "error",
        "-show_entries", "format=duration",
        "-of", "json",
        str(path),
    ])
    if proc.returncode != 0:
        raise ValueError("ffprobe could not read the audio.")
    info = json.loads(proc.stdout.decode("utf-8"))
    return int(float(info["format"]["duration"]) * 1000)


def mean_volume_db(path: Path) -> float:
    # volumedetect prints its stats at INFO level, so do not force
    # -loglevel error here.
    proc = subprocess.run(
        [
            settings.ffmpeg_bin, "-hide_banner",
            "-i", str(path),
            "-af", "volumedetect",
            "-f", "null", "-",
        ],
        capture_output=True,
        timeout=120,
    )
    text = (proc.stdout + proc.stderr).decode("utf-8", "replace")
    marker = "mean_volume:"
    for line in text.splitlines():
        if marker in line:
            value = line.split(marker, 1)[1].strip().replace(" dB", "")
            try:
                return float(value)
            except ValueError:
                continue
    return -91.0


def convert_to_wav(src: Path, dst: Path) -> None:
    """16 kHz mono PCM WAV — what NeMo manifests expect."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    proc = run_ffmpeg(["-i", str(src), "-ac", "1", "-ar", "16000", "-c:a", "pcm_s16le", str(dst)])
    if proc.returncode != 0:
        raise ValueError(proc.stderr.decode("utf-8", "replace")[-500:])


def validate_clip(path: Path) -> int:
    """Return duration ms after basic quality checks, or raise ValueError."""
    duration_ms = probe_duration_ms(path)
    if duration_ms < settings.min_clip_ms:
        raise ValueError("clip_too_short")
    if duration_ms > settings.max_clip_ms:
        raise ValueError("clip_too_long")
    if mean_volume_db(path) < -50.0:
        raise ValueError("clip_silent")
    return duration_ms
