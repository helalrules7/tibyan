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
  python3 tools/verify_word_timing.py --db [reciter ...]
      the rows content.db ships (ayah_timing, word_timing) instead of the
      timing files in tools/.cache; a reciter's rows there are checked
      whichever tool wrote them.
  python3 tools/verify_word_timing.py [--db] --relative [reciter ...]
      also a check that does not depend on how loud the pauses are: a
      boundary is in a dip when, within 150 ms, the loudness (100 ms
      smoothing) falls REL_DB under the speech around it (80th percentile
      of the 3 s either side). Recordings made in the Haram keep their
      reverberation in every pause, often above -35 dB, where
      silencedetect hears nothing; this check hears those pauses too.
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
WORD_FILES = ['word_timing.json', 'quranlab_word_timing.json', 'qdc_word_timing.json',
              'qul_word_timing.json']
NEAR_MS = 150
REL_DB = 12


def dips(item):
    """Boundaries of one surah in a dip REL_DB under the speech around them."""
    import numpy as np
    (reciter, surah), _, bounds = item
    env = ql.envelope(CACHE / 'audio' / str(reciter) / f'{surah:03d}.mp3')
    smooth = np.convolve(env, np.ones(10) / 10, mode='same')
    hit = 0
    for t in bounds:
        c = t // 10
        if c >= len(env):
            continue
        level = np.percentile(env[max(0, c - 300):c + 300], 80)
        hit += level - smooth[max(0, c - NEAR_MS // 10):c + NEAR_MS // 10 + 1].min() >= REL_DB
    return reciter, hit


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
    path = CACHE / 'mp3quran_ayat_timing.json'
    timing = json.loads(path.read_text(encoding='utf-8')) if path.exists() else {}
    for reciter, *_, read in c.RECITERS:
        if read is None or str(read) not in timing:
            continue
        for surah, rows in timing[str(read)].items():
            out[(reciter, int(surah))] = [s for a, s, _ in rows if a > 1]
    for name in ('quranlab_ayah_timing.json', 'qdc_ayah_timing.json', 'qul_ayah_timing.json'):
        path = CACHE / name
        if not path.exists():
            continue
        for reciter, surah, ayah, start, _ in json.loads(path.read_text(encoding='utf-8')):
            if ayah > 1:
                out.setdefault((reciter, surah), []).append(start)
    return out


def shipped():
    """Word spans and verse boundaries as content.db holds them."""
    import sqlite3
    db = sqlite3.connect(c.OUT)
    by, bounds = {}, {}
    for reciter, surah, start, end in db.execute(
            'SELECT reciter, surah, start_ms, end_ms FROM word_timing '
            'ORDER BY reciter, surah, ayah, word'):
        by.setdefault((reciter, surah), []).append((start, end))
    for reciter, surah, start in db.execute(
            'SELECT reciter, surah, start_ms FROM ayah_timing WHERE ayah > 1 '
            'ORDER BY reciter, surah, ayah'):
        bounds.setdefault((reciter, surah), []).append(start)
    return by, bounds


def main():
    args = sys.argv[1:]
    relative = '--relative' in args
    args = [a for a in args if a != '--relative']
    if args[:1] == ['--db']:
        args = args[1:]
        by, bounds = shipped()
    else:
        by = {}
        for name in WORD_FILES:
            path = CACHE / name
            if not path.exists():
                continue
            for reciter, surah, _, _, start, end in json.loads(path.read_text(encoding='utf-8')):
                by.setdefault((reciter, surah), []).append((start, end))
        bounds = verse_bounds()
    wanted = {int(a) for a in args} or {
        r for r, *_ in c.RECITERS if (CACHE / 'audio' / str(r)).is_dir()}
    items = [(key, by.get(key, []), bounds.get(key, [])) for key in sorted(set(by) | set(bounds))
             if key[0] in wanted and (CACHE / 'audio' / str(key[0]) / f'{key[1]:03d}.mp3').exists()]
    totals = {}
    with ProcessPoolExecutor() as pool:
        for reciter, n, bad, nb, near, quiet in pool.map(check, items):
            t = totals.setdefault(reciter, [0, 0, 0, 0, 0])
            for k, v in enumerate((n, bad, nb, near, quiet)):
                t[k] += v
    in_dip = {}
    if relative:
        with ProcessPoolExecutor() as pool:
            for reciter, hit in pool.map(dips, items):
                in_dip[reciter] = in_dip.get(reciter, 0) + hit
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
        if nb and relative:
            print(f'reciter {reciter}: {in_dip[reciter]} of {nb} verse boundaries '
                  f'({100 * in_dip[reciter] / nb:.1f}%) in a dip {REL_DB} dB under the speech '
                  f'around them')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
