import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tibyan_review/src/model/content_hash.dart';
import 'package:tibyan_review/src/model/model.dart';
import 'package:tibyan_review/src/model/workflow.dart';
import 'package:tibyan_review/src/store/sqlite_review_store.dart';

// Tests run with apps/review as the working directory.
final schema = File('../../tools/review_schema.sql');
final drafts = File('../../data/review/wahidi_asbab.review.db');

const ali = Actor('علي', Role.editor);
const omar = Actor('عمر', Role.reviewer);

SqliteReviewStore newStore() {
  final db = sqlite3.openInMemory();
  db.execute(schema.readAsStringSync());
  db.execute("INSERT INTO meta VALUES ('schema_version', '1')");
  db.execute("INSERT INTO surah VALUES (2, 'البقرة', 286)");
  // Placeholder verse rows: the store copies whatever content.db holds.
  for (var a = 1; a <= 5; a++) {
    db.execute('INSERT INTO verse VALUES (2, ?, ?, ?, 0, 2)', [a, 'كلمة$a أخرى$a ﰀ', 'كلمة$a']);
  }
  db.execute(
    "INSERT INTO source (id, key, kind, title, author, licence, url, file, sha256, retrieved_at) "
    "VALUES (1, 'test_book', 'asbab_nuzul', 'كتاب', 'مؤلف', 'test', 'about:blank', 'f', '0', '2026-10-02')",
  );
  const links = [Link(surah: 2, ayahFrom: 1, ayahTo: 2)];
  final hash = contentHash(sourceKey: 'test_book', volume: 1, page: 5, pageEnd: 5, text: 'نص تجريبي', links: links);
  db.execute(
    "INSERT INTO entry (id, source_id, seq, kind, volume, page, page_end, text, created_by, created_at, "
    "script_confidence, content_hash, updated_at) VALUES (1, 1, 1, 'passage', 1, 5, 5, 'نص تجريبي', "
    "'script:test', 'x', 0.95, ?, 'x')",
    [hash],
  );
  db.execute(
    "INSERT INTO entry_link (entry_id, surah, ayah_from, ayah_to, basis, confidence, created_by) "
    "VALUES (1, 2, 1, 2, 'marker+quote', 0.95, 'script:test')",
  );
  var t = DateTime.utc(2026, 10, 2);
  return SqliteReviewStore(db, label: 'test', clock: () => t = t.add(const Duration(seconds: 1)));
}

void main() {
  test('draft → in review → reviewed, with an audit row per action', () async {
    final store = newStore();
    var e = await store.apply(1, const SubmitAction(), ali);
    expect(e.state, ReviewState.inReview);
    expect(e.editor, 'علي');

    await expectLater(store.apply(1, const ApproveAction(), const Actor('علي', Role.reviewer)),
        throwsA(isA<WorkflowError>()));

    e = await store.apply(1, const ApproveAction(), omar);
    expect(e.state, ReviewState.reviewed);
    expect(e.reviewer, 'عمر');

    final audit = await store.audit(1);
    expect(audit.map((a) => '${a.actor}/${a.role}/${a.action}'), ['علي/editor/submit', 'عمر/reviewer/approve']);
    expect(audit.last.toState, 'reviewed');
    final approved = store.db.select("SELECT hash_after FROM audit WHERE action = 'approve'").first;
    expect(approved['hash_after'], e.contentHash);
    expect(await store.counts(), {ReviewState.draft: 0, ReviewState.inReview: 0, ReviewState.reviewed: 1});
  });

  test('editing a reviewed entry returns it to review with a new hash', () async {
    final store = newStore();
    await store.apply(1, const SubmitAction(), ali);
    final reviewed = await store.apply(1, const ApproveAction(), omar);
    final edited = await store.apply(
      1,
      const EditAction(links: [Link(surah: 2, ayahFrom: 3, ayahTo: 3, wordFrom: 1, wordTo: 2)]),
      const Actor('زيد', Role.editor),
    );
    expect(edited.state, ReviewState.inReview);
    expect(edited.reviewer, isNull);
    expect(edited.editor, 'زيد');
    expect(edited.contentHash, isNot(reviewed.contentHash));
    expect(edited.links.single.basis, 'manual');
    expect(edited.links.single.wordTo, 2);
    final row = (await store.audit(1)).last;
    expect(row.action, 'edit');
    expect(jsonDecode(row.detail!)['links_before'], hasLength(1));
    // Omar may now review Zayd's edit.
    expect((await store.apply(1, const ApproveAction(), omar)).state, ReviewState.reviewed);
  });

  test('a rejection returns the entry to draft with the note', () async {
    final store = newStore();
    await store.apply(1, const SubmitAction(), ali);
    final e = await store.apply(1, const RejectAction('الاقتباس من آية أخرى'), omar);
    expect(e.state, ReviewState.draft);
    expect(e.note, 'الاقتباس من آية أخرى');
    expect((await store.audit(1)).last.note, 'الاقتباس من آية أخرى');
  });

  test('the database refuses text edits, deletions and audit changes', () {
    final store = newStore();
    for (final sql in [
      "UPDATE entry SET text = 'x' WHERE id = 1",
      'DELETE FROM entry WHERE id = 1',
      "INSERT INTO audit (entry_id, at, actor, role, action) VALUES (1, 'x', 'a', 'admin', 'note')",
    ]) {
      if (sql.startsWith('INSERT')) {
        store.db.execute(sql);
        expect(() => store.db.execute("UPDATE audit SET actor = 'b'"), throwsA(isA<SqliteException>()));
        expect(() => store.db.execute('DELETE FROM audit'), throwsA(isA<SqliteException>()));
      } else {
        expect(() => store.db.execute(sql), throwsA(isA<SqliteException>()), reason: sql);
      }
    }
  });

  test('people are recorded with each role they act in', () async {
    final store = newStore();
    await store.addPerson(ali);
    await store.addPerson(const Actor('علي', Role.reviewer));
    expect((await store.people())['علي'], [Role.editor, Role.reviewer]);
  });

  test('filters: state, surah, low confidence, text search', () async {
    final store = newStore();
    expect(await store.entries(const EntryFilter(state: ReviewState.draft)), hasLength(1));
    expect(await store.entries(const EntryFilter(surah: 3)), isEmpty);
    expect(await store.entries(const EntryFilter(maxConfidence: 0.9)), isEmpty);
    expect(await store.entries(const EntryFilter(search: 'تجريبي')), hasLength(1));
    final v = await store.verses(2, 1, 2);
    expect(v.first.words, ['كلمة1', 'أخرى1']);
  });

  test('the shipped drafts database opens, and every hash matches the Dart hash', () async {
    if (!drafts.existsSync()) return markTestSkipped('data/review/wahidi_asbab.review.db not present');
    final db = sqlite3.open(drafts.path, mode: OpenMode.readOnly);
    final store = SqliteReviewStore(db, label: 'drafts');
    final counts = await store.counts();
    expect(counts[ReviewState.draft], greaterThan(500));
    expect(counts[ReviewState.reviewed], 0);
    final key = (await store.sources()).single.key;
    for (final s in await store.entries(const EntryFilter())) {
      final e = (await store.entry(s.id))!;
      expect(
        contentHash(
            sourceKey: key, volume: e.volume, page: e.page, pageEnd: e.pageEnd, text: e.text, links: e.links),
        e.contentHash,
        reason: 'entry ${e.seq}',
      );
    }
    db.close();
  });
}
