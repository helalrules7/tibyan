"""Arabic normalisation for training targets and WER/CER scoring.

Copied from the Tibyan model-evaluation spike (docs/recitation-model-
evaluation.md) so the runner scores exactly like that evaluation did.

Rules (applied to both reference and hypothesis):
  1. U+0670 (dagger alif) -> ا, then drop tashkeel and Quranic marks:
     U+0610-061A, U+064B-065F, U+06D6-06ED, U+08D3-08FF, tatweel U+0640.
  2. ٱ أ إ آ ٲ ٳ -> ا ; ى ی -> ي ; ة -> ه ; ؤ -> و ; ئ -> ي ; drop ء.
  3. Drop anything that is not an Arabic letter or a space (punctuation, digits, verse glyphs).
  4. Word-level Uthmani -> imla'i approximations (WORD_MAP) after the letter rules,
     plus a generic rule: 'وا' after ل/ي/ح/ك/ز endings written 'و' + dagger alif ("الصلوة" style -> 'ا').
These are approximations; they only need to make Tanzil Simple Clean (text_search)
and the models' outputs (Tarteel: imla'i with tashkeel; NVIDIA: imla'i with tashkeel) comparable.
"""
import re
import unicodedata

_MARKS = re.compile('[ؐ-ًؚ-ٟۖ-ۭ࣓-ࣿـ]')
_LETTER_MAP = str.maketrans({
    'ٱ': 'ا', 'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٲ': 'ا', 'ٳ': 'ا',
    'ى': 'ي', 'ی': 'ي', 'ة': 'ه', 'ؤ': 'و', 'ئ': 'ي', 'ء': '',
    'ہ': 'ه', 'ک': 'ك',
})
_NON_AR = re.compile('[^ء-ي ]')

# Uthmani spellings that survive the letter rules, mapped to the imla'i form (after rules).
WORD_MAP = {
    'الرحمان': 'الرحمن', 'رحمان': 'رحمن',
    'الصلواه': 'الصلاه', 'الصلوه': 'الصلاه', 'صلواه': 'صلاه',
    'الزكواه': 'الزكاه', 'الزكوه': 'الزكاه', 'الحيواه': 'الحياه', 'الحيوه': 'الحياه',
    'هاذا': 'هذا', 'هاذه': 'هذه', 'هاذان': 'هذان', 'ذالك': 'ذلك', 'ذالكم': 'ذلكم',
    'اولايك': 'اولئك', 'اوليك': 'اولئك', 'لاكن': 'لكن', 'لاكنه': 'لكنه',
    'السماوات': 'السماوات', 'السموات': 'السماوات', 'سماوات': 'سماوات', 'سموات': 'سماوات',
    'الاه': 'اله', 'الاها': 'الها', 'ابراهيم': 'ابراهيم', 'ابرهيم': 'ابراهيم',
    'يايها': 'يايها', 'ياايها': 'يايها', 'الملايكه': 'الملايكه', 'الملئكه': 'الملايكه',
    'داود': 'داود', 'شيا': 'شيا', 'شييا': 'شيا',
    'الانسان': 'الانسان', 'الانسن': 'الانسان',
    'طباقا': 'طباقا', 'طبقا': 'طباقا', 'تفاوت': 'تفاوت', 'تفوت': 'تفاوت',
    'الرحمان': 'الرحمن',
}


def norm_word(w: str) -> str:
    w = unicodedata.normalize('NFC', w)
    w = w.replace('ٰ', 'ا')
    w = _MARKS.sub('', w)
    w = w.translate(_LETTER_MAP)
    w = _NON_AR.sub('', w)
    # a stray hamza-on-alif mapped to alif can double it: "اا" -> "ا"
    w = re.sub('ا{2,}', 'ا', w)
    return WORD_MAP.get(w, w)


def norm_words(text: str) -> list[str]:
    text = unicodedata.normalize('NFC', text)
    text = re.sub('[۝ﰀ-﷿ﹰ-﻿\U000F0000-\U0010FFFF]', ' ', text)
    out = []
    for t in text.split():
        n = norm_word(t)
        if n:
            out.append(n)
    return out


def edit_ops(ref: list[str], hyp: list[str]):
    """Levenshtein on words. Returns (distance, subs, dels, ins)."""
    n, m = len(ref), len(hyp)
    d = [[0] * (m + 1) for _ in range(n + 1)]
    for i in range(n + 1):
        d[i][0] = i
    for j in range(m + 1):
        d[0][j] = j
    for i in range(1, n + 1):
        for j in range(1, m + 1):
            c = 0 if ref[i - 1] == hyp[j - 1] else 1
            d[i][j] = min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + c)
    # backtrack
    i, j, s, de, ins = n, m, 0, 0, 0
    while i > 0 or j > 0:
        if i > 0 and j > 0 and d[i][j] == d[i - 1][j - 1] + (0 if ref[i - 1] == hyp[j - 1] else 1):
            s += ref[i - 1] != hyp[j - 1]
            i, j = i - 1, j - 1
        elif i > 0 and d[i][j] == d[i - 1][j] + 1:
            de += 1
            i -= 1
        else:
            ins += 1
            j -= 1
    return d[n][m], s, de, ins


def norm_text(text: str) -> str:
    """Normalised words joined by single spaces (training target / scoring)."""
    return " ".join(norm_words(text))
