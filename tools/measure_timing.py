"""Measures recitation timings on the very surah files the app plays, by
forced alignment (tools/build_aligned_timing.py), for the gaps listed in
docs/MISSING_DATA.md: whole surahs with no timing (ث2 Mustafa Ismail,
ث5-ج the riwaya recitations without one, ث4 candidates for review), and
the words of single verses (ث10, ث12, ث13). It is run by
.github/workflows/timing-measure.yml on GitHub's runners (CPU): the model
and the audio are too large for a laptop's patience, not for a runner.
Nothing here publishes anything: the output is files to review in the
editor and merge by a pull request (docs/TIMING.md).

Modes:
  surahs   whole surahs: verse timing and, for a Hafs recitation, word
           timing, as build_aligned_timing.py measures them. A riwaya
           recitation (Warsh, Qalun, al-Duri, Shu'bah) gets verse timing
           only, its verses numbered by the riwaya's own count: the verses
           and text of the app's own riwaya pack (pages-<riwaya>-v1.zip,
           checked against the SHA-256 in lib/features/mushaf/data/
           page_pack.dart; build_riwaya_packs.py), which are the verses
           the app shows and data/timing/verse_words.json counts.
  verses   the words of single verses, inside their verse windows as they
           are (verse boundaries unchanged): the window is cut from the
           surah file and aligned alone, with the same model, stars and
           word rule. A verse that still reads badly (MIN_SCORE) stays
           without words. Windows come from data/timing/<slug>/NNN.json,
           or, for a reciter whose timing is not published (al-Muaiqly),
           from content.db; its words then go to private/, never to
           data/timing.

SPEC, for surahs: "all", "missing" (surahs with no file in
data/timing/<slug>/), or numbers and ranges ("1,9,21-23"). For verses:
"flagged" (verses timed without words), "known" (verses with a word
error in data/timing/known_errors.json), or "S:A,S:A,...".

Usage:
  python3 tools/measure_timing.py fetch-model
  python3 tools/measure_timing.py plan MODE SLUG SPEC --shards N      # JSON list of SPECs
  python3 tools/measure_timing.py run MODE SLUG SPEC --out DIR         # one shard
  python3 tools/measure_timing.py finish MODE SLUG DIR [DIR ...] --out OUT

`finish` assembles the shards into OUT: data/timing/<slug>/NNN.json (whole
new files), data/timing/<slug>/audio.json and data/timing/reciters.json
(the credit, as for the five reciters measured in Tibyan), peaks/<slug>/
(the editor's waveform files, for the server), private/ (words of an
unpublished reciter, for build_content_db.py) and REPORT.md.

Python dependencies (not part of the app): those of build_aligned_timing.py.
"""
import argparse
import hashlib
import json
import os
import re
import sqlite3
import sys
import urllib.request
from datetime import date
from pathlib import Path

import numpy as np

import build_aligned_timing as al
import build_timing_peaks as peaks
import timing_files as tf

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent
CACHE = ROOT / '.cache'
PAGE_PACK_DART = REPO / 'lib' / 'features' / 'mushaf' / 'data' / 'page_pack.dart'
PACKS = 'https://tibyan.ahmedhelal.dev/mirror/packs'
MODEL_HF = 'https://huggingface.co/jonatasgrosman/wav2vec2-large-xlsr-53-arabic/resolve/' + al.MODEL_REVISION
MODEL_MIRROR = 'https://tibyan.ahmedhelal.dev/mirror/sources/wav2vec2-large-xlsr-53-arabic'
MODEL_FILES = ['config.json', 'vocab.json', 'pytorch_model.bin']
MODEL_OPTIONAL = ['preprocessor_config.json', 'special_tokens_map.json', 'tokenizer_config.json']
# pytorch_model.bin, as recorded in docs/DATA_SOURCES.md (a0b26f6d…857b)
MODEL_SHA_ENDS = ('a0b26f6d', '857b')
TOOL = 'tools/measure_timing.py'
MEASURED_BY = ('Tibyan: measured by forced alignment on the surah files played '
               f'(tools/build_aligned_timing.py through {TOOL}, wav2vec2 Arabic model, Apache-2.0)')
LICENCE = 'Tibyan (published here under CC BY 4.0)'


# ------------------------------------------------------------------ fetching

def download(urls, target, user_agent='Tibyan timing measure'):
    """The first of urls that answers, saved to target. Returns the URL."""
    last = None
    for url in urls:
        try:
            req = urllib.request.Request(url, headers={'User-Agent': user_agent})
            tmp = target.with_suffix(target.suffix + '.part')
            target.parent.mkdir(parents=True, exist_ok=True)
            with urllib.request.urlopen(req, timeout=300) as r, open(tmp, 'wb') as f:
                while True:
                    chunk = r.read(1 << 20)
                    if not chunk:
                        break
                    f.write(chunk)
            tmp.rename(target)
            return url
        except Exception as e:  # noqa: BLE001 - try the next host
            last = e
    raise RuntimeError(f'no host served {target.name}: {last}')


def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def fetch_model():
    """The model files of MODEL_REVISION into tools/.cache, from Hugging Face
    (the pinned revision), else from Tibyan's mirror; checked against the
    mirror's SHA256SUMS when it answers, and the weights always against the
    hash recorded in docs/DATA_SOURCES.md."""
    al.MODEL.mkdir(parents=True, exist_ok=True)
    for name in MODEL_FILES + MODEL_OPTIONAL:
        target = al.MODEL / name
        if target.exists():
            continue
        try:
            print(name, 'from', download([f'{MODEL_HF}/{name}', f'{MODEL_MIRROR}/{name}'], target), flush=True)
        except RuntimeError:
            if name in MODEL_FILES:
                raise
    sums = {}
    try:
        with urllib.request.urlopen(f'{MODEL_MIRROR}/SHA256SUMS', timeout=60) as r:
            for line in r.read().decode().splitlines():
                parts = line.split()
                if len(parts) == 2:
                    sums[parts[1].lstrip('*').split('/')[-1]] = parts[0]
    except Exception as e:  # noqa: BLE001 - the mirror is a second check only
        print(f'mirror SHA256SUMS not read ({e}); checking the weights only', flush=True)
    for name, want in sums.items():
        if (al.MODEL / name).exists():
            got = sha256(al.MODEL / name)
            assert got == want, f'{name}: {got}, the mirror has {want}'
    got = sha256(al.MODEL / 'pytorch_model.bin')
    assert got.startswith(MODEL_SHA_ENDS[0]) and got.endswith(MODEL_SHA_ENDS[1]), got
    print(f'model {al.MODEL_REVISION}: ok (weights {got})')


def reciter(slug):
    r = {x['slug']: x for x in tf.reciters()}.get(slug)
    if r is None:
        raise SystemExit(f'{slug}: not in data/timing/reciters.json')
    return r


def fetch_audio(r, surah):
    """The surah file as the app plays it (Tibyan's mirror, then the
    source: build_timing_peaks.surah_urls), in tools/.cache/audio/<id>/.
    Returns (path, host)."""
    target = CACHE / 'audio' / str(r['id']) / f'{surah:03d}.mp3'
    host_file = target.with_suffix('.host')
    if target.exists():
        return target, host_file.read_text().strip() if host_file.exists() else ''
    url = download(peaks.surah_urls(r['folder_url'], surah), target)
    host_file.write_text(url.split('/')[2])
    return target, url.split('/')[2]


# ---------------------------------------------------------------- the text

def pack_sha(riwaya):
    """The SHA-256 the app expects of pages-<riwaya>-v1.zip (page_pack.dart)."""
    text = PAGE_PACK_DART.read_text(encoding='utf-8')
    m = re.search(r"_riwaya\(\s*'" + re.escape(riwaya) + r"',\s*'([0-9a-f]{64})'", text)
    if not m:
        raise SystemExit(f'{riwaya}: no pack hash in {PAGE_PACK_DART}')
    return m.group(1)


def riwaya_verses(riwaya):
    """{surah: {ayah: text}} of a riwaya, from the app's own pack (the
    verses it shows, numbered by the riwaya's count), checked against
    verse_words.json. The text is only read."""
    import lzma
    import zipfile
    path = CACHE / 'riwayat' / 'packs' / f'pages-{riwaya}-v1.zip'
    want = pack_sha(riwaya)
    if not path.exists() or sha256(path) != want:
        download([f'{PACKS}/pages-{riwaya}-v1.zip'], path)
    got = sha256(path)
    assert got == want, f'pages-{riwaya}-v1.zip: {got}, the app expects {want}'
    with zipfile.ZipFile(path) as z:
        data = json.loads(lzma.decompress(z.read('riwaya.json.xz')))
    out = {}
    for s, a, _page, _juz, _hf, _ht, text in data['verses']:
        out.setdefault(s, {})[a] = text
    counts = tf.load_json(tf.DATA / 'verse_words.json')['riwayat'][riwaya]
    for s in range(1, 115):
        assert sorted(out[s]) == list(range(1, counts[s - 1] + 1)), (riwaya, s)
    return out


def text_for(r):
    """({surah: {ayah: [word, ...]}}, opening(surah) -> words or None)."""
    if r['riwaya'] == 'hafs':
        db = sqlite3.connect(f'file:{al.DB}?mode=ro', uri=True)
        text = al.load_text(db)
        db.close()
        basmala = text[1][1]
        return text, (lambda s: None if s in (1, 9) else basmala)
    verses = riwaya_verses(r['riwaya'])
    text = {s: {a: al.words_of(t) for a, t in vs.items()} for s, vs in verses.items()}
    # The riwaya files are not read for a basmala unit: whether the reciter
    # says it (or joins the surahs) the first star takes what comes before
    # verse 1. In Shu'bah's al-Fatiha the basmala is verse 1, as in the text.
    return text, (lambda s: None)


# ------------------------------------------------------------------- specs

def parse_surahs(spec, slug):
    spec = spec.strip()
    if spec == 'all':
        return list(range(1, 115))
    if spec == 'missing':
        have = {int(p.stem) for p in (tf.DATA / slug).glob('[0-9][0-9][0-9].json')}
        return [s for s in range(1, 115) if s not in have]
    out = []
    for part in spec.replace(' ', '').split(','):
        if not part:
            continue
        a, _, b = part.partition('-')
        out += range(int(a), int(b or a) + 1)
    assert all(1 <= s <= 114 for s in out), spec
    return sorted(set(out))


def windows(r):
    """{(surah, ayah): (start_ms, end_ms, has words)} of a reciter's timed
    verses: its data/timing files, or content.db when not published."""
    out = {}
    if r.get('publish'):
        for path in sorted((tf.DATA / r['slug']).glob('[0-9][0-9][0-9].json')):
            doc = tf.load_json(path)
            for a, start, end, words in doc['verses']:
                if a > 0:
                    out[(doc['surah'], a)] = (start, end, bool(words))
        return out
    db = sqlite3.connect(f'file:{al.DB}?mode=ro', uri=True)
    have = {(s, a) for s, a in db.execute('SELECT DISTINCT surah, ayah FROM word_timing WHERE reciter = ?',
                                          (r['id'],))}
    for s, a, start, end in db.execute('SELECT surah, ayah, start_ms, end_ms FROM ayah_timing '
                                       'WHERE reciter = ? AND ayah > 0', (r['id'],)):
        out[(s, a)] = (start, end, (s, a) in have)
    db.close()
    return out


def parse_verses(spec, r):
    spec = spec.strip()
    if spec == 'flagged':
        return sorted(k for k, (_, _, has) in windows(r).items() if not has)
    if spec == 'known':
        # words that start before the previous one ends: re-measured inside
        # the verse (a verse past the end of its audio needs its surah measured)
        return sorted({(s, a) for slug, s, a, w, code in tf.known_errors()
                       if slug == r['slug'] and code == 'word_overlap'})
    out = []
    for part in spec.replace(' ', '').split(','):
        if part:
            s, a = part.split(':')
            out.append((int(s), int(a)))
    return sorted(set(out))


def spec_items(mode, r, spec):
    return parse_surahs(spec, r['slug']) if mode == 'surahs' else parse_verses(spec, r)


def plan(mode, r, spec, shards):
    """The spec split into at most [shards] parts of about the same work
    (Hafs words per surah as the measure; a surah stays in one part)."""
    items = spec_items(mode, r, spec)
    size = {s: sum(c) for s, c in tf.verse_words().items()}
    if mode == 'surahs':
        groups = {s: [s] for s in items}
        weight = {s: size[s] for s in items}
    else:
        groups = {}
        for s, a in items:
            groups.setdefault(s, []).append((s, a))
        weight = {s: len(v) * 30 for s, v in groups.items()}
    parts = [[] for _ in range(max(1, min(shards, len(groups))))]
    load = [0] * len(parts)
    for s in sorted(groups, key=lambda k: -weight[k]):
        i = load.index(min(load))
        parts[i] += groups[s]
        load[i] += weight[s]
    out = []
    for p in parts:
        if not p:
            continue
        if mode == 'surahs':
            out.append(','.join(str(s) for s in sorted(p)))
        else:
            out.append(','.join(f'{s}:{a}' for s, a in sorted(p)))
    return out


# --------------------------------------------------------------- measuring

def audio_facts(path, host):
    """(peaks bytes, {duration_ms, bytes, sha256, host}) as build_timing_peaks writes them."""
    mp3 = Path(path).read_bytes()
    pk, duration = peaks.peaks_of(mp3)
    return pk, {'duration_ms': duration, 'bytes': len(mp3), 'sha256': hashlib.sha256(mp3).hexdigest(),
                'host': host}


def doc_of(slug, surah, rows, words, riwaya):
    by = {}
    for a, w, start, end in words:
        by.setdefault(a, []).append([w, start, end])
    verses = []
    for a, start, end in rows:
        verses.append([a, start, end, [] if (riwaya or a == 0) else sorted(by.get(a, []))])
    return {'format': tf.FORMAT, 'reciter': slug, 'surah': surah, 'verses': verses}


def run_surahs(r, surahs, out):
    out.mkdir(parents=True, exist_ok=True)
    import torch
    torch.set_num_threads(os.cpu_count() or 2)
    text, opening = text_for(r)
    riwaya = r['riwaya'] != 'hafs'
    result = {'mode': 'surahs', 'slug': r['slug'], 'surahs': {}}
    fetched = []
    for s in surahs:
        try:
            path, host = fetch_audio(r, s)
        except RuntimeError as e:
            result['surahs'][str(s)] = {'error': str(e)}
            continue
        fetched.append(s)
        pk, facts = audio_facts(path, host)
        (out / 'peaks' / r['slug']).mkdir(parents=True, exist_ok=True)
        (out / 'peaks' / r['slug'] / f'{s:03d}.bin').write_bytes(pk)
        result['surahs'][str(s)] = {'audio': facts}
    al.emit(r['id'], fetched)
    aligned_path = out / f'aligned_{r["id"]}.json'
    al.align(r['id'], fetched, text=text, opening=opening, out_path=aligned_path)
    aligned = json.loads(aligned_path.read_text(encoding='utf-8')) if aligned_path.exists() else {}
    for s in fetched:
        entry = result['surahs'][str(s)]
        got = aligned.get(str(s))
        if got is None:
            entry['error'] = 'not aligned'
            continue
        doc = doc_of(r['slug'], s, got['verses'], got['words'], riwaya)
        entry['verses'] = sum(1 for v in doc['verses'] if v[0] > 0)
        entry['with_words'] = sum(1 for v in doc['verses'] if v[3])
        entry['flagged'] = got['flagged'] if not riwaya else []
        target = out / 'timing' / r['slug'] / f'{s:03d}.json'
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(tf.dumps(doc), encoding='utf-8')
    (out / 'result.json').write_text(json.dumps(result, indent=1, ensure_ascii=False), encoding='utf-8')
    return result


def measure_verse(model, device, a16, env, heard, ids, words, start_ms, end_ms):
    """Word rows [(word, start, end)] of one verse heard in a16 (the surah,
    16 kHz) between start_ms and end_ms, or (None, why)."""
    lo = start_ms - start_ms % al.FRAME_MS
    rate = al.RATE // 1000
    ctx = al.CONTEXT_S * al.RATE
    seg = a16[lo * rate:end_ms * rate]
    if len(seg) < al.RATE // 2:
        return None, 'window too short'
    e = al.emissions(model, device, seg, a16[max(0, lo * rate - ctx):lo * rate],
                     a16[end_ms * rate:end_ms * rate + ctx])
    v = al.align_verse(e, words, ids)
    if v is None:
        return None, 'window too short for its letters'
    off = lo // al.FRAME_MS
    v = [(s + off, z + off, sc) for s, z, sc in v]
    score = float(np.mean([w[2] for w in v]))
    if score < al.MIN_SCORE and len(v) == 1:
        span = al.loud_span(env, start_ms, end_ms)
        if span:
            return [(1, *span)], f'one word: its sound (score {score:.2f})'
    if score < al.MIN_SCORE:
        return None, f'mean letter log-probability {score:.2f}'
    spans = al.word_spans(v, start_ms, end_ms, heard)
    if spans is None:
        return None, 'words out of order'
    return [(k + 1, a, z) for k, (a, z) in enumerate(spans)], f'score {score:.2f}'


def run_verses(r, verses, out):
    out.mkdir(parents=True, exist_ok=True)
    import torch
    torch.set_num_threads(os.cpu_count() or 2)
    if r['riwaya'] != 'hafs':
        raise SystemExit('verses: riwaya recitations are timed by verse only')
    text, _ = text_for(r)
    win = windows(r)
    ids = al.vocab()
    model, device = al.load_model()
    result = {'mode': 'verses', 'slug': r['slug'], 'verses': {}, 'surahs': {}}
    rows = []
    by_surah = {}
    for s, a in verses:
        by_surah.setdefault(s, []).append(a)
    for s, ayahs in sorted(by_surah.items()):
        try:
            path, host = fetch_audio(r, s)
        except RuntimeError as e:
            for a in ayahs:
                result['verses'][f'{s}:{a}'] = {'error': str(e)}
            continue
        _, facts = audio_facts(path, host)
        result['surahs'][str(s)] = {'audio': facts}
        a16 = al.audio(path)
        env, _sm, heard = al.listen(path)
        doc = tf.load_json(tf.surah_path(r['slug'], s)) if r.get('publish') else None
        for a in ayahs:
            if (s, a) not in win:
                result['verses'][f'{s}:{a}'] = {'error': 'verse not timed'}
                continue
            start, end, _ = win[(s, a)]
            words, why = measure_verse(model, device, a16, env, heard, ids, text[s][a], start, end)
            result['verses'][f'{s}:{a}'] = {'words': None if words is None else len(words), 'why': why}
            print(f'{r["slug"]} {s}:{a}: {why}', flush=True)
            if words is None:
                continue
            if doc is not None:
                for v in doc['verses']:
                    if v[0] == a:
                        v[3] = [list(w) for w in words]
            else:
                rows += [[r['id'], s, a, k, ws, we] for k, ws, we in words]
        if doc is not None:
            target = out / 'timing' / r['slug'] / f'{s:03d}.json'
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(tf.dumps(doc), encoding='utf-8')
    if not r.get('publish') and rows:
        (out / 'private').mkdir(parents=True, exist_ok=True)
        (out / 'private' / f'aligned_words_{r["id"]}.json').write_text(json.dumps(rows), encoding='utf-8')
    (out / 'result.json').write_text(json.dumps(result, indent=1, ensure_ascii=False), encoding='utf-8')
    return result


# ------------------------------------------------------------------ finish

def write_audio_json(path, files, measured):
    lines = ['{', '  "format": 1,', '  "measured": %s,' % json.dumps(measured),
             '  "peaks_per_second": %d,' % (peaks.RATE // peaks.HOP), '  "files": {']
    keys = sorted(files)
    for i, k in enumerate(keys):
        lines.append('    %s: %s%s' % (json.dumps(k), json.dumps(files[k]), ',' if i < len(keys) - 1 else ''))
    lines += ['  }', '}']
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text('\n'.join(lines) + '\n', encoding='utf-8')


def credit(doc, slug, mode, surahs, verses, words, today):
    """reciters.json with the measured parts credited as the five reciters
    measured in Tibyan are: Tibyan's work, CC BY 4.0 here."""
    r = next(x for x in doc['reciters'] if x['slug'] == slug)
    measured_all = mode == 'surahs' and not r.get('publish')
    if measured_all:
        # A recitation with no published timing: all of it is ours now.
        r['verse_timing'] = {
            'source': MEASURED_BY + '; each boundary at the quietest point of the pause between the verses'
                      + ('; verses numbered by the riwaya\'s own count' if r['riwaya'] != 'hafs' else ''),
            'licence': LICENCE, 'attribution': 'Tibyan'}
        if words:
            r['word_timing'] = {'source': f'Tibyan: measured with the verses ({TOOL})',
                                'licence': LICENCE, 'attribution': 'Tibyan'}
        r['publish'] = True
        r['note'] = (f'Measured {today} on the surah files played ({TOOL}, docs/TIMING.md); '
                     f'surahs {compact(surahs)}.')
        return doc
    m = r.setdefault('measured', {'by': MEASURED_BY, 'licence': LICENCE, 'attribution': 'Tibyan'})
    if mode == 'surahs':
        m['surahs'] = sorted(set(m.get('surahs', [])) | set(surahs))
        parts = ['verse_timing'] + (['word_timing'] if words else [])
    else:
        old = {tuple(map(int, k.split(':'))) for k in m.get('word_verses', [])}
        m['word_verses'] = [f'{s}:{a}' for s, a in sorted(old | set(verses))]
        parts = ['word_timing']
    m['date'] = today
    for key in parts:
        t = r.get(key)
        if t is None:
            r[key] = {'source': f'Tibyan: measured ({TOOL}); see "measured"', 'licence': LICENCE,
                      'attribution': 'Tibyan'}
        elif 'Tibyan' not in t['attribution']:
            t['attribution'] += ' · Tibyan (measured parts: see "measured")'
    return doc


def compact(numbers):
    out, run = [], []
    for n in sorted(numbers):
        if run and n == run[-1] + 1:
            run.append(n)
            continue
        if run:
            out.append(f'{run[0]}-{run[-1]}' if len(run) > 1 else str(run[0]))
        run = [n]
    if run:
        out.append(f'{run[0]}-{run[-1]}' if len(run) > 1 else str(run[0]))
    return ','.join(out)


def dumps_reciters(doc):
    return json.dumps(doc, ensure_ascii=False, indent=2) + '\n'


def finish(mode, slug, shard_dirs, out):
    import shutil
    r = reciter(slug)
    today = date.today().isoformat()
    out = Path(out)
    results, files, audio, private = [], {}, {}, []
    for d in map(Path, shard_dirs):
        if (d / 'result.json').exists():
            results.append(json.loads((d / 'result.json').read_text(encoding='utf-8')))
        for p in sorted((d / 'timing' / slug).glob('[0-9][0-9][0-9].json')):
            files[int(p.stem)] = p
        for p in sorted((d / 'peaks' / slug).glob('*.bin')):
            (out / 'peaks' / slug).mkdir(parents=True, exist_ok=True)
            shutil.copy2(p, out / 'peaks' / slug / p.name)
        for p in sorted((d / 'private').glob('aligned_words_*.json')):
            private += json.loads(p.read_text(encoding='utf-8'))
    for res in results:
        for s, e in res.get('surahs', {}).items():
            if 'audio' in e:
                audio[f'{int(s):03d}'] = e['audio']
    # audio.json: the repository's, with the files measured here added or
    # updated. A file whose bytes differ from the recorded ones (any timing
    # not measured here was measured on other bytes) is updated and named
    # in the report.
    have_path = tf.DATA / slug / 'audio.json'
    have = tf.load_json(have_path)['files'] if have_path.exists() else {}
    changed_audio = {k: (have[k]['sha256'], v['sha256']) for k, v in audio.items()
                     if k in have and have[k]['sha256'] != v['sha256']}
    merged = dict(have)
    for k, v in audio.items():
        if k not in have or k in changed_audio:
            merged[k] = v
    if merged != have:
        write_audio_json(out / 'data' / 'timing' / slug / 'audio.json', merged, today)
    durations = {int(k): v['duration_ms'] for k, v in merged.items()}
    # the timing files, checked as CI will check them
    issues = {}
    for s, p in sorted(files.items()):
        target = out / 'data' / 'timing' / slug / p.name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(p, target)
        doc = tf.load_json(target)
        issues[s] = tf.validate(doc, slug, s, tf.counts_for(slug, s), durations.get(s))
    if private:
        (out / 'private').mkdir(parents=True, exist_ok=True)
        (out / 'private' / f'aligned_words_{r["id"]}.json').write_text(
            json.dumps(sorted(private)), encoding='utf-8')
    surahs = sorted(files) if mode == 'surahs' else []
    verses = []
    for res in results:
        for k, v in res.get('verses', {}).items():
            if v.get('words'):
                verses.append(tuple(map(int, k.split(':'))))
    words = any(v[3] for p in files.values() for v in tf.load_json(p)['verses'])
    if (surahs or verses) and r['licence'] == 'publishable':
        doc = credit(tf.load_json(tf.DATA / 'reciters.json'), slug, mode, surahs, sorted(verses), words, today)
        (out / 'data' / 'timing').mkdir(parents=True, exist_ok=True)
        (out / 'data' / 'timing' / 'reciters.json').write_text(dumps_reciters(doc), encoding='utf-8')
    report = report_md(r, mode, results, issues, changed_audio, private)
    (out / 'REPORT.md').write_text(report, encoding='utf-8')
    (out / 'report.json').write_text(json.dumps(
        {'slug': slug, 'mode': mode, 'results': results, 'changed_audio': changed_audio,
         'issues': {str(k): v for k, v in issues.items()}}, indent=1, ensure_ascii=False), encoding='utf-8')
    print(report)
    errors = sum(1 for v in issues.values() for i in v if i['level'] == 'error')
    return 1 if errors else 0


def report_md(r, mode, results, issues, changed_audio, private):
    lines = [f'# Measured timings: {r["name_en"]} ({r["slug"]}, {r["riwaya"]}), {mode}', '',
             f'Tool: `{TOOL}` with `tools/build_aligned_timing.py`, model revision `{al.MODEL_REVISION}`. '
             'Review every file in the timing editor before merging (docs/TIMING.md).', '']
    if mode == 'surahs':
        lines += ['| surah | verses | with words | flagged (verse timing only) | audio host | check |',
                  '|---|---|---|---|---|---|']
        rows = {}
        for res in results:
            rows.update({int(k): v for k, v in res['surahs'].items()})
        for s, e in sorted(rows.items()):
            if 'error' in e:
                lines.append(f'| {s} | — | — | — | — | not measured: {e["error"]} |')
                continue
            errs = [i for i in issues.get(s, []) if i['level'] == 'error']
            flagged = ', '.join(f'{a}' for a, _ in e.get('flagged', [])) or '—'
            lines.append(f'| {s} | {e["verses"]} | {e["with_words"]} | {flagged} | {e["audio"]["host"]} | '
                         + ('ok' if not errs else '; '.join(f'{i["code"]} {i["verse"]}' for i in errs[:5])) + ' |')
    else:
        done = failed = 0
        lines += ['| verse | result |', '|---|---|']
        for res in results:
            for k, v in sorted(res['verses'].items(), key=lambda kv: tuple(map(int, kv[0].split(':')))):
                ok = bool(v.get('words'))
                done += ok
                failed += not ok
                lines.append(f'| {k} | ' + (f'{v["words"]} words ({v["why"]})' if ok
                                            else f'stays without words: {v.get("why") or v.get("error")}') + ' |')
        lines += ['', f'{done} verses measured, {failed} left without words.']
        if private:
            lines += ['', f'Words of an unpublished reciter: `private/aligned_words_{r["id"]}.json` '
                          f'({len(private)} rows), for tools/.cache (build_content_db.py), never data/timing.']
    if changed_audio:
        lines += ['', '**The audio differs from data/timing/<slug>/audio.json** (its record, and any timing '
                      'not measured here, are of other bytes; audio.json and the peaks are updated): '
                      + ', '.join(sorted(changed_audio))]
    return '\n'.join(lines) + '\n'


# --------------------------------------------------------------------- cli

def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    sub.add_parser('fetch-model')
    for name in ('plan', 'run'):
        c = sub.add_parser(name)
        c.add_argument('mode', choices=['surahs', 'verses'])
        c.add_argument('slug')
        c.add_argument('spec')
        if name == 'plan':
            c.add_argument('--shards', type=int, default=6)
        else:
            c.add_argument('--out', required=True)
    f = sub.add_parser('finish')
    f.add_argument('mode', choices=['surahs', 'verses'])
    f.add_argument('slug')
    f.add_argument('shards', nargs='+')
    f.add_argument('--out', required=True)
    args = p.parse_args(argv)
    if args.cmd == 'fetch-model':
        fetch_model()
        return 0
    r = reciter(args.slug)
    if args.cmd == 'plan':
        print(json.dumps(plan(args.mode, r, args.spec, args.shards)))
        return 0
    if args.cmd == 'run':
        out = Path(args.out)
        out.mkdir(parents=True, exist_ok=True)
        items = spec_items(args.mode, r, args.spec)
        if args.mode == 'surahs':
            if r['licence'] != 'publishable':
                raise SystemExit(f'{r["slug"]}: its timing may not be published; measure its verses instead')
            run_surahs(r, items, out)
        else:
            run_verses(r, items, out)
        return 0
    return finish(args.mode, args.slug, args.shards, args.out)


if __name__ == '__main__':
    sys.exit(main())
