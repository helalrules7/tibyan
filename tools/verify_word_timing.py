"""Check the placed word timings against the audio: a word whose middle
falls inside a pause heard in the file (300 ms or longer) is misplaced.

Usage:
  python3 tools/verify_word_timing.py
"""
import bisect
import json
import sys
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import build_word_timing as b

CACHE = Path(__file__).resolve().parent / '.cache'


def check(item):
    (reciter, surah), words = item
    quiet = [q for q in b.silences(CACHE / 'audio' / str(reciter) / f'{surah:03d}.mp3')
             if q[1] - q[0] >= 300]
    starts = [q[0] for q in quiet]
    bad = 0
    for start, end in words:
        mid = (start + end) / 2
        i = bisect.bisect_right(starts, mid) - 1
        bad += i >= 0 and quiet[i][0] + 100 < mid < quiet[i][1] - 100
    return reciter, len(words), bad


def main():
    rows = json.loads((CACHE / 'word_timing.json').read_text(encoding='utf-8'))
    by = {}
    for reciter, surah, _, _, start, end in rows:
        by.setdefault((reciter, surah), []).append((start, end))
    totals = {}
    with ProcessPoolExecutor() as pool:
        for reciter, n, bad in pool.map(check, by.items()):
            t = totals.setdefault(reciter, [0, 0])
            t[0] += n
            t[1] += bad
    failed = False
    for reciter, (n, bad) in sorted(totals.items()):
        share = 100 * bad / n
        failed |= share > 1
        print(f'reciter {reciter}: {bad} of {n} words fall in a pause ({share:.2f}%)')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
