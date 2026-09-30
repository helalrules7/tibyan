"""Cut the owner's frame designs (tools/ornaments/src/themes/*.svg) into the
pieces the app draws, without redrawing anything: each piece is the
original SVG with a different viewBox, minus the layout placeholders.

Placeholders removed (they stand for the mushaf text the app draws):
  - every <text> ("QURAN PAGE", «سورة», "AL-FATIHAH" ...);
  - the ruled text lines (<line> with opacity .52).

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
    svg = re.sub(r'<text\b[^>]*>.*?</text>', '', svg, flags=re.S)
    svg = re.sub(r'<line\b[^>]*opacity="\.52"[^>]*/>', '', svg)
    return svg


def strip_background(svg):
    """Drop the first full-canvas rect (the paper), so the piece is transparent."""
    return re.sub(r'<rect width="\d+" height="\d+" fill="[^"]+"\s*/>', '', svg, count=1)


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
        write(f'frame_{s}_corner.svg', with_view(bare, X0, Y0, CORNER, CORNER))
        # Any 24-unit window of the band repeats seamlessly.
        write(f'frame_{s}_edge_h.svg', with_view(bare, X0 + CORNER, Y0, STEP, BAND))
        write(f'frame_{s}_edge_v.svg', with_view(bare, X0, Y0 + CORNER, BAND, STEP))
        write(f'frame_{s}_medal.svg', with_view(bare, 420, 1020, 60, 60))

        divider = strip_background(strip_placeholders(
            (SRC / f'{s}_02_surah_divider.svg').read_text(encoding='utf-8')))
        x0, y0, x1, y1 = drawing_box(divider, 1200, 340)
        write(f'frame_{s}_divider.svg',
              with_view(divider, round(x0), round(y0), round(x1 - x0), round(y1 - y0)))

        write(f'frame_{s}_splash.svg', (SRC / f'{s}_03_splash.svg').read_text(encoding='utf-8'))

        opening = strip_placeholders(
            (SRC / f'{s}_04_opening_fatihah_baqarah.svg').read_text(encoding='utf-8'))
        write(f'frame_{s}_open_a.svg', with_view(opening, 50, 50, 650, 900))
        write(f'frame_{s}_open_b.svg', with_view(opening, 700, 50, 650, 900))
        print(s, 'ok')
    return 0


if __name__ == '__main__':
    sys.exit(main())
