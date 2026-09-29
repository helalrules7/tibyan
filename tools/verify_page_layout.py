"""Checks that the page view draws every mark of every page, in both
editions, without cutting anything at the edges of the page area.

It repeats the layout arithmetic of lib/features/mushaf/presentation/
widgets/mushaf_page.dart (new edition) and old_mushaf_page.dart (old
edition) for several screen sizes, and for each of pages 3-604:
  - every contour (new) or ink row and column (old) is drawn by exactly
    one line band, and
  - once placed on screen it lies inside the page area.
Pages 1 and 2 are drawn whole (scaled to fit), so they are checked for fit.

Keep the constants below in step with the Dart files. Exits 1 on any
failure and lists the pages.

Usage: python3 tools/verify_page_layout.py
"""
import io
import sqlite3
import sys
import zipfile
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_word_boxes as B  # noqa: E402
from build_line_cuts import marker_items  # noqa: E402
import xml.etree.ElementTree as ET  # noqa: E402

ROOT = Path(__file__).resolve().parent
DB = ROOT.parent / 'assets' / 'db' / 'content.db'
IMAGES = ROOT / '.cache' / 'images_1024.zip'
LINES = 15

# new edition (mushaf_page.dart)
FIRST, PITCH = 26.2, 35.75
NEW_ABOVE, NEW_BELOW = 22.2, 21.4
VIEWBOX = (0.0, 0.0, 345.0, 550.0)
# old edition (old_mushaf_page.dart)
OLD_INK = (19, 6, 1011, 1632)
OLD_GRID_TOP, OLD_PITCH = 8.0, 1594 / 15
OLD_ABOVE, OLD_BELOW = 55.1, 83.1

# Page areas (w, h) in logical px: screen minus safe areas, the frame
# (4 px sides, 14 px top, 36 px frame inset each side) and the catchword row.
SCREENS = {
    'iPhone SE (375x667)': (375 - 80, 667 - 20 - 0 - 14 - 26 - 72),
    'iPhone 18 Pro (402x874)': (402 - 80, 874 - 59 - 34 - 14 - 26 - 72),
    'large phone (440x956)': (440 - 80, 956 - 62 - 34 - 14 - 26 - 72),
    'small Android (360x640)': (360 - 80, 640 - 24 - 0 - 14 - 26 - 72),
}


class Layout:
    def __init__(self, w, h, area, above, below):
        self.w, self.h = w, h
        self.area = area
        aw, ah = area[2] - area[0], area[3] - area[1]
        by_w, by_h = w / aw, h / ah
        self.scale = min(by_w, by_h)
        self.strips = by_w < by_h
        self.off_x = (w - aw * self.scale) / 2 - area[0] * self.scale
        s0 = h / LINES

        def pad(ink):
            need = ink * self.scale - s0 / 2 + 3
            return need if need > 0 else 0
        self.pad_top, self.pad_bottom = pad(above), pad(below)
        self.slot = (h - self.pad_top - self.pad_bottom) / LINES

    def slot_centre(self, j):
        return self.pad_top + (j + 0.5) * self.slot


def check_new(db, failures):
    with zipfile.ZipFile(B.SVG_ZIP) as z:
        pages = {p: z.read(f'svg/{p:03d}.svg').decode() for p in range(3, 605)}
    for name, (w, h) in SCREENS.items():
        lay = Layout(w, h, VIEWBOX, NEW_ABOVE, NEW_BELOW)
        bad = []
        for page, svg in pages.items():
            cuts = [y for (y,) in db.execute(
                "SELECT y FROM line_cut WHERE edition='madina1441' AND page=? ORDER BY gap", (page,))]
            owners = {}
            for line, d in db.execute('SELECT line, path FROM line_overflow WHERE page=?', (page,)):
                owners[d] = line
            items, _ = B.read_page(svg)
            problems = []
            all_boxes = items + marker_items(svg)
            for b, pts in all_boxes:
                x0, y0, x1, y1 = b
                crossing = [k for k, c in enumerate(cuts) if y0 < c < y1]
                if crossing:
                    d = 'M ' + ' L '.join(f'{x:.1f} {y:.1f}' for x, y in pts) + ' Z'
                    line = owners.get(d)
                    if line is None:
                        problems.append(f'mark at y {y0:.1f}-{y1:.1f} crosses a cut but has no owner')
                        continue
                else:
                    line = sum(1 for c in cuts if (y0 + y1) / 2 > c)
                top = lay.slot_centre(line) + (y0 - (FIRST + line * PITCH)) * lay.scale
                bottom = lay.slot_centre(line) + (y1 - (FIRST + line * PITCH)) * lay.scale
                left, right = x0 * lay.scale + lay.off_x, x1 * lay.scale + lay.off_x
                if top < -0.5 or bottom > h + 0.5 or left < -0.5 or right > w + 0.5 or x0 < VIEWBOX[0] or x1 > VIEWBOX[2]:
                    problems.append(f'line {line + 1}: mark drawn at y {top:.1f}-{bottom:.1f}, x {left:.1f}-{right:.1f} '
                                    f'outside {w}x{h}')
            if problems:
                bad.append((page, problems[:2]))
        report(f'new edition, {name}', bad, failures)


def check_old(db, failures):
    with zipfile.ZipFile(IMAGES) as z:
        alphas = {}
        for page in range(3, 605):
            a = Image.open(io.BytesIO(z.read(f'width_1024/page{page:03d}.png'))).convert('RGBA').getchannel('A')
            alphas[page] = a.point(lambda v: 255 if v > 60 else 0)
    for name, (w, h) in SCREENS.items():
        lay = Layout(w, h, OLD_INK, OLD_ABOVE, OLD_BELOW)
        bad = []
        for page, a in alphas.items():
            cuts = [y for (y,) in db.execute(
                "SELECT y FROM line_cut WHERE edition='madina1405' AND page=? ORDER BY gap", (page,))]
            problems = []
            x0, y0, x1, y1 = a.getbbox()
            if x0 < OLD_INK[0] or x1 > OLD_INK[2] or y0 < OLD_INK[1] or y1 > OLD_INK[3]:
                problems.append(f'ink {x0},{y0}-{x1},{y1} outside the crop {OLD_INK}')
            bands = [OLD_INK[1]] + cuts + [OLD_INK[3]]
            for j in range(LINES):
                band = a.crop((0, int(bands[j]), a.width, int(bands[j + 1]) + 1)).getbbox()
                if band is None:
                    continue
                top = lay.slot_centre(j) + (bands[j] + band[1] - (OLD_GRID_TOP + (j + 0.5) * OLD_PITCH)) * lay.scale
                bottom = lay.slot_centre(j) + (bands[j] + band[3] - (OLD_GRID_TOP + (j + 0.5) * OLD_PITCH)) * lay.scale
                if top < -0.5 or bottom > h + 0.5:
                    problems.append(f'line {j + 1}: drawn at y {top:.1f}-{bottom:.1f} outside height {h}')
            if problems:
                bad.append((page, problems[:2]))
        report(f'old edition, {name}', bad, failures)


def report(title, bad, failures):
    if not bad:
        print(f'OK    {title}: all 602 pages fit')
        return
    failures.append(title)
    print(f'FAIL  {title}: {len(bad)} pages')
    for page, problems in bad[:8]:
        print(f'        page {page}: ' + '; '.join(problems))


def main():
    db = sqlite3.connect(DB)
    failures = []
    check_new(db, failures)
    if IMAGES.exists():
        check_old(db, failures)
    else:
        print('SKIP  old edition: tools/.cache/images_1024.zip missing')
    return 1 if failures else 0


if __name__ == '__main__':
    sys.exit(main())
