"""Import al-Damghani's «إصلاح الوجوه والنظائر» (قاموس القرآن) from OpenITI as review drafts.

Source: OpenITI 0478IbnMuhammadDamghani.QamusQuran.ShamAY0034085-ara1, the
corpus's only (and primary) copy, cleaned of paratext by OpenITI. Its
metadata names the edition: tahqiq ʿAbd al-ʿAzīz Sayyid al-Ahl, Dār al-ʿIlm
lil-Malāyīn, Beirut, 3rd ed. 1980. Pinned to an OpenITI commit in
tools/sources.json and checked by its SHA-256. The digitiser's note at
the top says pages 426-450 are missing.

The book is a list of words (by root, in chapters by letter). Each word
has a header («أب على أربعة أوجه»), the list of its senses, and then one
paragraph per sense («فوجه منها: …»، «الثاني: …») quoting the verses in
which the word carries that sense, usually after the surah's name
(«قوله تعالى في سورة الحج " ملة أبيكم إبراهيم "»).

What the script does (structure only, never the text):
  * splits the book at its own markers: chapter lines («باب الهمزة»), word
    headers («… على N أوجه»), and the sense openers («فوجه منها»، then the
    ordinals in sequence: الثاني، الثالث…). From about page 90 on, the
    digitisation lost most line breaks, so the markers are found inside
    running text as well;
  * removes OpenITI markup only (paragraph and line-wrap marks, milestones,
    page tags and the «@» page-break marks beside them), keeping every word
    as it is (checked word by word against the source), and records the
    page range from the page tags;
  * suggests links for each sense from the book's own references: the
    surah the book names, and the quotation after it, looked up in that
    surah of the Tanzil simple-clean text. Each link gets a confidence and
    its basis; quotations that are not found are noted, never guessed.

Everything lands as a draft. A person reviews every entry in apps/review/.

Usage:
  python3 tools/import_damghani_wujuh.py              # writes data/review/wujuh_damghani.review.db
  python3 tools/import_damghani_wujuh.py --out X.db   # elsewhere (must not exist)
"""
import argparse
import json
import re
import sys
from pathlib import Path

import fetch_sources
import review_db
from import_wahidi_asbab import ALIASES, best_run, check_verbatim, norm, parse_openiti, same_word

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent
SOURCE_ID = 'openiti-damghani-qamusquran-shamay0034085'
SCRIPT = 'script:import_damghani_wujuh@1'
DEFAULT_OUT = REPO / 'data' / 'review' / 'wujuh_damghani.review.db'
CONTENT_DB = REPO / 'assets' / 'db' / 'content.db'

SOURCE_ROW = {
    'key': 'wujuh_damghani_sayyid_al_ahl',
    'kind': 'wujuh_nazair',
    'title': 'قاموس القرآن أو إصلاح الوجوه والنظائر في القرآن الكريم',
    'author': 'الحسين بن محمد الدامغاني (ت 478هـ)',
    'edition': 'الثالثة، 1980م',
    'publisher': 'دار العلم للملايين - بيروت',
    'tahqiq': 'عبد العزيز سيد الأهل',
    'licence': 'OpenITI digitisation: CC BY-NC-SA 4.0 (digitisation only; '
               'the editor\'s rights in the printed edition are not covered)',
    'digitised_by': 'OpenITI (from al-Maktaba al-Shamela, ShamAY 34085), '
                    'GitHub OpenITI/0500AH @ fff9e217',
}

# ---------------------------------------------------------------- markup

# «@» beside a page tag (or alone at the end of a line) marks the page
# break in this Shamela conversion; it is not part of the book.
PAGE_MARK = re.compile(r'@(?=[ \t]*(?:PageV\d+P\d+|$))', re.M)


def strip_page_marks(raw):
    return PAGE_MARK.sub('', raw)


# ---------------------------------------------------------------- markers

COUNT_WORDS = {
    'اثنين', 'ثلاثة', 'ثلاث', 'أربعة', 'اربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية', 'تسعة',
    'عشرة', 'عشر', 'أحد', 'احد', 'إحدى', 'احدى', 'اثني', 'اثنى', 'اثنا', 'ثلاثة',
    'عشرين', 'ثلاثين', 'أربعين', 'وعشرين', 'وثلاثين',
}
FACE_WORDS = {'أوجه', 'اوجه', 'وجها', 'وجهين', 'وجهان', 'وجوه', 'أوجه:', 'وجهين:'}
ON = re.compile(r'^(?:\S*?)على$')  # «على», or fused: «وعلى»، «أعلى»
ROOT_TOKEN = re.compile(r'^(?:[ء-ي]{1,2}|\(?\d+\)?-?|\d+-)$')
# Two-letter words that are also common particles: a header made of one of
# these alone must start a paragraph or follow a chapter line.
PARTICLES = {'في', 'فى', 'هو', 'هي', 'لا', 'ما', 'أن', 'إن', 'ان', 'أو', 'او', 'لم', 'لن',
             'قد', 'به', 'له', 'عن', 'ثم', 'كل', 'إذ', 'إذا', 'يا', 'بل', 'لو', 'هم', 'من', 'أي', 'أى'}

UNITS = {'الثاني': 2, 'الثانى': 2, 'الثالث': 3, 'الرابع': 4, 'الخامس': 5, 'السادس': 6,
         'السابع': 7, 'الثامن': 8, 'التاسع': 9, 'العاشر': 10, 'الحادي': 1, 'الحادى': 1,
         'العشرون': 20}


def word(t):
    return t.strip(':،.')


def ordinal_at(tokens, i):
    """(value, length) when tokens[i:] start a sense ordinal, else None."""
    first = word(tokens[i])
    if first in ('فوجه', 'فالوجه') and i + 1 < len(tokens) and word(tokens[i + 1]) in ('منها', 'منهما', 'الأول', 'الاول'):
        return 1, 2
    if first in ('الأول', 'الاول'):
        return 1, 1
    if first not in UNITS:
        return None
    value, n = UNITS[first], 1
    nxt = word(tokens[i + 1]) if i + 1 < len(tokens) else ''
    if nxt == 'عشر':
        value, n = value % 10 + 10, 2
    elif nxt in ('والعشرون', 'والعشرين'):
        value, n = value % 10 + 20, 2
    elif first in ('الحادي', 'الحادى'):
        return None
    if value == 1:
        return None
    return value, n


def has_colon(tokens, i, n):
    """A colon right after the ordinal (attached or as the next token)."""
    last = tokens[i + n - 1]
    nxt = tokens[i + n] if i + n < len(tokens) else ''
    return last.endswith(':') or nxt.startswith(':')


def header_at(tokens, i, para_start, chapter_before):
    """When tokens[i] is the «على» of a word header («أب على أربعة أوجه»),
    returns (start, end) of the header, else None."""
    if not ON.match(tokens[i]):
        return None
    j = i + 1
    counts = 0
    while j < len(tokens) and counts < 3 and word(tokens[j]) in COUNT_WORDS:
        j += 1
        counts += 1
    if j >= len(tokens) or word(tokens[j]) not in FACE_WORDS:
        return None
    if word(tokens[j]) in ('أوجه', 'اوجه') and counts == 0:
        return None
    end = j + 1
    k = i - 1  # walk back over the root letters («أ ب»، «أخ وعلى»: fused with على)
    if k >= 0 and tokens[k] == ')':  # «2- ر ج ل ( رجال ) على»
        m = k
        while m >= 0 and tokens[m] != '(' and k - m < 5:
            m -= 1
        if m >= 0 and tokens[m] == '(':
            k = m - 1
    elif k >= 0 and tokens[k].startswith('ال') and len(tokens[k]) > 3 and k - 1 >= 0 \
            and ROOT_TOKEN.match(tokens[k - 1]):
        k -= 1  # «ج ن ح الجناح على»
    roots = 0
    while k >= 0 and ROOT_TOKEN.match(tokens[k]) and roots < 6:
        k -= 1
        roots += 1
    start = k + 1
    if roots == 0 and tokens[i] == 'على' and not (para_start(start) or chapter_before(start)):
        return None
    if roots == 1 and tokens[start] in PARTICLES and not (para_start(start) or chapter_before(start)):
        return None
    return start, end


# ---------------------------------------------------------------- splitting

def tokenize(events):
    """Flat list of (word, page, paragraph index) from parsed events; the
    book's text only (the CHECK headings are OpenITI's, not the book's)."""
    out = []
    para = 0
    for kind, value in events:
        if kind == 'heading':
            continue
        para += 1
        for text, page in value:
            for w in text.split():
                out.append((w, page, para))
    return out


def split_entries(events):
    """Returns entries: dicts with seq, kind (front_matter, chapter, word,
    wajh), section (the word's header), header, ordinal, volume, page,
    page_end, text (paragraph breaks kept), notes."""
    toks = tokenize(events)
    words = [t[0] for t in toks]
    paras = [t[2] for t in toks]

    def para_start(i):
        return i == 0 or paras[i] != paras[i - 1]

    def chapter_at(i):
        """Length of a chapter line («باب الهمزة»، «باب الجيم والحاء») at i."""
        if i >= len(words) or words[i] != 'باب':
            return 0
        n = 1
        while i + n < len(words) and n < 4 and re.match(r'^و?ال[ء-ي]+$', words[i + n]) \
                and not ON.match(words[i + n]):
            n += 1
        return n if n > 1 else 0

    def chapter_before(i):
        for n in (2, 3, 4):
            if i - n >= 0 and chapter_at(i - n) == n:
                return True
        return False

    # cut points: (index, kind, info)
    cuts = []
    i = 0
    expected = None  # next sense ordinal inside the current word
    while i < len(words):
        h = header_at(words, i, para_start, chapter_before) if 'على' in words[i] else None
        if h:
            start, end = h
            for n in (2, 3, 4):
                if start - n >= 0 and chapter_at(start - n) == n:
                    cuts.append((start - n, 'chapter', None))
                    break
            # drop sense cuts that the header start overtakes
            while cuts and cuts[-1][0] >= start and cuts[-1][1] == 'wajh':
                cuts.pop()
            cuts.append((start, 'word', ' '.join(words[start:end])))
            expected = 1
            i = end
            continue
        if expected is not None:
            o = ordinal_at(words, i)
            # the next ordinal in sequence; one skipped only with a colon or
            # at a paragraph start
            if o and (o[0] == expected or (o[0] == expected + 1 and expected > 1
                                            and (has_colon(words, i, o[1]) or para_start(i)))):
                cuts.append((i, 'wajh', o[0]))
                expected = o[0] + 1
                i += o[1]
                continue
        n = chapter_at(i)
        if n and para_start(i):
            cuts.append((i, 'chapter', None))
            i += n
            continue
        i += 1

    entries = []
    bounds = [c[0] for c in cuts] + [len(words)]
    if cuts and cuts[0][0] > 0:
        cuts.insert(0, (0, 'front_matter', None))
        bounds.insert(0, 0)
    elif not cuts:
        cuts, bounds = [(0, 'front_matter', None)], [0, len(words)]
    section = None
    for (start, kind, info), end in zip(cuts, bounds[1:]):
        if start == end:
            continue
        if kind == 'word':
            section = info
        text, prev = [], None
        for w, _, p in toks[start:end]:
            if prev is not None and p != prev:
                text.append('\n')
            elif prev is not None:
                text.append(' ')
            text.append(w)
            prev = p
        pages = [t[1] for t in toks[start:end] if t[1]]
        entries.append({
            'kind': kind,
            'section': section if kind in ('word', 'wajh') else (
                ' '.join(words[start:end]) if kind == 'chapter' else None),
            'header': info if kind == 'word' else None,
            'ordinal': info if kind == 'wajh' else None,
            'volume': pages[0][0] if pages else None,
            'page': pages[0][1] if pages else None,
            'page_end': pages[-1][1] if pages else None,
            'text': ''.join(text),
        })
    for seq, e in enumerate(entries, 1):
        e['seq'] = seq
    return entries


# ---------------------------------------------------------------- linking

ANALYSIS_TOKEN = re.compile(r'\(\(|\)\)|"|[^\s"()]+|[()]')
OPEN = {'"': '"', '((': '))', '(': ')'}
SKIP_BEFORE_QUOTE = {'قوله', 'تعالى', 'وقوله', 'سبحانه'}

EXTRA_ALIASES = {
    'حم المؤمن': 40, 'حم عسق': 42, 'حم الزخرف': 43, 'حم الدخان': 44, 'حم الجاثية': 45,
    'حم الأحقاف': 46, 'المنافقين': 63, 'التطفيف': 83, 'المطففين': 83, 'النبأ': 78,
    'سبأ': 34, 'الانفطار': 82, 'الانشقاق': 84, 'الحاقة': 69, 'السجدة': 32,
}


class Quran:
    """Tanzil simple-clean tokens per verse (comparison only)."""

    def __init__(self, rows, names):
        self.tokens = {}
        self.by_surah = {}
        for surah, ayah, text, prefix in rows:
            toks = [skeleton(t) for t in norm(text[prefix:]).split()]
            self.tokens[(surah, ayah)] = toks
            self.by_surah.setdefault(surah, []).append(ayah)
        table = {norm(n): s for s, n in names.items()}
        table.update({norm(k): v for k, v in ALIASES.items()})
        table.update({norm(k): v for k, v in EXTRA_ALIASES.items()})
        self.names = table

    def surahs_named(self, toks):
        """(surah, tokens used, exact) for the surah name at the start of
        toks: exact names (two words, then one) first; else the names one
        letter away, all of them (the quotation decides)."""
        for n in (2, 1):
            if len(toks) >= n and all(re.search(r'[ء-ي]', t) for t in toks[:n]):
                key = norm(' '.join(toks[:n]))
                for cand in (key, 'ال' + key, re.sub('^ال', '', key)):
                    if cand in self.names:
                        return [(self.names[cand], n, True)]
        if not toks:
            return []
        key = norm(toks[0])
        near = sorted({s for name, s in self.names.items()
                       if ' ' not in name and len(key) >= 3 and same_word(key, name)})
        return [(s, 1, False) for s in near]

    def locate(self, quote, surah):
        """Verses of the surah where the longest start of the quotation is
        found contiguously. Returns (matched length, [ayah])."""
        q = [skeleton(t) for t in norm(' '.join(quote)).split()]
        best, hits = 0, []
        for ayah in self.by_surah.get(surah, []):
            verse = self.tokens[(surah, ayah)]
            k = prefix_run(q, verse)
            if k > best:
                best, hits = k, [ayah]
            elif k == best and k:
                hits.append(ayah)
        return best, len(q), hits


def skeleton(t):
    return t.replace('ا', '') or t


def prefix_run(q, verse):
    """Longest k such that q[:k] appears contiguously in verse."""
    best = 0
    for j in range(len(verse)):
        k = 0
        while k < len(q) and j + k < len(verse) and same_word(q[k], verse[j + k]):
            k += 1
        best = max(best, k)
        if best == len(q):
            break
    return best


def references(text):
    """The book's references in a passage: [(name tokens, quote tokens,
    delimited)] for each «سورة <name> <quotation>»."""
    toks = ANALYSIS_TOKEN.findall(text)
    out = []
    for i, t in enumerate(toks):
        if t not in ('سورة', 'سوره'):
            continue
        rest = toks[i + 1:i + 60]
        out.append((i, rest))
    return toks, out


def split_quote(rest, used):
    """The quotation after a surah name: delimited text, or the words that
    follow (the verse search decides where it ends)."""
    j = used
    while j < len(rest) and rest[j] in SKIP_BEFORE_QUOTE:
        j += 1
    if j < len(rest) and rest[j] in OPEN:
        close = OPEN[rest[j]]
        k = j + 1
        while k < len(rest) and rest[k] != close and k - j < 45:
            k += 1
        words = [w for w in rest[j + 1:k] if re.search(r'[ء-ي]', w)]
        return words, True
    words = []
    for w in rest[j:j + 20]:
        if w in OPEN or w in OPEN.values() or w == 'سورة':
            break
        words.append(w)
    return words, False


def suggest_links(entry, quran):
    """Returns ([link], [note]) for one sense (or word) entry."""
    if entry['kind'] not in ('wajh', 'word'):
        return [], []
    links, notes = [], []
    toks, refs = references(entry['text'])
    seen = set()
    for _, rest in refs:
        cands = quran.surahs_named(rest)
        if not cands:
            notes.append(f'surah name not recognised: {" ".join(rest[:2])}')
            continue
        quote, delimited = split_quote(rest, cands[0][1])
        if not [w for w in quote if norm(w)]:
            continue  # «ومثلها في سورة النمل»: a reference without a quotation
        found = []
        for surah, used, exact in cands:
            k, n, hits = quran.locate(quote, surah)
            found.append((k, n, hits, surah, exact))
        k, n, hits, surah, exact = max(found, key=lambda f: f[0])
        tied = [f for f in found if f[0] == k and k]
        if not exact and len(tied) > 1:
            notes.append(f'surah name «{rest[0]}» is close to several names; not linked')
            continue
        if delimited and n and k == n:
            conf = 0.8
        elif delimited and k >= 3 and k >= 0.6 * n:
            conf = 0.6
        elif not delimited and k >= 4:
            conf = 0.6
        elif not delimited and k == 3:
            conf = 0.5
        else:
            if n >= 2:
                notes.append(f'quotation after «سورة {" ".join(rest[:cands[0][1]])}» not found there: '
                             f'{" ".join(quote[:6])}')
            continue
        matched = ' '.join(quote[:k] if not delimited else quote)
        if not exact:
            conf = min(conf, 0.5)
            notes.append(f'surah name «{rest[0]}» read as surah {surah} (the quotation is there)')
        if len(hits) > 1:
            notes.append(f'«{matched}» is in {len(hits)} verses of surah {surah}: {hits[:8]}')
            conf = 0.4
        ayah = hits[0]
        if (surah, ayah) in seen:
            continue
        seen.add((surah, ayah))
        links.append({'surah': surah, 'ayah_from': ayah, 'ayah_to': ayah, 'quote': matched,
                      'basis': 'quote', 'confidence': conf})
    return links, notes


# ---------------------------------------------------------------- main

def load_source():
    manifest = json.loads((ROOT / 'sources.json').read_text(encoding='utf-8'))
    source = next(s for s in manifest['sources'] if s['id'] == SOURCE_ID)
    if fetch_sources.main({SOURCE_ID}) != 0:
        raise SystemExit(f'{SOURCE_ID}: SHA-256 mismatch, refusing to import')
    return source, fetch_sources.CACHE / source['file']


def load_quran(content_db):
    import sqlite3
    content = sqlite3.connect(f'file:{content_db}?mode=ro', uri=True)
    names = dict(content.execute('SELECT id, name_ar FROM surah'))
    quran = Quran(content.execute(
        'SELECT surah, number, text_search, search_basmala_prefix FROM ayah'), names)
    content.close()
    return quran


def build(out, content_db, path, source):
    raw = path.read_text(encoding='utf-8')
    text = strip_page_marks(raw)
    meta_ok = ('#META# المحقق: ' + SOURCE_ROW['tahqiq']) in raw and 'دار العلم للملايين' in raw
    if not meta_ok:
        raise SystemExit('edition metadata changed: check المحقق and دار النشر')
    _, events = parse_openiti(text)
    entries = split_entries(events)
    check_verbatim(text, entries)
    quran = load_quran(content_db)

    db = review_db.create(out, content_db)
    row = dict(SOURCE_ROW, url=source['url'], file=source['file'], sha256=source['sha256'],
               retrieved_at=review_db.now()[:10],
               notes='OpenITI cleaned version (paratext removed). The digitiser notes pages '
                     '426-450 are missing. From about page 90 the digitisation lost most line '
                     'breaks: word headers and sense openers were found inside running text, so '
                     'check each split. «@» page-break marks beside the page tags were removed '
                     'as markup.')
    source_id = review_db.add_source(db, row)
    stats = {'entries': 0, 'by_kind': {}, 'senses': 0, 'senses_linked': 0, 'senses_unlinked': 0,
             'words': 0, 'links': 0, 'by_confidence': {}, 'quotations_not_found': 0,
             'surah_names_not_recognised': 0}
    linked_verses = set()
    for e in entries:
        links, notes = suggest_links(e, quran)
        e['notes'] = notes
        review_db.add_draft(db, source_id, row['key'], e, links, SCRIPT)
        stats['entries'] += 1
        stats['by_kind'][e['kind']] = stats['by_kind'].get(e['kind'], 0) + 1
        if e['kind'] == 'wajh':
            stats['senses'] += 1
            stats['senses_linked' if links else 'senses_unlinked'] += 1
        stats['words'] += e['kind'] == 'word'
        stats['links'] += len(links)
        for l in links:
            c = str(l['confidence'])
            stats['by_confidence'][c] = stats['by_confidence'].get(c, 0) + 1
            linked_verses.add((l['surah'], l['ayah_from']))
        stats['quotations_not_found'] += sum(n.startswith('quotation after') for n in notes)
        stats['surah_names_not_recognised'] += sum(n.startswith('surah name not') for n in notes)
    stats['linked_verses'] = len(linked_verses)
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
