"""Readers for the riwaya sources, shared by build_riwaya_packs.py and
verify_riwayat.py. Structure only: every text is returned exactly as it is
in its file.

Sources (all in tools/.cache/riwayat/, fetched by fetch_riwayat.py):
  <qws>-kfqc-json.zip, <qws>-kfqc-svg.zip   quran-ws/quran-svg v1.1.1: the KFGQPC
                                            page artwork of each riwaya's Madina
                                            mushaf as SVG, verse outlines, surah list
  Uthmanic<Name>_v2-x.zip                   KFGQPC "quran-dev" riwaya text and font
                                            (the Complex's own files, published MD5)
  quranpedia/mushafs-<n>.json.gz            Quranpedia: each riwaya verse's Hafs
                                            numbers (`number_in_hafs`)
"""
import gzip
import json
import re
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CACHE = ROOT / '.cache'
RCACHE = CACHE / 'riwayat'

# id: (quran-ws name, KFGQPC zip, KFGQPC json member, KFGQPC font member,
#      Quranpedia mushaf id, Arabic name, English name)
RIWAYAT = {
    'warsh': ('warsh', 'UthmanicWarsh_v2-1.zip',
              'UthmanicWarsh_v2-1 data/warshData_v2-1.json',
              'UthmanicWarsh_v2-1 font/uthmanic_warsh_v21.ttf', 4,
              'ورش عن نافع', 'Warsh from Nafi'),
    'qalun': ('qalon', 'UthmanicQaloun_v2-1.zip',
              'UthmanicQaloun_v2-1 data/QalounData_v2-1.json',
              'UthmanicQaloun_v2-1 font/uthmanic_qaloun_v21.ttf', 7,
              'قالون عن نافع', 'Qalun from Nafi'),
    'douri': ('douri', 'UthmanicDouri_v2-0.zip',
              'UthmanicDouri_v2-0 data/DouriData_v2-0.json',
              'UthmanicDouri_v2-0 font/uthmanic_douri_v20.ttf', 6,
              'الدوري عن أبي عمرو', 'al-Duri from Abu Amr'),
    'shubah': ('shubah', 'UthmanicShuba_v2-0.zip',
               'UthmanicShuba_v2-0 data/shubaData_v2-0.json',
               'UthmanicShuba_v2-0 font/uthmanic_shuba_v20.ttf', 9,
               'شعبة عن عاصم', "Shu'bah from Asim"),
}


def sha256(path):
    import hashlib
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def qws_verses(riwaya):
    """{(surah, ayah): dict(page, polygon, x, y)} in page order, from the
    quran-ws page files (the `NNN-surahMM.json` copies are skipped)."""
    name = RIWAYAT[riwaya][0]
    out = {}
    with zipfile.ZipFile(RCACHE / f'{name}-kfqc-json.zip') as z:
        for member in sorted(z.namelist()):
            m = re.fullmatch(r'(?:.*/)?(\d{3})\.json', member)
            if not m:
                continue
            page = int(m.group(1))
            for a in json.loads(z.read(member)):
                key = (a['surahNumber'], a['ayahNumber'])
                if key in out:
                    # A verse that runs over a page break has an outline on
                    # each page; its page is where it starts.
                    out[key]['more'].append((page, a['polygon'], a.get('x'), a.get('y')))
                    continue
                out[key] = dict(page=page, polygon=a['polygon'], x=a.get('x'),
                                y=a.get('y'), more=[])
    return out


def qws_surahs(riwaya):
    name = RIWAYAT[riwaya][0]
    with zipfile.ZipFile(RCACHE / f'{name}-kfqc-json.zip') as z:
        member = next(n for n in z.namelist() if n.endswith('surah.json'))
        return {s['number']: s for s in json.loads(z.read(member))}


def qws_svg_names(riwaya):
    name = RIWAYAT[riwaya][0]
    with zipfile.ZipFile(RCACHE / f'{name}-kfqc-svg.zip') as z:
        return sorted(n for n in z.namelist() if re.fullmatch(r'(?:.*/)?\d{3}\.svg', n))


def kfgqpc_rows(riwaya):
    """The KFGQPC rows as published (text verbatim)."""
    _, zname, member, *_ = RIWAYAT[riwaya]
    with zipfile.ZipFile(RCACHE / zname) as z:
        return json.loads(z.read(member).decode('utf-8-sig'))


def kfgqpc_text(riwaya):
    """{(surah, ayah): aya_text} verbatim. Each ends with the verse number:
    the number glyph of the riwaya's KFGQPC font, after a space, except
    Warsh 16:123 (no space before the glyph) and Shu'bah 2:286 (the number
    in Arabic-Indic digits), as published."""
    out = {}
    for r in kfgqpc_rows(riwaya):
        text = r['aya_text']
        assert 'ﰀ' <= text[-1] <= '﷿' or text.endswith(' ٢٨٦'), (
            riwaya, r['sura_no'], r['aya_no'])
        out[(r['sura_no'], r['aya_no'])] = text
    return out


def kfgqpc_font(riwaya):
    """(file name, bytes) of the riwaya's KFGQPC font, unchanged."""
    _, zname, _, font, *_ = RIWAYAT[riwaya]
    with zipfile.ZipFile(RCACHE / zname) as z:
        return Path(font).name, z.read(font)


def kfgqpc_hafs_text():
    with zipfile.ZipFile(CACHE / 'UthmanicHafs_v2-0.zip') as z:
        rows = json.loads(z.read('UthmanicHafs_v2-0 data/hafsData_v2-0.json'))
    return {(r['sura_no'], r['aya_no']): r['aya_text'] for r in rows}


def quranpedia(riwaya):
    """{(surah, ayah): dict(hafs=[numbers in the same surah], juz, hizb, page)}."""
    n = RIWAYAT[riwaya][4]
    d = json.load(gzip.open(RCACHE / 'quranpedia' / f'mushafs-{n}.json.gz'))['data']
    out = {}
    for s in d['surahs']:
        for a in s['ayahs']:
            out[(s['id'], a['number'])] = dict(
                hafs=list(a['number_in_hafs'] or []), juz=a['juz'], hizb=a['hizb'],
                page=a['page_number'])
    return out


def hafs_counts():
    """Verses per surah in Hafs (Tanzil metadata)."""
    import xml.etree.ElementTree as ET
    meta = ET.parse(CACHE / 'quran-data.xml').getroot()
    return {int(s.get('index')): int(s.get('ayas')) for s in meta.find('suras')}


def counts(keys):
    out = {}
    for s, _ in keys:
        out[s] = out.get(s, 0) + 1
    return out


# Base letters only, for comparing two texts (never for showing one): drop
# marks, small letters, signs, spaces and the verse number; fold the letter
# shapes the riwayat write differently (hamza seats, alif forms, ya and
# alif maqsura, ta marbuta) so that the alignment follows the words.
_MARKS = re.compile(
    '[ؐ-ًؚ-ٰٟۖ-ۭ࣓-ࣿ'
    'ـ  ﰀ-﷿۝۞۩‌-‏'
    '٠-٩]')
_FOLD = str.maketrans({
    'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ٲ': 'ا', 'ٳ': 'ا',
    'ى': 'ي', 'ی': 'ي', 'ۦ': 'ي', 'ئ': 'ي', 'ے': 'ي',
    'ؤ': 'و', 'ۥ': 'و',
    'ة': 'ه', 'ۃ': 'ه',
    'ء': '', 'ٔ': '', 'ٕ': '',
    'ک': 'ك', 'ڢ': 'ف', 'ڧ': 'ق', 'ں': 'ن',
})


def skeleton(text):
    return _MARKS.sub('', text).translate(_FOLD)


def aligned_surah(riwaya_text, hafs_text, surah, n_riwaya, n_hafs):
    """For each riwaya verse of a surah, the Hafs verses its letters fall
    in, from aligning the two letter strings of the whole surah: a riwaya
    verse covers each Hafs verse with which it shares a word's worth of
    aligned letters (3, or 30% of either verse when shorter)."""
    import difflib
    r_parts, r_owner = [], []
    for a in range(1, n_riwaya + 1):
        s = skeleton(riwaya_text[(surah, a)])
        r_parts.append(s)
        r_owner += [a] * len(s)
    h_parts, h_owner = [], []
    for a in range(1, n_hafs + 1):
        s = skeleton(hafs_text[(surah, a)])
        h_parts.append(s)
        h_owner += [a] * len(s)
    sm = difflib.SequenceMatcher(None, ''.join(r_parts), ''.join(h_parts), autojunk=False)
    pair = {}
    for block in sm.get_matching_blocks():
        for k in range(block.size):
            key = (r_owner[block.a + k], h_owner[block.b + k])
            pair[key] = pair.get(key, 0) + 1
    out = {}
    for a in range(1, n_riwaya + 1):
        out[a] = sorted(h for (ra, h), n in pair.items()
                        if ra == a and (n >= 3 or n >= 0.3 * len(h_parts[h - 1])
                                        or n >= 0.3 * len(r_parts[a - 1])))
    return out


def hafs_map(riwaya):
    """{(surah, ayah): [Hafs verse numbers in that surah]}, worked out from
    the KFGQPC riwaya text and the KFGQPC Hafs text (verify_riwayat.py
    checks it against Quranpedia's published map). Al-Fatiha: the riwayat
    other than Shu'bah do not count the basmala, which Hafs counts as 1:1;
    the riwaya text has no basmala, so no riwaya verse maps to Hafs 1:1."""
    text = kfgqpc_text(riwaya)
    hafs = kfgqpc_hafs_text()
    hc = hafs_counts()
    rc = counts(text)
    out = {}
    for s in range(1, 115):
        for a, hs in aligned_surah(text, hafs, s, rc[s], hc[s]).items():
            out[(s, a)] = hs
    return out


def check_map(m, riwaya_counts, hafs_counts_):
    """Problems in a riwaya -> Hafs map: every Hafs verse covered once (a
    Hafs verse split by the riwaya is shared by consecutive verses), each
    entry a run, never stepping back. Al-Fatiha's 1:1 may be uncovered."""
    problems = []
    for s in range(1, 115):
        seq = [m[(s, a)] for a in range(1, riwaya_counts[s] + 1)]
        flat = sorted({h for hs in seq for h in hs})
        want = list(range(1, hafs_counts_[s] + 1))
        if flat != want and not (s == 1 and flat == want[1:]):
            problems.append((s, 'coverage', sorted(set(want) - set(flat))))
        for a, hs in enumerate(seq, 1):
            if not hs or hs != list(range(hs[0], hs[-1] + 1)):
                problems.append((s, a, 'not a run', hs))
        for a in range(1, len(seq)):
            if seq[a] and seq[a - 1] and seq[a][0] < seq[a - 1][-1]:
                problems.append((s, a + 1, 'steps back'))
    return problems
