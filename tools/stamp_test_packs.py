"""Stamp a staged audio index or tafsir text pack as TEST data, for the
closed testing phase only (owner's decision 2026-10-05: testers see the
flagged features now, from drafts and from sources whose permission is
still pending, clearly marked as test data).

Book packs are stamped by `tools/export_pack.py --test-drafts`; this tool
does the same for the two other kinds the app downloads:

  audio-index IN OUT --id ID
      A verse audio index (tools/audio_index.py) with `id` = ID,
      `status` = "test", and both titles ending with the test mark. The
      links are kept as they are.
  text-pack IN OUT
      A copy of a tafsir text pack (tools/fetch_quranenc_extra.py pack)
      with pack_index `status` = "test" and its title ending with the test
      mark. The verse table is not touched (checked after the copy), and
      OUT.index.json gives pack_sha256 and bytes.

Only labels we write are changed (ids, titles, status); no Quran or
scholarly text is. Every test pack is listed in lib/core/testing/
test_packs.dart and must be removed before a public release
(docs/MISSING_DATA.md, «قبل النشر العام»).

Usage:
  python3 tools/stamp_test_packs.py audio-index tools/.cache/staging/nuqayah/almuyassar/index.json \\
      out/test-nuqayah-almuyassar.json --id test-nuqayah-almuyassar
  python3 tools/stamp_test_packs.py text-pack \\
      tools/.cache/staging/quranenc/english_mokhtasar/english_mokhtasar.pack.db \\
      out/test-english-mokhtasar.pack.db
"""
import argparse
import json
import shutil
import sqlite3
import sys
from pathlib import Path

import audio_index
import staging

TEST_STATUS = 'test'
TITLE_MARK_AR = ' (مسودة للاختبار)'
TITLE_MARK_EN = ' (test draft)'


def stamp_audio_index(index, test_id):
    """A copy of [index] stamped as test data (validated)."""
    out = dict(index)
    out['id'] = test_id
    out['status'] = TEST_STATUS
    out['title_ar'] = out.get('title_ar', test_id) + TITLE_MARK_AR
    out['title_en'] = out.get('title_en', test_id) + TITLE_MARK_EN
    audio_index.validate(out)
    return out


def _verses(path):
    db = sqlite3.connect(f'file:{path}?mode=ro', uri=True)
    try:
        return db.execute('SELECT surah, ayah, text, footnotes FROM verse '
                          'ORDER BY surah, ayah').fetchall()
    finally:
        db.close()


def stamp_text_pack(src, out):
    """Copies the pack [src] to [out] stamped as test data; returns the
    index written beside it."""
    src, out = Path(src), Path(out)
    if out.exists():
        raise FileExistsError(out)
    out.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, out)
    db = sqlite3.connect(out)
    meta = dict(db.execute('SELECT key, value FROM pack_index'))
    if meta.get('kind') != 'tafsir_text':
        db.close()
        out.unlink()
        raise ValueError(f'{src}: not a tafsir text pack')
    db.execute("INSERT OR REPLACE INTO pack_index VALUES ('title', ?)",
               (meta.get('title', '') + TITLE_MARK_EN,))
    db.execute("INSERT OR REPLACE INTO pack_index VALUES ('status', ?)", (TEST_STATUS,))
    db.commit()
    db.execute('VACUUM')
    db.close()
    if _verses(out) != _verses(src):
        out.unlink()
        raise RuntimeError('the verse table changed in the copy')
    index = {'status': TEST_STATUS, 'title': meta.get('title', '') + TITLE_MARK_EN,
             'source_pack_sha256': staging.sha256_file(src),
             'pack_sha256': staging.sha256_file(out), 'bytes': out.stat().st_size}
    Path(str(out) + '.index.json').write_text(
        json.dumps(index, ensure_ascii=False, indent=2, sort_keys=True) + '\n', encoding='utf-8')
    return index


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = ap.add_subparsers(dest='cmd', required=True)
    a = sub.add_parser('audio-index')
    a.add_argument('src', type=Path)
    a.add_argument('out', type=Path)
    a.add_argument('--id', required=True)
    t = sub.add_parser('text-pack')
    t.add_argument('src', type=Path)
    t.add_argument('out', type=Path)
    args = ap.parse_args(argv)
    if args.cmd == 'audio-index':
        index = stamp_audio_index(json.loads(args.src.read_text(encoding='utf-8')), args.id)
        args.out.parent.mkdir(parents=True, exist_ok=True)
        audio_index.write(args.out, index)
        print(f'{args.out}: sha256 {staging.sha256_file(args.out)} '
              f'bytes {args.out.stat().st_size}')
    else:
        print(json.dumps(stamp_text_pack(args.src, args.out), ensure_ascii=False, indent=1))
    return 0


if __name__ == '__main__':
    sys.exit(main())
