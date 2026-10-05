"""Shared helpers for staged sources: downloaded, verified and recorded,
but not shipped in the app (owner's decision 2026-10-05: stage while the
permission replies are pending, publish nothing until they arrive).

Everything lands in tools/.cache/staging/<source>/ (git-ignored). Each
directory gets a SHA256SUMS file (the `sha256sum -c` format) and a
manifest.json with the source URL, the retrieval date and the licence
status. Bodies are written exactly as served: no text is changed.
"""
import datetime
import hashlib
import json
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
STAGING = ROOT / '.cache' / 'staging'
USER_AGENT = 'tibyan-tools/0.1'

# Verses per surah (Hafs, Kufan count), the structure only. Used to walk
# the APIs verse by verse; the same numbers as Tanzil's quran-data.xml.
VERSE_COUNTS = (
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
    111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73,
    54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60,
    49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52,
    44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19,
    26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3,
    6, 3, 5, 4, 5, 6)


def verses():
    """Every (surah, ayah) in order."""
    for s, n in enumerate(VERSE_COUNTS, 1):
        for a in range(1, n + 1):
            yield s, a


def sha256_bytes(data):
    return hashlib.sha256(data).hexdigest()


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def get(url, tries=5, timeout=60):
    """The response body, as bytes, exactly as served."""
    for attempt in range(tries):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return r.read()
        except urllib.error.HTTPError:
            raise
        except Exception:
            if attempt == tries - 1:
                raise
            time.sleep(2 * (attempt + 1))


def head(url, timeout=60):
    """(status, headers dict) of a HEAD request; nothing is downloaded."""
    req = urllib.request.Request(url, method='HEAD', headers={'User-Agent': USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, {k.lower(): v for k, v in r.headers.items()}
    except urllib.error.HTTPError as e:
        return e.code, {k.lower(): v for k, v in (e.headers or {}).items()}


def head_record(url):
    status, h = head(url)
    return {'url': url, 'status': status,
            'content_type': h.get('content-type'),
            'content_length': int(h['content-length']) if h.get('content-length', '').isdigit() else None,
            'last_modified': h.get('last-modified'), 'etag': h.get('etag')}


def write_sums(directory):
    """Write SHA256SUMS for every file under directory (except itself and
    manifest.json, which records the sums' own hash)."""
    directory = Path(directory)
    lines = []
    for p in sorted(directory.rglob('*')):
        if p.is_file() and p.name not in ('SHA256SUMS', 'manifest.json'):
            lines.append(f'{sha256_file(p)}  {p.relative_to(directory).as_posix()}')
    (directory / 'SHA256SUMS').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    return sha256_file(directory / 'SHA256SUMS')


def write_manifest(directory, **fields):
    directory = Path(directory)
    fields.setdefault('retrieved', datetime.date.today().isoformat())
    fields['sha256sums'] = sha256_file(directory / 'SHA256SUMS')
    (directory / 'manifest.json').write_text(
        json.dumps(fields, ensure_ascii=False, indent=1, sort_keys=True) + '\n', encoding='utf-8')
