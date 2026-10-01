"""Where the recited speech of each verse starts and ends in its surah file,
so the app can shorten the long silences reciters leave between verses.

For each reciter with verse timings in content.db:
  - verses with word timings: from the first word's start to the last
    word's end;
  - other verses: the speech heard inside the verse's window
    (ffmpeg silencedetect, as in build_word_timing.py).

Nothing here touches the Quran text; it only measures the audio.

Usage:
  python3 tools/build_ayah_speech.py     # needs tools/.cache/audio/<reciter>/NNN.mp3
A verse whose surah file is not cached keeps the row of the last build.
Writes tools/.cache/ayah_speech.json: [[reciter, surah, ayah, start_ms, end_ms], ...]
"""
import json
import sqlite3
import sys
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import build_word_timing as b

ROOT = Path(__file__).resolve().parent
CACHE = ROOT / '.cache'
DB = ROOT.parent / 'assets' / 'db' / 'content.db'
OUT = CACHE / 'ayah_speech.json'


def surah_rows(job):
    reciter, surah, windows, words = job
    audio = CACHE / 'audio' / str(reciter) / f'{surah:03d}.mp3'
    quiet = None
    rows = []
    for ayah, start, end in windows:
        if ayah == 0:
            continue
        w = words.get(ayah)
        if w:
            s, e = w
        else:
            if not audio.exists():
                continue
            if quiet is None:
                quiet = b.silences(audio)
            s, e = b.speech_span((start, end), quiet)
        # Keep inside the verse's window; skip anything implausible.
        s, e = max(s, start), min(e, end)
        if e - s >= 300:
            rows.append((reciter, surah, ayah, s, e))
    return rows


def main():
    db = sqlite3.connect(DB)
    windows, words = {}, {}
    for r, s, a, st, en in db.execute(
            'SELECT reciter, surah, ayah, start_ms, end_ms FROM ayah_timing ORDER BY 1, 2, 3'):
        windows.setdefault((r, s), []).append((a, st, en))
    for r, s, a, st, en in db.execute(
            'SELECT reciter, surah, ayah, MIN(start_ms), MAX(end_ms) FROM word_timing GROUP BY 1, 2, 3'):
        words.setdefault((r, s), {})[a] = (st, en)
    jobs = [(r, s, w, words.get((r, s), {})) for (r, s), w in sorted(windows.items())]
    rows = []
    with ProcessPoolExecutor() as pool:
        for part in pool.map(surah_rows, jobs):
            rows += part
    # A verse measured in an earlier build whose surah file is not cached
    # now keeps its row, when its verse window is unchanged.
    old = json.loads(OUT.read_text(encoding='utf-8')) if OUT.exists() else []
    have = {tuple(r[:3]) for r in rows}
    window = {(r, s, a): (st, en) for (r, s), w in windows.items() for a, st, en in w}
    for r, s, a, st, en in old:
        audio = CACHE / 'audio' / str(r) / f'{s:03d}.mp3'
        span = window.get((r, s, a))
        if (r, s, a) not in have and not audio.exists() and span and span[0] <= st and en <= span[1]:
            rows.append((r, s, a, st, en))
    rows.sort()
    per = {}
    for r, *_ in rows:
        per[r] = per.get(r, 0) + 1
    print('verses with a speech span per reciter:', per)
    OUT.write_text(json.dumps(rows, separators=(',', ':')), encoding='utf-8')
    print(f'{len(rows)} rows -> {OUT}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
