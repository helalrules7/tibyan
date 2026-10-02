"""Draws pages of the new Madina edition (1441H) with the tajweed colouring
built by build_tajweed.py, for a human to check where the colours land.

The page artwork is drawn unchanged; each coloured contour is drawn again
in its rule's colour, clipped to the letter where the build clipped it,
exactly as the app does. Rendered with headless Google Chrome.

Usage:  python3 tools/verify_tajweed.py 3 50 77   -> tools/out/tajweed_NNN.png
"""
import re
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
import build_tajweed as bt  # noqa: E402
import build_word_boxes as bw  # noqa: E402

CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
OUT = ROOT / 'out'

# Preview colours only (the app's palette is chosen by the reader).
COLOURS = {
    'hamzat_wasl': '#8a8a8a', 'lam_shamsiyyah': '#8a8a8a', 'silent': '#8a8a8a',
    'madd_2': '#c58a00', 'madd_246': '#e07000', 'madd_muttasil': '#c62828',
    'madd_munfasil': '#e53935', 'madd_6': '#8b0000',
    'ghunnah': '#2e7d32', 'ikhfa': '#43a047', 'ikhfa_shafawi': '#43a047', 'iqlab': '#00897b',
    'idghaam_ghunnah': '#1b5e20', 'idghaam_no_ghunnah': '#6d4c41', 'idghaam_shafawi': '#1b5e20',
    'idghaam_mutajanisayn': '#757575', 'idghaam_mutaqaribayn': '#757575',
    'qalqalah': '#1565c0',
}


def subpaths(d):
    """Each subpath of a path as its own path data, starting with an
    absolute moveto (the rest of its commands are kept as written)."""
    toks = bw.TOKENS.findall(d)
    i, cmd = 0, None
    x = y = sx = sy = 0.0
    out, cur = [], None

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
                cur.append('z')
                continue
        rel, c = cmd.islower(), cmd.upper()
        if c == 'M':
            dx, dy = num(), num()
            x, y = (x + dx, y + dy) if rel else (dx, dy)
            sx, sy = x, y
            cur = [f'M{x:.4f} {y:.4f}']
            out.append(cur)
            cmd = 'l' if rel else 'L'  # further pairs are line segments
            continue
        n = {'L': 2, 'H': 1, 'V': 1, 'C': 6, 'S': 4, 'Q': 4}[c]
        vals = [num() for _ in range(n)]
        cur.append(cmd + ' '.join(f'{v:g}' for v in vals))
        if c == 'H':
            x = x + vals[0] if rel else vals[0]
        elif c == 'V':
            y = y + vals[0] if rel else vals[0]
        else:
            x, y = (x + vals[-2], y + vals[-1]) if rel else (vals[-2], vals[-1])
    return [' '.join(p) for p in out]


def page_contours(svg):
    """[(transform, subpath)] for the page text, in the build's order."""
    out = []

    def walk(el, m, in_content):
        m = bw.compose(m, bw.parse_transform(el.get('transform')))
        in_content = in_content or el.get('id') == 'content'
        if el.tag == bw.SVG_NS + 'path' and in_content and el.get('class') != 'ayahPolygon':
            out.extend((m, s) for s in subpaths(el.get('d')))
        for child in el:
            walk(child, m, in_content)

    import xml.etree.ElementTree as ET
    walk(ET.fromstring(svg), (1, 0, 0, 1, 0, 0), False)
    return out


def preview(page, entries, svg):
    contours = page_contours(svg)
    view = re.search(r'viewBox="([^"]+)"', svg).group(1)
    defs, uses = [], []
    for n, (r, c, x0, x1) in enumerate(entries):
        m, d = contours[c]
        mat = 'matrix(' + ' '.join(f'{v:g}' for v in m) + ')'
        defs.append(f'<clipPath id="c{n}"><path transform="{mat}" d="{d}"/></clipPath>')
        use = (f'<g clip-path="url(#c{n})"><g transform="{mat}"><path d="{d}" '
               f'fill="{COLOURS[bt.RULES[r]]}"/></g></g>')
        if x0 is not None:
            defs.append(f'<clipPath id="r{n}"><rect x="{x0}" y="-1000" width="{x1 - x0}" height="3000"/></clipPath>')
            use = f'<g clip-path="url(#r{n})">{use}</g>'
        uses.append(use)
    body = svg[svg.index('>', svg.index('<svg')) + 1:svg.rindex('</svg>')]
    return (f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:ayah="https://quranpedia.net" viewBox="{view}" width="1380" height="2200">'
            f'<rect x="-1000" y="-1000" width="3000" height="3000" fill="#fffdf6"/>{body}'
            f'<defs>{"".join(defs)}</defs>{"".join(uses)}</svg>')


def main(pages):
    import build_word_boxes
    spans, _ = bt.all_spans(build_word_boxes.load_text())
    data, stats = bt.new_edition(spans, pages)
    print(stats)
    OUT.mkdir(exist_ok=True)
    with zipfile.ZipFile(bw.SVG_ZIP) as z, tempfile.TemporaryDirectory() as tmp:
        for page in pages:
            svg = z.read(f'svg/{page:03d}.svg').decode()
            src = Path(tmp) / f'{page}.svg'
            src.write_text(preview(page, data.get(page, []), svg), encoding='utf-8')
            png = OUT / f'tajweed_{page:03d}.png'
            subprocess.run([CHROME, '--headless=new', '--disable-gpu', f'--screenshot={png}',
                            '--window-size=1380,2200', '--hide-scrollbars', src.as_uri()],
                           capture_output=True, check=True)
            print(png.relative_to(ROOT.parent))


if __name__ == '__main__':
    main([int(a) for a in sys.argv[1:]] or [3])
