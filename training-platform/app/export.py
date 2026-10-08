from __future__ import annotations

import hashlib
import json
import shutil
from pathlib import Path

from sqlalchemy.orm import Session

from . import verses
from .config import settings
from .models import Recording


def build_export(db: Session) -> dict:
    """Copy accepted recordings into media/export and write the NeMo manifest.

    The manifest is one JSON object per line:
        {"audio_filepath": "...", "duration": seconds, "text": "..."}
    The verse text is read verbatim from the verses loader (exported from
    content.db); it is never typed or edited here.
    """
    accepted = (
        db.query(Recording)
        .filter(Recording.status == "accepted")
        .order_by(Recording.id)
        .all()
    )
    media = Path(settings.media_dir).resolve()
    root = media / "export"
    wavs = root / "wavs"
    wavs.mkdir(parents=True, exist_ok=True)

    lines: list[str] = []
    checksums: list[str] = []
    for rec in accepted:
        src = media / rec.audio_path
        if not src.is_file():
            continue
        dst = wavs / f"{rec.id}.wav"
        shutil.copyfile(src, dst)
        sha = hashlib.sha256(dst.read_bytes()).hexdigest()
        checksums.append(f"{sha}  wavs/{rec.id}.wav")

        text = verses.ayah_range_text(
            rec.surah, rec.ayah, rec.ayah_end or rec.ayah
        ) or ""
        lines.append(
            json.dumps(
                {
                    "audio_filepath": f"wavs/{rec.id}.wav",
                    "duration": round(rec.audio_duration_ms / 1000, 3),
                    "text": text,
                },
                ensure_ascii=False,
            )
        )

    manifest = root / "manifest.jsonl"
    manifest.write_text(
        "\n".join(lines) + ("\n" if lines else ""), encoding="utf-8"
    )
    (root / "SHA256SUMS").write_text(
        "\n".join(checksums) + ("\n" if checksums else ""), encoding="utf-8"
    )
    return {"count": len(lines), "manifest": str(manifest), "dir": str(root)}
