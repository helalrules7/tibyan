"""Checks the Shamarly page geometry (tools/.cache/shamarly_geometry.db,
made by build_shamarly.py) against the page images and the other sources,
and draws overlays for a human reviewer.

Checks:
  1. lines     every text page has 15 line slots (7 on pages 2-3);
  2. cuts      every ink component of every page is drawn whole by exactly
               one line, taking the line's band plus its overflow
               rectangles, less other lines' rectangles (as the app's
               old-edition page does); how far the first and last lines' ink
               reaches beyond their baselines (constants for the app);
  3. markers   markers per page = verses ending there (shamerly.db); every
               verse 1..n of every surah ends exactly once;
  4. pages     6,236 verses have a start page; end pages agree with
               shamerly.db; page breaks agree with the first-word index
               (a page starts mid-verse exactly when the index is > 0);
  5. headers   114 surah starts: 112 printed header frames on pages 4-522
               plus the two ornate titles; 112 basmala lines (none for
               at-Tawba; al-Fatiha's basmala is its verse 1);
  6. words     verses with word boxes; word counts equal ours; words whose
               width is far from their KFGQPC font width (relative to the
               verse) are flagged for a look, like verify_word_boxes.py.

Usage:
  python3 tools/verify_shamarly.py                       # print the checks
  python3 tools/verify_shamarly.py --preview 3 50 300    # also draw overlays
Exits 1 when a hard check fails.
"""
import collections
import json
import sqlite3
import statistics
import sys
from multiprocessing import Pool
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import shamarly_image as S  # noqa: E402

ROOT = Path(__file__).resolve().parent
GEO = ROOT / '.cache' / 'shamarly_geometry.db'
SRC = ROOT / '.cache' / 'shamarly'
CONTENT = ROOT.parent / 'assets' / 'db' / 'content.db'
PREVIEW = SRC / 'preview'
FONT_WIDTHS = ROOT / 'word_font_widths.json'
LOW, HIGH = 0.5, 2.0


def db():
    return sqlite3.connect(f'file:{GEO}?mode=ro', uri=True)


def check_page(page):
    """Cut check for one page: [problem], (above, below) ink reach."""
    g = db()
    ink, _ = S.load(page)
    if page in (2, 3):
        keep = np.zeros_like(ink)
        keep[320:1095, 60:826] = True
        ink &= keep
    labels, boxes, sizes = S.label(ink)
    lines = g.execute('SELECT line, baseline, y0, y1 FROM line WHERE page = ? ORDER BY line', (page,)).fetchall()
    cuts = [y for (y,) in g.execute('SELECT y FROM line_cut WHERE page = ? ORDER BY gap', (page,))]
    h, w = ink.shape
    band = np.searchsorted(np.array(cuts), np.arange(h), side='right')  # line of each row
    drawn = np.repeat(band[:, None], w, axis=1).astype(np.int16)
    who = np.full((h, w), -1, np.int16)
    for line, x0, y0, x1, y1 in g.execute('SELECT line, x0, y0, x1, y1 FROM line_overflow WHERE page = ?', (page,)):
        sub = who[y0:y1, x0:x1]
        who[y0:y1, x0:x1] = np.where(sub == -1, line, np.where(sub == line, line, -2))
    drawn = np.where(who >= 0, who, drawn)
    drawn = np.where(who == -2, -1, drawn)     # two lines claim it: neither draws it
    problems = []
    lab = labels.ravel()
    d = drawn.ravel()
    ks = lab[lab > 0]
    ds = d[lab > 0]
    lo = np.full(len(sizes), 99, np.int16)
    hi = np.full(len(sizes), -9, np.int16)
    np.minimum.at(lo, ks, ds)
    np.maximum.at(hi, ks, ds)
    for k in range(1, len(sizes)):
        if lo[k] < 0:
            problems.append(f'ink at {tuple(int(v) for v in boxes[k])} is not drawn (claimed by two lines)')
        elif lo[k] != hi[k]:
            problems.append(f'ink at {tuple(int(v) for v in boxes[k])} is split between lines {lo[k]} and {hi[k]}')
    ys = np.flatnonzero(ink.any(1))
    above = lines[0][1] - int(ys[0]) if len(ys) else 0
    below = int(ys[-1]) + 1 - lines[-1][1] if len(ys) else 0
    return page, problems, above, below


def main():
    argv = sys.argv[1:]
    g = db()
    hard = []
    pages = [p for (p,) in g.execute("SELECT page FROM page WHERE kind != 'cover' ORDER BY page")]

    # 1. lines
    counts = collections.Counter(n for (n,) in g.execute("SELECT lines FROM page WHERE kind = 'text'"))
    pitches = [p for (p,) in g.execute("SELECT pitch FROM page WHERE kind = 'text'")]
    kinds = dict(g.execute('SELECT kind, COUNT(*) FROM line GROUP BY kind').fetchall())
    ok = set(counts) == {15}
    print(f'{"OK  " if ok else "FAIL"}  lines: {sum(counts.values())} text pages, lines per page {dict(counts)}, '
          f'pitch {min(pitches):.2f}-{max(pitches):.2f} px (median {statistics.median(pitches):.2f}); '
          f'pages 2-3: {g.execute("SELECT GROUP_CONCAT(lines) FROM page WHERE kind = ?", ("ornate",)).fetchone()[0]} lines; '
          f'slots {kinds}')
    if not ok:
        hard.append('lines')

    # 2. cuts
    with Pool(8) as pool:
        res = pool.map(check_page, pages)
    bad = [(p, pr) for p, pr, _, _ in res if pr]
    crossing = g.execute('SELECT SUM(crossing), COUNT(*) FROM line_cut').fetchone()
    n_over = g.execute('SELECT COUNT(*) FROM line_overflow').fetchone()[0]
    print(f'{"OK  " if not bad else "FAIL"}  cuts: {crossing[1]} cuts, {crossing[0]} components cross one '
          f'(given to their line by {n_over} rectangles); ink split or lost on {len(bad)} pages')
    for p, pr in bad[:10]:
        print(f'        page {p}: {len(pr)}: ' + '; '.join(pr[:2]))
    if bad:
        hard.append('cuts')
    text = [(p, a, b) for p, _, a, b in res if p > 3]
    wa = max(text, key=lambda t: t[1])
    wb = max(text, key=lambda t: t[2])
    print(f'        ink reach: first line up to {wa[1]} px above its baseline (page {wa[0]}), '
          f'last line up to {wb[2]} px below its baseline (page {wb[0]})')

    # 3. markers
    pts = sqlite3.connect(f'file:{SRC / "shamerly.db"}?mode=ro', uri=True)
    exp = collections.Counter(p for (p,) in pts.execute('SELECT page FROM mushaf WHERE ayah > 0'))
    got = collections.Counter(p for (p,) in g.execute('SELECT page FROM marker'))
    off = sorted(p for p in set(exp) | set(got) if exp[p] != got[p])
    content = sqlite3.connect(f'file:{CONTENT}?mode=ro', uri=True)
    verses = content.execute('SELECT surah, number FROM ayah ORDER BY id').fetchall()
    marked = set(g.execute('SELECT surah, ayah FROM marker'))
    missing = [v for v in verses if v not in marked]
    ok = not off and not missing
    print(f'{"OK  " if ok else "FAIL"}  markers: {sum(got.values())} of {len(verses)} verses; '
          f'pages where the count differs from shamerly.db: {off or "none"}; verses with no marker: {missing or "none"}')
    if not ok:
        hard.append('markers')

    # 4. pages
    ours = {(s, a): (p, e) for s, a, p, e in g.execute('SELECT surah, ayah, page, end_page FROM ayah')}
    theirs = {(s, a): p for s, a, p in pts.execute('SELECT sura, ayah, page FROM mushaf WHERE ayah > 0')}
    no_page = [v for v in verses if ours.get(v, (0, 0))[0] == 0]
    end_diff = [v for v in verses if v in ours and ours[v][1] != theirs.get(v)]
    fwi = {}
    for row in (SRC / 'shemerly_page_first_word_index.txt').read_text().split()[1:]:
        p, i = row.split(',')[:2]
        if i.strip():
            fwi[int(p)] = int(i)
    mid = {}
    for v in verses:
        if v in ours and ours[v][0] < ours[v][1]:
            for p in range(ours[v][0] + 1, ours[v][1] + 1):
                mid[p] = v
    brk = [p for p in range(3, 523) if p in fwi and (fwi[p] > 0) != (p in mid)]
    n_pages = len({p for p, _ in ours.values()})
    ok = not no_page and not end_diff and not brk
    print(f'{"OK  " if ok else "FAIL"}  pages: {len(ours) - len(no_page)} verses with a start page '
          f'({n_pages} distinct pages); end page differs from shamerly.db: {end_diff[:10] or "none"}; '
          f'page breaks against the first-word index: {len(fwi)} pages, {len(brk)} disagree {brk[:10] or ""}')
    if not ok:
        hard.append('pages')

    # 5. headers and basmalas
    heads = dict(g.execute('SELECT surah, page FROM header').fetchall())
    bas = [s for (s,) in g.execute("SELECT surah FROM line WHERE kind = 'basmala'")]
    want_bas = [s for s in range(2, 115) if s != 9]
    frames = sum(1 for s in heads if s > 2)
    ok = sorted(heads) == list(range(1, 115)) and sorted(bas) == want_bas
    starts = {s: p for s, p in g.execute('SELECT surah, page FROM ayah WHERE ayah = 1')}
    far = [s for s, p in heads.items() if not 0 <= starts[s] - p <= 1]
    print(f'{"OK  " if ok and not far else "FAIL"}  headers: {len(heads)} surah starts '
          f'({frames} printed frames + 2 ornate titles); {len(bas)} basmala lines '
          f'(missing {sorted(set(want_bas) - set(bas)) or "none"}); '
          f'header not on the page of verse 1 or the one before: {far or "none"}')
    if not ok or far:
        hard.append('headers')

    # 6. words
    ours_n = dict(((s, a), n) for s, a, n in content.execute('SELECT surah, ayah, COUNT(*) FROM word_box GROUP BY 1, 2'))
    level = dict(((s, a), m) for s, a, m in g.execute('SELECT surah, ayah, words_matched FROM ayah'))
    got_n = dict(((s, a), n) for s, a, n in g.execute('SELECT surah, ayah, COUNT(*) FROM word_box GROUP BY 1, 2'))
    matched = [v for v, m in level.items() if m >= 1]
    boxed = [v for v in level if v in got_n]       # level 0 too: best split, not confirmed
    wrong = [v for v in boxed if got_n.get(v) != ours_n[v]]
    import re
    texts = {(s, a): [t for t in re.split('[  ]', d)[:-1] if t and t != '۞']
             for s, a, d in content.execute('SELECT surah, number, display_text FROM ayah')}
    fw = json.loads(FONT_WIDTHS.read_text(encoding='utf-8'))
    flagged = {}
    for v in boxed:
        ws = g.execute('SELECT word, x1 - x0 FROM word_box WHERE surah = ? AND ayah = ? ORDER BY word', v).fetchall()
        ratios = [w / fw[t] for (_, w), t in zip(ws, texts[v]) if fw.get(t)]
        if not ratios:
            continue
        med = statistics.median(ratios)
        out = [i + 1 for i, r in enumerate(ratios) if not LOW <= r / med <= HIGH]
        if out:
            flagged[v] = out
    n_words = sum(got_n.values())
    ok = not wrong
    l2 = [v for v in matched if level[v] == 2]
    f2 = sum(len(flagged.get(v, [])) for v in l2)
    w2 = sum(got_n[v] for v in l2)
    print(f'{"OK  " if ok else "FAIL"}  words: {len(matched)} of {len(verses)} verses have word boxes '
          f'({100 * len(matched) / len(verses):.1f}%; level 2: {len(l2)}, {100 * len(l2) / len(verses):.1f}%), '
          f'{n_words} words; word count differs from ours: {len(wrong)}; '
          f'words far from their font width (for a look): {sum(len(x) for x in flagged.values())} in {len(flagged)} verses '
          f'({f2} of {w2} words at level 2)')
    l0 = [v for v in boxed if level[v] == 0]
    f0 = sum(len(flagged.get(v, [])) for v in l0)
    w0 = sum(got_n[v] for v in l0)
    print(f'      plus {len(l0)} verses with their best split, not confirmed (level 0): {w0} words, '
          f'{f0} far from their font width; {len(verses) - len(boxed)} verses without word boxes')
    PREVIEW.mkdir(parents=True, exist_ok=True)
    with open(PREVIEW / 'flagged_words.txt', 'w') as f:
        for v, ws in sorted(flagged.items()):
            f.write(f'{v[0]}:{v[1]} level {level[v]} words {ws}\n')
    if not ok:
        hard.append('words')
    rv = g.execute('SELECT kind, COUNT(*) FROM review GROUP BY kind').fetchall()
    print(f'      review notes: {dict(rv)}')

    if '--preview' in argv:
        want = [int(p) for p in argv[argv.index('--preview') + 1:] if p.isdigit()]
        PREVIEW.mkdir(parents=True, exist_ok=True)
        for p in want:
            draw(g, p, flagged, level)
        print(f'      overlays for pages {want} in {PREVIEW}')
    return 1 if hard else 0


def draw(g, page, flagged, level):
    """Left: lines (blue), cuts (green), overflow (orange), markers (magenta).
    Right: verse boxes (tinted), word boxes (green/blue at level 2, orange at
    level 1, red when flagged by the width check)."""
    im = Image.open(SRC / 'pages' / f'{page:03d}.png').convert('RGBA')
    base = Image.new('RGBA', im.size, 'white')
    base.alpha_composite(im)
    base = base.convert('RGB')
    left, right = base.copy(), base.copy()
    d = ImageDraw.Draw(left, 'RGBA')
    for line, kind, surah, bl, y0, y1, x0, x1 in g.execute(
            'SELECT line, kind, surah, baseline, y0, y1, x0, x1 FROM line WHERE page = ?', (page,)):
        d.line((0, bl, 12, bl), fill=(0, 0, 255), width=3)
        d.text((14, bl - 12), f'{line} {kind}{"" if surah is None else " " + str(surah)}', fill=(0, 0, 255))
    for (y,) in g.execute('SELECT y FROM line_cut WHERE page = ?', (page,)):
        d.line((0, y, im.width, y), fill=(0, 160, 0), width=1)
    for line, x0, y0, x1, y1 in g.execute('SELECT line, x0, y0, x1, y1 FROM line_overflow WHERE page = ?', (page,)):
        d.rectangle((x0, y0, x1 - 1, y1 - 1), outline=(255, 140, 0))
    for s, a, x0, y0, x1, y1 in g.execute('SELECT surah, ayah, x0, y0, x1, y1 FROM marker WHERE page = ?', (page,)):
        d.rectangle((x0, y0, x1 - 1, y1 - 1), outline=(220, 0, 220), width=2)
        d.text((x0, y1 + 1), f'{s}:{a}', fill=(220, 0, 220))
    d = ImageDraw.Draw(right, 'RGBA')
    colours = [(255, 0, 0, 40), (0, 0, 255, 40), (0, 160, 0, 40)]
    for i, (s, a, x0, y0, x1, y1) in enumerate(g.execute(
            'SELECT surah, ayah, x0, y0, x1, y1 FROM verse_box WHERE page = ? ORDER BY surah, ayah, part', (page,))):
        d.rectangle((x0, y0, x1 - 1, y1 - 1), fill=colours[a % 3])
    for s, a, wn, x0, y0, x1, y1 in g.execute(
            'SELECT surah, ayah, word, x0, y0, x1, y1 FROM word_box WHERE page = ?', (page,)):
        c = ((255, 0, 0) if wn in flagged.get((s, a), []) else (230, 130, 0) if level[(s, a)] == 1
             else (0, 120, 0) if wn % 2 else (0, 0, 200))
        d.rectangle((x0, y0, x1 - 1, y1 - 1), outline=c, width=1)
    out = Image.new('RGB', (im.width * 2 + 10, im.height), 'white')
    out.paste(left, (0, 0))
    out.paste(right, (im.width + 10, 0))
    out.save(PREVIEW / f'{page:03d}.png')


if __name__ == '__main__':
    sys.exit(main())
