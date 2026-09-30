"""Word study data for content.db: each word's root and lemma (Quranic
Arabic Corpus 0.4) and the entries of «الميسر في غريب القرآن» (Nuqayah).

Structure only. Nothing here writes, edits or fills in religious text:
  - The corpus is read as published. Its roots and lemmas are written in
    the corpus's extended Buckwalter transliteration; they are turned into
    Arabic letters with the corpus's own table
    (https://corpus.quran.com/java/buckwalter.jsp), letter for letter.
    Roots are spelled with spaces between letters, as the corpus shows
    them («ر ح م»).
  - The book's entries are copied verbatim: the phrase it explains (as it
    quotes it between ﴿ ﴾) and the explanation after it.

Word numbers are ours: the words of the KFGQPC text without the verse
number and without ۞, as word_box counts them. The corpus numbers words
over the Tanzil text; the two agree in all but a few verses, and only
verses whose word counts agree get corpus rows (the others are listed by
report()).

The book keys its entries by verse and quoted phrase. An entry is tied to
words only when its phrase, compared letter by letter without marks,
occurs exactly once in its verse; otherwise it stays on the verse (word
columns NULL) and the app shows it with the verse's meanings.

Inputs (tools/.cache/, see sources.json):
  quranic-corpus-morphology-0.4.txt   Quranic Arabic Corpus 0.4 (GPL, verbatim)
  nuqayah_almuyassar_gharib.json      fetch_gharib.py
  UthmanicHafs_v2-0.zip               KFGQPC Hafs 2.0 (our word numbering)

Usage:
  python3 tools/build_word_study.py     # prints the coverage report
"""
import json
import re
import sys
import unicodedata
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CACHE = ROOT / '.cache'
CORPUS = CACHE / 'quranic-corpus-morphology-0.4.txt'
GHARIB = CACHE / 'nuqayah_almuyassar_gharib.json'
KFGQPC = CACHE / 'UthmanicHafs_v2-0.zip'

HIZB = '۞'  # ۞, drawn in the text but not a word

# Extended Buckwalter transliteration of the Quranic Arabic Corpus
# (https://corpus.quran.com/java/buckwalter.jsp).
BUCKWALTER = {
    "'": 'ء', '>': 'أ', '&': 'ؤ', '<': 'إ', '}': 'ئ',
    'A': 'ا', 'b': 'ب', 'p': 'ة', 't': 'ت', 'v': 'ث',
    'j': 'ج', 'H': 'ح', 'x': 'خ', 'd': 'د', '*': 'ذ',
    'r': 'ر', 'z': 'ز', 's': 'س', '$': 'ش', 'S': 'ص',
    'D': 'ض', 'T': 'ط', 'Z': 'ظ', 'E': 'ع', 'g': 'غ',
    '_': 'ـ', 'f': 'ف', 'q': 'ق', 'k': 'ك', 'l': 'ل',
    'm': 'م', 'n': 'ن', 'h': 'ه', 'w': 'و', 'Y': 'ى',
    'y': 'ي', 'F': 'ً', 'N': 'ٌ', 'K': 'ٍ', 'a': 'َ',
    'u': 'ُ', 'i': 'ِ', '~': 'ّ', 'o': 'ْ', '^': 'ٓ',
    '#': 'ٔ', '`': 'ٰ', '{': 'ٱ', ':': 'ۜ', '@': '۟',
    '"': '۠', '[': 'ۢ', ';': 'ۣ', ',': 'ۥ', '.': 'ۦ',
    '!': 'ۨ', '-': '۪', '+': '۫', '%': '۬', ']': 'ۭ',
}
# In roots the corpus writes hamza as A and shows it as أ («س أ ل»).
ROOT_LETTERS = {**BUCKWALTER, 'A': 'أ'}

LINE = re.compile(r'\((\d+):(\d+):(\d+):(\d+)\)\t([^\t]*)\t([^\t]*)\t(.*)')


def arabic(text, table=BUCKWALTER):
    return ''.join(table[c] for c in text)


def root_arabic(root):
    """'rHm' -> 'ر ح م'."""
    return ' '.join(ROOT_LETTERS[c] for c in root)


def lemma_arabic(lemma):
    """The corpus numbers lemmas that share a spelling (rab~2); the number
    is not part of the word."""
    return arabic(re.sub(r'\d+$', '', lemma))


def read_corpus(path=CORPUS):
    """{(surah, ayah): {word: [(form, tag, {feature: value})]}} in order."""
    out = {}
    for line in path.read_text(encoding='utf-8').splitlines():
        m = LINE.fullmatch(line)
        if not m:
            continue
        s, a, w, _ = map(int, m.groups()[:4])
        feats = {}
        for f in m.group(7).split('|'):
            k, _, v = f.partition(':')
            feats.setdefault(k, v)
        out.setdefault((s, a), {}).setdefault(w, []).append((m.group(5), m.group(6), feats))
    return out


def read_words(path=KFGQPC):
    """{(surah, ayah): [words]} of the KFGQPC text, numbered as word_box."""
    with zipfile.ZipFile(path) as z:
        rows = json.loads(z.read('UthmanicHafs_v2-0 data/hafsData_v2-0.json'))
    return {(r['sura_no'], r['aya_no']):
            [t for t in re.split('[  ]', r['aya_text'])[:-1] if t and t != HIZB]
            for r in rows}


def word_root_rows(corpus, words):
    """[(surah, ayah, word, root, lemma, pos)] and the verses left out.
    A word takes the root, lemma and part of speech of its stem."""
    rows, skipped = [], []
    for key in sorted(words):
        segments = corpus.get(key, {})
        if len(segments) != len(words[key]):
            skipped.append((*key, len(segments), len(words[key])))
            continue
        for w in sorted(segments):
            stems = [(tag, f) for _, tag, f in segments[w] if 'STEM' in f]
            if not stems:
                continue
            tag, f = next(((t, f) for t, f in stems if 'ROOT' in f), stems[0])
            root = root_arabic(f['ROOT']) if 'ROOT' in f else None
            lemma = lemma_arabic(f['LEM']) if 'LEM' in f else None
            if root is None and lemma is None:
                continue
            rows.append((key[0], key[1], w, root, lemma, f.get('POS', tag)))
    return rows, skipped


# ------------------------------------------------------------ al-Muyassar fi Gharib

AR_DIGITS = str.maketrans('٠١٢٣٤٥٦٧٨٩', '0123456789')
ENTRY = re.compile(r'(?:([٠-٩]+)\s*-\s*)?﴿([^﴾]+)﴾\s*:\s*(.*)', re.S)


def parse_gharib(pages):
    """[(surah, ayah, order, phrase, text)] and lines that did not parse.
    Lines are "N- ﴿phrase﴾: text"; a line without N belongs to the verse
    of the line before it."""
    entries, odd = [], []
    for surah, start, count, data in pages:
        ayah = None
        for line in data.split('\n'):
            if not line.strip():
                continue
            m = ENTRY.fullmatch(line.strip())
            if not m:
                odd.append((surah, ayah, line))
                continue
            if m.group(1):
                ayah = int(m.group(1).translate(AR_DIGITS))
            if ayah is None or not start <= ayah < start + count:
                odd.append((surah, ayah, line))
                continue
            entries.append((surah, ayah, m.group(2), m.group(3)))
    order = {}
    out = []
    for surah, ayah, phrase, text in entries:
        n = order[(surah, ayah)] = order.get((surah, ayah), 0) + 1
        out.append((surah, ayah, n, phrase, text))
    return out, odd


FOLD = {'ٱ': 'ا', 'أ': 'ا', 'إ': 'ا', 'آ': 'ا',
        'ى': 'ي', 'ی': 'ي', 'ئ': 'ي', 'ؤ': 'و'}

# Letters joined to the front of a word that the book leaves out when it
# quotes it (وَٱلۡفُرۡقَانَ is quoted ﴿ٱلۡفُرۡقَانَ﴾).
PROCLITICS = {'و', 'ف', 'ب', 'ل', 'ك', 'س', 'وب', 'ول', 'وك', 'وس', 'فب', 'فل', 'فك', 'فس'}


def skeleton(word):
    """Letters only, for comparing spellings: marks, tatweel and small
    letters dropped; alif, ya, and hamza-seat forms folded."""
    out = []
    for c in unicodedata.normalize('NFC', word):
        if unicodedata.category(c) == 'Mn' or c in 'ـۥۦء':
            continue
        c = FOLD.get(c, c)
        if 'ء' <= c <= 'ي':
            out.append(c)
    return ''.join(out)


def locate(phrase, verse_words):
    """(first, last) word numbers where the phrase occurs, when it occurs
    exactly once in the verse; otherwise None. The letters of whole words
    are compared, spaces aside (the book writes أَوَ لَمۡ for أَوَلَمۡ);
    only when that finds nothing may the first word carry a joined
    و ف ب ل ك س that the quote leaves out."""
    target = ''.join(skeleton(t) for t in phrase.split())
    words = [skeleton(t) for t in verse_words]
    if not target:
        return None

    def spans(test, slack=0):
        found = []
        for i in range(len(words)):
            joined = ''
            for j in range(i, len(words)):
                joined += words[j]
                if len(joined) >= len(target) and test(joined):
                    found.append((i + 1, j + 1))
                    break
                if len(joined) >= len(target) + slack:
                    break
        return found

    hits = spans(lambda s: s == target)
    if not hits:
        hits = spans(lambda s: s.endswith(target) and s[:len(s) - len(target)] in PROCLITICS,
                     slack=2)
    return hits[0] if len(hits) == 1 else None


def gharib_rows(pages, words):
    """[(surah, ayah, ord, word_from, word_to, phrase, text)] and the lines
    that did not parse."""
    entries, odd = parse_gharib(pages)
    rows = []
    for surah, ayah, n, phrase, text in entries:
        span = locate(phrase, words[(surah, ayah)])
        rows.append((surah, ayah, n, *(span or (None, None)), phrase, text))
    return rows, odd


def build():
    """(word_root rows, skipped verses, gharib rows, odd lines)."""
    words = read_words()
    roots, skipped = word_root_rows(read_corpus(), words)
    pages = json.loads(GHARIB.read_text(encoding='utf-8'))['pages']
    gharib, odd = gharib_rows(pages, words)
    return roots, skipped, gharib, odd


def report(roots, skipped, gharib, odd):
    total = sum(1 for _ in read_words().values())
    print(f'corpus: {total - len(skipped)}/{total} verses mapped, '
          f'{len(roots)} words with a root or lemma, '
          f'{sum(1 for r in roots if r[3])} with a root')
    for s, a, theirs, ours in skipped:
        print(f'  skipped {s}:{a}: corpus {theirs} words, KFGQPC {ours}')
    tied = sum(1 for r in gharib if r[3] is not None)
    print(f'gharib: {len(gharib)} entries, {tied} tied to words, {len(gharib) - tied} on the verse only; '
          f'{len(odd)} lines not parsed')
    for s, a, line in odd[:20]:
        print(f'  odd {s}:{a}: {line[:80]}')


if __name__ == '__main__':
    report(*build())
    sys.exit(0)
