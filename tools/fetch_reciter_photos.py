"""Fetch a licence-checked photo of each reciter from Wikimedia Commons.

Commons is the one source whose licence is written down with the file, so
the tool keeps only files under a licence that lets us ship them (public
domain, CC0, CC BY, CC BY-SA), records the file, its author, its licence
and its page, and writes the photo to `tools/photos/<id>.jpg` for
`tools/build_reciter_photos.py` to shrink.

Usage:
  python3 tools/fetch_reciter_photos.py [reciter id ...]
"""
import json
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

UA = 'tibyan-tools/0.1 (reciter photos; https://github.com/tibyan)'

ROOT = Path(__file__).resolve().parent
PHOTOS = ROOT / 'photos'
DB = ROOT.parent / 'assets' / 'db' / 'content.db'
API = 'https://commons.wikimedia.org/w/api.php'
OK = ('cc0', 'cc-by', 'cc by', 'public domain', 'pd-', 'attribution')
NAMES = {
    1: 'Muhammad Siddiq Al-Minshawi',
    2: 'Mahmoud Khalil Al-Husary',
    3: 'Abdul Basit Abdus Samad',
    4: 'Mahmoud Ali Al-Banna',
    5: 'Mustafa Ismail',
    10: 'Yasser Al-Dosari',
    11: 'Abdul Rahman Al-Sudais',
    12: 'Mishary Rashid Alafasy',
    13: 'Saad Al-Ghamdi',
    14: 'Mohamed Al-Tablawi',
}


def open_url(url, tries=6):
    # Commons answers 429 when asked too fast: go slowly and back off.
    for attempt in range(tries):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': UA})
            with urllib.request.urlopen(req, timeout=120) as r:
                time.sleep(1.5)
                return r.read()
        except urllib.error.HTTPError as e:
            if e.code != 429 or attempt == tries - 1:
                raise
            time.sleep(5 * (attempt + 1))
    raise RuntimeError(url)


def get(params):
    params['format'] = 'json'
    return json.loads(open_url(API + '?' + urllib.parse.urlencode(params)))


def search(name):
    d = get({'action': 'query', 'list': 'search', 'srsearch': name,
             'srnamespace': '6', 'srlimit': '8'})
    return [h['title'] for h in d.get('query', {}).get('search', [])]


def info(title):
    d = get({'action': 'query', 'titles': title, 'prop': 'imageinfo',
             'iiprop': 'url|extmetadata|mime', 'iiurlwidth': '512'})
    pages = d.get('query', {}).get('pages', {})
    for p in pages.values():
        ii = (p.get('imageinfo') or [{}])[0]
        meta = ii.get('extmetadata', {})
        return {
            'title': title,
            'thumb': ii.get('thumburl'),
            'mime': ii.get('mime', ''),
            'license': (meta.get('LicenseShortName', {}) or {}).get('value', ''),
            'artist': (meta.get('Artist', {}) or {}).get('value', ''),
            'page': ii.get('descriptionurl', ''),
        }
    return None


def main():
    PHOTOS.mkdir(exist_ok=True)
    ids = [int(a) for a in sys.argv[1:]] or sorted(NAMES)
    for rid in ids:
        name = NAMES.get(rid, '')
        found = None
        for title in search(name):
            if not title.lower().endswith(('.jpg', '.jpeg', '.png')):
                continue
            i = info(title)
            if i and any(k in i['license'].lower() for k in OK):
                found = i
                break
        if not found:
            print(f'{rid} {name}: no licensed photo found')
            continue
        out = PHOTOS / f'{rid}.jpg'
        out.write_bytes(open_url(found['thumb']))
        print(f'{rid} {name}: {out.name} <- {found["title"]} | '
              f'{found["license"]} | {found["page"]}')


if __name__ == '__main__':
    main()
