"""Measures each word of the KFGQPC text in the KFGQPC Hafs font, for
build_word_boxes.py (expected relative word widths).

Uses headless Google Chrome (canvas measureText) so Arabic shaping is
exact. The font is only measured, never modified.

Output: tools/word_font_widths.json  {word: width at 100 px}
Usage:  python3 tools/measure_font_widths.py
"""
import html
import json
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
from build_word_boxes import TEXT_ZIP, FONT_WIDTHS, load_text  # noqa: E402

CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
FONT = 'UthmanicHafs_v2-0 font/uthmanic_hafs_v20.ttf'


def main():
    words = sorted({w for ws in load_text().values() for w in ws})
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        with zipfile.ZipFile(TEXT_ZIP) as z:
            (tmp / 'font.ttf').write_bytes(z.read(FONT))
        (tmp / 'measure.html').write_text(
            '<!doctype html><meta charset=utf-8><style>@font-face{font-family:K;src:url(font.ttf)}</style>'
            '<pre id=o></pre><script>const words=' + json.dumps(words, ensure_ascii=False) + ';'
            "document.fonts.load('100px K').then(()=>{const c=document.createElement('canvas').getContext('2d');"
            "c.font='100px K';c.direction='rtl';const r={};for(const w of words)r[w]=c.measureText(w).width;"
            "document.getElementById('o').textContent=JSON.stringify(r);});</script>", encoding='utf-8')
        dom = subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--allow-file-access-from-files',
                              '--virtual-time-budget=20000', '--dump-dom', (tmp / 'measure.html').as_uri()],
                             capture_output=True, text=True, check=True).stdout
    widths = json.loads(html.unescape(re.search(r'<pre id="o">(.*?)</pre>', dom, re.S).group(1)))
    assert len(widths) == len(words)
    FONT_WIDTHS.write_text(json.dumps({k: round(v, 2) for k, v in sorted(widths.items())},
                                      ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
    print(f'{len(widths)} words measured -> {FONT_WIDTHS.relative_to(ROOT.parent)}')


if __name__ == '__main__':
    main()
