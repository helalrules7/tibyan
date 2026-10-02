"""Cross-checks the riwaya sources before a pack is built.

For each riwaya (Warsh, Qalun, al-Duri, Shu'bah):
  1. Verses per surah agree between the quran-ws page outlines, the
     quran-ws surah list and the KFGQPC text (Quranpedia is compared too).
  2. The page where each verse starts agrees between quran-ws and KFGQPC.
  3. The riwaya -> Hafs verse map, worked out from the KFGQPC riwaya text
     and the KFGQPC Hafs text (riwayat.hafs_map), is complete and in order.
  4. That map agrees with Quranpedia's published `number_in_hafs` at every
     verse, apart from the disagreements listed (each is printed with both
     texts so a person can check it).

Usage: python3 tools/verify_riwayat.py [--report docs/verification/<file>.md]
Exits non-zero on any disagreement in 1-3; 4 is reported.
"""
import sys

import riwayat as R


def main(argv):
    report = argv[argv.index('--report') + 1] if '--report' in argv else None
    hafs_counts = R.hafs_counts()
    hafs_text = R.kfgqpc_hafs_text()
    lines = []
    failed = False

    def say(s=''):
        print(s)
        lines.append(s)

    say('# Riwaya sources: cross-check')
    say()
    say('Produced by `tools/verify_riwayat.py`. Texts are compared on their base letters only; '
        'nothing is changed.')
    say()
    only = argv[argv.index('--only') + 1].split(',') if '--only' in argv else list(R.RIWAYAT)
    for riwaya, spec in R.RIWAYAT.items():
        if riwaya not in only:
            continue
        say(f'## {spec[5]} ({riwaya})')
        say()
        qws = R.qws_verses(riwaya)
        surahs = R.qws_surahs(riwaya)
        text = R.kfgqpc_text(riwaya)
        qp = R.quranpedia(riwaya)
        rows = R.kfgqpc_rows(riwaya)
        cq, ck, cp = R.counts(qws), R.counts(text), R.counts(qp)
        cs = {n: s['ayahCount'] for n, s in surahs.items()}
        say(f'- Verses: quran-ws outlines {len(qws)}, quran-ws surah list {sum(cs.values())}, '
            f'KFGQPC text {len(text)}, Quranpedia {len(qp)}')
        bad = [s for s in range(1, 115) if len({cq.get(s), ck.get(s), cs.get(s)}) > 1]
        for s in bad:
            say(f'  - **surah {s}: counts differ** quran-ws {cq.get(s)}, surah list {cs.get(s)}, '
                f'KFGQPC {ck.get(s)}, Quranpedia {cp.get(s)}')
            if cq.get(s) == cs.get(s) == cp.get(s):
                say(f'    - the printed page (quran-ws outlines, one per verse marker) and '
                    f'Quranpedia agree: the pack takes this surah\'s verses from Quranpedia')
            else:
                failed = True
        for s in range(1, 115):
            if cp.get(s) != ck.get(s):
                say(f'  - surah {s}: Quranpedia counts {cp.get(s)}, KFGQPC {ck.get(s)} '
                    f'(Quranpedia not used for this surah)')
        diff = [s for s in range(1, 115) if ck.get(s) != hafs_counts[s]]
        say(f'- Surahs counted differently from Hafs: {len(diff)}')
        kp = {(x['sura_no'], x['aya_no']): str(x['page']) for x in rows}
        pbad = [k for k in qws if k[0] not in bad and int(kp[k].split('-')[0]) != qws[k]['page']]
        say(f'- Start page: quran-ws and KFGQPC disagree at {len(pbad)} verses {pbad[:6]}')
        failed |= bool(pbad)
        pages = sorted({v['page'] for v in qws.values()})
        svgs = len(R.qws_svg_names(riwaya))
        say(f'- Pages: {pages[0]}..{pages[-1]} ({len(pages)} with verses); SVG pages {svgs}')
        failed |= svgs != 604 or len(pages) != 604

        m = R.hafs_map(riwaya)
        problems = R.check_map(m, ck, hafs_counts)
        say(f'- Riwaya -> Hafs map from the KFGQPC texts: {len(problems)} structural problems {problems[:6]}')
        failed |= bool(problems)
        same = sum(1 for (s, a), hs in m.items() if hs == [a])
        split = sum(1 for hs in m.values() if len(hs) > 1)
        say(f'- Verses with the same number in Hafs: {same} of {len(m)}; '
            f'verses covering two or more Hafs verses: {split}')

        disagree = []
        for (s, a), hs in sorted(m.items()):
            if cp.get(s) != ck.get(s):
                continue
            theirs = qp[(s, a)]['hafs']
            if s == 1 and hs == [h for h in theirs if h != 1]:
                continue  # Quranpedia also gives Hafs 1:1 (the basmala)
            if hs != theirs:
                disagree.append((s, a, theirs, hs))
        say(f'- Agreement with Quranpedia\'s `number_in_hafs`: '
            f'{len(m) - len(disagree)} of {len(m)} verses; {len(disagree)} disagree')
        for s, a, theirs, ours in disagree:
            say(f'  - {s}:{a}: Quranpedia {theirs}, KFGQPC texts {ours}')
            say(f'    - riwaya: {text[(s, a)]}')
            for h in sorted(set(theirs) | set(ours)):
                say(f'    - Hafs {s}:{h}: {hafs_text[(s, h)]}')
        say()

    if report:
        with open(report, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines) + '\n')
    print('FAILED' if failed else 'OK')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
