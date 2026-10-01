"""Catchword boxes for the Shamarly mushaf: under each page the app shows the
next page's first word, cut from the next page's image (ink only, drawn in
the page's ink colour). This finds that word's box.

Nothing here reads, writes or changes Quran text. The text of content.db is
only used to COUNT a word's joined-letter pieces (build_shamarly.piece_range),
as build_shamarly.py does.

Method (image px, 886x1377), for every page p = 3..521 whose next page q
opens with a text line (a page opening with a surah header or a basmala
keeps the basmala catchword, drawn as text):

1. The pieces of q's first line (build_shamarly.analyse: components standing
   on the baseline), right to left, and every other component of that line
   (dots, marks) given to its nearest piece.
2. The word starting q is the verse's word number first_word_index[q]
   (quran_android issue #1180); its piece range limits where it can end.
   Inside that range the cut goes at the widest gap between two pieces.
3. The box is the union of the chosen word's components. It must be clean:
   no pixel of another component (the next word, the line below, a margin
   mark) inside it. When one word gives no clean box, two words are tried
   the same way. Never more, never part of a word.
4. HAND overrides the choice (words 1 or 2) for pages where the gap rule
   misjudged a word end; every box was checked by eye on contact sheets
   (--sheets).

Output: tools/.cache/shamarly_catchword.json [[page, x0, y0, x1, y1, words]]
read by build_content_db.py into table shamarly_catchword.

Usage: python3 tools/build_shamarly_catchword.py [--pages 3-521] [--sheets DIR]
"""
import argparse
import json
import statistics
import sqlite3
import sys
from multiprocessing import Pool
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_shamarly as SH  # noqa: E402
import build_word_boxes as B  # noqa: E402
import shamarly_image as S  # noqa: E402

ROOT = Path(__file__).resolve().parent
CACHE = ROOT / '.cache'
OUT = CACHE / 'shamarly_catchword.json'
PAD = 2                        # px of paper kept round the ink
STRIP = 4                      # width of the erase strips
ALIF_W = 14                    # an alif is no wider than this (px)
STAR = dict(w=(14, 21), px=(120, 210))   # the hizb star (۞) drawn on the line

# Set by eye on the contact sheets (--sheets), where the split put a piece
# or a mark of the first word into the second (or the reverse): page ->
# x (px) such that the first word is the components of the first line whose
# centre lies right of it; WORDS: pages whose box holds two words.
HAND = {}
WORDS = {}


def verse_tokens():
    order, tokens = SH.verse_list()
    return {v: [t for t in toks if t != B.HIZB] for v, toks in tokens.items()}


def first_verse(geo, q, line):
    """(surah, ayah) of the rightmost verse box on line `line` of page q."""
    row = geo.execute('SELECT surah, ayah FROM verse_box WHERE page = ? AND line = ? '
                      'ORDER BY x1 DESC LIMIT 1', (q, line)).fetchone()
    return tuple(row) if row else None


def pieces_of(r, line):
    """Pieces of a line right to left: [(x0, x1, [component])], merged as
    build_shamarly.split_words merges them; and the line's other components."""
    comps = [c for c in r['comps'] if c[5] == line and not c[6]]
    cores = r['cores']
    cs = sorted(((cores[c[0]][0], cores[c[0]][1], c) for c in comps if c[0] in cores),
                key=lambda t: -(t[0] + t[1]))
    pieces = []
    for x0, x1, c in cs:
        if pieces:
            p0, p1, members = pieces[-1]
            overlap = min(p1, x1) - max(p0, x0)
            if overlap > 0 and overlap >= SH.MERGE_FRAC * min(p1 - p0, x1 - x0):
                pieces[-1] = (min(p0, x0), max(p1, x1), members + [c])
                continue
        pieces.append((x0, x1, [c]))
    in_piece = {c[0] for _, _, m in pieces for c in m}
    marks = [c for c in comps if c[0] not in in_piece]
    return pieces, marks


def owners(pieces, marks):
    """Index of the piece each mark belongs to (nearest, as split_words)."""
    out = {}
    for c in marks:
        def dist(pc):
            dx = max(pc[1] - c[3], c[1] - pc[3], 0)
            dy = max(pc[2] - c[4], c[2] - pc[4], 0)
            return (B.MARK_H_WEIGHT * dx) ** 2 + dy * dy
        best = min(((dist(pc), i) for i, (_, _, m) in enumerate(pieces) for pc in m))
        out[c[0]] = best[1]
    return out


def box_for(pieces, marks, own, n):
    """Components and box of the first n pieces with their marks."""
    ks = [c for _, _, m in pieces[:n] for c in m] + [c for c in marks if own[c[0]] < n]
    x0 = min(c[1] for c in ks)
    y0 = min(c[2] for c in ks)
    x1 = max(c[3] for c in ks)
    y1 = max(c[4] for c in ks)
    return {c[0] for c in ks}, (x0, y0, x1, y1)


def word_ends(pieces, rng, start):
    """Candidate ends (piece counts) of a word starting at piece `start`,
    best first: inside its piece range, widest gap first."""
    lo, hi = rng
    ends = []
    for n in range(start + lo, start + hi + 1):
        if n >= len(pieces):
            break
        gap = pieces[n - 1][0] - pieces[n][1]
        ends.append((gap, n))
    return [n for _, n in sorted(ends, reverse=True)]


def erase_rects(foreign_mask, mine, ox, oy):
    """Rectangles (page px) covering every pixel of foreign_mask and no
    pixel of mine: per foreign component its tight box when that is clean,
    else STRIP-wide column strips, else the runs of each column."""
    out = []
    labels, boxes, _ = S.label(foreign_mask)
    for k in range(1, len(boxes)):
        x0, y0, x1, y1 = (int(v) for v in boxes[k])
        comp = labels[y0:y1, x0:x1] == k
        if not mine[y0:y1, x0:x1].any():
            out.append((ox + x0, oy + y0, ox + x1, oy + y1))
            continue
        for sx in range(x0, x1, STRIP):
            m = comp[:, sx - x0:sx - x0 + STRIP]
            if not m.any():
                continue
            yy, xx = np.nonzero(m)
            r = (sx + int(xx.min()), y0 + int(yy.min()), sx + int(xx.max()) + 1, y0 + int(yy.max()) + 1)
            if not mine[r[1]:r[3], r[0]:r[2]].any():
                out.append((ox + r[0], oy + r[1], ox + r[2], oy + r[3]))
                continue
            for cx in range(r[0], r[2]):
                col = np.flatnonzero(comp[:, cx - x0])
                if not len(col):
                    continue
                start = prev = int(col[0])
                for y in list(col[1:]) + [None]:
                    if y is not None and y == prev + 1:
                        prev = int(y)
                        continue
                    out.append((ox + cx, oy + y0 + start, ox + cx + 1, oy + y0 + prev + 1))
                    if y is not None:
                        start = prev = int(y)
    return out


def first_word(q, r, segs, toks, font_widths, cut=None):
    """Components of the first word printed on page q, and how sure that is.

    segs: [(line, x0, x1)] the parts of the page's first verse on page q;
    toks: its tokens printed on page q (۞ kept: this calligraphy draws the
    hizb star on the line, as a piece). The pieces of those parts are split
    into the tokens as build_shamarly.split_words does (dynamic programming
    over piece counts, gaps and font widths, four ways); the first word is
    sure when all four splits end it at the same piece."""
    segments = []
    for line, x0, x1 in segs:
        comps = [c for c in r['comps'] if c[5] == line and not c[6] and x0 <= (c[1] + c[3]) / 2 < x1]
        segments.append((q, line, comps, r['cores']))
    if toks[0] == B.HIZB:
        # the hizb star opening the line is not a word: leave it out (it
        # is erased from the box if it reaches into it)
        comps = segments[0][2]
        star = max(comps, key=lambda c: c[3])
        w, h, px = star[3] - star[1], star[4] - star[2], star[7]
        assert STAR['w'][0] <= w <= STAR['w'][1] and STAR['w'][0] <= h <= STAR['w'][1] \
            and STAR['px'][0] <= px <= STAR['px'][1], f'page {q}: no hizb star {star}'
        comps.remove(star)
        toks = toks[1:]
    if cut is not None:
        # set by hand: the components right of x = cut
        return [c for c in segments[0][2] if (c[1] + c[3]) / 2 >= cut], True
    pieces_of, units = [], []
    for _, _, comps, cores in segments:
        cs = sorted(((cores[c[0]][0], cores[c[0]][1], c) for c in comps if c[0] in cores),
                    key=lambda t: -(t[0] + t[1]))
        pieces = []
        for x0, x1, c in cs:
            if pieces:
                p0, p1, members = pieces[-1]
                overlap = min(p1, x1) - max(p0, x0)
                if overlap > 0 and overlap >= SH.MERGE_FRAC * min(p1 - p0, x1 - x0):
                    pieces[-1] = (min(p0, x0), max(p1, x1), members + [c])
                    continue
            pieces.append((x0, x1, [c]))
        pieces_of.append(pieces)
        units.append([(x0 * SH.PX_TO_UNITS, x1 * SH.PX_TO_UNITS, m) for x0, x1, m in pieces])
    ranges = [SH.piece_range(t) for t in toks]
    loose = [SH.piece_range(t, loose=True) for t in toks]
    splits = [SH.align(units, ranges), SH.align(units, loose)]
    first = splits[0] or splits[1]
    if first is None:
        return None
    try:
        widths = [font_widths[t] if t != B.HIZB else 0 for t in toks]
        scale = statistics.median((units[si][a][1] - units[si][b][0]) / f
                                  for (si, a, b), f in zip(first, widths) if f)
        expected = [max(scale * f, 0.5) for f in widths]
        splits += [SH.align(units, ranges, expected), SH.align(units, loose, expected)]
    except (KeyError, statistics.StatisticsError):
        pass
    splits = [s for s in splits if s]
    groups = splits[-2] if len(splits) >= 3 else splits[0]
    w = 0
    ends = {s[w] for s in splits}
    sure = len(splits) == 4 and len(ends) == 1
    # every piece to its token, then marks to the nearest piece on the line
    owner = {}
    for wi, (si, a, b) in enumerate(groups):
        for _, _, members in pieces_of[si][a:b + 1]:
            for c in members:
                owner[c[0]] = wi
    line0 = segments[0][2]
    placed = [c for c in line0 if c[0] in owner]
    # where the first word's pieces end and the second's begin, near the
    # baseline: a mark goes to the side of that border its centre is on
    # (the nearest piece would give the next word's first fatha, sitting
    # over the gap, to the first word)
    cores = r['cores']
    ends = [cores[c[0]][0] for c in placed if owner[c[0]] == w]
    starts = [cores[c[0]][1] for c in placed if owner[c[0]] == w + 1]
    border = (min(ends) + max(starts)) / 2 if ends and starts else None
    word = []
    for c in line0:
        wi = owner.get(c[0])
        if wi is None and border is not None:
            wi = w if (c[1] + c[3]) / 2 >= border else w + 1
        if wi is None:
            def dist(pc):
                dx = max(pc[1] - c[3], c[1] - pc[3], 0)
                dy = max(pc[2] - c[4], c[2] - pc[4], 0)
                return (B.MARK_H_WEIGHT * dx) ** 2 + dy * dy
            wi = owner[min(placed, key=dist)[0]]
        if wi == w:
            word.append(c)
    # The next word's wasla alif (ٱ) often stands so close that it (or the
    # wasla sign over it) goes to the first word: when the next word starts
    # with ٱ and the first does not end with an alif, a tall thin stroke
    # left of all the first word's pieces is that alif; it and the marks
    # just above it go.
    letters = [ch for ch in toks[w] if ch in B.LETTERS]
    if len(toks) > w + 1 and toks[w + 1].startswith('ٱ') and letters[-1] not in SH.ALIFS:
        body = [c for c in word if owner.get(c[0]) == w and c[0] in cores]
        for c in sorted(word, key=lambda c: c[1] + c[3]):
            tall = c[3] - c[1] <= ALIF_W and c[4] - c[2] >= SH.TALL_H
            others = [o for o in body if o is not c]
            if tall and others and (c[1] + c[3]) / 2 < min((o[1] + o[3]) / 2 for o in others):
                above = [m for m in word if m is not c and min(m[3], c[3]) - max(m[1], c[1]) > 0
                         and 0 <= c[2] - m[4] <= 15]
                word = [m for m in word if m is not c and m not in above]
                break
    return word, sure


def solve(args):
    q, line, segs, toks, font_widths = args
    r = SH.analyse(q)
    im = Image.open(S.PAGES / f'{q:03d}.png')
    opaque = np.asarray(im.getchannel('A')) > 127
    ink, _ = S.load(q)
    labels, _, _ = S.label(ink)
    word, sure = first_word(q, r, segs, toks, font_widths, HAND.get(q - 1))
    ids = {c[0] for c in word}
    x0 = min(c[1] for c in word)
    y0 = min(c[2] for c in word)
    x1 = max(c[3] for c in word)
    y1 = max(c[4] for c in word)
    b = (max(0, x0 - PAD), max(0, y0 - PAD), min(S.W, x1 + PAD), min(S.H, y1 + PAD))
    lab = labels[b[1]:b[3], b[0]:b[2]]
    mine = np.isin(lab, list(ids))
    other = opaque[b[1]:b[3], b[0]:b[2]] & ~mine
    erase = erase_rects(other, mine, b[0], b[1])
    return dict(page=q - 1, next=q, line=line, words=WORDS.get(q - 1, 1), sure=sure, box=b, erase=erase,
                hand=q - 1 in HAND, tokens=toks[:3])


def sheets(results, out_dir):
    """Contact sheets, 40 crops each: the crop as the app draws it (black),
    the ink it erases (light red), and the line to its left (grey)."""
    out_dir.mkdir(parents=True, exist_ok=True)
    per, cols, cell_w, cell_h = 40, 4, 440, 170
    for s in range(0, len(results), per):
        chunk = results[s:s + per]
        sheet = Image.new('RGB', (cell_w * cols, cell_h * (per // cols)), 'white')
        d = ImageDraw.Draw(sheet)
        for i, r in enumerate(chunk):
            im = Image.open(S.PAGES / f"{r['next']:03d}.png")
            a = np.asarray(im.getchannel('A')) > 127
            x0, y0, x1, y1 = r['box']
            ctx_x0 = max(0, x0 - 170)
            reg = a[y0:y1, ctx_x0:x1]
            rgb = np.full(reg.shape + (3,), 255, np.uint8)
            rgb[reg] = (170, 170, 170)
            keep = np.zeros_like(a)
            keep[y0:y1, x0:x1] = a[y0:y1, x0:x1]
            gone = np.zeros_like(a)
            for e0, f0, e1, f1 in r['erase']:
                gone[f0:f1, e0:e1] = True
            keep &= ~gone
            gone &= a
            rgb[keep[y0:y1, ctx_x0:x1]] = (0, 0, 0)
            rgb[gone[y0:y1, ctx_x0:x1]] = (255, 150, 150)
            img = Image.fromarray(rgb)
            scale = min(1.5, (cell_w - 10) / img.width, (cell_h - 24) / img.height)
            img = img.resize((int(img.width * scale), int(img.height * scale)), Image.LANCZOS)
            cx, cy = (i % cols) * cell_w, (i // cols) * cell_h
            sheet.paste(img, (cx + cell_w - img.width - 5, cy + 20))
            bx = cx + cell_w - 5 - int((x1 - x0) * scale)
            d.rectangle((bx - 1, cy + 19, cx + cell_w - 4, cy + 20 + img.height), outline=(60, 120, 230))
            d.text((cx + 6, cy + 4), f"page {r['page']}  ({r['words']} word{'s' if r['words'] > 1 else ''})"
                   f"{'' if r['sure'] else '  - splits disagree'}{'  (hand)' if r['hand'] else ''}",
                   fill=(0, 0, 180) if r['sure'] else (200, 0, 0))
            d.rectangle((cx, cy, cx + cell_w - 1, cy + cell_h - 1), outline=(215, 215, 215))
        sheet.save(out_dir / f'sheet_{s // per + 1:02d}.png')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--pages', default='3-521')
    ap.add_argument('--sheets')
    ap.add_argument('--jobs', type=int, default=8)
    a = ap.parse_args()
    lo, hi = (int(v) for v in a.pages.split('-'))
    geo = sqlite3.connect(f'file:{SH.OUT}?mode=ro', uri=True)
    _, raw = SH.verse_list()
    fwi = SH.first_word_index()
    font_widths = json.loads(SH.FONT_WIDTHS.read_text(encoding='utf-8'))
    jobs = []
    skipped = []
    for p in range(lo, hi + 1):
        q = p + 1
        first = geo.execute('SELECT kind FROM line WHERE page = ? ORDER BY line LIMIT 1', (q,)).fetchone()[0]
        if first != 'text':
            skipped.append((p, first))
            continue
        v = first_verse(geo, q, 0)
        start_page, end_page = geo.execute('SELECT page, end_page FROM ayah WHERE surah = ? AND ayah = ?',
                                           v).fetchone()
        toks = raw[v]
        words = [i for i, t in enumerate(toks) if t != B.HIZB]
        begin = 0 if start_page == q else words[fwi[q]]
        end = len(toks) if end_page == q else words[fwi[q + 1]]
        segs = geo.execute('SELECT line, x0, x1 FROM verse_box WHERE surah = ? AND ayah = ? AND page = ? '
                           'ORDER BY part', (*v, q)).fetchall()
        jobs.append((q, 0, segs, toks[begin:end], font_widths))
    with Pool(a.jobs) as pool:
        results = pool.map(solve, jobs, chunksize=4)
    one = sum(r['words'] == 1 for r in results)
    print(f'{len(results)} boxes ({one} one word, {len(results) - one} two words); '
          f'{len(skipped)} pages keep the basmala (next page opens with a header or basmala): '
          f'{" ".join(str(p) for p, _ in skipped)}')
    if lo == 3 and hi == 521:
        OUT.write_text(json.dumps([[r['page'], *r['box'], r['words'],
                                    ' '.join(','.join(map(str, e)) for e in r['erase'])]
                                   for r in results]))
        print('wrote', OUT)
    if a.sheets:
        sheets(results, Path(a.sheets))
    json.dump(results, open(CACHE / 'shamarly_catchword_debug.json', 'w'), default=str)


if __name__ == '__main__':
    main()
