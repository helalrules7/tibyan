"""Recolours the original opening-page frame (run from the repo root) for
themes the owner's folder has none for:
blues -> the theme's main colour, golds/olives/greens -> its second,
reds/oranges -> its accent; cream and white untouched."""
import sys
import numpy as np
from PIL import Image

DIR = 'docs/design/fateha-themes'
SRC = f'{DIR}/01-fateha-baqara.webp'

def to_hsv(rgb):
    r, g, b = [rgb[..., i] / 255.0 for i in range(3)]
    mx = np.max(rgb, -1) / 255.0; mn = np.min(rgb, -1) / 255.0; d = mx - mn
    h = np.zeros_like(mx)
    m = d > 1e-6
    rc = np.where(m, (mx - r) / np.where(m, d, 1), 0)
    gc = np.where(m, (mx - g) / np.where(m, d, 1), 0)
    bc = np.where(m, (mx - b) / np.where(m, d, 1), 0)
    h = np.where(r == mx, bc - gc, np.where(g == mx, 2.0 + rc - bc, 4.0 + gc - rc))
    h = (h / 6.0) % 1.0
    s = np.where(mx > 0, d / np.where(mx > 0, mx, 1), 0)
    return h * 360, s, mx

def to_rgb(h, s, v):
    h = (h % 360) / 60.0
    i = np.floor(h).astype(int) % 6; f = h - np.floor(h)
    p = v * (1 - s); q = v * (1 - s * f); t = v * (1 - s * (1 - f))
    out = np.zeros(h.shape + (3,))
    for k, (a, b, c) in enumerate([(v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q)]):
        sel = i == k
        out[sel, 0] = a[sel]; out[sel, 1] = b[sel]; out[sel, 2] = c[sel]
    return (out * 255).clip(0, 255).astype(np.uint8)

# theme: (blue -> (hue, sat x, val x)), (gold/green -> ...), (red/orange -> ...)
THEMES = {
    # Tibyan (the old Zakhrafa): navy, teal, coral
    'tibyan':  ((212, 0.85, 0.80), (174, 0.95, 0.85), (18, 1.0, 1.0)),
    # Timurid: calm teal with sand
    'timurid': ((188, 0.80, 0.95), (36, 0.45, 1.05), (188, 0.6, 0.9)),
    # Abbasid: black with gold
    'abbasid': ((220, 0.25, 0.28), (40, 0.80, 1.00), (40, 0.7, 0.9)),
}

def recolour(name):
    blue, gold, red = THEMES[name]
    im = Image.open(SRC).convert('RGBA'); a = np.array(im)
    h, s, v = to_hsv(a[..., :3].astype(float))
    col = s > 0.18                     # leave cream, white and greys alone
    isblue = col & (h >= 185) & (h < 275)
    isgold = col & (((h >= 38) & (h < 185)))
    isred = col & ((h < 38) | (h >= 275))
    H, S, V = h.copy(), s.copy(), v.copy()
    for m, (hh, sx, vx) in ((isblue, blue), (isgold, gold), (isred, red)):
        H[m] = hh; S[m] = (s[m] * sx).clip(0, 1); V[m] = (v[m] * vx).clip(0, 1)
    rgb = to_rgb(H, S, V)
    out = np.dstack([rgb, a[..., 3]])
    Image.fromarray(out, 'RGBA').save(f'{DIR}/frame_{name}.png')

if __name__ == '__main__':
    for n in sys.argv[1:] or THEMES:
        recolour(n)
    print('ok')
