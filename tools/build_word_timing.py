"""Word timings for the mp3quran surah files, for highlighting each word
as it is recited.

Sources (both CC BY 4.0 or equivalent, see docs/DATA_SOURCES.md):
  - cpfair/quran-align: word segments per verse, measured on everyayah's
    per-verse files of the same reciters.
  - mp3quran.net verse timings (tools/fetch_ayat_timing.py).

The per-verse files and mp3quran's surah files are not cut the same way
and run at slightly different lengths, so the word segments are placed
on the surah file: speech start and end in each verse come from the
audio itself (ffmpeg silencedetect), and pauses inside a verse are
matched to the pauses between aligned words when their counts agree.

Only verses whose aligned word count equals our word boxes are kept.
Nothing here touches the Quran text.

Usage:
  python3 tools/build_word_timing.py [reciter ...]   # needs tools/.cache/audio/<reciter>/NNN.mp3
Writes tools/.cache/word_timing.json (rows of surahs not built, or
without cached audio, are kept) and prints coverage.
"""
import json
import re
import sqlite3
import subprocess
import sys
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent
CACHE = ROOT / '.cache'
DB = ROOT.parent / 'assets' / 'db' / 'content.db'
OUT = CACHE / 'word_timing.json'

# content.db reciter id -> (word segments file in tools/.cache, mp3quran
# timing read id). quran-align files are lists of verses; QuranLab's
# (fetch_quranlab_timing.py) are {surah: {ayah: segments}}; both hold
# [word_start, word_end, start_ms, end_ms] segments in the per-verse file.
RECITERS = {
    1: ('quran-align/Minshawy_Murattal_128kbps.json', 112),
    2: ('quran-align/Husary_64kbps.json', 118),
    3: ('quran-align/Abdul_Basit_Murattal_64kbps.json', 53),
}
# Tried 2026-09-30 for the imams of the two Harams and rejected: the
# mp3quran verse timings do not fall on the pauses of these recordings,
# so the words cannot be placed by them (docs/DATA_SOURCES.md):
# Sudais ('quran-align/Abdurrahmaan_As-Sudais_192kbps.json', 54),
# Abdullah al-Juhani ('quranlab_abdullah-al-juhani_timing.json', 62),
# Salah al-Budair ('quranlab_salah-al-budair_timing.json', 43),
# Muhsin al-Qasim ('quranlab_muhsin-al-qasim_timing.json', 67).
NOISE_DB = -35      # silence threshold for silencedetect
# A recording whose quietest 2% of 10 ms frames stay above RAISED_FLOOR dB
# never falls silent (mastered loud over a noise floor near -30 dB, as some
# Haram recordings are): its pauses are frames FLOOR_BELOW dB under its
# median loudness instead.
RAISED_FLOOR = -45
FLOOR_BELOW = 16
MIN_SILENCE = 0.2   # seconds, for silencedetect
PAUSE_MS = 250      # a gap this long between aligned words is a pause
SNAP_MS = 1500      # farthest a heard pause may be from the boundary it pins


def frames_db(path):
    """Loudness of an audio file in dB per 10 ms frame (8 kHz mono)."""
    raw = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', str(path), '-map', '0:a:0', '-ac', '1',
         '-ar', '8000', '-f', 's16le', '-'], capture_output=True, check=True).stdout
    a = np.frombuffer(raw, dtype=np.int16).astype(np.float64) / 32768
    n = len(a) // 80
    power = (a[:n * 80].reshape(n, 80) ** 2).mean(axis=1)
    return 10 * np.log10(power + 1e-12)


def raised_quiet(env):
    """The quiet level of a recording that never falls silent, else None."""
    if np.percentile(env, 2) <= RAISED_FLOOR:
        return None
    return round(float(np.median(env))) - FLOOR_BELOW


def quiet_db(path, base):
    """The level under which a frame counts as quiet: base, or the raised
    level of a recording that never falls silent."""
    raised = raised_quiet(frames_db(path))
    return base if raised is None else raised


def silences(path):
    """[(start_ms, end_ms)] of silence in an audio file: ffmpeg
    silencedetect at NOISE_DB. In a recording that never falls silent
    (see raised_quiet) silencedetect, which looks at every sample, never fires:
    there a silence is a run of 10 ms frames whose mean power is under
    the raised level, MIN_SILENCE or longer."""
    env = frames_db(path)
    noise = raised_quiet(env)
    if noise is not None:
        edges = np.flatnonzero(np.diff(np.concatenate([[0], (env < noise).astype(int), [0]])))
        return [(int(a) * 10, int(e) * 10) for a, e in zip(edges[::2], edges[1::2])
                if (e - a) * 10 >= MIN_SILENCE * 1000]
    out = subprocess.run(
        ['ffmpeg', '-hide_banner', '-nostats', '-i', str(path), '-map', '0:a:0', '-af',
         f'silencedetect=noise={NOISE_DB}dB:d={MIN_SILENCE}', '-f', 'null', '-'],
        capture_output=True, encoding='utf-8', errors='replace').stderr
    starts = [float(x) for x in re.findall(r'silence_start: ([\d.]+)', out)]
    ends = [float(x) for x in re.findall(r'silence_end: ([\d.]+)', out)]
    if len(ends) < len(starts):
        ends.append(float('inf'))
    return [(round(s * 1000), round(e * 1000)) for s, e in zip(starts, ends)]


def speech_span(window, quiet):
    """Where speech starts and ends inside a verse window."""
    start, end = window
    for s, e in quiet:
        if s <= start < e:
            start = min(e, end)
        if s < end <= e:
            end = max(s, start)
    return start, end


def word_spans(segments, words):
    """[(start, end)] per word, in the aligned file's time. Segments cover
    [first, last) word indices; a segment over several words is split
    evenly; a word no segment covers takes the gap around it."""
    spans = [None] * words
    for first, last, s, e in segments:
        n = max(1, last - first)
        for k in range(first, min(last, words)):
            i = k - first
            spans[k] = (s + (e - s) * i / n, s + (e - s) * (i + 1) / n)
    for k in range(words):
        if spans[k] is None:
            prev = next((spans[j][1] for j in range(k - 1, -1, -1) if spans[j]), None)
            nxt = next((spans[j][0] for j in range(k + 1, words) if spans[j]), None)
            if prev is None and nxt is None:
                return None
            prev = nxt if prev is None else prev
            nxt = prev if nxt is None else nxt
            spans[k] = (prev, nxt)
    return spans


def mapper(anchors):
    """Piecewise-linear map through [(aligned_ms, file_ms)] anchors."""
    def f(t):
        for (a0, b0), (a1, b1) in zip(anchors, anchors[1:]):
            if t <= a1 or (a1, b1) == anchors[-1]:
                if a1 == a0:
                    return b0
                return b0 + (t - a0) * (b1 - b0) / (a1 - a0)
        return anchors[-1][1]
    return f


def place_verse(window, quiet, segments, words):
    """Word (start, end) in the surah file, and whether pauses matched."""
    spans = word_spans(segments, words)
    if spans is None:
        return None, False
    s0, s1 = speech_span(window, quiet)
    a0, a1 = spans[0][0], spans[-1][1]
    if s1 <= s0 or a1 <= a0:
        return None, False
    gaps = [(spans[k][1], spans[k + 1][0]) for k in range(words - 1)
            if spans[k + 1][0] - spans[k][1] >= PAUSE_MS]
    inner = [(s, e) for s, e in quiet if s > s0 and e < s1 and e - s >= PAUSE_MS]
    matched = bool(gaps) and len(gaps) == len(inner)
    middle = []
    if matched:
        for (ga, gb), (qa, qb) in zip(gaps, inner):
            middle += [(ga, qa), (gb, qb)]
    elif inner:
        # The alignment shows no pauses (its words run on): pin each pause
        # heard in the file to the word boundary that falls nearest to it
        # on a straight mapping, keeping the boundaries in order.
        f = mapper([(a0, s0), (a1, s1)])
        used = -1
        for qa, qb in inner:
            best = None
            for k in range(used + 1, words - 1):
                d = abs(f(spans[k][1]) - qa)
                if best is None or d < best[0]:
                    best = (d, k)
            if best is None or best[0] > SNAP_MS:
                continue
            k = best[1]
            middle += [(spans[k][1], qa), (spans[k + 1][0], qb)]
            used = k
        matched = bool(middle)
    f = mapper([(a0, s0), *middle, (a1, s1)])
    return [(round(f(s)), round(f(e))) for s, e in spans], matched


def build_surah(job):
    reciter, surah, audio, windows, aligned, counts = job
    quiet = silences(audio)
    rows, stats = [], {'verses': 0, 'placed': 0, 'matched': 0}
    for ayah, start, end in windows:
        if ayah == 0:
            continue
        stats['verses'] += 1
        entry = aligned.get(ayah)
        if entry is None or entry[0] != counts.get(ayah):
            continue
        placed, matched = place_verse((start, end), quiet, entry[1], entry[0])
        if placed is None:
            continue
        stats['placed'] += 1
        stats['matched'] += matched
        for n, (s, e) in enumerate(placed, start=1):
            rows.append((reciter, surah, ayah, n, s, max(e, s + 1)))
    return rows, stats


def load_segments(name):
    """{surah: {ayah: (word count, segments)}} from a quran-align or QuranLab file."""
    text = (CACHE / name).read_text(encoding='utf-8')
    if text[:1] not in '[{':
        # Some quran-align files start with the aligner's crash log line.
        text = text[text.index('\n[') + 1:]
    data = json.loads(text)
    if isinstance(data, dict):
        data = [{'surah': int(s), 'ayah': int(a), 'segments': segs}
                for s, verses in data.items() for a, segs in verses.items()]
    aligned = {}
    for e in data:
        words = max((seg[1] for seg in e['segments']), default=0)
        aligned.setdefault(e['surah'], {})[e['ayah']] = (words, e['segments'])
    return aligned


def main():
    db = sqlite3.connect(DB)
    counts = {}
    for s, a, n in db.execute('SELECT surah, ayah, COUNT(*) FROM word_box GROUP BY surah, ayah'):
        counts.setdefault(s, {})[a] = n
    timing = json.loads((CACHE / 'mp3quran_ayat_timing.json').read_text(encoding='utf-8'))
    built = [int(a) for a in sys.argv[1:]] or list(RECITERS)
    jobs = []
    for reciter in built:
        align_name, read = RECITERS[reciter]
        aligned = load_segments(align_name)
        for surah in range(1, 115):
            audio = CACHE / 'audio' / str(reciter) / f'{surah:03d}.mp3'
            windows = timing[str(read)][str(surah)]
            numbers = [a for a, _, _ in windows if a > 0]
            if not audio.exists() or numbers != sorted(counts[surah]):
                continue
            jobs.append((reciter, surah, audio, windows, aligned.get(surah, {}), counts[surah]))
    # Rows of surahs not built this time (reciter not asked for, or surah
    # file not cached) are kept, for reciters still in RECITERS.
    have = {(j[0], j[1]) for j in jobs}
    old = json.loads(OUT.read_text(encoding='utf-8')) if OUT.exists() else []
    rows, totals = [r for r in old if (r[0], r[1]) not in have and r[0] in RECITERS], {}
    with ProcessPoolExecutor() as pool:
        for (reciter, *_), (r, stats) in zip(jobs, pool.map(build_surah, jobs)):
            rows += r
            t = totals.setdefault(reciter, {'verses': 0, 'placed': 0, 'matched': 0, 'surahs': 0})
            t['surahs'] += 1
            for k, v in stats.items():
                t[k] += v
    for reciter, t in sorted(totals.items()):
        print(f"reciter {reciter}: {t['surahs']} surahs, {t['placed']}/{t['verses']} verses "
              f"with word timing, pauses matched in {t['matched']}")
    OUT.write_text(json.dumps(rows, separators=(',', ':')), encoding='utf-8')
    print(f'{len(rows)} words -> {OUT}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
