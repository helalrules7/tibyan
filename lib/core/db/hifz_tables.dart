import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import 'habit_tables.dart';

/// A UUID that is the same on every device for the same [key] (SHA-1 name
/// based, as RFC 4122 version 5 lays it out), so a hifz row made on two
/// devices for the same unit or verse is one row when synced.
String stableUuid(String key) {
  final b = sha1.convert(utf8.encode('tibyan:$key')).bytes.sublist(0, 16);
  b[6] = (b[6] & 0x0f) | 0x50;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = [for (final x in b) x.toRadixString(16).padLeft(2, '0')].join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

/// A unit in spaced review (lib/features/hifz/domain/fsrs.dart): a page,
/// a hizb quarter or a surah, kept as its verse range so it is the same in
/// every edition. Its uuid is [stableUuid] of `srs:unit:from:to`.
@DataClassName('SrsItemRow')
class SrsItems extends Table with SyncColumns {
  @override
  String get tableName => 'srs_item';

  IntColumn get id => integer().autoIncrement()();

  /// `page`, `quarter` or `surah`.
  TextColumn get unit => text()();

  /// First and last verse, `surah:ayah`.
  TextColumn get fromRef => text()();
  TextColumn get toRef => text()();

  /// FSRS memory state: days to 90% recall, and difficulty 1..10.
  RealColumn get stability => real()();
  RealColumn get difficulty => real()();
  DateTimeColumn get dueAt => dateTime()();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastReviewAt => dateTime().nullable()();
}

/// How firmly each verse is memorized, for the hifz map: [strength] 1 weak
/// to 4 strong (lib/features/hifz/domain/strength.dart). [unit] is `ayah`
/// and [ref] `surah:ayah`; the uuid is [stableUuid] of `memo:unit:ref`.
@DataClassName('MemorizationRow')
class Memorizations extends Table with SyncColumns {
  @override
  String get tableName => 'memorization';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get unit => text()();
  TextColumn get ref => text()();
  IntColumn get strength => integer()();
}
