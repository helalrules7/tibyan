"""Builds the eight heritage themes (Seljuk, Umayyad, Timurid, Hijazi,
Fatimid, Andalusi, Mamluk, Abbasid) from a checkout of quran-assets
(https://github.com/quran-ws/quran-assets; licences are tracked in
docs/DATA_SOURCES.md).

What it makes, flat under assets/themes/:
  <id>_frame_corner.svg, <id>_frame_edge_h.svg, <id>_frame_edge_v.svg
                    the page frame's slices, copied unchanged (the corner is
                    the top-left one; the app mirrors it and repeats the
                    edges), or <id>_frame.svg for a frame with no slices
  <id>_header.svg   the surah header, unchanged (its name box is data-slot)
  <id>_marker.svg   the verse-end marker, unchanged (number box: data-slot)
  <id>.json         the style: its 17 interface colours per mode and the
                    colour of each class of the art per mode

The art is never redrawn: only the fill of each `class="cN"` group and the
stroke of the `class="line"` group are changed, in the app, per mode. The
light mode keeps the approved design's colours; bright white puts the same
art on pure white; night and black move every class colour to the dark
paper by turning its lightness over (pale fills become deep, dark rules
become light) at the same hue. Mamluk and Abbasid were designed dark:
their night (Mamluk) and black (Abbasid) colours are the design's, and
their light colours are chosen from the same hues by hand.

Every interface colour is checked against the contrast rules of
test/theme/theme_contrast_test.dart before a file is written.

Usage: python3 tools/build_themes.py <path to quran-assets>
"""
import colorsys
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

APP = Path(__file__).resolve().parent.parent
OUT = APP / 'assets' / 'themes'

# id, Arabic and English names and descriptions, frame / header / marker
# styles in quran-assets, frame band (px, the edge's depth on screen).
THEMES = [
    dict(
        id='seljuk',
        name=('سلجوقي', 'Seljuk'),
        description=(
            'إطار بني وفيروزي كزخارف السلاجقة، من مصحف الدوري',
            'A brown and turquoise frame in the Seljuk manner, from the Douri mushaf',
        ),
        frame='mushaf-douri', header='mushaf-douri',
        marker='font-010-regular-bold', band=20,
    ),
    dict(
        id='umayyad',
        name=('أموي', 'Umayyad'),
        description=(
            'زيتوني ورملي هادئ كفسيفساء الأمويين',
            'Calm olive and sand, like Umayyad mosaics',
        ),
        frame='mushaf-hafs-adi', header='mushaf-hafs-adi',
        marker='font-013-regular', band=20,
    ),
    dict(
        id='timurid',
        name=('تيموري', 'Timurid'),
        description=(
            'فيروزي ورملي كقباب سمرقند، من مصحف المدينة الكبير',
            'Turquoise and sand like the domes of Samarkand, from the large Madina mushaf',
        ),
        frame='mushaf-hafs-madinah-kabir', header='mushaf-hafs-madinah-kabir',
        marker='mushaf-hafs-madinah-kabir', band=24,
    ),
    dict(
        id='hijazi',
        name=('حجازي', 'Hijazi'),
        description=(
            'أخف الزخارف: إطار رفيع بلون الحجر على أبيض صافٍ',
            'The lightest ornament: a thin stone-coloured frame on pure white',
        ),
        frame='mushaf-warsh', header='mushaf-warsh',
        marker='font-012-light', band=16,
    ),
    dict(
        id='fatimid',
        name=('فاطمي', 'Fatimid'),
        description=(
            'زمردي وذهبي رملي كزخارف القاهرة الفاطمية',
            'Emerald and sandy gold, like Fatimid Cairo',
        ),
        frame='mushaf-sousi', header='mushaf-sousi',
        marker='font-007-regular', band=20,
    ),
    dict(
        id='andalusi',
        name=('أندلسي', 'Andalusi'),
        description=(
            'كحلي وخوخي كزليج الأندلس، من مصحفي السوسي وقالون',
            'Navy and peach like Andalusian tiles, from the Sousi and Qalun mushafs',
        ),
        frame='mushaf-sousi', header='mushaf-qalon',
        marker='mushaf-qalon', band=20,
    ),
    dict(
        id='mamluk',
        name=('مملوكي', 'Mamluk'),
        description=(
            'عنابي وذهبي على أرضية داكنة دافئة، صُمم للوضع الليلي',
            'Maroon and gold on a warm dark ground, designed for night reading',
        ),
        frame='mushaf-shubah', header='mushaf-shubah',
        marker='font-009-medium', band=20,
    ),
    dict(
        id='abbasid',
        name=('عباسي', 'Abbasid'),
        description=(
            'ذهبي على أسود كمصاحف بغداد المذهبة، صُمم للوضع الأسود',
            'Gold on black like the gilded mushafs of Baghdad, designed for the black mode',
        ),
        frame='mushaf-hafs-madinah-kabir', header='mushaf-hafs-madinah-kabir',
        marker='font-010-regular-bold', band=24,
    ),
]

# ── Colours ──────────────────────────────────────────────────────────────

def rgb(h):
    h = h.lstrip('#')
    if len(h) == 3:
        h = ''.join(c * 2 for c in h)
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def hexc(c):
    return '#' + ''.join(f'{round(max(0, min(1, v)) * 255):02X}' for v in c)


def lum(h):
    def ch(c):
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = rgb(h)
    return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b)


def contrast(a, b):
    la, lb = lum(a), lum(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


def hls(h):
    return colorsys.rgb_to_hls(*rgb(h))


def from_hls(h, l, s):
    return hexc(colorsys.hls_to_rgb(h, l, s))


def to_dark(colour, paper, ink_l, line=False):
    """A light design's colour for a dark paper: the lightness turned over
    between the paper (a little above it) and [ink_l], the hue kept and the
    saturation eased. Near-white fills become the lifted paper."""
    h, l, s = hls(colour)
    ph, pl, ps = hls(paper)
    if line:
        if s < 0.12:
            return from_hls(ph, ink_l, max(ps, 0.18))
        return from_hls(h, ink_l, min(s, 0.35) * 0.6)
    base = pl + 0.05
    nl = base + (1 - l) ** 1.15 * (ink_l - base)
    if s < 0.12 or l > 0.97:
        # Whites and greys take the paper's own tint.
        return from_hls(ph, nl, max(ps, s * 0.5))
    return from_hls(h, nl, s * 0.72)


def palette(qa, kind, style):
    """Class -> colour as drawn in quran-assets."""
    a = CATALOG[f'{kind}/{style}']
    return {p['name']: p['hex'] for p in a['palette'] if p['name'] != 'slot'}


# The approved light designs (mock/themes.json), keyed by theme: frame,
# header and marker class colours; classes left out keep the drawn colour.
LIGHT = {
    'seljuk': dict(
        paper='#FFFCF6', ink='#2B1E18',
        frame={}, header={},
        marker={'c1': '#FFFCF6', 'c2': '#D9EEF7', 'c3': '#1DACEC', 'c4': '#5D3325'},
    ),
    'umayyad': dict(
        paper='#FDFBF3', ink='#26291C',
        frame={'c2': '#DCE3C6', 'c3': '#EADBB8', 'c4': '#C9A76A', 'c5': '#7C8B4A',
               'c6': '#A8844A', 'c7': '#4F5E2C', 'line': '#3A3A2C'},
        header={'c2': '#DCE3C6', 'c3': '#EADBB8', 'c4': '#C9A76A', 'c5': '#7C8B4A',
                'c6': '#4F5E2C', 'line': '#3A3A2C'},
        marker={'c1': '#FDFBF3', 'c2': '#EADBB8', 'c3': '#4F5E2C', 'c4': '#7C8B4A',
                'c5': '#C9A76A'},
    ),
    'timurid': dict(
        paper='#FCFBF7', ink='#16303A',
        frame={'c2': '#C9B79C', 'c3': '#2E8A95', 'c4': '#2E8A95', 'line': '#1F4E5A'},
        header={'c2': '#C9B79C', 'c3': '#2E8A95', 'c4': '#2E8A95', 'c5': '#2E8A95',
                'line': '#1F4E5A'},
        marker={'c2': '#C9B79C', 'c3': '#2E8A95', 'c4': '#A08868', 'c5': '#6B5640',
                'line': '#1F4E5A'},
    ),
    'hijazi': dict(
        paper='#FFFFFF', ink='#26292C',
        frame={'c2': '#E4E1DB', 'c3': '#D8C8B4', 'c4': '#B9C4C0', 'line': '#8C847C'},
        header={'c2': '#EEEAE3', 'c3': '#D8C8B4', 'c4': '#D8C8B4', 'c5': '#C9C9C6',
                'c6': '#9FB0AC', 'line': '#8C847C'},
        marker={'c1': '#FFFFFF', 'c2': '#F1ECE3', 'c3': '#6F6A64', 'c4': '#8C847C',
                'c5': '#D8C8B4'},
    ),
    'fatimid': dict(
        paper='#FEFCF5', ink='#15261F',
        frame={'c2': '#E6CF9A', 'c3': '#C3CCC4', 'c4': '#0E5847', 'line': '#23302A'},
        header={'c2': '#E6CF9A', 'c3': '#C3CCC4', 'c4': '#0E5847', 'line': '#23302A'},
        marker={'c1': '#FEFCF5', 'c2': '#0E5847', 'c3': '#B08D4E'},
    ),
    'andalusi': dict(
        paper='#FFFDFA', ink='#18202B',
        frame={},
        header={'c2': '#D3D7DE', 'c3': '#F6CDBE', 'c4': '#AAB5C3', 'c5': '#EFA78F',
                'c6': '#003B6D', 'line': '#30313E'},
        marker={'c2': '#F3B8A3', 'c3': '#003B6D', 'line': '#30313E'},
    ),
    # Designed dark: these light colours are chosen by hand from the
    # design's own hues (maroon, gold, rose grey).
    'mamluk': dict(
        paper='#FFFBF5', ink='#2A1B18',
        frame={'c1': '#FFFBF5', 'c2': '#EBCB9A', 'c3': '#D8C4C0', 'c4': '#C79A5E',
               'c5': '#8A2E27', 'c6': '#5E1E1A', 'line': '#3A2A2A'},
        header={'c1': '#FFFBF5', 'c2': '#EBCB9A', 'c3': '#D8C4C0', 'c4': '#C79A5E',
                'c5': '#B7A3A0', 'c6': '#8A2E27', 'c7': '#5E1E1A', 'line': '#3A2A2A'},
        marker={'c1': '#FFFBF5', 'c2': '#F1E0C8', 'c3': '#8A2E27'},
    ),
    # Gold and bronze on cream.
    'abbasid': dict(
        paper='#FFFCF4', ink='#2A2418',
        frame={'c1': '#FFFCF4', 'c2': '#E3D3B0', 'c3': '#A8843F', 'c4': '#A8843F',
               'line': '#4A3B22'},
        header={'c1': '#FFFCF4', 'c2': '#E3D3B0', 'c3': '#A8843F', 'c4': '#A8843F',
                'c5': '#A8843F', 'line': '#4A3B22'},
        marker={'c1': '#FFFCF4', 'c2': '#F1E6C8', 'c3': '#A8843F', 'c4': '#4A3B22'},
    ),
}

# The designs made for a dark mode, as approved (mock/themes.json x_dusk
# for Mamluk at night, x_gold for Abbasid in black).
DESIGNED_DARK = {
    ('mamluk', 'night'): dict(
        frame={'c1': '#2A1A1C', 'c2': '#C79A5E', 'c3': '#5C4648', 'c4': '#B7844A',
               'c5': '#8A2E27', 'c6': '#5E1E1A', 'line': '#D9C4A6'},
        header={'c1': '#2A1A1C', 'c2': '#C79A5E', 'c3': '#5C4648', 'c4': '#B7844A',
                'c5': '#6E5A58', 'c6': '#8A2E27', 'c7': '#5E1E1A', 'line': '#D9C4A6'},
        marker={'c1': '#1B1113', 'c2': '#3A2528', 'c3': '#C79A5E'},
    ),
    ('mamluk', 'black'): dict(
        frame={'c1': '#150D0E', 'c2': '#AE8650', 'c3': '#48363A', 'c4': '#9E7240',
               'c5': '#7A2822', 'c6': '#521A17', 'line': '#C4AF92'},
        header={'c1': '#150D0E', 'c2': '#AE8650', 'c3': '#48363A', 'c4': '#9E7240',
                'c5': '#5C4B49', 'c6': '#7A2822', 'c7': '#521A17', 'line': '#C4AF92'},
        marker={'c1': '#0B0607', 'c2': '#2C1C1F', 'c3': '#B08548'},
    ),
    ('abbasid', 'black'): dict(
        frame={'c1': '#121212', 'c2': '#6E5B43', 'c3': '#B8955A', 'c4': '#B8955A',
               'line': '#D8C79E'},
        header={'c1': '#121212', 'c2': '#6E5B43', 'c3': '#B8955A', 'c4': '#B8955A',
                'c5': '#B8955A', 'line': '#D8C79E'},
        marker={'c1': '#0A0A0A', 'c2': '#2A241B', 'c3': '#B8955A', 'c4': '#D8C79E'},
    ),
    ('abbasid', 'night'): dict(
        frame={'c1': '#231F19', 'c2': '#76634A', 'c3': '#C2A064', 'c4': '#C2A064',
               'line': '#DDCFAA'},
        header={'c1': '#231F19', 'c2': '#76634A', 'c3': '#C2A064', 'c4': '#C2A064',
                'c5': '#C2A064', 'line': '#DDCFAA'},
        marker={'c1': '#1A1712', 'c2': '#322B20', 'c3': '#C2A064', 'c4': '#DDCFAA'},
    ),
}

# Interface colours: screen, paper and ink per mode, the strong accent
# (buttons, header band), the marker colour and the light accent used on
# dark modes.
UI = {
    'seljuk': dict(
        light=dict(bg='#F4EFE8', accent='#6E3C29', marker='#1A7FAE', gold='#5D3325'),
        night=dict(bg='#15100D', paper='#1C1612', ink='#ECE3D6', accent='#7FCBEB',
                   marker='#3C9DCB', head='#3A2419'),
        black=dict(paper='#0A0806', ink='#E6DDD0', accent='#6FBFE3',
                   marker='#2F8DBA', head='#2A1A12'),
    ),
    'umayyad': dict(
        light=dict(bg='#F2F1E6', accent='#4F5E2C', marker='#6E7C3F', gold='#4F5E2C'),
        night=dict(bg='#12140C', paper='#1A1D12', ink='#E8E6D6', accent='#B5C58A',
                   marker='#8E9E5A', head='#2F3820'),
        black=dict(paper='#0A0B07', ink='#E2E0D0', accent='#A9B97F',
                   marker='#7F8F4E', head='#232A17'),
    ),
    'timurid': dict(
        light=dict(bg='#EEF3F2', accent='#1F6E78', marker='#2E8A95', gold='#1F5E67'),
        night=dict(bg='#0B1618', paper='#102022', ink='#E3ECEA', accent='#7FCFD6',
                   marker='#3FA3AD', head='#173A40'),
        black=dict(paper='#050C0D', ink='#DDE7E5', accent='#72C2C9',
                   marker='#2F8F98', head='#10292D'),
    ),
    'hijazi': dict(
        light=dict(bg='#F6F5F2', accent='#5E5A55', marker='#8C847C', gold='#5E5A55'),
        night=dict(bg='#121314', paper='#1A1B1D', ink='#E6E4E0', accent='#C9C2B8',
                   marker='#9C948B', head='#34322F'),
        black=dict(paper='#0A0A0B', ink='#E0DED9', accent='#BEB7AD',
                   marker='#8A837B', head='#262523'),
    ),
    'fatimid': dict(
        light=dict(bg='#EEF2EE', accent='#0E5847', marker='#1B7A63', gold='#0E5847'),
        night=dict(bg='#0A1411', paper='#101E1A', ink='#E6EEE9', accent='#7FD1B8',
                   marker='#3FA588', head='#123F34'),
        black=dict(paper='#050B09', ink='#E0E9E4', accent='#72C4AB',
                   marker='#2F9578', head='#0C2E26'),
    ),
    'andalusi': dict(
        light=dict(bg='#F1F0F2', accent='#003B6D', marker='#3A6EA5', gold='#003B6D'),
        night=dict(bg='#0A1220', paper='#101B29', ink='#E9E1CC', accent='#F3B8A3',
                   marker='#C98E7A', head='#1A2A3F'),
        black=dict(paper='#05080C', ink='#E2DAC5', accent='#E8AE99',
                   marker='#B98F7E', head='#0C141E'),
    ),
    'mamluk': dict(
        light=dict(bg='#F5ECE4', accent='#8A2E27', marker='#9E6B33', gold='#7A2620'),
        night=dict(bg='#120B0C', paper='#1B1113', ink='#EEE3D2', accent='#D9B27A',
                   marker='#C79A5E', head='#3A2528'),
        black=dict(paper='#0B0607', ink='#E8DCCB', accent='#CDA56C',
                   marker='#B08548', head='#2A1A1C'),
    ),
    'abbasid': dict(
        light=dict(bg='#F3EEE3', accent='#6B5227', marker='#9C7A3E', gold='#6E5426'),
        night=dict(bg='#12100C', paper='#1A1712', ink='#EAE1CC', accent='#D8C79E',
                   marker='#B8955A', head='#2E271D'),
        black=dict(paper='#0A0A0A', ink='#E8DFCA', accent='#D8C79E',
                   marker='#B8955A', head='#1E1A14'),
    ),
}


def mix(a, b, t):
    ca, cb = rgb(a), rgb(b)
    return hexc(tuple(x + (y - x) * t for x, y in zip(ca, cb)))


def ensure(fg, bg, minimum, towards):
    """[fg] moved towards [towards] until it meets [minimum] against [bg]."""
    c = fg
    t = 0.0
    while contrast(c, bg) < minimum and t < 1:
        t += 0.02
        c = mix(fg, towards, t)
    return c


def tokens(tid, mode, paper, ink):
    u = UI[tid]
    if mode in ('light', 'white'):
        l = u['light']
        bg = '#FFFFFF' if mode == 'white' else l['bg']
        a = ensure(l['accent'], paper, 4.5, '#000000')
        a = ensure(a, bg, 4.5, '#000000')
        marker = ensure(l['marker'], paper, 3.2, '#000000')
        gold = ensure(l['gold'], paper, 4.8, '#000000')
        muted = ensure(mix(ink, paper, 0.42), paper, 4.8, ink)
        muted = ensure(muted, bg, 4.8, ink)
        return {
            'bg': bg, 'paper': paper, 'ink': ink,
            'frame': a, 'goldText': gold,
            'border': mix(l['bg'] if mode == 'light' else '#F0EEEA', ink, 0.12),
            'headBg': a, 'headFg': '#FFFFFF', 'marker': marker,
            'player': a, 'playerFg': '#FFFFFF',
            'accent': '#FFFFFF', 'accentFg': a,
            'muted': muted,
            'highlight': marker + '33',
            'control': a, 'onControl': '#FFFFFF',
        }
    d = u[mode]
    bg = d.get('bg', '#000000')
    accent = ensure(d['accent'], paper, 4.8, '#FFFFFF')
    marker = ensure(d['marker'], paper, 3.2, '#FFFFFF')
    muted = ensure(mix(ink, paper, 0.36), paper, 4.8, ink)
    muted = ensure(muted, bg, 4.8, ink)
    head = d['head']
    return {
        'bg': bg, 'paper': paper, 'ink': ink,
        'frame': head, 'goldText': accent,
        'border': mix(paper, ink, 0.14),
        'headBg': head, 'headFg': ink, 'marker': marker,
        'player': head, 'playerFg': ink,
        'accent': ink, 'accentFg': paper,
        'muted': muted,
        'highlight': marker + '40',
        'control': accent, 'onControl': bg if contrast(bg, accent) >= 4.5 else '#000000',
    }


RULES = [
    ('ink', 'paper', 7), ('ink', 'bg', 7), ('muted', 'paper', 4.5),
    ('muted', 'bg', 4.5), ('goldText', 'paper', 4.5), ('headFg', 'headBg', 4.5),
    ('playerFg', 'player', 4.5), ('accentFg', 'accent', 4.5),
    ('marker', 'paper', 3), ('control', 'paper', 3), ('control', 'bg', 3),
    ('onControl', 'control', 4.5),
]


def check(tid, mode, t):
    for fg, bg, m in RULES:
        r = contrast(t[fg][:7], t[bg][:7])
        if r < m:
            raise SystemExit(f'{tid}/{mode}: {fg} on {bg} = {r:.2f} < {m}')


# ── Art colours per mode ─────────────────────────────────────────────────

def art_modes(t, qa):
    tid = t['id']
    light = LIGHT[tid]
    kinds = {'frame': ('page-frames', t['frame']),
             'header': ('surah-headers', t['header']),
             'marker': ('ayah-markers', t['marker'])}
    drawn = {k: palette(qa, *v) for k, v in kinds.items()}
    ui = UI[tid]
    papers = {
        'light': light['paper'], 'white': '#FFFFFF',
        'night': ui['night']['paper'], 'black': ui['black']['paper'],
    }
    inks = {
        'light': light['ink'], 'white': light['ink'],
        'night': ui['night']['ink'], 'black': ui['black']['ink'],
    }
    out = {}
    for mode in ('light', 'white', 'night', 'black'):
        maps = {}
        for k in kinds:
            eff = {**drawn[k], **light[k]}      # the light design's colours
            if mode == 'light':
                m = dict(light[k])
                if k == 'marker':
                    m['c1'] = m.get('c1', light['paper'])
            elif mode == 'white':
                m = dict(light[k])
                # The paper-coloured parts follow the white paper.
                for c, v in eff.items():
                    if c == 'c1' or v.upper() == light['paper'].upper():
                        m[c] = '#FFFFFF'
            elif (tid, mode) in DESIGNED_DARK:
                m = dict(DESIGNED_DARK[(tid, mode)][k])
            else:
                paper = papers[mode]
                ink_l = 0.80 if mode == 'night' else 0.72
                m = {}
                for c, v in eff.items():
                    if c == 'c1' or v.upper() == light['paper'].upper():
                        m[c] = paper if k == 'marker' else to_dark('#FFFFFF', paper, ink_l)
                    else:
                        m[c] = to_dark(v, paper, ink_l, line=c == 'line')
            maps[k] = {c: m[c].upper() for c in sorted(m)}
        out[mode] = maps
    return out, papers, inks


# ── Files ────────────────────────────────────────────────────────────────

def copy(src, dst):
    shutil.copyfile(src, dst)
    return dst.name


def build(qa):
    head = subprocess.run(['git', '-C', str(qa), 'rev-parse', 'HEAD'],
                          capture_output=True, text=True, check=True).stdout.strip()
    index = json.loads((OUT / 'index.json').read_text())
    for t in THEMES:
        tid = t['id']
        fa = CATALOG[f'page-frames/{t["frame"]}']
        frame_dir = qa / 'assets' / 'page-frames' / t['frame']
        if fa.get('slices'):
            s = fa['slices']['files']
            frame = {
                'corner': copy(qa / s['corner'], OUT / f'{tid}_frame_corner.svg'),
                'edgeH': copy(qa / s['edge-h'], OUT / f'{tid}_frame_edge_h.svg'),
                'edgeV': copy(qa / s['edge-v'], OUT / f'{tid}_frame_edge_v.svg'),
            }
        else:
            frame = {'whole': copy(frame_dir / 'color.svg', OUT / f'{tid}_frame.svg')}
        header = copy(qa / 'assets' / 'surah-headers' / t['header'] / 'color.svg',
                      OUT / f'{tid}_header.svg')
        marker = copy(qa / 'assets' / 'ayah-markers' / t['marker'] / 'color.svg',
                      OUT / f'{tid}_marker.svg')
        colours, papers, inks = art_modes(t, qa)
        modes = {}
        for mode in ('light', 'white', 'night', 'black'):
            tok = tokens(tid, mode, papers[mode], inks[mode])
            check(tid, mode, tok)
            modes[mode] = tok
        licence = lambda kind, style: CATALOG[f'{kind}/{style}']['license']['id']
        style = {
            'id': tid,
            'version': 1,
            'name': {'ar': t['name'][0], 'en': t['name'][1]},
            'description': {'ar': t['description'][0], 'en': t['description'][1]},
            'fonts': {'surahHeader': 'KFGQPCAN'},
            'frame': {
                'outerWidth': t['band'], 'outerStyle': 'art', 'innerWidth': 0,
                'gap': 0, 'radius': 0, 'innerRadius': 0, 'corner': 'art',
            },
            'ornaments': {'surahHeader': 'art', 'ayahMarker': 'theme', 'density': 'rich'},
            'radii': {'card': 14, 'sheet': 24, 'chip': 18, 'surahHeader': 0},
            'art': {
                'source': {
                    'repo': 'https://github.com/quran-ws/quran-assets',
                    'commit': head,
                    'frame': {'id': f'page-frames/{t["frame"]}',
                              'license': licence('page-frames', t['frame'])},
                    'header': {'id': f'surah-headers/{t["header"]}',
                               'license': licence('surah-headers', t['header'])},
                    'marker': {'id': f'ayah-markers/{t["marker"]}',
                               'license': licence('ayah-markers', t['marker'])},
                },
                'frame': {**frame, 'band': t['band']},
                'header': header,
                'marker': marker,
                'modes': colours,
            },
            'modes': modes,
        }
        (OUT / f'{tid}.json').write_text(json.dumps(style, ensure_ascii=False, indent=2) + '\n')
        if tid not in index['styles']:
            index['styles'].append(tid)
    (OUT / 'index.json').write_text(json.dumps(index, ensure_ascii=False, indent=2) + '\n')
    print('ok', [t['id'] for t in THEMES], head)


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    QA = Path(sys.argv[1]).resolve()
    CATALOG = {a['id']: a for a in json.loads((QA / 'catalog.json').read_text())['assets']}
    build(QA)
