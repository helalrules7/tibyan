"""Checks that the app draws its own surah header over every printed one.

A printed surah header is a single very wide shape: in the new edition a
contour wider than 250 units, in the old edition an ink run wider than
750 px. Finds the line of every printed header on pages 3-604 and compares
it with the lines the app computes (lib/features/mushaf/mushaf_providers.dart:
the header two lines above verse 1, one for at-Tawba, or at the end of the
previous page when it does not fit). Exits 1 on any difference.
"""
import io
import sqlite3
import sys
import zipfile
from pathlib import Path

from PIL import Image
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_word_boxes as B  # noqa: E402

ROOT = Path(__file__).resolve().parent
DB = sqlite3.connect(ROOT.parent / 'assets' / 'db' / 'content.db')
FIRST, PITCH = 26.2, 35.75


def rects(d):
    import re
    out, xs, ys = [], [], []
    for t in re.findall(r'[MLZ]|-?\d+\.?\d*', d):
        pass
    parts = d.replace('Z', 'Z|').split('|')
    for part in parts:
        nums = [float(v) for v in re.findall(r'-?\d+\.?\d*', part)]
        if len(nums) >= 2:
            px, py = nums[0::2], nums[1::2]
            out.append((min(px), min(py), max(px), max(py)))
    return out


def expected(edition):
    """{page: {header lines}} as the app computes them."""
    col = 'page_1405' if edition == 'madina1405' else 'page'
    starts = DB.execute(f'SELECT surah, {col} FROM ayah WHERE number = 1 AND surah > 1').fetchall()
    line_of = {}
    if edition == 'madina1441':
        for s, a, p, d in DB.execute('SELECT surah, number, page, path FROM ayah_polygon WHERE number = 1'):
            line_of[(s, p)] = max(0, min(14, round((sorted(rects(d), key=lambda r: r[1])[0][1] - 8.3) / 35.75)))
    else:
        g = sqlite3.connect(str(ROOT / '.cache' / 'ayahinfo_1024.db'))
        for s, p, ln in g.execute('SELECT sura_number, page_number, MIN(line_number) FROM glyphs WHERE ayah_number = 1 GROUP BY 1, 2'):
            line_of[(s, p)] = ln - 1
    out = {}
    for s, p in starts:
        if p <= 2:
            continue
        line = line_of[(s, p)]
        need = 1 if s == 9 else 2
        if line >= need:
            out.setdefault(p, set()).add(line - need)
        else:
            out.setdefault(p - 1, set()).add(15 - (need - line))
    return out


def printed_new():
    """Lines with ink that belong to no verse: headers and basmalas."""
    found = {}
    polys = {}
    for p, d in DB.execute('SELECT page, path FROM ayah_polygon'):
        polys.setdefault(p, []).extend(rects(d))
    with zipfile.ZipFile(B.SVG_ZIP) as z:
        for page in range(3, 605):
            items, _ = B.read_page(z.read(f'svg/{page:03d}.svg').decode())
            inked = {max(0, min(14, round(((b[1] + b[3]) / 2 - FIRST) / PITCH))) for b, _ in items}
            for j in inked:
                cy = FIRST + j * PITCH
                if not any(r[1] <= cy <= r[3] for r in polys.get(page, [])):
                    found.setdefault(page, set()).add(j)
    return found


def printed_old():
    """Lines holding a header frame. The frame's top and bottom borders are
    solid rows over 850 px of ink (text never passes 650); the frame's line
    is the one holding the centre between them."""
    found = {}
    with zipfile.ZipFile(ROOT / '.cache' / 'images_1024.zip') as z:
        for page in range(3, 605):
            a = np.asarray(Image.open(io.BytesIO(z.read(f'width_1024/page{page:03d}.png'))).convert('RGBA'))[:, :, 3] > 60
            dense = np.flatnonzero(a.sum(axis=1) > 850)
            groups = []
            for y in dense:
                if groups and y - groups[-1][-1] < 140:
                    groups[-1].append(y)
                else:
                    groups.append([y])
            for g in groups:
                centre = (g[0] + g[-1]) / 2
                found.setdefault(page, set()).add(max(0, min(14, int((centre - 8) / (1594 / 15)))))
    return found


def compare(name, exp, got):
    bad = sorted(p for p in set(exp) | set(got) if exp.get(p, set()) != got.get(p, set()))
    if not bad:
        print(f'OK    {name}: {sum(len(v) for v in got.values())} printed headers, all covered')
        return True
    print(f'FAIL  {name}: {len(bad)} pages differ')
    for p in bad[:15]:
        print(f'        page {p}: printed on lines {sorted(got.get(p, []))}, app draws {sorted(exp.get(p, []))}')
    return False


if __name__ == '__main__':
    exp = expected('madina1441')
    tawba = {p for (p,) in DB.execute('SELECT page FROM ayah WHERE surah = 9 AND number = 1')}
    # the new edition check sees the basmala line too (none for at-Tawba)
    with_basmala = {}
    for p, lines in exp.items():
        for j in lines:
            with_basmala.setdefault(p, set()).add(j)
            if not (p in tawba and j == 0) and j + 1 <= 14:
                with_basmala.setdefault(p, set()).add(j + 1)
    ok = compare('new edition (header and basmala lines)', with_basmala, printed_new())
    ok = compare('old edition', expected('madina1405'), printed_old()) and ok
    sys.exit(0 if ok else 1)
