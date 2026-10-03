"""Check the placed timings against the audio.

Words: a word whose middle falls inside a pause heard in the file (300 ms
or longer) is misplaced. Verse boundaries: a boundary between two verses
should lie in, or within 150 ms of, a pause heard in the file (200 ms or
longer), and within 100 ms of a frame quieter than -40 dB (pauses too
short for silencedetect). Both levels rise for a recording mastered
loud (build_word_timing.quiet_db). The published mp3quran boundaries (reciters
1 to 3), quran.com's (the imams, reciters 8 to 10) and the derived
ones (al-Banna and Mustafa Ismail) are checked the same way.

Usage:
  python3 tools/verify_word_timing.py [reciter ...]   # default: every reciter with cached audio
"""
import bisect
import json
import sys
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import build_content_db as c
import build_quranlab_timing as ql
import build_word_timing as b

CACHE = Path(__file__).resolve().parent / '.cache'
WORD_FILES = ['word_timing.json', 'quranlab_word_timing.json', 'qdc_word_timing.json']
NEAR_MS = 150


def inside(quiet, starts, t, margin):
    i = bisect.bisect_right(starts, t + margin) - 1
    return i >= 0 and quiet[i][0] - margin <= t <= quiet[i][1] + margin


def check(item):
    (reciter, surah), words, bounds = item
    heard = b.silences(CACHE / 'audio' / str(reciter) / f'{surah:03d}.mp3')
    quiet = [q for q in heard if q[1] - q[0] >= 300]
    starts = [q[0] for q in quiet]
    bad = 0
    for start, end in words:
        mid = (start + end) / 2
        i = bisect.bisect_right(starts, mid) - 1
        bad += i >= 0 and quiet[i][0] + 100 < mid < quiet[i][1] - 100
    heard_starts = [q[0] for q in heard]
    near = sum(inside(heard, heard_starts, t, NEAR_MS) for t in bounds)
    # Short pauses (under 200 ms) escape silencedetect: count a boundary
    # whose loudness drops below -40 dB within 100 ms as quiet too.
    quiet_near = 0
    if bounds:
        path = CACHE / 'audio' / str(reciter) / f'{surah:03d}.mp3'
        env = ql.envelope(path)
        floor = b.quiet_db(path, ql.SPEECH_DB)
        quiet_near = sum(env[max(0, t // 10 - 10):t // 10 + 11].min() < floor
                         for t in bounds if t // 10 - 10 < len(env))
    return reciter, len(words), bad, len(bounds), near, quiet_near


def verse_bounds():
    """{(reciter, surah): [boundary ms]}: the start of every verse after
    the first, from mp3quran (reciters 1-3) and from our own derivation."""
    out = {}
    timing = json.loads((CACHE / 'mp3quran_ayat_timing.json').read_text(encoding='utf-8'))
    for reciter, *_, read in c.RECITERS:
        if read is None:
            continue
        for surah, rows in timing[str(read)].items():
            out[(reciter, int(surah))] = [s for a, s, _ in rows if a > 1]
    for name in ('quranlab_ayah_timing.json', 'qdc_ayah_timing.json'):
        path = CACHE / name
        if not path.exists():
            continue
        for reciter, surah, ayah, start, _ in json.loads(path.read_text(encoding='utf-8')):
            if ayah > 1:
                out.setdefault((reciter, surah), []).append(start)
    return out


def main():
    by = {}
    for name in WORD_FILES:
        path = CACHE / name
        if not path.exists():
            continue
        for reciter, surah, _, _, start, end in json.loads(path.read_text(encoding='utf-8')):
            by.setdefault((reciter, surah), []).append((start, end))
    bounds = verse_bounds()
    wanted = {int(a) for a in sys.argv[1:]} or {
        r for r, *_ in c.RECITERS if (CACHE / 'audio' / str(r)).is_dir()}
    items = [(key, by.get(key, []), bounds.get(key, [])) for key in sorted(set(by) | set(bounds))
             if key[0] in wanted and (CACHE / 'audio' / str(key[0]) / f'{key[1]:03d}.mp3').exists()]
    totals = {}
    with ProcessPoolExecutor() as pool:
        for reciter, n, bad, nb, near, quiet in pool.map(check, items):
            t = totals.setdefault(reciter, [0, 0, 0, 0, 0])
            for k, v in enumerate((n, bad, nb, near, quiet)):
                t[k] += v
    failed = False
    for reciter, (n, bad, nb, near, quiet) in sorted(totals.items()):
        if n:
            share = 100 * bad / n
            failed |= share > 1
            print(f'reciter {reciter}: {bad} of {n} words fall in a pause ({share:.2f}%)')
        if nb:
            print(f'reciter {reciter}: {near} of {nb} verse boundaries lie in or next to '
                  f'a heard pause ({100 * near / nb:.1f}%); {quiet} ({100 * quiet / nb:.1f}%) '
                  f'within 100 ms of a quiet frame (under {ql.SPEECH_DB} dB)')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
