# tools

Scripts that download, verify and prepare data. They handle structure only (download, checksum, split, map to verses, compare). **They never write or change religious text.**

| Script | What it does |
|---|---|
| `fetch_sources.py` | Downloads every source in `sources.json` into `.cache/` and rejects any file whose SHA-256 differs |
| `verify_text/compare_tanzil_kfgqpc.py` | Lists verses whose base letters differ between Tanzil and the KFGQPC text. Every listed verse goes to a human reviewer |

Rules:
- Raw files stay in `.cache/` (git-ignored) and are rebuilt from `sources.json`.
- A new or changed source gets its own `data(...)` commit that names the source, edition and license, and updates `docs/DATA_SOURCES.md`.
- License evidence for each source lives in `docs/licenses/`.
