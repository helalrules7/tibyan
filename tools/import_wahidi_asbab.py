"""Import al-Wahidi's «أسباب نزول القرآن» from OpenITI as review drafts.

Source: OpenITI 0468IbnAhmadWahidiNaysaburi.AsbabNuzul.Shamela0011314-ara1
(the corpus's primary version: ed. ʿIṣām b. ʿAbd al-Muḥsin al-Ḥumaydān,
Dār al-Iṣlāḥ, Dammam, 2nd ed. 1412/1992), pinned to an OpenITI commit
in tools/sources.json and checked by its SHA-256.

What the script does (structure only, never the text):
  * splits the book by its own sections (### headings: front matter and one
    heading per surah) and, inside a surah, by its own passage headers
    («قوله تعالى: {…} {N}»): each header starts a passage that runs to the
    next header;
  * removes OpenITI markup only (paragraph marks, line-wrap marks,
    milestones `msNNN`, page tags), keeping every word as it is and
    recording the page range from the page tags;
  * suggests verse links from the book's markers: the surah heading, the
    verse number the edition prints after the quotation, and the quotation
    itself, which is looked up in the Tanzil simple-clean text to confirm
    or find the verse. Each link gets a confidence score and its basis.

Everything lands as a draft. A person reviews every entry in apps/review/.

Usage:
  python3 tools/import_wahidi_asbab.py              # writes data/review/wahidi_asbab.review.db
  python3 tools/import_wahidi_asbab.py --out X.db   # elsewhere (must not exist)
"""
import argparse
import json
import re
import sys
from pathlib import Path

import fetch_sources
import review_db

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent
SOURCE_ID = 'openiti-wahidi-asbab-shamela0011314'
SCRIPT = 'script:import_wahidi_asbab@1'
DEFAULT_OUT = REPO / 'data' / 'review' / 'wahidi_asbab.review.db'
CONTENT_DB = REPO / 'assets' / 'db' / 'content.db'

SOURCE_ROW = {
    'key': 'wahidi_asbab_humaydan',
    'kind': 'asbab_nuzul',
    'title': 'أسباب نزول القرآن',
    'author': 'أبو الحسن علي بن أحمد الواحدي النيسابوري (ت 468هـ)',
    'edition': 'الثانية، 1412هـ - 1992م',
    'publisher': 'دار الإصلاح - الدمام',
    'tahqiq': 'عصام بن عبد المحسن الحميدان',
    'licence': 'OpenITI digitisation: CC BY-NC-SA 4.0 (digitisation only; '
               'the editor\'s rights in the printed edition are not covered)',
    'digitised_by': 'OpenITI (from al-Maktaba al-Shamela 11314), release 2025.1.9; '
                    'GitHub OpenITI/0475AH @ cc9beb0d',
}

# ---------------------------------------------------------------- parsing

PAGE_TAG = re.compile(r'PageV(\d+)P(\d+)')
MILESTONE = re.compile(r'\s*\bms\d+\b')
HEADING = re.compile(r'^###\s*\|+\s*(.*)$')
# The verse number(s) the edition prints after a quotation: {6}, {1، 2},
# {5 - 6}; a few passages use square brackets: [107، 108].
NUM_MARKER = re.compile(r'[{\[]\s*\d+(?:\s*(?:[،,]|-|–)\s*\d+)*\s*[}\]]')
# A printed page number in square brackets that opens a few headers: [260].
PAGE_PREFIX = re.compile(r'^\[\d+\]\s*')
HEADER_START = re.compile(
    r'^(?:\(\d+\)\s*-\s*)?و?قوله(?:\s*تعالى|\s*-\s*عز وجل\s*-|\s*عز وجل|\s*سبحانه)?\s*:?\s*\{')
# The same header after a printed page number, quoting without braces.
HEADER_AFTER_PAGE = re.compile(r'^\[\d+\]\s*و?قوله')
QUOTE = re.compile(r'\{([^{}]*[^\s{}\d،,\-–][^{}]*)\}')
SURAH_HEADING = re.compile(r'^سورة\s+(.+)$')


def parse_openiti(raw):
    """Returns (meta, events). meta: {'040.EdEDITOR': ...}. events: list of
    ('heading', title) and ('para', segments) where segments is a list of
    (text, page) pairs: the text before each page tag belongs to that page."""
    head, sep, body = raw.partition('#META#Header#End#')
    if not sep:
        raise ValueError('not an OpenITI mARkdown file')
    meta = {}
    for line in head.split('\n'):
        m = re.match(r'#META#\s*(\S+)\s*::\s*(.*)$', line)
        if m:
            meta[m.group(1)] = m.group(2).strip()

    blocks = []  # ['heading', title] | ['para', raw text]
    for line in body.split('\n'):
        h = HEADING.match(line)
        if h:
            blocks.append(['heading', h.group(1).strip()])
        elif line.startswith('# '):
            blocks.append(['para', line[2:]])
        elif line.startswith('~~'):
            if blocks and blocks[-1][0] == 'para':
                blocks[-1][1] += ' ' + line[2:]
            else:
                blocks.append(['para', line[2:]])
        elif line.strip():
            blocks.append(['para', line.strip()])

    # Split paragraphs at page tags; text before a tag is on that page.
    events, pending = [], []
    for kind, value in blocks:
        if kind == 'heading':
            events.append(('heading', value))
            continue
        segments = []
        pos = 0
        for m in PAGE_TAG.finditer(value):
            seg = [value[pos:m.start()], None]
            segments.append(seg)
            pending.append(seg)
            page = (int(m.group(1)), int(m.group(2)))
            for p in pending:
                p[1] = page
            pending = []
            pos = m.end()
        seg = [value[pos:], None]
        segments.append(seg)
        pending.append(seg)
        events.append(('para', segments))
    last = None
    for e in reversed(events):  # text after the last tag: the last page
        if e[0] == 'para':
            last = next((s[1] for s in reversed(e[1]) if s[1]), last)
            if last:
                break
    for p in pending:
        p[1] = last
    out = []
    for kind, value in events:
        if kind == 'heading':
            out.append((kind, value))
        else:
            segs = [(clean(t), page) for t, page in value]
            segs = [(t, page) for t, page in segs if t]
            if segs:
                out.append(('para', segs))
    return meta, out


def clean(text):
    """Removes OpenITI markup only: milestones and surplus whitespace."""
    text = MILESTONE.sub('', text)
    return re.sub(r'\s+', ' ', text).strip()


def body_words(raw):
    """Every word of the book's body in order, with only OpenITI markup
    taken out. Used to prove the split keeps the text whole."""
    body = raw.partition('#META#Header#End#')[2]
    words = []
    for line in body.split('\n'):
        if HEADING.match(line):
            continue
        line = PAGE_TAG.sub(' ', line)
        line = re.sub(r'^(# |~~)', '', line)
        words += MILESTONE.sub(' ', line).split()
    return words


def check_verbatim(raw, entries):
    got = [w for e in entries for w in e['text'].split()]
    want = body_words(raw)
    if got != want:
        i = next((k for k, (a, b) in enumerate(zip(got, want)) if a != b), min(len(got), len(want)))
        raise SystemExit(f'split changed the text near word {i}: {want[i - 5:i + 5]} vs {got[i - 5:i + 5]}')


def para_text(segments):
    return ' '.join(t for t, _ in segments)


# ---------------------------------------------------------------- splitting

def is_header(text):
    return bool(HEADER_START.match(text) or HEADER_AFTER_PAGE.match(text)) or (
        text.startswith('{') and len(text) < 200 and NUM_MARKER.search(text) is not None)


def split_entries(events, surah_of):
    """Splits parsed events into entries by the book's own sections and
    passage headers. `surah_of(heading)` returns a surah number or None.
    Returns a list of dicts with seq, kind, section, surah, header, paras,
    volume, page, page_end, text."""
    entries = []
    section, surah = None, None
    current = None

    def close():
        nonlocal current
        if current and current['paras']:
            entries.append(current)
        current = None

    def start(kind, header=None):
        nonlocal current
        close()
        current = {'kind': kind, 'section': section, 'surah': surah,
                   'header': header, 'paras': []}

    for kind, value in events:
        if kind == 'heading':
            if not re.search(r'[ء-ي]', value):
                continue  # stray "...." headings inside a section
            section = value
            surah = surah_of(value)
            start('surah_intro' if surah else 'front_matter')
            continue
        text = para_text(value)
        if current is None:
            start('front_matter')
        if (current['kind'] == 'passage' and len(current['paras']) == 1
                and not NUM_MARKER.search(PAGE_PREFIX.sub('', current['header']))
                and len(text) < 80 and NUM_MARKER.search(text)):
            # A header that wraps into a second paragraph («…الطاغوت} {51} .»
            # or the verse number alone): its marker still belongs to it.
            current['header'] += ' ' + text
        elif surah and is_header(text):
            start('passage', header=text)
        current['paras'].append(value)
    close()

    for seq, e in enumerate(entries, 1):
        segs = [s for para in e['paras'] for s in para]
        e['seq'] = seq
        e['volume'] = segs[0][1][0] if segs[0][1] else None
        e['page'] = segs[0][1][1] if segs[0][1] else None
        e['page_end'] = segs[-1][1][1] if segs[-1][1] else None
        e['text'] = '\n'.join(para_text(p) for p in e['paras'])
    return entries


# ---------------------------------------------------------------- surahs

ALIASES = {
    'بني إسرائيل': 17, 'بنى إسرائيل': 17, 'الإسراء': 17,
    'تبت': 111, 'المسد': 111, 'اللهب': 111,
    'المؤمنين': 23, 'حم السجدة': 41, 'السجدة حم': 41,
    'الملائكة': 35, 'المجادلة': 58, 'الدهر': 76, 'الإنسان': 76,
    'التحريم': 66, 'المتحرم': 66, 'براءة': 9, 'التوبة': 9,
    'المؤمن': 40, 'غافر': 40, 'سأل سائل': 70, 'المعارج': 70,
    'القتال': 47, 'محمد': 47, 'الكافرون': 109, 'الكافرين': 109,
    'إذا زلزلت': 99, 'الزلزلة': 99, 'إذا الشمس كورت': 81, 'إذا السماء انفطرت': 82,
    'إذا السماء انشقت': 84, 'اقرأ': 96, 'اقرأ باسم ربك': 96, 'لم يكن': 98,
    'ألم نشرح': 94, 'ألم تر': 105, 'أرأيت': 107, 'عم': 78, 'عم يتساءلون': 78,
    'هل أتاك': 88, 'هل أتى': 76, 'سبح': 87, 'الضحى': 93,
}


def norm(s):
    """Folding for comparison only. The stored text is never normalised."""
    s = re.sub(r'[ؐ-ًؚ-ٰٟۖ-ۭـ]', '', s)
    s = re.sub('[أإآٱ]', 'ا', s)
    s = s.replace('ى', 'ي').replace('ة', 'ه').replace('ؤ', 'و').replace('ئ', 'ي')
    s = re.sub(r'[^ء-ي\s]', ' ', s)
    return re.sub(r'\s+', ' ', s).strip()


def surah_resolver(surah_names):
    """surah_names: {number: arabic name}. Returns heading -> number|None."""
    table = {norm(name): n for n, name in surah_names.items()}
    table.update({norm(k): v for k, v in ALIASES.items()})

    def resolve(heading):
        m = SURAH_HEADING.match(heading.strip())
        if not m:
            return None
        name = norm(m.group(1))
        for candidate in (name, 'ال' + name, re.sub('^ال', '', name)):
            if candidate in table:
                return table[candidate]
        return None
    return resolve


# ---------------------------------------------------------------- linking

def parse_header(header):
    """Returns (quote, (ayah_from, ayah_to) or None) from a passage header."""
    quote = None
    q = QUOTE.search(header)
    if q:
        quote = q.group(1).strip()
    numbers = None
    for m in NUM_MARKER.finditer(PAGE_PREFIX.sub('', header)):
        nums = [int(x) for x in re.findall(r'\d+', m.group(0))]
        numbers = (min(nums), max(nums))
    return quote, numbers


def same_word(a, b):
    """Token equality that forgives one letter in longer words (spelling
    differences between the book's quotation and the mushaf orthography,
    e.g. يرجوا/يرجو, تحي/تحيي). Comparison only."""
    if a == b:
        return True
    if min(len(a), len(b)) < 3 or abs(len(a) - len(b)) > 1:
        return False
    if len(a) > len(b):
        a, b = b, a
    i = 0
    while i < len(a) and a[i] == b[i]:
        i += 1
    return a[i:] == b[i + 1:] or (len(a) == len(b) and a[i + 1:] == b[i + 1:])


def best_run(quote_tokens, verse_tokens):
    """Longest run of quote tokens found contiguously in the verse, as a
    fraction of the quote's length."""
    if not quote_tokens:
        return 0.0
    best = 0
    n, m = len(quote_tokens), len(verse_tokens)
    prev = [0] * (m + 1)
    for i in range(1, n + 1):
        cur = [0] * (m + 1)
        qi = quote_tokens[i - 1]
        for j in range(1, m + 1):
            if same_word(qi, verse_tokens[j - 1]):
                cur[j] = prev[j - 1] + 1
                if cur[j] > best:
                    best = cur[j]
        prev = cur
    return best / n


class Verses:
    def __init__(self, rows, ayah_counts):
        """rows: (surah, ayah, text_search, basmala_prefix)."""
        self.tokens = {}
        for surah, ayah, text, prefix in rows:
            self.tokens[(surah, ayah)] = norm(text[prefix:]).split()
        self.counts = ayah_counts

    def span_tokens(self, surah, a, b):
        out = []
        for ayah in range(a, b + 1):
            out += self.tokens.get((surah, ayah), [])
        return out

    def score(self, quote, surah, a, b):
        return best_run(norm(quote).split(), self.span_tokens(surah, a, b))

    def find(self, quote, surah):
        """Verses of the surah holding the whole quotation; failing that,
        verses where it starts and runs into the next verse."""
        last = self.counts[surah]
        hits = [a for a in range(1, last + 1) if self.score(quote, surah, a, a) == 1.0]
        if not hits:
            hits = [a for a in range(1, last) if self.score(quote, surah, a, a + 1) == 1.0]
        return hits


def suggest_links(entry, verses):
    """Returns ([link], [note]) for one entry. Links rest on the book's own
    markers; nothing here touches the entry's text."""
    if not entry['surah']:
        return [], []
    surah = entry['surah']
    count = verses.counts[surah]
    if entry['kind'] == 'surah_intro':
        # Text under the surah heading before the first passage: about the
        # whole surah, unless it is only the basmala.
        if norm(entry['text']) == norm('بسم الله الرحمن الرحيم'):
            return [], []
        return [{'surah': surah, 'ayah_from': 1, 'ayah_to': count, 'quote': None,
                 'basis': 'marker', 'confidence': 0.5}], [
            'text under the surah heading: linked to the whole surah']
    if entry['kind'] != 'passage':
        return [], []
    quote, numbers = parse_header(entry['header'])
    notes = []
    if numbers and not (1 <= numbers[0] <= numbers[1] <= count):
        notes.append(f'verse number {numbers} is outside surah {surah} (1-{count})')
        numbers = None

    def link(a, b, basis, conf, at=surah):
        return {'surah': at, 'ayah_from': a, 'ayah_to': b, 'quote': quote,
                'basis': basis, 'confidence': conf}

    if numbers:
        a, b = numbers
        if not quote:
            return [link(a, b, 'marker', 0.6)], notes
        s = verses.score(quote, surah, a, min(b + 1, count))
        if s >= 0.9:
            return [link(a, b, 'marker+quote', 0.95)], notes
        if s >= 0.75:
            notes.append(f'quotation matches {surah}:{a}-{b} at {s:.2f} (spelling differs)')
            return [link(a, b, 'marker+quote', 0.85)], notes
        hits = verses.find(quote, surah)
        if len(hits) == 1:
            notes.append(f'book prints {surah}:{a}-{b}; quotation found in {surah}:{hits[0]}')
            return [link(hits[0], hits[0], 'quote', 0.6)], notes
        elsewhere = find_nearby(verses, quote, surah, a)
        if elsewhere:
            notes.append(f'quotation not in surah {surah}; found at {elsewhere[0]}:{elsewhere[1]} '
                         '(a surah heading may be missing in the source)')
            return [link(elsewhere[1], elsewhere[1], 'quote', 0.5, at=elsewhere[0])], notes
        notes.append(f'quotation matches {surah}:{a}-{b} at {s:.2f}')
        return [link(a, b, 'marker', 0.5 if s >= 0.5 else 0.3)], notes
    if quote:
        hits = verses.find(quote, surah)
        if len(hits) == 1:
            return [link(hits[0], hits[0], 'quote', 0.75)], notes
        if hits:
            notes.append(f'quotation found in {len(hits)} verses of surah {surah}: {hits}')
            return [link(hits[0], hits[0], 'quote', 0.4)], notes
        elsewhere = find_nearby(verses, quote, surah, None)
        if elsewhere:
            notes.append(f'quotation not in surah {surah}; found at {elsewhere[0]}:{elsewhere[1]}')
            return [link(elsewhere[1], elsewhere[1], 'quote', 0.4, at=elsewhere[0])], notes
    notes.append('no verse number and the quotation was not found')
    return [], notes


def find_nearby(verses, quote, surah, number):
    """The quotation in one of the next two surahs (where the source lost a
    surah heading), preferring the verse number the book prints."""
    for other in (surah + 1, surah + 2):
        if other > 114:
            break
        hits = verses.find(quote, other)
        if number in hits:
            return other, number
        if len(hits) == 1:
            return other, hits[0]
    return None


# ---------------------------------------------------------------- main

def load_source():
    manifest = json.loads((ROOT / 'sources.json').read_text(encoding='utf-8'))
    source = next(s for s in manifest['sources'] if s['id'] == SOURCE_ID)
    if fetch_sources.main({SOURCE_ID}) != 0:
        raise SystemExit(f'{SOURCE_ID}: SHA-256 mismatch, refusing to import')
    return source, fetch_sources.CACHE / source['file']


def build(out, content_db, path, source):
    import sqlite3
    raw = path.read_text(encoding='utf-8')
    meta, events = parse_openiti(raw)
    for key, field in (('040.EdEDITOR', 'tahqiq'), ('043.EdPUBLISHER', 'publisher')):
        if meta.get(key) and meta[key].replace(' ', '') != SOURCE_ROW[field].replace(' ', ''):
            raise SystemExit(f'edition metadata changed: {key} = {meta[key]}')

    content = sqlite3.connect(f'file:{content_db}?mode=ro', uri=True)
    names = dict(content.execute('SELECT id, name_ar FROM surah'))
    counts = dict(content.execute('SELECT id, ayah_count FROM surah'))
    verses = Verses(content.execute(
        'SELECT surah, number, text_search, search_basmala_prefix FROM ayah'), counts)
    content.close()

    resolve = surah_resolver(names)
    unresolved = [v for k, v in events
                  if k == 'heading' and SURAH_HEADING.match(v) and resolve(v) is None]
    if unresolved:
        raise SystemExit(f'surah headings not resolved: {unresolved}')
    entries = split_entries(events, resolve)
    check_verbatim(raw, entries)

    db = review_db.create(out, content_db)
    row = dict(SOURCE_ROW, url=source['url'], file=source['file'], sha256=source['sha256'],
               retrieved_at=review_db.now()[:10],
               notes='OpenITI cleaned version: the editor\'s footnotes were removed by OpenITI; '
                     'footnote numbers such as (1) remain in the text as printed.')
    source_id = review_db.add_source(db, row)
    stats = {'entries': 0, 'passage': 0, 'linked': 0, 'by_basis': {}, 'by_confidence': {}}
    for e in entries:
        links, notes = suggest_links(e, verses)
        e['notes'] = notes
        review_db.add_draft(db, source_id, row['key'], e, links, SCRIPT)
        stats['entries'] += 1
        stats['passage'] += e['kind'] == 'passage'
        if links:
            stats['linked'] += 1
            l = links[0]
            stats['by_basis'][l['basis']] = stats['by_basis'].get(l['basis'], 0) + 1
            stats['by_confidence'][l['confidence']] = stats['by_confidence'].get(l['confidence'], 0) + 1
    db.execute("INSERT INTO meta VALUES ('import_stats', ?)", (json.dumps(stats, sort_keys=True),))
    db.commit()
    db.close()
    return stats


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--out', type=Path, default=DEFAULT_OUT)
    ap.add_argument('--content-db', type=Path, default=CONTENT_DB)
    args = ap.parse_args(argv)
    source, path = load_source()
    stats = build(args.out, args.content_db, path, source)
    print(json.dumps(stats, ensure_ascii=False, sort_keys=True, indent=1))
    return 0


if __name__ == '__main__':
    sys.exit(main())
