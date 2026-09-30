"""Download «الميسر في غريب القرآن» from Nuqayah's reader (read.tafsir.one).

Nuqayah granted written permission for this book (no ads, no profit);
see docs/licenses/2026-09-28_nuqayah_permission_email.pdf. «السراج» is
not covered and is not downloaded.

The reader loads the book one mushaf page at a time:
  https://read.tafsir.one/get.php?uth&src=almuyassar-g&s=S&a=A
returns the page holding verse S:A as JSON: "ayahs_start" (first verse of
the page, within surah S), "ayahs" (the verses on it, in Nuqayah's text)
and "data" (the book's entries for those verses). A page with a single
verse has only "ayah" and "data". This script walks each
surah page by page and keeps "ayahs_start", the verse count and "data"
exactly as served. The Quran text in "ayahs" is not kept: the app shows
the KFGQPC text.

Usage:
  python3 tools/fetch_gharib.py

Writes tools/.cache/nuqayah_almuyassar_gharib.json:
  {"source": URL template, "pages": [[surah, ayahs_start, ayah_count, data], ...]}
"""
import json
import sys
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OUT = ROOT / '.cache' / 'nuqayah_almuyassar_gharib.json'
API = 'https://read.tafsir.one/get.php?uth&src=almuyassar-g&s={surah}&a={ayah}'
META = ROOT / '.cache' / 'quran-data.xml'


def fetch(url):
    for attempt in range(5):
        try:
            request = urllib.request.Request(url, headers={'User-Agent': 'tibyan-tools/0.1'})
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.loads(response.read())
        except Exception:
            if attempt == 4:
                raise
            time.sleep(2 * (attempt + 1))


def verse_counts():
    import xml.etree.ElementTree as ET
    return {int(s.get('index')): int(s.get('ayas'))
            for s in ET.parse(META).getroot().find('suras')}


def main():
    pages = []
    for surah, count in sorted(verse_counts().items()):
        ayah = 1
        while ayah <= count:
            r = fetch(API.format(surah=surah, ayah=ayah))
            if 'ayahs' in r:
                start, n = int(r['ayahs_start']), len(r['ayahs'])
            else:  # a page holding one verse only (e.g. 2:282) has just "ayah"
                start, n = ayah, 1
            assert start <= ayah < start + n, (surah, ayah, start, n)
            pages.append([surah, start, n, r['data']])
            ayah = start + n
            time.sleep(0.1)
        print(f'surah {surah}: {count} verses', flush=True)
    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text(json.dumps({'source': API, 'pages': pages}, ensure_ascii=False,
                              separators=(',', ':')), encoding='utf-8')
    print(f'{len(pages)} pages -> {OUT}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
