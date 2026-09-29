"""Image helpers for the Shamarly mushaf pages (pure numpy, no OpenCV/SciPy).

The archive.org page images (tools/.cache/shamarly/pages/NNN.png, 886x1377)
are RGBA with a binary alpha: text ink is opaque and black, the background is
transparent, and the surah-header frames and the margin marks are opaque and
coloured. Pages 1-3 are RGB scans of the ornate opening pages instead.

Used by build_shamarly.py and verify_shamarly.py.
"""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent
PAGES = ROOT / '.cache' / 'shamarly' / 'pages'
W, H = 886, 1377
COLOUR = 40        # max - min of R, G, B above this: a coloured pixel


def load(page):
    """(ink, colour): boolean arrays. ink = black text pixels."""
    im = Image.open(PAGES / f'{page:03d}.png')
    rgb = np.asarray(im.convert('RGB')).astype(np.int16)
    colourful = (rgb.max(2) - rgb.min(2)) > COLOUR
    if im.mode == 'RGBA':
        opaque = np.asarray(im.getchannel('A')) > 127
        return opaque & ~colourful, opaque & colourful
    # ornate opening pages: dark, unsaturated pixels are text
    dark = rgb.mean(2) < 110
    return dark & ~colourful, colourful


def runs(mask):
    """Horizontal runs of True: arrays (y, x0, x1) with x1 exclusive."""
    m = np.zeros((mask.shape[0], mask.shape[1] + 2), dtype=np.int8)
    m[:, 1:-1] = mask
    d = np.diff(m, axis=1)
    ys, xs = np.nonzero(d == 1)
    ye, xe = np.nonzero(d == -1)
    # np.nonzero is row-major, so starts and ends pair up in order
    return ys, xs, xe


def label(mask):
    """8-connected components. Returns (labels, boxes, sizes): labels is an
    int32 image (0 = background, k = component k), boxes[k] = (x0, y0, x1, y1)
    exclusive, sizes[k] = pixel count. Index 0 of boxes/sizes is unused."""
    ys, x0s, x1s = runs(mask)
    n = len(ys)
    parent = list(range(n))

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    row_start = np.searchsorted(ys, np.arange(mask.shape[0] + 1))
    ys_l, x0_l, x1_l = ys.tolist(), x0s.tolist(), x1s.tolist()
    for y in range(1, mask.shape[0]):
        a, a_end = row_start[y - 1], row_start[y]
        b, b_end = row_start[y], row_start[y + 1]
        while a < a_end and b < b_end:
            # 8-connectivity: runs touch when they overlap or meet diagonally
            if x0_l[a] <= x1_l[b] and x0_l[b] <= x1_l[a]:
                ra, rb = find(a), find(b)
                if ra != rb:
                    parent[max(ra, rb)] = min(ra, rb)
            if x1_l[a] < x1_l[b]:
                a += 1
            else:
                b += 1
    roots = [find(i) for i in range(n)]
    ids, lab = {}, np.empty(n, dtype=np.int32)
    for i, r in enumerate(roots):
        lab[i] = ids.setdefault(r, len(ids) + 1)
    k = len(ids)
    labels = np.zeros(mask.shape, dtype=np.int32)
    for i in range(n):
        labels[ys_l[i], x0_l[i]:x1_l[i]] = lab[i]
    boxes = np.zeros((k + 1, 4), dtype=np.int32)
    boxes[1:, 0] = W * 10
    boxes[1:, 1] = H * 10
    np.minimum.at(boxes[:, 0], lab, x0s)
    np.minimum.at(boxes[:, 1], lab, ys)
    np.maximum.at(boxes[:, 2], lab, x1s)
    np.maximum.at(boxes[:, 3], lab, ys + 1)
    sizes = np.zeros(k + 1, dtype=np.int64)
    np.add.at(sizes, lab, x1s - x0s)
    return labels, boxes, sizes


def holes(mask):
    """Areas of the background regions of `mask` that do not touch its edge
    (the enclosed counters), largest first."""
    bg, boxes, sizes = label(~np.pad(mask, 1))
    edge = set(np.unique(np.concatenate([bg[0], bg[-1], bg[:, 0], bg[:, -1]])).tolist())
    return sorted((int(sizes[k]) for k in range(1, len(sizes)) if k not in edge), reverse=True)
