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
  python3 tools/build_word_timing.py      # needs tools/.cache/audio/<reciter>/NNN.mp3
Writes tools/.cache/word_timing.json and prints coverage.
"""
import json
import re
import sqlite3
import subprocess
import sys
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CACHE = ROOT / '.cache'
DB = ROOT.parent / 'assets' / 'db' / 'content.db'
OUT = CACHE / 'word_timing.json'

# content.db reciter id -> (quran-align file, mp3quran timing read id)
RECITERS = {
    1: ('Minshawy_Murattal_128kbps', 112),
    2: ('Husary_64kbps', 118),
    3: ('Abdul_Basit_Murattal_64kbps', 53),
}
NOISE = '-35dB'
MIN_SILENCE = 0.2   # seconds, for silencedetect
PAUSE_MS = 250      # a gap this long between aligned words is a pause
SNAP_MS = 1500      # farthest a heard pause may be from the boundary it pins


def silences(path):
    """[(start_ms, end_ms)] of silence in an audio file."""
    out = subprocess.run(
        ['ffmpeg', '-hide_banner', '-nostats', '-i', str(path), '-map', '0:a:0', '-af',
         f'silencedetect=noise={NOISE}:d={MIN_SILENCE}', '-f', 'null', '-'],
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


def main():
    db = sqlite3.connect(DB)
    counts = {}
    for s, a, n in db.execute('SELECT surah, ayah, COUNT(*) FROM word_box GROUP BY surah, ayah'):
        counts.setdefault(s, {})[a] = n
    timing = json.loads((CACHE / 'mp3quran_ayat_timing.json').read_text(encoding='utf-8'))
    jobs = []
    for reciter, (align_name, read) in RECITERS.items():
        aligned = {}
        for e in json.loads((CACHE / 'quran-align' / f'{align_name}.json').read_text()):
            words = max((seg[1] for seg in e['segments']), default=0)
            aligned.setdefault(e['surah'], {})[e['ayah']] = (words, e['segments'])
        for surah in range(1, 115):
            audio = CACHE / 'audio' / str(reciter) / f'{surah:03d}.mp3'
            windows = timing[str(read)][str(surah)]
            numbers = [a for a, _, _ in windows if a > 0]
            if not audio.exists() or numbers != sorted(counts[surah]):
                continue
            jobs.append((reciter, surah, audio, windows, aligned.get(surah, {}), counts[surah]))
    rows, totals = [], {}
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
