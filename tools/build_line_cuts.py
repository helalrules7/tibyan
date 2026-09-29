"""Where to cut each page into its 15 lines, so the app can spread the
lines over the screen height without clipping any mark.

New edition (quran-ws SVG): for each gap between two lines, the row that
crosses the fewest contours. Contours that still cross it are recorded
with their exact outline and the line they belong to, so the app can give
each one to its own line (a straight cut would clip them).

Old edition (quran.com PNG): the row with the least ink in each gap.

The page artwork is never modified; this only records geometry.
Called by build_content_db.py.
"""
import io
import sys
import zipfile
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_word_boxes as B  # noqa: E402

ROOT = Path(__file__).resolve().parent
IMAGES = ROOT / '.cache' / 'images_1024.zip'
FIRST, PITCH, LINES = 26.2, 35.75, 15          # new edition line grid
OLD_TOP, OLD_PITCH = 8, 1594 / 15              # old edition line grid (px)


def _d(points):
    return 'M ' + ' L '.join(f'{x:.1f} {y:.1f}' for x, y in points) + ' Z'


def new_edition():
    """Yields (page, cuts[14], overflow[(line, path_d)])."""
    with zipfile.ZipFile(B.SVG_ZIP) as z:
        for page in range(3, 605):
            items, _ = B.read_page(z.read(f'svg/{page:03d}.svg').decode())
            cuts, overflow = [], []
            for j in range(LINES - 1):
                lo, hi = FIRST + j * PITCH + 6, FIRST + (j + 1) * PITCH - 6
                best, y = None, lo
                while y <= hi:
                    n = sum(1 for b, _ in items if b[1] < y < b[3])
                    if best is None or n < best[0]:
                        best = (n, y)
                    y += 0.25
                cut = best[1]
                cuts.append(cut)
                for b, pts in items:
                    if b[1] < cut < b[3]:
                        cy = (b[1] + b[3]) / 2
                        line = min(range(LINES), key=lambda k: abs(FIRST + k * PITCH - cy))
                        overflow.append((line, _d(pts)))
            yield page, cuts, overflow


def old_edition():
    """Yields (page, cuts[14]) in image pixels."""
    with zipfile.ZipFile(IMAGES) as z:
        for page in range(3, 605):
            alpha = Image.open(io.BytesIO(z.read(f'width_1024/page{page:03d}.png'))).convert('RGBA').getchannel('A')
            w, h = alpha.size
            px = alpha.load()
            cuts = []
            for j in range(LINES - 1):
                mid = OLD_TOP + (j + 1) * OLD_PITCH
                rows = range(int(mid - 30), int(mid + 30))
                ink = {y: sum(1 for x in range(0, w, 2) if px[x, y] > 60) for y in rows}
                low = min(ink.values())
                best = [y for y in rows if ink[y] == low]
                cuts.append(best[len(best) // 2])
            yield page, cuts
