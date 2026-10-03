"""Page geometry for the Shamarly (Egyptian) mushaf, from its page images.

Source N14 in docs/MISSING_DATA.md: 522 page images from archive.org
(details/shamerly, no licence; the owner allows it) and the verse points of
the open-source Shamarly Android app (shamerly.db). Nothing here reads,
writes or changes Quran text: the text of our own content.db is only used
to COUNT words and joined-letter pieces, exactly as build_word_boxes.py does.

Method (all in image pixels, 886x1377):

1. Ink. Pages 4-522 have a binary alpha: opaque black = text, opaque and
   coloured = surah-header frames and margin marks (never text). Pages 2-3
   are the ornate opening pages (RGB); their text is the dark ink inside the
   frame. Page 1 is the cover and is skipped.
2. Lines. Every text page has 15 line slots on a regular pitch (~88.6 px).
   Diacritics bridge the lines, so blank-row gaps do not work: the grid
   (top, pitch) is fitted per page to the baseline peaks of the row
   profile. Each line's baseline is the densest row within 6 px of the grid.
   A surah-header frame (coloured) covers exactly two slots; the slot after
   it is the basmala (not for at-Tawba). Pages 2-3 have 7 lines each.
3. Cuts. Between two lines, the row where the fewest ink components cross
   (ties: the middle one), as build_line_cuts.old_edition does. A component
   that still crosses belongs to the line whose letter body it touches; the
   part of it on the other side of the cut is recorded as small rectangles
   (8 px wide column strips), so the app can draw it with its own line.
4. Verse-end markers. The marker is a scalloped ring round the verse
   number. It is found by its counter: the enclosed background inside one
   ink component, 30-41 x 33-43 px and 550-1150 px in area (bigger on
   pages 2-3), unioning the counters the digits split it into. A ring with
   a broken outline is taken by its size right at its point. Each marker
   is paired with a (surah, ayah) of shamerly.db on the same page: in
   reading order, and its approximate point (≈ 4 px above-left of the
   ring's corner) must be within 30 px.
5. Verse regions. Each text line is split at its markers, right to left.
   The first segment of a page continues the verse left open on the
   previous page. One box per verse per line (band height).
6. Words. In every segment, components standing on the baseline are joined
   pieces; the KFGQPC word list predicts a range of pieces per word
   (piece_range); dynamic programming (align, after build_word_boxes.align)
   splits the pieces into words, preferring wide gaps and font-proportional
   widths. Four splits (strict and loose ranges, with and without widths):
   words_matched = 2 when all four agree and every word is in range, 1 when
   the two strict ones agree, else 0 (no word boxes). A verse running over a
   page break must also agree with the first-word index of quran_android
   issue #1180.

Anything that fails a check is left out and listed in `review`.

Output: tools/.cache/shamarly_geometry.db (SQLite; tables documented in
SCHEMA below). verify_shamarly.py re-checks it and prints the numbers.

Usage: python3 tools/build_shamarly.py [--pages 40-60] [--jobs 8]
"""
import argparse
import datetime
import hashlib
import json
import math
import re
import sqlite3
import statistics
import sys
from multiprocessing import Pool
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_word_boxes as B  # noqa: E402
import shamarly_image as S  # noqa: E402

ROOT = Path(__file__).resolve().parent
CACHE = ROOT / '.cache'
SRC = CACHE / 'shamarly'
POINTS_DB = SRC / 'shamerly.db'
FIRST_WORDS = SRC / 'shemerly_page_first_word_index.txt'
CONTENT = ROOT.parent / 'assets' / 'db' / 'content.db'
OUT = CACHE / 'shamarly_geometry.db'
FONT_WIDTHS = ROOT / 'word_font_widths.json'

LAST_PAGE = 522
LINES = 15                      # line slots on pages 4-522
ORNATE = {2: 7, 3: 7}           # opening pages: lines of text
ORNATE_BOX = (60, 320, 826, 1095)  # text area inside their frame
HEADER_ROWS = 500               # coloured px in a row of a header frame
MARKER = dict(w=(30, 41), h=(33, 43), area=(550, 1150))
MARKER_ORNATE = dict(w=(40, 52), h=(43, 55), area=(1200, 1800))
RING = dict(w=(40, 56), h=(42, 54), px=(450, 900))   # a marker ring alone (pages 4-522)
POINT_OFFSET = (4, 4)          # shamerly.db point ≈ ring corner - this
POINT_TOLERANCE = 30
STRIP = 8                       # width of overflow rectangles
CORE_REACH = 3                  # a piece reaches down to at least this far above the baseline
# Smaller components there are dots and marks. A damma after a final mim
# stands on the line as low as a small waw (ۥ) or a hamza (ء), so all of
# these are left out of the pieces, and piece_range allows for it.
CORE_MIN_H, CORE_MIN_PX = 20, 80
TALL_H, TALL_W, TALL_REACH = 24, 12, 10   # an alif standing on a hamza below (a dagger alif ends higher)
TOUCH_COST = 0.4                # a word drawing touching pieces as one
EXTRA = 3.0                    # a piece more than the word can have
HAMZA_MAX_PX = 70              # a hamza below an alif is smaller than this
MARGIN_X = (6, 876)             # ink wholly outside these columns is a margin mark
CORE_BAND = 10                # rows above the baseline that give a piece's extent
MERGE_FRAC = 2                 # never merge: pieces overlap a lot in this calligraphy
PX_TO_UNITS = 345 / 886         # build_word_boxes.align is tuned in 1441 units

SCHEMA = """
CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
CREATE TABLE page (                 -- one row per page image 1..522
  page INTEGER PRIMARY KEY,
  kind TEXT NOT NULL,               -- cover | ornate | text
  lines INTEGER NOT NULL,           -- line slots (15; 7 on the ornate pages)
  grid_top REAL, pitch REAL);       -- fitted baseline grid: baseline j = grid_top + j * pitch
CREATE TABLE line (                 -- every line slot
  page INTEGER NOT NULL, line INTEGER NOT NULL,   -- line 0-based
  kind TEXT NOT NULL,               -- text | header | basmala | empty
  surah INTEGER,                    -- for header and basmala slots
  baseline INTEGER NOT NULL,        -- densest ink row of the line (px)
  y0 INTEGER NOT NULL, y1 INTEGER NOT NULL,   -- band: previous cut .. next cut (page ink edge at the ends)
  x0 INTEGER, x1 INTEGER,           -- ink extent of the line
  PRIMARY KEY (page, line));
CREATE TABLE line_cut (             -- where to split a page into its lines
  page INTEGER NOT NULL, gap INTEGER NOT NULL,   -- gap j is below line j
  y INTEGER NOT NULL,               -- cut between image rows y-1 and y
  crossing INTEGER NOT NULL,        -- ink components crossing it
  PRIMARY KEY (page, gap));
CREATE TABLE line_overflow (        -- ink crossing a cut: rectangles on the far side, and their line
  page INTEGER NOT NULL, line INTEGER NOT NULL,
  x0 INTEGER NOT NULL, y0 INTEGER NOT NULL, x1 INTEGER NOT NULL, y1 INTEGER NOT NULL);
CREATE TABLE header (               -- printed surah-header frames (coloured)
  surah INTEGER PRIMARY KEY, page INTEGER NOT NULL,
  first_line INTEGER,               -- first of its two slots (NULL on pages 2-3, drawn in the ornament)
  x0 INTEGER NOT NULL, y0 INTEGER NOT NULL, x1 INTEGER NOT NULL, y1 INTEGER NOT NULL);
CREATE TABLE marker (               -- verse-end markers (ring box)
  surah INTEGER NOT NULL, ayah INTEGER NOT NULL,
  page INTEGER NOT NULL, line INTEGER NOT NULL,
  x0 INTEGER NOT NULL, y0 INTEGER NOT NULL, x1 INTEGER NOT NULL, y1 INTEGER NOT NULL,
  PRIMARY KEY (surah, ayah));
CREATE TABLE ayah (                 -- 6,236 verses
  surah INTEGER NOT NULL, ayah INTEGER NOT NULL,
  page INTEGER NOT NULL,            -- page where the verse starts (as content.db page_1405)
  end_page INTEGER NOT NULL,        -- page of its marker
  words INTEGER NOT NULL,           -- our word count (word_box numbering)
  words_matched INTEGER NOT NULL,   -- how sure the word split is: 2 stable; 1 the split changes with a looser piece count; 0 not confirmed (boxes are the best split, or none)
  PRIMARY KEY (surah, ayah));
CREATE TABLE verse_box (            -- one box per verse per line, reading order (part = 0..)
  surah INTEGER NOT NULL, ayah INTEGER NOT NULL, part INTEGER NOT NULL,
  page INTEGER NOT NULL, line INTEGER NOT NULL,
  x0 INTEGER NOT NULL, y0 INTEGER NOT NULL, x1 INTEGER NOT NULL, y1 INTEGER NOT NULL,
  PRIMARY KEY (surah, ayah, part));
CREATE TABLE word_box (             -- every verse with a split (any words_matched); word as in content.db word_box
  surah INTEGER NOT NULL, ayah INTEGER NOT NULL, word INTEGER NOT NULL,
  page INTEGER NOT NULL, line INTEGER NOT NULL,
  x0 INTEGER NOT NULL, y0 INTEGER NOT NULL, x1 INTEGER NOT NULL, y1 INTEGER NOT NULL,
  PRIMARY KEY (surah, ayah, word));
CREATE TABLE review (               -- everything left out, for a human
  page INTEGER, surah INTEGER, ayah INTEGER,
  kind TEXT NOT NULL, detail TEXT NOT NULL);
"""

# ------------------------------------------------------------------ inputs


def verse_list():
    """[(surah, ayah)] in mushaf order and {verse: tokens} (verse number
    removed, ۞ kept as a token) from content.db, read only."""
    db = sqlite3.connect(f'file:{CONTENT}?mode=ro', uri=True)
    order, tokens = [], {}
    for s, a, text in db.execute('SELECT surah, number, display_text FROM ayah ORDER BY id'):
        order.append((s, a))
        tokens[(s, a)] = [t for t in re.split('[ \u00a0]', text)[:-1] if t]
    return order, tokens


def points():
    """{page: [(surah, ayah, x, y)]} verse points of shamerly.db (ayah > 0).
    Its two ayah = 0 rows sit on the ornate surah titles of pages 2 and 3."""
    db = sqlite3.connect(f'file:{POINTS_DB}?mode=ro', uri=True)
    out = {}
    for p, s, a, x, y in db.execute('SELECT page, sura, ayah, x, y FROM mushaf WHERE ayah > 0 ORDER BY sura, ayah'):
        out.setdefault(p, []).append((s, a, x, y))
    return out


def first_word_index():
    """{page: index} from quran_android issue #1180: the 0-based index,
    within its verse, of the first word printed on the page."""
    out = {}
    for row in FIRST_WORDS.read_text().split()[1:]:
        p, i = row.split(',')[:2]      # one row (page 262) has a trailing comma
        if i.strip():
            out[int(p)] = int(i)
    return out


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

# ------------------------------------------------------------ page analysis


def fit_grid(prof, n, pitches, tops):
    best = None
    for P in pitches:
        ys = (tops[:, None] + P * np.arange(n)[None, :]).round().astype(int)
        ys = np.clip(ys, 2, len(prof) - 3)
        sc = np.maximum.reduce([prof[ys + d] for d in (-2, -1, 0, 1, 2)]).sum(1)
        i = int(sc.argmax())
        if best is None or sc[i] > best[0]:
            best = (sc[i], float(tops[i]), float(P))
    return best[1], best[2]


def header_frames(colour):
    """Coloured bands at least a header wide: [(x0, y0, x1, y1)]."""
    rows = np.flatnonzero(colour.sum(1) > HEADER_ROWS)
    groups = []
    for y in rows:
        if groups and y - groups[-1][-1] <= 15:
            groups[-1].append(int(y))
        else:
            groups.append([int(y)])
    out = []
    for g in groups:
        if g[-1] - g[0] < 100:
            continue
        cols = np.flatnonzero(colour[g[0]:g[-1] + 1].any(0))
        out.append((int(cols[0]), g[0], int(cols[-1]) + 1, g[-1] + 1))
    return out


def find_markers(ink, labels, ornate):
    """Ring boxes [(x0, y0, x1, y1)] of the verse-end markers."""
    lim = MARKER_ORNATE if ornate else MARKER
    bg, boxes, sizes = S.label(~ink)
    groups = {}
    h, w = ink.shape
    # topmost-leftmost pixel of every background region (first in raster order)
    ids, at = np.unique(bg.ravel(), return_index=True)
    first = {int(k): (int(i) // w, int(i) % w) for k, i in zip(ids, at)}
    for k in range(1, len(sizes)):
        x0, y0, x1, y1 = (int(v) for v in boxes[k])
        if x0 == 0 or y0 == 0 or x1 == w or y1 == h or sizes[k] < 30 or sizes[k] > 3000:
            continue
        fy, fx = first[k]
        ring = int(labels[fy - 1, fx])
        # counters of one component that fit in one marker together (a ring
        # can touch a letter, whose own counters then stay apart)
        for g in groups.setdefault(ring, []):
            u = (min(g[0], x0), min(g[1], y0), max(g[2], x1), max(g[3], y1))
            if u[2] - u[0] <= lim['w'][1] and u[3] - u[1] <= lim['h'][1]:
                g[:4] = u
                g[4] += int(sizes[k])
                break
        else:
            groups[ring].append([x0, y0, x1, y1, int(sizes[k])])
    out = []
    for ring, (x0, y0, x1, y1, area) in ((r, g) for r, gs in groups.items() for g in gs):
        if (lim['w'][0] <= x1 - x0 <= lim['w'][1] and lim['h'][0] <= y1 - y0 <= lim['h'][1]
                and lim['area'][0] <= area <= lim['area'][1]):
            m = 10 if ornate else 7
            wx, wy = max(0, x0 - m), max(0, y0 - m)
            win = labels[wy:y1 + m, wx:x1 + m] == ring
            yy, xx = np.nonzero(win)
            if ring == 0 or not len(yy):
                continue
            out.append(((wx + int(xx.min()), wy + int(yy.min()),
                         wx + int(xx.max()) + 1, wy + int(yy.max()) + 1), ring))
    return out


def own_rects(labels, line_map, k, x0, y0, x1, y1):
    """Rectangles covering component k's pixels in (x0, y0)-(x1, y1) and no
    ink of another line: the tight box if it is clean, else STRIP-wide
    column strips, else, where a strip still holds such ink, the pixel runs
    of each column."""
    lab = labels[y0:y1, x0:x1]
    mine = lab == k
    lines = line_map[y0:y1, x0:x1]
    j = lines[mine][0] if mine.any() else -1
    other = (lab != 0) & (lines != j)

    def tight(m, ox, oy):
        yy, xx = np.nonzero(m)
        return (ox + int(xx.min()), oy + int(yy.min()), ox + int(xx.max()) + 1, oy + int(yy.max()) + 1)

    if not mine.any():
        return []
    r = tight(mine, x0, y0)
    if not other[r[1] - y0:r[3] - y0, r[0] - x0:r[2] - x0].any():
        return [r]
    out = []
    for sx in range(0, x1 - x0, STRIP):
        m = mine[:, sx:sx + STRIP]
        if not m.any():
            continue
        r = tight(m, x0 + sx, y0)
        if not other[r[1] - y0:r[3] - y0, r[0] - x0:r[2] - x0].any():
            out.append(r)
            continue
        for cx in range(sx, min(sx + STRIP, x1 - x0)):
            col = np.flatnonzero(mine[:, cx])
            if not len(col):
                continue
            start = prev = int(col[0])
            for y in list(col[1:]) + [None]:
                if y is not None and y == prev + 1:
                    prev = int(y)
                    continue
                out.append((x0 + cx, y0 + start, x0 + cx + 1, y0 + prev + 1))
                if y is not None:
                    start = prev = int(y)
    return out


def analyse(page):
    """Everything one page image tells, without the verse data."""
    ornate = page in ORNATE
    ink, colour = S.load(page)
    if ornate:
        x0, y0, x1, y1 = ORNATE_BOX
        keep = np.zeros_like(ink)
        keep[y0:y1, x0:x1] = True
        ink = ink & keep
        colour = colour & ~keep
    labels, boxes, sizes = S.label(ink)
    n = len(sizes)
    frames = [] if ornate else header_frames(colour)
    prof = ink.sum(1).astype(float)
    if ornate:
        nlines = ORNATE[page]
        top, pitch = fit_grid(prof, nlines, np.arange(85, 101, 0.1), np.arange(380, 470, 0.5))
    else:
        nlines = LINES
        top, pitch = fit_grid(prof, nlines, np.arange(86.0, 91.01, 0.05), np.arange(60, 125.01, 0.5))
    grid = [top + j * pitch for j in range(nlines)]
    base = []
    for g in grid:
        lo = int(round(g)) - 6
        base.append(lo + int(prof[lo:lo + 13].argmax()))

    # header slots: a frame covers the two slots whose bodies it spans
    slot_kind = ['text'] * nlines
    frame_slot = []
    for f in frames:
        cy = (f[1] + f[3]) / 2
        # the frame is centred on the gap between its two slots' bodies
        j = int(round((cy - top + 0.35 * pitch) / pitch)) - 1
        j = max(0, min(nlines - 2, j))
        slot_kind[j] = slot_kind[j + 1] = 'header'
        frame_slot.append((f, j))

    # every component's line: the line whose letter body it touches most
    body = [(b - 0.34 * pitch, b + 0.06 * pitch) for b in base]

    def owner(y0, y1):
        best = None
        for j, (lo, hi) in enumerate(body):
            if slot_kind[j] == 'header':
                continue
            ov = min(y1, hi) - max(y0, lo)
            d = (0, -ov) if ov > 0 else (max(lo - y1, y0 - hi), 0)
            if best is None or d < best[0]:
                best = (d, j)
        return best[1]

    line_of = np.zeros(n, dtype=np.int32)
    for k in range(1, n):
        line_of[k] = owner(boxes[k][1], boxes[k][3])
    # margin marks (black parts of the coloured hizb signs) are not text
    margin = (boxes[:, 0] >= MARGIN_X[1]) | (boxes[:, 2] <= MARGIN_X[0])
    # dark parts of a header frame belong to its first slot and are not text
    window = {}                          # gap -> (lo, hi) forced by a frame
    for (fx0, fy0, fx1, fy1), j in frame_slot:
        inside = ((boxes[:, 0] >= fx0 - 3) & (boxes[:, 2] <= fx1 + 3)
                  & (boxes[:, 1] >= fy0 - 3) & (boxes[:, 3] <= fy1 + 3))
        line_of[inside] = j
        margin |= inside
        # the whole frame is drawn by its first slot: cut above and below it
        if j > 0:
            window[j - 1] = (None, fy0)
        window[j] = (fy1, fy1)
        if j + 1 < nlines - 1:
            window[j + 1] = (fy1, None)
    margin[0] = False

    # cuts: fewest crossing components in the gap between two bodies
    cross = np.zeros(ink.shape[0] + 1, dtype=np.int32)
    ks = np.arange(1, n)
    np.add.at(cross, boxes[ks, 1] + 1, 1)
    np.add.at(cross, boxes[ks, 3], -1)
    cross = np.cumsum(cross)            # cross[y]: components with pixels above and below y
    cuts, crossing = [], []
    for j in range(nlines - 1):
        lo = int(base[j] + 0.1 * pitch)
        hi = int(base[j + 1] - 0.3 * pitch)
        flo, fhi = window.get(j, (None, None))
        if flo is not None:
            lo = max(lo, flo) if fhi is None else flo
        if fhi is not None:
            hi = min(hi, fhi) if flo is None else fhi
        hi = max(hi, lo)
        c = cross[lo:hi + 1]
        low = int(c.min())
        rows = [lo + i for i in np.flatnonzero(c == low)]
        # among the best rows, the least ink, then the middle one
        inks = [prof[y] + prof[y - 1] for y in rows]
        best = [y for y, v in zip(rows, inks) if v == min(inks)]
        cuts.append(int(best[len(best) // 2]))
        crossing.append(low)

    edges = [0] + cuts + [ink.shape[0]]
    line_map = line_of[labels]
    overflow = []
    for k in range(1, n):
        x0, y0, x1, y1 = (int(v) for v in boxes[k])
        j = int(line_of[k])
        if y0 >= edges[j] and y1 <= edges[j + 1]:
            continue
        for lo, hi in ((y0, edges[j]), (edges[j + 1], y1)):
            if hi <= lo:
                continue
            overflow += [(j, *r) for r in own_rects(labels, line_map, k, x0, lo, x1, hi)]

    found = find_markers(ink, labels, ornate)
    markers = [m for m, _ in found]
    # components inside a marker (ring and digits) are not words; nor is a
    # ring that touches a letter (that verse's words then fail their count)
    in_marker = np.zeros(n, dtype=bool)
    for (mx0, my0, mx1, my1), ring in found:
        inside = ((boxes[:, 0] >= mx0 - 1) & (boxes[:, 2] <= mx1 + 1)
                  & (boxes[:, 1] >= my0 - 1) & (boxes[:, 3] <= my1 + 1))
        in_marker |= inside
        in_marker[ring] = True
    in_marker[0] = False

    lines = []
    for j in range(nlines):
        ks_j = [k for k in range(1, n) if line_of[k] == j and not margin[k]]
        if slot_kind[j] == 'header':
            ext = None
        elif ks_j:
            ext = (int(min(boxes[k][0] for k in ks_j)), int(max(boxes[k][2] for k in ks_j)))
        else:
            ext = None
            slot_kind[j] = 'empty'
        top_y = edges[j] if j else (int(min(boxes[k][1] for k in ks_j)) if ks_j else 0)
        bot_y = edges[j + 1] if j < nlines - 1 else (int(max(boxes[k][3] for k in ks_j)) if ks_j else ink.shape[0])
        lines.append(dict(kind=slot_kind[j], baseline=base[j], y0=top_y, y1=bot_y, ext=ext))

    comps = [(int(k), *(int(v) for v in boxes[k]), int(line_of[k]), bool(in_marker[k] or margin[k]), int(sizes[k]))
             for k in range(1, n)]
    # a hamza below an alif stands on the baseline but is not a piece: the
    # alif above it is (the "tall" rule below)
    hamza_below = set()
    alifs = [c for c in comps if c[4] - c[2] >= 20 and c[3] - c[1] <= 12]
    for k, x0, y0, x1, y1, j, mk, npx in comps:
        if mk or npx >= HAMZA_MAX_PX or y1 - y0 >= 16:
            continue
        for k2, a0, b0, a1, b1, j2, mk2, _ in alifs:
            if (j2 == j and k2 != k and 0 <= y0 - b1 <= 8
                    and min(x1, a1) - max(x0, a0) > 0):
                hamza_below.add(k)
                break
    # joined-letter pieces: components that stand on the baseline (dots and
    # marks there are smaller), and tall strokes ending a little above it
    # (an alif over a hamza below). Their x extent near the baseline.
    cores = {}
    for k, x0, y0, x1, y1, j, mk, npx in comps:
        b = base[j]
        if mk or y0 >= b or k in hamza_below:
            continue
        stands = y1 >= b - CORE_REACH and (npx >= CORE_MIN_PX or y1 - y0 >= CORE_MIN_H)
        tall = y1 - y0 >= TALL_H and x1 - x0 <= TALL_W and y1 >= b - TALL_REACH
        if not (stands or tall):
            continue
        # near the baseline only: tails below it reach under the next word
        lo = max(y0, min(b, y1) - CORE_BAND)
        band = labels[lo:min(y1, b + 3), x0:x1] == k
        if not band.any():
            band = labels[y0:y1, x0:x1] == k
        xx = np.flatnonzero(band.any(0))
        cores[k] = (x0 + int(xx.min()), x0 + int(xx.max()) + 1)
    # ring-sized components that are not markers (for rings with a broken outline)
    rings = [c for c in comps if not c[6] and RING['w'][0] <= c[3] - c[1] <= RING['w'][1]
             and RING['h'][0] <= c[4] - c[2] <= RING['h'][1] and RING['px'][0] <= c[7] <= RING['px'][1]]
    return dict(page=page, kind='ornate' if ornate else 'text', lines=lines, top=top, pitch=pitch,
                cuts=cuts, crossing=crossing, overflow=overflow, frames=frame_slot,
                markers=markers, comps=comps, cores=cores, rings=rings)

# ------------------------------------------------------------------- words


ALIFS = set('اٱأإآ')


def piece_range(word, loose=False):
    """(fewest, most) joined-letter pieces the Shamarly calligraphy draws for
    a word. The most is build_word_boxes.predicted_pieces (the KFGQPC
    count). This calligraphy often lets a standalone alif touch the lam after
    it (ٱل, إلا, ٱلله), and a small waw, yeh or hamza on the line is too
    small to be told from a mark, so each of those may take one piece off.
    loose: one more non-joining letter may touch the next (رو, كان)."""
    most = B.predicted_pieces(word)
    letters = [ch for ch in word if ch in B.LETTERS or ch in 'ۥۦ']
    touch = sum(1 for a, b in zip(letters, letters[1:]) if a in ALIFS and b == 'ل')
    touch += sum(ch in 'ۥۦء' for ch in word)
    if loose and any(a in B.RIGHT_JOINING and not (a in ALIFS and b == 'ل')
                     for a, b in zip(letters, letters[1:])):
        touch += 1
    return max(1, most - touch), most


def align(segments, ranges, expected=None, gap_weight=B.GAP_WEIGHT):
    """build_word_boxes.align with a range of piece counts per word: inside
    the range a missing piece costs TOUCH_COST, outside as there."""
    comps = [(si, j) for si, seg in enumerate(segments) for j in range(len(seg))]
    n, W = len(comps), len(ranges)
    best = [[math.inf] * (n + 1) for _ in range(W + 1)]
    back = [[None] * (n + 1) for _ in range(W + 1)]
    best[0][0] = 0.0
    for i in range(1, W + 1):
        lo, hi = ranges[i - 1]
        for t in range(1, n + 1):
            seg_t = comps[t - 1][0]
            for s in range(t - 1, -1, -1):
                if comps[s][0] != seg_t:
                    break  # a word never spans two lines
                if best[i - 1][s] == math.inf:
                    continue
                m = t - s
                if m > hi:
                    pen = EXTRA * (m - hi)
                elif m >= lo:
                    pen = TOUCH_COST * (hi - m)
                else:
                    pen = TOUCH_COST * (hi - lo) + B.MISSING * (lo - m)
                cost = best[i - 1][s] + pen
                if s > 0 and comps[s - 1][0] == seg_t:
                    a, b = segments[seg_t][comps[s - 1][1]], segments[seg_t][comps[s][1]]
                    cost -= gap_weight * (a[0] - b[1])
                if expected:
                    seg = segments[seg_t]
                    w = seg[comps[s][1]][1] - seg[comps[t - 1][1]][0]
                    cost += B.WIDTH_WEIGHT * abs(math.log(max(w, 0.5) / expected[i - 1]))
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
    if not {(si, 0) for si, seg in enumerate(segments) if seg} <= {(g[0], g[1]) for g in groups}:
        return None
    return groups


def split_words(segments, tokens, font_widths):
    """segments: [(page, line, [components])] of one verse in reading order.
    Returns (exact, [(token_index, page, line, box)]) or None."""
    segs, pieces_of = [], []
    for page, line, comps, cores in segments:
        cs = sorted(((cores[c[0]][0], cores[c[0]][1], c) for c in comps if c[0] in cores),
                    key=lambda t: -(t[0] + t[1]))
        pieces = []
        for x0, x1, c in cs:
            if pieces:
                p0, p1, members = pieces[-1]
                overlap = min(p1, x1) - max(p0, x0)
                if overlap > 0 and overlap >= MERGE_FRAC * min(p1 - p0, x1 - x0):
                    pieces[-1] = (min(p0, x0), max(p1, x1), members + [c])
                    continue
            pieces.append((x0, x1, [c]))
        pieces_of.append(pieces)
        segs.append([(x0 * PX_TO_UNITS, x1 * PX_TO_UNITS, m) for x0, x1, m in pieces])
    if sum(len(s) for s in segs) == 0:
        return None
    # Four splits: the strict and the loose piece counts, each with gaps
    # only and with gaps and font widths. level 2: all four agree and every
    # word has a piece count it can have (exact); level 1: exact, and the two
    # strict splits agree; else 0.
    ranges = [piece_range(t) for t in tokens]
    loose = [piece_range(t, loose=True) for t in tokens]
    first = align(segs, ranges)
    if first is None:
        return None
    groups, splits = first, [first]
    try:
        widths = [font_widths[t] for t in tokens]
        scale = statistics.median((segs[si][a][1] - segs[si][b][0]) / f
                                  for (si, a, b), f in zip(first, widths) if f)
        expected = [max(scale * f, 0.5) for f in widths]
        groups = align(segs, ranges, expected) or first
        splits += [groups, align(segs, loose), align(segs, loose, expected)]
    except (KeyError, statistics.StatisticsError):
        pass
    exact = all(lo <= b - a + 1 <= hi for (_, a, b), (lo, hi) in zip(groups, ranges))
    level = 0
    if exact and len(splits) == 4 and splits[0] == splits[1]:
        level = 2 if splits[1] == splits[2] == splits[3] else 1

    # every piece to its word, then marks to the nearest word on the line
    owner = {}
    for wi, (si, a, b) in enumerate(groups):
        for x0, x1, members in pieces_of[si][a:b + 1]:
            for c in members:
                owner[(si, c[0])] = wi
    boxes = [None] * len(tokens)

    def grow(wi, si, c):
        page, line = segments[si][0], segments[si][1]
        cur = boxes[wi]
        box = (c[1], c[2], c[3], c[4])
        boxes[wi] = (page, line, *box) if cur is None else (
            page, line, min(cur[2], box[0]), min(cur[3], box[1]), max(cur[4], box[2]), max(cur[5], box[3]))

    for si, (page, line, comps, cores) in enumerate(segments):
        placed = [(c, owner[(si, c[0])]) for c in comps if (si, c[0]) in owner]
        if not placed:
            continue
        for c in comps:
            wi = owner.get((si, c[0]))
            if wi is None:
                def dist(pc):
                    dx = max(pc[1] - c[3], c[1] - pc[3], 0)
                    dy = max(pc[2] - c[4], c[2] - pc[4], 0)
                    return (B.MARK_H_WEIGHT * dx) ** 2 + dy * dy
                wi = min(placed, key=lambda t: dist(t[0]))[1]
            grow(wi, si, c)
    return exact, level, groups, boxes

# ------------------------------------------------------------------ build


def build(pages, jobs):
    order, tokens = verse_list()
    pts = points()
    fwi = first_word_index()
    font_widths = json.loads(FONT_WIDTHS.read_text(encoding='utf-8'))
    with Pool(jobs) as pool:
        info = {r['page']: r for r in pool.imap(analyse, pages, chunksize=4)}
    review = []

    def note(kind, detail, page=None, verse=(None, None)):
        review.append((page, verse[0], verse[1], kind, detail))

    # ---- markers to verses
    marker_of = {}          # verse -> (page, line, box)
    page_markers = {}       # page -> [(line, box, verse)] reading order
    for p in pages:
        r = info[p]
        cuts = r['cuts']

        def line_at(y):
            return sum(1 for c in cuts if y >= c)
        exp = pts.get(p, [])
        if len(r['markers']) < len(exp):
            # a ring whose outline is broken has no counter: take a ring-sized
            # component right at a point that no marker explains
            for s, a, x, y in exp:
                if any(abs(m[0] - POINT_OFFSET[0] - x) <= 15 and abs(m[1] - POINT_OFFSET[1] - y) <= 15
                       for m in r['markers']):
                    continue
                near = [c for c in r['rings'] if abs(c[1] - POINT_OFFSET[0] - x) <= 15
                        and abs(c[2] - POINT_OFFSET[1] - y) <= 15]
                if len(near) == 1:
                    box = tuple(near[0][1:5])
                    r['markers'].append(box)
                    note('marker', f'{s}:{a} ring is open; found by its size at its point', p, (s, a))
                    r['comps'] = [c[:6] + (True,) + c[7:] if c[1] >= box[0] - 1 and c[3] <= box[2] + 1
                                  and c[2] >= box[1] - 1 and c[4] <= box[3] + 1 else c for c in r['comps']]
                    for c in r['comps']:
                        if c[6]:
                            r['cores'].pop(c[0], None)
        found = sorted(((line_at((m[1] + m[3]) / 2), m) for m in r['markers']),
                       key=lambda t: (t[0], -t[1][0]))
        ok = len(found) == len(exp)
        pairs = []
        if ok:
            for (line, m), (s, a, x, y) in zip(found, exp):
                d = math.hypot(m[0] - POINT_OFFSET[0] - x, m[1] - POINT_OFFSET[1] - y)
                # page 2: the ring of 1:1 is printed above the basmala, its point beside it
                tol = 50 if p in ORNATE else POINT_TOLERANCE
                if d > tol:
                    ok = False
                    note('marker', f'{s}:{a} marker at {m[:2]} is {d:.0f} px from its point ({x}, {y})', p, (s, a))
                pairs.append((line, m, (s, a)))
        else:
            note('marker', f'{len(found)} markers found, {len(exp)} verses end here', p)
            # keep the ones that pair unambiguously with a point
            for line, m in found:
                near = [(math.hypot(m[0] - POINT_OFFSET[0] - x, m[1] - POINT_OFFSET[1] - y), (s, a))
                        for s, a, x, y in exp]
                near.sort()
                if near and near[0][0] <= POINT_TOLERANCE and (len(near) == 1 or near[1][0] > 2 * POINT_TOLERANCE):
                    pairs.append((line, m, near[0][1]))
        for line, m, v in pairs:
            if v in marker_of:
                note('marker', f'{v[0]}:{v[1]} paired twice', p, v)
                continue
            marker_of[v] = (p, line, m)
        page_markers[p] = pairs

    # ---- walk the verses through the lines
    idx = {v: i for i, v in enumerate(order)}
    segs_of = {v: [] for v in order}     # verse -> [(page, line, x0, x1, comps, cores)]
    start_page = {}
    header_rows, line_rows = [], []
    # index of the verse being read: the one after the last that ends before
    cur = sum(len(v) for p, v in pts.items() if p < pages[0])
    bad = set()                          # verses whose place on the page is uncertain
    pending_basmala = None
    for p in pages:
        r = info[p]
        marks = {}
        for line, m, v in page_markers[p]:
            marks.setdefault(line, []).append((m, v))
        frames = {j: f for f, j in r['frames']}
        j = 0
        kinds = [ln['kind'] for ln in r['lines']]
        surah_of_line = [None] * len(kinds)
        if p == 3:
            # the ornate title of al-Baqarah sits in the frame; its basmala is line 0
            header_rows.append((2, p, None, 60, 120, 826, 310))
            kinds[0] = 'basmala'
            surah_of_line[0] = 2
        if p == 2:
            header_rows.append((1, p, None, 60, 120, 826, 310))
        if pending_basmala and kinds[0] == 'text' and not marks.get(0):
            # the header closed the previous page; its basmala opens this one
            kinds[0] = 'basmala'
            surah_of_line[0] = pending_basmala
        elif pending_basmala:
            note('header', f'no basmala line after the header of surah {pending_basmala}', p)
        pending_basmala = None
        while j < len(kinds):
            if kinds[j] == 'header':
                s = order[cur][0] if cur < len(order) else None
                if cur < len(order) and order[cur][1] == 1:
                    f = frames.get(j)
                    header_rows.append((s, p, j, *f))
                    surah_of_line[j] = surah_of_line[j + 1] = s
                    if s != 9 and j + 2 < len(kinds) and kinds[j + 2] == 'text' and not marks.get(j + 2):
                        kinds[j + 2] = 'basmala'
                        surah_of_line[j + 2] = s
                    elif s != 9 and j + 2 == len(kinds):
                        pending_basmala = s
                    elif s != 9:
                        note('header', f'no basmala line after the header of surah {s}', p)
                else:
                    note('header', f'header frame on lines {j}-{j + 1} but verse {order[cur] if cur < len(order) else None} is not a first verse', p)
                j += 2
                continue
            if kinds[j] in ('basmala', 'empty'):
                j += 1
                continue
            # a text line: split at its markers, right to left
            ext = r['lines'][j]['ext']
            right, left = ext[1], ext[0]
            for m, v in sorted(marks.get(j, []), key=lambda t: -t[0][0]):
                if cur >= len(order):
                    break
                if v != order[cur]:
                    note('order', f'line {j}: marker of {v[0]}:{v[1]} where {order[cur][0]}:{order[cur][1]} should end', p, v)
                    bad.update(order[min(cur, idx[v]):max(cur, idx[v]) + 1])
                    cur = idx[v]
                segs_of[order[cur]].append((p, j, m[0], right))
                start_page.setdefault(order[cur], p)
                cur += 1
                right = m[0]
            # the rest of the line, when it holds letters (not just a mark
            # left of the last marker), starts the next verse
            rest = [c for c in r['comps'] if c[5] == j and c[0] in r['cores']
                    and left <= (c[1] + c[3]) / 2 < right]
            if rest and cur < len(order):
                segs_of[order[cur]].append((p, j, left, right))
                start_page.setdefault(order[cur], p)
            j += 1
        line_rows.append((p, kinds, surah_of_line))

    # ---- verse boxes and words
    word_rows, box_rows, ayah_rows = [], [], []
    for v in order:
        segs = segs_of[v]
        if v not in marker_of:
            note('marker', 'no marker found', start_page.get(v), v)
        end_page = marker_of[v][0] if v in marker_of else (segs[-1][0] if segs else 0)
        for part, (p, j, x0, x1) in enumerate(segs):
            ln = info[p]['lines'][j]
            box_rows.append((*v, part, p, j, x0, ln['y0'], x1, ln['y1']))
        toks = tokens[v]
        n_words = sum(1 for t in toks if t != B.HIZB)
        ok = 0
        if segs and v in marker_of and v not in bad:
            segments = []
            for p, j, x0, x1 in segs:
                comps = [c for c in info[p]['comps'] if c[5] == j and not c[6]
                         and x0 <= (c[1] + c[3]) / 2 < x1]
                segments.append((p, j, comps, info[p]['cores']))
            res = split_words(segments, toks, font_widths)
            if res is None:
                note('words', 'no alignment', segs[0][0], v)
            else:
                exact, level, groups, boxes = res
                pages_of = [segments[g[0]][0] for g in groups]
                fw_ok = True
                if len({s[0] for s in segs}) > 1:
                    later = segs[-1][0]
                    before = sum(1 for t, pg in zip(toks, pages_of) if pg < later and t != B.HIZB)
                    if later in fwi and fwi[later] != before:
                        fw_ok = False
                        note('words', f'{before} words before page {later}, first-word index says {fwi[later]}', later, v)
                if not exact:
                    note('words', 'pieces do not match the words', segs[0][0], v)
                elif None in boxes:
                    note('words', 'a word got no ink', segs[0][0], v)
                elif level == 0:
                    note('words', 'the split changes without the font widths', segs[0][0], v)
                elif fw_ok:
                    ok = level
                    if level == 1:
                        note('words', 'level 1: a looser piece count splits it otherwise', segs[0][0], v)
                # Every verse with a split and ink for every word gets its
                # boxes; ayah.words_matched (0, 1, 2) says how sure the split
                # is, and readers of word_box choose the level they need.
                if fw_ok and None not in boxes:
                    wn = 0
                    for t, b in zip(toks, boxes):
                        if t == B.HIZB:
                            continue
                        wn += 1
                        word_rows.append((*v, wn, *b))
        ayah_rows.append((*v, start_page.get(v, 0), end_page, n_words, int(ok)))
    return info, marker_of, header_rows, line_rows, ayah_rows, box_rows, word_rows, review


def write(pages, info, marker_of, header_rows, line_rows, ayah_rows, box_rows, word_rows, review):
    OUT.unlink(missing_ok=True)
    db = sqlite3.connect(OUT)
    db.executescript(SCHEMA)
    meta = {
        'source_images': 'https://archive.org/details/shamerly (522 PNG, 886x1377; no licence, used with the owner\'s consent)',
        'source_points': 'shamerly.db of the open-source Shamarly Android app (verse points, approximate)',
        'source_first_words': 'quran_android issue #1180, shemerly_page_first_word_index.txt',
        'sha256_shamerly_db': sha256(POINTS_DB),
        'sha256_first_word_index': sha256(FIRST_WORDS),
        'units': 'image pixels of the 886x1377 page images',
        'built': datetime.date.today().isoformat(),
        'tool': 'tools/build_shamarly.py',
    }
    zipf = SRC / 'shamarly-pages-archive-org.zip'
    if zipf.exists():
        meta['sha256_pages_zip'] = sha256(zipf)
    db.executemany('INSERT INTO meta VALUES (?,?)', meta.items())
    db.execute("INSERT INTO page VALUES (1, 'cover', 0, NULL, NULL)")
    lines_by_page = {p: (k, s) for p, k, s in line_rows}
    for p in pages:
        r = info[p]
        db.execute('INSERT INTO page VALUES (?,?,?,?,?)', (p, r['kind'], len(r['lines']), round(r['top'], 2), round(r['pitch'], 3)))
        kinds, surahs = lines_by_page[p]
        for j, ln in enumerate(r['lines']):
            ext = ln['ext'] or (None, None)
            db.execute('INSERT INTO line VALUES (?,?,?,?,?,?,?,?,?)',
                       (p, j, kinds[j], surahs[j], ln['baseline'], ln['y0'], ln['y1'], *ext))
        db.executemany('INSERT INTO line_cut VALUES (?,?,?,?)',
                       [(p, j, y, c) for j, (y, c) in enumerate(zip(r['cuts'], r['crossing']))])
        db.executemany('INSERT INTO line_overflow VALUES (?,?,?,?,?,?)', [(p, *o) for o in r['overflow']])
    db.executemany('INSERT INTO header VALUES (?,?,?,?,?,?,?)', header_rows)
    db.executemany('INSERT INTO marker VALUES (?,?,?,?,?,?,?,?)',
                   [(*v, p, line, *m) for v, (p, line, m) in marker_of.items()])
    db.executemany('INSERT INTO ayah VALUES (?,?,?,?,?,?)', ayah_rows)
    db.executemany('INSERT INTO verse_box VALUES (?,?,?,?,?,?,?,?,?)', box_rows)
    db.executemany('INSERT INTO word_box VALUES (?,?,?,?,?,?,?,?,?)', word_rows)
    db.executemany('INSERT INTO review VALUES (?,?,?,?,?)', review)
    db.commit()
    db.execute('VACUUM')
    db.close()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--pages', default=f'2-{LAST_PAGE}')
    ap.add_argument('--jobs', type=int, default=8)
    args = ap.parse_args()
    a, b = (int(v) for v in args.pages.split('-'))
    pages = list(range(a, b + 1))
    res = build(pages, args.jobs)
    write(pages, *res)
    info, marker_of, header_rows, line_rows, ayah_rows, box_rows, word_rows, review = res
    print(f'pages {a}-{b}: {sum(len(info[p]["markers"]) for p in pages)} markers, '
          f'{len(marker_of)} paired, {len(header_rows)} headers, '
          f'{sum(r[5] == 2 for r in ayah_rows)} + {sum(r[5] == 1 for r in ayah_rows)} verses with word boxes (level 2 + 1), {len(review)} review notes -> {OUT}')


if __name__ == '__main__':
    main()
