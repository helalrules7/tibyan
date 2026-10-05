"""The verse-level index of AQQD qiraat clips (MISSING_DATA ن2), kept as
text in `data/qiraat_audio/` so contributors can add, in a pull request,
where the differing word sits inside a clip.

AQQD (Annotated Quranic Qira'at Dataset, OSF project 6sh5d) names each clip
    R023_S5_Surah_036_Aya40_C2.wav = reciter 23, style 5, surah 36, verse 40, clip 2
and has no other metadata: a clip is a verse (or part of one) recited in one
style. The index holds no audio and no Quran text, only where each clip is
(OSF path and download URL), its size and duration, its provenance group
(which decides its licence), and contributor word ranges:

    data/qiraat_audio/index/036.json
    {
      "format": 1,
      "surah": 36,
      "verses": {
        "40": {
          "S5": [
            {"file": "R023_S5_Surah_036_Aya40_C2.wav", "reciter": "R023", "clip": 2, ...,
             "words": [{"range": [1830, 2410, 3], "by": "alice", "reviewed_by": "bob"}]}
          ]
        }
      }
    }

One clip per line. A word range is [start_ms, end_ms, word]: milliseconds
from the start of the clip, and the word's number in the verse as in
content.db's word_box (KFGQPC Hafs words, the hizb sign not counted; the
counts are in data/timing/verse_words.json). "by" is who measured it,
"reviewed_by" the second person who listened and approved it; the app
plays a range only once it has a reviewer.

data/qiraat_audio/styles.json maps style codes to qiraat (filled by hand
from the paper; null = unknown), provenance.json the groups and which
reciter belongs to which.

Usage:
  python3 tools/qiraat_audio.py listing                 OSF file listing (measure_aqqd_coverage.py)
  python3 tools/qiraat_audio.py build [--listing PATH]  index files from the listing (keeps word ranges)
  python3 tools/qiraat_audio.py durations [SURAH...]    exact durations from each WAV header (HTTP range)
  python3 tools/qiraat_audio.py check [FILES...]        validates the index (CI)
  python3 tools/qiraat_audio.py format [FILES...]       rewrites files in the canonical layout
"""
import argparse
import json
import re
import struct
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent
DATA = REPO / 'data' / 'qiraat_audio'
INDEX = DATA / 'index'
VERSE_WORDS = REPO / 'data' / 'timing' / 'verse_words.json'
LISTING = ROOT / '.cache' / 'staging' / 'aqqd' / 'listing.json'
FORMAT = 1
NAME_RE = re.compile(r'^R(\d+)_S(\d+)_Surah_(\d+)_Aya_?(\d+)_C(\d+)\.wav$', re.I)
FILE_RE = re.compile(r'(?:^|/)index/(\d{3})\.json$')
STYLE_RE = re.compile(r'^S\d+$')
URL_RE = re.compile(r'^https://(osf\.io|files\.osf\.io|files\.[a-z0-9.-]+\.osf\.io)/')
# AQQD's WAV format (paper): 44.1 kHz, 16-bit, mono. A file's size gives an
# upper bound on its duration (the header only makes the audio shorter).
BYTES_PER_SECOND = 44100 * 2
CLIP_KEYS = ('file', 'reciter', 'clip', 'path', 'url', 'size', 'duration_ms', 'group', 'words')
USER_AGENT = 'tibyan-tools/0.1'


# ------------------------------------------------------------------ data

def load_json(path):
    return json.loads(Path(path).read_text(encoding='utf-8'))


def verse_words(path=VERSE_WORDS):
    """[[words per verse] per surah], Hafs."""
    return load_json(path)['surahs']


def parse_name(name):
    """(reciter code 'R023', style 'S5', surah, ayah, clip) or None."""
    m = NAME_RE.match(name)
    if not m:
        return None
    r, s, su, a, c = m.groups()
    return f'R{r}', f'S{int(s)}', int(su), int(a), int(c)


def clip_sort_key(c):
    p = parse_name(c['file'])
    return (int(p[0][1:]), p[4], c['file']) if p else (1 << 30, 0, c['file'])


def dumps(doc):
    """The canonical text of an index file: one clip per line."""
    lines = ['{', f'  "format": {FORMAT},', f'  "surah": {int(doc["surah"])},', '  "verses": {']
    verses = sorted(doc['verses'].items(), key=lambda kv: int(kv[0]))
    for vi, (ayah, styles) in enumerate(verses):
        lines.append(f'    {json.dumps(str(ayah))}: {{')
        items = sorted(styles.items(), key=lambda kv: int(kv[0][1:]))
        for si, (style, clips) in enumerate(items):
            lines.append(f'      {json.dumps(style)}: [')
            clips = sorted(clips, key=clip_sort_key)
            for ci, c in enumerate(clips):
                ordered = {k: c.get(k) for k in CLIP_KEYS}
                ordered.update({k: v for k, v in c.items() if k not in ordered})
                comma = ',' if ci < len(clips) - 1 else ''
                lines.append('        ' + json.dumps(ordered, ensure_ascii=False) + comma)
            lines.append('      ]' + (',' if si < len(items) - 1 else ''))
        lines.append('    }' + (',' if vi < len(verses) - 1 else ''))
    lines += ['  }', '}']
    return '\n'.join(lines) + '\n'


def index_path(surah, root=INDEX):
    return Path(root) / f'{surah:03d}.json'


# ------------------------------------------------------------------ build

def clip_url(entry):
    if entry.get('download'):
        return entry['download']
    if entry.get('id'):
        return f'https://osf.io/download/{entry["id"]}/'
    return None


def build(listing, provenance, root=INDEX):
    """Writes index files from an OSF listing ([{name, path, size, id,
    download}]), keeping each known clip's duration and word ranges. The
    group of every clip is set again from provenance.json's reciters.
    Returns (files written, clips, names skipped)."""
    reciters = provenance.get('reciters', {})
    by_surah, skipped = {}, []
    for e in listing:
        p = parse_name(Path(e.get('name', '')).name)
        url = clip_url(e)
        if not p or not url:
            skipped.append(e.get('name', ''))
            continue
        reciter, style, surah, ayah, clip = p
        by_surah.setdefault(surah, []).append((ayah, style, {
            'file': Path(e['name']).name, 'reciter': reciter, 'clip': clip,
            'path': e.get('path'), 'url': url, 'size': e.get('size'),
            'duration_ms': None, 'group': reciters.get(reciter, 'unknown'), 'words': []}))
    written = clips = 0
    Path(root).mkdir(parents=True, exist_ok=True)
    for surah, rows in sorted(by_surah.items()):
        path = index_path(surah, root)
        old = {}
        if path.exists():
            for styles in load_json(path)['verses'].values():
                for cs in styles.values():
                    for c in cs:
                        old[c['file']] = c
        verses = {}
        for ayah, style, c in rows:
            prev = old.pop(c['file'], None)
            if prev:
                c['duration_ms'] = prev.get('duration_ms')
                c['words'] = prev.get('words') or []
            verses.setdefault(str(ayah), {}).setdefault(style, []).append(c)
            clips += 1
        for gone in old.values():  # a clip with word ranges is never dropped silently
            if gone.get('words'):
                print(f'{gone["file"]}: no longer in the listing but has word ranges; kept', file=sys.stderr)
                p = parse_name(gone['file'])
                verses.setdefault(str(p[3]), {}).setdefault(p[1], []).append(gone)
        text = dumps({'surah': surah, 'verses': verses})
        if not path.exists() or path.read_text(encoding='utf-8') != text:
            path.write_text(text, encoding='utf-8')
            written += 1
    return written, clips, skipped


# ------------------------------------------------------------------ durations

def wav_duration_ms(head):
    """The duration in ms that a WAV file's header declares, from its first
    bytes (fmt and the data chunk's size), or None."""
    if len(head) < 12 or head[:4] != b'RIFF' or head[8:12] != b'WAVE':
        return None
    pos, byte_rate = 12, None
    while pos + 8 <= len(head):
        cid, size = head[pos:pos + 4], struct.unpack('<I', head[pos + 4:pos + 8])[0]
        if cid == b'fmt ' and pos + 16 <= len(head):
            byte_rate = struct.unpack('<I', head[pos + 16:pos + 20])[0]
        elif cid == b'data':
            return size * 1000 // byte_rate if byte_rate else None
        pos += 8 + size + (size & 1)
    return None


def fetch_head(url, n=8192):
    req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT, 'Range': f'bytes=0-{n - 1}'})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read(n)


def durations(surahs=None, root=INDEX, fetch=fetch_head):
    """Fills duration_ms of clips that have none, from their WAV headers."""
    filled = 0
    for path in sorted(Path(root).glob('[0-9][0-9][0-9].json')):
        if surahs and int(path.stem) not in surahs:
            continue
        doc, changed = load_json(path), False
        for styles in doc['verses'].values():
            for cs in styles.values():
                for c in cs:
                    if c.get('duration_ms') is None:
                        ms = wav_duration_ms(fetch(c['url']))
                        if ms:
                            c['duration_ms'], changed = ms, True
                            filled += 1
        if changed:
            path.write_text(dumps(doc), encoding='utf-8')
    return filled


# ------------------------------------------------------------------ check

def validate(doc, surah, counts, styles, provenance):
    """Errors in one index file, as strings."""
    errs = []
    if doc.get('format') != FORMAT:
        errs.append(f'format must be {FORMAT}')
    if doc.get('surah') != surah:
        errs.append(f'surah must be {surah} (the file name)')
    verses = doc.get('verses')
    if not isinstance(verses, dict):
        return errs + ['verses must be an object']
    groups = provenance.get('groups', {})
    reciters = provenance.get('reciters', {})
    seen = set()
    for ayah_key, by_style in verses.items():
        where = f'{surah}:{ayah_key}'
        if not re.fullmatch(r'[1-9]\d*', str(ayah_key)):
            errs.append(f'{where}: verse key must be a number')
            continue
        ayah = int(ayah_key)
        if not (1 <= surah <= len(counts) and ayah <= len(counts[surah - 1])):
            errs.append(f'{where}: no such verse')
            continue
        nwords = counts[surah - 1][ayah - 1]
        if not isinstance(by_style, dict):
            errs.append(f'{where}: must be an object of styles')
            continue
        for style, clips in by_style.items():
            w = f'{where} {style}'
            if not STYLE_RE.match(style) or style not in styles:
                errs.append(f'{w}: unknown style (add it to styles.json first)')
            if not isinstance(clips, list):
                errs.append(f'{w}: must be a list of clips')
                continue
            for c in clips:
                errs += validate_clip(c, w, surah, ayah, style, nwords, groups, reciters, seen)
    return errs


def validate_clip(c, w, surah, ayah, style, nwords, groups, reciters, seen):
    if not isinstance(c, dict) or not isinstance(c.get('file'), str):
        return [f'{w}: a clip must be an object with a file name']
    w = f'{w} {c["file"]}'
    errs = []
    extra = set(c) - set(CLIP_KEYS)
    if extra:
        errs.append(f'{w}: unknown keys {sorted(extra)}')
    if c['file'] in seen:
        errs.append(f'{w}: listed twice')
    seen.add(c['file'])
    p = parse_name(c['file'])
    if not p:
        return errs + [f'{w}: not an AQQD clip name']
    reciter, s, su, a, n = p
    if (s, su, a) != (style, surah, ayah):
        errs.append(f'{w}: the name says {s} {su}:{a}, the index puts it under {style} {surah}:{ayah}')
    if c.get('reciter') != reciter or c.get('clip') != n:
        errs.append(f'{w}: reciter and clip must be {reciter} and {n} (from the name)')
    if not isinstance(c.get('url'), str) or not URL_RE.match(c['url']):
        errs.append(f'{w}: url must be an https link on osf.io')
    if c.get('group') not in groups:
        errs.append(f'{w}: group must be one of {sorted(groups)}')
    elif c['group'] != reciters.get(reciter, 'unknown'):
        errs.append(f'{w}: group must be {reciters.get(reciter, "unknown")!r}, as provenance.json gives {reciter}')
    size, dur = c.get('size'), c.get('duration_ms')
    for k, v in (('size', size), ('duration_ms', dur)):
        if v is not None and (not isinstance(v, int) or isinstance(v, bool) or v <= 0):
            errs.append(f'{w}: {k} must be a positive whole number or null')
    limit = dur if isinstance(dur, int) and dur > 0 else (
        size * 1000 // BYTES_PER_SECOND if isinstance(size, int) and size > 0 else None)
    words = c.get('words')
    if not isinstance(words, list):
        return errs + [f'{w}: words must be a list']
    spans = []
    for r in words:
        rng = r.get('range') if isinstance(r, dict) else None
        if not (isinstance(rng, list) and len(rng) == 3
                and all(isinstance(x, int) and not isinstance(x, bool) for x in rng)):
            errs.append(f'{w}: a word entry is {{"range": [start_ms, end_ms, word], "by": ...}}')
            continue
        extra = set(r) - {'range', 'by', 'reviewed_by'}
        if extra:
            errs.append(f'{w}: unknown keys {sorted(extra)} in a word entry')
        start, end, word = rng
        ww = f'{w} word {word}'
        if not isinstance(r.get('by'), str) or not r['by'].strip():
            errs.append(f'{ww}: "by" (who measured it) is required')
        rev = r.get('reviewed_by')
        if rev is not None and (not isinstance(rev, str) or not rev.strip()):
            errs.append(f'{ww}: reviewed_by must be a name')
        elif rev is not None and rev.strip().lower() == str(r.get('by', '')).strip().lower():
            errs.append(f'{ww}: the reviewer must be a second person')
        if not 1 <= word <= nwords:
            errs.append(f'{ww}: the verse has {nwords} words')
        if not 0 <= start < end:
            errs.append(f'{ww}: start must be before end, from 0')
        if limit is None:
            errs.append(f'{ww}: the clip has no duration or size to check the range against')
        elif end > limit:
            errs.append(f'{ww}: ends at {end} ms, past the clip ({limit} ms)')
        spans.append((start, end, word))
    spans.sort()
    for (s1, e1, w1), (s2, e2, w2) in zip(spans, spans[1:]):
        if s2 < e1:
            errs.append(f'{w}: words {w1} and {w2} overlap')
    return errs


def check(files=None, root=INDEX, data=DATA, counts_path=VERSE_WORDS):
    """{file: [errors]} for the given index files (all when none)."""
    counts = verse_words(counts_path)
    out = {}
    try:
        styles = load_json(Path(data) / 'styles.json')['styles']
        provenance = load_json(Path(data) / 'provenance.json')
    except (OSError, ValueError, KeyError) as e:
        return {'data/qiraat_audio': [f'styles.json or provenance.json unreadable: {e}']}
    for code, v in styles.items():
        if not STYLE_RE.match(code):
            out.setdefault('styles.json', []).append(f'{code}: style codes are S1, S2, ...')
        elif v is not None and not (isinstance(v, dict) and isinstance(v.get('source'), str) and v['source'].strip()):
            out.setdefault('styles.json', []).append(f'{code}: null, or an object with its "source" in the paper')
    groups = provenance.get('groups', {})
    for code, g in provenance.get('reciters', {}).items():
        if not re.fullmatch(r'R\d+', code) or g not in groups:
            out.setdefault('provenance.json', []).append(f'{code}: reciter codes map to one of {sorted(groups)}')
    paths = [Path(f) for f in files] if files else sorted(Path(root).glob('*.json'))
    for path in paths:
        m = FILE_RE.search(path.as_posix())
        name = path.as_posix()
        if not m or not 1 <= int(m.group(1)) <= 114:
            out[name] = ['index files are index/NNN.json, NNN the surah (001-114)']
            continue
        if not path.exists():
            continue  # removed in this change
        try:
            text = path.read_text(encoding='utf-8')
            doc = json.loads(text)
        except (OSError, ValueError) as e:
            out[name] = [f'not valid JSON: {e}']
            continue
        errs = validate(doc, int(m.group(1)), counts, styles, provenance)
        if not errs and text != dumps(doc):
            errs.append('not in the canonical layout: run `python3 tools/qiraat_audio.py format`')
        if errs:
            out[name] = errs
    return out


# ------------------------------------------------------------------ main

def main(argv):
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    sub = ap.add_subparsers(dest='cmd', required=True)
    sub.add_parser('listing')
    b = sub.add_parser('build')
    b.add_argument('--listing', default=str(LISTING))
    d = sub.add_parser('durations')
    d.add_argument('surahs', nargs='*', type=int)
    c = sub.add_parser('check')
    c.add_argument('files', nargs='*')
    f = sub.add_parser('format')
    f.add_argument('files', nargs='*')
    a = ap.parse_args(argv)
    if a.cmd == 'listing':
        import measure_aqqd_coverage
        measure_aqqd_coverage.listing()
        return 0
    if a.cmd == 'build':
        if not Path(a.listing).exists():
            print(f'{a.listing} missing: run `python3 tools/qiraat_audio.py listing` (needs osf.io)')
            return 1
        written, clips, skipped = build(load_json(a.listing), load_json(DATA / 'provenance.json'))
        print(f'{clips} clips; {written} index files written; {len(skipped)} names skipped {skipped[:5]}')
        return 0
    if a.cmd == 'durations':
        print(f'{durations(set(a.surahs))} durations filled')
        return 0
    if a.cmd == 'format':
        for path in [Path(x) for x in a.files] or sorted(INDEX.glob('*.json')):
            path.write_text(dumps(load_json(path)), encoding='utf-8')
        return 0
    problems = check(a.files)
    for name, errs in problems.items():
        for e in errs:
            print(f'{name}: {e}')
    n = len(a.files) if a.files else len(list(INDEX.glob('*.json')))
    print(f'{n} index files checked; {sum(len(e) for e in problems.values())} errors')
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
