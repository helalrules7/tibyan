"""Builds the page-frame specs of the six frame designs (Abbasid, Umayyad,
Andalusian, Ottoman, Egyptian, Modern Islamic) from Ahmed's vector
designs in tools/ornaments/src/themes/.

Each design is five SVG files, all procedural (rects, polygons, lines,
circles, quadratic and cubic paths):
  <set>_01_page_frame.svg      rules, band rhythm, corners, medallion
  <set>_02_surah_divider.svg   surah banner: cartouche, rosettes, scrolls
  <set>_03_splash.svg          cover composition around a radial motif
  <set>_04_opening_fatihah_baqarah.svg   the two opening pages
  <set>_05_detail_studies.svg  reference sheet (signature ornament)

The app redraws them with a CustomPainter at any size, so this script
keeps geometry, not pictures: every shape in design units, relative to
the point it hangs from (a corner, a centre, a cartouche tip), and every
colour as a role of the design's palette (bg, ink, gold, accent), which
the app adapts to night and black modes.

The SVGs are line art. The look Ahmed aims for (his reference sheet,
docs/design/2026-09-30_frame_designs_reference.png) is richer: a filled
band with a repeating tile, square corner pieces, arched opening pages.
LOOK below adds what the SVGs do not carry: the band colour, the tile and
corner kinds, the arch shape and the extra motif colours, read off that
sheet. The app draws the tiles and arches in code.

The horizontal lines, the circles beside them and the "QURAN PAGE",
"AL-FATIHAH" and «سورة» labels are layout placeholders for the mushaf
text: they are left out.

Output: assets/config/frame_<set>.json (assets/config/ is already an
asset folder; sub-folders are not, so the files sit at its top level).

Usage: python3 tools/build_frame_designs.py
"""
import json
import math
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SRC = ROOT / 'ornaments' / 'src' / 'themes'
OUT = ROOT.parent / 'assets' / 'config'
SETS = ['abbasid', 'umayyad', 'andalusian', 'ottoman', 'egyptian',
        'modern_islamic']
NS = '{http://www.w3.org/2000/svg}'

# The richer look per set (from the reference sheet): band ground, tile
# along the band, corner rosette, arch over the opening pages, and the
# tile's two colours (m1, m2) besides the SVG palette's gold.
LOOK = {
    'abbasid': dict(band='#173F3A', tile='star8', rosette='star8',
                    arch='pointed', m1='#0F2B28', m2='#C9A24E'),
    'umayyad': dict(band='#DDD3B2', tile='lozenge', rosette='quatrefoil',
                    arch='round', m1='#5F6E47', m2='#9C7A3A'),
    'andalusian': dict(band='#1E4E8A', tile='zellige', rosette='star8',
                       arch='horseshoe', m1='#2E8C8A', m2='#C0573F'),
    'ottoman': dict(band='#FBF6EA', tile='tulip', rosette='flower',
                    arch='ogee', m1='#B54A3A', m2='#244F97'),
    'egyptian': dict(band='#15344B', tile='mosaic', rosette='star8',
                     arch='pointed', m1='#2F6D9E', m2='#E9D7A2', lamp=True),
    'modern_islamic': dict(band='#E7F0EF', tile='lines', rosette='quatrefoil',
                           arch='pointed', m1='#245B67', m2='#8BA8A7'),
}


def r2(v):
    return round(v, 2) + 0.0


# ── SVG parsing ────────────────────────────────────────────────────────

def parse_path(d):
    """Absolute M/L/Q/C/Z commands from an SVG path string."""
    tokens = re.findall(r'[MLQCZmlqcz]|-?[\d.]+(?:e-?\d+)?', d)
    out, i, cmd = [], 0, None
    x = y = sx = sy = 0.0
    arity = {'M': 2, 'L': 2, 'Q': 4, 'C': 6, 'Z': 0}
    while i < len(tokens):
        t = tokens[i]
        if t.isalpha():
            cmd = t
            i += 1
            if cmd in 'Zz':
                out.append(['Z'])
                x, y = sx, sy
                continue
        n = arity[cmd.upper()]
        vals = [float(v) for v in tokens[i:i + n]]
        i += n
        if cmd.islower():
            vals = [v + (x if k % 2 == 0 else y) for k, v in enumerate(vals)]
        c = cmd.upper()
        out.append([c] + vals)
        x, y = vals[-2], vals[-1]
        if c == 'M':
            sx, sy = x, y
            cmd = 'l' if cmd == 'm' else 'L'  # implicit lineto after moveto
    return out


def shape_of(el):
    """One drawable primitive, absolute coordinates, raw colours."""
    tag = el.tag.replace(NS, '')
    a = el.attrib
    f = lambda k, d=0.0: float(a.get(k, d))
    s = {
        'fill': a.get('fill', '#000000' if tag in ('polygon', 'path', 'rect',
                                                    'circle') else 'none'),
        'stroke': a.get('stroke', 'none'),
        'w': f('stroke-width', 1.0),
        'o': f('opacity', 1.0),
    }
    if tag == 'rect':
        s.update(k='rect', x=f('x'), y=f('y'), wd=f('width'), ht=f('height'),
                 rx=f('rx'))
    elif tag == 'polygon':
        nums = [float(v) for v in re.findall(r'-?[\d.]+', a['points'])]
        s.update(k='poly', p=nums)
    elif tag == 'path':
        s.update(k='path', d=parse_path(a['d']))
    elif tag == 'line':
        s.update(k='line', p=[f('x1'), f('y1'), f('x2'), f('y2')])
    elif tag == 'circle':
        s.update(k='circle', c=[f('cx'), f('cy')], r=f('r'))
    else:
        return None
    return s


def load(name):
    root = ET.parse(SRC / name).getroot()
    vb = [float(v) for v in root.attrib['viewBox'].split()]
    shapes = [s for s in (shape_of(e) for e in root.iter()) if s]
    return vb, shapes


def points(s):
    """Every coordinate pair of a shape (for bounds)."""
    k = s['k']
    if k == 'rect':
        return [(s['x'], s['y']), (s['x'] + s['wd'], s['y'] + s['ht'])]
    if k in ('poly', 'line'):
        p = s['p']
        return list(zip(p[0::2], p[1::2]))
    if k == 'circle':
        (cx, cy), r = s['c'], s['r']
        return [(cx - r, cy - r), (cx + r, cy + r)]
    pts = []
    for c in s['d']:
        v = c[1:]
        pts += list(zip(v[0::2], v[1::2]))
    return pts


def bounds(s):
    pts = points(s)
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    return min(xs), min(ys), max(xs), max(ys)


def centre(s):
    x0, y0, x1, y1 = bounds(s)
    return (x0 + x1) / 2, (y0 + y1) / 2


# ── Output form ────────────────────────────────────────────────────────

class Palette:
    def __init__(self, bg, ink, gold, accent):
        self.roles = {'bg': bg, 'ink': ink, 'gold': gold, 'accent': accent}
        self.by_hex = {v.upper(): k for k, v in self.roles.items()}

    def role(self, hex_):
        if hex_ in (None, 'none'):
            return None
        try:
            return self.by_hex[hex_.upper()]
        except KeyError:
            sys.exit(f'colour {hex_} is not in the palette {self.roles}')


def emit(s, pal, ox=0.0, oy=0.0):
    """A shape relative to (ox, oy), colours as palette roles."""
    out = {'k': s['k']}
    k = s['k']
    if k == 'rect':
        out['r'] = [r2(s['x'] - ox), r2(s['y'] - oy), r2(s['wd']), r2(s['ht'])]
        if s['rx']:
            out['rx'] = r2(s['rx'])
    elif k in ('poly', 'line'):
        out['p'] = [r2(v - (ox if i % 2 == 0 else oy))
                    for i, v in enumerate(s['p'])]
    elif k == 'circle':
        out['c'] = [r2(s['c'][0] - ox), r2(s['c'][1] - oy)]
        out['r'] = r2(s['r'])
    else:
        out['d'] = [[c[0]] + [r2(v - (ox if i % 2 == 0 else oy))
                              for i, v in enumerate(c[1:])] for c in s['d']]
    fill, stroke = pal.role(s['fill']), pal.role(s['stroke'])
    if fill:
        out['fill'] = fill
    if stroke:
        out['stroke'] = stroke
        out['w'] = r2(s['w'])
    if s['o'] != 1.0:
        out['o'] = r2(s['o'])
    return out


def extent(shapes, cx, cy):
    """Largest distance of any point from (cx, cy)."""
    return r2(max(math.hypot(x - cx, y - cy)
                  for s in shapes for x, y in points(s)))


# ── The five files ─────────────────────────────────────────────────────

def page_frame(name, pal):
    """Rules, rhythm, corners and medallion of one framed page."""
    _, shapes = load(name)
    rules = [s for s in shapes if s['k'] == 'rect' and s['fill'] == 'none']
    outer = rules[0]
    bx, by, bw, bh = outer['x'], outer['y'], outer['wd'], outer['ht']
    text = next(s for s in shapes if s['k'] == 'rect' and s['fill'] != 'none'
                and s['stroke'] == 'none' and s['x'] > bx)
    spec = {
        'box': [r2(bw), r2(bh)],
        'rules': [dict(inset=r2(s['x'] - bx), **{
            k: v for k, v in emit(s, pal).items() if k in ('stroke', 'w', 'o', 'rx')
        }) for s in rules],
        'text': [r2(text['x'] - bx), r2(text['y'] - by)],
    }

    # The rhythm: small repeated motifs along the band, one kind per pair
    # of edges.
    small = [s for s in shapes if s['k'] == 'poly' and len(s['p']) == 16
             and bounds(s)[2] - bounds(s)[0] < 12]
    groups = {}
    for s in small:
        groups.setdefault((s['fill'], s['o']), []).append(s)
    rhythm = []
    for group in groups.values():
        if len(group) < 8:
            continue  # the stars inside the corner ornaments
        cs = [centre(s) for s in group]
        on_top = [c for c in cs if abs(c[1] - by) < 20]
        horizontal = len(on_top) > len(cs) / 4
        along = sorted({round(c[0] if horizontal else c[1], 2) for c in cs})
        steps = {round(b - a, 2) for a, b in zip(along, along[1:])}
        if len(steps) != 1:
            sys.exit(f'{name}: uneven rhythm {steps}')
        first = group[0]
        fx, fy = centre(first)
        rhythm.append({
            'edges': 'h' if horizontal else 'v',
            'offset': r2(fy - by if horizontal else fx - bx),
            'spacing': steps.pop(),
            'shapes': [emit(first, pal, fx, fy)],
        })
    spec['rhythm'] = sorted(rhythm, key=lambda r: r['edges'])

    # The corner ornament: everything else hanging from the top-left corner.
    corner = [s for s in shapes if s not in small and s not in rules
              and s['k'] in ('path', 'poly')
              and bounds(s)[2] < bx + 40 and bounds(s)[3] < by + 40]
    corner += [s for s in shapes if s['k'] == 'poly' and s in small
               and s not in sum((g for g in groups.values() if len(g) >= 8), [])
               and bounds(s)[2] < bx + 40 and bounds(s)[3] < by + 40]
    spec['corner'] = {
        'shapes': [emit(s, pal, bx, by) for s in corner],
        'extent': r2(max(max(bounds(s)[2] - bx, bounds(s)[3] - by)
                         for s in corner)),
    }

    # The medallion at the bottom centre (under the page number).
    mid = bx + bw / 2
    med = [s for s in shapes if s['k'] in ('path', 'poly', 'circle')
           and s not in small and abs(centre(s)[0] - mid) < 1 and centre(s)[1] > by + bh * 0.8]
    my = centre(max(med, key=lambda s: bounds(s)[2] - bounds(s)[0]))[1]
    spec['medallion'] = {
        'shapes': [emit(s, pal, mid, my) for s in med],
        'r': extent(med, mid, my),
        'bottom': r2(by + bh - my),
    }
    return spec


def hexagon(s):
    """Tip, shoulder and half-height of a pointed cartouche outline."""
    pts = [c[1:] for c in s['d'] if c[0] in 'ML']
    xs = sorted({p[0] for p in pts})
    ys = sorted({p[1] for p in pts})
    return xs[0], xs[1], (ys[-1] - ys[0]) / 2


def divider(name, pal):
    vb, shapes = load(name)
    cx, cy = vb[2] / 2, vb[3] / 2
    shapes = [s for s in shapes if not (s['k'] == 'rect' and s['x'] == 0)]
    hexes = [s for s in shapes if s['k'] == 'path'
             and all(c[0] in 'MLZ' for c in s['d'])]
    outer, inner = sorted(hexes, key=lambda s: hexagon(s)[0])
    tip, shoulder, half = hexagon(outer)
    itip, ishoulder, ihalf = hexagon(inner)

    def side(s):
        return centre(s)[0] < cx

    rest = [s for s in shapes if s not in hexes]
    # The rosettes: the octagon and star hanging off each tip.
    stars = [s for s in rest if s['k'] == 'poly' and len(s['p']) == 32]
    ros_all = [s for s in rest for st in stars
               if all(abs(a - b) < 1 for a, b in zip(centre(s), centre(st)))]
    ros = [s for s in ros_all if side(s)]
    rx, ry = centre(ros[0])
    ends = [s for s in rest if s not in ros_all]
    rtip = vb[2] - tip
    return {
        'cartouche': {
            'outer': dict(half=r2(half), point=r2(shoulder - tip),
                          **{k: v for k, v in emit(outer, pal).items()
                             if k in ('fill', 'stroke', 'w')}),
            'inner': dict(inset=r2(itip - tip), half=r2(ihalf),
                          point=r2(ishoulder - itip),
                          **{k: v for k, v in emit(inner, pal).items()
                             if k in ('fill', 'stroke', 'w')}),
        },
        'rosette': {
            'shapes': [emit(s, pal, rx, ry) for s in ros],
            'r': extent(ros, rx, ry),
            'dx': r2(rx - tip),
        },
        # Scroll and leaf at each end, from that end's tip; the left and
        # right ends are not mirror images in the design, so both are kept.
        'left': [emit(s, pal, tip, cy) for s in ends if side(s)],
        'right': [emit(s, pal, rtip, cy) for s in ends if not side(s)],
        # How far the ends reach out beyond the tips.
        'reach': r2(tip - min(bounds(s)[0] for s in ends)),
    }


def cover(name, pal):
    vb, shapes = load(name)
    w, h = vb[2], vb[3]
    cx, cy = w / 2, h / 2
    rects = [s for s in shapes if s['k'] == 'rect' and s['fill'] == 'none']
    motif = [s for s in shapes if s['k'] != 'rect']
    return {
        'size': [r2(w), r2(h)],
        'rules': sorted([dict(inset=r2(s['x']), **{
            k: v for k, v in emit(s, pal).items() if k in ('stroke', 'w', 'o')
        }) for s in rects], key=lambda r: r['inset']),
        'motif': [emit(s, pal, cx, cy) for s in motif],
        'r': extent(motif, cx, cy),
    }


def opening(name, pal):
    """The title cartouche and its ornament on each of the two pages."""
    vb, shapes = load(name)
    frames = [s for s in shapes if s['k'] == 'rect' and s['fill'] == 'none'
              and s.get('rx') == 2.0]
    titles = sorted([s for s in shapes if s['k'] == 'rect'
                     and s.get('rx') == 10.0], key=lambda s: s['x'])
    boxes = sorted(frames, key=lambda s: s['x'])
    texts = sorted([s for s in shapes if s['k'] == 'rect' and s['fill'] != 'none'
                    and s['x'] > 0], key=lambda s: s['x'])
    out = {}
    for key, box, title, text in zip(('fatiha', 'baqarah'), boxes, titles, texts):
        tx, ty = title['x'] + title['wd'] / 2, title['y'] + title['ht'] / 2
        orn = [s for s in shapes if s['k'] in ('path', 'poly')
               and abs(centre(s)[0] - tx) < 2 and abs(centre(s)[1] - ty) < 20
               and bounds(s)[2] - bounds(s)[0] > 30]
        out[key] = {
            'box': [r2(box['wd']), r2(box['ht'])],
            'title': dict(r=[r2(title['x'] - box['x']), r2(title['y'] - box['y']),
                             r2(title['wd']), r2(title['ht'])],
                          rx=r2(title['rx']),
                          **{k: v for k, v in emit(title, pal).items()
                             if k in ('stroke', 'w')}),
            'text': [r2(text['x'] - box['x']), r2(text['y'] - box['y']),
                     r2(text['wd']), r2(text['ht'])],
            'ornament': {
                'shapes': [emit(s, pal, tx, centre(s)[1]) for s in orn],
                'r': extent(orn, tx, centre(orn[0])[1]),
                'dy': r2(centre(orn[0])[1] - ty),
            },
        }
    return out


def signature(name, pal):
    """The signature ornament: the fourth study (two nested stars)."""
    _, shapes = load(name)
    panels = sorted([s for s in shapes if s['k'] == 'rect' and s['wd'] == 250],
                    key=lambda s: s['x'])
    p = panels[3]
    cx, cy = p['x'] + p['wd'] / 2, p['y'] + p['ht'] / 2
    inside = [s for s in shapes if s['k'] != 'rect'
              and p['x'] < centre(s)[0] < p['x'] + p['wd']
              and p['y'] < centre(s)[1] < p['y'] + p['ht']]
    return {'shapes': [emit(s, pal, cx, cy) for s in inside],
            'r': extent(inside, cx, cy)}


def palette(name):
    _, shapes = load(name)
    bg = next(s for s in shapes if s['k'] == 'rect' and s['x'] == 0)['fill']
    rules = [s for s in shapes if s['k'] == 'rect' and s['fill'] == 'none']
    accent = next(s['fill'] for s in shapes if s['k'] == 'poly'
                  and s['o'] == 0.7)
    return Palette(bg, rules[0]['stroke'], rules[1]['stroke'], accent)


def luminance(hex_):
    r, g, b = (int(hex_[i:i + 2], 16) / 255 for i in (1, 3, 5))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def build(name):
    pal = palette(f'{name}_01_page_frame.svg')
    return {
        'id': name,
        'palette': pal.roles,
        'dark': luminance(pal.roles['bg']) < 0.5,
        'page': page_frame(f'{name}_01_page_frame.svg', pal),
        'divider': divider(f'{name}_02_surah_divider.svg', pal),
        'cover': cover(f'{name}_03_splash.svg', pal),
        'opening': opening(f'{name}_04_opening_fatihah_baqarah.svg', pal),
        'signature': signature(f'{name}_05_detail_studies.svg', pal),
        'look': LOOK[name],
    }


def main():
    for name in SETS:
        spec = build(name)
        path = OUT / f'frame_{name}.json'
        path.write_text(json.dumps(spec, ensure_ascii=False,
                                   separators=(',', ':')) + '\n')
        print(f'{path.relative_to(ROOT.parent)}: {path.stat().st_size} bytes')


if __name__ == '__main__':
    main()
