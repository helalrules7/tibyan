"""Measures where the tajweed colouring is lost, stage by stage, per edition.

For each sample page and edition:
  a) cpfair annotations of the verses that start on the page (the basmala
     Tanzil puts before verse 1 left out, as the build does);
  b) annotations that keep at least one KFGQPC letter after the
     Tanzil -> KFGQPC alignment (build_tajweed.verse_spans);
  c) annotations whose letters get a place on the page (a contour, or a
     rectangle around ink);
  d) annotations the app draws with its default colours (madd_2 and
     idghaam_no_ghunnah have no default colour), and whose place has ink
     under it (image editions: ink pixels inside the rectangle; 1441: the
     clip window overlaps the contour).

Also draws, for the image editions, the stored rectangles over the page
image the way the app does (ink inside a rectangle recoloured), next to
the plain page, into build/tajweed_audit/.

This only measures. It never writes or changes text or rules.

Usage: python3 tools/audit_tajweed.py [--draw]
Inputs: as build_tajweed.py, plus assets/db/content.db (the stored rows and
the Shamarly word boxes).
"""
import io
import json
import sqlite3
import sys
import zipfile
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
import build_tajweed as bt  # noqa: E402
import build_word_boxes as bw  # noqa: E402

import os  # noqa: E402
if os.environ.get('TAJWEED_SVG_ZIP'):   # the same pages, e.g. unpacked from the 1441 pack
    bw.SVG_ZIP = Path(os.environ['TAJWEED_SVG_ZIP'])
DB = ROOT.parent / 'assets' / 'db' / 'content.db'
OUT = ROOT.parent / 'build' / 'tajweed_audit'
MADINA_PAGES = [2, 3, 50, 106, 187, 300, 450, 582, 604]
# Shamarly: roughly the same places, plus pages that have no tajweed row.
SHAMARLY_PAGES = [2, 3, 5, 44, 90, 162, 260, 390, 504, 522, 32, 103, 205, 294]
NO_COLOUR = set()   # rules with no default colour (lib/features/mushaf/data/tajweed.dart): none since 2026-10-03


def content():
    return sqlite3.connect(f'file:{DB}?mode=ro', uri=True)


def verses_on(edition, page):
    col = {'madina1441': 'page', 'madina1405': 'page_1405', 'shamarly': 'page_shamarly'}[edition]
    return [(s, a) for s, a in content().execute(
        f'SELECT surah, number FROM ayah WHERE {col} = ? ORDER BY id', (page,))]


def shamarly_words(kfgqpc):
    """As build_tajweed.shamarly_words, from content.db's copy of the
    Shamarly word boxes (the verses with words_matched >= 1)."""
    by_page = {}
    for page, s, a, n, line, x0, y0, x1, y1 in content().execute(
            'SELECT page, surah, ayah, word, line, x0, y0, x1, y1 FROM shamarly_word_box '
            'WHERE level >= 1 ORDER BY page'):
        index = bt.word_index(kfgqpc[(s, a)])
        if n <= len(index):
            by_page.setdefault(page, []).append(((s, a), index[n - 1], line, [(x0, y0, x1, y1)]))
    return sorted(by_page.items())


def shamarly_loader():
    from PIL import Image
    meta = {p: (k, pitch) for p, k, pitch in content().execute('SELECT page, kind, pitch FROM shamarly_page')}
    z = zipfile.ZipFile(bt.CACHE / 'shamarly' / 'shamarly-pages-archive-org.zip')

    def image(page):
        return Image.open(io.BytesIO(z.read(f'{page:03d}.png')))

    def load(page):
        kind, pitch = meta[page]
        return bt.ink_mask(image(page), kind != 'text'), pitch or 80
    return load, image, meta


def old_loader():
    from PIL import Image
    z = zipfile.ZipFile(bt.CACHE / 'images_1024.zip')

    def image(page):
        return Image.open(io.BytesIO(z.read(f'width_1024/page{page:03d}.png')))

    def load(page):
        return bt.ink_mask(image(page), False), 1594 / 15
    return load, image


def image_stage_c(spans, kfgqpc, words_on_pages, load_page, pages):
    """{page: {(verse, rule, wi, li, part): [rects]}} : build_tajweed.image_edition
    with each span's rectangles kept apart."""
    by_verse = defaultdict(lambda: defaultdict(list))
    for key, sp in spans.items():
        for rule, wi, li, part in sp:
            by_verse[key][wi].append((rule, li, part))
    out, masks = {}, {}
    for page, words in words_on_pages:
        if page not in pages:
            continue
        mask, pitch = load_page(page)
        masks[page] = mask
        lines = {}
        for _, _, line, rects in words:
            lines.setdefault(line, []).extend(rects)
        bases = {line: bt.baseline(mask, (min(r[0] for r in rs), min(r[1] for r in rs),
                                          max(r[2] for r in rs), max(r[3] for r in rs)))
                 for line, rs in lines.items()}
        got_page = out.setdefault(page, {})
        for verse, wi, line, rects in words:
            todo = by_verse.get(verse, {}).get(wi)
            if not todo:
                continue
            got = bt.image_word(mask, kfgqpc[verse][wi], rects, bases[line], pitch)
            for rule, li, part in todo:
                boxes = [] if got is None else got[0].get((li, part), [])
                got_page[(verse, rule, wi, li, part)] = boxes
    return out, masks


def new_stage_c(spans, pages):
    """{(verse, rule, wi, li, part): [(contour, x0, x1, contour bbox)]} on the
    new edition, as build_tajweed.new_edition places them."""
    index, boxes = {}, {}
    with zipfile.ZipFile(bw.SVG_ZIP) as z:
        for page in pages:
            items, _ = bw.read_page(z.read(f'svg/{page:03d}.svg').decode())
            index[page] = {}
            for i, (bbox, _) in enumerate(items):
                index[page].setdefault(bbox, i)
    out = {}
    for verse, tokens, segs, groups, _, owner in bw.layouts(pages):
        vs = spans.get(verse, [])
        words = {}
        for wi, (si, a, b) in enumerate(groups):
            words[wi] = (segs[si][0], segs[si][2][a:b + 1], [])
        for page, _, pieces, cs in segs:
            cores = {id(bb) for p in pieces for bb in p[2]}
            for bbox, _ in cs:
                if id(bbox) not in cores:
                    words[owner[id(bbox)]][2].append(bbox)
        for rule, wi, li, part in vs:
            key = (verse, rule, wi, li, part)
            if wi not in words:
                out[key] = []
                continue
            page, pieces, marks = words[wi]
            ranges, piece_of, exact = bt.letter_ranges(tokens[wi], [(p[0], p[1]) for p in pieces])
            mark_of = {}
            for bb in marks:
                mark_of.setdefault(bt.nearest_letter(ranges, (bb[0] + bb[2]) / 2), []).append(bb)
            alone = exact and len(bt.runs(tokens[wi])[piece_of[li]]) == 1
            got = []
            if part == 'body':
                chosen = [pieces[piece_of[li]]] if exact else pieces
                x0, x1 = ranges[li]
                for p in chosen:
                    for bb in p[2]:
                        got.append((page, index[page][bb], None if alone else x0, None if alone else x1, bb))
            for bb in mark_of.get(li, []):
                got.append((page, index[page][bb], None, None, bb))
            out[key] = got
    return out


def ink_in(mask, r):
    x0, y0, x1, y1 = (int(v) for v in r)
    return int(mask[max(y0, 0):y1, max(x0, 0):x1].sum())


def audit():
    kfgqpc = bw.load_text()
    spans, _ = bt.all_spans(kfgqpc)
    tanzil = bt.read_tanzil(bt.TANZIL_2017)
    data = {(e['surah'], e['ayah']): e['annotations'] for e in json.loads(bt.TAJWEED.read_text(encoding='utf-8'))}

    def stage_a(verses):
        out = []
        for v in verses:
            prefix = bt.basmala_prefix(tanzil, v)
            out += [(v, i, a['rule']) for i, a in enumerate(data[v]) if a['start'] >= prefix]
        return out

    # Which annotation each placed letter came from: verse_spans keeps the
    # order of the annotations, so redo it per annotation.
    def spans_of_annotation(v):
        prefix = bt.basmala_prefix(tanzil, v)
        res = {}
        for i, a in enumerate(data[v]):
            if a['start'] < prefix:
                continue
            res[i] = bt.verse_spans([a], tanzil[v], kfgqpc[v], prefix)
        return res

    report = {}
    # ---- new edition
    pages = MADINA_PAGES
    placed_new = new_stage_c(spans, range(1, 605))
    zpack = None
    for ed in ('madina1441', 'madina1405', 'shamarly'):
        report[ed] = {}
    if True:
        ed = 'madina1441'
        for page in pages:
            verses = verses_on(ed, page)
            a = stage_a(verses)
            b = c = d = 0
            rules_lost = Counter()
            for v in verses:
                for i, sp in spans_of_annotation(v).items():
                    rule = data[v][i]['rule']
                    if not sp:
                        rules_lost['b:' + rule] += 1
                        continue
                    b += 1
                    pl = [g for (r, wi, li, part) in sp for g in placed_new.get((v, r, wi, li, part), [])]
                    if not pl:
                        rules_lost['c:' + rule] += 1
                        continue
                    c += 1
                    visible = [g for g in pl if g[2] is None or (min(g[3], g[4][2]) - max(g[2], g[4][0]) > 0.05)]
                    if rule in NO_COLOUR:
                        rules_lost['d(no default colour):' + rule] += 1
                    elif not visible:
                        rules_lost['d(empty clip):' + rule] += 1
                    else:
                        d += 1
            report[ed][page] = dict(a=len(a), b=b, c=c, d=d, lost=dict(rules_lost.most_common(8)))
    # ---- image editions
    load_old, _ = old_loader()
    old, masks_old = image_stage_c(spans, kfgqpc, bt.old_edition_words(kfgqpc, MADINA_PAGES), load_old, set(MADINA_PAGES))
    load_sh, _, _ = shamarly_loader()
    sh, masks_sh = image_stage_c(spans, kfgqpc, shamarly_words(kfgqpc), load_sh, set(SHAMARLY_PAGES))
    for ed, placed, masks, pages in (('madina1405', old, masks_old, MADINA_PAGES),
                                     ('shamarly', sh, masks_sh, SHAMARLY_PAGES)):
        for page in pages:
            verses = verses_on(ed, page)
            a = stage_a(verses)
            b = c = d = 0
            rules_lost = Counter()
            by_key = {}
            for p_ in placed.values():
                by_key.update(p_)
            for v in verses:
                for i, sp in spans_of_annotation(v).items():
                    rule = data[v][i]['rule']
                    if not sp:
                        rules_lost['b:' + rule] += 1
                        continue
                    b += 1
                    keys = [(v, r, wi, li, part) for (r, wi, li, part) in sp]
                    if not any(k in by_key for k in keys):
                        rules_lost['c(no word box for the verse):' + rule] += 1
                        continue
                    rects = [r for k in keys for r in by_key.get(k, [])]
                    if not rects:
                        rules_lost['c(no ink piece for the letter):' + rule] += 1
                        continue
                    c += 1
                    pg = next(pp for pp, p_ in placed.items() if keys[0] in p_ or any(k in p_ for k in keys))
                    if rule in NO_COLOUR:
                        rules_lost['d(no default colour):' + rule] += 1
                    elif not any(ink_in(masks[pg], r) > 0 for r in rects):
                        rules_lost['d(no ink in rect):' + rule] += 1
                    else:
                        d += 1
            report[ed][page] = dict(a=len(a), b=b, c=c, d=d, lost=dict(rules_lost.most_common(8)))
    return report, spans, old, sh


def stored_rows(edition, page):
    row = content().execute('SELECT data FROM tajweed_page WHERE edition = ? AND page = ?', (edition, page)).fetchone()
    return row[0] if row else ''


DRAW_COLOURS = {   # the app's default light-paper shades (TajweedHue.light)
    'hamzat_wasl': '7A7A7A', 'lam_shamsiyyah': '7A7A7A', 'silent': '7A7A7A',
    'madd_246': 'B85A00', 'madd_muttasil': 'D32F2F', 'madd_munfasil': 'D32F2F', 'madd_6': '8E1B1B',
    'ghunnah': '1B5E20', 'ikhfa': '1B5E20', 'ikhfa_shafawi': '1B5E20', 'iqlab': '1B5E20',
    'idghaam_ghunnah': '1B5E20', 'idghaam_shafawi': '1B5E20',
    'idghaam_mutajanisayn': '7A7A7A', 'idghaam_mutaqaribayn': '7A7A7A', 'qalqalah': '1565C0',
}


def draw_image_page(edition, page, image, opaque, name):
    """The page as the app draws it with tajweed on (default colours): the
    ink inside each stored rectangle recoloured; left: the plain page."""
    import numpy as np
    from PIL import Image
    im = image.convert('RGBA')
    a = np.asarray(im).copy()
    ink = bt.ink_mask(image, opaque)
    paper = np.full(a.shape, 255, np.uint8)
    base = np.where(ink[..., None], np.array([20, 20, 20, 255], np.uint8), paper)
    out = base.copy()
    for e in stored_rows(edition, page).split(';'):
        if not e:
            continue
        r, x0, y0, x1, y1 = (int(v) for v in e.split(','))
        hexc = DRAW_COLOURS.get(bt.RULES[r])
        if hexc is None:
            continue
        rgb = np.array([int(hexc[i:i + 2], 16) for i in (0, 2, 4)] + [255], np.uint8)
        sub = ink[y0:y1, x0:x1]
        region = out[y0:y1, x0:x1]
        region[sub] = rgb
    both = np.concatenate([base, np.full((a.shape[0], 12, 4), 200, np.uint8), out], axis=1)
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray(both).convert('RGB').save(OUT / name)


def main():
    report, _, _, _ = audit()
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'audit.json').write_text(json.dumps({e: {str(p): v for p, v in r.items()} for e, r in report.items()},
                                               ensure_ascii=False, indent=1))
    for ed, pages in report.items():
        tot = Counter()
        print(f'\n{ed}:  page   a    b    c    d   (d/a)')
        for page, r in pages.items():
            tot.update({k: r[k] for k in 'abcd'})
            print(f'        {page:4d} {r["a"]:4d} {r["b"]:4d} {r["c"]:4d} {r["d"]:4d}  {r["d"] / max(r["a"], 1):5.0%}  {r["lost"]}')
        print(f'  total      {tot["a"]:4d} {tot["b"]:4d} {tot["c"]:4d} {tot["d"]:4d}  {tot["d"] / max(tot["a"], 1):5.0%}')
    if '--draw' in sys.argv:
        _, image = old_loader()
        for p in MADINA_PAGES:
            draw_image_page('madina1405', p, image(p), False, f'madina1405_p{p:03d}.png')
        _, image, meta = shamarly_loader()
        for p in SHAMARLY_PAGES:
            draw_image_page('shamarly', p, image(p), meta[p][0] != 'text', f'shamarly_p{p:03d}.png')


if __name__ == '__main__':
    main()
