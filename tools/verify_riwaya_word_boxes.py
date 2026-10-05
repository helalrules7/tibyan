"""Checks the riwaya word boxes (build_riwaya_word_boxes.py) and draws
pages for review.

There is no second source of word positions for these editions (the
Hafs check compares with quran.com's 1405H glyph boxes; nothing like it
exists for the riwayat), so the checks are about the geometry itself:

  coverage  every printed verse has a box for each of its words, as many
            as its KFGQPC text has words (split surahs: see the builder)
  outline   each box's centre lies inside its verse's outline on its page
            (the quran-ws verse outlines)
  order     a verse's words run in reading order: page and line forward,
            right to left on a line
  overlap   two neighbouring words on a line overlapping by more than half
            of the narrower one
  width     a word's box width over its width in the riwaya's font, against
            the verse's median: outside 0.6 to 1.6 is flagged, as in
            verify_word_boxes.py. The font widths also guide the split,
            so this is not independent: it finds the words the split had
            to squeeze or stretch, which are worth a look.

Flags point a reviewer to places worth a look; they are not errors.

Usage:
  python3 tools/verify_riwaya_word_boxes.py [warsh,qalun,...] [--words DIR]
          [--render DIR]
  --words DIR   read DIR/words-<riwaya>.json (build_riwaya_word_boxes.py
                --out DIR) instead of building again
  --render DIR  draw every page with flagged words as PNG (cairosvg) or,
                without cairosvg, as SVG: boxes in green and blue, flagged
                ones in red
"""
import collections
import json
import statistics
import sys
import zipfile
from pathlib import Path

import build_riwaya_word_boxes as W
import build_word_boxes as B
import riwayat as R

LOW, HIGH = 0.6, 1.6


def load(riwaya, words_dir):
    """{(surah, ayah): (exact, [(word_no, page, x0, y0, x1, y1)])} in page
    units."""
    if words_dir:
        d = json.loads((Path(words_dir) / f'words-{riwaya}.json').read_text(encoding='utf-8'))
        return {(s, a): (exact, [(i + 1, b[0], *(v / 10 for v in b[1:])) for i, b in enumerate(bs)])
                for s, a, exact, _, bs in d['verses']}
    return {k: (e, bs) for k, (e, _, bs) in W.build(riwaya).items()}


def outlines(riwaya):
    """{(page, surah, ayah): [polygon]} from the page SVGs' verse outlines."""
    out = collections.defaultdict(list)
    with zipfile.ZipFile(R.RCACHE / f'{R.RIWAYAT[riwaya][0]}-kfqc-svg.zip') as z:
        for name in R.qws_svg_names(riwaya):
            page = int(name[-7:-4])
            _, verses = B.read_page(z.read(name).decode())
            for s, a, parts in verses:
                out[(page, s, a)].extend(parts)
    return out


def check(riwaya, boxes):
    text = {k: W.words_of(W.verse_tokens(t)) for k, t in R.kfgqpc_text(riwaya).items()}
    printed = R.qws_verses(riwaya)
    # A surah the text file counts differently (al-Duri's al-Mulk): its
    # words per printed verse are not in the text file; only the surah's
    # total is compared.
    pc, tc = R.counts(printed), R.counts(text)
    for s in range(1, 115):
        if pc[s] != tc[s]:
            want = sum(len(text[(s, a)]) for a in range(1, tc[s] + 1))
            got = sum(len(boxes.get((s, a), (0, []))[1]) for a in range(1, pc[s] + 1))
            print(f'  surah {s}: printed {pc[s]} verses, text {tc[s]}; words {got} of {want}')
            for a in range(1, tc[s] + 1):
                text.pop((s, a))
    polys = outlines(riwaya)
    fonts = W.font_widths(R.kfgqpc_font(riwaya)[1], {w for ws in text.values() for w in ws})
    problems = collections.defaultdict(list)  # kind -> [(verse, word)]
    flagged = collections.defaultdict(set)    # verse -> word numbers
    missing = [k for k in printed if k not in boxes]
    for verse, (_, bs) in sorted(boxes.items()):
        words = text.get(verse)
        if words is not None and len(words) != len(bs):
            problems['count'].append((verse, None))
        for n, page, x0, y0, x1, y1 in bs:
            c = ((x0 + x1) / 2, (y0 + y1) / 2)
            if not any(B.inside(c, p) for p in polys.get((page, *verse), [])):
                problems['outline'].append((verse, n))
                flagged[verse].add(n)
        for (n, p0, ax0, ay0, ax1, ay1), (m, p1, bx0, by0, bx1, by1) in zip(bs, bs[1:]):
            same_line = p0 == p1 and abs((ay0 + ay1) / 2 - (by0 + by1) / 2) < (ay1 - ay0) / 2
            if p1 < p0 or (same_line and bx1 > ax1 + 1):
                problems['order'].append((verse, m))
                flagged[verse].add(m)
            if same_line:
                overlap = min(ax1, bx1) - max(ax0, bx0)
                if overlap > 0.5 * min(ax1 - ax0, bx1 - bx0):
                    problems['overlap'].append((verse, m))
                    flagged[verse].add(m)
        if words is not None and len(words) == len(bs):
            ratios = [(b[4] - b[2]) / fonts[w] for w, b in zip(words, bs) if fonts[w] > 0]
            med = statistics.median(ratios) if ratios else 0
            for (n, *_), w in zip(bs, words):
                if med and fonts[w] > 0:
                    r = (bs[n - 1][4] - bs[n - 1][2]) / fonts[w] / med
                    if not LOW <= r <= HIGH:
                        problems['width'].append((verse, n))
                        flagged[verse].add(n)
    return missing, problems, flagged


def report(riwaya, boxes, missing, problems, flagged):
    words = sum(len(bs) for _, bs in boxes.values())
    exact = sum(e for e, _ in boxes.values())
    n_flag = sum(len(f) for f in flagged.values())
    pages = collections.Counter(boxes[v][1][w - 1][1] for v, ws in flagged.items() for w in ws)
    print(f'{riwaya}: {len(boxes)} verses, {words} words; exact {exact} ({100 * exact / len(boxes):.1f}%)')
    print(f'  printed verses without boxes: {len(missing)} {missing[:5]}')
    for kind in ('count', 'outline', 'order', 'overlap', 'width'):
        print(f'  {kind}: {len(problems[kind])}')
    print(f'  words flagged: {n_flag} ({100 * n_flag / words:.1f}%), in {len(flagged)} verses, '
          f'on {len(pages)} pages')
    print('  pages with the most flags:', ', '.join(f'{p} ({n})' for p, n in pages.most_common(8)))
    return pages


def render(riwaya, boxes, flagged, pages, out):
    """Draws each page with its word boxes; flagged words in red."""
    try:
        import cairosvg
    except ImportError:
        cairosvg = None
    by_page = collections.defaultdict(list)
    for verse, (_, bs) in boxes.items():
        for n, page, x0, y0, x1, y1 in bs:
            colour = 'red' if n in flagged.get(verse, ()) else ('#393' if n % 2 else '#33c')
            by_page[page].append(f'<rect x="{x0}" y="{y0}" width="{x1 - x0}" height="{y1 - y0}" '
                                 f'fill="none" stroke="{colour}" stroke-width="0.4"/>')
    out.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(R.RCACHE / f'{R.RIWAYAT[riwaya][0]}-kfqc-svg.zip') as z:
        for page in pages:
            svg = z.read(f'svg/{page:03d}.svg').decode()
            svg = svg.replace('</svg>', ''.join(by_page[page]) + '</svg>')
            if cairosvg:
                cairosvg.svg2png(bytestring=svg.encode(), write_to=str(out / f'{riwaya}-{page:03d}.png'),
                                 output_width=1035, background_color='white')
            else:
                (out / f'{riwaya}-{page:03d}.svg').write_text(svg, encoding='utf-8')
    print(f'  drew {len(pages)} pages in {out}')


def main(argv):
    words_dir = render_dir = None
    if '--words' in argv:
        i = argv.index('--words')
        words_dir = argv[i + 1]
        del argv[i:i + 2]
    if '--render' in argv:
        i = argv.index('--render')
        render_dir = Path(argv[i + 1])
        del argv[i:i + 2]
    for riwaya in (argv[0].split(',') if argv else list(R.RIWAYAT)):
        boxes = load(riwaya, words_dir)
        missing, problems, flagged = check(riwaya, boxes)
        pages = report(riwaya, boxes, missing, problems, flagged)
        if render_dir:
            render(riwaya, boxes, flagged, sorted(pages), render_dir)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
