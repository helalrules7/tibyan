# Tibyan review tool

Flutter web app for reviewing imported scholarly entries beside the mushaf text. How to run it and the review workflow: [`docs/review/README.md`](../../docs/review/README.md).

- `lib/src/model/`: data, the workflow rules, the content hash (same as `tools/review_db.py`).
- `lib/src/store/`: the storage interface, the local SQLite backend, and the Supabase stub.
- `supabase/`: Postgres schema with row-level security, ready for when a shared project exists.
- `web/sqlite3.wasm`: from sqlite3.dart release `sqlite3-3.7.0` (must match `sqlite3` in `pubspec.lock`), SHA-256 `fbcd2e82…1a1f`.
- `fonts/`: symlinks to the app's KFGQPC fonts, unmodified.
