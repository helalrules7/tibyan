"""Describe Quranpedia's topics.json (MISSING_DATA ن7): how deep the tree
is, how many topics sit at each level, which surahs and verses it links,
whether any field names a source book, and the titles of the first levels.
Read only: titles are printed as they are in the file, nothing is written
into the app.

The schema is read loosely: a topic is an object with a title key; its
children are the topic objects found in its lists; its verses are the
surah/ayah pairs (or "S:A" / "S:A-B" strings) found under it outside its
child topics.

Usage:
  python3 tools/inspect_quranpedia_topics.py [--titles DEPTH] [--sample N]
Input: tools/.cache/quranpedia/topics.json.gz (fetch_quranpedia_dumps.py).
"""
import gzip
import json
import re
import sys
from collections import Counter

import staging

TOPICS = staging.ROOT / '.cache' / 'quranpedia' / 'topics.json.gz'
TITLE_KEYS = ('title', 'name', 'topic', 'label', 'title_ar', 'name_ar')
SURAH_KEYS = ('surah', 'sura', 'surah_id', 'sura_id', 'surah_number', 'chapter')
AYAH_KEYS = ('ayah', 'aya', 'ayah_number', 'aya_number', 'verse', 'number_in_surah')
AYAH_TO_KEYS = ('ayah_to', 'aya_to', 'to', 'end', 'ayah_end', 'to_ayah')
SOURCE_KEYS = ('source', 'sources', 'book', 'books', 'reference', 'references', 'ref',
               'author', 'kitab', 'masdar')
RANGE_RE = re.compile(r'^(\d{1,3}):(\d{1,3})(?:\s*-\s*(\d{1,3}))?$')


def _int(v):
    if isinstance(v, int):
        return v
    if isinstance(v, str) and v.isdigit():
        return int(v)
    return None


def title_of(o):
    if not isinstance(o, dict):
        return None
    for k in TITLE_KEYS:
        if isinstance(o.get(k), str) and o[k].strip():
            return o[k]
    return None


def verses_in(o):
    """Verse refs directly in o (not inside nested topics)."""
    out = set()
    if isinstance(o, str):
        m = RANGE_RE.match(o.strip())
        if m:
            s, a, b = int(m.group(1)), int(m.group(2)), int(m.group(3) or m.group(2))
            out.update((s, x) for x in range(a, b + 1))
        return out
    if isinstance(o, list):
        for v in o:
            if not title_of(v):
                out |= verses_in(v)
        return out
    if isinstance(o, dict):
        s = next((_int(o[k]) for k in SURAH_KEYS if _int(o.get(k))), None)
        a = next((_int(o[k]) for k in AYAH_KEYS if _int(o.get(k))), None)
        if s and a:
            b = next((_int(o[k]) for k in AYAH_TO_KEYS if _int(o.get(k))), a)
            out.update((s, x) for x in range(a, max(a, b) + 1))
        for k, v in o.items():
            if isinstance(v, (dict, list, str)) and not title_of(v) and k not in TITLE_KEYS:
                out |= verses_in(v)
    return out


def children(o):
    out = []

    def walk(v):
        if isinstance(v, dict):
            if title_of(v):
                out.append(v)
            else:
                for x in v.values():
                    walk(x)
        elif isinstance(v, list):
            for x in v:
                walk(x)
    if isinstance(o, dict):
        for k, v in o.items():
            if k not in TITLE_KEYS:
                walk(v)
    else:
        walk(o)
    return out


def tree_stats(data):
    """Counts per depth (1 = root topics), leaves, verse coverage, source
    fields, and the node list as (depth, title, verse count, child count)."""
    per_depth, nodes = Counter(), []
    verses, sources, leaves = set(), Counter(), 0
    with_verses = 0

    def visit(node, depth):
        nonlocal leaves, with_verses
        per_depth[depth] += 1
        kids = children(node)
        vs = verses_in(node)
        verses.update(vs)
        with_verses += bool(vs)
        for k in node:
            if k.lower() in SOURCE_KEYS and node[k] not in (None, '', [], {}):
                sources[k] += 1
        if not kids:
            leaves += 1
        nodes.append((depth, title_of(node), len(vs), len(kids)))
        for c in kids:
            visit(c, depth + 1)
    for root in children(data):
        visit(root, 1)
    return dict(per_depth=dict(sorted(per_depth.items())), topics=sum(per_depth.values()),
                leaves=leaves, topics_with_verses=with_verses, verses=len(verses),
                surahs=sorted({s for s, _ in verses}), source_fields=dict(sources), nodes=nodes)


def main(argv):
    depth = int(argv[argv.index('--titles') + 1]) if '--titles' in argv else 2
    sample = int(argv[argv.index('--sample') + 1]) if '--sample' in argv else 40
    raw = TOPICS.read_bytes()
    data = json.loads(gzip.decompress(raw))
    st = tree_stats(data)
    print(f'file: {TOPICS.name} sha256 {staging.sha256_bytes(raw)}')
    top = data if isinstance(data, dict) else {}
    print('top-level keys:', sorted(top)[:20] if top else type(data).__name__)
    print(f"topics {st['topics']}, per depth {st['per_depth']}, leaves {st['leaves']}")
    print(f"topics with verses {st['topics_with_verses']}; verses {st['verses']} of 6236; "
          f"surahs {len(st['surahs'])}: {st['surahs']}")
    print(f"source fields: {st['source_fields'] or 'none'}")
    shown = 0
    for d, t, nv, nk in st['nodes']:
        if d <= depth and shown < sample:
            print(f"{'  ' * (d - 1)}- {t} ({nv} verses, {nk} sub-topics)")
            shown += 1
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
