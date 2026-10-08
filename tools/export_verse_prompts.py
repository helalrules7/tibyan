#!/usr/bin/env python3
"""Export the Quran verse prompts for the training platform.

Reads the app's verified content.db (read-only) and writes a JSON file of
surahs and ayah texts, verbatim (display_text, KFGQPC Hafs 2.0 — the same
text the app renders). No verse text is typed or edited here: everything is
SELECTed straight out of content.db.

Usage:
    python3 tools/export_verse_prompts.py [output.json]
Default output: training-platform/data/verses.json
"""

from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DB = REPO / "assets" / "db" / "content.db"


def main() -> int:
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else (
        REPO / "training-platform" / "data" / "verses.json"
    )

    con = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    con.row_factory = sqlite3.Row
    try:
        surahs = [
            {
                "number": row["id"],
                "name_ar": row["name_ar"],
                "name_en": row["name_en"],
                "ayah_count": row["ayah_count"],
            }
            for row in con.execute(
                "SELECT id, name_ar, name_en, ayah_count FROM surah ORDER BY id"
            )
        ]
        ayahs = [
            {
                "surah": row["surah"],
                "number": row["number"],
                "text": row["display_text"],
            }
            for row in con.execute(
                "SELECT surah, number, display_text FROM ayah ORDER BY id"
            )
        ]
    finally:
        con.close()

    payload = {
        "source": "assets/db/content.db",
        "surahs": surahs,
        "ayahs": ayahs,
    }

    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    print(f"Wrote {len(surahs)} surahs and {len(ayahs)} ayahs to {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
