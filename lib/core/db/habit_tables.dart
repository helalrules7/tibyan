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
  /// Since v5 the day the plan's pace is counted from.
  TextColumn get rebasedOn => text().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  // v5 (khatmah v1.1). A row from v4 has [rangeStart] null until its log is
  // carried over to sessions (KhatmahStore.migrateLegacy).

  /// `fullQuran`, `partial`, `dailyWird` or `custom`.
  TextColumn get kind => text().withDefault(const Constant('fullQuran'))();

  /// The verses of the khatma (`ayah.id`), and where reading starts.
  IntColumn get rangeStart => integer().nullable()();
  IntColumn get rangeEnd => integer().nullable()();
  IntColumn get startAt => integer().nullable()();

  /// `duration`, `endDate`, `dailyAmount` or `openEnded`.
  TextColumn get pacingMode => text().withDefault(const Constant('endDate'))();

  /// `adaptive` or `fixed`.
  TextColumn get scheduleMode =>
      text().withDefault(const Constant('adaptive'))();

  /// The planned amount a day, in Madina pages (verse weights).
  RealColumn get dailyWeight => real().nullable()();

  /// Rest weekdays (`DateTime.weekday`, 1 = Monday), comma separated:
  /// `5` for Friday.
  TextColumn get restWeekdays => text().withDefault(const Constant(''))();

  /// `auto`, `ask` or `manual`.
  TextColumn get countingMode => text().withDefault(const Constant('auto'))();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  /// `active`, `paused`, `completed` or `cancelled`. Replaces reading it
  /// from [completedAt] and `deletedAt`, which are still written.
  TextColumn get status => text().withDefault(const Constant('active'))();
  BoolColumn get autoRestart => boolean().withDefault(const Constant(false))();

  /// The preset it was made from (`ramadan_30`…).
  TextColumn get presetId => text().nullable()();

  /// The answer to «finish early, or a lighter portion?»: null (not asked
  /// yet), `finishEarly` or `lighter`.
  TextColumn get aheadChoice => text().nullable()();

  /// Notification kinds on for this khatma, comma separated.
  TextColumn get reminderKinds => text().withDefault(const Constant(''))();

  /// A catch-up the reader chose (JSON), or null.
  TextColumn get recovery => text().nullable()();
}

/// A stretch a khatma was paused: its days are not counted.
@DataClassName('KhatmaPauseRow')
class KhatmaPauses extends Table with SyncColumns {
  @override
  String get tableName => 'khatma_pause';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get khatmaUuid => text()();

  /// First paused day, and the last (null while still paused).
  TextColumn get fromDay => text()();
  TextColumn get toDay => text().nullable()();
}

/// The part of a reading session counted for a khatma.
@DataClassName('SessionAttributionRow')
class SessionAttributions extends Table with SyncColumns {
  @override
  String get tableName => 'session_attribution';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionUuid => text()();
  TextColumn get khatmaUuid => text()();

  /// The verses counted, new to the khatma when counted (JSON runs).
  TextColumn get ranges => text()();

  /// Their weight then.
  RealColumn get newWeight => real()();

  /// `auto`, `userAccepted`, `manual`, or `declined` (an «ask» answered
  /// no; kept so it is not asked again).
  TextColumn get decidedBy => text()();
  BoolColumn get undone => boolean().withDefault(const Constant(false))();

  /// The logical day of the session, and when it started (for order).
  TextColumn get day => text()();
  DateTimeColumn get at => dateTime()();
}

/// Cache: a khatma's coverage, rebuilt from its attributions.
@DataClassName('KhatmaCoverageRow')
class KhatmaCoverages extends Table {
  @override
  String get tableName => 'khatma_coverage';

  TextColumn get khatmaUuid => text()();
  TextColumn get ranges => text()();
  RealColumn get coveredWeight => real()();
  IntColumn get frontier => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {khatmaUuid};
}

/// Cache: what was read for a khatma on a logical day.
@DataClassName('DailyStatRow')
class DailyStats extends Table {
  @override
  String get tableName => 'daily_stat';

  TextColumn get khatmaUuid => text()();
  TextColumn get day => text()();
  RealColumn get weightRead => real()();
  IntColumn get sessions => integer()();
  IntColumn get seconds => integer()();
  RealColumn get target => real().nullable()();

  @override
  Set<Column> get primaryKey => {khatmaUuid, day};
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

  /// How it was read: `page` (the page view), `scroll` (auto-scroll),
  /// `verse` («آية آية») or `continuous`.
  TextColumn get mode => text().withDefault(const Constant('page'))();
  TextColumn get edition => text().nullable()();

  // v5 (khatmah v1.1).

  /// `reader`, `audio` or `manual`.
  TextColumn get source => text().withDefault(const Constant('reader'))();

  /// Where the reading was opened from (`EntryPoint.name`).
  TextColumn get entryPoint => text().withDefault(const Constant('other'))();

  /// Time spent reading, idle stretches left out.
  IntColumn get activeSeconds => integer().nullable()();

  /// The verses read (JSON runs of `ayah.id`).
  TextColumn get ranges => text().withDefault(const Constant(''))();
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
  'khatma_pause',
  'session_attribution',
  'reading_session',
  'listening_session',
  'reflection',
  'srs_item',
  'memorization',
];
