-- Review database, schema version 1.
--
-- One file per book (or batch). tools/import_*.py creates it with drafts;
-- the review tool (apps/review/) opens it, records every action, and saves
-- it; tools/export_pack.py reads only reviewed rows out of it.
--
-- The same tables exist for Postgres/Supabase in
-- apps/review/supabase/schema.sql. Keep the two in step.
--
-- Rules the schema enforces itself:
--   * a reviewed entry has a reviewer who is not its editor;
--   * the audit log is append-only (no UPDATE, no DELETE);
--   * entries are never deleted (a bad split is noted and left out of packs).

PRAGMA foreign_keys = ON;

CREATE TABLE meta (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

-- People who act in the tool, and the roles they may act in
-- (comma-separated: editor, reviewer, admin). The role used is stored
-- with every action in the audit log.
CREATE TABLE person (
  name     TEXT PRIMARY KEY,
  roles    TEXT NOT NULL,
  added_at TEXT NOT NULL
);

-- The book row: which book, which printed edition, who edited it (tahqiq),
-- under what licence, and the exact file we split (with its SHA-256).
CREATE TABLE source (
  id           INTEGER PRIMARY KEY,
  key          TEXT NOT NULL UNIQUE,
  kind         TEXT NOT NULL,          -- asbab_nuzul, munasabat, ...
  title        TEXT NOT NULL,
  author       TEXT NOT NULL,
  edition      TEXT,
  publisher    TEXT,
  tahqiq       TEXT,
  licence      TEXT NOT NULL,
  digitised_by TEXT,
  url          TEXT NOT NULL,
  file         TEXT NOT NULL,
  sha256       TEXT NOT NULL,
  retrieved_at TEXT NOT NULL,
  notes        TEXT
);

-- One passage of the book, verbatim. The text is never edited in the tool:
-- a wrong split or a typo against the printed page is written in `note`
-- and fixed by re-importing.
CREATE TABLE entry (
  id                INTEGER PRIMARY KEY,
  source_id         INTEGER NOT NULL REFERENCES source(id),
  seq               INTEGER NOT NULL,   -- order in the book
  kind              TEXT NOT NULL,      -- passage, surah_intro, front_matter
  section           TEXT,               -- the book's own heading
  volume            INTEGER,
  page              INTEGER,            -- first page in that edition
  page_end          INTEGER,            -- last page in that edition
  text              TEXT NOT NULL,
  created_by        TEXT NOT NULL,      -- 'script:<name>@<version>' or a person
  created_at        TEXT NOT NULL,
  script_confidence REAL,               -- best link confidence the script gave
  state             TEXT NOT NULL DEFAULT 'draft'
                    CHECK (state IN ('draft', 'in_review', 'reviewed')),
  editor            TEXT,
  edited_at         TEXT,
  reviewer          TEXT,
  reviewed_at       TEXT,
  note              TEXT,
  content_hash      TEXT NOT NULL,
  updated_at        TEXT NOT NULL,
  UNIQUE (source_id, seq),
  CHECK (state <> 'reviewed'
         OR (reviewer IS NOT NULL AND editor IS NOT NULL AND reviewer <> editor))
);
CREATE INDEX entry_state ON entry (state);

-- Links from an entry to verse(s) and optionally word(s). `quote` is the
-- book's own quotation of the verse, verbatim; `basis` says what the link
-- rests on: marker (the book's verse number), quote (the quotation found
-- in the verse), marker+quote (both agree), or manual (a person set it).
CREATE TABLE entry_link (
  id         INTEGER PRIMARY KEY,
  entry_id   INTEGER NOT NULL REFERENCES entry(id),
  surah      INTEGER NOT NULL CHECK (surah BETWEEN 1 AND 114),
  ayah_from  INTEGER NOT NULL,
  ayah_to    INTEGER NOT NULL,
  word_from  INTEGER,                   -- 1-based word of ayah_from (KFGQPC text)
  word_to    INTEGER,
  quote      TEXT,
  basis      TEXT NOT NULL CHECK (basis IN ('marker', 'quote', 'marker+quote', 'manual')),
  confidence REAL NOT NULL CHECK (confidence BETWEEN 0 AND 1),
  created_by TEXT NOT NULL,
  CHECK (ayah_to >= ayah_from)
);
CREATE INDEX entry_link_entry ON entry_link (entry_id);
CREATE INDEX entry_link_verse ON entry_link (surah, ayah_from);

-- Every action, append-only. `detail` is JSON (what changed).
CREATE TABLE audit (
  id          INTEGER PRIMARY KEY,
  entry_id    INTEGER REFERENCES entry(id),
  at          TEXT NOT NULL,
  actor       TEXT NOT NULL,
  role        TEXT NOT NULL CHECK (role IN ('script', 'editor', 'reviewer', 'admin')),
  action      TEXT NOT NULL,            -- import, edit, submit, approve, reject, note
  from_state  TEXT,
  to_state    TEXT,
  hash_before TEXT,
  hash_after  TEXT,
  note        TEXT,
  detail      TEXT
);
CREATE INDEX audit_entry ON audit (entry_id);

CREATE TRIGGER audit_no_update BEFORE UPDATE ON audit
BEGIN SELECT RAISE(ABORT, 'audit log is append-only'); END;
CREATE TRIGGER audit_no_delete BEFORE DELETE ON audit
BEGIN SELECT RAISE(ABORT, 'audit log is append-only'); END;
CREATE TRIGGER entry_no_delete BEFORE DELETE ON entry
BEGIN SELECT RAISE(ABORT, 'entries are never deleted'); END;
CREATE TRIGGER entry_text_frozen BEFORE UPDATE OF text ON entry
WHEN NEW.text IS NOT OLD.text
BEGIN SELECT RAISE(ABORT, 'entry text is verbatim and cannot be edited'); END;

-- Verbatim copies from assets/db/content.db (its SHA-256 is in meta), so
-- the tool shows each entry beside the real mushaf text without a second
-- file. display_text is the KFGQPC Hafs 2.0 text for the KFGQPC font.
CREATE TABLE surah (
  id         INTEGER PRIMARY KEY,
  name_ar    TEXT NOT NULL,
  ayah_count INTEGER NOT NULL
);
CREATE TABLE verse (
  surah                 INTEGER NOT NULL,
  ayah                  INTEGER NOT NULL,
  display_text          TEXT NOT NULL,
  text_search           TEXT NOT NULL,
  search_basmala_prefix INTEGER NOT NULL,
  page                  INTEGER NOT NULL,
  PRIMARY KEY (surah, ayah)
) WITHOUT ROWID;
