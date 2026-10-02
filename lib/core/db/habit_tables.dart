import 'dart:math';

import 'package:drift/drift.dart';

/// A random version 4 UUID (RFC 4122), for rows that sync across devices.
String newUuid() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = [for (final x in b) x.toRadixString(16).padLeft(2, '0')].join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

/// Columns every synced table carries (the plan's sync model): a UUID that
/// is the same on every device, the time of the last change (last write
/// wins), and a soft delete so deletions sync too.
mixin SyncColumns on Table {
  TextColumn get uuid => text().clientDefault(newUuid).unique()();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// A khatma plan: read the whole mushaf of [edition] from [startDate] to
/// [targetDate]. Dates are local calendar days, `yyyy-MM-dd`.
@DataClassName('KhatmaRow')
class Khatmas extends Table with SyncColumns {
  @override
  String get tableName => 'khatma';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();

  /// The edition whose pages the plan counts (`MushafEdition.name`).
  TextColumn get edition => text()();

  /// `page`, `juz` or `hizb`: what a day's portion is made of.
  TextColumn get unit => text().withDefault(const Constant('page'))();
  TextColumn get startDate => text()();
  TextColumn get targetDate => text()();

  /// Units a day, when the plan was made from a daily amount; null when it
  /// was made from an end date.
  RealColumn get dailyPortion => real().nullable()();

  /// Daily reminder, minutes after midnight; null for none.
  IntColumn get reminderTime => integer().nullable()();

  /// The day the rest was spread again over the remaining days (catch-up).
  TextColumn get rebasedOn => text().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
}

/// Pages of a khatma read on a day, as a run of pages.
@DataClassName('KhatmaLogRow')
class KhatmaLogs extends Table with SyncColumns {
  @override
  String get tableName => 'khatma_log';

  IntColumn get id => integer().autoIncrement()();

  /// The khatma's uuid (row ids differ between devices).
  TextColumn get khatmaUuid => text()();
  TextColumn get date => text()();
  IntColumn get fromPage => integer()();
  IntColumn get toPage => integer()();
}

/// Time spent in the page view, recorded automatically.
@DataClassName('ReadingSessionRow')
class ReadingSessions extends Table with SyncColumns {
  @override
  String get tableName => 'reading_session';

  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();

  /// Pages that stayed on screen long enough to count as read.
  IntColumn get pages => integer()();

  /// `page` (the page view).
  TextColumn get mode => text().withDefault(const Constant('page'))();
  TextColumn get edition => text().nullable()();
}

/// Time spent listening to a recitation, recorded automatically.
@DataClassName('ListeningSessionRow')
class ListeningSessions extends Table with SyncColumns {
  @override
  String get tableName => 'listening_session';

  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get seconds => integer()();
  IntColumn get reciterId => integer()();
}

/// The reader's own note on a verse (tadabbur journal).
@DataClassName('ReflectionRow')
class Reflections extends Table with SyncColumns {
  @override
  String get tableName => 'reflection';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();
  TextColumn get body => text().named('text')();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
}

/// Changes waiting to be sent to the sync server, one per row (a later
/// change replaces an earlier one). Filled for every synced table; sent
/// only when accounts and sync are switched on and the reader signs in.
@DataClassName('OutboxRow')
class Outbox extends Table {
  @override
  String get tableName => 'outbox';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get entity => text().named('table_name')();
  TextColumn get rowUuid => text().named('row_id')();

  /// `upsert` or `delete`.
  TextColumn get op => text()();

  /// The row as JSON.
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {entity, rowUuid},
  ];
}

/// Tables that sync, by their SQL name.
const syncedTables = [
  'khatma',
  'khatma_log',
  'reading_session',
  'listening_session',
  'reflection',
];
