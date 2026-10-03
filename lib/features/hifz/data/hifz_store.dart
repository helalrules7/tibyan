import 'package:drift/drift.dart';

import '../../../core/db/user_database.dart';
import '../../../core/sync/outbox_writer.dart';

/// Reads and writes of the hifz tables in user.db. Every write is queued in
/// the sync outbox in the same transaction.
extension HifzStore on UserDatabase {
  static String srsUuid(String unit, String fromRef, String toRef) =>
      stableUuid('srs:$unit:$fromRef:$toRef');

  static String memoUuid(String unit, String ref) =>
      stableUuid('memo:$unit:$ref');

  /// Review units that are not deleted, soonest due first.
  Stream<List<SrsItemRow>> watchSrsItems() =>
      (select(srsItems)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([
              (t) => OrderingTerm.asc(t.dueAt),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .watch();

  /// The unit, if it is in review (not deleted).
  Future<SrsItemRow?> srsItem(String unit, String fromRef, String toRef) =>
      (select(srsItems)..where(
            (t) =>
                t.uuid.equals(srsUuid(unit, fromRef, toRef)) &
                t.deletedAt.isNull(),
          ))
          .getSingleOrNull();

  Future<void> _queueSrs(String uuid) async {
    final row = await (select(
      srsItems,
    )..where((t) => t.uuid.equals(uuid))).getSingle();
    await enqueueChange(
      this,
      table: 'srs_item',
      uuid: uuid,
      row: row.toJson(),
      deleted: row.deletedAt != null,
    );
  }

  /// Records a review of a unit. Its first review (or the first after it
  /// was removed) starts it afresh.
  Future<void> saveSrsReview({
    required String unit,
    required String fromRef,
    required String toRef,
    required double stability,
    required double difficulty,
    required DateTime dueAt,
    required bool lapse,
    required DateTime now,
  }) => transaction(() async {
    final uuid = srsUuid(unit, fromRef, toRef);
    final old = await (select(
      srsItems,
    )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
    final fresh = old == null || old.deletedAt != null;
    final entry = SrsItemsCompanion(
      uuid: Value(uuid),
      unit: Value(unit),
      fromRef: Value(fromRef),
      toRef: Value(toRef),
      stability: Value(stability),
      difficulty: Value(difficulty),
      dueAt: Value(dueAt),
      reps: Value(fresh ? 1 : old.reps + 1),
      lapses: Value(fresh ? 0 : old.lapses + (lapse ? 1 : 0)),
      lastReviewAt: Value(now),
      updatedAt: Value(now),
      deletedAt: const Value(null),
    );
    if (old == null) {
      await into(srsItems).insert(entry);
    } else {
      await (update(srsItems)..where((t) => t.id.equals(old.id))).write(entry);
    }
    await _queueSrs(uuid);
  });

  /// Removes a unit from review (kept as deleted, so the deletion syncs).
  Future<void> deleteSrsItem(int id) => transaction(() async {
    final now = DateTime.now();
    await (update(srsItems)..where((t) => t.id.equals(id))).write(
      SrsItemsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
    final row = await (select(
      srsItems,
    )..where((t) => t.id.equals(id))).getSingle();
    await _queueSrs(row.uuid);
  });

  /// Strength of every memorized verse, by `surah:ayah`.
  Stream<Map<String, int>> watchVerseStrengths() =>
      (select(memorizations)
            ..where((t) => t.unit.equals('ayah') & t.deletedAt.isNull()))
          .watch()
          .map((rows) => {for (final r in rows) r.ref: r.strength});

  Future<Map<String, int>> verseStrengths(Iterable<String> refs) async {
    final rows =
        await (select(memorizations)..where(
              (t) =>
                  t.unit.equals('ayah') &
                  t.ref.isIn(refs.toList()) &
                  t.deletedAt.isNull(),
            ))
            .get();
    return {for (final r in rows) r.ref: r.strength};
  }

  /// Sets the strength of verses, by `surah:ayah`.
  Future<void> setVerseStrengths(Map<String, int> strengths) =>
      transaction(() async {
        final now = DateTime.now();
        for (final e in strengths.entries) {
          final uuid = memoUuid('ayah', e.key);
          await into(memorizations).insert(
            MemorizationsCompanion.insert(
              uuid: Value(uuid),
              unit: 'ayah',
              ref: e.key,
              strength: e.value,
              updatedAt: Value(now),
            ),
            onConflict: DoUpdate(
              (_) => MemorizationsCompanion(
                strength: Value(e.value),
                updatedAt: Value(now),
                deletedAt: const Value(null),
              ),
              target: [memorizations.uuid],
            ),
          );
          final row = await (select(
            memorizations,
          )..where((t) => t.uuid.equals(uuid))).getSingle();
          await enqueueChange(
            this,
            table: 'memorization',
            uuid: uuid,
            row: row.toJson(),
          );
        }
      });
}
