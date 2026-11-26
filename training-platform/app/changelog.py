"""Release notes for altibyan.app/changelog.

The notes are copies of docs/release-notes/v*.md (Arabic first, then
English after a `---` line). Only a small Markdown subset is used there:
`## ` titles, `- ` bullets, **bold**, `code` and [links](url). The
per-release download lines are left out: /download lists the current
ways to get the app.
"""
from __future__ import annotations

import re
from functools import lru_cache
from html import escape
from pathlib import Path

from markupsafe import Markup

NOTES_DIR = Path(__file__).parent / "release_notes"

# Phrases the site doesn't carry: a riwaya the site doesn't list, and a
# feature that was removed from the app.
_DROP = (
    ("، وAndroid Auto", ""),
    (", plus Android Auto", ""),
    ("أربع روايات جديدة (ورش وقالون والدوري وشعبة)", "روايات جديدة (ورش وقالون والدوري)"),
    ("four new riwayat (Warsh, Qalun, al-Duri, Shu'bah)", "new riwayat (Warsh, Qalun and al-Duri)"),
)
_SKIP_LINE = re.compile(r"^\*\*(التحميل|Downloads):\*\*")


def _inline(text: str) -> str:
    out = escape(text, quote=False)
    out = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", out)
    out = re.sub(r"`([^`]+)`", r'<code dir="ltr">\1</code>', out)
    out = re.sub(
        r"\[([^\]]+)\]\((https?://[^)\s]+)\)",
        lambda m: f'<a href="{escape(m.group(2))}" rel="noopener">{m.group(1)}</a>',
        out,
    )
    return out


def _render(block: str) -> tuple[str, Markup]:
    for old, new in _DROP:
        block = block.replace(old, new)
    title, html, in_list = "", [], False
    for raw in block.strip().splitlines():
        line = raw.strip()
        if line.startswith("## ") and not title:
            title = line[3:].strip()
            continue
        if line.startswith("- "):
            if not in_list:
                html.append("<ul>")
                in_list = True
            html.append(f"<li>{_inline(line[2:])}</li>")
            continue
        if in_list:
            html.append("</ul>")
            in_list = False
        if not line or _SKIP_LINE.match(line):
            continue
        if line.startswith("### "):
            html.append(f"<h3>{_inline(line[4:])}</h3>")
        else:
            html.append(f"<p>{_inline(line)}</p>")
    if in_list:
        html.append("</ul>")
    return title, Markup("\n".join(html))


def _version(path: Path) -> tuple[int, ...]:
    return tuple(int(p) for p in re.findall(r"\d+", path.stem))


@lru_cache(maxsize=1)
def releases() -> list[dict]:
    """Every release, newest first: version, and title + HTML per language."""
    items = []
    for path in sorted(NOTES_DIR.glob("v*.md"), key=_version, reverse=True):
        parts = re.split(r"^---\s*$", path.read_text(encoding="utf-8"), maxsplit=1, flags=re.M)
        ar = _render(parts[0])
        en = _render(parts[1]) if len(parts) > 1 else ar
        items.append({"version": path.stem.lstrip("v"), "ar": ar, "en": en})
    return items
