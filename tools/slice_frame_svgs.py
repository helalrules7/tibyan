"""Cut the owner's frame designs (tools/ornaments/src/themes/*.svg) into the
pieces the app draws, without redrawing anything: each piece is the
original SVG with a different viewBox, minus the layout placeholders.

Placeholders removed (they stand for the mushaf text the app draws):
  - every <text> ("QURAN PAGE", «سورة», "AL-FATIHAH" ...);
  - the ruled text lines (<line> with opacity .52);
  - in the opening pages, the shapes inside the text panels (verse-marker
    circles and an arc standing for the text);
  - in the page-frame pieces, the text panel's paper (the app's paper
    shows there).
Shapes wholly outside a piece's view are dropped too (never visible).

Pieces per set, written flat to assets/ornaments/ (an existing asset
folder), as frame_<set>_<piece>.svg:
  corner   top-left corner of the page frame (46 units; the app mirrors it)
  edge_h   one repeat of the top band (one rhythm motif), tiled by the app
  edge_v   one repeat of the left band, tiled by the app
  medal    the page frame's bottom medallion
  divider  the surah divider, cropped to its drawing, background removed
  splash   the splash / cover composition, whole
  open_a   the al-Fatiha opening page (left half of _04), background kept
  open_b   the al-Baqarah opening page (right half of _04)

Usage:
  python3 tools/slice_frame_svgs.py
"""
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SRC = ROOT / 'ornaments' / 'src' / 'themes'
OUT = ROOT.parent / 'assets' / 'ornaments'
SETS = ['abbasid', 'umayyad', 'andalusian', 'ottoman', 'egyptian', 'modern_islamic']

# Page frame (_01, 900 x 1200): the outer rule is at x=120 / y=80, the inner
# one at x=130 / y=90; the band's motifs repeat every 24 units, from x=138
# along the top and from y=122 down the sides. The band piece is 34 units
# deep, from just outside the outer rule to past the corner flourishes.
BAND = 34
# The corner piece is larger than the band: its flourish (an octagon and
# stars) sits just inside the inner rule.
CORNER = 46
X0, Y0 = 116, 76
STEP = 24


def strip_placeholders(svg):
    # An unused, empty blur filter (nothing refers to it).
    svg = re.sub(r'<defs>\s*<filter id="none">.*?</filter>\s*</defs>\s*', '', svg, flags=re.S)
    svg = re.sub(r'<text\b[^>]*>.*?</text>', '', svg, flags=re.S)
    svg = re.sub(r'<line\b[^>]*opacity="\.52"[^>]*/>', '', svg)
    return svg


def strip_background(svg):
    """Drop the first full-canvas rect (the paper), so the piece is transparent."""
    return re.sub(r'<rect width="\d+" height="\d+" fill="[^"]+"\s*/>', '', svg, count=1)


NUM = re.compile(r'-?\d+(?:\.\d+)?')


def _box(tag):
    """Bounding box of an element's own coordinates, or None to keep it."""
    kind = re.match(r'<(\w+)', tag).group(1)
    def attr(name):
        m = re.search(r'\s%s="([^"]*)"' % name, tag)
        return m.group(1) if m else None
    if kind == 'polygon':
        v = [float(n) for n in NUM.findall(attr('points') or '')]
    elif kind == 'line':
        v = [float(attr(k) or 0) for k in ('x1', 'y1', 'x2', 'y2')]
    elif kind == 'circle':
        cx, cy, r = (float(attr(k) or 0) for k in ('cx', 'cy', 'r'))
        v = [cx - r, cy - r, cx + r, cy + r]
    elif kind == 'path':
        d = attr('d') or ''
        if re.search(r'[a-zA-Z]', re.sub(r'[MLQCZ]', '', d)):
            return None  # relative or arc commands: keep it
        v = [float(n) for n in NUM.findall(d)]
    else:
        return None
    if len(v) < 2 or len(v) % 2:
        return None
    xs, ys = v[0::2], v[1::2]
    return min(xs), min(ys), max(xs), max(ys)


def prune(svg, x, y, w, h, margin=6):
    """Drop shapes that lie wholly outside the view (they would never show,
    and the app draws each band piece many times per page)."""
    def keep(m):
        b = _box(m.group(0))
        if b is None:
            return m.group(0)
        x0, y0, x1, y1 = b
        if x1 < x - margin or y1 < y - margin or x0 > x + w + margin or y0 > y + h + margin:
            return ''
        return m.group(0)
    return re.sub(r'<(?:polygon|line|circle|path)\b[^>]*/>', keep, svg)


# Text panels of the opening pages (_04): the mushaf page goes there.
PANELS = [(115, 175, 520, 665), (765, 175, 520, 665)]


def without_panel_marks(svg):
    """Drop the shapes drawn wholly inside a text panel (the verse-marker
    circles and the arc that stand for the text), which would otherwise
    show through the mushaf page drawn over them."""
    def keep(m):
        b = _box(m.group(0))
        if b is None:
            return m.group(0)
        for px, py, pw, ph in PANELS:
            if b[0] >= px and b[1] >= py and b[2] <= px + pw and b[3] <= py + ph:
                return ''
        return m.group(0)
    return re.sub(r'<(?:polygon|line|circle|path)\b[^>]*/>', keep, svg)


def piece(svg, x, y, w, h):
    return with_view(prune(svg, x, y, w, h), x, y, w, h)


def without_panel(svg):
    """Drop the text panel's paper (the page's own paper shows there)."""
    return re.sub(r'<rect x="170" y="130" width="560" height="940"[^>]*/>', '', svg)


def with_view(svg, x, y, w, h):
    svg = re.sub(r'\swidth="[\d.]+"\s+height="[\d.]+"\s+viewBox="[^"]*"',
                 f' width="{w}" height="{h}" viewBox="{x} {y} {w} {h}"', svg, count=1)
    return svg


def drawing_box(svg, width, height):
    """Bounding box of what is drawn (non-transparent pixels), in SVG units."""
    with tempfile.TemporaryDirectory() as d:
        src = Path(d) / 'a.svg'
        png = Path(d) / 'a.png'
        src.write_text(svg, encoding='utf-8')
        subprocess.run(['rsvg-convert', '-w', str(width), '-o', str(png), str(src)], check=True)
        from PIL import Image
        im = Image.open(png).convert('RGBA')
        box = im.getchannel('A').getbbox()
        k = width / im.width
        pad = 4
        x0, y0, x1, y1 = box
        return (max(0, x0 * k - pad), max(0, y0 * k - pad),
                min(width, x1 * k + pad), min(height, y1 * k + pad))


def write(name, svg):
    (OUT / name).write_text(svg, encoding='utf-8')


def main():
    for s in SETS:
        frame = strip_placeholders((SRC / f'{s}_01_page_frame.svg').read_text(encoding='utf-8'))
        bare = strip_background(frame)
        bare = without_panel(bare)
        write(f'frame_{s}_corner.svg', piece(bare, X0, Y0, CORNER, CORNER))
        # Any 24-unit window of the band repeats seamlessly.
        write(f'frame_{s}_edge_h.svg', piece(bare, X0 + CORNER, Y0, STEP, BAND))
        write(f'frame_{s}_edge_v.svg', piece(bare, X0, Y0 + CORNER, BAND, STEP))
        write(f'frame_{s}_medal.svg', piece(bare, 420, 1020, 60, 60))

        divider = strip_background(strip_placeholders(
            (SRC / f'{s}_02_surah_divider.svg').read_text(encoding='utf-8')))
        x0, y0, x1, y1 = drawing_box(divider, 1200, 340)
        write(f'frame_{s}_divider.svg',
              with_view(divider, round(x0), round(y0), round(x1 - x0), round(y1 - y0)))

        write(f'frame_{s}_splash.svg', strip_placeholders(
            (SRC / f'{s}_03_splash.svg').read_text(encoding='utf-8')))

        opening = without_panel_marks(strip_placeholders(
            (SRC / f'{s}_04_opening_fatihah_baqarah.svg').read_text(encoding='utf-8')))
        write(f'frame_{s}_open_a.svg', piece(opening, 50, 50, 650, 900))
        write(f'frame_{s}_open_b.svg', piece(opening, 700, 50, 650, 900))
        print(s, 'ok')
    return 0


if __name__ == '__main__':
    sys.exit(main())
