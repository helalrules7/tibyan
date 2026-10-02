"""Word boxes for the new Madina edition (1441H), derived from page geometry.

The quran-ws page SVGs draw each page as one outline path, with a separate
outline (a union of rectangles) per verse. There are no per-word shapes.
This script finds each word's box without touching the text:

1. Split the page path into contours and assign each to its verse outline.
2. Per line, find the baseline (the row with the most ink) and take every
   contour that crosses it as a "piece" (a run of joined letters).
3. The KFGQPC text predicts how many pieces each word has: letters such as
   ا د ذ ر ز و never join the next letter. Dynamic programming splits each
   verse's pieces into its words, matching those counts, preferring wide
   gaps, and preferring widths close to the word's width in the KFGQPC
   font (`word_font_widths.json`, measured by measure_font_widths.py).
4. Marks and dots join the nearest piece; a word's box is the union of its
   contours.

Verses where every word got exactly its predicted piece count are marked
exact = 1. verify_word_boxes.py cross-checks the result and draws pages
for human review.

Inputs:  tools/.cache/hafs-kfqc-svg.zip, tools/.cache/UthmanicHafs_v2-0.zip,
         tools/word_font_widths.json
Usage:   called by build_content_db.py; or `python3 tools/build_word_boxes.py`
         to print statistics.
"""
import json
import math
import re
import statistics
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CACHE = ROOT / '.cache'
SVG_ZIP = CACHE / 'hafs-kfqc-svg.zip'
TEXT_ZIP = CACHE / 'UthmanicHafs_v2-0.zip'
FONT_WIDTHS = ROOT / 'word_font_widths.json'

HIZB = '۞'  # ۞, drawn on the line but not a word

# Tuned on pages 3-119 and checked by eye on pages 1, 2, 42, 50 and 226.
MERGE_FRAC = 0.3      # merge two pieces only when their cores overlap this much
EXTRA, MISSING = 1.0, 3.0   # cost per extra / missing piece in a word
GAP_WEIGHT = 0.35     # reward for cutting at a wide gap
WIDTH_WEIGHT = 2.0    # cost for a word much wider or narrower than expected
MARK_H_WEIGHT = 6.0   # marks join letters mostly above or below them

# ---------------------------------------------------------------- geometry

NUM = r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?'
TOKENS = re.compile(r'[MmLlHhVvCcSsQqZz]|' + NUM)
SVG_NS = '{http://www.w3.org/2000/svg}'


def parse_transform(text):
    m = (1, 0, 0, 1, 0, 0)
    for name, args in re.findall(r'(\w+)\(([^)]*)\)', text or ''):
        v = [float(x) for x in re.findall(NUM, args)]
        if name == 'matrix':
            n = tuple(v)
        elif name == 'translate':
            n = (1, 0, 0, 1, v[0], v[1] if len(v) > 1 else 0)
        elif name == 'scale':
            n = (v[0], 0, 0, v[1] if len(v) > 1 else v[0], 0, 0)
        else:
            raise ValueError(name)
        m = compose(m, n)
    return m


def compose(m, n):
    a, b, c, d, e, f = m
    A, B, C, D, E, F = n
    return (a * A + c * B, b * A + d * B, a * C + c * D, b * C + d * D,
            a * E + c * F + e, b * E + d * F + f)


def contours(d):
    """Subpaths of a path as lists of points (on-curve and control points)."""
    toks = TOKENS.findall(d)
    i, cmd = 0, None
    x = y = sx = sy = 0.0
    out, cur = [], []

    def num():
        nonlocal i
        i += 1
        return float(toks[i - 1])

    while i < len(toks):
        if toks[i].isalpha():
            cmd = toks[i]
            i += 1
            if cmd in 'Zz':
                x, y = sx, sy
                continue
        rel, c = cmd.islower(), cmd.upper()
        if c == 'M':
            dx, dy = num(), num()
            x, y = (x + dx, y + dy) if rel else (dx, dy)
            if cur:
                out.append(cur)
            cur, sx, sy = [(x, y)], x, y
            cmd = 'l' if rel else 'L'
        elif c == 'L':
            dx, dy = num(), num()
            x, y = (x + dx, y + dy) if rel else (dx, dy)
            cur.append((x, y))
        elif c == 'H':
            dx = num()
            x = x + dx if rel else dx
            cur.append((x, y))
        elif c == 'V':
            dy = num()
            y = y + dy if rel else dy
            cur.append((x, y))
        else:  # C, S, Q
            pts = []
            for _ in range(3 if c == 'C' else 2):
                dx, dy = num(), num()
                pts.append((x + dx, y + dy) if rel else (dx, dy))
            cur.extend(pts)
            x, y = pts[-1]
    if cur:
        out.append(cur)
    return out


def read_page(svg_text):
    """Returns ([(bbox, points)] for the page text, [(surah, ayah, [polygon])])."""
    items, verses = [], []

    def walk(el, m, in_content):
        m = compose(m, parse_transform(el.get('transform')))
        in_content = in_content or el.get('id') == 'content'
        if el.tag == SVG_NS + 'path':
            if el.get('class') == 'ayahPolygon':
                parts = [[apply(m, p) for p in c] for c in contours(el.get('d'))]
                verses.append((int(el.get('surah')), int(el.get('ayah')), parts))
            elif in_content:
                for c in contours(el.get('d')):
                    pts = [apply(m, p) for p in c]
                    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
                    items.append(((min(xs), min(ys), max(xs), max(ys)), pts))
        for child in el:
            walk(child, m, in_content)

    walk(ET.fromstring(svg_text), (1, 0, 0, 1, 0, 0), False)
    return items, verses


def apply(m, p):
    a, b, c, d, e, f = m
    return a * p[0] + c * p[1] + e, b * p[0] + d * p[1] + f


def inside(pt, poly):
    x, y = pt
    hit, j = False, len(poly) - 1
    for i in range(len(poly)):
        (xi, yi), (xj, yj) = poly[i], poly[j]
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi:
            hit = not hit
        j = i
    return hit


def crossings(pts, y):
    """Intervals where the horizontal line y is inside the contour (even-odd)."""
    xs = []
    for i in range(len(pts)):
        (x1, y1), (x2, y2) = pts[i], pts[(i + 1) % len(pts)]
        if (y1 > y) != (y2 > y):
            xs.append(x1 + (y - y1) * (x2 - x1) / (y2 - y1))
    xs.sort()
    return list(zip(xs[0::2], xs[1::2]))

# ------------------------------------------------------------------- text


RIGHT_JOINING = set('آأؤإاةدذرزوٱ')
NON_JOINING = {'ء'}
LETTERS = {chr(c) for c in range(0x0621, 0x064B)} | {'ٱ', 'ـ'}


def predicted_pieces(word):
    """Runs of joined letters in a word. Small waw and small yeh (ۥ ۦ) are
    drawn on the line as pieces of their own."""
    if word == HIZB:
        return 1
    letters = [ch for ch in word if ch in LETTERS]
    n = 1 + sum(ch in 'ۥۦ' for ch in word)
    for a, b in zip(letters, letters[1:]):
        if a in RIGHT_JOINING or a in NON_JOINING or b in NON_JOINING:
            n += 1
    return n


def load_text():
    """{(surah, ayah): [tokens]} from the KFGQPC text, verse number removed."""
    with zipfile.ZipFile(TEXT_ZIP) as z:
        rows = json.loads(z.read('UthmanicHafs_v2-0 data/hafsData_v2-0.json'))
    return {(r['sura_no'], r['aya_no']): [t for t in re.split(r'[  ]', r['aya_text'])[:-1] if t]
            for r in rows}

# ------------------------------------------------------------ segmentation


def page_segments(svg_text):
    """[(verse, line, pieces, contours)] for one page. pieces are
    (x0, x1, [bbox...]) right to left; contours are (bbox, points)."""
    items, verses = read_page(svg_text)
    ys = sorted((b[1] + b[3]) / 2 for b, _ in items if b[3] - b[1] > 8)
    groups = [[ys[0]]]
    for v in ys[1:]:
        (groups[-1].append(v) if v - groups[-1][-1] < 6 else groups.append([v]))
    centers = [statistics.median(g) for g in groups if len(g) >= 3]

    per_line = {i: [] for i in range(len(centers))}
    for bbox, pts in items:
        cy = (bbox[1] + bbox[3]) / 2
        li = min(range(len(centers)), key=lambda i: abs(centers[i] - cy))
        c = ((bbox[0] + bbox[2]) / 2, cy)
        verse = next(((s, a) for s, a, parts in verses if any(inside(c, p) for p in parts)), None)
        if verse:
            per_line[li].append((bbox, pts, verse))

    out = []
    for li, lst in per_line.items():
        big = [(b, pts) for b, pts, _ in lst if b[3] - b[1] > 8]
        if not big:
            continue
        best, base, y = -1, centers[li], centers[li] - 16
        while y <= centers[li] + 16:
            ink = sum(b - a for bb, pts in big if bb[1] <= y <= bb[3] for a, b in crossings(pts, y))
            if ink > best:
                best, base = ink, y
            y += 0.25
        by_verse = {}
        for bbox, pts, verse in lst:
            by_verse.setdefault(verse, []).append((bbox, pts))
        for verse, cs in by_verse.items():
            cores = []
            for bbox, pts in cs:
                if bbox[3] - bbox[1] < 2.5 or not (bbox[1] <= base + 1 and bbox[3] >= base - 1):
                    continue
                xs = [x for dy in (-1.0, 0.0, 1.0) for a, b in crossings(pts, base + dy) for x in (a, b)]
                if xs:
                    cores.append((min(xs), max(xs), bbox))
            cores.sort(key=lambda c: -(c[0] + c[1]))
            pieces = []
            for x0, x1, bbox in cores:
                if pieces:
                    p0, p1, boxes = pieces[-1]
                    overlap = min(p1, x1) - max(p0, x0)
                    if overlap > 0 and overlap >= MERGE_FRAC * min(p1 - p0, x1 - x0):
                        pieces[-1] = (min(p0, x0), max(p1, x1), boxes + [bbox])
                        continue
                pieces.append((x0, x1, [bbox]))
            out.append((verse, li, pieces, cs))
    return out


def align(segments, counts, expected=None):
    """Splits a verse's pieces (list per line segment) into words. Returns
    [(segment, first, last)] per word, or None."""
    comps = [(si, j) for si, seg in enumerate(segments) for j in range(len(seg))]
    n, W = len(comps), len(counts)
    best = [[math.inf] * (n + 1) for _ in range(W + 1)]
    back = [[None] * (n + 1) for _ in range(W + 1)]
    best[0][0] = 0.0
    for i in range(1, W + 1):
        k = counts[i - 1]
        for t in range(1, n + 1):
            seg_t = comps[t - 1][0]
            for s in range(t - 1, -1, -1):
                if comps[s][0] != seg_t:
                    break  # a word never spans two lines
                if best[i - 1][s] == math.inf:
                    continue
                m = t - s
                cost = best[i - 1][s] + (EXTRA * (m - k) if m >= k else MISSING * (k - m))
                if s > 0 and comps[s - 1][0] == seg_t:
                    a, b = segments[seg_t][comps[s - 1][1]], segments[seg_t][comps[s][1]]
                    cost -= GAP_WEIGHT * (a[0] - b[1])
                if expected:
                    seg = segments[seg_t]
                    w = seg[comps[s][1]][1] - seg[comps[t - 1][1]][0]
                    cost += WIDTH_WEIGHT * abs(math.log(max(w, 0.5) / expected[i - 1]))
                if cost < best[i][t]:
                    best[i][t], back[i][t] = cost, s
    if best[W][n] == math.inf:
        return None
    groups, t = [], n
    for i in range(W, 0, -1):
        s = back[i][t]
        groups.append((comps[s][0], comps[s][1], comps[t - 1][1]))
        t = s
    groups.reverse()
    # every line segment must start with a word
    if not {(si, 0) for si, seg in enumerate(segments) if seg} <= {(g[0], g[1]) for g in groups}:
        return None
    return groups


def layouts(pages=range(1, 605)):
    """Yields, per verse, how its contours split into its words:
    (verse, tokens, segs, groups, exact, owner). segs are the verse's line
    segments [(page, line, pieces, contours)]; groups[word index] is
    (segment, first piece, last piece); owner maps id(bbox) of every
    contour to its word index (tokens include ۞)."""
    text = load_text()
    font_widths = json.loads(FONT_WIDTHS.read_text(encoding='utf-8'))
    by_verse = {}
    with zipfile.ZipFile(SVG_ZIP) as z:
        for page in pages:
            for verse, li, pieces, cs in page_segments(z.read(f'svg/{page:03d}.svg').decode()):
                by_verse.setdefault(verse, []).append((page, li, pieces, cs))
    for verse, segs in by_verse.items():
        segs.sort(key=lambda s: (s[0], s[1]))
        tokens = text[verse]
        segments = [pieces for _, _, pieces, _ in segs]
        counts = [predicted_pieces(w) for w in tokens]
        groups = align(segments, counts)
        if groups is None:
            raise RuntimeError(f'no alignment for {verse}')
        widths = [font_widths[w] for w in tokens]
        scale = statistics.median((segments[si][a][1] - segments[si][b][0]) / f
                                  for (si, a, b), f in zip(groups, widths))
        groups = align(segments, counts, [scale * f for f in widths]) or groups
        exact = all(b - a + 1 == c for (_, a, b), c in zip(groups, counts))

        owner, by_page = {}, {}
        for wi, (si, a, b) in enumerate(groups):
            for piece in segments[si][a:b + 1]:
                for bbox in piece[2]:
                    owner[id(bbox)] = wi
                    by_page.setdefault(segs[si][0], []).append((bbox, wi))
        for page, _, _, cs in segs:
            for bbox, _ in cs:
                if id(bbox) in owner:
                    continue

                def dist(pb):
                    dx = max(pb[0] - bbox[2], bbox[0] - pb[2], 0)
                    dy = max(pb[1] - bbox[3], bbox[1] - pb[3], 0)
                    return (MARK_H_WEIGHT * dx) ** 2 + dy * dy
                owner[id(bbox)] = min(by_page[page], key=lambda c: dist(c[0]))[1]
        yield verse, tokens, segs, groups, exact, owner


def build(pages=range(1, 605)):
    """Returns {(surah, ayah): (exact, [(word_no, page, x0, y0, x1, y1)])}.
    Word numbers count words only (۞ is skipped), from 1."""
    result = {}
    for verse, tokens, segs, _, exact, owner in layouts(pages):
        boxes = [None] * len(tokens)
        for page, _, _, cs in segs:
            for bbox, _ in cs:
                wi = owner[id(bbox)]
                cur = boxes[wi]
                boxes[wi] = (page, *bbox) if cur is None else (
                    page, min(cur[1], bbox[0]), min(cur[2], bbox[1]),
                    max(cur[3], bbox[2]), max(cur[4], bbox[3]))
        words, n = [], 0
        for token, box in zip(tokens, boxes):
            if token == HIZB:
                continue
            n += 1
            words.append((n, *box))
        result[verse] = (exact, words)
    return result


if __name__ == '__main__':
    res = build()
    exact = sum(e for e, _ in res.values())
    print(f'{len(res)} verses, {sum(len(w) for _, w in res.values())} words, '
          f'{exact} verses with every word matching its predicted pieces')
    sys.exit(0)
