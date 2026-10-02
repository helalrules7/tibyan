import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/user_database.dart';

/// Records a change of a synced row in the outbox, replacing any earlier
/// change of the same row, so the outbox never holds more than one entry
/// per row. Call it inside the transaction that wrote the row.
Future<void> enqueueChange(
  UserDatabase db, {
  required String table,
  required String uuid,
  required Map<String, dynamic> row,
  bool deleted = false,
}) => db
    .into(db.outbox)
    .insert(
      OutboxCompanion.insert(
        entity: table,
        rowUuid: uuid,
        op: deleted ? 'delete' : 'upsert',
        payload: jsonEncode(row),
      ),
      onConflict: DoUpdate(
        (_) => OutboxCompanion(
          op: Value(deleted ? 'delete' : 'upsert'),
          payload: Value(jsonEncode(row)),
          createdAt: Value(DateTime.now()),
        ),
        target: [db.outbox.entity, db.outbox.rowUuid],
      ),
    );
