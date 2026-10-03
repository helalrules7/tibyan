"""Verse and word timings for Mahmoud Ali al-Banna (murattal, reciter 4)
on the mp3quran surah files (https://server8.mp3quran.net/bna/), verse by
verse: a verse that cannot be found by its sound no longer costs its
whole surah its timing.

build_quranlab_timing.py (QuranLab's word timings, CC BY 4.0, measured
on everyayah's per-verse files of the same recording) drops a surah
whenever one verse fails. This tool keeps every verse it can place and
times the others by forced alignment on the surah file itself, with the
same kind of open tools QuranLab used:

1. Transfer (most verses): each verse is found in the surah file by the
   sound of its per-verse file (build_quranlab_timing.place_verse and
   bridge, unchanged), and QuranLab's word times are carried over
   through the verse's phrases (anchors, place_words). A pair of
   neighbouring verses that fails a check (overlap, or speech between
   them that belongs to neither) loses its placement; its neighbours
   keep theirs.
2. Forced alignment (the rest): the audio between the nearest placed
   verses is aligned against the verses' words with a CTC model,
   jonatasgrosman/wav2vec2-large-xlsr-53-arabic (Apache-2.0, revision
   pinned in MODEL_REVISION; mirrored on our server), through
   torchaudio.functional.forced_align. A "star" token that matches any
   sound at a fixed cost sits before, between and after the verses, so
   an opening, a repeated phrase or a reverb tail is not forced onto a
   word. Long stretches are aligned a few verses at a time. Verses
   placed by sound whose QuranLab words cannot be carried over (no
   phrase found, word count differs, 12:67 has no QuranLab timing) get
   their words the same way, inside their own window.
   The aligner reads the Tanzil Uthmani words (content.db ayah.text,
   whose word numbers QuranLab's use) and keeps, for its own tokens,
   only the letters its vocabulary knows (ٱ and the dagger alif are read
   as ا). The text is only read; nothing here writes it.
   Tanzil splits three words that KFGQPC writes as one (15:7 لوما, 27:20
   and 36:22 مالي): their two parts' times are joined into the one word
   box.
   A one-word verse timed this way (mostly opening letters such as حم,
   said by name, which the aligner hears poorly) is given its verse's
   sound, first to last loud frame (`span` in the report).
3. Proportional placement is the last resort: QuranLab's word times
   scaled into the verse's measured window. It is flagged `approx` in
   the report and in docs/MISSING_DATA.md. A verse that cannot be
   placed at all stays untimed.

Verse boundaries are the quietest point (100 ms smoothing) in the pause
before each verse, as in build_quranlab_timing.py.

Python dependencies (not part of the app; any virtualenv):
  numpy, torch==2.5.1, torchaudio==2.5.1, transformers==4.46.3
The model is read from tools/.cache/wav2vec2-large-xlsr-53-arabic/ (the
files of MODEL_REVISION, as mirrored in
mirror/sources/wav2vec2-large-xlsr-53-arabic/ with SHA256SUMS).

Usage:
  python3 tools/fetch_quranlab_timing.py mahmoud-ali-al-banna
  python3 tools/fetch_recitation_audio.py verses mahmoud_ali_al_banna_32kbps
  (surah files in tools/.cache/audio/4/NNN.mp3)
  python tools/build_banna_timing.py [surah ...]     # default: all 114
  python tools/build_banna_timing.py --compare N     # forced alignment vs QuranLab on N transferred verses
  python tools/build_banna_timing.py --apply         # write reciter 4's rows into content.db

Writes tools/.cache/banna_ayah_timing.json ([4, surah, ayah, start_ms,
end_ms]), banna_word_timing.json ([4, surah, ayah, word, start_ms,
end_ms]) and banna_timing_report.json (how each verse was timed), and
prints coverage. Surahs not built this time keep their rows.
"""
import argparse
import json
import sqlite3
import subprocess
import sys
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import numpy as np

import build_quranlab_timing as ql
import build_word_timing as b

ROOT = Path(__file__).resolve().parent
CACHE = ROOT / '.cache'
DB = ROOT.parent / 'assets' / 'db' / 'content.db'
RECITER = 4
FOLDER = 'mahmoud_ali_al_banna_32kbps'
QURANLAB = CACHE / 'quranlab_banna_timing.json'
AYAH_OUT = CACHE / 'banna_ayah_timing.json'
WORD_OUT = CACHE / 'banna_word_timing.json'
REPORT = CACHE / 'banna_timing_report.json'
MODEL_DIR = CACHE / 'wav2vec2-large-xlsr-53-arabic'
MODEL_ID = 'jonatasgrosman/wav2vec2-large-xlsr-53-arabic'
MODEL_REVISION = 'af46c2d8531b8dcbb5e23b952f739b372c2e5d2d'

SR = 16000
FRAME = 320               # samples per CTC frame (20 ms)
FRAME_MS = 20
CHUNK = 20 * SR           # model input per pass
CONTEXT = 2 * SR          # extra audio on each side of a pass, dropped after
STAR = -3.0               # log-probability of the star token on every frame
SINGLE = 240_000          # ms: longer stretches are aligned a few verses at a time
STEP = 90_000             # ms of verses aligned per step in a long stretch
QUIET_RUN = 10            # 10 ms frames of quiet that end a word's sound
ONSET = 25                # 10 ms frames searched before a word for its onset
HOP = ql.HOP


# ---------------------------------------------------------------- text

def letters_of(word, vocab):
    """The aligner's tokens for one Uthmani word: the letters its
    vocabulary knows. Tokens only; the text itself is never changed."""
    out = []
    for i, ch in enumerate(word):
        if ch == 'ٱ':
            out.append('ا')
        elif ch == 'ٰ':
            # dagger alif: a long a, unless it rides on alif maqsura
            if not out or out[-1] not in 'ىا':
                out.append('ا')
        elif ch in vocab and ch not in 'ًٌٍَُِّْ':
            out.append(ch)
    return [vocab[c] for c in out]


def plain(word):
    return ''.join(c for c in word if 'ء' <= c <= 'ي')


def tanzil_words(text, prefix, count):
    """Tanzil Uthmani words of a verse (basmala prefix and the ۞ ۩ signs
    left out), and for each word box the Tanzil words it covers: one each,
    except where Tanzil splits a word KFGQPC writes whole."""
    words = [w for w in text[prefix:].split() if w not in ('۞', '۩')]
    if len(words) == count:
        return words, [[k] for k in range(count)]
    if len(words) != count + 1:
        return words, None
    # find the pair whose join is a single KFGQPC word: try each and keep
    # the one listed (15:7, 27:20, 36:22 are the only cases)
    for k in range(len(words) - 1):
        if plain(words[k]) + plain(words[k + 1]) in ('لوما', 'مالى', 'ومالى'):
            groups = [[j] for j in range(k)] + [[k, k + 1]] + [[j] for j in range(k + 2, len(words))]
            return words, groups
    return words, None


def merged_segments(segments, groups):
    """QuranLab segments (Tanzil word indices) renumbered to word boxes."""
    if groups is None:
        return None
    to_box = {}
    for box, g in enumerate(groups):
        for k in g:
            to_box[k] = box
    out = []
    for first, last, s, e in segments:
        if first not in to_box or last - 1 not in to_box:
            return None
        out.append([to_box[first], to_box[last - 1] + 1, s, e])
    return out


# ------------------------------------------------------- stage 1: sound

def transfer_surah(job):
    """Verses placed by their sound, per verse. Returns surah, {ayah:
    (start, end) frames of speech}, {ayah: how}, {ayah: why dropped},
    envelope length, ratios."""
    surah, audio, verse_dir, counts, letters = job
    env = ql.envelope(audio)
    verses = range(1, len(counts) + 1)
    venvs = {a: ql.envelope(verse_dir / f'{surah:03d}{a:03d}.mp3') for a in verses}
    own = {a: ql.own_length(venvs[a]) for a in verses}
    heard = [a for a in verses if own[a]]
    pace = sum(own[a] for a in heard) / sum(letters[a] for a in heard)
    estimated = {a for a in verses if not own[a]}
    for a in estimated:
        own[a] = round(letters[a] * pace)
    speech, how, missing = {}, {}, []
    last_end, guess = 0, 0
    for a in verses:
        venv = venvs[a]
        if a == 1:
            sound = int(np.flatnonzero(env > ql.SPEECH_DB)[0])
            placed = ql.place_verse(env, venv, sound - ql.BACK, sound + ql.OPENING, False)
            if placed is None:
                placed = ql.place_verse(env, venv, sound - ql.BACK, sound + ql.OPENING, True)
                if placed is not None:
                    speech[1], how[1] = placed, 'sound'
                    guess = placed[1]
                    continue
        elif own[a]:
            placed = ql.place_verse(env, venv, last_end - ql.BACK, guess + ql.NEXT_SEARCH, False)
        else:
            placed = None
        if placed is None:
            missing.append(a)
            guess += own[a] + 50
            continue
        speech[a], how[a] = placed, 'sound'
        last_end = guess = placed[1]
    if 1 in speech and 2 in speech and speech[1][1] > speech[2][0]:
        del speech[1], how[1]
        missing.insert(0, 1)
    ratios = [(speech[a][1] - speech[a][0]) / own[a] for a in speech if a > 1]
    for a in missing:
        low, high = (ql.LOW, ql.BRIDGE_HIGH) if a not in estimated else (0.75, 1.33)
        if a > 1 and a - 1 not in speech:
            continue
        after = speech.get(a + 1) if a < len(counts) else (len(env), len(env))
        bridged = ql.bridge(env, own[a], speech.get(a - 1), after, low, high)
        if bridged is not None:
            speech[a], how[a] = bridged, 'bridged'
    # The checks of build_quranlab_timing, per pair of neighbours: a pair
    # that fails loses its placement, the rest of the surah keeps its own.
    dropped = {}
    changed = True
    while changed:
        changed = False
        placed = sorted(speech)
        for p, a in zip(placed, placed[1:]):
            prev, s = speech[p][1], speech[a][0]
            if a == p + 1 and s < prev - ql.OVERLAP:
                why = 'overlap'
            elif a == p + 1 and int((env[prev:s] > ql.SPEECH_DB).sum()) > ql.STRAY:
                why = 'speech between verses'
            elif a != p + 1 and s - prev < 0.75 * sum(own[v] for v in range(p + 1, a)):
                # the verses between them would not fit: the later one
                # was found too early (a similar passage)
                del speech[a], how[a]
                dropped[a] = 'found too early for the verses before it'
                changed = True
                break
            else:
                continue
            for v in (p, a):
                del speech[v], how[v]
                dropped[v] = why
            changed = True
            break
    first_unplaced = {a: 'not found by its sound' for a in missing if a not in speech}
    first_unplaced.update(dropped)
    return (surah, {a: list(map(int, v)) for a, v in speech.items()}, how,
            {a: w for a, w in first_unplaced.items() if a not in speech}, len(env),
            [float(r) for r in ratios], {a: int(own[a]) for a in verses})


# --------------------------------------------- stage 2: forced alignment

def decode(path):
    raw = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', str(path), '-map', '0:a:0', '-ac', '1',
         '-ar', str(SR), '-f', 's16le', '-'], capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768


class Aligner:
    def __init__(self, threads=6):
        import torch
        from transformers import Wav2Vec2ForCTC
        torch.set_num_threads(threads)
        self.torch = torch
        self.model = Wav2Vec2ForCTC.from_pretrained(MODEL_DIR).eval()
        vocab = json.loads((MODEL_DIR / 'vocab.json').read_text(encoding='utf-8'))
        self.vocab = vocab
        self.blank = vocab['<pad>']
        self.sep = vocab['|']
        self.star = len(vocab)

    def emissions(self, audio):
        """Log-probabilities per 20 ms frame (frames x tokens+star)."""
        torch = self.torch
        parts = []
        n = len(audio) // FRAME
        for start in range(0, n * FRAME, CHUNK):
            lo, hi = max(0, start - CONTEXT), min(len(audio), start + CHUNK + CONTEXT)
            x = audio[lo:hi]
            x = (x - x.mean()) / np.sqrt(x.var() + 1e-7)
            with torch.inference_mode():
                logits = self.model(torch.from_numpy(x)[None]).logits[0]
            lp = torch.log_softmax(logits.float(), dim=-1)
            f0 = (start - lo) // FRAME
            take = min(CHUNK, n * FRAME - start) // FRAME
            part = lp[f0:f0 + take]
            if len(part) < take:  # the model's last frame may fall short
                part = torch.cat([part, part[-1:].expand(take - len(part), -1)])
            parts.append(part)
        em = torch.cat(parts)
        star = torch.full((len(em), 1), STAR)
        return torch.cat([em, star], dim=1)

    def align(self, em, verses, tail_star=True):
        """Forced alignment of verses (each a list of words, each a list
        of token ids) over emissions em. Returns, per verse, per word,
        (first frame, last frame + 1, mean probability), or None."""
        torch = self.torch
        import torchaudio.functional as F
        targets, where = [self.star], []
        for v, words in enumerate(verses):
            for w, toks in enumerate(words):
                if w:
                    targets.append(self.sep)
                for t in toks:
                    where.append((v, w))
                    targets.append(t)
            targets.append(self.star)
        if not tail_star:
            targets.pop()
        letter_at = [i for i, t in enumerate(targets) if t not in (self.star, self.sep)]
        repeats = sum(1 for x, y in zip(targets, targets[1:]) if x == y)
        if len(targets) + repeats > len(em):
            return None
        try:
            ali, scores = F.forced_align(em[None], torch.tensor([targets], dtype=torch.int32),
                                         blank=self.blank)
        except RuntimeError:
            return None
        spans = F.merge_tokens(ali[0], scores[0].exp())
        assert len(spans) == len(targets)
        out = [[None] * len(words) for words in verses]
        for i, (v, w) in zip(letter_at, where):
            sp = spans[i]
            cur = out[v][w]
            if cur is None:
                out[v][w] = [sp.start, sp.end, [sp.score]]
            else:
                cur[1] = sp.end
                cur[2].append(sp.score)
        star_frames = [spans[i].end - spans[i].start for i, t in enumerate(targets) if t == self.star]
        return [[(s, e, float(np.mean(p))) for s, e, p in v] for v in out], star_frames


def refine(env, frames, offset_ms, limit_ms):
    """Word (start_ms, end_ms) from token frames: the start moves back to
    the onset when the word follows a quiet moment; the end is where its
    sound stops (QUIET_RUN quiet frames), before the next word."""
    quiet = env < ql.SPEECH_DB
    out = []
    for k, (s, e, _) in enumerate(frames):
        start = offset_ms + s * FRAME_MS
        f = start // HOP
        lo = max(0, f - ONSET)
        q = np.flatnonzero(quiet[lo:f])
        if len(q):
            start = (lo + int(q[-1]) + 1) * HOP
        out.append([start, offset_ms + e * FRAME_MS])
    for k in range(len(out)):
        nxt = out[k + 1][0] if k + 1 < len(out) else limit_ms
        f = out[k][1] // HOP
        stop = nxt // HOP
        run = 0
        end = None
        for j in range(f, max(f, stop)):
            if j < len(quiet) and quiet[j]:
                run += 1
                if run >= QUIET_RUN:
                    end = (j - run + 1) * HOP
                    break
            else:
                run = 0
        out[k][1] = min(nxt, end if end is not None else nxt)
        if k + 1 < len(out) and out[k + 1][0] < out[k][0]:
            out[k + 1][0] = out[k][0]
        out[k][1] = max(out[k][1], out[k][0] + 1)
    return [tuple(map(int, w)) for w in out]


def align_stretch(al, audio, env, lo_ms, hi_ms, verses, own_ms):
    """Words of consecutive verses heard between lo_ms and hi_ms, a few
    verses at a time when the stretch is long. Returns per verse a list of
    (start_ms, end_ms) or None, and per verse the mean letter probability."""
    out = [None] * len(verses)
    conf = [None] * len(verses)
    i, cur = 0, lo_ms
    while i < len(verses):
        total = sum(own_ms[i:])
        if hi_ms - cur <= SINGLE or total <= SINGLE * 0.6:
            j, end, last = len(verses), hi_ms, True
        else:
            j, acc = i, 0
            while j < len(verses) and acc < STEP:
                acc += own_ms[j]
                j += 1
            j = max(j, i + 2) if len(verses) - i >= 2 else len(verses)
            end = min(hi_ms, cur + int(sum(own_ms[i:j]) * 1.4) + 15_000)
            last = end >= hi_ms or j >= len(verses)
        em = al.emissions(audio[cur * SR // 1000:end * SR // 1000])
        got = al.align(em, verses[i:j])
        if got is None:
            return out, conf
        words, _ = got
        # Keep every verse when the stretch ended here; otherwise all but
        # the last, whose end may have been squeezed by the cut.
        keep = j - i if last else max(1, j - i - 1)
        for k in range(keep):
            v = i + k
            limit = end if v + 1 >= len(verses) or k + 1 >= len(words) else cur + words[k + 1][0][0] * FRAME_MS
            out[v] = refine(env, words[k], cur, limit)
            conf[v] = float(np.mean([p for _, _, p in words[k]]))
        if keep == j - i and last:
            break
        # go on from the middle of the pause before the next verse
        nxt = words[keep][0][0]
        prev_end = words[keep - 1][-1][1]
        cur = cur + ((prev_end + nxt) // 2) * FRAME_MS
        i += keep
    return out, conf


# --------------------------------------------------------- the build

def load_inputs():
    db = sqlite3.connect(DB)
    counts, letters, text = {}, {}, {}
    for s, a, n in db.execute('SELECT surah, ayah, COUNT(*) FROM word_box GROUP BY surah, ayah'):
        counts.setdefault(s, {})[a] = n
    for s, a, t, p, clean in db.execute(
            'SELECT surah, number, text, basmala_prefix, text_search FROM ayah'):
        letters.setdefault(s, {})[a] = len(clean.replace(' ', ''))
        text[(s, a)] = (t, p)
    return counts, letters, text


def proportional(segments, count, span_ms):
    """Last resort: QuranLab's word times scaled into the verse's span."""
    if not segments:
        return None
    spans = b.word_spans(segments, count)
    if spans is None:
        return None
    a0, a1 = spans[0][0], spans[-1][1]
    s0, s1 = span_ms
    if a1 <= a0 or s1 <= s0:
        return None
    f = b.mapper([(a0, s0), (a1, s1)])
    return [(round(f(s)), max(round(f(e)), round(f(s)) + 1)) for s, e in spans]


def build(surahs, al):
    counts, letters, text = load_inputs()
    timing = json.loads(QURANLAB.read_text(encoding='utf-8'))
    verse_dir = CACHE / 'everyayah' / FOLDER
    jobs = [(s, CACHE / 'audio' / str(RECITER) / f'{s:03d}.mp3', verse_dir, counts[s], letters[s])
            for s in surahs]
    with ProcessPoolExecutor(6) as pool:
        stage1 = list(pool.map(transfer_surah, jobs))
    ayah_rows, word_rows, report = [], [], {}
    for surah, speech, how, unplaced, n_env, _, own in stage1:
        speech = {int(a): v for a, v in speech.items()}
        audio_path = CACHE / 'audio' / str(RECITER) / f'{surah:03d}.mp3'
        env = ql.envelope(audio_path)
        audio = None
        n = len(counts[surah])
        verses = range(1, n + 1)
        method = {a: how[a] for a in speech}
        conf = {}
        words_ms = {}
        # tokens and the word-box grouping of every verse
        toks, groups = {}, {}
        for a in verses:
            t, p = text[(surah, a)]
            tw, g = tanzil_words(t, p, counts[surah][a])
            groups[a] = g
            toks[a] = [letters_of(w, al.vocab) for w in tw] if al else None
        # Forced alignment over each run of verses not placed by sound.
        runs, a = [], 1
        while a <= n:
            if a in speech:
                a += 1
                continue
            r = a
            while r + 1 <= n and r + 1 not in speech:
                r += 1
            runs.append((a, r))
            a = r + 1
        for a, r in runs:
            if al is None:
                break
            if audio is None:
                audio = decode(audio_path)
            lo = speech[a - 1][1] * HOP if a > 1 else 0
            hi = speech[r + 1][0] * HOP if r < n else len(audio) * 1000 // SR
            run = list(range(a, r + 1))
            got, cf = align_stretch(al, audio, env, lo, hi, [toks[v] for v in run],
                                    [own[v] * HOP for v in run])
            for v, w, c in zip(run, got, cf):
                if w is None:
                    continue
                w = join_groups(w, groups[v])
                if w is None:
                    continue
                words_ms[v] = w
                speech[v] = [w[0][0] // HOP, (w[-1][1] + HOP - 1) // HOP]
                method[v] = 'fa'
                conf[v] = c
        # Verse boundaries: the quietest point before each verse.
        placed = sorted(speech)
        bad_order = [v for p, v in zip(placed, placed[1:]) if speech[v][0] < speech[p][1] - ql.OVERLAP]
        for v in bad_order:
            speech.pop(v, None)
            method.pop(v, None)
            words_ms.pop(v, None)
        if not all(a in speech for a in verses):
            # Verse timing needs every verse of the surah (the app finds the
            # verse playing from the start times); words are kept only where
            # the verses around them are timed.
            missing = [a for a in verses if a not in speech]
            report[surah] = {'untimed': missing, 'why': {a: unplaced.get(a, 'alignment failed') for a in missing}}
            continue
        starts = {}
        for a in verses:
            s = speech[a][0]
            prev = speech[a - 1][1] if a > 1 else 0
            if a == 1 and s < 50:
                starts[a] = 0
            else:
                starts[a] = ql.quietest(env, max(prev, s - ql.LEAD), max(prev + 1, s))
        ends = {a: starts[a + 1] if a < n else n_env for a in verses}
        if starts[1] > 0:
            ayah_rows.append((RECITER, surah, 0, 0, starts[1] * HOP))
        ayah_rows += [(RECITER, surah, a, starts[a] * HOP, ends[a] * HOP) for a in verses]
        # Words of verses placed by sound: QuranLab's, through the anchors.
        aligned = {int(k): v for k, v in timing.get(str(surah), {}).items()}
        for a in verses:
            if method[a] == 'fa':
                continue
            seg = merged_segments(aligned[a], groups[a]) if a in aligned else None
            points = ql.anchors(env, ql.envelope(verse_dir / f'{surah:03d}{a:03d}.mp3'), *speech[a])
            placed_words = ql.place_words(seg, counts[surah][a], points) if seg else None
            if placed_words:
                words_ms[a] = placed_words
                method[a] = 'transfer' if method[a] == 'sound' else 'transfer-bridged'
        # Words by forced alignment inside the verse's own window.
        for a in verses:
            if a in words_ms or al is None:
                continue
            if audio is None:
                audio = decode(audio_path)
            lo, hi = starts[a] * HOP, ends[a] * HOP
            em = al.emissions(audio[lo * SR // 1000:hi * SR // 1000])
            got = al.align(em, [toks[a]])
            w = None
            if got is not None:
                w = join_groups(refine(env, got[0][0], lo, hi), groups[a])
                conf[a] = float(np.mean([p for _, _, p in got[0][0]]))
            if w is not None:
                words_ms[a] = w
                method[a] = 'fa-words'
            elif a in aligned:
                seg = merged_segments(aligned[a], groups[a])
                w = proportional(seg, counts[surah][a], (speech[a][0] * HOP, speech[a][1] * HOP))
                if w is not None:
                    words_ms[a] = w
                    method[a] = 'approx'
        # A verse of one word (most are opening letters, حم, طسم, which the
        # aligner hears poorly: their letters are said by name) is that
        # word: from its first to its last sound inside its window.
        for a in verses:
            if counts[surah][a] == 1 and method.get(a) in ('fa', 'fa-words'):
                lo, hi = starts[a], ends[a]
                loud = np.flatnonzero(env[lo:hi] > ql.SPEECH_DB)
                if len(loud):
                    words_ms[a] = [((lo + int(loud[0])) * HOP, (lo + int(loud[-1]) + 1) * HOP)]
                    method[a] = 'span'
                    conf.pop(a, None)
        rep = {}
        for a in verses:
            w = words_ms.get(a)
            if w is None or len(w) != counts[surah][a]:
                rep[a] = [method.get(a, 'none'), None]
                continue
            lo, hi = starts[a] * HOP, ends[a] * HOP
            w = [(max(lo, s), min(hi, max(e, s + 1))) for s, e in w]
            if any(w[k][0] < w[k - 1][0] for k in range(1, len(w))):
                rep[a] = [method[a], None]
                continue
            word_rows += [(RECITER, surah, a, k, s, e) for k, (s, e) in enumerate(w, start=1)]
            rep[a] = [method[a], round(conf[a], 3) if a in conf else None]
        report[surah] = {'verses': rep, 'unplaced_by_sound': unplaced}
        counts_m = {}
        for m, _ in rep.values():
            counts_m[m] = counts_m.get(m, 0) + 1
        print(f'surah {surah}: {counts_m}', flush=True)
    return ayah_rows, word_rows, report


def join_groups(words, groups):
    """Word times per Tanzil word -> per word box."""
    if groups is None or len(words) != sum(len(g) for g in groups):
        return None
    return [(words[g[0]][0], words[g[-1]][1]) for g in groups]


# ------------------------------------------------------------ checks

def compare(n_verses, al):
    """Forced alignment inside the windows of verses whose QuranLab words
    were carried over by sound, against those words: start differences."""
    counts, _, text = load_inputs()
    words = json.loads(WORD_OUT.read_text(encoding='utf-8'))
    report = json.loads(REPORT.read_text(encoding='utf-8'))
    ayahs = {(r[1], r[2]): (r[3], r[4]) for r in json.loads(AYAH_OUT.read_text(encoding='utf-8'))}
    by = {}
    for _, s, a, k, st, en in words:
        by.setdefault((s, a), []).append(st)
    rng = np.random.default_rng(7)
    pool = [(int(s), int(a)) for s, r in report.items() for a, (m, _) in r.get('verses', {}).items()
            if m == 'transfer']
    pick = sorted(pool[i] for i in rng.choice(len(pool), size=min(n_verses, len(pool)), replace=False))
    diffs, per_surah = [], {}
    audio_cache = {}
    for s, a in pick:
        if s not in audio_cache:
            audio_cache.clear()
            path = CACHE / 'audio' / str(RECITER) / f'{s:03d}.mp3'
            audio_cache[s] = (decode(path), ql.envelope(path))
        audio, env = audio_cache[s]
        lo, hi = ayahs[(s, a)]
        t, p = text[(s, a)]
        tw, g = tanzil_words(t, p, counts[s][a])
        em = al.emissions(audio[lo * SR // 1000:hi * SR // 1000])
        got = al.align(em, [[letters_of(w, al.vocab) for w in tw]])
        if got is None:
            continue
        w = join_groups(refine(env, got[0][0], lo, hi), g)
        ref = sorted(by[(s, a)])
        d = [x[0] - r for x, r in zip(w, ref)]
        diffs += d
    d = np.abs(np.array(diffs))
    print(f'{len(pick)} verses, {len(d)} words: |forced alignment - QuranLab| start: '
          f'median {np.median(d):.0f} ms, 90% {np.percentile(d, 90):.0f} ms, '
          f'95% {np.percentile(d, 95):.0f} ms; within 100 ms {100 * (d <= 100).mean():.1f}%, '
          f'within 250 ms {100 * (d <= 250).mean():.1f}%; signed median {np.median(diffs):.0f} ms')


SOURCE_ID = 19


def source_row(today):
    """content.db source row for the forced alignment (the transferred
    words stay credited to QuranLab, source 12)."""
    return (SOURCE_ID, 'banna-forced-alignment',
            'Verse and word timings of al-Banna (murattal) where QuranLab\'s cannot be carried '
            'over: forced alignment on the mp3quran surah files by Tibyan',
            'Tibyan; model: jonatasgrosman/wav2vec2-large-xlsr-53-arabic', MODEL_REVISION[:12],
            'Apache-2.0 (model); timings by Tibyan',
            f'https://huggingface.co/{MODEL_ID}',
            'محاذاة صوتية لتوقيت البنا: تبيان، بنموذج wav2vec2-large-xlsr-53-arabic (Apache-2.0)',
            None, sha256(WORD_OUT), today)


def sha256(path):
    import hashlib
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def replace(db, ayahs, words):
    """Reciter 4's verse and word rows replaced by these."""
    db.execute('DELETE FROM ayah_timing WHERE reciter = ?', (RECITER,))
    db.execute('DELETE FROM word_timing WHERE reciter = ?', (RECITER,))
    db.executemany('INSERT INTO ayah_timing VALUES (?,?,?,?,?)', ayahs)
    db.executemany('INSERT INTO word_timing VALUES (?,?,?,?,?,?)', words)


def apply():
    """Replace reciter 4's verse, word and speech rows in content.db."""
    import build_ayah_speech as sp
    from datetime import date
    ayahs = json.loads(AYAH_OUT.read_text(encoding='utf-8'))
    words = json.loads(WORD_OUT.read_text(encoding='utf-8'))
    db = sqlite3.connect(DB)
    with db:
        replace(db, ayahs, words)
        db.execute('DELETE FROM source WHERE id = ?', (SOURCE_ID,))
        db.execute('INSERT INTO source VALUES (?,?,?,?,?,?,?,?,?,?,?)',
                   source_row(date.today().isoformat()))
    windows, spans = {}, {}
    for _, s, a, st, en in ayahs:
        windows.setdefault(s, []).append((a, st, en))
    for _, s, a, _, st, en in words:
        lo, hi = spans.get((s, a), (st, en))
        spans[(s, a)] = (min(lo, st), max(hi, en))
    jobs = [(RECITER, s, sorted(w), {a: v for (ss, a), v in spans.items() if ss == s})
            for s, w in sorted(windows.items())]
    rows = []
    with ProcessPoolExecutor(6) as pool:
        for part in pool.map(sp.surah_rows, jobs):
            rows += part
    with db:
        db.execute('DELETE FROM ayah_speech WHERE reciter = ?', (RECITER,))
        db.executemany('INSERT INTO ayah_speech VALUES (?,?,?,?,?)', rows)
    db.execute('VACUUM')
    # keep the cached speech spans in step for the next full build
    path = CACHE / 'ayah_speech.json'
    if path.exists():
        old = [r for r in json.loads(path.read_text(encoding='utf-8')) if r[0] != RECITER]
        path.write_text(json.dumps(sorted(old + [list(r) for r in rows]), separators=(',', ':')),
                        encoding='utf-8')
    print(f'content.db: reciter {RECITER}: {sum(1 for r in ayahs if r[2] > 0)} verses, '
          f'{len(words)} words, {len(rows)} speech spans')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('surahs', nargs='*', type=int)
    ap.add_argument('--compare', type=int)
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--no-align', action='store_true', help='stage 1 only (no model)')
    args = ap.parse_args()
    if args.apply:
        apply()
        return 0
    al = None if args.no_align else Aligner()
    if args.compare:
        compare(args.compare, al)
        return 0
    surahs = args.surahs or list(range(1, 115))
    ayahs, words, report = build(surahs, al)
    done = set(surahs)
    old_a = json.loads(AYAH_OUT.read_text(encoding='utf-8')) if AYAH_OUT.exists() else []
    old_w = json.loads(WORD_OUT.read_text(encoding='utf-8')) if WORD_OUT.exists() else []
    old_r = json.loads(REPORT.read_text(encoding='utf-8')) if REPORT.exists() else {}
    ayahs = sorted([r for r in old_a if r[1] not in done] + [list(r) for r in ayahs])
    words = sorted([r for r in old_w if r[1] not in done] + [list(r) for r in words])
    old_r = {k: v for k, v in old_r.items() if int(k) not in done}
    old_r.update({str(k): v for k, v in report.items()})
    AYAH_OUT.write_text(json.dumps(ayahs, separators=(',', ':')), encoding='utf-8')
    WORD_OUT.write_text(json.dumps(words, separators=(',', ':')), encoding='utf-8')
    REPORT.write_text(json.dumps(old_r, ensure_ascii=False, sort_keys=True), encoding='utf-8')
    timed = sum(1 for r in ayahs if r[2] > 0)
    worded = len({(r[1], r[2]) for r in words})
    methods = {}
    for r in old_r.values():
        for m, _ in r.get('verses', {}).values():
            methods[m] = methods.get(m, 0) + 1
    print(f'reciter {RECITER}: {len({r[1] for r in ayahs})} surahs, {timed} verses timed, '
          f'{worded} with word timing ({len(words)} words); by method: {methods}')
    untimed = {k: v['untimed'] for k, v in old_r.items() if 'untimed' in v}
    if untimed:
        print('surahs without timing:', untimed)
    return 0


if __name__ == '__main__':
    sys.exit(main())
