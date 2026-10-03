"""Waveform peaks and audio facts for the timing editor.

For each surah file of a recitation: reads the bytes the app plays (our
mirror first, then the source), and writes

  <out>/<slug>/NNN.bin   one byte per 10 ms: the loudest sample in it, 0..255
                         (mono, 8 kHz), for the editor's waveform
  data/timing/<slug>/audio.json
                         each file's duration (decoded samples), size and
                         SHA-256, so the checks know the length without audio

The editor draws the waveform from the .bin files (a whole surah of al-Baqarah
decoded in a phone's browser would need gigabytes). They are published under
https://tibyan.ahmedhelal.dev/timing/peaks/<slug>/.

Needs ffmpeg. Runs on Python 3.8 (the server's).

Usage:
  python3 tools/build_timing_peaks.py SLUG --out DIR [--audio-json PATH] [--surahs 1-114]
      [--local-root DIR]   read mirrored files from this directory (the
                           server's mirror/sources/recitations) instead of over HTTP
"""
import argparse
import hashlib
import json
import subprocess
import sys
import urllib.request
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DATA = ROOT.parent / 'data' / 'timing'
MIRROR = 'https://tibyan.ahmedhelal.dev/mirror/sources/recitations'
RATE = 8000
HOP = 80  # samples per peak: 10 ms


def surah_urls(folder_url, surah):
    """The mirror, then the source: `surahUrls` in recitation.dart."""
    if '{surah}' in folder_url:
        source = folder_url.replace('{surah}', str(surah))
    else:
        source = '%s%03d.mp3' % (folder_url, surah)
    path = '/' + source.split('://', 1)[1].split('/', 1)[1]
    return [MIRROR + path, source]


def fetch(urls, local_root=None):
    if local_root:
        path = Path(local_root) / urls[0][len(MIRROR) + 1:]
        if path.exists():
            return urls[0], path.read_bytes()
    last = None
    for url in urls:
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Tibyan timing peaks'})
            with urllib.request.urlopen(req, timeout=120) as r:
                return url, r.read()
        except Exception as e:  # noqa: BLE001 - try the next host
            last = e
    raise RuntimeError('no host served the file: %s' % last)


def peaks_of(mp3):
    """(peaks bytes, duration in ms) of one mp3, decoded by ffmpeg."""
    p = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', 'pipe:0', '-ac', '1', '-ar', str(RATE), '-f', 's16le', 'pipe:1'],
        input=mp3, stdout=subprocess.PIPE, check=True)
    try:
        import numpy as np
        pcm = np.frombuffer(p.stdout, dtype='<i2').astype(np.int32)
        samples = len(pcm)
        pad = (-samples) % HOP
        blocks = np.abs(np.concatenate([pcm, np.zeros(pad, np.int32)])).reshape(-1, HOP).max(axis=1)
        return bytes(np.minimum(255, blocks >> 7).astype(np.uint8)), samples * 1000 // RATE
    except ImportError:
        pass
    pcm = memoryview(p.stdout).cast('h')
    samples = len(pcm)
    out = bytearray()
    for i in range(0, samples, HOP):
        chunk = pcm[i:i + HOP]
        m = max(max(chunk), -min(chunk))
        out.append(min(255, m >> 7))
    return bytes(out), samples * 1000 // RATE


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('slug')
    ap.add_argument('--out', required=True)
    ap.add_argument('--audio-json')
    ap.add_argument('--reciters', default=str(DATA / 'reciters.json'))
    ap.add_argument('--surahs', default='1-114')
    ap.add_argument('--local-root')
    args = ap.parse_args()
    reciter = next(r for r in json.loads(Path(args.reciters).read_text(encoding='utf-8'))['reciters']
                   if r['slug'] == args.slug)
    a, b = (int(x) for x in args.surahs.split('-'))
    out = Path(args.out) / args.slug
    out.mkdir(parents=True, exist_ok=True)
    audio_path = Path(args.audio_json or DATA / args.slug / 'audio.json')
    files = {}
    if audio_path.exists():
        files = json.loads(audio_path.read_text(encoding='utf-8'))['files']
    for surah in range(a, b + 1):
        try:
            url, mp3 = fetch(surah_urls(reciter['folder_url'], surah), args.local_root)
        except RuntimeError as e:
            print('%s %03d: %s' % (args.slug, surah, e), flush=True)
            continue
        peaks, duration = peaks_of(mp3)
        (out / ('%03d.bin' % surah)).write_bytes(peaks)
        files['%03d' % surah] = {'duration_ms': duration, 'bytes': len(mp3),
                                 'sha256': hashlib.sha256(mp3).hexdigest(),
                                 'host': url.split('/')[2]}
        print('%s %03d: %d ms, %d bytes, from %s' % (args.slug, surah, duration, len(mp3), url), flush=True)
    doc = {'format': 1, 'measured': date.today().isoformat(), 'peaks_per_second': RATE // HOP,
           'files': {k: files[k] for k in sorted(files)}}
    audio_path.parent.mkdir(parents=True, exist_ok=True)
    lines = ['{', '  "format": 1,', '  "measured": %s,' % json.dumps(doc['measured']),
             '  "peaks_per_second": %d,' % doc['peaks_per_second'], '  "files": {']
    keys = list(doc['files'])
    for i, k in enumerate(keys):
        lines.append('    %s: %s%s' % (json.dumps(k), json.dumps(doc['files'][k]), ',' if i < len(keys) - 1 else ''))
    lines += ['  }', '}']
    audio_path.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    return 0


if __name__ == '__main__':
    sys.exit(main())
