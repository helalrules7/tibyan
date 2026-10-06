#!/usr/bin/env python3
"""Builds assets/config/surah_type_1342.json from the transcription of the
surah headers of the 1924 Cairo mushaf (King Fuad, Bulaq 1342H), and checks
it against the app's other data.

The transcription is by hand, from crops of the 600 dpi scan, in two
independent passes (pass1.txt, pass2.txt). This script:

1. compares the two passes field by field;
2. takes pass 1 and applies RESOLVED: the decision on every disagreement,
   made by looking again at the crop (and the few corrections found then);
3. adds the structured fields (STRUCTURE), written by hand from the
   statement, and checks that every number in the statement is in them and
   no other number;
4. cross-checks the verse counts against the KFGQPC Hafs data, the type and
   the surah revealed before against the Tanzil metadata of content.db,
   and the statement against the Shamarly headers (shamarly_headers.txt);
5. writes the JSON and prints every difference.

Nothing is inferred, completed or normalised: the statement, the count and
the «after» name are kept as printed. The data is a draft until a qualified
reviewer compares it with the scan (docs/MISSING_DATA.md, N16).

Usage: python3 tools/surah_type_1342/build.py [--html OUT_DIR]
  --html writes OUT_DIR/index.html for the reviewer: each header crop
  (headers/NNN-pPPP.png, as published on the mirror) beside its
  transcription.
"""

from __future__ import annotations

import html
import json
import re
import sqlite3
import sys
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
OUT = ROOT / 'assets/config/surah_type_1342.json'
KFGQPC = ROOT / 'tools/.cache/UthmanicHafs_v2-0.zip'
CONTENT_DB = ROOT / 'assets/db/content.db'

# The printed page of each surah's header (the PDF page; it equals the
# printed page). Al-Fatiha and al-Baqara have their header in two frames, one
# above and one below the text of the opening pages.
PAGES = {
    1: 2, 2: 3, 3: 62, 4: 97, 5: 134, 6: 162, 7: 192, 8: 226, 9: 239,
    10: 265, 11: 283, 12: 302, 13: 320, 14: 329, 15: 337, 16: 345, 17: 364,
    18: 380, 19: 396, 20: 406, 21: 420, 22: 432, 23: 445, 24: 456, 25: 470,
    26: 479, 27: 494, 28: 506, 29: 520, 30: 530, 31: 539, 32: 544, 33: 548,
    34: 562, 35: 571, 36: 579, 37: 587, 38: 597, 39: 605, 40: 617, 41: 629,
    42: 638, 43: 647, 44: 656, 45: 660, 46: 665, 47: 672, 48: 678, 49: 684,
    50: 688, 51: 692, 52: 696, 53: 700, 54: 704, 55: 708, 56: 713, 57: 718,
    58: 724, 59: 729, 60: 734, 61: 738, 62: 740, 63: 742, 64: 745, 65: 748,
    66: 751, 67: 754, 68: 757, 69: 761, 70: 764, 71: 767, 72: 770, 73: 773,
    74: 775, 75: 778, 76: 781, 77: 784, 78: 786, 79: 789, 80: 791, 81: 793,
    82: 795, 83: 796, 84: 799, 85: 800, 86: 802, 87: 803, 88: 804, 89: 806,
    90: 808, 91: 809, 92: 810, 93: 811, 94: 812, 95: 813, 96: 814, 97: 815,
    98: 816, 99: 817, 100: 818, 101: 819, 102: 820, 103: 820, 104: 821,
    105: 822, 106: 822, 107: 823, 108: 824, 109: 824, 110: 825, 111: 825,
    112: 826, 113: 826, 114: 827,
}

FIELDS = ['name', 'statement', 'count', 'after', 'remark']

# Every disagreement between the passes, and the corrections found while
# resolving them: (surah, field) -> (value, how it was decided).
RESOLVED = {
    (40, 'statement'): (
        'مكية إلا آيتى ٥٦ و٥٧ فمدنيتان',
        'pass 1: the hamza under the alif of «إلا» is printed, apart from '
        'the alif (seen at 3x on the crop)',
    ),
    (43, 'statement'): (
        'مكية إلا آية ٥٤ فمدنية',
        'pass 1: the hamza under the alif of «إلا» is printed (seen at full '
        'resolution beside al-Hijr 15, which has none)',
    ),
    (68, 'statement'): (
        'مكية إلا من آية ١٧ إلى غاية آية ٣٣ ومن آية ٤٨ إلى غاية آية ٥٠ '
        'فمدنية',
        'pass 1: both digits of «٣٣» have the three teeth of ٣ (seen at 24x '
        'beside the ٢ of «٥٢» in the same header); the Shamarly header also '
        'has ٣٣',
    ),
    (82, 'name'): (
        'الأنفطار',
        'pass 2: the title prints a hamza over the alif (seen at 2x)',
    ),
    (84, 'name'): (
        'الأنشقاق',
        'pass 2: the title prints a hamza over the alif (seen at 2x)',
    ),
    (84, 'after'): (
        'الأنفطار',
        'pass 2: a hamza over the alif (seen at 2x)',
    ),
    # Found while resolving, the same in both passes:
    (96, 'remark'): (
        'وهى أول ما نزل من القرءان',
        'both passes had «القرآن»; at 2x the word is printed «القرءان», '
        'the hamza on the line before the alif',
    ),
}

# Marks the reviewer should look at: read, but not beyond doubt.
UNCERTAIN = {
    30: 'the stroke over the alif of «الانشقاق» («نزلت بعد») may be a hamza '
        'or a fatha; transcribed without it, as both passes read it',
    2: 'the header is in the ornamental opening frames, in a different hand: '
       'the hamza of «إلا» and the dots of «فى» are hard to see',
}

# The structured fields, by hand from the statement. Each exception:
#   verses: [n, ...]          the verses listed
#   from, to                  a range «من آية a إلى غاية آية b»; to null for
#                             «إلى آخر السورة»
#   last: n                   «الآيتين الأخيرتين» (2), «الآيات الثلاث
#                             الأخيرة» (3)
#   first: n / rest: true     al-Ma'un's «ثلاث الآيات الأول … البقية»
#   type: meccan | medinan    what the statement says they are, or null
#   note: the printed words that say what they are when that is not a type
#                             (a place: «فنزلت بمنى فى حجة الوداع»)
# The surah's own type is «type» (mixed: al-Ma'un, whose statement gives
# its two parts and no type for the whole).
M, D = 'meccan', 'medinan'
STRUCTURE: dict[int, tuple[str, list[dict]] | tuple[str, list[dict], str]] = {
    2: (D, [{'verses': [281], 'type': None,
             'note': 'فنزلت بمنى فى حجة الوداع'}]),
    5: (D, [{'verses': [3], 'type': None,
             'note': 'فنزلت بعرفات فى حجة الوداع'}]),
    6: (M, [{'verses': [20, 23, 91, 93, 114, 141, 151, 152, 153],
             'type': D}]),
    7: (M, [{'from': 163, 'to': 170, 'type': D}]),
    8: (D, [{'from': 30, 'to': 36, 'type': M}]),
    9: (D, [{'last': 2, 'type': M}]),
    10: (M, [{'verses': [40, 94, 95, 96], 'type': D}]),
    11: (M, [{'verses': [12, 17, 114], 'type': D}]),
    12: (M, [{'verses': [1, 2, 3, 7], 'type': D}]),
    14: (M, [{'verses': [28, 29], 'type': D}]),
    15: (M, [{'verses': [87], 'type': D}]),
    16: (M, [{'last': 3, 'type': D}]),
    17: (M, [{'verses': [26, 32, 33, 57], 'type': D},
             {'from': 73, 'to': 80, 'type': D}]),
    18: (M, [{'verses': [28], 'type': D}, {'from': 83, 'to': 101, 'type': D}]),
    19: (M, [{'verses': [58, 71], 'type': D}]),
    20: (M, [{'verses': [130, 131], 'type': D}]),
    22: (D, [{'verses': [52, 53, 54, 55], 'type': None,
              'note': 'فبين مكة والمدينة'}]),
    25: (M, [{'verses': [68, 69, 70], 'type': D}]),
    26: (M, [{'verses': [197], 'type': D}, {'from': 224, 'to': None, 'type': D}]),
    28: (M, [{'from': 52, 'to': 55, 'type': D},
             {'verses': [85], 'type': None,
              'note': 'فبالجحفة أثناء الهجرة'}]),
    29: (M, [{'from': 1, 'to': 11, 'type': D}]),
    30: (M, [{'verses': [17], 'type': D}]),
    31: (M, [{'verses': [27, 28, 29], 'type': D}]),
    32: (M, [{'from': 16, 'to': 20, 'type': D}]),
    34: (M, [{'verses': [6], 'type': D}]),
    36: (M, [{'verses': [45], 'type': D}]),
    39: (M, [{'verses': [52, 53, 54], 'type': D}]),
    40: (M, [{'verses': [56, 57], 'type': D}]),
    42: (M, [{'verses': [23, 24, 25, 27], 'type': D}]),
    43: (M, [{'verses': [54], 'type': D}]),
    45: (M, [{'verses': [14], 'type': D}]),
    46: (M, [{'verses': [10, 15, 35], 'type': D}]),
    47: (D, [{'verses': [13], 'type': None,
              'note': 'فنزلت فى الطريق أثناء الهجرة'}]),
    48: (D, [], 'نزلت فى الطريق عند الانصراف من الحديبية'),
    50: (M, [{'verses': [38], 'type': D}]),
    53: (M, [{'verses': [32], 'type': D}]),
    54: (M, [{'verses': [44, 45, 46], 'type': D}]),
    56: (M, [{'verses': [81, 82], 'type': D}]),
    68: (M, [{'from': 17, 'to': 33, 'type': D},
             {'from': 48, 'to': 50, 'type': D}]),
    73: (M, [{'verses': [10, 11, 20], 'type': D}]),
    77: (M, [{'verses': [48], 'type': D}]),
    107: ('mixed', [{'first': 3, 'type': M}, {'rest': True, 'type': D}]),
    110: (D, [], 'نزلت بمنى فى حجة الوداع'),
}

# The verse count in words where the print writes it so.
COUNT_WORDS = {'سبع': 7, 'مائتان وست وثمانون': 286}

AR_DIGITS = str.maketrans('٠١٢٣٤٥٦٧٨٩', '0123456789')


def read_pass(path: Path) -> dict[int, dict[str, str]]:
    out = {}
    for line in path.read_text(encoding='utf-8').splitlines():
        if not line.strip() or line.startswith('#'):
            continue
        p = line.split('|')
        assert len(p) == 6, line
        out[int(p[0])] = dict(zip(FIELDS, p[1:]))
    assert sorted(out) == list(range(1, 115)), path
    return out


def numbers(text: str) -> list[int]:
    return [int(n.translate(AR_DIGITS)) for n in re.findall('[٠-٩]+', text)]


def structured_numbers(exceptions: list[dict]) -> list[int]:
    out = []
    for e in exceptions:
        out += e.get('verses', [])
        out += [e[k] for k in ('from', 'to') if e.get(k) is not None]
    return out


def header_text(s: int, r: dict[str, str]) -> str:
    """The header's lines after «سورة …», in the order printed."""
    parts = [r['statement']]
    if s == 110:  # its remark stands before the count
        parts.append(r['remark'])
    parts.append(f"وآياتها {r['count']}")
    if r['after']:
        parts.append(f"نزلت بعد {r['after']}")
    if r['remark'] and s != 110:
        parts.append(r['remark'])
    return ' '.join(parts)


def kfgqpc_counts() -> dict[int, int]:
    with zipfile.ZipFile(KFGQPC) as z:
        data = json.loads(z.read('UthmanicHafs_v2-0 data/hafsData_v2-0.json'))
    counts: dict[int, int] = {}
    for v in data:
        counts[v['sura_no']] = counts.get(v['sura_no'], 0) + 1
    return counts


def norm_name(s: str) -> str:
    s = s.removeprefix('سورة ').strip()
    s = re.sub('[أإآ]', 'ا', s)
    for a, b in (('ى', 'ي'), ('ة', 'ه'), ('ء', ''), ('ئ', 'ي')):
        s = s.replace(a, b)
    return s


def norm_statement(s: str) -> str:
    """For comparing with the Shamarly headers only: spelling and the list
    separators set aside, the words and numbers kept."""
    s = s.replace('،', ' و').replace('ي ', 'ى ').replace('في ', 'فى ')
    s = re.sub('[أإآ]', 'ا', s)
    s = s.replace('آيتي', 'آيتى').replace('الاية', 'اية').replace('اية', 'اية')
    s = re.sub(r'\s+', ' ', s.replace('و ', 'و')).strip()
    return s


def main() -> int:
    p1 = read_pass(HERE / 'pass1.txt')
    p2 = read_pass(HERE / 'pass2.txt')
    disagreements = [
        (s, f, p1[s][f], p2[s][f])
        for s in range(1, 115)
        for f in FIELDS
        if p1[s][f] != p2[s][f]
    ]
    print(f'Passes: {len(disagreements)} disagreements')
    final = {s: dict(p1[s]) for s in p1}
    for s, f, a, b in disagreements:
        assert (s, f) in RESOLVED, f'unresolved: surah {s} {f}: {a!r} / {b!r}'
        print(f'  {s} {f}: pass1 {a!r} / pass2 {b!r} -> {RESOLVED[(s, f)][0]!r}')
    for (s, f), (v, _) in RESOLVED.items():
        final[s][f] = v

    counts = kfgqpc_counts()
    db = sqlite3.connect(f'file:{CONTENT_DB}?mode=ro', uri=True)
    tanzil = {
        i: (n, r, o)
        for i, n, r, o in db.execute(
            'select id, name_ar, revelation, revelation_order from surah')
    }
    by_order = {o: i for i, (_, _, o) in tanzil.items()}
    names = {norm_name(n): i for i, (n, _, _) in tanzil.items()}
    shamarly = {}
    for line in (HERE / 'shamarly_headers.txt').read_text().splitlines():
        if line and not line.startswith('#'):
            p = line.split('|')
            shamarly[int(p[0])] = p[1:]

    surahs, report = [], []
    for s in range(1, 115):
        r = final[s]
        if s not in STRUCTURE:
            assert r['statement'] in ('مكية', 'مدنية'), (s, r['statement'])
            kind, exceptions, rest = {'مكية': M, 'مدنية': D}[
                r['statement']], [], []
        else:
            kind, exceptions, *rest = STRUCTURE[s]
            first = r['statement'].split()[0]
            if kind in (M, D) and first in ('مكية', 'مدنية'):
                assert {'مكية': M, 'مدنية': D}[first] == kind, s
        # Every number of the statement is in the structure, and no other.
        assert sorted(numbers(r['statement'])) == sorted(
            structured_numbers(exceptions)), (s, r['statement'])
        for e in exceptions:
            if e.get('note'):
                assert e['note'] in r['statement'], (s, e['note'])
        note = rest[0] if rest else None
        if note:
            assert note in r['statement'], (s, note)
        count = COUNT_WORDS.get(r['count']) or int(
            r['count'].translate(AR_DIGITS))

        # Cross-checks.
        if count != counts[s]:
            report.append(f'{s}: verse count {count} printed, '
                          f'{counts[s]} in KFGQPC Hafs')
        tn, tr, to = tanzil[s]
        if kind in (M, D) and kind != tr:
            report.append(f'{s}: type {kind} printed, {tr} in Tanzil')
        if kind == 'mixed':
            report.append(f'{s}: printed as two parts ({r["statement"]}), '
                          f'{tr} in Tanzil')
        before = by_order.get(to - 1)
        printed_after = names.get(norm_name(r['after'])) if r['after'] else None
        if r['after'] and printed_after is None:
            raise SystemExit(f'{s}: «after» not found: {r["after"]}')
        if printed_after != before:
            report.append(
                f'{s}: «نزلت بعد» {r["after"] or "not printed"} '
                f'({printed_after}); Tanzil order {to}, after surah {before}')
        sh = shamarly[s]
        if sh[0] and norm_statement(sh[0]) != norm_statement(r['statement']):
            report.append(f'{s}: Shamarly «{sh[0]}» / 1342 «{r["statement"]}»')
        if sh[1] and (COUNT_WORDS.get(sh[1]) or int(
                sh[1].translate(AR_DIGITS))) != count:
            report.append(f'{s}: Shamarly count {sh[1]}')
        if sh[2] and names.get(norm_name(sh[2])) != printed_after:
            report.append(f'{s}: Shamarly «after» {sh[2]}')

        entry = {
            'surah': s,
            'page': PAGES[s],
            'type': kind,
            'statement': r['statement'],
            'exceptions': exceptions,
            'verse_count_printed': r['count'],
            'verse_count': count,
            'after_printed': r['after'] or None,
            'remark': r['remark'] or None,
            'header_text': header_text(s, r),
        }
        if note:
            entry['note'] = note
        if s in UNCERTAIN:
            entry['uncertain'] = UNCERTAIN[s]
        surahs.append(entry)

    print(f'Cross-checks: {len(report)} differences')
    for line in report:
        print('  ' + line)

    data = {
        'status': 'draft-transcription',
        'source': {
            'title': 'مصحف الملك فؤاد، الطبعة الأولى',
            'edition': 'جمع ورتب في المطبعة الأميرية ببولاق وطبع في مصلحة '
                       'المساحة بالجيزة سنة ١٣٤٢هـ (1924)',
            'scan': 'https://archive.org/download/mushafElMe4679669676497saha'
                    '_201703/mushafElMesaha.pdf',
            'scan_sha256': '227a5c0a7036fd8006967b7651eb1cb0c46a14d22777d113'
                           'cc1f7ebd0af59175',
            'mirror': 'https://tibyan.ahmedhelal.dev/mirror/sources/'
                      'mushaf-1342-cairo/',
            'headers': 'https://tibyan.ahmedhelal.dev/mirror/sources/'
                       'mushaf-1342-cairo/headers/',
            'stated_source': 'وأُخذ بيان مكيه ومدنيه من الكتب المذكورة، '
                             'و"كتاب أبي القاسم عمر بن محمد بن عبد الكافي"، '
                             'و"كتب القراءات والتفسير" على خلاف في بعضها '
                             '(التعريف، ص و، صفحة PDF 834)',
            'rights': 'public domain: Egyptian government publication of '
                      '1924 (50-year term for legal persons, expired); '
                      'published before 1931 (US)',
        },
        'transcribed': '2026-10-06',
        'method': 'by hand from 600 dpi crops, two independent passes '
                  '(tools/surah_type_1342/pass1.txt, pass2.txt), every '
                  'disagreement resolved on the crop '
                  '(tools/surah_type_1342/build.py)',
        'review': {'approved': False, 'reviewer': None},
        'spelling': 'as printed: «فى», «آيتى», «ابراهيم», «الا» or «إلا» '
                    'as each header has it; digits as Arabic-Indic',
        'surahs': surahs,
    }
    text = json.dumps(data, ensure_ascii=False, indent=1) + '\n'
    OUT.write_text(text, encoding='utf-8')
    print(f'Wrote {OUT.relative_to(ROOT)}')

    if '--html' in sys.argv:
        out_dir = Path(sys.argv[sys.argv.index('--html') + 1])
        write_html(out_dir, surahs, disagreements, report)
    return 0


def write_html(out_dir: Path, surahs, disagreements, report) -> None:
    crops = sorted(p.name for p in out_dir.glob('[0-9][0-9][0-9]-p*.png'))
    rows = []
    for e in surahs:
        imgs = ''.join(
            f'<a href="{c}"><img src="{c}" loading="lazy" '
            f'alt="رأس سورة {e["surah"]}"></a>'
            for c in crops if c.startswith(f'{e["surah"]:03d}-'))
        exc = html.escape(json.dumps(e['exceptions'], ensure_ascii=False))
        extra = ''
        if e.get('uncertain'):
            extra += (f'<p class="u">للمراجعة: '
                      f'{html.escape(e["uncertain"])}</p>')
        rows.append(
            f'<section id="s{e["surah"]}"><h2>{e["surah"]} · ص '
            f'{e["page"]}</h2><div class="pair"><div class="img">{imgs}</div>'
            f'<div class="t"><p class="h">{html.escape(e["header_text"])}</p>'
            f'<dl><dt>البيان</dt><dd>{html.escape(e["statement"])}</dd>'
            f'<dt>النوع</dt><dd>{e["type"]}</dd>'
            f'<dt>المستثنى</dt><dd><code>{exc}</code></dd>'
            f'<dt>عدد الآيات</dt><dd>{html.escape(e["verse_count_printed"])}'
            f' ({e["verse_count"]})</dd>'
            f'<dt>نزلت بعد</dt><dd>{html.escape(e["after_printed"] or "—")}'
            f'</dd></dl>{extra}</div></div></section>')
    dis = ''.join(
        f'<li>{s} ({f}): القراءة ١ «{html.escape(a)}»، القراءة ٢ '
        f'«{html.escape(b)}» ← «{html.escape(RESOLVED[(s, f)][0])}»: '
        f'{html.escape(RESOLVED[(s, f)][1])}</li>'
        for s, f, a, b in disagreements)
    fixes = ''.join(
        f'<li>{s} ({f}): «{html.escape(v)}»: {html.escape(why)}</li>'
        for (s, f), (v, why) in RESOLVED.items()
        if not any(d[0] == s and d[1] == f for d in disagreements))
    rep = ''.join(f'<li>{html.escape(x)}</li>' for x in report)
    (out_dir / 'index.html').write_text(f'''<!doctype html>
<html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>رؤوس سور مصحف ١٣٤٢</title>
<style>
:root{{--bg:#f7f1e6;--ink:#1e1915;--muted:#7a4a26;--card:#fffdf8;--line:#dccbb0}}
@media (prefers-color-scheme: dark){{:root{{--bg:#1b1814;--ink:#eee4d4;--muted:#d1a77d;--card:#26221c;--line:#4a3f31}}}}
body{{background:var(--bg);color:var(--ink);font-family:system-ui,sans-serif;margin:0 auto;padding:16px;max-width:1200px}}
h1{{font-size:22px}}h2{{font-size:16px;margin:0 0 8px;color:var(--muted)}}
section{{background:var(--card);border:1px solid var(--line);border-radius:8px;padding:12px;margin:12px 0}}
.pair{{display:grid;grid-template-columns:minmax(0,3fr) minmax(0,2fr);gap:16px;align-items:start}}
@media (max-width:760px){{.pair{{grid-template-columns:1fr}}}}
.img img{{width:100%;height:auto;background:#fff;display:block;margin-bottom:6px}}
.h{{font-size:20px;line-height:1.8;margin:0 0 8px}}
dl{{display:grid;grid-template-columns:auto 1fr;gap:4px 12px;margin:0}}dt{{color:var(--muted)}}dd{{margin:0}}
code{{font-size:12px;word-break:break-word}}.u{{color:#b3261e}}
</style></head><body>
<h1>رؤوس السور في مصحف الملك فؤاد (بولاق ١٣٤٢هـ): نقل أول للمراجعة</h1>
<p>الحالة: <b>مسودة نقل</b> (draft-transcription). نُقل كل رأس يدويا مرتين
مستقلتين من مسح ٦٠٠ نقطة، وقورنت القراءتان آليا، وحُسم كل خلاف بالنظر في
الصورة. المطلوب من المراجع: مقابلة كل نص بصورته، والتوقيع على الملف أو تسجيل
الفروق. المصدر: <a href="../">mushaf-1342-cairo</a>. البيانات:
<code>assets/config/surah_type_1342.json</code>.</p>
<h2>خلاف القراءتين وحسمه</h2><ol>{dis}</ol>
<h2>تصحيحات وُجدت عند الحسم (القراءتان متفقتان عليها خطأ)</h2><ol>{fixes}</ol>
<h2>الفروق مع البيانات الأخرى (للعلم، لم يُغير شيء)</h2><ul>{rep}</ul>
{''.join(rows)}
</body></html>
''', encoding='utf-8')
    print(f'Wrote {out_dir / "index.html"}')


if __name__ == '__main__':
    sys.exit(main())
