"""The riwaya recitations (Warsh, Qalun, al-Duri, Shu'bah) in content.db.

Called by build_content_db.py after the Hafs reciters. Also runs on its own
to add them to an already built content.db (it is idempotent):

  python3 tools/fetch_riwaya_timing.py      # mp3quran verse timings
  python3 tools/riwaya_reciters.py          # adds them to assets/db/content.db

Adds to content.db (schema 14):
  reciter.riwaya        TEXT NOT NULL DEFAULT 'hafs' (hafs | warsh | qalun | douri | shubah)
  reciter rows 101..    the riwaya recitations below (all murattal, mp3quran.net)
  ayah_timing rows      their verse timings as mp3quran publishes them, numbered by
                        the riwaya's own count; a surah whose timing does not have
                        exactly one row per verse of the printed riwaya mushaf
                        (quran-ws outlines) gets none and plays without highlighting
  source rows 40..43    mp3quran riwaya timings, quran-ws riwaya pages, the KFGQPC
                        riwaya texts and fonts, Quranpedia (verse map check)

Nothing here is religious text: only names, URLs and timings.
"""
import json
import sqlite3
import sys
from datetime import date
from pathlib import Path

import riwayat as R

ROOT = Path(__file__).resolve().parent
TIMING = ROOT / '.cache' / 'mp3quran_riwaya_timing.json'
SCHEMA_VERSION = 14

# (id, Arabic name, English name, riwaya, folder URL, mp3quran timing read or None).
# Names as mp3quran.net gives them. ids start at 101 and are never reused.
RIWAYA_RECITERS = [
    (101, 'محمود خليل الحصري', 'Mahmoud Khalil al-Husary', 'warsh',
     'https://server13.mp3quran.net/husr/Rewayat-Warsh-A-n-Nafi/', 120),
    (102, 'القارئ ياسين', 'al-Qari Yasin', 'warsh',
     'https://server11.mp3quran.net/qari/', 14),
    (103, 'العيون الكوشي', 'al-Oyoun al-Koushi', 'warsh',
     'https://server11.mp3quran.net/koshi/', 16),
    (104, 'عمر القزابري', 'Omar al-Qazabri', 'warsh',
     'https://server9.mp3quran.net/omar_warsh/', 80),
    (105, 'محمد سايد', 'Mohammad Sayed', 'warsh',
     'https://server16.mp3quran.net/m_sayed/Rewayat-Warsh-A-n-Nafi/', 134),
    (106, 'عبد الباسط عبد الصمد', 'Abdul Basit Abdul Samad', 'warsh',
     'https://server7.mp3quran.net/basit/Rewayat-Warsh-A-n-Nafi/', None),
    (111, 'محمود خليل الحصري', 'Mahmoud Khalil al-Husary', 'qalun',
     'https://server13.mp3quran.net/husr/Rewayat-Qalon-A-n-Nafi/', 270),
    (112, 'علي بن عبدالرحمن الحذيفي', 'Ali al-Hudhaifi', 'qalun',
     'https://server9.mp3quran.net/huthifi_qalon/', 75),
    (113, 'الدوكالي محمد العالم', 'al-Dokali Mohammad al-Alim', 'qalun',
     'https://server7.mp3quran.net/dokali/', 208),
    (121, 'محمود خليل الحصري', 'Mahmoud Khalil al-Husary', 'douri',
     'https://server13.mp3quran.net/husr/Rewayat-Aldori-A-n-Abi-Amr/', 269),
    (122, 'نورين محمد صديق', 'Noreen Mohammad Siddiq', 'douri',
     'https://server16.mp3quran.net/nourin_siddig/Rewayat-Aldori-A-n-Abi-Amr/', None),
    (123, 'الفاتح محمد الزبير', 'al-Fatih al-Zubair', 'douri',
     'https://server6.mp3quran.net/fateh/', None),
    (131, 'علي بن عبدالرحمن الحذيفي', 'Ali al-Hudhaifi', 'shubah',
     'https://server9.mp3quran.net/hthfi/Rewayat-Sho-bah-A-n-Asim/', 305),
    (132, 'أحمد ديبان', 'Ahmad Deban', 'shubah',
     'https://server16.mp3quran.net/deban/Rewayat-Sho-bah-A-n-Asim/', None),
]


def riwaya_counts():
    """Verses per surah of each riwaya's printed mushaf (quran-ws outlines)."""
    return {r: R.counts(R.qws_verses(r)) for r in R.RIWAYAT}


def timing_rows(timing, counts):
    rows, gaps = [], []
    for rid, _, _, riwaya, _, read in RIWAYA_RECITERS:
        if read is None:
            continue
        for surah, entries in timing[str(read)].items():
            surah = int(surah)
            numbers = [a for a, _, _ in entries if a > 0]
            if numbers != list(range(1, counts[riwaya][surah] + 1)):
                gaps.append((rid, surah))
                continue
            rows += [(rid, surah, a, start, end) for a, start, end in entries]
    return rows, gaps


def sources(today):
    sha = R.sha256
    rc = R.RCACHE
    return [
        (40, 'mp3quran-riwayat', 'Riwaya recitations and their verse timings',
         'mp3quran.net', None,
         'mp3quran.net general permission to copy any material or use any link',
         'https://mp3quran.net', 'تلاوات الروايات وتوقيت آياتها: mp3quran.net', None,
         sha(TIMING), today),
        (41, 'quran-ws-riwayat',
         "Quran SVG: KFGQPC page artwork and verse outlines of Warsh, Qalun, al-Duri, Shu'bah",
         'Quran.ws; page artwork: King Fahd Glorious Quran Printing Complex', '1.1.1',
         'CC BY 4.0 (attribution waived in products); artwork under KFGQPC terms',
         'https://github.com/quran-ws/quran-svg',
         'صفحات مصاحف الروايات: مجمع الملك فهد لطباعة المصحف الشريف', None,
         sha(rc / 'warsh-kfqc-json.zip'), today),
        (42, 'kfgqpc-riwayat',
         "KFGQPC Uthmanic texts and fonts of Warsh (2.1), Qalun (2.1), al-Duri (2.0), Shu'bah (2.0)",
         'King Fahd Glorious Quran Printing Complex', None,
         'KFGQPC: free use; fonts unmodified; permission for the texts requested (letter 2)',
         'https://qurancomplex.gov.sa/quran-dev/',
         'نصوص الروايات وخطوطها: مجمع الملك فهد لطباعة المصحف الشريف', None,
         sha(rc / 'UthmanicWarsh_v2-1.zip'), today),
        (43, 'quranpedia-mushafs', 'Riwaya verse numbers in Hafs (number_in_hafs), used to check the map',
         'Quranpedia (quranpedia.net)', '2026-10-02',
         'Free inside applications; republishing as a dataset requires credit and the version',
         'https://api.quranpedia.net/dumps/',
         'مطابقة أرقام آيات الروايات: الموسوعة القرآنية', None,
         sha(rc / 'quranpedia' / 'mushafs-4.json.gz'), today),
    ]


def apply(db, today=None):
    """Adds the riwaya column, sources, reciters and timings to [db]."""
    today = today or date.today().isoformat()
    cols = [r[1] for r in db.execute('PRAGMA table_info(reciter)')]
    if 'riwaya' not in cols:
        db.execute("ALTER TABLE reciter ADD COLUMN riwaya TEXT NOT NULL DEFAULT 'hafs'")
    ids = [r[0] for r in RIWAYA_RECITERS]
    marks = ','.join('?' * len(ids))
    db.execute(f'DELETE FROM ayah_timing WHERE reciter IN ({marks})', ids)
    db.execute(f'DELETE FROM reciter WHERE id IN ({marks})', ids)
    db.execute('DELETE FROM source WHERE id BETWEEN 40 AND 43')
    db.executemany('INSERT INTO source VALUES (?,?,?,?,?,?,?,?,?,?,?)', sources(today))
    db.executemany(
        'INSERT INTO reciter (id, name_ar, name_en, style, folder_url, source_id, riwaya) '
        'VALUES (?,?,?,?,?,?,?)',
        [(i, ar, en, 'murattal', url, 40, riwaya) for i, ar, en, riwaya, url, _ in RIWAYA_RECITERS])
    rows, gaps = timing_rows(json.loads(TIMING.read_text(encoding='utf-8')), riwaya_counts())
    db.executemany('INSERT INTO ayah_timing VALUES (?,?,?,?,?)', rows)
    for rid, surah in gaps:
        print(f'riwaya timing gap: reciter {rid}, surah {surah} (plays without highlighting)')
    return rows, gaps


def main():
    path = ROOT.parent / 'assets' / 'db' / 'content.db'
    db = sqlite3.connect(path)
    rows, gaps = apply(db)
    db.execute(f'PRAGMA user_version = {SCHEMA_VERSION}')
    db.execute("UPDATE meta SET value = ? WHERE key = 'schema_version'", (str(SCHEMA_VERSION),))
    db.commit()
    db.execute('VACUUM')
    db.close()
    print(f'{path.name}: {len(RIWAYA_RECITERS)} riwaya reciters, {len(rows)} timing rows, '
          f'{len(gaps)} surahs without timing')
    return 0


if __name__ == '__main__':
    sys.exit(main())
