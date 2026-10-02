import 'dart:convert';

import 'package:sqlite3/common.dart';

import '../model/content_hash.dart';
import '../model/model.dart';
import '../model/workflow.dart';
import 'review_store.dart';

/// The local backend: a review database (tools/review_schema.sql) opened
/// with package:sqlite3, native in tests and WebAssembly in the browser.
class SqliteReviewStore implements ReviewStore {
  SqliteReviewStore(this.db, {required this.label, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    db.execute('PRAGMA foreign_keys = ON');
    final version = db.select("SELECT value FROM meta WHERE key = 'schema_version'");
    if (version.isEmpty || version.first['value'] != supportedSchema) {
      throw const FormatException('ليس ملف مراجعة بالإصدار 1 من المخطط');
    }
  }

  static const supportedSchema = '1';

  final CommonDatabase db;
  final DateTime Function() _clock;

  @override
  final String label;

  String _now() => _clock().toUtc().toIso8601String().split('.').first.replaceAll(RegExp(r'Z?$'), 'Z');

  @override
  Future<List<Source>> sources() async => [
        for (final r in db.select('SELECT * FROM source ORDER BY id'))
          Source(
            id: r['id'] as int,
            key: r['key'] as String,
            kind: r['kind'] as String,
            title: r['title'] as String,
            author: r['author'] as String,
            edition: r['edition'] as String?,
            publisher: r['publisher'] as String?,
            tahqiq: r['tahqiq'] as String?,
            licence: r['licence'] as String,
            digitisedBy: r['digitised_by'] as String?,
            url: r['url'] as String,
            sha256: r['sha256'] as String,
          ),
      ];

  @override
  Future<List<SurahInfo>> surahs() async => [
        for (final r in db.select('SELECT id, name_ar, ayah_count FROM surah ORDER BY id'))
          SurahInfo(r['id'] as int, r['name_ar'] as String, r['ayah_count'] as int),
      ];

  @override
  Future<Map<ReviewState, int>> counts() async {
    final out = {for (final s in ReviewState.values) s: 0};
    for (final r in db.select('SELECT state, count(*) AS n FROM entry GROUP BY state')) {
      out[ReviewState.parse(r['state'] as String)] = r['n'] as int;
    }
    return out;
  }

  @override
  Future<List<EntrySummary>> entries(EntryFilter f) async {
    final where = <String>[];
    final args = <Object?>[];
    if (f.state != null) {
      where.add('e.state = ?');
      args.add(f.state!.db);
    }
    if (f.kind != null) {
      where.add('e.kind = ?');
      args.add(f.kind);
    }
    if (f.surah != null) {
      where.add('EXISTS (SELECT 1 FROM entry_link x WHERE x.entry_id = e.id AND x.surah = ?)');
      args.add(f.surah);
    }
    if (f.maxConfidence != null) {
      where.add('(e.script_confidence IS NULL OR e.script_confidence < ?)');
      args.add(f.maxConfidence);
    }
    if (f.search != null && f.search!.trim().isNotEmpty) {
      where.add('instr(e.text, ?) > 0');
      args.add(f.search!.trim());
    }
    final rows = db.select('''
      SELECT e.id, e.seq, e.kind, e.section, e.page, e.state, e.script_confidence,
             substr(e.text, 1, 90) AS preview,
             (SELECT surah || ':' || ayah_from || CASE WHEN ayah_to > ayah_from
                     THEN '-' || ayah_to ELSE '' END
                FROM entry_link l WHERE l.entry_id = e.id ORDER BY l.id LIMIT 1) AS first_link
        FROM entry e
       ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
       ORDER BY e.source_id, e.seq''', args);
    return [
      for (final r in rows)
        EntrySummary(
          id: r['id'] as int,
          seq: r['seq'] as int,
          kind: r['kind'] as String,
          section: r['section'] as String?,
          page: r['page'] as int?,
          state: ReviewState.parse(r['state'] as String),
          confidence: (r['script_confidence'] as num?)?.toDouble(),
          firstLink: r['first_link'] as String?,
          preview: (r['preview'] as String).replaceAll('\n', ' '),
        ),
    ];
  }

  List<Link> _links(int entryId) => [
        for (final r in db.select('SELECT * FROM entry_link WHERE entry_id = ? ORDER BY id', [entryId]))
          Link(
            surah: r['surah'] as int,
            ayahFrom: r['ayah_from'] as int,
            ayahTo: r['ayah_to'] as int,
            wordFrom: r['word_from'] as int?,
            wordTo: r['word_to'] as int?,
            quote: r['quote'] as String?,
            basis: r['basis'] as String,
            confidence: (r['confidence'] as num).toDouble(),
            createdBy: r['created_by'] as String,
          ),
      ];

  @override
  Future<Entry?> entry(int id) async => _entry(id);

  Entry? _entry(int id) {
    final rows = db.select('SELECT * FROM entry WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return Entry(
      id: r['id'] as int,
      sourceId: r['source_id'] as int,
      seq: r['seq'] as int,
      kind: r['kind'] as String,
      section: r['section'] as String?,
      volume: r['volume'] as int?,
      page: r['page'] as int?,
      pageEnd: r['page_end'] as int?,
      text: r['text'] as String,
      createdBy: r['created_by'] as String,
      createdAt: r['created_at'] as String,
      scriptConfidence: (r['script_confidence'] as num?)?.toDouble(),
      state: ReviewState.parse(r['state'] as String),
      editor: r['editor'] as String?,
      editedAt: r['edited_at'] as String?,
      reviewer: r['reviewer'] as String?,
      reviewedAt: r['reviewed_at'] as String?,
      note: r['note'] as String?,
      contentHash: r['content_hash'] as String,
      updatedAt: r['updated_at'] as String,
      links: _links(id),
    );
  }

  @override
  Future<List<AuditRow>> audit(int entryId) async => [
        for (final r in db.select('SELECT * FROM audit WHERE entry_id = ? ORDER BY id', [entryId]))
          AuditRow(
            id: r['id'] as int,
            at: r['at'] as String,
            actor: r['actor'] as String,
            role: r['role'] as String,
            action: r['action'] as String,
            fromState: r['from_state'] as String?,
            toState: r['to_state'] as String?,
            note: r['note'] as String?,
            detail: r['detail'] as String?,
          ),
      ];

  @override
  Future<List<Verse>> verses(int surah, int from, int to) async => [
        for (final r in db.select(
            'SELECT surah, ayah, display_text, page FROM verse '
            'WHERE surah = ? AND ayah BETWEEN ? AND ? ORDER BY ayah',
            [surah, from, to]))
          Verse(r['surah'] as int, r['ayah'] as int, r['display_text'] as String, r['page'] as int),
      ];

  @override
  Future<Map<String, List<Role>>> people() async => {
        for (final r in db.select('SELECT name, roles FROM person ORDER BY name'))
          r['name'] as String: [
            for (final s in (r['roles'] as String).split(',').where((s) => s.isNotEmpty)) Role.parse(s),
          ],
      };

  @override
  Future<void> addPerson(Actor actor) async {
    final name = actor.name.trim();
    if (name.isEmpty) throw const WorkflowError('اكتب اسمك');
    final current = (await people())[name];
    if (current == null) {
      db.execute('INSERT INTO person (name, roles, added_at) VALUES (?, ?, ?)', [name, actor.role.db, _now()]);
    } else if (!current.contains(actor.role)) {
      final roles = [...current, actor.role].map((r) => r.db).join(',');
      db.execute('UPDATE person SET roles = ? WHERE name = ?', [roles, name]);
    }
  }

  String _sourceKey(int sourceId) =>
      db.select('SELECT key FROM source WHERE id = ?', [sourceId]).first['key'] as String;

  @override
  Future<Entry> apply(int entryId, ReviewAction action, Actor actor) async {
    final entry = _entry(entryId);
    if (entry == null) throw WorkflowError('لا يوجد مدخل رقم $entryId');
    final outcome = decide(entry, action, actor);
    final at = _now();

    final links = action is EditAction && action.links != null ? action.links! : entry.links;
    final page = action is EditAction && action.page != null ? action.page : entry.page;
    final pageEnd = action is EditAction && action.pageEnd != null ? action.pageEnd : entry.pageEnd;
    final hash = contentHash(
      sourceKey: _sourceKey(entry.sourceId),
      volume: entry.volume,
      page: page,
      pageEnd: pageEnd,
      text: entry.text,
      links: links,
    );

    final detail = <String, Object?>{};
    if (action is EditAction) {
      if (action.links != null) {
        detail['links_before'] = [for (final l in entry.links) l.toJson()];
        detail['links_after'] = [for (final l in links) l.toJson()];
      }
      if (action.page != null || action.pageEnd != null) {
        detail['pages_before'] = [entry.page, entry.pageEnd];
        detail['pages_after'] = [page, pageEnd];
      }
      if (action.note != null) detail['note_before'] = entry.note;
    }

    db.execute('BEGIN');
    try {
      if (action is EditAction && action.links != null) {
        db.execute('DELETE FROM entry_link WHERE entry_id = ?', [entryId]);
        for (final l in links) {
          final kept = entry.links.any(l.sameTarget);
          db.execute(
            'INSERT INTO entry_link (entry_id, surah, ayah_from, ayah_to, word_from, word_to, '
            'quote, basis, confidence, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [
              entryId, l.surah, l.ayahFrom, l.ayahTo, l.wordFrom, l.wordTo, l.quote,
              kept ? l.basis : 'manual', kept ? l.confidence : 1.0, kept ? l.createdBy : actor.name,
            ],
          );
        }
      }
      db.execute(
        '''UPDATE entry SET state = ?, page = ?, page_end = ?, content_hash = ?, updated_at = ?,
             editor = CASE WHEN ? THEN ? ELSE editor END,
             edited_at = CASE WHEN ? THEN ? ELSE edited_at END,
             reviewer = CASE WHEN ? THEN ? WHEN ? THEN NULL ELSE reviewer END,
             reviewed_at = CASE WHEN ? THEN ? WHEN ? THEN NULL ELSE reviewed_at END,
             note = COALESCE(?, note)
           WHERE id = ?''',
        [
          outcome.to.db, page, pageEnd, hash, at,
          outcome.setEditor ? 1 : 0, actor.name,
          outcome.setEditor ? 1 : 0, at,
          outcome.setReviewer ? 1 : 0, actor.name, outcome.clearReview ? 1 : 0,
          outcome.setReviewer ? 1 : 0, at, outcome.clearReview ? 1 : 0,
          outcome.note,
          entryId,
        ],
      );
      db.execute(
        'INSERT INTO audit (entry_id, at, actor, role, action, from_state, to_state, '
        'hash_before, hash_after, note, detail) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          entryId, at, actor.name, actor.role.db, action.name, entry.state.db, outcome.to.db,
          entry.contentHash, hash,
          switch (action) { RejectAction(:final note) => note.trim(), EditAction(:final note) => note, _ => null },
          detail.isEmpty ? null : jsonEncode(detail),
        ],
      );
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
    return _entry(entryId)!;
  }
}
