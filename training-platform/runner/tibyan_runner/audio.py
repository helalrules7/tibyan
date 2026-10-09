"""Audio helpers: read 16 kHz mono WAV, and cut long clips the way the
app does (at the quietest 20 ms frame between 5 and 8 s, never past 11 s)
so evaluation sees segments like the app's recogniser does."""
from __future__ import annotations

import wave
from pathlib import Path

import numpy as np

SR = 16000


def read_wav(path: Path) -> np.ndarray:
    with wave.open(str(path), "rb") as w:
        if w.getsampwidth() != 2:
            raise ValueError(f"{path.name}: expected 16-bit PCM")
        frames = w.readframes(w.getnframes())
        ch = w.getnchannels()
        sr = w.getframerate()
    x = np.frombuffer(frames, dtype="<i2").astype(np.float32) / 32768.0
    if ch > 1:
        x = x.reshape(-1, ch).mean(axis=1)
    if sr != SR:
        # Platform audio is always 16 kHz; resample linearly just in case.
        n = int(len(x) * SR / sr)
        x = np.interp(np.linspace(0, len(x) - 1, n), np.arange(len(x)), x).astype(np.float32)
    return x


def segments(x: np.ndarray, cap_s: float = 8.0, search_s: float = 3.0,
             hard_s: float = 11.0) -> list[np.ndarray]:
    frame = int(0.02 * SR)
    out = []
    start = 0
    while len(x) - start > cap_s * SR:
        lo = start + int((cap_s - search_s) * SR)
        hi = min(len(x), start + int(cap_s * SR))
        win = x[lo:hi]
        n = len(win) // frame
        if n == 0:
            break
        energy = (win[: n * frame].reshape(n, frame) ** 2).mean(axis=1)
        smooth = np.convolve(energy, np.ones(3) / 3, mode="same")
        median = float(np.median(energy)) or 1e-12
        i = int(np.argmin(smooth))
        if smooth[i] > 0.35 * median:
            # No real dip: cut at the hard limit instead.
            cut = min(len(x), start + int(hard_s * SR))
        else:
            cut = lo + i * frame + frame // 2
        out.append(x[start:cut])
        start = max(cut - int(0.2 * SR), start + 1)
    out.append(x[start:])
    return [s for s in out if len(s) >= int(0.3 * SR)]
