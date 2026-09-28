"""Build the downloadable page pack for the new Madina edition (Hafs, 1441H).

Takes the 604 page SVGs from the quran-ws release, unchanged, compresses
each one on its own with xz, and writes a stored (uncompressed) zip with a
manifest listing every page's SHA-256. The app downloads this pack once,
keeps the .xz files on the device (about 65 MB instead of 357 MB) and
decompresses a page when it is shown.

The page artwork is not modified in any way.

Input:  tools/.cache/hafs-kfqc-svg.zip   (quran-ws/quran-svg v1.1.1)
Output: tools/out/pages-hafs-1441-v1.zip
Usage:  python3 tools/build_page_pack.py
"""
import hashlib
import json
import lzma
import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SRC = ROOT / '.cache' / 'hafs-kfqc-svg.zip'
OUT_DIR = ROOT / 'out'
PACK_ID = 'pages-hafs-1441-v1'


def main():
    OUT_DIR.mkdir(exist_ok=True)
    out = OUT_DIR / f'{PACK_ID}.zip'
    pages = []
    with zipfile.ZipFile(SRC) as src, zipfile.ZipFile(out, 'w', zipfile.ZIP_STORED) as dst:
        names = sorted(n for n in src.namelist() if re.fullmatch(r'svg/\d{3}\.svg', n))
        assert len(names) == 604, len(names)
        for name in names:
            svg = src.read(name)
            packed = lzma.compress(svg, preset=9 | lzma.PRESET_EXTREME)
            page = int(name[4:7])
            file_name = f'{page:03d}.svg.xz'
            dst.writestr(file_name, packed)
            pages.append({
                'page': page,
                'file': file_name,
                'svg_sha256': hashlib.sha256(svg).hexdigest(),
                'xz_sha256': hashlib.sha256(packed).hexdigest(),
                'xz_bytes': len(packed),
            })
        manifest = {
            'id': PACK_ID,
            'edition': 'madina-1441-hafs',
            'pages': 604,
            'viewBox': [345, 550],
            'firstPagesViewBox': [235, 235],
            'source': 'quran-ws/quran-svg v1.1.1 (hafs-kfqc-svg.zip), artwork unchanged',
            'source_sha256': hashlib.sha256(SRC.read_bytes()).hexdigest(),
            'license': 'Page artwork: King Fahd Glorious Quran Printing Complex '
                       '(free use in software, see docs/licenses). Layer: quran-ws, '
                       'CC BY 4.0 with attribution waived in products.',
            'files': pages,
        }
        dst.writestr('manifest.json', json.dumps(manifest, ensure_ascii=False, indent=1))
    total = sum(p['xz_bytes'] for p in pages)
    print(f'{out.relative_to(ROOT.parent)}: {len(pages)} pages, '
          f'{total / 1e6:.1f} MB of pages, pack sha256 {hashlib.sha256(out.read_bytes()).hexdigest()}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
