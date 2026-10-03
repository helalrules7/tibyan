"""Verse and word timings for Mahmoud Ali al-Banna (murattal, reciter 4)
and Mustafa Ismail (murattal, reciter 5) on the mp3quran surah files
(https://server8.mp3quran.net/bna/ and /mustafa/), from everyayah's
per-verse files of the same recordings and QuranLab's word timings.
Mustafa Ismail's verses are found the same way; QuranLab times the words
of only 2,015 of his verses, so the others get verse timing only.
The numbers in this note are al-Banna's.

mp3quran publishes no verse timing for this recitation. QuranLab
(quranlab/quran-audio, CC BY 4.0, see fetch_quranlab_timing.py) publishes
word timings for 6,235 of 6,236 verses, measured on everyayah's per-verse
files (mahmoud_ali_al_banna_32kbps). Those files are cut from the same
recording as the surah files: 98% of the verses found below are 0.99 to
1.09 times as long in the surah file as in their own file, and the
difference is pauses (the per-verse files shorten some of them; the
surah files carry no basmala before verse 1, the per-verse files of
verse 1 usually do). So each verse is found in the surah file by its
sound, not guessed from durations.

Method (all on loudness envelopes: dB per 10 ms frame, clipped at -60):
1. Place each verse, in order. Its per-verse file's first and last 3 s
   (the whole verse when it is short) are located in the surah file by
   normalised cross-correlation (0.85 or more), the first just after the
   previous verse, the last where the verse's length says it should be,
   up to 15% later (longer pauses). Among near-equal peaks the earliest
   is taken, so a refrain (55:13 and its repeats) is matched to its next
   occurrence. Verse 1 is searched at the file's first sound; when its
   own file opens with a basmala, it is found by its end.
2. A verse that cannot be located this way is placed between its
   neighbours when both were located: the speech between them, which
   must be 0.9 to 1.5 times the verse's own length (up to 1.5: the surah
   file may hold a repeated phrase that the per-verse file cut out). Its
   own file of 12:67 is silent; its length is then estimated from its
   letters (0.75 to 1.33).
3. Checks: verses in order, no more than 0.5 s of overlap, and no more
   than 1 s of sound between two verses (sound that belongs to no verse
   means a repeat or a misplaced verse). A surah that fails any check,
   or has a verse that could not be placed, gets no timing at all: it
   plays without highlighting.
4. Verse boundaries: the quietest point (100 ms smoothing) in the pause
   before each verse, at most 3 s before it. The opening before verse 1,
   when there is one, is ayah 0; the last verse runs to the end of the
   file.
5. Words: the phrases of the per-verse file (sound between pauses of
   250 ms or more) are located inside the verse's span, and QuranLab's
   word times are mapped through them with build_word_timing's
   word_spans and mapper (piecewise linear between phrase anchors).
   Only verses whose QuranLab word count equals our word boxes are kept,
   and only when every word falls inside its verse.

Aligning verse durations to the heard silences was considered and not
used: with this recording's reverb few pauses fall below silencedetect's
threshold, and the reciter pauses inside long verses as long as between
them, so durations alone would be ambiguous where the sound is not.

Nothing here touches the Quran text (verse letters are only counted, for
12:67's length).

Usage:
  python3 tools/fetch_quranlab_timing.py mahmoud-ali-al-banna mustafa-ismail
  python3 tools/fetch_recitation_audio.py surahs 4 5
  python3 tools/fetch_recitation_audio.py verses mahmoud_ali_al_banna_32kbps Mustafa_Ismail_48kbps
  python3 tools/build_quranlab_timing.py [reciter ...]    # default: 4 5
Needs tools/.cache/audio/<reciter>/NNN.mp3 (the surah files) and
tools/.cache/everyayah/<folder>/SSSAAA.mp3 (https://everyayah.com/data/<folder>/,
folders in RECITERS below). Writes tools/.cache/quranlab_ayah_timing.json
([reciter, surah, ayah, start_ms, end_ms]) and quranlab_word_timing.json
([reciter, surah, ayah, word, start_ms, end_ms]), replacing only the rows
of the reciters built (the others are kept), and prints coverage and the
surahs left out.
"""
import json
import sqlite3
import subprocess
import sys
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import numpy as np
from numpy.lib.stride_tricks import sliding_window_view

import build_word_timing as b

ROOT = Path(__file__).resolve().parent
CACHE = ROOT / '.cache'
DB = ROOT.parent / 'assets' / 'db' / 'content.db'
# content.db reciter id -> (QuranLab timing file, everyayah per-verse
# folder, whether its word timings are kept). Mustafa Ismail's QuranLab
# word timings failed the check (1.13% of words in a pause; al-Banna's
# 0.16%): his verses get verse timing only.
RECITERS = {
    4: ('quranlab_banna_timing.json', 'mahmoud_ali_al_banna_32kbps', True),
    5: ('quranlab_mustafa-ismail_timing.json', 'Mustafa_Ismail_48kbps', False),
    11: (
        'quranlab_abdul-rahman-al-sudais_timing.json',
        'Abdurrahmaan_As-Sudais_192kbps',
        True,
    ),
    12: ('quranlab_mishary-alafasy_timing.json', 'Alafasy_128kbps', True),
    13: ('quranlab_saad-al-ghamdi_timing.json', 'Ghamadi_40kbps', True),
    14: (
        'quranlab_mohamed-al-tablawi_timing.json',
        'Mohammad_al_Tablaway_128kbps',
        True,
    ),
}
AYAH_OUT = CACHE / 'quranlab_ayah_timing.json'
WORD_OUT = CACHE / 'quranlab_word_timing.json'

RATE = 8000
HOP = 10              # ms per envelope frame
FLOOR_DB = -60        # the envelope is clipped here, so hiss does not count
SPEECH_DB = -40       # a frame louder than this holds speech
SPLIT = 25            # frames (250 ms) of quiet that end a phrase
MIN_PHRASE = 100      # frames: shorter phrases join the next one
CONTEXT = 10          # quiet frames kept around a phrase template
MIN_CORR = 0.85       # a phrase is located when it correlates this well
TIE = 0.03            # peaks this close to the best: the earliest wins
OPENING = 200         # frames after the file's first sound where verse 1 may start
NEXT_SEARCH = 1500    # frames searched after the previous phrase (15 s)
BACK = 50             # frames a phrase may start before the previous one ended
LEAD = 300            # frames before a verse searched for its boundary (3 s)
EDGE = 300            # frames: a verse is found by its first and last 3 s
PAD = 300             # ms a word may reach past the anchored stretch
LOW, HIGH = 0.9, 1.15  # verse length in the surah file / in its own file, accepted
BRIDGE_HIGH = 1.5     # the same for a verse placed between its neighbours (may hold a repeat)
STRAY = 100           # frames of sound allowed between two verses (reverb, breath)
OVERLAP = 50          # frames a verse may start before the previous one's (reverb) tail ends


def envelope(path):
    """Loudness in dB per 10 ms frame, clipped at FLOOR_DB."""
    raw = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', str(path), '-map', '0:a:0', '-ac', '1',
         '-ar', str(RATE), '-f', 's16le', '-'], capture_output=True, check=True).stdout
    a = np.frombuffer(raw, dtype=np.int16).astype(np.float64) / 32768
    hop = RATE * HOP // 1000
    n = len(a) // hop
    power = (a[:n * hop].reshape(n, hop) ** 2).mean(axis=1)
    return np.maximum(10 * np.log10(power + 1e-12), FLOOR_DB)


def phrases(env):
    """[(start, end)] frames of the phrases in a per-verse file: speech
    split at quiet of SPLIT frames or more, short phrases joined."""
    loud = np.flatnonzero(env > SPEECH_DB)
    if len(loud) == 0:
        return []
    cuts = np.flatnonzero(np.diff(loud) > SPLIT)
    out = [[int(loud[0]), None]]
    for c in cuts:
        out[-1][1] = int(loud[c]) + 1
        out.append([int(loud[c + 1]), None])
    out[-1][1] = int(loud[-1]) + 1
    merged = []
    for p in out:
        if merged and merged[-1][1] - merged[-1][0] < MIN_PHRASE:
            merged[-1][1] = p[1]
        else:
            merged.append(p)
    if len(merged) > 1 and merged[-1][1] - merged[-1][0] < MIN_PHRASE:
        last = merged.pop()
        merged[-1][1] = last[1]
    return [tuple(p) for p in merged]


def locate(env, template, lo, hi):
    """(frame, correlation) where template starts in env, lo <= frame <= hi.
    Normalised cross-correlation of the loudness curves; among peaks
    within TIE of the best, the earliest is taken, so a refrain is
    matched to its next occurrence, not a later one."""
    lo = max(0, lo)
    hi = min(hi, len(env) - len(template))
    if hi < lo:
        return None, 0.0
    t = template - template.mean()
    windows = sliding_window_view(env[lo:hi + len(template)], len(template))
    w = windows - windows.mean(axis=1, keepdims=True)
    corr = (w @ t) / (np.linalg.norm(w, axis=1) * np.linalg.norm(t) + 1e-9)
    best = float(corr.max())
    if best < MIN_CORR:
        i = int(corr.argmax())
    else:
        first = int(np.flatnonzero(corr >= max(MIN_CORR, best - TIE))[0])
        i = first + int(corr[first:first + 20].argmax())
    return lo + i, float(corr[i])


def quietest(env, lo, hi):
    """Frame of the quietest point in [lo, hi) (100 ms smoothing), the
    middle of the quietest stretch when several frames tie."""
    if hi - lo < 2:
        return hi
    seg = np.convolve(env[lo:hi], np.ones(10) / 10, mode='same')
    low = np.flatnonzero(seg <= seg.min() + 0.5)
    runs = np.split(low, np.flatnonzero(np.diff(low) > 1) + 1)
    run = max(runs, key=len)
    return lo + int(run[len(run) // 2])


def template(venv, a, b_):
    return venv[max(0, a - CONTEXT):min(len(venv), b_ + CONTEXT)], max(0, a - CONTEXT)


def place_verse(env, venv, lo, hi, first):
    """(speech start, speech end) of a verse in the surah file, in frames,
    or None; its speech starts between frames lo and hi. The verse's
    first and last 3 s are located separately (the whole verse when it is
    short): the files may differ in between, for example a pause cut
    shorter in the per-verse file."""
    loud = np.flatnonzero(venv > SPEECH_DB)
    if len(loud) == 0:
        return None
    v0, v1 = int(loud[0]), int(loud[-1]) + 1
    edge = min(EDGE, v1 - v0)
    tail_tpl, tail_off = template(venv, v1 - edge, v1)
    if v1 - v0 <= 2 * EDGE:
        tpl, off = template(venv, v0, v1)
        frame, corr = locate(env, tpl, lo - (v0 - off), hi - (v0 - off))
        if frame is not None and corr >= MIN_CORR:
            return frame - off + v0, frame - off + v1
    else:
        head_tpl, head_off = template(venv, v0, v0 + EDGE)
        head, corr = locate(env, head_tpl, lo - (v0 - head_off), hi - (v0 - head_off))
        if head is not None and corr >= MIN_CORR:
            s = head - head_off + v0
            # The verse in the surah file is as long as its own file or
            # longer (longer pauses): 0.99 to 1.09 times for 98% of verses.
            expect = s + (tail_off - v0)
            tail, corr = locate(env, tail_tpl, expect - (v1 - v0) * 3 // 100 - 30,
                                expect + int((v1 - v0) * (HIGH - 1)) + 30)
            if tail is not None and corr >= MIN_CORR:
                return s, tail + v1 - tail_off
    if not first:
        return None
    # Verse 1: the per-verse file may open with a basmala that the surah
    # file does not have. Then the verse is found by its end, and its
    # speech starts with the first sound of the surah file, which must
    # fit in the per-verse file's length.
    s = int(np.flatnonzero(env > SPEECH_DB)[0])
    tail, corr = locate(env, tail_tpl, s, s + (v1 - v0) * 11 // 10 - (v1 - tail_off))
    if tail is None or corr < MIN_CORR:
        return None
    return s, tail + v1 - tail_off


def bridge(env, own, before, after, low, high):
    """(speech start, speech end) of a verse that could not be matched by
    its sound, when both neighbours were: it is the speech between them.
    Its start is the first sound after the pause that follows the
    previous verse (the file's first sound for verse 1), its end the last
    sound before the next verse (the end of the file for the last verse).
    Accepted only when that stretch is low to high times the verse's own
    speech (`own` frames); verse 1's own file may also hold a basmala the
    surah file lacks, so it only has to fit."""
    if after is None:
        return None
    loud = env > SPEECH_DB
    if before is None:
        begin = int(np.flatnonzero(loud)[0]) if loud.any() else after[0]
    else:
        quiet = np.flatnonzero(~loud[before[1]:after[0]])
        if len(quiet) == 0:
            return None
        rest = np.flatnonzero(loud[before[1] + int(quiet[0]):after[0]])
        if len(rest) == 0:
            return None
        begin = before[1] + int(quiet[0]) + int(rest[0])
    span = speak(loud, begin, after[0], own, before is None, low, high)
    if span is None and before is not None:
        # No pause heard after the previous verse (it runs straight on, or
        # its tail was placed a little late): the first pause found was
        # inside this verse. Start at the first sound after the previous
        # verse instead; the length check still has to pass.
        rest = np.flatnonzero(loud[before[1]:after[0]])
        if len(rest):
            span = speak(loud, before[1] + int(rest[0]), after[0], own, False, low, high)
    return span


def speak(loud, begin, stop, own, first, low, high):
    """(begin, end of the last sound before stop), when its length is low
    to high times own (verse 1: 0.2 to 1.1), else None."""
    speech = np.flatnonzero(loud[begin:stop])
    if len(speech) == 0:
        return None
    end = begin + int(speech[-1]) + 1
    ratio = (end - begin) / own
    if not (0.2 <= ratio <= 1.1 if first else low <= ratio <= high):
        return None
    return begin, end


def own_length(venv):
    """Frames from the first to the last sound of a per-verse file (0 when silent)."""
    loud = np.flatnonzero(venv > SPEECH_DB)
    return int(loud[-1] - loud[0]) + 1 if len(loud) else 0


def anchors(env, venv, s, e):
    """[(per-verse frame, surah frame)] for the phrases of a placed verse
    found inside its span [s, e) of the surah file, in order."""
    out = []
    cursor = s
    todo = phrases(venv)
    while todo:
        p0, p1 = todo.pop(0)
        tpl, off = template(venv, p0, p1)
        frame, corr = locate(env, tpl, cursor - BACK, e - len(tpl) + CONTEXT)
        if frame is None or corr < MIN_CORR:
            if p1 - p0 >= 2 * MIN_PHRASE:
                cut = quietest(venv, p0 + (p1 - p0) // 4, p1 - (p1 - p0) // 4)
                todo[:0] = [(p0, cut), (cut, p1)]
            continue
        shift = frame - off
        out += [(p0, p0 + shift), (p1, p1 + shift)]
        cursor = p1 + shift
    return out


def place_words(segments, count, points):
    """QuranLab's word times (per-verse file) mapped onto the surah file
    through the anchors, or None when the word count differs from our
    word boxes or a word falls outside the anchored stretch."""
    if not segments or max(s[1] for s in segments) != count or len(points) < 2:
        return None
    spans = b.word_spans(segments, count)
    if spans is None:
        return None
    ms = [(a * HOP, c * HOP) for a, c in points]
    if spans[0][0] < ms[0][0] - PAD or spans[-1][1] > ms[-1][0] + PAD:
        return None
    f = b.mapper(ms)
    out = [(round(f(s)), round(f(e))) for s, e in spans]
    if any(out[k][0] < out[k - 1][0] for k in range(1, len(out))):
        return None
    return [(s, max(e, s + 1)) for s, e in out]


def build_surah(job):
    """Verse rows, word rows and a report for one surah; no rows when a
    verse cannot be placed."""
    reciter, surah, audio, verse_dir, aligned, counts, letters = job
    env = envelope(audio)
    verses = range(1, len(counts) + 1)
    speech, missing, bridged_verses = {}, [], []
    venvs = {a: envelope(verse_dir / f'{surah:03d}{a:03d}.mp3') for a in verses}
    # A verse's own length (frames of its per-verse file from first to last
    # sound); estimated from its letters when that file is silent (12:67).
    own = {a: own_length(venvs[a]) for a in verses}
    heard = [a for a in verses if own[a]]
    pace = sum(own[a] for a in heard) / sum(letters[a] for a in heard)
    estimated = {a for a in verses if not own[a]}
    for a in estimated:
        own[a] = round(letters[a] * pace)
    last_end, guess = 0, 0   # end of the last placed verse; where the search goes on
    for a in verses:
        venv = venvs[a]
        reach = NEXT_SEARCH
        if a == 1:
            # The surah files open straight with verse 1.
            sound = int(np.flatnonzero(env > SPEECH_DB)[0])
            placed = place_verse(env, venv, sound - BACK, sound + OPENING, False)
            if placed is None:
                # Found by its end only (its own file may open with a
                # basmala): too weak to search verse 2 after it.
                placed = place_verse(env, venv, sound - BACK, sound + OPENING, True)
                if placed is not None:
                    speech[1] = placed
                    guess = placed[1]
                    continue
        else:
            placed = place_verse(env, venv, last_end - BACK, guess + reach, False)
        if placed is None:
            # Go on from where the verse would end: the two recordings
            # run at the same pace (see bridge).
            missing.append(a)
            guess += own[a] + 50
            continue
        speech[a] = placed
        last_end = guess = placed[1]
    # Verse 1 found overlapping verse 2 is a false match: bridge it instead.
    if 1 in speech and 2 in speech and speech[1][1] > speech[2][0]:
        del speech[1]
        missing.insert(0, 1)
    ratios = [(speech[a][1] - speech[a][0]) / own[a] for a in speech if a > 1]
    for a in missing:
        low, high = (LOW, BRIDGE_HIGH) if a not in estimated else (0.75, 1.33)
        if a > 1 and a - 1 not in speech:
            continue
        # the last verse runs to the end of the file
        after = speech.get(a + 1) if a < len(counts) else (len(env), len(env))
        bridged = bridge(env, own[a], speech.get(a - 1), after, low, high)
        if bridged is not None:
            speech[a] = bridged
            bridged_verses.append(a)
    missing = [a for a in missing if a not in speech]
    if missing:
        return surah, None, None, {'unplaced verses': missing[:10], 'count': len(missing), 'ratios': ratios}
    starts = {}
    for a in verses:
        s = speech[a][0]
        prev = speech[a - 1][1] if a > 1 else 0
        if a == 1 and s < 50:
            starts[a] = 0
        elif s < prev - OVERLAP:
            return surah, None, None, {'verses overlap': a, 'ratios': ratios}
        elif a > 1 and int((env[prev:s] > SPEECH_DB).sum()) > STRAY:
            # speech that belongs to no verse: a repeat, or a verse misplaced
            return surah, None, None, {'speech between verses': (a - 1, a), 'ratios': ratios}
        else:
            starts[a] = quietest(env, max(prev, s - LEAD), s)
    ends = {a: starts[a + 1] if a < len(counts) else len(env) for a in verses}
    rows = [(reciter, surah, 0, 0, starts[1] * HOP)] if starts[1] > 0 else []
    rows += [(reciter, surah, a, starts[a] * HOP, ends[a] * HOP) for a in verses]
    words = []
    for a in verses:
        points = anchors(env, venvs[a], *speech[a])
        placed = place_words(aligned.get(a), counts[a], points)
        if placed and placed[0][0] >= starts[a] * HOP and placed[-1][1] <= ends[a] * HOP:
            words += [(reciter, surah, a, k, s, e) for k, (s, e) in enumerate(placed, start=1)]
    return surah, rows, words, {'bridged': bridged_verses, 'ratios': ratios}


def build_reciter(reciter, counts, letters):
    timing_file, folder, keep_words = RECITERS[reciter]
    timing = json.loads((CACHE / timing_file).read_text(encoding='utf-8'))
    verse_dir = CACHE / 'everyayah' / folder
    jobs, unmatched = [], []
    for surah in range(1, 115):
        aligned = {int(a): v for a, v in timing.get(str(surah), {}).items()} if keep_words else {}
        audio = CACHE / 'audio' / str(reciter) / f'{surah:03d}.mp3'
        if not audio.exists():
            continue
        if not all((verse_dir / f'{surah:03d}{a:03d}.mp3').exists() for a in counts[surah]):
            # everyayah has no per-verse files for this surah (Mustafa
            # Ismail: surahs 3 to 45): nothing to find the verses by.
            unmatched.append(surah)
            continue
        jobs.append((reciter, surah, audio, verse_dir, aligned, counts[surah], letters[surah]))
    if not jobs:
        return [], [], set()
    if unmatched:
        print(f'reciter {reciter}: no per-verse files for {len(unmatched)} surahs: {unmatched}')
    verses, words, skipped, ratios, bridged = [], [], [], [], 0
    with ProcessPoolExecutor() as pool:
        for surah, v, w, info in pool.map(build_surah, jobs):
            ratios += info.pop('ratios', [])
            if v is None:
                skipped.append((surah, info))
                continue
            bridged += len(info['bridged'])
            verses += v
            words += w
    ratios.sort()
    print(f'reciter {reciter}: verse length, surah file / per-verse file, 1% 5% 50% 95% 99%:',
          ' '.join(f'{ratios[int(len(ratios) * p)]:.2f}' for p in (0.01, 0.05, 0.5, 0.95, 0.99)))
    print(f'{bridged} verses placed between their neighbours')
    timed = sum(1 for r in verses if r[2] > 0)
    worded = len({(r[1], r[2]) for r in words})
    print(f'reciter {reciter}: {len(jobs) - len(skipped)} of {len(jobs)} surahs, {timed} verses with verse timing, '
          f'{worded} with word timing ({len(words)} words)')
    for surah, info in skipped:
        print(f'  surah {surah}: no timing ({info})')
    return verses, words, {j[1] for j in jobs}


def main():
    db = sqlite3.connect(DB)
    counts = {}
    for s, a, n in db.execute('SELECT surah, ayah, COUNT(*) FROM word_box GROUP BY surah, ayah'):
        counts.setdefault(s, {})[a] = n
    # letters per verse (search text, spaces left out): only its length is used
    letters = {}
    for s, a, text in db.execute('SELECT surah, number, text_search FROM ayah'):
        letters.setdefault(s, {})[a] = len(text.replace(' ', ''))
    built = [int(a) for a in sys.argv[1:]] or list(RECITERS)
    old_verses = json.loads(AYAH_OUT.read_text(encoding='utf-8')) if AYAH_OUT.exists() else []
    old_words = json.loads(WORD_OUT.read_text(encoding='utf-8')) if WORD_OUT.exists() else []
    done = set()
    verses, words = [], []
    for reciter in built:
        v, w, surahs = build_reciter(reciter, counts, letters)
        if not surahs:
            print(f'reciter {reciter}: no surah files cached, previous rows kept')
        done |= {(reciter, s) for s in surahs}
        verses += v
        words += w
    # Rows of surahs not built this time (reciter not asked for, or its
    # files not cached) are kept as they are.
    verses = [r for r in old_verses if (r[0], r[1]) not in done] + verses
    words = [r for r in old_words if (r[0], r[1]) not in done] + words
    AYAH_OUT.write_text(json.dumps(verses, separators=(',', ':')), encoding='utf-8')
    WORD_OUT.write_text(json.dumps(words, separators=(',', ':')), encoding='utf-8')
    return 0


if __name__ == '__main__':
    sys.exit(main())
