"""Checks the word boxes of the new edition and draws pages for review.

Cross-check: the old Madina edition (1405H) was written by the same
calligrapher, and quran.com's glyph boxes give each of its words' widths.
A wrong cut in the new edition makes one word too wide and its neighbour
too narrow compared with the old edition. Words whose width ratio is far
from their verse's median are flagged. Many flags are false alarms
(the calligrapher stretches words differently in the two editions), so
flags point a human reviewer to places worth a look; they are not errors.

The quran.com data is used here only for checking; nothing from it goes
into the app.

Usage:
  python3 tools/verify_word_boxes.py                  # print the summary
  python3 tools/verify_word_boxes.py --render DIR     # also draw every page
                                                      # with flagged words, as PNG
Inputs: assets/db/content.db (word_box table), tools/.cache/ayahinfo_1024.zip
"""
import collections
import sqlite3
import statistics
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent
DB = REPO / 'assets' / 'db' / 'content.db'
AYAHINFO = ROOT / '.cache' / 'ayahinfo_1024.zip'
SVG_ZIP = ROOT / '.cache' / 'hafs-kfqc-svg.zip'
CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
LOW, HIGH = 0.6, 1.6


def old_widths(word_counts):
    """{verse: {word_no: width}} from quran.com's 1405H glyph boxes. Pause
    marks are separate glyphs there: the narrowest extra positions go."""
    with tempfile.NamedTemporaryFile(suffix='.db') as tmp:
        with zipfile.ZipFile(AYAHINFO) as z:
            tmp.write(z.read('ayahinfo_1024.db'))
        tmp.flush()
        rows = sqlite3.connect(tmp.name).execute(
            'SELECT sura_number, ayah_number, position, max_x - min_x FROM glyphs').fetchall()
    pos = collections.defaultdict(lambda: collections.defaultdict(int))
    for s, a, p, w in rows:
        pos[(s, a)][p] += w
    out = {}
    for verse, n in word_counts.items():
        ps = sorted(pos[verse])[:-1]  # the last position is the verse number
        widths = [pos[verse][p] for p in ps]
        extra = len(ps) - n
        if extra < 0:
            continue
        drop = set(sorted(range(len(ps)), key=lambda i: widths[i])[:extra])
        out[verse] = [w for i, w in enumerate(widths) if i not in drop]
    return out


def main():
    db = sqlite3.connect(DB)
    boxes = collections.defaultdict(list)
    exact = {}
    for s, a, w, page, x0, x1, ex in db.execute(
            'SELECT surah, ayah, word, page, x0, x1, exact FROM word_box ORDER BY surah, ayah, word'):
        boxes[(s, a)].append((page, x1 - x0))
        exact[(s, a)] = ex
    old = old_widths({v: len(b) for v, b in boxes.items()})
    flagged = {}
    for verse, bs in boxes.items():
        if verse not in old:
            continue
        ratios = [w / o for (_, w), o in zip(bs, old[verse]) if o > 0]
        med = statistics.median(ratios)
        bad = [i + 1 for i, r in enumerate(ratios) if not LOW <= r / med <= HIGH]
        if bad:
            flagged[verse] = bad
    words = sum(len(b) for b in boxes.values())
    n_flag = sum(len(b) for b in flagged.values())
    pages = collections.Counter(boxes[v][w - 1][0] for v, ws in flagged.items() for w in ws)
    print(f'{len(boxes)} verses, {words} words')
    print(f'verses with every word matching its predicted pieces: {sum(exact.values())}')
    print(f'words flagged by the cross-check: {n_flag} ({100 * n_flag / words:.1f}%), '
          f'in {len(flagged)} verses, on {len(pages)} pages')
    print('pages with the most flags:', ', '.join(f'{p} ({n})' for p, n in pages.most_common(10)))

    if '--render' in sys.argv:
        out = Path(sys.argv[sys.argv.index('--render') + 1])
        out.mkdir(parents=True, exist_ok=True)
        render(db, flagged, sorted(pages), out)


def render(db, flagged, pages, out):
    """Draws each page with every word box; flagged words in red."""
    with zipfile.ZipFile(SVG_ZIP) as z, tempfile.TemporaryDirectory() as tmp:
        for page in pages:
            svg = z.read(f'svg/{page:03d}.svg').decode()
            rects = []
            for s, a, w, x0, y0, x1, y1 in db.execute(
                    'SELECT surah, ayah, word, x0, y0, x1, y1 FROM word_box WHERE page = ?', (page,)):
                colour = 'red' if w in flagged.get((s, a), []) else ('#393' if w % 2 else '#33c')
                x0, y0, x1, y1 = x0 / 10, y0 / 10, x1 / 10, y1 / 10
                rects.append(f'<rect x="{x0}" y="{y0}" width="{x1 - x0}" height="{y1 - y0}" '
                             f'fill="none" stroke="{colour}" stroke-width="0.4"/>')
            body = svg[svg.index('<svg'):].replace('<svg ', '<svg width="1035" height="1650" ', 1)
            body = body.replace('</svg>', ''.join(rects) + '</svg>')
            page_html = Path(tmp) / f'{page:03d}.html'
            page_html.write_text('<!doctype html><body style="margin:0;background:#fff">' + body)
            subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--window-size=1035,1650',
                            f'--screenshot={out / f"{page:03d}.png"}', page_html.as_uri()],
                           capture_output=True)
    print(f'drew {len(pages)} pages in {out}')


if __name__ == '__main__':
    main()
