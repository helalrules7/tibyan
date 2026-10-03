"""Word timings for a reciter whose per-verse audio we cannot align.

`build_quranlab_timing.py` finds each verse inside the surah file by
matching its sound, which needs the reciter's per-verse files from
everyayah to be the same recording as the mp3quran surah file we ship.
For Al-Sudais, Alafasy, Al-Ghamdi and Al-Tablaway they are not: the takes
differ, so nothing correlates and no word can be placed.

This keeps QuranLab's word times in proportion inside each verse's own
window — the verse timings we already ship, measured on our own files by
mp3quran — so every word lands in the right verse, and its spacing inside
that verse follows QuranLab's. The result is approximate inside a verse
(a few hundred milliseconds), not the acoustic placement the other
pipeline manages; it is the price of the two takes differing.

Usage:
  python3 tools/build_scaled_word_timing.py [reciter id ...]

Writes rows into `assets/db/content.db`'s `word_timing` for those
reciters only, and prints the coverage. Check with
`python3 tools/verify_word_timing.py`.
"""
import json
import sqlite3
import sys
from pathlib import Path

import build_quranlab_timing as q
import timing_files

ROOT = Path(__file__).resolve().parent
DB = ROOT.parent / 'assets' / 'db' / 'content.db'


def verse_counts(db):
    """How many words our word boxes hold for each verse."""
    return {
        (s, a): n
        for s, a, n in db.execute(
            'select surah, ayah, count(*) from word_box group by surah, ayah'
        )
    }


def verse_windows(db, reciter):
    """The verse's own window in the surah file, as we ship it."""
    return {
        (s, a): (start, end)
        for s, a, start, end in db.execute(
            'select surah, ayah, start_ms, end_ms from ayah_timing '
            'where reciter = ? and ayah > 0',
            (reciter,),
        )
    }


def rows_for(reciter, timing, counts, windows):
    """One row per word, placed in proportion inside its verse."""
    rows = []
    for surah_s, verses in timing.items():
        surah = int(surah_s)
        for ayah_s, segments in verses.items():
            ayah = int(ayah_s)
            count = counts.get((surah, ayah))
            window = windows.get((surah, ayah))
            if not count or not window or not segments:
                continue
            # The verse file's own speech, first sound to last.
            first = min(s[2] for s in segments)
            last = max(s[3] for s in segments)
            if last <= first:
                continue
            start_ms, end_ms = window
            if end_ms <= start_ms:
                continue
            # Two anchor points: a straight scale from the verse file's
            # timebase onto the verse's window in the surah file.
            points = [
                (first // q.HOP, start_ms // q.HOP),
                (last // q.HOP, end_ms // q.HOP),
            ]
            placed = q.place_words(segments, count, points)
            if not placed:
                continue
            rows += [
                (reciter, surah, ayah, k, s, e)
                for k, (s, e) in enumerate(placed, start=1)
            ]
    return rows


def main():
    ids = [int(a) for a in sys.argv[1:]] or sorted(q.RECITERS)
    db = sqlite3.connect(DB)
    counts = verse_counts(db)
    kept = {r['id']: slug for slug, r in timing_files.published().items()}
    for reciter in ids:
        if reciter in kept:
            # Its timings live in data/timing now, corrected by hand there;
            # build_content_db.py puts them in. Regenerating would undo that.
            print(f'{reciter}: kept in data/timing/{kept[reciter]}, not regenerated')
            continue
        entry = q.RECITERS.get(reciter)
        if entry is None:
            print(f'{reciter}: not in RECITERS')
            continue
        timing_file = entry[0]
        timing = _load(timing_file)
        if timing is None:
            continue
        rows = rows_for(
            reciter, timing, counts, verse_windows(db, reciter)
        )
        if not rows:
            print(f'{reciter}: nothing placed')
            continue
        db.execute('delete from word_timing where reciter = ?', (reciter,))
        db.executemany(
            'insert or replace into word_timing '
            '(reciter, surah, ayah, word, start_ms, end_ms) '
            'values (?, ?, ?, ?, ?, ?)',
            rows,
        )
        db.commit()
        ayahs = {(r[1], r[2]) for r in rows}
        print(
            f'{reciter}: {len(rows)} words in {len(ayahs)} verses '
            f'({len(rows) / sum(counts.values()):.1%} of the mushaf) '
            f'from {timing_file}'
        )
    db.close()


def _load(name):
    path = q.CACHE / name
    if not path.exists():
        print(f'{name}: not fetched yet')
        return None
    return json.loads(path.read_text(encoding='utf-8'))


if __name__ == '__main__':
    main()
