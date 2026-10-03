"""Verse and word timings for the imams Tibyan plays from quranicaudio.com,
from quran.com's QDC timings (tools/fetch_qdc_timing.py).

The timings were measured on quranicaudio.com's surah files. The API
names a newer copy for some (qdc/.../murattal/), but its file_size is
that of the /quran/<reciter>/NNN.mp3 file Tibyan plays, byte for byte;
a surah whose file here has another size gets no timing.

Verses: timestamp_from/timestamp_to as published; the opening before
verse 1 (isti'adha, basmala), when there is one, is ayah 0. A surah with
a verse missing, out of order or overlapping the previous one by more
than 0.5 s gets no verse timing (it plays without highlighting).

Words: a verse keeps its word timings when every word of our word boxes
has a segment and no segment names a word past them. When the imam
repeats a phrase, its words appear twice; the first reading of each
word is kept, and the verse only when those first readings run in order.

Nothing here touches the Quran text.

Usage:
  python3 tools/fetch_qdc_timing.py
  python3 tools/fetch_recitation_audio.py surahs 8 9 10
  python3 tools/build_qdc_timing.py
Writes tools/.cache/qdc_ayah_timing.json ([reciter, surah, ayah,
start_ms, end_ms]) and qdc_word_timing.json ([reciter, surah, ayah,
word, start_ms, end_ms]) and prints coverage.
"""
import json
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CACHE = ROOT / '.cache'
DB = ROOT.parent / 'assets' / 'db' / 'content.db'
TIMING = CACHE / 'qdc_timing.json'
AYAH_OUT = CACHE / 'qdc_ayah_timing.json'
WORD_OUT = CACHE / 'qdc_word_timing.json'

# content.db reciter id -> QDC reciter id. Only al-Dosari's timings match
# the bytes his own audio_url serves; Sudais's and Shuraim's name files of
# another size, so every surah of theirs failed the size check and their
# rows were dropped (measured 2026-10-01).
RECITERS = {10: 97}
OVERLAP = 500   # ms a verse may start before the previous one ends


def words_of(segments, count):
    """[(start, end)] per word from the first reading of each, or None."""
    first = {}
    for seg in segments:
        if len(seg) != 3:
            continue
        word, start, end = int(seg[0]), round(seg[1]), round(seg[2])
        if not 1 <= word <= count:
            return None
        first.setdefault(word, (start, max(end, start + 1)))
    if len(first) != count:
        return None
    spans = [first[k] for k in range(1, count + 1)]
    if any(spans[k][0] < spans[k - 1][0] for k in range(1, count)):
        return None
    return spans


def main():
    db = sqlite3.connect(DB)
    counts = {}
    for s, a, n in db.execute('SELECT surah, ayah, COUNT(*) FROM word_box GROUP BY surah, ayah'):
        counts.setdefault(s, {})[a] = n
    timing = json.loads(TIMING.read_text(encoding='utf-8'))
    verses, words = [], []
    for reciter, qdc in RECITERS.items():
        skipped, timed, total_words, worded, word_rows = [], 0, 0, 0, 0
        for surah in range(1, 115):
            entry = timing[str(qdc)][str(surah)]
            total_words += sum(counts[surah].values())
            audio = CACHE / 'audio' / str(reciter) / f'{surah:03d}.mp3'
            if not audio.exists() or audio.stat().st_size != int(entry['file_size']):
                skipped.append((surah, 'not the file the timing was measured on'))
                continue
            rows = sorted(entry['verses'])
            if [a for a, *_ in rows] != sorted(counts[surah]):
                skipped.append((surah, 'verses missing'))
                continue
            if any(rows[k][1] < rows[k - 1][2] - OVERLAP or rows[k][1] < rows[k - 1][1]
                   for k in range(1, len(rows))):
                skipped.append((surah, 'verses overlap'))
                continue
            if rows[0][1] > 0:
                verses.append((reciter, surah, 0, 0, rows[0][1]))
            for a, start, end, segments in rows:
                verses.append((reciter, surah, a, start, max(end, start + 1)))
                spans = words_of(segments, counts[surah][a])
                if spans is None or spans[0][0] < start - OVERLAP or spans[-1][1] > end + OVERLAP:
                    continue
                worded += 1
                word_rows += len(spans)
                words += [(reciter, surah, a, k, s, e) for k, (s, e) in enumerate(spans, start=1)]
            timed += len(rows)
        print(f'reciter {reciter} (qdc {qdc}): {114 - len(skipped)} surahs, {timed} verses with verse '
              f'timing, {worded} with word timing ({word_rows} of {total_words} words, '
              f'{100 * word_rows / total_words:.1f}%)')
        for surah, why in skipped:
            print(f'  surah {surah}: no timing ({why})')
    AYAH_OUT.write_text(json.dumps(verses, separators=(',', ':')), encoding='utf-8')
    WORD_OUT.write_text(json.dumps(words, separators=(',', ':')), encoding='utf-8')
    return 0


if __name__ == '__main__':
    sys.exit(main())
