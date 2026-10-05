"""Build the downloadable page packs of the riwaya editions: Warsh, Qalun,
al-Duri and Shu'bah, each the KFGQPC Madina mushaf of that riwaya.

Each pack holds:
  NNN.svg.xz     the 604 page SVGs from quran-ws/quran-svg v1.1.1, unchanged
                 (the KFGQPC page artwork), each xz-compressed on its own
  riwaya.json.xz the riwaya's verses and page geometry (below)
  words.json.xz  the boxes of the words on the pages (below)
  <font>.ttf     the riwaya's KFGQPC font, unchanged (catchwords)
  manifest.json  every file's SHA-256 (of the stored bytes)

riwaya.json:
  verses   [surah, ayah, page, juz, hafs_from, hafs_to, text] in mushaf order.
           Numbering and page as printed (quran-ws outlines, checked against
           KFGQPC). juz and text: the KFGQPC riwaya file, verbatim. hafs_from
           .. hafs_to: the Hafs verses (same surah) it covers, worked out from
           the KFGQPC riwaya and Hafs texts and checked against Quranpedia
           (tools/verify_riwayat.py); 0, 0 when none.
  surahs   [verses, start page] for surahs 1..114
  polygons [page, surah, ayah, outline, marker x, marker y] (quran-ws)
  cuts     {page: 14 cuts between the 15 lines}; overflow {page: [[line, outline]]}
           measured on the artwork like tools/build_line_cuts.py
  grid     [first line centre, line pitch], opening [ink box, body box] of
           pages 1-2, all in the page's units

words.json (tools/build_riwaya_word_boxes.py):
  verses   [surah, ayah, exact, word count, [[page, x0, y0, x1, y1] per
           word]] with boxes in tenths of the page's units, words as the
           verse text of riwaya.json splits at its spaces (verse number and
           ۞ left out). exact = 1 when every word matched its predicted
           letter groups. A verse is left out unless its words are exactly
           those of its text in riwaya.json.

Where the KFGQPC text file and the printed pages count a surah differently
(al-Duri, al-Mulk: 30 in the text file, 31 markers on the printed page),
that surah's verses, text and Hafs map come from Quranpedia, whose count
matches the printed page; the manifest lists such surahs.

Nothing in the artwork or the texts is modified.

Usage: python3 tools/build_riwaya_packs.py [warsh,qalun,...]
Output: tools/out/pages-<riwaya>-v2.zip
"""
import gzip
import hashlib
import json
import lzma
import re
import statistics
import sys
import zipfile

import build_line_cuts
import build_riwaya_word_boxes as W
import build_word_boxes as B
import riwayat as R

OUT_DIR = R.ROOT / 'out'
# 1: pages, riwaya.json and font. 2: also words.json. A new version is a
# new file name: apps that know the old SHA-256 keep downloading v1.
VERSION = 2


def measure_grid(z, names):
    """Median first line centre and pitch over pages with 15 clear lines."""
    firsts, pitches = [], []
    for name in names[2::7]:
        items, _ = B.read_page(z.read(name).decode())
        ys = sorted((b[1] + b[3]) / 2 for b, _ in items if b[3] - b[1] > 4)
        clusters = []
        for y in ys:
            if clusters and y - clusters[-1][-1] < 8:
                clusters[-1].append(y)
            else:
                clusters.append([y])
        centres = [statistics.median(c) for c in clusters if len(c) > 15]
        if len(centres) != 15:
            continue
        pitch = (centres[-1] - centres[0]) / 14
        firsts.append(centres[0])
        pitches.append(pitch)
    return round(statistics.median(firsts), 2), round(statistics.median(pitches), 3)


def opening_boxes(z, name, polygons):
    """Ink box of an opening page's text block, and the box of its verses."""
    items, _ = B.read_page(z.read(name).decode())
    xs0 = [b[0] for b, _ in items]
    ys0 = [b[1] for b, _ in items]
    xs1 = [b[2] for b, _ in items]
    ys1 = [b[3] for b, _ in items]
    ink = [min(xs0), min(ys0), max(xs1), max(ys1)]
    pts = []
    for d in polygons:
        for pair in d.split():
            x, y = pair.split(',')
            pts.append((float(x), float(y)))
    body = [min(p[0] for p in pts) - 4, min(p[1] for p in pts) - 4,
            max(p[0] for p in pts) + 4, max(p[1] for p in pts) + 4]
    return [round(v, 2) for v in ink], [round(v, 2) for v in body]


def word_boxes(riwaya, verses):
    """words.json: the word boxes of every verse whose words in the box
    build are exactly the words of its text in riwaya.json."""
    built = W.build(riwaya)
    keep, left_out = {}, []
    for s, a, *_, text in verses:
        entry = built.get((s, a))
        if entry and entry[1] == W.words_of(W.verse_tokens(text)):
            keep[(s, a)] = entry
        else:
            left_out.append([s, a])
    out = W.to_json(keep)
    out['left_out'] = left_out
    st = W.stats(riwaya, keep)
    print(f"{riwaya}: word boxes for {st['verses']} verses ({st['words']} words), "
          f"{st['exact']} exact ({st['exact_pct']}%); left out {left_out}")
    return out


def build(riwaya):
    spec = R.RIWAYAT[riwaya]
    pack_id = f'pages-{riwaya}-v{VERSION}'
    qws = R.qws_verses(riwaya)
    text = R.kfgqpc_text(riwaya)
    rows = {(r['sura_no'], r['aya_no']): r for r in R.kfgqpc_rows(riwaya)}
    hafs_map = R.hafs_map(riwaya)
    qws_counts, k_counts = R.counts(qws), R.counts(text)

    # Surahs where the text file and the printed page count differently.
    from_qp = [s for s in range(1, 115) if qws_counts[s] != k_counts[s]]
    qp_text = {}
    if from_qp:
        qp = R.quranpedia(riwaya)
        n = spec[4]
        d = json.load(gzip.open(R.RCACHE / 'quranpedia' / f'mushafs-{n}.json.gz'))['data']
        for s in d['surahs']:
            if s['id'] in from_qp:
                for a in s['ayahs']:
                    qp_text[(s['id'], a['number'])] = a['text']
        for s in from_qp:
            assert R.counts(k for k in qp if k[0] == s)[s] == qws_counts[s], s

    verses = []
    for key in sorted(qws):
        s, a = key
        if s in from_qp:
            hs = qp[key]['hafs']
            juz = qp[key]['juz']
            t = qp_text[key]
        else:
            hs = hafs_map[key]
            juz = rows[key]['jozz']
            t = text[key]
        verses.append([s, a, qws[key]['page'], juz, hs[0] if hs else 0, hs[-1] if hs else 0, t])

    words = word_boxes(riwaya, verses)

    surah_list = R.qws_surahs(riwaya)
    surahs = [[qws_counts[s], qws[(s, 1)]['page']] for s in range(1, 115)]
    for s in range(1, 115):
        assert surah_list[s]['ayahCount'] == qws_counts[s]

    polygons = []
    for (s, a), v in sorted(qws.items(), key=lambda kv: (kv[1]['page'], kv[0])):
        polygons.append([v['page'], s, a, v['polygon'], v['x'], v['y']])
        for page, poly, x, y in v['more']:
            polygons.append([page, s, a, poly, x, y])
    polygons.sort(key=lambda p: (p[0], p[1], p[2]))

    OUT_DIR.mkdir(exist_ok=True)
    out = OUT_DIR / f'{pack_id}.zip'
    svg_zip = R.RCACHE / f'{spec[0]}-kfqc-svg.zip'
    files = []
    with zipfile.ZipFile(svg_zip) as z:
        names = R.qws_svg_names(riwaya)
        assert len(names) == 604, len(names)
        grid = measure_grid(z, names)
        cuts, overflow = {}, {}
        for name in names[2:]:
            page = int(re.search(r'(\d{3})\.svg$', name).group(1))
            c, o = build_line_cuts.svg_page_cuts(z.read(name).decode(), *grid)
            cuts[page] = [round(v, 2) for v in c]
            if o:
                overflow[page] = [[line, d] for line, d in o]
        opening = [opening_boxes(z, names[i], [p[3] for p in polygons if p[0] == i + 1])
                   for i in (0, 1)]
        data = dict(
            id=riwaya, name_ar=spec[5], name_en=spec[6], pages=604,
            grid=list(grid), opening=opening, font=R.kfgqpc_font(riwaya)[0],
            surahs=surahs, verses=verses, polygons=polygons,
            cuts={str(k): v for k, v in cuts.items()},
            overflow={str(k): v for k, v in overflow.items()},
            text_from_quranpedia=from_qp,
        )
        with zipfile.ZipFile(out, 'w', zipfile.ZIP_STORED) as dst:
            for name in names:
                svg = z.read(name)
                packed = lzma.compress(svg, preset=9 | lzma.PRESET_EXTREME)
                page = int(re.search(r'(\d{3})\.svg$', name).group(1))
                file_name = f'{page:03d}.svg.xz'
                dst.writestr(file_name, packed)
                files.append(dict(page=page, file=file_name,
                                  svg_sha256=hashlib.sha256(svg).hexdigest(),
                                  xz_sha256=hashlib.sha256(packed).hexdigest(),
                                  xz_bytes=len(packed)))
            raw = json.dumps(data, ensure_ascii=False, separators=(',', ':')).encode()
            packed = lzma.compress(raw, preset=9 | lzma.PRESET_EXTREME)
            dst.writestr('riwaya.json.xz', packed)
            files.append(dict(file='riwaya.json.xz', json_sha256=hashlib.sha256(raw).hexdigest(),
                              xz_sha256=hashlib.sha256(packed).hexdigest(), xz_bytes=len(packed)))
            raw = json.dumps(words, ensure_ascii=False, separators=(',', ':')).encode()
            packed = lzma.compress(raw, preset=9 | lzma.PRESET_EXTREME)
            dst.writestr('words.json.xz', packed)
            files.append(dict(file='words.json.xz', json_sha256=hashlib.sha256(raw).hexdigest(),
                              xz_sha256=hashlib.sha256(packed).hexdigest(), xz_bytes=len(packed)))
            font_name, font = R.kfgqpc_font(riwaya)
            dst.writestr(font_name, font)
            # xz_sha256 is the SHA-256 of the stored bytes; the font is stored as is.
            files.append(dict(file=font_name, xz_sha256=hashlib.sha256(font).hexdigest(),
                              xz_bytes=len(font)))
            manifest = dict(
                id=pack_id, edition=f'madina-{riwaya}', riwaya=riwaya, pages=604,
                source=f'quran-ws/quran-svg v1.1.1 ({spec[0]}-kfqc-svg.zip, {spec[0]}-kfqc-json.zip), '
                       f'artwork unchanged; KFGQPC {spec[1]} (text and font, unchanged); '
                       'Quranpedia mushafs dump 2026-10-02 (map check'
                       + (f'; verses of surahs {from_qp}' if from_qp else '') + ')',
                source_sha256={
                    f'{spec[0]}-kfqc-svg.zip': R.sha256(svg_zip),
                    f'{spec[0]}-kfqc-json.zip': R.sha256(R.RCACHE / f'{spec[0]}-kfqc-json.zip'),
                    spec[1]: R.sha256(R.RCACHE / spec[1]),
                },
                license='Page artwork, text and font: King Fahd Glorious Quran Printing Complex '
                        '(free use in software; the font unmodified). Outlines: quran-ws, CC BY 4.0 '
                        'with attribution waived in products. See docs/DATA_SOURCES.md.',
                files=files,
            )
            dst.writestr('manifest.json', json.dumps(manifest, ensure_ascii=False, indent=1))
    digest = R.sha256(out)
    print(f'{out.name}: {out.stat().st_size} bytes, sha256 {digest}, grid {grid}, '
          f'verses {len(verses)}, polygons {len(polygons)}, overflow pages {len(overflow)}, '
          f'verses with word boxes {len(words["verses"])}')
    return out, digest


def main(argv):
    chosen = argv[0].split(',') if argv else list(R.RIWAYAT)
    for riwaya in chosen:
        build(riwaya)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
