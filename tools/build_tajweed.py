"""Tajweed colouring data for the page editions, from cpfair/quran-tajweed.

The tajweed rules are not ours: every span comes from the cpfair data
(CC BY 4.0, machine-generated, see docs/DATA_SOURCES.md). This script only
places those spans on the printed pages. It never writes or changes text.

1. Spans. cpfair gives each rule as character offsets in the Tanzil
   Uthmani text of 2017. Each offset is moved onto the KFGQPC text (the
   words of the page editions) by aligning the two texts' letters; a span
   becomes a list of (word, letter, part): `body` when the span covers the
   letter itself, `marks` when it covers only its marks (for example the
   maddah or a tanween). Spans inside the basmala that Tanzil puts before
   verse 1 are left out: the pages print it as a header line.

2. Where a letter lies inside its word. A word is drawn as pieces (runs of
   joined letters); the KFGQPC text predicts them (build_word_boxes.py).
   Inside a piece of several letters, each letter's share of the piece's
   width comes from the KFGQPC font (word_letter_widths.json, measured by
   measure_letter_widths.py). This is an estimate: the printed calligraphy
   is not the font.

3. Per edition:
   - New Madina (1441H, SVG): every contour of the page path is known.
     A letter alone in its piece is coloured as its own contours, exactly.
     A letter inside a piece is coloured as that piece's contours clipped
     to the letter's estimated width. Marks and dots are separate
     contours, coloured whole when they sit over the letter.
   - Old Madina (1405H) and Shamarly (page images): the ink inside each
     word box is split into connected components; components across the
     baseline are the word's pieces, the rest are marks. The same letter
     shares are applied, and the result is stored as rectangles (image px)
     around the coloured ink.

Output (content.db):
  tajweed_letter: every coloured letter on the KFGQPC text of a riwaya,
              (riwaya, surah, ayah, word, letter, part, rule, source), source
              being the row of the source table. One
              table for every source: a new source (quran-ws, Quran.com,
              the V4 fonts) adds rows with its own `source` and the same
              placement below runs on them. Today: cpfair, Hafs.
  tajweed_page (one row per edition and page), placed from tajweed_letter:
  madina1441: "rule,contour[,x0,x1];..."  contour = index of the contour in
              the page's text paths (document order, one per moveto); x0,x1
              (page units) clip it to a letter
  madina1405, shamarly: "rule,x0,y0,x1,y1;..." image px
Rules are numbered as in RULES.

Inputs: tools/.cache/cpfair_tajweed.hafs.uthmani-pause-sajdah.json,
        tools/.cache/quran-uthmani-2017-cpfair.txt, plus the inputs of
        build_word_boxes.py; for the image editions images_1024.zip,
        ayahinfo_1024.db and the Shamarly pages and geometry.
Usage:  called by build_content_db.py; or `python3 tools/build_tajweed.py`
        to print statistics.
"""
import difflib
import json
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CACHE = ROOT / '.cache'
TAJWEED = CACHE / 'cpfair_tajweed.hafs.uthmani-pause-sajdah.json'
TANZIL_2017 = CACHE / 'quran-uthmani-2017-cpfair.txt'
LETTER_WIDTHS = ROOT / 'word_letter_widths.json'

# Rule keys as in the cpfair data. The index is what the app stores.
RULES = [
    'hamzat_wasl', 'lam_shamsiyyah', 'silent',
    'madd_2', 'madd_246', 'madd_muttasil', 'madd_munfasil', 'madd_6',
    'ghunnah', 'ikhfa', 'ikhfa_shafawi', 'iqlab',
    'idghaam_ghunnah', 'idghaam_no_ghunnah', 'idghaam_shafawi',
    'idghaam_mutajanisayn', 'idghaam_mutaqaribayn',
    'qalqalah',
]

HIZB = '۞'

# --------------------------------------------------------------- letters


def is_base(ch):
    """A letter (with tatweel, small waw and small yeh); marks are not."""
    return unicodedata.category(ch).startswith('L')


def letters(word):
    """[(start, end)] character spans of a word's letters: each base
    character with the marks that follow it."""
    out = []
    for i, ch in enumerate(word):
        if is_base(ch) or not out:
            out.append([i, i + 1])
        else:
            out[-1][1] = i + 1
    return [tuple(s) for s in out]


RIGHT_JOINING = set('آأؤإاةدذرزوٱ')
NON_JOINING = {'ء'}
OWN_PIECE = set('ۥۦ')   # small waw and small yeh are drawn on the line on their own


def runs(word):
    """Letter indices of each piece (run of joined letters) of a word, in
    reading order; the same prediction as build_word_boxes.predicted_pieces."""
    bases = [word[s] for s, _ in letters(word)]
    out = []
    for i, ch in enumerate(bases):
        prev = bases[i - 1] if i else None
        if (not out or ch in OWN_PIECE or prev in OWN_PIECE or prev in RIGHT_JOINING
                or prev in NON_JOINING or ch in NON_JOINING):
            out.append([i])
        else:
            out[-1].append(i)
    return out

# ----------------------------------------------------------------- spans


# Letters written differently in the two texts but the same letter.
SAME = str.maketrans({'ى': 'ي', 'ئ': 'ي', 'ؤ': 'و', 'ۦ': 'ـ'})


def read_tanzil(path):
    verses = {}
    for line in path.read_text(encoding='utf-8').split('\n'):
        parts = line.split('|')
        if len(parts) == 3 and parts[0].isdigit():
            verses[(int(parts[0]), int(parts[1]))] = parts[2]
    return verses


def basmala_prefix(verses, key):
    """Length of the basmala Tanzil puts before verse 1 (0 when none)."""
    surah, ayah = key
    if ayah != 1 or surah in (1, 9):
        return 0
    first = verses[(1, 1)]
    text = verses[key]
    strip = lambda s: ''.join(c for c in s if is_base(c) or c == ' ')
    if strip(text).startswith(strip(first) + ' '):
        return len(' '.join(text.split(' ')[:4])) + 1
    return 0


def letter_map(tanzil, words):
    """Maps each Tanzil character index to (word index, letter index) in the
    KFGQPC words, by aligning the two texts' letters. Marks follow their
    letter. Characters with no counterpart are left out."""
    t_letters = [i for i, ch in enumerate(tanzil) if is_base(ch)]
    k_letters = [(wi, li) for wi, w in enumerate(words) if w != HIZB
                 for li, _ in enumerate(letters(w))]
    k_chars = ''.join(words[wi][letters(words[wi])[li][0]] for wi, li in k_letters)
    t_chars = ''.join(tanzil[i] for i in t_letters)
    sm = difflib.SequenceMatcher(None, t_chars.translate(SAME), k_chars.translate(SAME), autojunk=False)
    to_k = {}
    for op, i1, i2, j1, j2 in sm.get_opcodes():
        if op == 'equal' or (op == 'replace' and j2 > j1):
            for i in range(i1, i2):
                to_k[i] = k_letters[j1 + (i - i1) * (j2 - j1) // (i2 - i1)]
    out, current, li = {}, None, -1
    for i, ch in enumerate(tanzil):
        if ch == ' ':
            current = None
        elif is_base(ch):
            li += 1
            current = to_k.get(li)
        out[i] = (current, is_base(ch)) if current is not None else None
    return out


def verse_spans(annotations, tanzil, words, prefix=0):
    """[(rule, word index, letter index, part)] for one verse. part is
    'body' or 'marks'."""
    where = letter_map(tanzil, words)
    out = []
    for a in annotations:
        rule = a['rule']
        if rule not in RULES:
            continue
        parts = {}
        for i in range(max(a['start'], prefix), a['end']):
            hit = where.get(i)
            if hit is None:
                continue
            (wi, li), base = hit
            parts[(wi, li)] = 'body' if base or parts.get((wi, li)) == 'body' else 'marks'
        out += [(rule, wi, li, part) for (wi, li), part in sorted(parts.items())]
    return out


def all_spans(kfgqpc):
    """{(surah, ayah): [(rule, word index, letter index, part)]} on the
    KFGQPC tokens (۞ included in the indices) and statistics."""
    tanzil = read_tanzil(TANZIL_2017)
    data = json.loads(TAJWEED.read_text(encoding='utf-8'))
    out, total, placed = {}, 0, 0
    for entry in data:
        key = (entry['surah'], entry['ayah'])
        prefix = basmala_prefix(tanzil, key)
        spans = verse_spans(entry['annotations'], tanzil[key], kfgqpc[key], prefix)
        total += sum(1 for a in entry['annotations'] if a['start'] >= prefix)
        placed += len({(r, wi) for r, wi, _, _ in spans})
        out[key] = spans
    return out, total

# ------------------------------------------------- the letter table




def cpfair_letters(kfgqpc):
    """Rows of tajweed_letter from cpfair (Hafs): (riwaya, surah, ayah,
    word, letter, part, rule, source). word counts the words of the KFGQPC
    verse from 1 (۞ not counted), as word_box does; letter counts the
    word's letters from 0 (letters()); part is 'body' or 'marks'."""
    spans, _ = all_spans(kfgqpc)
    rows = set()
    for (surah, ayah), sp in spans.items():
        number = {t: n + 1 for n, t in enumerate(word_index(kfgqpc[(surah, ayah)]))}
        for rule, wi, li, part in sp:
            rows.add(('hafs', surah, ayah, number[wi], li, part, rule, SOURCE_ID))
    return sorted(rows)


def spans_from_letters(rows, kfgqpc):
    """{(surah, ayah): [(rule, token index, letter, part)]}, the form the
    placement below works on, from tajweed_letter rows of one riwaya (token
    indices count ۞, as build_word_boxes does)."""
    out = {}
    for _, surah, ayah, word, letter, part, rule, _ in rows:
        tokens = word_index(kfgqpc[(surah, ayah)])
        out.setdefault((surah, ayah), []).append((rule, tokens[word - 1], letter, part))
    return out


def read_letters(db, riwaya='hafs', source=None):
    """tajweed_letter rows of [riwaya] (and of one [source] when given)."""
    q = ('SELECT riwaya, surah, ayah, word, letter, part, rule, source FROM tajweed_letter '
         'WHERE riwaya = ?')
    args = [riwaya]
    if source:
        q += ' AND source = ?'
        args.append(source)
    return db.execute(q + ' ORDER BY surah, ayah, word, letter', args).fetchall()

# ------------------------------------------------------- letters in a word


_letter_widths = None


def letter_widths(word):
    """Where each letter of [word] ends in the KFGQPC font (100 px),
    cumulative from the word's start (its right edge), never decreasing."""
    global _letter_widths
    if _letter_widths is None:
        _letter_widths = json.loads(LETTER_WIDTHS.read_text(encoding='utf-8'))
    out, top = [], 0.0
    for w in _letter_widths[word]:
        top = max(top, w)
        out.append(top)
    return out


def letter_ranges(word, pieces):
    """Estimated x-range (x0, x1) of each letter of [word], given the x-ranges
    of its printed pieces from right to left. Returns (ranges, piece of
    each letter, exact): when the pieces are not the predicted ones, the
    whole word is shared out and no letter has a piece of its own."""
    cum = [0.0] + letter_widths(word)
    rs = runs(word)
    exact = len(rs) == len(pieces)
    if exact:
        groups = list(zip(rs, pieces, range(len(rs))))
    else:
        every = [i for r in rs for i in r]
        whole = (min(p[0] for p in pieces), max(p[1] for p in pieces))
        groups = [(every, whole, None)]
    ranges, owner = {}, {}
    for run, (x0, x1), k in groups:
        f0, f1 = cum[run[0]], cum[run[-1] + 1]
        span = f1 - f0
        for i in run:
            a = (cum[i] - f0) / span if span > 0 else 0
            b = (cum[i + 1] - f0) / span if span > 0 else 1
            ranges[i] = (x1 - b * (x1 - x0), x1 - a * (x1 - x0))
            owner[i] = k
    return ranges, owner, exact


def nearest_letter(ranges, x):
    """The letter whose range holds x, or the closest one."""
    return min(ranges, key=lambda i: max(ranges[i][0] - x, x - ranges[i][1], 0))

# ------------------------------------------------------ new Madina (SVG)


def new_edition(spans, pages=range(1, 605)):
    """{page: [(rule index, contour index, x0, x1)]}; x0 and x1 are None
    when the whole contour is coloured. Also returns statistics."""
    import zipfile
    import build_word_boxes as bw
    by_page = {}
    index = {}
    with zipfile.ZipFile(bw.SVG_ZIP) as z:
        for page in pages:
            items, _ = bw.read_page(z.read(f'svg/{page:03d}.svg').decode())
            index[page] = {}
            for i, (bbox, _) in enumerate(items):
                index[page].setdefault(bbox, i)
    stats = {'letters': 0, 'exact': 0, 'clipped': 0, 'missing': 0}
    for verse, tokens, segs, groups, _, owner in bw.layouts(pages):
        verse_spans = spans.get(verse, [])
        if not verse_spans:
            continue
        # Each word's pieces and marks.
        words = {}
        for wi, (si, a, b) in enumerate(groups):
            pieces = segs[si][2][a:b + 1]
            words[wi] = (segs[si][0], pieces, [])
        for page, _, pieces, cs in segs:
            cores = {id(bb) for p in pieces for bb in p[2]}
            for bbox, _ in cs:
                if id(bbox) not in cores:
                    words[owner[id(bbox)]][2].append(bbox)
        cache = {}
        for rule, wi, li, part in verse_spans:
            stats['letters'] += 1
            if wi not in words:
                stats['missing'] += 1
                continue
            page, pieces, marks = words[wi]
            if wi not in cache:
                ranges, piece_of, exact = letter_ranges(tokens[wi], [(p[0], p[1]) for p in pieces])
                mark_of = {}
                for bb in marks:
                    mark_of.setdefault(nearest_letter(ranges, (bb[0] + bb[2]) / 2), []).append(bb)
                cache[wi] = (ranges, piece_of, exact, mark_of)
            ranges, piece_of, exact, mark_of = cache[wi]
            r = RULES.index(rule)
            out = by_page.setdefault(page, [])
            alone = exact and len(runs(tokens[wi])[piece_of[li]]) == 1
            stats['exact' if alone else 'clipped'] += part == 'body'
            if part == 'body':
                chosen = [pieces[piece_of[li]]] if exact else pieces
                x0, x1 = ranges[li]
                for p in chosen:
                    for bb in p[2]:
                        c = index[page][bb]
                        out.append((r, c, None, None) if alone else (r, c, round(x0, 2), round(x1, 2)))
            for bb in mark_of.get(li, []):
                out.append((r, index[page][bb], None, None))
    return {p: sorted(set(v), key=lambda e: (e[1], e[0])) for p, v in by_page.items()}, stats


def encode_new(entries):
    return ';'.join(f'{r},{c}' if x0 is None else f'{r},{c},{x0:g},{x1:g}' for r, c, x0, x1 in entries)

# ---------------------------------------------------------- page images

MERGE_FRAC = 0.3   # as build_word_boxes: merge pieces whose cores overlap this much


def ink_mask(image, opaque):
    """Boolean ink mask of a page image: its alpha, or for opaque scans its
    darkness."""
    import numpy as np
    a = np.asarray(image.convert('RGBA'))
    if opaque:
        lum = 0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]
        return lum < 110
    return a[..., 3] > 127


def components(mask, x0, y0):
    """Connected ink components (8-connected) of a boolean crop whose
    top-left corner is (x0, y0) on the page. Returns [(bbox, rows)] where
    rows maps each row (page y) to its (min x, max x) in that component."""
    import numpy as np
    parent = []

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    runs_all, prev = [], []
    for y in range(mask.shape[0]):
        row = mask[y]
        if not row.any():
            prev = []
            continue
        d = np.diff(np.concatenate(([0], row.view(np.int8), [0])))
        starts, ends = np.flatnonzero(d == 1), np.flatnonzero(d == -1) - 1
        cur = []
        for s, e in zip(starts.tolist(), ends.tolist()):
            k = len(parent)
            parent.append(k)
            for ps, pe, pk in prev:
                if ps <= e + 1 and pe >= s - 1:
                    a, b = find(k), find(pk)
                    if a != b:
                        parent[a] = b
            cur.append((s, e, k))
            runs_all.append((y, s, e, k))
        prev = cur
    comps = {}
    for y, s, e, k in runs_all:
        r = find(k)
        c = comps.setdefault(r, {})
        lo, hi = c.get(y + y0, (s + x0, e + x0))
        c[y + y0] = (min(lo, s + x0), max(hi, e + x0))
    out = []
    for rows in comps.values():
        ys = list(rows)
        out.append(((min(v[0] for v in rows.values()), min(ys),
                     max(v[1] for v in rows.values()) + 1, max(ys) + 1), rows))
    return out


def baseline(mask, box):
    """The row with the most ink inside [box] (x0, y0, x1, y1)."""
    x0, y0, x1, y1 = box
    return y0 + int(mask[y0:y1, x0:x1].sum(axis=1).argmax())


def image_word(mask, word, rects, base, pitch):
    """Coloured rectangles for one word on a page image: {(letter, part):
    [rect]} where part is body or marks."""
    xs0 = max(0, min(r[0] for r in rects))
    ys0 = max(0, min(r[1] for r in rects))
    xs1 = min(mask.shape[1], max(r[2] for r in rects))
    ys1 = min(mask.shape[0], max(r[3] for r in rects))
    if xs1 <= xs0 or ys1 <= ys0:
        return None
    crop = mask[ys0:ys1, xs0:xs1].copy()
    # Only the word's own boxes (a word may have several glyph boxes).
    inside = crop.copy()
    inside[:] = False
    for r in rects:
        inside[max(r[1] - ys0, 0):r[3] - ys0, max(r[0] - xs0, 0):r[2] - xs0] = True
    crop &= inside
    comps = components(crop, xs0, ys0)
    cores, marks = [], []
    for bbox, rows in comps:
        hit = [rows[y] for y in (base - 1, base, base + 1) if y in rows]
        if hit and bbox[3] - bbox[1] >= 0.07 * pitch:
            cores.append((min(h[0] for h in hit), max(h[1] for h in hit) + 1, bbox))
        else:
            marks.append(bbox)
    if not cores:
        return None
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
    ranges, piece_of, exact = letter_ranges(word, [(p[0], p[1]) for p in pieces])
    mark_of = {}
    for bb in marks:
        mark_of.setdefault(nearest_letter(ranges, (bb[0] + bb[2]) / 2), []).append(bb)
    out = {}
    for li, (lx0, lx1) in ranges.items():
        alone = exact and len(runs(word)[piece_of[li]]) == 1
        chosen = [pieces[piece_of[li]]] if exact else pieces
        body = []
        for p in chosen:
            for bb in p[2]:
                if alone:
                    body.append(bb)
                else:
                    a, b = max(bb[0], int(lx0)), min(bb[2], int(round(lx1)) + 1)
                    if b > a:
                        body.append((a, bb[1], b, bb[3]))
        out[(li, 'marks')] = mark_of.get(li, [])
        out[(li, 'body')] = body + out[(li, 'marks')]
    return out, exact


def image_edition(spans, kfgqpc, words_on_pages, load_page):
    """{page: [(rule, x0, y0, x1, y1)]} for an edition drawn from page
    images. words_on_pages yields (page, [(verse, word index, line,
    [rects])]); load_page(page) returns (mask, pitch)."""
    by_verse = {}
    for key, spans_ in spans.items():
        for rule, wi, li, part in spans_:
            by_verse.setdefault(key, {}).setdefault(wi, []).append((rule, li, part))
    out, stats = {}, {'letters': 0, 'placed': 0, 'words_exact': 0, 'words': 0}
    for page, words in words_on_pages:
        wanted = [w for w in words if by_verse.get(w[0], {}).get(w[1])]
        if not wanted:
            continue
        mask, pitch = load_page(page)
        lines = {}
        for _, _, line, rects in words:
            lines.setdefault(line, []).extend(rects)
        bases = {line: baseline(mask, (min(r[0] for r in rs), min(r[1] for r in rs),
                                       max(r[2] for r in rs), max(r[3] for r in rs)))
                 for line, rs in lines.items()}
        rows = out.setdefault(page, set())
        for verse, wi, line, rects in wanted:
            todo = by_verse[verse][wi]
            stats['letters'] += len(todo)
            got = image_word(mask, kfgqpc[verse][wi], rects, bases[line], pitch)
            if got is None:
                continue
            geo, exact = got
            stats['words'] += 1
            stats['words_exact'] += exact
            for rule, li, part in todo:
                boxes = geo.get((li, part), [])
                stats['placed'] += bool(boxes)
                for b in boxes:
                    rows.add((RULES.index(rule), *(int(v) for v in b)))
    return {p: sorted(v) for p, v in out.items() if v}, stats


def encode_image(entries):
    return ';'.join(','.join(str(v) for v in e) for e in entries)


def word_index(tokens):
    """KFGQPC token index of each word number (۞ not counted), from 1."""
    return [i for i, t in enumerate(tokens) if t != HIZB]


def old_edition_words(kfgqpc, pages=range(1, 605)):
    """Word boxes of the old Madina edition, matched to the words exactly as
    the app does (mushaf_providers.dart: pageWordBoxesProvider)."""
    import sqlite3
    db = sqlite3.connect(f'file:{CACHE / "ayahinfo_1024.db"}?mode=ro', uri=True)
    for page in pages:
        by_verse = {}
        for s, a, pos, line, x0, x1, y0, y1 in db.execute(
                'SELECT sura_number, ayah_number, position, line_number, min_x, max_x, min_y, max_y '
                'FROM glyphs WHERE page_number = ? ORDER BY glyph_id', (page,)):
            by_verse.setdefault((s, a), {}).setdefault(pos, []).append((line, (x0, y0, x1, y1)))
        words = []
        for verse, positions in by_verse.items():
            if verse not in kfgqpc:
                continue
            index = word_index(kfgqpc[verse])
            keys = sorted(positions)[:-1]  # the verse-end marker
            kept = [p for p in keys if sum(r[2] - r[0] for _, r in positions[p]) >= 20]
            if len(kept) != len(index):
                continue
            for n, p in enumerate(kept):
                words.append((verse, index[n], positions[p][0][0], [r for _, r in positions[p]]))
        yield page, words


def shamarly_words(kfgqpc):
    import sqlite3
    db = sqlite3.connect(f'file:{CACHE / "shamarly_geometry.db"}?mode=ro', uri=True)
    rows = db.execute('SELECT w.page, w.surah, w.ayah, w.word, w.line, w.x0, w.y0, w.x1, w.y1 '
                      'FROM word_box w JOIN ayah a ON a.surah = w.surah AND a.ayah = w.ayah '
                      'WHERE a.words_matched >= 1 ORDER BY w.page').fetchall()
    by_page = {}
    for page, s, a, n, line, x0, y0, x1, y1 in rows:
        index = word_index(kfgqpc[(s, a)])
        if n <= len(index):
            by_page.setdefault(page, []).append(((s, a), index[n - 1], line, [(x0, y0, x1, y1)]))
    return sorted(by_page.items())


def old_edition(spans, kfgqpc, pages=range(1, 605)):
    import io
    import zipfile
    from PIL import Image
    z = zipfile.ZipFile(CACHE / 'images_1024.zip')

    def load(page):
        image = Image.open(io.BytesIO(z.read(f'width_1024/page{page:03d}.png')))
        return ink_mask(image, False), 1594 / 15

    return image_edition(spans, kfgqpc, old_edition_words(kfgqpc, pages), load)


def shamarly_edition(spans, kfgqpc, pages=None):
    import sqlite3
    from PIL import Image
    db = sqlite3.connect(f'file:{CACHE / "shamarly_geometry.db"}?mode=ro', uri=True)
    meta = {p: (kind, pitch) for p, kind, pitch in db.execute('SELECT page, kind, pitch FROM page')}

    def load(page):
        kind, pitch = meta[page]
        image = Image.open(CACHE / 'shamarly' / 'pages' / f'{page:03d}.png')
        return ink_mask(image, kind != 'text'), pitch or 80

    words = [(p, w) for p, w in shamarly_words(kfgqpc) if pages is None or p in pages]
    return image_edition(spans, kfgqpc, words, load)


SOURCE_ID = 18
SCHEMA = '''
CREATE TABLE tajweed_letter (           -- each letter a tajweed rule applies to (tools/build_tajweed.py)
  riwaya TEXT NOT NULL,                 -- hafs (the only riwaya with data today)
  surah INTEGER NOT NULL, ayah INTEGER NOT NULL,   -- the riwaya's own verse numbers
  word INTEGER NOT NULL,                -- word of the KFGQPC text of the riwaya, from 1 (۞ not counted)
  letter INTEGER NOT NULL,              -- letter of the word, from 0 (a base character and its marks)
  part TEXT NOT NULL,                   -- body: the letter itself; marks: only its marks
  rule TEXT NOT NULL,                   -- the source's rule key (build_tajweed.RULES)
  source INTEGER NOT NULL,              -- where the rule comes from: source.id (18: cpfair/quran-tajweed 496f71c)
  PRIMARY KEY (riwaya, surah, ayah, word, letter, part, rule, source)) WITHOUT ROWID;
CREATE TABLE tajweed_page (             -- tajweed colouring per page (tools/build_tajweed.py)
  edition TEXT NOT NULL,                -- madina1441 | madina1405 | shamarly
  page INTEGER NOT NULL,
  data TEXT NOT NULL,                   -- madina1441: "rule,contour[,x0,x1];..."; others: "rule,x0,y0,x1,y1;..." (px)
  PRIMARY KEY (edition, page)) WITHOUT ROWID;
'''


def write(db, today):
    """Adds the tajweed_letter and tajweed_page tables and their source row
    to content.db: the letters first, then each edition placed from them."""
    import hashlib
    import build_word_boxes
    db.executescript(SCHEMA)
    db.execute('INSERT INTO source VALUES (?,?,?,?,?,?,?,?,?,?,?)', (
        SOURCE_ID, 'cpfair-quran-tajweed', 'Tajweed annotations (Hafs), placed on the pages by Tibyan',
        'Collin Fair (quran-tajweed); placement by Tibyan', '496f71c (2021-10-12)',
        'CC BY 4.0; machine-generated, not yet reviewed by a qualified reader',
        'https://github.com/cpfair/quran-tajweed',
        'أحكام التجويد: quran-tajweed © Collin Fair (CC BY 4.0)', None,
        hashlib.sha256(TAJWEED.read_bytes()).hexdigest(), today))
    kfgqpc = build_word_boxes.load_text()
    db.executemany('INSERT INTO tajweed_letter VALUES (?,?,?,?,?,?,?,?)', cpfair_letters(kfgqpc))
    # Every edition is placed from the letter table, whatever its source.
    spans = spans_from_letters(read_letters(db, 'hafs'), kfgqpc)
    print(f'tajweed: {sum(len(v) for v in spans.values())} coloured letters')
    new, stats = new_edition(spans)
    print(f'tajweed madina1441: {stats}')
    rows = [('madina1441', p, encode_new(v)) for p, v in sorted(new.items())]
    if (CACHE / 'images_1024.zip').exists() and (CACHE / 'ayahinfo_1024.db').exists():
        old, stats = old_edition(spans, kfgqpc)
        print(f'tajweed madina1405: {stats}')
        rows += [('madina1405', p, encode_image(v)) for p, v in sorted(old.items())]
    sh, stats = shamarly_edition(spans, kfgqpc)
    print(f'tajweed shamarly: {stats}')
    rows += [('shamarly', p, encode_image(v)) for p, v in sorted(sh.items())]
    db.executemany('INSERT INTO tajweed_page VALUES (?,?,?)', rows)


def write_into(path, schema_version):
    """Adds the tajweed data to an already built content.db (same result
    as a full build_content_db.py run, for this table)."""
    import sqlite3
    from datetime import date
    db = sqlite3.connect(path)
    db.execute('DROP TABLE IF EXISTS tajweed_page')
    db.execute('DROP TABLE IF EXISTS tajweed_letter')
    db.execute('DELETE FROM source WHERE id = ?', (SOURCE_ID,))
    write(db, date.today().isoformat())
    db.execute("UPDATE meta SET value = ? WHERE key = 'schema_version'", (str(schema_version),))
    db.execute(f'PRAGMA user_version = {schema_version}')
    db.commit()
    db.execute('VACUUM')
    db.close()


if __name__ == '__main__':
    sys.path.insert(0, str(ROOT))
    import build_word_boxes
    if sys.argv[1:2] == ['--into']:
        import build_content_db
        write_into(sys.argv[2], build_content_db.SCHEMA_VERSION)
        sys.exit(0)
    spans, total = all_spans(build_word_boxes.load_text())
    print(f'{total} annotations, {sum(len(v) for v in spans.values())} coloured letters')
    pages = range(int(sys.argv[1]), int(sys.argv[2]) + 1) if len(sys.argv) > 2 else range(1, 605)
    kfgqpc = build_word_boxes.load_text()
    new, stats = new_edition(spans, pages)
    print(f'new edition: {stats}, {sum(len(encode_new(v)) for v in new.values()) // 1024} KB')
    old, stats = old_edition(spans, kfgqpc, pages)
    print(f'old edition: {stats}, {sum(len(encode_image(v)) for v in old.values()) // 1024} KB')
    sh, stats = shamarly_edition(spans, kfgqpc, set(pages))
    print(f'shamarly: {stats}, {sum(len(encode_image(v)) for v in sh.values()) // 1024} KB')
