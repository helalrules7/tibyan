"""Where the ink of each old Madina (1405H) page lies, for drawing a page
fitted to the height a little larger (lib/features/mushaf/presentation/
widgets/old_mushaf_page.dart).

The pages share one crop (the ink of all 604 pages together), so most
pages keep a margin of their own: their text spans about 55..982 px of
the 1024 px width where the crop spans 19..1011. Each page's own extents
let it fill the space instead.

Input:  tools/.cache/images_1024.zip (quran.com page images).
Output: assets/config/old_page_ink.json: {"page": [left, top, right, bottom]}
        in image px, for pages 3..604 (1 and 2 are the opening pages).
Usage:  python3 tools/measure_old_page_ink.py
"""
import io
import json
import re
import zipfile
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent
ZIP = ROOT / '.cache' / 'images_1024.zip'
OUT = ROOT.parent / 'assets' / 'config' / 'old_page_ink.json'
# A pixel counts as ink above this alpha; a row or column needs this many.
ALPHA = 40
MIN_PIXELS = 2


def extents(png):
    im = np.array(Image.open(io.BytesIO(png)).convert('LA'))
    ink = im[:, :, 1] > ALPHA
    cols = np.where(ink.sum(0) > MIN_PIXELS)[0]
    rows = np.where(ink.sum(1) > MIN_PIXELS)[0]
    return [int(cols[0]), int(rows[0]), int(cols[-1]) + 1, int(rows[-1]) + 1]


def main():
    out = {}
    with zipfile.ZipFile(ZIP) as z:
        for name in sorted(z.namelist()):
            m = re.search(r'page(\d+)\.png$', name)
            if not m or int(m.group(1)) < 3:
                continue
            out[str(int(m.group(1)))] = extents(z.read(name))
    OUT.write_text(json.dumps(out, separators=(',', ':'), sort_keys=True) + '\n')
    print(f'{len(out)} pages -> {OUT.relative_to(ROOT.parent)}')


if __name__ == '__main__':
    main()
