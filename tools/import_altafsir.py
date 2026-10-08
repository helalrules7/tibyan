"""Import the altafsir.com copies of six tafsirs from OpenITI as review drafts.

Books (ث1 and غ1 in docs/MISSING_DATA.md), each pinned to an OpenITI
commit in tools/sources.json and checked by its SHA-256:

  tabari      0310Tabari.JamicBayan.Tafsir01001-ara1
  qurtubi     0671AbuCabdAllahQurtubi.JamicLiAhkamQuran.Tafsir01005-ara1
  ibn_kathir  0774IbnKathir.TafsirQuran.Tafsir01007-ara7
  baghawi     0510IbnMascudBaghawi.Tafsir.Tafsir02013-ara1
  saadi       1376CabdRahmanSacdi.TaysirKarimRahman.Tafsir10098-ara1
  biqai       0885BurhanDinBiqaci.NazmDurar.Tafsir02025-ara1  (نظم الدرر، المناسبات)

These copies were scraped from altafsir.com by the COBHUNI project
(Hamburg University). OpenITI marks them INCOMPLETE_VERSION and
PAGINATION: only the commentary on the verses (no introductions), no named
edition or editor, and no page numbers. What they do have is altafsir's own
segmentation: a heading per surah («### | [2 - سورة البقرة]») and one per
group of verses («### || [2.1-5]»).

What the script does (structure only, never the text):
  * splits the book at those headings: one entry per verse group, and any
    text between a surah heading and its first verse group as a surah
    introduction;
  * removes OpenITI markup only (paragraph and line-wrap marks, milestones
    `msNNN`), keeping every word as it is (checked word by word against
    the source);
  * suggests one link per entry: the verse range of altafsir's heading,
    confirmed when a quotation inside the passage («{ … }») is found in
    those verses of the Tanzil simple-clean text. A range that is not
    confirmed keeps a low confidence and a note; a heading that does not
    fit the surah gets no link.

Everything lands as a draft. A person reviews every entry in apps/review/.

Usage:
  python3 tools/import_altafsir.py saadi          # writes data/review/tafsir_saadi.review.db
  python3 tools/import_altafsir.py all            # every book
  python3 tools/import_altafsir.py tabari --out X.db   # elsewhere (must not exist)
"""
import argparse
import json
import re
import sys
from pathlib import Path

import fetch_sources
import review_db
from import_wahidi_asbab import MILESTONE, Verses, best_run, check_verbatim, norm, parse_openiti

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent
SCRIPT = 'script:import_altafsir@1'
CONTENT_DB = REPO / 'assets' / 'db' / 'content.db'

_ALTAFSIR = ('Text scraped from altafsir.com by Alicia González Martínez (COBHUNI project, '
             'Hamburg University); OpenITI marks it INCOMPLETE_VERSION and PAGINATION: '
             'commentary on the verses only, no introductions, no named edition, no pages. ')
_LICENCE = ('OpenITI digitisation: CC BY-NC-SA 4.0 (digitisation only). The printed edition '
            'behind the altafsir.com text, its editor, and altafsir.com\'s own terms are '
            'unknown and not covered.')


def _book(key, kind, title, author, source_id, out, repo, commit, notes=''):
    return {
        'source_id': source_id,
        'out': REPO / 'data' / 'review' / out,
        'row': {
            'key': key,
            'kind': kind,
            'title': title,
            'author': author,
            'edition': 'غير مذكورة (نسخة موقع altafsir.com)',
            'publisher': None,
            'tahqiq': None,
            'licence': _LICENCE,
            'digitised_by': f'OpenITI (from altafsir.com via COBHUNI), GitHub OpenITI/{repo} @ {commit[:8]}',
        },
        'notes': _ALTAFSIR + notes,
    }


BOOKS = {
    'tabari': _book(
        'tafsir_tabari_altafsir', 'tafsir', 'جامع البيان عن تأويل آي القرآن',
        'أبو جعفر محمد بن جرير الطبري (ت 310هـ)', 'openiti-tabari-tafsir01001',
        'tafsir_tabari.review.db', '0325AH', '089e665b4958e0f145a46941987fb81cf3dda1b8'),
    'qurtubi': _book(
        'tafsir_qurtubi_altafsir', 'tafsir', 'الجامع لأحكام القرآن',
        'أبو عبد الله محمد بن أحمد القرطبي (ت 671هـ)', 'openiti-qurtubi-tafsir01005',
        'tafsir_qurtubi.review.db', '0675AH', '4b1d2886508b435eb0377ccab96e1da96cc8ee0a',
        'OpenITI also removed paratext (CLEANED_VERSION, 2023).'),
    'ibn_kathir': _book(
        'tafsir_ibn_kathir_altafsir', 'tafsir', 'تفسير القرآن العظيم',
        'أبو الفداء إسماعيل بن عمر بن كثير (ت 774هـ)', 'openiti-ibnkathir-tafsir01007',
        'tafsir_ibn_kathir.review.db', '0775AH', '61b0c7891699554aeff8dffdb8b1a2a59d2d22ab'),
    'baghawi': _book(
        'tafsir_baghawi_altafsir', 'tafsir', 'معالم التنزيل',
        'أبو محمد الحسين بن مسعود البغوي (ت 516هـ)', 'openiti-baghawi-tafsir02013',
        'tafsir_baghawi.review.db', '0525AH', '6290621b58e063ed1aa47ffd0a6fc1630191e7cb'),
    'saadi': _book(
        'tafsir_saadi_altafsir', 'tafsir', 'تيسير الكريم الرحمن في تفسير كلام المنان',
        'عبد الرحمن بن ناصر السعدي (ت 1376هـ)', 'openiti-saadi-tafsir10098',
        'tafsir_saadi.review.db', '1400AH', '6b4084ba42c8e0bd7c888a8c4b37c43ca771c322',
        'OpenITI also removed paratext (CLEANED_VERSION, 2023). The author died in 1956: '
        'his text may still be under copyright in some countries.'),
    'biqai': _book(
        'munasabat_biqai_altafsir', 'munasabat', 'نظم الدرر في تناسب الآيات والسور',
        'برهان الدين إبراهيم بن عمر البقاعي (ت 885هـ)', 'openiti-biqai-nazmdurar-tafsir02025',
        'munasabat_biqai.review.db', '0900AH', '271ff65bd8364d3a46b5806ca529617d1ffc3393',
        'The whole book is imported (it is a full tafsir built on the relations between '
        'verses and surahs), split by altafsir\'s verse groups. OpenITI also has '
        'Shamela0009098 (Dar al-Kitab al-Islami, Cairo, with pages) but without verse '
        'headings, so it is not used for linking.'),
}

# ---------------------------------------------------------------- headings

SURAH_HEAD = re.compile(r'^\[\s*(\d+)\s*-\s*(سورة\s+.+?)\s*\]')
VERSE_HEAD = re.compile(r'^\[\s*(\d+)\s*\.\s*(\d+)\s*(?:-\s*(\d+)\s*)?\]')
QUOTE = re.compile(r'\{([^{}]*)\}')


def parse_heading(title):
    """('surah', number, name) | ('verses', surah, from, to) | None.
    OpenITI milestones (msNNN) inside a heading are markup and ignored."""
    title = MILESTONE.sub('', title).strip()
    m = SURAH_HEAD.match(title)
    if m:
        return ('surah', int(m.group(1)), m.group(2))
    m = VERSE_HEAD.match(title)
    if m:
        a = int(m.group(2))
        return ('verses', int(m.group(1)), a, int(m.group(3) or a))
    return None


def split_entries(events):
    """Splits parsed events at altafsir's headings. Returns a list of dicts
    with seq, kind, section, surah, range (surah, from, to) or None, label
    (altafsir's heading), volume/page (None: no pages), text."""
    entries = []
    current = None
    surah, section = None, None

    def close():
        nonlocal current
        if current and current['paras']:
            entries.append(current)
        current = None

    for kind, value in events:
        if kind == 'heading':
            h = parse_heading(value)
            if h is None:
                raise SystemExit(f'unknown heading: {value!r}')
            close()
            if h[0] == 'surah':
                surah, section = h[1], h[2]
                current = {'kind': 'surah_intro', 'section': section, 'surah': surah,
                           'range': None, 'label': value, 'paras': []}
            else:
                current = {'kind': 'passage', 'section': section, 'surah': surah,
                           'range': h[1:], 'label': value, 'paras': []}
            continue
        if current is None:
            current = {'kind': 'front_matter', 'section': None, 'surah': None,
                       'range': None, 'label': None, 'paras': []}
        current['paras'].append(' '.join(t for t, _ in value))
    close()
    for seq, e in enumerate(entries, 1):
        e['seq'] = seq
        e['volume'] = e['page'] = e['page_end'] = None
        e['text'] = '\n'.join(e.pop('paras'))
    return entries


# ---------------------------------------------------------------- linking

def skeleton(tokens):
    """Comparison only: drops alif so that the book's spelling of a verse
    («السموت») meets the Tanzil spelling («السماوات»). Never stored."""
    return [t.replace('ا', '') or t for t in tokens]


def quotations(text):
    """The passage's own quotations («{ … }»), as written."""
    return [q.strip() for q in QUOTE.findall(text) if norm(q)]


def suggest_links(entry, verses):
    """Returns ([link], [note]). The link rests on altafsir's heading; a
    quotation of the passage found inside those verses confirms it."""
    notes = []
    if entry['kind'] == 'surah_intro':
        count = verses.counts[entry['surah']]
        return [{'surah': entry['surah'], 'ayah_from': 1, 'ayah_to': count, 'quote': None,
                 'basis': 'marker', 'confidence': 0.5}], [
            'text under the surah heading before its first verse group: linked to the whole surah']
    if entry['kind'] != 'passage':
        return [], []
    surah, a, b = entry['range']
    notes.append(f'altafsir heading {entry["label"]}')
    if surah != entry['surah']:
        notes.append(f'heading names surah {surah} under the heading of surah {entry["surah"]}')
        return [], notes
    count = verses.counts.get(surah, 0)
    if not (1 <= a <= b <= count):
        notes.append(f'verses {a}-{b} are outside surah {surah} (1-{count})')
        return [], notes

    span = skeleton(verses.span_tokens(surah, a, b))
    quotes = quotations(entry['text'])
    multi = single = None
    for q in quotes:
        tokens = skeleton(norm(q).split())
        if best_run(tokens, span) == 1.0:
            if len(tokens) >= 2:
                multi = q
                break
            single = single or q

    def link(basis, conf, quote=None):
        return {'surah': surah, 'ayah_from': a, 'ayah_to': b, 'quote': quote,
                'basis': basis, 'confidence': conf}

    if multi:
        return [link('marker+quote', 0.95, multi)], notes
    if single:
        notes.append('only a one-word quotation was found in these verses')
        return [link('marker+quote', 0.85, single)], notes
    if quotes:
        notes.append(f'none of the passage\'s {len(quotes)} quotations was found in {surah}:{a}-{b}')
        return [link('marker', 0.5)], notes
    notes.append('the passage quotes nothing to confirm the heading')
    return [link('marker', 0.6)], notes


def coverage_notes(entries, counts):
    """Notes on gaps and overlaps between consecutive verse groups, and
    the verses no group covers. Returns {seq: [note]} and the uncovered
    verse count."""
    notes = {}
    covered = set()
    last = {}
    for e in entries:
        if e['kind'] != 'passage' or e['range'][0] != e['surah']:
            continue
        s, a, b = e['range']
        prev = last.get(s, 0)
        if a > prev + 1:
            notes.setdefault(e['seq'], []).append(f'no verse group for {s}:{prev + 1}-{a - 1} before this one')
        elif a <= prev:
            notes.setdefault(e['seq'], []).append(f'starts at {s}:{a}, inside the previous group (to {prev})')
        last[s] = max(prev, b)
        covered.update((s, x) for x in range(a, min(b, counts.get(s, 0)) + 1))
    total = sum(counts.values())
    return notes, total - len(covered)


# ---------------------------------------------------------------- main

def load_verses(content_db):
    import sqlite3
    content = sqlite3.connect(f'file:{content_db}?mode=ro', uri=True)
    counts = dict(content.execute('SELECT id, ayah_count FROM surah'))
    verses = Verses(content.execute(
        'SELECT surah, number, text_search, search_basmala_prefix FROM ayah'), counts)
    content.close()
    return verses


def load_source(source_id):
    manifest = json.loads((ROOT / 'sources.json').read_text(encoding='utf-8'))
    source = next(s for s in manifest['sources'] if s['id'] == source_id)
    if fetch_sources.main({source_id}) != 0:
        raise SystemExit(f'{source_id}: SHA-256 mismatch, refusing to import')
    return source, fetch_sources.CACHE / source['file']


def build(book, out, content_db, path, source, verses=None):
    raw = path.read_text(encoding='utf-8')
    _, events = parse_openiti(raw)
    if not re.search(r'^#META# Source: altafsir\.com\s*$', raw.partition('#META#Header#End#')[0], re.M):
        raise SystemExit('not an altafsir.com copy (no "#META# Source: altafsir.com")')
    entries = split_entries(events)
    check_verbatim(raw, entries)
    verses = verses or load_verses(content_db)
    gap_notes, uncovered = coverage_notes(entries, verses.counts)

    db = review_db.create(out, content_db)
    row = dict(book['row'], url=source['url'], file=source['file'], sha256=source['sha256'],
               retrieved_at=review_db.now()[:10], notes=book['notes'])
    source_id = review_db.add_source(db, row)
    stats = {'entries': 0, 'by_kind': {}, 'linked': 0, 'unlinked_passages': [],
             'by_basis': {}, 'by_confidence': {}, 'verses_without_passage': uncovered}
    linked_verses = set()
    for e in entries:
        links, notes = suggest_links(e, verses)
        e['notes'] = notes + gap_notes.get(e['seq'], [])
        review_db.add_draft(db, source_id, row['key'], e, links, SCRIPT)
        stats['entries'] += 1
        stats['by_kind'][e['kind']] = stats['by_kind'].get(e['kind'], 0) + 1
        if links:
            stats['linked'] += 1
            l = links[0]
            stats['by_basis'][l['basis']] = stats['by_basis'].get(l['basis'], 0) + 1
            c = str(l['confidence'])
            stats['by_confidence'][c] = stats['by_confidence'].get(c, 0) + 1
            if e['kind'] == 'passage':
                linked_verses.update((l['surah'], x) for x in range(l['ayah_from'], l['ayah_to'] + 1))
        elif e['kind'] == 'passage':
            stats['unlinked_passages'].append({'seq': e['seq'], 'heading': e['label'],
                                               'notes': e['notes']})
    stats['linked_verses'] = len(linked_verses)
    db.execute("INSERT INTO meta VALUES ('import_stats', ?)",
               (json.dumps(stats, sort_keys=True, ensure_ascii=False),))
    db.commit()
    db.close()
    return stats


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('book', choices=[*BOOKS, 'all'])
    ap.add_argument('--out', type=Path, help='only with one book')
    ap.add_argument('--content-db', type=Path, default=CONTENT_DB)
    args = ap.parse_args(argv)
    names = list(BOOKS) if args.book == 'all' else [args.book]
    if args.out and len(names) > 1:
        ap.error('--out needs a single book')
    verses = load_verses(args.content_db)
    for name in names:
        book = BOOKS[name]
        source, path = load_source(book['source_id'])
        stats = build(book, args.out or book['out'], args.content_db, path, source, verses)
        print(name, json.dumps(stats, ensure_ascii=False, sort_keys=True, indent=1))
    return 0


if __name__ == '__main__':
    sys.exit(main())
