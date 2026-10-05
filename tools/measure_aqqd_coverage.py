"""Measure how much of Quranpedia's word-level qiraat data (qiraat.json,
MISSING_DATA ن1: 3,455 verses / 5,783 words on 2026-09-28) the AQQD audio
dataset (Annotated Quranic Qira'at Dataset, CC0 1.0, OSF project 6sh5d)
could cover (MISSING_DATA ن2).

AQQD labels each clip by its file name only:
    R023_S5_Surah_036_Aya40_C2.wav = reciter 23, style 5, surah 36, verse 40, clip 2
(the convention given in the dataset paper). A clip is located by verse,
not by word. So for each style the measure is:
  - verses: qiraat verses with at least one clip of that style;
  - words: qiraat words in those verses. This is an UPPER BOUND: a clip of
    a verse does not show which of its words it reaches.
The audio is never downloaded: only the file listing is read (the OSF
API gives each file's name, size and hashes).

Usage:
  python3 tools/measure_aqqd_coverage.py listing        # OSF listing -> staging
  python3 tools/measure_aqqd_coverage.py measure [--style-map map.json] [--listing names.txt]
Inputs: tools/.cache/quranpedia/qiraat.json.gz (fetch_quranpedia_dumps.py),
tools/.cache/staging/aqqd/listing.json (or a text file of names, one per line).
--style-map maps a style code ("S5") to its qira'a, from the paper's table.
"""
import gzip
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

import staging

OSF_NODE = '6sh5d'
OSF_FILES = f'https://api.osf.io/v2/nodes/{OSF_NODE}/files/osfstorage/'
OUT = staging.STAGING / 'aqqd'
QIRAAT = staging.ROOT / '.cache' / 'quranpedia' / 'qiraat.json.gz'
EXPECTED = (3455, 5783)  # verses, words in qiraat.json on 2026-09-28
NAME_RE = re.compile(r'R(\d+)_S(\d+)_Surah_(\d+)_Aya_?(\d+)_C(\d+)\.wav$', re.I)
SURAH_KEYS = ('surah', 'sura', 'surah_id', 'sura_id', 'surah_number', 'sura_no', 'chapter')
AYAH_KEYS = ('ayah', 'aya', 'ayah_number', 'aya_number', 'aya_no', 'verse', 'number_in_surah')
WORD_KEYS = ('word_id', 'word_number', 'word_index', 'word_position', 'position', 'word')
VERSE_KEY_RE = re.compile(r'^(\d{1,3}):(\d{1,3})$')


def parse_name(name):
    """(reciter, style, surah, ayah, clip) from an AQQD file name, or None."""
    m = NAME_RE.search(name)
    if not m:
        return None
    r, s, su, a, c = (int(x) for x in m.groups())
    return r, s, su, a, c


def _first(d, keys):
    for k in keys:
        v = d.get(k)
        if isinstance(v, int) or (isinstance(v, str) and v.isdigit()):
            return int(v)
    return None


def qiraat_words(data):
    """{(surah, ayah): set(word ids)} from a qiraat dump. The schema is
    read loosely: a word entry is any object with a word key, located by
    surah/ayah keys on itself or its enclosing objects, or by a "S:A"
    dictionary key. Word ids are the word key's value (index or text)."""
    out = defaultdict(set)

    def walk(o, surah, ayah):
        if isinstance(o, dict):
            surah = _first(o, SURAH_KEYS) or surah
            ayah = _first(o, AYAH_KEYS) or ayah
            word = next((o[k] for k in WORD_KEYS if k in o and isinstance(o[k], (int, str))), None)
            if word is not None and surah and ayah:
                out[(surah, ayah)].add(word)
            for k, v in o.items():
                m = VERSE_KEY_RE.match(str(k))
                if m:
                    walk(v, int(m.group(1)), int(m.group(2)))
                elif isinstance(v, (dict, list)):
                    walk(v, surah, ayah)
        elif isinstance(o, list):
            for v in o:
                walk(v, surah, ayah)
    walk(data, None, None)
    return dict(out)


def clips_by_style(names):
    """{style: {(surah, ayah): clip count}}, plus the unparsed names."""
    by, bad = defaultdict(lambda: defaultdict(int)), []
    reciters = defaultdict(set)
    for n in names:
        p = parse_name(n)
        if not p:
            bad.append(n)
            continue
        r, s, su, a, _ = p
        by[s][(su, a)] += 1
        reciters[s].add(r)
    return {s: dict(v) for s, v in by.items()}, {s: len(v) for s, v in reciters.items()}, bad


def coverage(words, by_style):
    """Rows per style: clips, verses with clips, qiraat verses covered, qiraat
    words in covered verses (upper bound). Plus 'any' and '>=2 styles'."""
    qv = set(words)
    rows = {}
    for s, verses in sorted(by_style.items()):
        cov = qv & set(verses)
        rows[s] = dict(clips=sum(verses.values()), verses=len(verses), qiraat_verses=len(cov),
                       qiraat_words=sum(len(words[v]) for v in cov))
    styles_per_verse = defaultdict(int)
    for verses in by_style.values():
        for v in verses:
            styles_per_verse[v] += 1
    for label, need in (('any', 1), ('2+', 2)):
        cov = {v for v in qv if styles_per_verse.get(v, 0) >= need}
        rows[label] = dict(clips=None, verses=sum(1 for c in styles_per_verse.values() if c >= need),
                           qiraat_verses=len(cov), qiraat_words=sum(len(words[v]) for v in cov))
    return rows


def osf_walk(url, out):
    """Every file under an OSF storage folder: name, path, size, hashes."""
    while url:
        page = json.loads(staging.get(url))
        for item in page['data']:
            a = item['attributes']
            if a['kind'] == 'folder':
                osf_walk(item['relationships']['files']['links']['related']['href'], out)
            else:
                out.append({'name': a['name'], 'path': a['materialized_path'], 'size': a['size'],
                            'hashes': (a.get('extra') or {}).get('hashes')})
        url = page['links'].get('next')
    return out


def listing():
    OUT.mkdir(parents=True, exist_ok=True)
    files = osf_walk(OSF_FILES, [])
    (OUT / 'listing.json').write_text(json.dumps(files, indent=0) + '\n', encoding='utf-8')
    staging.write_sums(OUT)
    staging.write_manifest(OUT, source=f'https://osf.io/{OSF_NODE}/', api=OSF_FILES,
                           files=len(files), license='CC0 1.0 (dataset paper)', mirrored=False)
    archives = [f['name'] for f in files if f['name'].lower().endswith(('.zip', '.tar', '.gz', '.7z', '.rar'))]
    print(f'{len(files)} files listed; archives: {archives[:10]}')
    if archives:
        print('The clips are inside archives: their names need the archive index '
              '(e.g. `unzip -l`), which needs the archive itself.')


def measure(argv):
    style_map = {}
    names = None
    if '--style-map' in argv:
        style_map = json.loads(Path(argv[argv.index('--style-map') + 1]).read_text(encoding='utf-8'))
    if '--listing' in argv:
        names = Path(argv[argv.index('--listing') + 1]).read_text(encoding='utf-8').split()
    else:
        names = [f['name'] for f in json.loads((OUT / 'listing.json').read_text(encoding='utf-8'))]
    words = qiraat_words(json.load(gzip.open(QIRAAT)))
    nv, nw = len(words), sum(len(w) for w in words.values())
    if (nv, nw) != EXPECTED:
        print(f'qiraat.json read as {nv} verses / {nw} words, expected {EXPECTED}: '
              'the reader does not fit this dump; fix qiraat_words() first.')
        return 1
    by, reciters, bad = clips_by_style(names)
    print(f'AQQD names parsed: {len(names) - len(bad)} of {len(names)}; qiraat {nv} verses / {nw} words')
    print('| style | qira\'a | reciters | clips | verses with clips | qiraat verses covered | '
          'qiraat words in them (upper bound) |')
    print('|---|---|---|---|---|---|---|')
    for s, r in coverage(words, by).items():
        name = style_map.get(f'S{s}', '') if isinstance(s, int) else ''
        print(f"| {('S%s' % s) if isinstance(s, int) else s} | {name} | {reciters.get(s, '')} | "
              f"{r['clips'] if r['clips'] is not None else ''} | {r['verses']} | "
              f"{r['qiraat_verses']} ({100 * r['qiraat_verses'] / nv:.1f}%) | "
              f"{r['qiraat_words']} ({100 * r['qiraat_words'] / nw:.1f}%) |")
    return 0


def main(argv):
    if argv and argv[0] == 'listing':
        listing()
        return 0
    if argv and argv[0] == 'measure':
        return measure(argv[1:])
    print(__doc__)
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
