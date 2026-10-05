"""Word boxes for the riwaya editions (Warsh, Qalun, al-Duri, Shu'bah),
derived from their page geometry the way build_word_boxes.py derives
them for Hafs.

Each riwaya's quran-ws page SVGs (the KFGQPC artwork of its Madina
mushaf) are split into pieces of joined letters, line by line and verse
by verse (build_word_boxes.page_segments). The riwaya's own KFGQPC text
says how many pieces each word has (letters such as ا د ذ ر ز و ے never
join the next one), and the riwaya's own KFGQPC font says how wide each
word is: build_word_boxes.align splits each verse's pieces into its words
from those two. Nothing in the artwork, the texts or the fonts is
changed; texts are only split at their spaces and fonts only measured.

Word widths are measured with HarfBuzz (uharfbuzz), which shapes Arabic
exactly as the browser does: on the Hafs font it gives the widths of
word_font_widths.json (measured in Chrome) for all 21,123 words, to
within 0.01%.

Words of a verse: its KFGQPC text split at spaces and no-break spaces,
without empty pieces and without the verse-number glyph at the end
(Warsh 16:123 has no space before it, Shu'bah 2:286 has Arabic-Indic
digits). ۞ is aligned like a piece but is not a word. The app splits a
verse of the pack in the same way (RiwayaData.words) and uses a verse's
boxes only when it gets the same number of words.

Where the printed pages count a surah's verses differently from the
text file (al-Duri, al-Mulk: 31 verse markers, 30 verses in the text
file), the one text verse that the page splits in two is found from the
geometry (the split whose piece counts fit best) and its words are
shared between the two printed verses by where their pieces lie: each
printed verse has its own outline, and a word never crosses one.
build_riwaya_packs.py then keeps those verses only if their words are
exactly those of the verse text in the pack.

Inputs:  tools/.cache/riwayat/<qws>-kfqc-svg.zip, <qws>-kfqc-json.zip and
         the KFGQPC riwaya zip (tools/fetch_sources.py), uharfbuzz
         (pip install uharfbuzz)
Usage:   python3 tools/build_riwaya_word_boxes.py [warsh,qalun,...]
             [--pages 1-50] [--out DIR]
         prints statistics; --out writes words-<riwaya>.json (the
         pack's words.json) into DIR. build_riwaya_packs.py puts
         words.json.xz into each pack.
"""
import json
import re
import statistics
import sys
import zipfile

import build_word_boxes as B
import riwayat as R

FORMAT = 1  # words.json format

_NUMBER = re.compile('[ﰀ-﷿]+$|^[٠-٩]+$')


def verse_tokens(text):
    """A verse's tokens for the alignment (۞ included), verbatim pieces of
    [text] split at its spaces, without the verse number."""
    tokens = [t for t in re.split('[  ]', text) if t]
    last = _NUMBER.sub('', tokens[-1])
    return tokens[:-1] + [last] if last else tokens[:-1]


def words_of(tokens):
    return [t for t in tokens if t != B.HIZB]


def font_widths(font_bytes, words):
    """{word: advance width at 100 px} in the given font (HarfBuzz)."""
    import uharfbuzz as hb
    face = hb.Face(font_bytes)
    font = hb.Font(face)
    out = {}
    for w in words:
        buf = hb.Buffer()
        buf.add_str(w)
        buf.guess_segment_properties()
        hb.shape(font, buf)
        out[w] = round(sum(p.x_advance for p in buf.glyph_positions) * 100 / face.upem, 2)
    return out


def _pieces(segs):
    return sum(len(pieces) for _, _, pieces, _ in segs)


def _predicted(tokens):
    return sum(B.predicted_pieces(t) for t in tokens)


def split_verse(surah, text_counts, printed_counts, text, by_verse):
    """For a surah whose printed verses number one more than the text
    file's: the text verse k (1-based) that is printed as verses k and
    k + 1, chosen where the printed piece counts fit the predicted ones
    best."""
    n, m = text_counts[surah], printed_counts[surah]
    assert m == n + 1, (surah, n, m)
    pieces = [_pieces(by_verse.get((surah, a), [])) for a in range(1, m + 1)]
    want = [_predicted(text[(surah, a)]) for a in range(1, n + 1)]
    best = None
    for k in range(1, n + 1):
        printed = pieces[:k - 1] + [pieces[k - 1] + pieces[k]] + pieces[k + 1:]
        cost = sum(abs(p - w) for p, w in zip(printed, want))
        if best is None or cost < best[0]:
            best = (cost, k)
    return best[1]


def build(riwaya, pages=range(1, 605)):
    """{(surah, ayah): (exact, words, [(word_no, page, x0, y0, x1, y1)])}
    in the printed numbering; words are the verse's words (۞ dropped)."""
    spec = R.RIWAYAT[riwaya]
    text = {k: verse_tokens(t) for k, t in R.kfgqpc_text(riwaya).items()}
    by_verse = B.page_verse_segments(R.RCACHE / f'{spec[0]}-kfqc-svg.zip', pages)
    font = R.kfgqpc_font(riwaya)[1]
    return derive(by_verse, text, R.counts(R.qws_verses(riwaya)),
                  lambda words: font_widths(font, words))


def derive(by_verse, text, printed_counts, widths):
    """The word boxes from the page segments of each printed verse
    ([by_verse], build_word_boxes.page_verse_segments), the text's tokens
    per verse, the printed verse counts per surah and [widths] (a function
    from a set of words to their font widths). See build()."""
    text_counts = R.counts(text)
    # Surahs counted differently: the text verse k that the page prints as
    # verses k and k + 1 is aligned against both together, as one.
    split = {s: split_verse(s, text_counts, printed_counts, text, by_verse)
             for s in printed_counts if printed_counts[s] != text_counts.get(s)}
    units, layout_text = {}, {}
    for verse in sorted(by_verse):  # a verse's segments before the next one's
        s, a = verse
        k = split.get(s)
        key = verse if k is None or a <= k else (s, a - 1)
        units.setdefault(key, []).extend(by_verse[verse])
        layout_text[key] = text[key]
    for segs in units.values():
        segs.sort(key=lambda g: (g[0], g[1]))
    seg_verse = {}  # id(pieces) -> printed verse
    for verse, segs in by_verse.items():
        for g in segs:
            seg_verse[id(g[2])] = verse

    fonts = widths({t for ts in layout_text.values() for t in ts})
    result = {}
    for _, tokens, segs, groups, exact, owner in B.layouts(
            text=layout_text, font_widths=fonts, by_verse=units):
        boxes = [None] * len(tokens)
        for page, _, _, cs in segs:
            for bbox, _ in cs:
                wi = owner[id(bbox)]
                cur = boxes[wi]
                boxes[wi] = (page, *bbox) if cur is None else (
                    page, min(cur[1], bbox[0]), min(cur[2], bbox[1]),
                    max(cur[3], bbox[2]), max(cur[4], bbox[3]))
        # A word's printed verse: the one whose outline holds its pieces.
        printed = [seg_verse[id(segs[si][2])] for si, _, _ in groups]
        for token, box, verse in zip(tokens, boxes, printed):
            if token == B.HIZB:
                continue
            _, ws, bs = result.setdefault(verse, (exact, [], []))
            ws.append(token)
            bs.append((len(bs) + 1, *box))
    return result


def to_json(result):
    """The pack's words.json: boxes in tenths of the page's units."""
    verses = []
    for (s, a), (exact, words, boxes) in sorted(result.items()):
        verses.append([s, a, int(exact), len(words), [
            [page, round(x0 * 10), round(y0 * 10), round(x1 * 10), round(y1 * 10)]
            for _, page, x0, y0, x1, y1 in boxes]])
    return dict(format=FORMAT, units='tenths of the page viewBox units', verses=verses)


def stats(riwaya, result):
    n = len(result)
    exact = sum(e for e, _, _ in result.values())
    words = sum(len(w) for _, w, _ in result.values())
    widths = [b[4] - b[2] for _, _, bs in result.values() for b in bs]
    return dict(riwaya=riwaya, verses=n, words=words, exact=exact,
                exact_pct=round(100 * exact / n, 1),
                median_width=round(statistics.median(widths), 2))


def parse_pages(arg):
    a, _, b = arg.partition('-')
    return range(int(a), int(b or a) + 1)


def main(argv):
    pages = range(1, 605)
    out_dir = None
    if '--pages' in argv:
        i = argv.index('--pages')
        pages = parse_pages(argv[i + 1])
        del argv[i:i + 2]
    if '--out' in argv:
        i = argv.index('--out')
        from pathlib import Path
        out_dir = Path(argv[i + 1])
        del argv[i:i + 2]
    chosen = argv[0].split(',') if argv else list(R.RIWAYAT)
    for riwaya in chosen:
        result = build(riwaya, pages)
        st = stats(riwaya, result)
        print(f"{riwaya}: {st['verses']} verses, {st['words']} words, {st['exact']} verses "
              f"({st['exact_pct']}%) with every word matching its predicted pieces")
        if out_dir:
            out_dir.mkdir(parents=True, exist_ok=True)
            path = out_dir / f'words-{riwaya}.json'
            path.write_text(json.dumps(to_json(result), separators=(',', ':')), encoding='utf-8')
            print(f'  -> {path}')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
