"""Builds the small read-only database behind the website's live reader.

Everything is copied VERBATIM from the app's own content database
(assets/db/content.db): no text is written, changed or generated here.

    python3 training-platform/tools/build_site_quran.py [content.db] [out.db]

Tables: surah, ayah (KFGQPC Hafs 2.0 display text + Tanzil Simple Clean for
search), tafsir (التفسير الميسر, QuranEnc), reciter + timing (Hafs reciters
that have verse timings), credit (the source lines the app itself shows).
"""
from __future__ import annotations

import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "assets" / "db" / "content.db"
OUT = ROOT / "training-platform" / "data" / "site-quran.db"

MUYASSAR = 7  # source.id of التفسير الميسر


def build(src: Path = SRC, out: Path = OUT) -> Path:
    out.parent.mkdir(parents=True, exist_ok=True)
    if out.exists():
        out.unlink()
    db = sqlite3.connect(out)
    db.execute("ATTACH DATABASE ? AS c", (str(src),))
    db.executescript(
        """
        CREATE TABLE surah (id INTEGER PRIMARY KEY, name_ar TEXT NOT NULL, name_en TEXT NOT NULL,
          revelation TEXT NOT NULL, ayah_count INTEGER NOT NULL, start_page INTEGER NOT NULL);
        INSERT INTO surah SELECT id, name_ar, name_en, revelation, ayah_count, start_page FROM c.surah;

        CREATE TABLE ayah (surah INTEGER NOT NULL, number INTEGER NOT NULL, text TEXT NOT NULL,
          basmala_prefix INTEGER NOT NULL, text_search TEXT NOT NULL, page INTEGER NOT NULL,
          juz INTEGER NOT NULL, PRIMARY KEY (surah, number)) WITHOUT ROWID;
        INSERT INTO ayah SELECT surah, number, display_text, basmala_prefix, text_search, page, juz
          FROM c.ayah ORDER BY id;

        CREATE TABLE tafsir (surah INTEGER NOT NULL, ayah INTEGER NOT NULL, text TEXT NOT NULL,
          PRIMARY KEY (surah, ayah)) WITHOUT ROWID;

        CREATE TABLE reciter (id INTEGER PRIMARY KEY, name_ar TEXT NOT NULL, name_en TEXT NOT NULL,
          folder_url TEXT NOT NULL, credit TEXT NOT NULL);
        INSERT INTO reciter SELECT r.id, r.name_ar, r.name_en, r.folder_url, s.attribution
          FROM c.reciter r JOIN c.source s ON s.id = r.source_id
          WHERE r.riwaya = 'hafs' AND r.style = 'murattal'
            AND (SELECT count(*) FROM c.ayah_timing t WHERE t.reciter = r.id) >= 6200
          ORDER BY r.id;

        CREATE TABLE timing (reciter INTEGER NOT NULL, surah INTEGER NOT NULL, ayah INTEGER NOT NULL,
          start_ms INTEGER NOT NULL, end_ms INTEGER NOT NULL,
          PRIMARY KEY (reciter, surah, ayah)) WITHOUT ROWID;
        INSERT INTO timing SELECT t.* FROM c.ayah_timing t WHERE t.reciter IN (SELECT id FROM reciter);

        CREATE TABLE credit (key TEXT PRIMARY KEY, line TEXT NOT NULL, url TEXT NOT NULL);
        """
    )
    db.execute("INSERT INTO tafsir SELECT surah, ayah, text FROM c.commentary WHERE source_id = ?", (MUYASSAR,))
    for key, sid in (("text", 5), ("search", 2), ("tafsir", MUYASSAR)):
        db.execute("INSERT INTO credit SELECT ?, attribution, url FROM c.source WHERE id = ?", (key, sid))
    db.commit()
    counts = {t: db.execute(f"SELECT count(*) FROM {t}").fetchone()[0]
              for t in ("surah", "ayah", "tafsir", "reciter", "timing")}
    assert counts["surah"] == 114 and counts["ayah"] == 6236 and counts["tafsir"] == 6236, counts
    db.execute("DETACH DATABASE c")
    db.execute("VACUUM")
    db.close()
    print(out, counts, f"{out.stat().st_size / 1e6:.1f} MB")
    return out


if __name__ == "__main__":
    build(Path(sys.argv[1]) if len(sys.argv) > 1 else SRC, Path(sys.argv[2]) if len(sys.argv) > 2 else OUT)
