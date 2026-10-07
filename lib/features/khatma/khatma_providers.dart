import 'dart:async';
import 'dart:math';
import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/user_database.dart';
import '../../core/flags/feature_flags.dart';
import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/sync/sync.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/data/mushaf_repository.dart';
import '../mushaf/data/page_pack.dart';
import '../mushaf/data/riwaya_data.dart';
import '../mushaf/mushaf_providers.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import 'data/activity_repository.dart';
import 'data/khatma_repository.dart';
import 'data/quran_index_loader.dart';
import 'domain/day.dart';
import 'domain/quran_index.dart';
import 'domain/khatma_plan.dart';
import 'domain/reading_tracker.dart';
import 'domain/reminder_plan.dart';
import 'services/home_widget_sync.dart';
import 'services/reminder_scheduler.dart';

/// The verses' numbers, pages and weights, built once from content.db.
final quranIndexProvider = FutureProvider<QuranIndex>(
  (ref) => loadQuranIndex(ref.watch(contentDatabaseProvider)),
);

/// A riwaya edition's pack data: the edition being read's, or another's
/// read from its pack when it is on the device; null for Hafs editions and
/// for a pack not downloaded.
final editionRiwayaDataProvider =
    FutureProvider.family<RiwayaData?, MushafEdition>((ref, edition) async {
      if (!edition.isRiwaya) return null;
      if (ref.watch(editionProvider) == edition) {
        return ref.watch(riwayaDataProvider.future);
      }
      try {
        final installer = PagePackInstaller(
          root: ref.watch(packsDirProvider),
          spec: PagePackSpec.of(edition),
        );
        if (!installer.isInstalled) return null;
        return await RiwayaData.load(installer.dir);
      } catch (_) {
        return null;
      }
    });

/// The pages of [edition] in Hafs verse numbers (a riwaya's from its pack;
/// null when the pack is not on the device).
final editionPagesProvider =
    FutureProvider.family<EditionPageMap?, MushafEdition>((ref, edition) async {
      final index = await ref.watch(quranIndexProvider.future);
      final hafs = index.hafsPages(edition.name);
      if (hafs != null) return hafs;
      final data = await ref.watch(editionRiwayaDataProvider(edition).future);
      return data == null ? null : riwayaPages(edition.name, data, index);
    });

final khatmaRepositoryProvider = Provider<KhatmaRepository>(
  (ref) => KhatmaRepository(ref.watch(userDatabaseProvider)),
);

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(ref.watch(userDatabaseProvider)),
);

/// Overridden in `main()` with the device's notifications.
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => NoReminders(),
);

/// Overridden in `main()` with the home screen widget plugin.
final homeWidgetSyncProvider = Provider<HomeWidgetSync>(
  (ref) => NoHomeWidget(),
);

/// The current day, moved on when the app comes back to the foreground.
class TodayNotifier extends Notifier<Day> {
  @override
  Day build() => Day.today();

  void refresh() {
    final now = Day.today();
    if (now != state) state = now;
  }
}

final todayProvider = NotifierProvider<TodayNotifier, Day>(TodayNotifier.new);

final activeKhatmaProvider = StreamProvider<KhatmaRow?>(
  (ref) => ref.watch(khatmaRepositoryProvider).watchActive(),
);

final completedKhatmasProvider = StreamProvider<List<KhatmaRow>>(
  (ref) => ref.watch(khatmaRepositoryProvider).watchCompleted(),
);

final khatmaLogsProvider = StreamProvider.family<List<KhatmaLogRow>, String>(
  (ref, uuid) => ref.watch(khatmaRepositoryProvider).watchLogs(uuid),
);

MushafEdition editionNamed(String name) =>
    MushafEdition.values.asNameMap()[name] ?? MushafEdition.madina1441;

PortionUnit unitNamed(String name) =>
    PortionUnit.values.asNameMap()[name] ?? PortionUnit.page;

/// The first page of each unit of an edition (page, juz or hizb).
Future<List<int>> unitStartsOf(
  MushafRepository repo,
  MushafEdition edition,
  PortionUnit unit,
) async {
  final first = (await repo.ayah(1, 1)).pageIn(edition);
  final starts = switch (unit) {
    PortionUnit.page => pageUnitStarts(first, edition.pageCount),
    PortionUnit.juz => [
      for (final j in await repo.juzStarts()) j.ayah.pageIn(edition),
    ],
    PortionUnit.hizb => [
      for (final a in await repo.hizbStarts()) a.pageIn(edition),
    ],
  };
  final sorted = starts.toSet().toList()..sort();
  sorted[0] = first;
  return sorted;
}

final unitStartsProvider =
    FutureProvider.family<List<int>, (MushafEdition, PortionUnit)>(
      (ref, k) => unitStartsOf(ref.watch(mushafRepositoryProvider), k.$1, k.$2),
    );

/// A khatma with its plan and what has been read.
class KhatmaStatus {
  KhatmaStatus._(this.row, this.plan, this.read, this.today);

  /// Builds the plan of [row]: from its start, or from the day of the last
  /// catch-up and the unit reached then.
  factory KhatmaStatus.of(
    KhatmaRow row,
    List<KhatmaLogRow> logs,
    List<int> unitStarts,
    Day today,
  ) {
    final edition = editionNamed(row.edition);
    final read = readPages(logs);
    final rebased = row.rebasedOn == null ? null : Day.parse(row.rebasedOn!);
    var base = 0;
    if (rebased != null) {
      final probe = KhatmaPlan(
        unitStarts: unitStarts,
        lastPage: edition.pageCount,
        from: rebased,
        target: rebased,
      );
      final next = probe.nextPage(readPagesBefore(logs, rebased));
      base = next == null ? probe.unitCount : probe.unitOf(next);
    }
    final from = rebased ?? Day.parse(row.startDate);
    final target = Day.parse(row.targetDate);
    final plan = KhatmaPlan(
      unitStarts: unitStarts,
      lastPage: edition.pageCount,
      from: from,
      target: target.isBefore(from) ? from : target,
      baseUnit: base,
    );
    return KhatmaStatus._(row, plan, read, today);
  }

  final KhatmaRow row;
  final KhatmaPlan plan;
  final Set<int> read;
  final Day today;

  MushafEdition get edition => editionNamed(row.edition);
  PortionUnit get unit => unitNamed(row.unit);
  int get done => plan.pagesDone(read);
  int get total => plan.totalPages;
  double get fraction => total == 0 ? 0 : done / total;
  bool get complete => plan.isComplete(read);
  ({PageRange range, int pages})? get todayPortion =>
      plan.todayPortion(today, read);
  int get behind => plan.pagesBehind(today, read);
  int get daysLeft => max(0, plan.target.difference(today) + 1);

  /// The end date if the reader keeps the plan's daily amount from today.
  Day extendedTarget() {
    final base = plan.unitOf(plan.nextPage(read) ?? plan.lastPage);
    final perDay = row.dailyPortion ?? (plan.unitCount / _originalDays);
    return today.add(KhatmaPlan.daysFor(plan.unitCount - base, perDay) - 1);
  }

  int get _originalDays =>
      Day.parse(row.targetDate).difference(Day.parse(row.startDate)) + 1;
}

final khatmaStatusProvider = FutureProvider<KhatmaStatus?>((ref) async {
  final row = await ref.watch(activeKhatmaProvider.future);
  if (row == null) return null;
  final logs = await ref.watch(khatmaLogsProvider(row.uuid).future);
  final starts = await ref.watch(
    unitStartsProvider((editionNamed(row.edition), unitNamed(row.unit))).future,
  );
  return KhatmaStatus.of(row, logs, starts, ref.watch(todayProvider));
});

/// Records reading and listening, keeps the khatma's log, reminders and
/// home screen widget up to date.
class KhatmaService {
  KhatmaService(this._ref);

  final Ref _ref;

  KhatmaRepository get _repo => _ref.read(khatmaRepositoryProvider);
  ActivityRepository get _activity => _ref.read(activityRepositoryProvider);
  MushafRepository get _mushaf => _ref.read(mushafRepositoryProvider);

  AppLocalizations get _l => lookupAppLocalizations(
    _ref.read(settingsProvider).locale ?? const Locale('ar'),
  );

  Future<KhatmaStatus?> status() async {
    final row = await _repo.active();
    if (row == null) return null;
    final starts = await unitStartsOf(
      _mushaf,
      editionNamed(row.edition),
      unitNamed(row.unit),
    );
    return KhatmaStatus.of(
      row,
      await _repo.logs(row.uuid),
      starts,
      Day.today(),
    );
  }

  /// Pages of [to] holding the verses of [page] of [from] (a riwaya's
  /// pages through its pack; none when the pack is not on the device).
  Future<Set<int>> pagesIn(
    int page,
    MushafEdition from,
    MushafEdition to,
  ) async {
    if (from == to) return {page};
    final a = await _ref.read(editionPagesProvider(from).future);
    final b = await _ref.read(editionPagesProvider(to).future);
    final verses = a?.ayahsOn(page);
    if (b == null || verses == null) return const {};
    return b.pagesOf(verses.from, verses.to);
  }

  /// A page stayed on screen long enough: it counts for the khatma.
  Future<void> pageRead(PageRead r) async {
    final row = await _repo.active();
    if (row == null) return;
    final pages = await pagesIn(
      r.page,
      editionNamed(r.edition),
      editionNamed(row.edition),
    );
    final fresh = await _repo.recordRead(row, pages, Day.of(r.at));
    if (fresh.isEmpty) return;
    await _afterProgress();
  }

  Future<void> _afterProgress() async {
    final s = await status();
    if (s != null && s.complete) await _repo.complete(s.row.uuid);
    await refresh();
  }

  Future<void> sessionEnded(ReadingSpan s) => _activity.addReadingSession(
    start: s.start,
    end: s.end,
    pages: s.pages,
    edition: s.edition,
  );

  /// Starts a khatma, setting aside the one still open.
  Future<void> create({
    required String title,
    required MushafEdition edition,
    required PortionUnit unit,
    required Day start,
    required Day target,
    double? dailyPortion,
    int? reminderTime,
  }) async {
    final open = await _repo.active();
    if (open != null) await _repo.delete(open.uuid);
    await _repo.create(
      title: title,
      edition: edition.name,
      unit: unit,
      start: start,
      target: target,
      dailyPortion: dailyPortion,
      reminderTime: reminderTime,
    );
    if (reminderTime != null) {
      await _ref.read(reminderSchedulerProvider).requestPermission();
    }
    await refresh();
  }

  Future<void> delete(String uuid) async {
    await _repo.delete(uuid);
    await refresh();
  }

  Future<void> setReminder(int? minutes) async {
    final row = await _repo.active();
    if (row == null) return;
    if (minutes != null) {
      await _ref.read(reminderSchedulerProvider).requestPermission();
    }
    await _repo.setReminder(row.uuid, minutes);
    await refresh();
  }

  /// Today's portion read in a printed mushaf (or another app).
  Future<void> markTodayRead() async {
    final s = await status();
    final portion = s?.todayPortion;
    if (s == null || portion == null) return;
    await _repo.recordRead(s.row, {
      for (var p = portion.range.from; p <= portion.range.to; p++) p,
    }, Day.today());
    await _afterProgress();
  }

  /// Catch-up: the pages left are spread over the days left.
  Future<void> spreadRest() async {
    final s = await status();
    if (s == null) return;
    await _repo.spreadRest(s.row.uuid, Day.today());
    await refresh();
  }

  /// Catch-up: the daily amount stays and the end date moves.
  Future<void> moveTarget() async {
    final s = await status();
    if (s == null) return;
    await _repo.moveTarget(s.row.uuid, Day.today(), s.extendedTarget());
    await refresh();
  }

  /// Schedules the next days' reminders again (rolling) and rewrites the
  /// home screen widget. Run on start, on resume and after every change.
  Future<void> refresh() async {
    _ref.read(todayProvider.notifier).refresh();
    final s = await status();
    final l = _l;
    final digits = NumberFormatter(
      _ref.read(settingsProvider).locale ?? const Locale('ar'),
    );
    final today = Day.today();
    final upcoming = s == null || s.complete
        ? const <Day, PageRange>{}
        : s.plan.upcoming(today, s.read, count: reminderDaysAhead);

    // Reminders.
    final minutes = s?.row.reminderTime;
    final notices = <ReminderNotice>[
      if (s != null && minutes != null)
        for (final r in planReminders(
          now: DateTime.now(),
          minutes: minutes,
          plan: s.plan,
          read: s.read,
        ))
          (
            plan: r,
            title: l.khatmaReminderTitle,
            body: l.khatmaReminderBody(
              digits(r.range!.from),
              digits(r.range!.to),
            ),
            payload: widgetUri(r.range!.from, s.row.edition).toString(),
          ),
    ];
    try {
      await _ref
          .read(reminderSchedulerProvider)
          .replace(notices, channel: l.khatmaReminderChannel);
    } catch (_) {
      // Notifications unavailable: the khatma works without them.
    }

    // Home screen widget.
    final surahs = await _ref.read(surahsProvider.future);
    final ar = l.localeName == 'ar';
    final days = <Day, WidgetDay>{};
    for (final MapEntry(key: day, value: range) in upcoming.entries) {
      final first = (await _mushaf.ayahsOnPage(
        range.from,
        s!.edition,
        await _ref.read(editionRiwayaDataProvider(s.edition).future),
      )).firstOrNull;
      final surah = first == null ? null : surahs[first.surah - 1];
      days[day] = (
        portion: l.khatmaPagesRange(digits(range.from), digits(range.to)),
        reference: first == null || surah == null
            ? ''
            : l.journalVerseRef(
                ar ? surah.nameAr : surah.nameEn,
                digits(first.number),
              ),
        page: range.from,
      );
    }
    await _ref
        .read(homeWidgetSyncProvider)
        .write(
          WidgetData(
            title: s == null ? l.khatmaTitle : s.row.title,
            edition: s?.row.edition ?? '',
            days: days,
            idle: s == null
                ? l.widgetNoKhatma
                : s.complete
                ? l.khatmaComplete
                : l.khatmaTodayDone,
          ),
        );
  }

  /// The page to open for a widget or reminder tap
  /// (`tibyan://khatma?page=…&edition=…`), in the edition being read now.
  Future<String> routeFor(Uri uri) async {
    final page = int.tryParse(uri.queryParameters['page'] ?? '');
    if (page == null) return '/khatma';
    final from = editionNamed(uri.queryParameters['edition'] ?? '');
    final now = _ref.read(editionProvider);
    final pages = await pagesIn(page, from, now);
    return '/mushaf?page=${pages.isEmpty ? page : pages.reduce(min)}';
  }
}

final khatmaServiceProvider = Provider<KhatmaService>(KhatmaService.new);

/// Time spent listening, recorded once playback stops.
class ListeningTracker {
  ListeningTracker(this._save, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final Future<void> Function(DateTime start, int seconds, int reciter) _save;
  final DateTime Function() _now;
  DateTime? _start;
  int? _reciter;

  /// Shorter plays (a verse tapped by mistake) are not recorded.
  static const minSeconds = 10;

  void playing(bool on, int reciterId) {
    if (on) {
      if (_start != null && _reciter == reciterId) return;
      if (_start != null) _stop();
      _start = _now();
      _reciter = reciterId;
    } else {
      _stop();
    }
  }

  void _stop() {
    final start = _start;
    final reciter = _reciter;
    _start = null;
    if (start == null || reciter == null) return;
    final seconds = _now().difference(start).inSeconds;
    if (seconds >= minSeconds) unawaited(_save(start, seconds, reciter));
  }
}

final listeningTrackerProvider = Provider<ListeningTracker>(
  (ref) => ListeningTracker(
    (start, seconds, reciter) => ref
        .read(activityRepositoryProvider)
        .addListeningSession(
          start: start,
          seconds: seconds,
          reciterId: reciter,
        ),
  ),
);

/// Sync, kept off by the `accounts_sync` flag until a Supabase project
/// exists (docs/SYNC.md).
final syncEngineProvider = Provider<SyncEngine>(
  (ref) => SyncEngine(
    db: ref.watch(userDatabaseProvider),
    backend: ref.watch(syncBackendProvider),
    enabled: ref.watch(featureFlagsProvider).isOn(Feature.accountsSync),
    prefs: ref.watch(sharedPreferencesProvider),
  ),
);

/// Whether the gentle streak notes are shown (plan D9: they can be
/// turned off).
class StreakNotesSetting extends Notifier<bool> {
  static const _key = 'habits.streakNotes';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(_key) ?? true;

  Future<void> set(bool on) async {
    state = on;
    await ref.read(sharedPreferencesProvider).setBool(_key, on);
  }
}

final streakNotesProvider = NotifierProvider<StreakNotesSetting, bool>(
  StreakNotesSetting.new,
);
