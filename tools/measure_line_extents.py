"""Measures, over all 604 pages of each edition, how far the ink of the
first and last lines reaches beyond their line centres, so the app can
leave enough room that no line is ever cut. Prints the constants used by
the page layouts (lib/features/mushaf/presentation/widgets/*_page.dart).

New edition: page units, line grid 26.2 + 35.75 * j.
Old edition: image pixels, line grid 8 + (j + 0.5) * 1594 / 15.
"""
import io
import sys
import zipfile
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_word_boxes as B  # noqa: E402

ROOT = Path(__file__).resolve().parent
FIRST, PITCH = 26.2, 35.75
OLD_TOP, OLD_PITCH = 8, 1594 / 15


def new_edition():
    above = below = 0.0
    worst = (0, 0)
    with zipfile.ZipFile(B.SVG_ZIP) as z:
        for page in range(3, 605):
            items, _ = B.read_page(z.read(f'svg/{page:03d}.svg').decode())
            top = min(b[1] for b, _ in items)
            bottom = max(b[3] for b, _ in items)
            a, b = FIRST - top, bottom - (FIRST + 14 * PITCH)
            if a > above:
                above = a
            if b > below:
                below, worst = b, (page, round(bottom, 1))
    return above, below, worst


def old_edition():
    above = below = 0
    with zipfile.ZipFile(ROOT / '.cache' / 'images_1024.zip') as z:
        for page in range(3, 605):
            alpha = Image.open(io.BytesIO(z.read(f'width_1024/page{page:03d}.png'))).convert('RGBA').getchannel('A')
            box = alpha.point(lambda v: 255 if v > 60 else 0).getbbox()
            above = max(above, OLD_TOP + 0.5 * OLD_PITCH - box[1])
            below = max(below, box[3] - (OLD_TOP + 14.5 * OLD_PITCH))
    return above, below


if __name__ == '__main__':
    a, b, w = new_edition()
    print(f'new edition: first line ink up to {a:.1f} units above its centre, '
          f'last line ink up to {b:.1f} units below its centre (worst page {w[0]})')
    oa, ob = old_edition()
    print(f'old edition: {oa:.1f} px above, {ob:.1f} px below')
