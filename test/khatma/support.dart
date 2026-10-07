import 'dart:io';

import 'package:drift/native.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/khatma/data/quran_index_loader.dart';
import 'package:tibyan/features/khatma/domain/quran_index.dart';

QuranIndex? _index;

/// The verse index of the real bundled content.db, built once per test
/// file.
Future<QuranIndex> realIndex() async {
  if (_index != null) return _index!;
  final db = ContentDatabase(
    NativeDatabase(
      File('assets/db/content.db'),
      setup: (raw) => raw.execute('PRAGMA query_only = ON'),
    ),
  );
  try {
    return _index = await loadQuranIndex(db);
  } finally {
    await db.close();
  }
}

/// The user database's schema as version 4 made it (before khatmah v1.1),
/// dumped from that version: one statement per line.
List<String> userDbV4Schema() => [
  for (final line in File('test/fixtures/user_db_v4.sql').readAsLinesSync())
    if (line.trim().isNotEmpty) line.trim().replaceAll(RegExp(r';$'), ''),
];
