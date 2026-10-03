"""Verse and word timings measured on the very surah files Tibyan plays,
by forced alignment, for reciters whose published timings do not fall on
the pauses of those files (see docs/DATA_SOURCES.md, "verse boundaries").

Each surah file is read by a CTC speech model,
jonatasgrosman/wav2vec2-large-xlsr-53-arabic (Apache-2.0; revision
MODEL_REVISION, mirrored on our server in
mirror/sources/wav2vec2-large-xlsr-53-arabic/ with SHA256SUMS), and the
model's letter probabilities are aligned with the words of the surah
(torchaudio.functional.forced_align). The words are those of our word
boxes: content.db ayah.display_text (KFGQPC Hafs 2.0), one word per word
box. They are only read: for its own tokens the aligner keeps the
letters its vocabulary knows (ٱ is read as ا; harakat and Quranic marks
are dropped). Nothing here writes or changes the text.

A "star" token that matches any sound (the frame's best token, less a
small cost per frame) sits before the basmala, between words and verses
and at the end, so an isti'adha, a repeated phrase or verse or a closing
takbir is not forced onto a word. The surah is
aligned a few verses at a time (BATCH letters), each window starting
where the last kept verse ended.

From the aligned words:
- Verse boundary: the quietest point (100 ms smoothing) between the end
  of a verse's last word and the start of the next verse's first word
  (REACH ms either side, inside those two words, when a pause DIP dB
  deep is there; a reciter may join two verses without one).
  A verse's end is the next verse's start; the last verse ends where its
  sound fades (or at the end of the file). The opening before verse 1
  (isti'adha, basmala) is ayah 0.
- Word: from its first letter to the next word's first letter; a word
  followed by a pause heard in the file (PAUSE ms or longer, quieter than
  the file's quiet level) ends where that pause starts.
A verse whose words align badly (mean letter probability under MIN_SCORE,
or a word squeezed into one frame) keeps its verse timing but no word
timing; such verses are listed in the report.

Python dependencies (not part of the app; any virtualenv):
  numpy, torch==2.5.1, torchaudio==2.5.1, transformers==4.46.3

Usage:
  python tools/build_aligned_timing.py emit <reciter> [surah ...]    # model output, cached
  python tools/build_aligned_timing.py align <reciter> [surah ...]   # timings from it
  python tools/build_aligned_timing.py apply <reciter ...>           # write rows into content.db

`emit` reads tools/.cache/audio/<reciter>/NNN.mp3 and writes
tools/.cache/emissions/<reciter>/NNN.npy (log-probabilities per 20 ms
frame, float16). `align` writes tools/.cache/aligned_<reciter>.json:
{surah: {"verses": [[ayah, start_ms, end_ms], ...], "words": [[ayah,
word, start_ms, end_ms], ...], "flagged": [[ayah, why], ...], "speech":
[[ayah, first letter ms, last letter ms], ...]}}. `apply`
replaces the reciter's ayah_timing and word_timing rows with them.
Check with `python3 tools/verify_word_timing.py --db <reciter>`.
"""
import json
import sqlite3
import subprocess
import sys
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent
CACHE = ROOT / '.cache'
DB = ROOT.parent / 'assets' / 'db' / 'content.db'
MODEL = CACHE / 'wav2vec2-large-xlsr-53-arabic'
MODEL_REVISION = 'af46c2d8531b8dcbb5e23b952f739b372c2e5d2d'

RATE = 16000
FRAME_MS = 20         # one model frame
CHUNK_S = 16          # seconds the model reads at once, plus CONTEXT_S each side (MPS: under 20.4 s in all)
BATCH_CHUNKS = 4      # chunks read together
CONTEXT_S = 2         # seconds of audio either side of a chunk, read and dropped
BATCH = 240           # letters aligned per window
# The star tokens' cost per frame, under the frame's best token. Between
# words (a phrase read twice) it costs enough that a verse's words keep
# together; between verses less, as an imam may read a whole verse, or
# its last part, again (18 s of it in 12:10); the window's last star is
# nearly free (the window runs on past the batch), its first one dearer,
# so that a batch whose words come back later in the surah (a refrain)
# takes their first reading.
STAR_IN = 1.0
STAR_VERSE = 0.3
STAR_LEAD = 0.3
STAR_TAIL = 0.05
RETRIES = 3           # wider windows tried for a batch whose kept verses read badly
MIN_SCORE = -3.0      # mean letter log-probability under which a verse's words are dropped
PAUSE = 300           # ms: shortest quiet stretch that ends a word early
REACH = 250           # ms either side of the aligned gap searched for the pause
DIP = 12              # dB under the speech around it that makes a pause
SMOOTH = 10           # 10 ms frames: smoothing of the loudness for the quietest point

# Letters the model's vocabulary knows; ٱ (alif wasla) is read as ا.
LETTERS = set('ءآأؤإئابةتثجحخدذرزسشصضطظعغفقكلمنهوىي')
MAP = {'ٱ': 'ا'}


def words_of(text):
    """The words of a verse's KFGQPC text, one per word box: '۞' and the
    verse-number glyph are not words."""
    return [w for w in text.split()
            if w != '۞' and any(ch in LETTERS or ch in MAP for ch in w)]


def letters(word):
    return [MAP.get(ch, ch) for ch in word if ch in LETTERS or ch in MAP]


def load_text(db):
    """{surah: {ayah: [word, ...]}}, checked against the word boxes."""
    counts = {(s, a): n for s, a, n in db.execute(
        'SELECT surah, ayah, COUNT(*) FROM word_box GROUP BY surah, ayah')}
    out = {}
    for s, a, text in db.execute('SELECT surah, number, display_text FROM ayah'):
        w = words_of(text)
        assert len(w) == counts[(s, a)], (s, a, len(w), counts[(s, a)])
        out.setdefault(s, {})[a] = w
    return out


def audio(path):
    raw = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', str(path), '-map', '0:a:0', '-ac', '1',
         '-ar', str(RATE), '-f', 'f32le', '-'], capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32)


# ---------------------------------------------------------------- emit

def emit(reciter, surahs):
    import torch
    from transformers import Wav2Vec2ForCTC
    device = 'mps' if torch.backends.mps.is_available() else 'cpu'
    model = Wav2Vec2ForCTC.from_pretrained(MODEL).eval().to(device)
    if device == 'mps':
        model = model.half()
    out_dir = CACHE / 'emissions' / str(reciter)
    out_dir.mkdir(parents=True, exist_ok=True)
    step = CHUNK_S * RATE
    ctx = CONTEXT_S * RATE
    hop = RATE * FRAME_MS // 1000
    for surah in surahs:
        target = out_dir / f'{surah:03d}.npy'
        src = CACHE / 'audio' / str(reciter) / f'{surah:03d}.mp3'
        if target.exists() or not src.exists():
            continue
        a = audio(src)
        frames = len(a) // hop
        pieces = []
        for i in range(0, len(a), step):
            lo, hi = max(0, i - ctx), min(len(a), i + step + ctx)
            if hi - lo >= 400:
                pieces.append((lo, hi, (i - lo) // hop, min(step, len(a) - i) // hop))
        parts = []
        with torch.inference_mode():
            k = 0
            while k < len(pieces):
                # chunks of the same length go through the model together
                n = 1
                while (n < BATCH_CHUNKS and k + n < len(pieces)
                       and pieces[k + n][1] - pieces[k + n][0] == pieces[k][1] - pieces[k][0]):
                    n += 1
                xs = []
                for lo, hi, _, _ in pieces[k:k + n]:
                    x = torch.from_numpy(a[lo:hi].copy())
                    xs.append((x - x.mean()) / (x.std() + 1e-7))
                x = torch.stack(xs).to(device)
                if device == 'mps':
                    x = x.half()
                lp = model(x).logits.float().log_softmax(-1).cpu().numpy()
                for row, (_, _, first, keep) in zip(lp, pieces[k:k + n]):
                    parts.append(row[first:first + keep])
                k += n
        e = np.concatenate(parts)[:frames]
        if len(e) < frames:
            e = np.concatenate([e, np.repeat(e[-1:], frames - len(e), axis=0)])
        tmp = target.with_suffix('.part.npy')
        np.save(tmp, e.astype(np.float16))
        tmp.rename(target)
        print(f'reciter {reciter} surah {surah}: {frames} frames', flush=True)



# ---------------------------------------------------------------- align

def vocab():
    return json.loads((MODEL / 'vocab.json').read_text(encoding='utf-8'))


def force(e, targets):
    """Viterbi path of targets through e (frames x tokens, log-probabilities,
    the last column being the star). [(start, end, mean log-prob)] per
    target, frames, end exclusive; None when the window is too short."""
    import torch
    import torchaudio.functional as F
    if len(e) < len(targets) * 2 + 2:
        return None
    lp = torch.from_numpy(np.ascontiguousarray(e, dtype=np.float32))[None]
    tg = torch.tensor([targets], dtype=torch.int32)
    labels, scores = F.forced_align(lp, tg, blank=0)
    labels, scores = labels[0].numpy(), scores[0].numpy()
    spans, k, t = [], -1, 0
    prev = 0
    while t < len(labels):
        if labels[t] == 0:
            prev = 0
            t += 1
            continue
        u = t
        while u + 1 < len(labels) and labels[u + 1] == labels[t]:
            u += 1
        # a run of one label is one target, unless CTC put the same
        # label twice in a row with no blank between (never: targets
        # that repeat are kept apart by a blank).
        spans.append((t, u + 1, float(scores[t:u + 1].mean())))
        t = u + 1
    assert len(spans) == len(targets), (len(spans), len(targets))
    return spans


def tokens_for(units, ids, star):
    """Targets for a run of units (verses, or the basmala), each a list of
    words: a star (a phrase read twice goes to it) between words, star + 1
    after every unit. Returns (targets, owner) where owner[i] = (unit
    index, word index) for a letter, None for a star."""
    targets, owner = [star], [None]
    for u, words in enumerate(units):
        for w, word in enumerate(words):
            if w:
                targets.append(star)
                owner.append(None)
            for ch in letters(word):
                targets.append(ids[ch])
                owner.append((u, w))
        targets.append(star + 1)
        owner.append(None)
    return targets, owner


def place(spans, owner, units, lo):
    """Per unit: [(word start, word end, score)] in absolute frames."""
    out = [[None] * len(words) for words in units]
    for (s, e, sc), o in zip(spans, owner):
        if o is None:
            continue
        u, w = o
        cur = out[u][w]
        out[u][w] = (s + lo, e + lo, [sc]) if cur is None else (cur[0], e + lo, cur[2] + [sc])
    return [[(s, e, float(np.mean(sc))) for s, e, sc in unit] for unit in out]


def align_surah(e, units, ids):
    """Word spans (frames) for every unit, aligned a few units at a time."""
    star = e.shape[1]
    e = e.astype(np.float32)
    best = e.max(axis=1, keepdims=True)
    e = np.concatenate([e, best - STAR_IN, best - STAR_VERSE, best - STAR_LEAD, best - STAR_TAIL],
                       axis=1)
    sizes = [sum(len(letters(w)) for w in words) for words in units]
    placed = [None] * len(units)
    cursor, i = 0, 0
    per_letter = 10.0          # frames per letter, learnt as we go
    done_letters = done_frames = 0
    while i < len(units):
        j, n = i, sizes[i]
        while j + 1 < len(units) and n < BATCH:
            j += 1
            n += sizes[j]
        last = j == len(units) - 1
        win = int(n * per_letter * 2 + 750)
        keep = j - i + 1 if (last or j == i) else j - i
        best_got, best_score, tries = None, None, 0
        while True:
            hi = len(e) if last else min(len(e), cursor + win)
            targets, owner = tokens_for(units[i:j + 1], ids, star)
            targets[0], targets[-1] = star + 2, star + 3
            spans = force(e[cursor:hi], targets)
            if spans is not None:
                got = place(spans, owner, units[i:j + 1], cursor)
                # the whole batch must end well inside the window: a
                # window cut short squeezes the batch's last verses
                inside = last or hi >= len(e) or got[-1][-1][1] < hi - 500
                if inside:
                    # a kept verse that reads badly may have been pulled onto
                    # a neighbour read twice by a window still too short:
                    # widen a few times and keep the best reading
                    score = min(np.mean([w[2] for w in got[k]]) for k in range(keep))
                    if best_score is None or score > best_score:
                        best_got, best_score = got, score
                    tries += 1
                    if score >= MIN_SCORE or tries > RETRIES or hi >= len(e):
                        break
            if hi >= len(e):
                if best_got is None:
                    return placed
                break
            win = int(win * 1.6)
        got = best_got
        for k in range(keep):
            placed[i + k] = got[k]
        end = got[keep - 1][-1][1]
        done_letters += sum(sizes[i:i + keep])
        done_frames += end - cursor
        per_letter = max(4.0, done_frames / max(1, done_letters))
        cursor = end
        i += keep
    return placed



# ---------------------------------------------------------------- timings

def quiet_runs(env, level, shortest):
    """[(start, end)] 10 ms frames of runs under level, shortest frames or longer."""
    q = np.concatenate([[0], (env < level).astype(int), [0]])
    edges = np.flatnonzero(np.diff(q))
    return [(int(a), int(b)) for a, b in zip(edges[::2], edges[1::2]) if b - a >= shortest]


def timings(path, units, placed, opening):
    """Verse rows [(ayah, start, end)] and word rows [(ayah, word, start,
    end)] in ms, and the flagged verses [(ayah, why)]. units[0] is the
    basmala when opening is True; ayah numbers follow."""
    import build_quranlab_timing as ql
    import build_word_timing as b
    env = ql.envelope(path)                       # 10 ms frames
    sm = np.convolve(env, np.ones(SMOOTH) / SMOOTH, mode='same')
    total_ms = len(env) * 10
    heard = [q for q in b.silences(path) if q[1] - q[0] >= PAUSE]
    level = b.quiet_db(path, ql.SPEECH_DB)
    heard += [(a * 10, z * 10) for a, z in quiet_runs(sm, level, PAUSE // 10)]
    heard.sort()
    f2ms = FRAME_MS
    first = 1 if opening else 0
    verses = placed[first:]
    flagged = []
    if any(v is None for v in verses):
        return None, None, [(k + 1, 'not aligned') for k, v in enumerate(verses) if v is None], None

    def quietest(a_ms, z_ms):
        a, z = a_ms // 10, z_ms // 10
        if z <= a:
            return z_ms
        return (a + int(np.argmin(sm[a:z]))) * 10

    starts = [v[0][0] * f2ms for v in verses]
    ends = [v[-1][1] * f2ms for v in verses]
    bounds = []
    for k in range(len(verses)):
        if k == 0:
            before = placed[0][-1][1] * f2ms if opening else max(0, starts[0] - 1500)
            bounds.append(quietest(before, starts[0]) if starts[0] > before else starts[0])
        else:
            # CTC marks a letter by a short spike, which may come a little
            # before the sound ends or after it starts: the pause is looked
            # for REACH ms either side of the gap, inside the two words.
            # When the reciter joins the two verses (no pause DIP dB deep
            # there), the boundary stays inside the aligned gap.
            lo = max(ends[k - 1] - REACH, verses[k - 1][-1][0] * f2ms + f2ms)
            hi = min(starts[k] + REACH, verses[k][0][1] * f2ms)
            t = quietest(lo, hi) if hi > lo else starts[k]
            c = t // 10
            level = np.percentile(env[max(0, c - 300):c + 300], 80)
            if level - sm[min(c, len(sm) - 1)] < DIP:
                t = quietest(ends[k - 1], starts[k]) if starts[k] > ends[k - 1] else starts[k]
            bounds.append(t)
    # the last verse ends where its sound fades: the first heard pause after it
    tail = next((q[0] for q in heard if q[1] > ends[-1] + 10 and q[0] >= ends[-1] - 10),
                total_ms)
    stops = bounds[1:] + [max(ends[-1], min(total_ms, tail))]
    rows = []
    if bounds[0] > 0:
        rows.append((0, 0, bounds[0]))
    rows += [(k + 1, bounds[k], max(stops[k], bounds[k] + 1)) for k in range(len(verses))]
    words = []
    starts_heard = [q[0] for q in heard]
    import bisect
    for k, v in enumerate(verses):
        score = float(np.mean([w[2] for w in v]))
        if score < MIN_SCORE:
            flagged.append((k + 1, f'mean letter log-probability {score:.2f}'))
            continue
        spans = []
        for w, (s, e, _) in enumerate(v):
            s_ms, e_ms = s * f2ms, e * f2ms
            nxt = v[w + 1][0] * f2ms if w + 1 < len(v) else stops[k]
            # the first heard pause that starts after this word's sound
            i = bisect.bisect_left(starts_heard, e_ms - 10)
            stop = nxt
            if i < len(heard) and heard[i][0] < nxt:
                stop = max(e_ms, heard[i][0])
            spans.append((max(s_ms, bounds[k]), max(min(stop, stops[k]), s_ms + f2ms)))
        if any(spans[n][0] < spans[n - 1][0] for n in range(1, len(spans))):
            flagged.append((k + 1, 'words out of order'))
            continue
        words += [(k + 1, n + 1, a, z) for n, (a, z) in enumerate(spans)]
    speech = [(k + 1, starts[k], ends[k]) for k in range(len(verses))]
    return rows, words, flagged, speech


def align_job(job):
    reciter, surah, text, basmala = job
    path = CACHE / 'audio' / str(reciter) / f'{surah:03d}.mp3'
    e = np.load(CACHE / 'emissions' / str(reciter) / f'{surah:03d}.npy')
    ids = vocab()
    opening = surah not in (1, 9)
    units = ([basmala] if opening else []) + [text[a] for a in sorted(text)]
    placed = align_surah(e, units, ids)
    rows, words, flagged, speech = timings(path, units, placed, opening)
    return surah, rows, words, flagged, speech


def align(reciter, surahs):
    db = sqlite3.connect(DB)
    text = load_text(db)
    basmala = text[1][1]
    jobs = []
    for s in surahs:
        if (CACHE / 'emissions' / str(reciter) / f'{s:03d}.npy').exists():
            jobs.append((reciter, s, text[s], basmala))
    out_path = CACHE / f'aligned_{reciter}.json'
    out = json.loads(out_path.read_text(encoding='utf-8')) if out_path.exists() else {}
    with ProcessPoolExecutor(4) as pool:
        for surah, rows, words, flagged, speech in pool.map(align_job, jobs):
            if rows is None:
                print(f'reciter {reciter} surah {surah}: not aligned {flagged[:3]}', flush=True)
                out.pop(str(surah), None)
                continue
            out[str(surah)] = {'verses': rows, 'words': words, 'flagged': flagged,
                               'speech': speech}
            n = len(text[surah])
            print(f'reciter {reciter} surah {surah}: {n} verses, {len({w[0] for w in words})} with '
                  f'words; flagged {flagged[:4]}', flush=True)
    out_path.write_text(json.dumps(out, sort_keys=True, separators=(',', ':')), encoding='utf-8')



# ---------------------------------------------------------------- apply

SOURCE_ID = 22


def source_row(today):
    """content.db source row: these timings are measured in Tibyan."""
    return (SOURCE_ID, 'forced-alignment-timing',
            'Verse and word timings measured by forced alignment on the surah files played '
            '(al-Dosari, al-Sudais, al-Afasy, al-Ghamdi, al-Tablaway)',
            'Tibyan (tools/build_aligned_timing.py), with jonatasgrosman/wav2vec2-large-xlsr-53-arabic',
            MODEL_REVISION,
            'Timings: measured in Tibyan from the recitations; model Apache-2.0',
            'https://huggingface.co/jonatasgrosman/wav2vec2-large-xlsr-53-arabic',
            'توقيت الآيات والكلمات: مقيس في تبيان على ملفات التلاوة نفسها (محاذاة آلية)', None,
            MODEL_REVISION, today)


def apply(reciters):
    """Replace each reciter's verse and word rows with the aligned ones, for
    the surahs aligned; other surahs keep their rows."""
    from datetime import date
    db = sqlite3.connect(DB)
    for reciter in reciters:
        path = CACHE / f'aligned_{reciter}.json'
        out = json.loads(path.read_text(encoding='utf-8'))
        verses = words = 0
        for s, d in out.items():
            surah = int(s)
            db.execute('DELETE FROM ayah_timing WHERE reciter = ? AND surah = ?', (reciter, surah))
            db.execute('DELETE FROM word_timing WHERE reciter = ? AND surah = ?', (reciter, surah))
            db.executemany('INSERT INTO ayah_timing VALUES (?,?,?,?,?)',
                           [(reciter, surah, a, st, en) for a, st, en in d['verses']])
            db.executemany('INSERT INTO word_timing VALUES (?,?,?,?,?,?)',
                           [(reciter, surah, a, w, st, en) for a, w, st, en in d['words']])
            verses += sum(1 for v in d['verses'] if v[0] > 0)
            words += len(d['words'])
        print(f'reciter {reciter}: {len(out)} surahs, {verses} verses, {words} words written')
    db.execute('DELETE FROM source WHERE id = ?', (SOURCE_ID,))
    db.execute('INSERT INTO source VALUES (?,?,?,?,?,?,?,?,?,?,?)',
               source_row(date.today().isoformat()))
    db.commit()


def main():
    cmd, *args = sys.argv[1:]
    if cmd == 'emit':
        emit(int(args[0]), [int(a) for a in args[1:]] or range(1, 115))
    elif cmd == 'align':
        align(int(args[0]), [int(a) for a in args[1:]] or range(1, 115))
    elif cmd == 'apply':
        apply([int(a) for a in args])
    return 0


if __name__ == '__main__':
    sys.exit(main())
