"""Builds the ornament images for the Zakhrafa style from the vector
sources in tools/ornaments/src/ (files provided by Ahmed; licences are
tracked in docs/DATA_SOURCES.md).

What it makes, under assets/ornaments/ (PNG, rendered at 4x so the
pieces stay sharp on every screen):
  frame_corner.png        top-right corner of the page frame (the app
                          mirrors it for the other three corners)
  frame_edge_h.png        one repeat of the top edge (mirrored for the bottom)
  frame_edge_v.png        one repeat of the right edge (mirrored for the left)
  mosaic_tile.png         seamless tile of the geometric mosaic
  rosette_cartouche.png   rosette at the ends of the cartouches
  rosette_margin.png      rosette for juz and hizb marks in the margin
  marker_7.png, marker_9.png, marker_16.png   optional verse-marker shapes
  splash_gold.png         the golden arch background for the dark splash

The Turkish border is recoloured from lavender and blue to the Zakhrafa
palette (teal, coral, navy). Rendering uses headless Google Chrome, and
Ghostscript for the EPS.

Usage: python3 tools/build_ornaments.py
"""
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
SRC = ROOT / 'ornaments' / 'src'
OUT = ROOT.parent / 'assets' / 'ornaments'
CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
SCALE = 4
BAND = 30.0  # frame band depth in logical pixels

TURK_COLOURS = {
    '#CC99FF': '#E6784A', '#6699FF': '#1FA79B', '#99FF99': '#F6E3C8', '#FF9999': '#F3A27C',
    '#DEFF9D': '#F6E3C8', '#45D6D6': '#F2C46D', '#1B59AA': '#2B4A63', '#1F62BA': '#24425C',
    '#002454': '#14263A',
}
ROSETTE_B_COLOURS = {
    '#D8D9C9': '#F6E3C8', '#A9D962': '#1FA79B', '#5C4167': '#1C2F45', '#F3A4A0': '#F3A27C',
    '#2EB7C1': '#1FA79B', '#258F99': '#0D5F59', '#EF821D': '#E6784A', '#812081': '#1C2F45',
    '#0075BF': '#4F79B7', '#E5C6C6': '#F6E3C8', '#F7EBEB': '#FFFFFF', '#038C73': '#0D5F59',
    '#85AB4D': '#0D5F59', '#ECE7E1': '#FFFFFF', '#E6FFC2': '#F6E3C8', '#EF9B4C': '#E6784A',
    '#3BA7A7': '#1FA79B', '#FFE6C9': '#F6E3C8', '#F2F2F2': '#FFFFFF',
}
ROSETTE_A_COLOURS = {'#5D5D7C': '#1C2F45', '#D6856A': '#E6784A', '#115E78': '#1C2F45', '#268FC4': '#4F79B7'}

# Turkish border geometry, in its own units (a 1400 x 1400 symmetric frame)
CORNER, DEPTH, PERIOD, EDGE_START = 245, 200, 152, 245
ROSETTES_A = [(75, 164, 286, 328), (387, 164, 302, 328), (698, 164, 328, 328), (1075, 164, 244, 328),
              (61, 485, 311, 327), (405, 485, 277, 327), (720, 485, 284, 327), (1020, 485, 319, 327)]
ROSETTES_B = [(61, 108, 291, 318), (381, 108, 306, 318), (703, 108, 318, 318), (1038, 108, 302, 318),
              (49, 536, 315, 336), (380, 536, 308, 336), (715, 536, 294, 336), (1028, 536, 323, 336)]


def load(name, colours, strip=()):
    s = (SRC / name).read_text(encoding='utf-8', errors='ignore')
    s = re.sub(r'<!DOCTYPE[^\[]*\[.*?\]>', '', s, flags=re.S)
    for bit in strip:
        s = s.replace(bit, '')
    return re.sub(r'#[0-9a-fA-F]{6}\b', lambda m: colours.get(m.group(0).upper(), m.group(0)), s)


def render_crop(svg_text, box, out_w, out_h, name, transparent=True):
    """Renders the viewBox `box` of an SVG to out_w x out_h logical px at SCALE."""
    x, y, w, h = box
    svg = re.sub(r'<svg\b[^>]*>', f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
                 f'width="{out_w}" height="{out_h}" viewBox="{x} {y} {w} {h}" preserveAspectRatio="none">', svg_text, count=1)
    with tempfile.TemporaryDirectory() as tmp:
        html = Path(tmp) / 'r.html'
        html.write_text(f'<!doctype html><html style="overflow:hidden"><body style="margin:0;background:transparent">{svg}</body></html>',
                        encoding='utf-8')
        # Chrome has a minimum window size: render in a larger window and crop.
        shot = Path(tmp) / 'shot.png'
        win_w, win_h = max(600, int(out_w) + 1), max(600, int(out_h) + 1)
        args = [CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', f'--window-size={win_w},{win_h}',
                f'--force-device-scale-factor={SCALE}', f'--screenshot={shot}']
        if transparent:
            args.append('--default-background-color=00000000')
        subprocess.run(args + [html.as_uri()], check=True, capture_output=True)
        Image.open(shot).crop((0, 0, round(out_w * SCALE), round(out_h * SCALE))).save(OUT / name)
    print(f'{name}: {Image.open(OUT / name).size}')


def square(box):
    x, y, w, h = box
    side = max(w, h)
    return (x - (side - w) / 2, y - (side - h) / 2, side, side)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    turk = load('turkish_border.svg', TURK_COLOURS)
    s = BAND / DEPTH
    corner = round(CORNER * s, 2)
    render_crop(turk, (1400 - CORNER, 0, CORNER, CORNER), corner, corner, 'frame_corner.png')
    render_crop(turk, (EDGE_START, 0, PERIOD, DEPTH), round(PERIOD * s, 2), BAND, 'frame_edge_h.png')
    render_crop(turk, (1400 - DEPTH, EDGE_START, DEPTH, PERIOD), BAND, round(PERIOD * s, 2), 'frame_edge_v.png')

    ros_a = load('rosettes_a.svg', ROSETTE_A_COLOURS, strip=('<rect fill="#EFEFEF" width="1400" height="980"/>',))
    ros_b = load('rosettes_b.svg', ROSETTE_B_COLOURS, strip=('<rect fill="#FFEECC" width="1400" height="980"/>',))
    render_crop(ros_a, square(ROSETTES_A[2]), 40, 40, 'rosette_cartouche.png')
    render_crop(ros_a, square(ROSETTES_A[6]), 40, 40, 'rosette_margin.png')
    render_crop(ros_a, square(ROSETTES_A[6]), 40, 40, 'marker_7.png')
    render_crop(ros_b, square(ROSETTES_B[0]), 40, 40, 'marker_9.png')
    render_crop(ros_b, square(ROSETTES_B[7]), 40, 40, 'marker_16.png')

    # Mosaic: render the Vol 2 border at 3x and cut one seamless repeat
    # (204 x 302 px at 3x) from the band between its first two arches.
    vol2 = (SRC / 'border_vol2.svg').read_text(encoding='utf-8', errors='ignore')
    with tempfile.TemporaryDirectory() as tmp:
        html = Path(tmp) / 'v.html'
        big = Path(tmp) / 'v.png'
        html.write_text(f'<!doctype html><html style="overflow:hidden"><body style="margin:0">{vol2}</body></html>', encoding='utf-8')
        subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--window-size=1400,980',
                        '--force-device-scale-factor=3', f'--screenshot={big}', html.as_uri()], check=True, capture_output=True)
        Image.open(big).convert('RGB').crop((900, 1142, 900 + 204, 1142 + 302)).save(OUT / 'mosaic_tile.png')
    print(f'mosaic_tile.png: {Image.open(OUT / "mosaic_tile.png").size}')

    # Golden background for the dark splash, cropped to a tall phone shape.
    with tempfile.TemporaryDirectory() as tmp:
        png = Path(tmp) / 'g.png'
        subprocess.run(['gs', '-q', '-dSAFER', '-dBATCH', '-dNOPAUSE', '-dEPSCrop', '-sDEVICE=png16m', '-r120',
                        f'-sOutputFile={png}', str(SRC / 'golden_decor_06.eps')], check=True)
        im = Image.open(png).convert('RGB')
        h = 2532
        im = im.resize((round(im.width * h / im.height), h), Image.LANCZOS)
        left = (im.width - 1170) // 2
        im.crop((left, 0, left + 1170, h)).save(OUT / 'splash_gold.jpg', quality=88)
    print('splash_gold.jpg: (1170, 2532)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
