"""Verse and word timings for the imams Tibyan plays from quranicaudio.com,
from quran.com's QDC timings (tools/fetch_qdc_timing.py) and, for those
QDC does not time, from Quranic Universal Library's (QUL,
tools/fetch_qul_timing.py; the same layout, made with the same segment
tools).

The timings were measured on quranicaudio.com's surah files. The QDC API
names a newer copy for some (qdc/.../murattal/), but its file_size is
that of the /quran/<reciter>/NNN.mp3 file Tibyan plays, byte for byte;
a surah whose file here has another size gets no timing. QUL names the
very file Tibyan plays (maher_almu3aiqly/year1440/NNN.mp3) and its size,
checked the same way.

Verses: timestamp_from/timestamp_to as published; the opening before
verse 1 (isti'adha, basmala), when there is one, is ayah 0. A surah with
a verse missing, out of order or overlapping the previous one by more
than 0.5 s gets no verse timing (it plays without highlighting).

Words: a verse keeps its word timings when every word of our word boxes
has a segment and no segment names a word past them. When the imam
repeats a phrase, its words appear twice; the first reading of each
word is kept, and the verse only when those first readings run in order.

QUL's word segments run on to the next word's start, so a word read
before a pause (a waqf inside the verse, or the verse's end) lasts, in
the data, until the reciter speaks again: as published, 965 of
al-Muaiqly's 77,180 words have their middle inside a pause of 300 ms or
more that silencedetect hears in the file (1.25%; only one of them
starts in it). For the QUL set, a word end that runs more than 100 ms
into such a pause is moved back to where the pause starts (the word's
own sound stops there): 6,139 ends, by 1.2 s at the median. Word starts
and verse times stay as published. A pause is only taken as the word's
end when it starts at least 150 ms after the word does. After this,
2 words of 77,180 fall in a pause (tools/verify_word_timing.py).

Nothing here touches the Quran text.

Usage:
  python3 tools/fetch_qdc_timing.py; python3 tools/fetch_qul_timing.py
  python3 tools/fetch_recitation_audio.py surahs 10 15
  python3 tools/build_qdc_timing.py [qdc|qul ...]    # default: both
Writes tools/.cache/<set>_ayah_timing.json ([reciter, surah, ayah,
start_ms, end_ms]) and <set>_word_timing.json ([reciter, surah, ayah,
word, start_ms, end_ms]) for each set (qdc, qul) and prints coverage.
"""
import bisect
import json
import sqlite3
import sys
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import build_word_timing as b

ROOT = Path(__file__).resolve().parent
CACHE = ROOT / '.cache'
DB = ROOT.parent / 'assets' / 'db' / 'content.db'
# set -> {content.db reciter id: id in that set's timing file}.
# QDC: only al-Dosari's timings match the bytes his own audio_url serves;
# Sudais's and Shuraim's name files of another size, so every surah of
# theirs failed the size check and their rows were dropped (measured
# 2026-10-01). QUL: al-Muaiqly's recitation 159 (his 1440H recording).
SETS = {
    'qdc': {10: 97},
    'qul': {15: 159},
}
OVERLAP = 500   # ms a verse may start before the previous one ends
TRIM = {'qul'}  # sets whose word ends are cut back to the pause they run into
PAUSE = 300     # ms: shortest heard pause a word end is cut back to
SOUND = 150     # ms of the word that must come before that pause
RUN_ON = 100    # ms a word end may run into a pause before it is cut back


def pauses(audio):
    return [q for q in b.silences(audio) if q[1] - q[0] >= PAUSE]


def trim_ends(spans, quiet):
    """spans with each word end that runs more than RUN_ON ms into a heard
    pause moved back to the pause's start; the number of ends moved."""
    starts = [q[0] for q in quiet]
    out, moved = [], 0
    for s, e in spans:
        i = bisect.bisect_left(starts, s + SOUND)
        if i < len(quiet) and quiet[i][0] < e - RUN_ON:
            e = quiet[i][0]
            moved += 1
        out.append((s, e))
    return out, moved


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


def build(name, counts):
    timing = json.loads((CACHE / f'{name}_timing.json').read_text(encoding='utf-8'))
    verses, words = [], []
    for reciter, qdc in SETS[name].items():
        skipped, timed, total_words, worded, word_rows, trimmed = [], 0, 0, 0, 0, 0
        worded_keys = set()
        heard = {}
        if name in TRIM:
            files = {s: CACHE / 'audio' / str(reciter) / f'{s:03d}.mp3' for s in range(1, 115)}
            files = {s: f for s, f in files.items() if f.exists()}
            with ProcessPoolExecutor() as pool:
                heard = dict(zip(files, pool.map(pauses, files.values())))
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
                if surah in heard:
                    spans, moved = trim_ends(spans, heard[surah])
                    trimmed += moved
                worded += 1
                worded_keys.add((surah, a))
                word_rows += len(spans)
                words += [(reciter, surah, a, k, s, e) for k, (s, e) in enumerate(spans, start=1)]
            timed += len(rows)
        print(f'reciter {reciter} ({name} {qdc}): {114 - len(skipped)} surahs, {timed} verses with verse '
              f'timing, {worded} with word timing ({word_rows} of {total_words} words, '
              f'{100 * word_rows / total_words:.1f}%)')
        for surah, why in skipped:
            print(f'  surah {surah}: no timing ({why})')
        if name in TRIM:
            print(f'  {trimmed} word ends cut back to the pause they ran into')
        missed = [f'{s}:{a}' for s in range(1, 115) for a in counts[s]
                  if (s, a) not in worded_keys and s not in dict(skipped)]
        if missed:
            print(f'  verses without word timing: {" ".join(missed)}')
    (CACHE / f'{name}_ayah_timing.json').write_text(json.dumps(verses, separators=(',', ':')),
                                                    encoding='utf-8')
    (CACHE / f'{name}_word_timing.json').write_text(json.dumps(words, separators=(',', ':')),
                                                    encoding='utf-8')


def main():
    db = sqlite3.connect(DB)
    counts = {}
    for s, a, n in db.execute('SELECT surah, ayah, COUNT(*) FROM word_box GROUP BY surah, ayah'):
        counts.setdefault(s, {})[a] = n
    for name in sys.argv[1:] or SETS:
        build(name, counts)
    return 0


if __name__ == '__main__':
    sys.exit(main())
