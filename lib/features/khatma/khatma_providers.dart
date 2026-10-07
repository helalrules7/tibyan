import 'dart:async';
import 'dart:math';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding;

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
import '../mushaf/presentation/navigation.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import 'data/activity_repository.dart';
import 'data/khatma_repository.dart';
import 'data/khatmah_book.dart';
import 'data/khatmah_store.dart';
import 'data/quran_index_loader.dart';
import 'domain/day.dart';
import 'domain/interval_set.dart';
import 'domain/khatmah.dart';
import 'domain/khatmah_engine.dart';
import 'domain/planner.dart';
import 'domain/recovery.dart';
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

final khatmahStoreProvider = Provider<KhatmahStore>(
  (ref) => KhatmahStore(ref.watch(userDatabaseProvider)),
);

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

/// The current logical day (2.6: it starts at «بداية اليوم», 3:00 by
/// default), moved on when the app comes back to the foreground.
class TodayNotifier extends Notifier<Day> {
  Day _now() =>
      Day.logical(DateTime.now(), ref.read(settingsProvider).dayStartHour);

  @override
  Day build() {
    ref.watch(settingsProvider.select((s) => s.dayStartHour));
    return _now();
  }

  void refresh() {
    final now = _now();
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

/// A khatma's state as the screens show it: in the pages of the edition
/// being read, from the engine's verse coverage and the planner's portion.
class KhatmaStatus {
  KhatmaStatus({
    required this.row,
    required this.khatmah,
    required this.ledger,
    required this.edition,
    required this.pages,
    required this.today,
    required this.wird,
    required this.recovery,
    required this.progress,
    required this.end,
    required this.extendTo,
  });

  final KhatmaRow row;
  final Khatmah khatmah;
  final Ledger ledger;

  /// The edition being read: pages are shown in it.
  final MushafEdition edition;
  final EditionPageMap pages;
  final Day today;

  /// Today's portion (null on a rest day, a paused day, or once complete).
  final Wird? wird;
  final RecoveryState recovery;

  /// The share read, by weight (0 … 1).
  final double progress;

  /// The end date: planned, or where the daily amount leads.
  final Day? end;
  final Day? extendTo;

  PortionUnit get unit => unitNamed(row.unit);

  /// The khatma's pages in this edition.
  late final Set<int> _rangePages = pages.pagesOf(
    khatmah.rangeStart,
    khatmah.rangeEnd,
  );

  /// Pages read in this edition (every verse ending on them read).
  late final Set<int> read = pages
      .readPages(ledger.covered)
      .intersection(_rangePages);

  int get done => read.length;
  int get total => _rangePages.length;
  double get fraction => progress;
  bool get complete => ledger.complete;

  /// The page «continue» opens: the first unread verse's.
  int? get nextPage {
    final f = ledger.frontier;
    return f == null ? null : pages.pageOf(f);
  }

  /// Today's portion in pages, and its pages not read yet; null once it is
  /// read (or there is none today).
  ({PageRange range, int pages})? get todayPortion {
    final w = wird;
    if (w == null || w.done) return null;
    final unread = w.ranges.subtract(ledger.covered);
    if (unread.isEmpty) return null;
    final from = pages.pageOf(khatmah.order.frontier(ledger.covered) ?? w.from);
    final to = pages.lastPageOf(w.to);
    final left = {for (final r in unread.ranges) ...pages.pagesOf(r.from, r.to)}
        .difference(read);
    return (range: (from: min(from, to), to: to), pages: left.length);
  }

  /// Pages behind, shown only when a catch-up is worth suggesting (more
  /// than half a day's amount).
  int get behind =>
      recovery.suggest ? max(1, (recovery.deficit - 1e-9).ceil()) : 0;

  Day get target => end ?? today;
  int get daysLeft => end == null ? 0 : max(0, end!.difference(today) + 1);

  /// The end date if the reader keeps the plan's daily amount from today.
  Day extendedTarget() => extendTo ?? target;
}

/// Bumped by every change to the khatmas or their record.
final khatmahChangesProvider = StreamProvider<int>((ref) async* {
  var n = 0;
  yield n;
  await for (final _ in ref.watch(khatmahStoreProvider).changes()) {
    yield ++n;
  }
});

/// The khatmas at work over the store, with the verse index.
final khatmahBookProvider = FutureProvider<KhatmahBook>((ref) async {
  final index = await ref.watch(quranIndexProvider.future);
  return KhatmahBook(
    store: ref.watch(khatmahStoreProvider),
    index: index,
    dayStartHour: ref.watch(settingsProvider.select((s) => s.dayStartHour)),
  );
});

/// The primary khatma's state, in the edition being read.
final khatmaStatusProvider = FutureProvider<KhatmaStatus?>((ref) async {
  ref.watch(khatmahChangesProvider);
  final today = ref.watch(todayProvider);
  final edition = ref.watch(editionProvider);
  final book = await ref.watch(khatmahBookProvider.future);
  final pages =
      await ref.watch(editionPagesProvider(edition).future) ??
      book.index.madina1441;
  return statusOf(book, today, edition, pages);
});

/// Every active or paused khatma, with its state in the edition being read.
final khatmaStatusesProvider = FutureProvider<List<KhatmaStatus>>((ref) async {
  ref.watch(khatmahChangesProvider);
  final today = ref.watch(todayProvider);
  final edition = ref.watch(editionProvider);
  final book = await ref.watch(khatmahBookProvider.future);
  final pages =
      await ref.watch(editionPagesProvider(edition).future) ??
      book.index.madina1441;
  final plans = await book.store.khatmahs(open: true);
  plans.sort((a, b) {
    if (a.isPrimary == b.isPrimary) return 0;
    return a.isPrimary ? -1 : 1;
  });
  return [
    for (final plan in plans)
      ?await statusOf(book, today, edition, pages, khatmah: plan),
  ];
});

/// A completed khatma for its read-only statistics screen.
final completedKhatmaStatusProvider =
    FutureProvider.family<KhatmaStatus?, String>((ref, uuid) async {
      ref.watch(khatmahChangesProvider);
      final today = ref.watch(todayProvider);
      final edition = ref.watch(editionProvider);
      final book = await ref.watch(khatmahBookProvider.future);
      final pages =
          await ref.watch(editionPagesProvider(edition).future) ??
          book.index.madina1441;
      final plan = await book.store.byUuid(uuid);
      if (plan == null || plan.status != KhatmahStatus.completed) return null;
      return statusOf(book, today, edition, pages, khatmah: plan);
    });

/// The primary khatma's state on [today], in [pages] of [edition].
Future<KhatmaStatus?> statusOf(
  KhatmahBook book,
  Day today,
  MushafEdition edition,
  EditionPageMap pages, {
  Khatmah? khatmah,
}) async {
  final k = khatmah ?? await book.primary();
  if (k == null) return null;
  final row = await book.store.row(k.uuid);
  if (row == null) return null;
  final ledger = await book.ledger(k);
  final snap = Snapper(book.index, pages, quarters: !edition.isRiwaya);
  final recovery = book.recovery;
  return KhatmaStatus(
    row: row,
    khatmah: k,
    ledger: ledger,
    edition: edition,
    pages: pages,
    today: today,
    wird: book.planner.wird(k, ledger, today, snap),
    recovery: recovery.state(k, ledger, today),
    progress: book.engine.progress(ledger),
    end: book.planner.projectedEnd(k, ledger, today) ?? k.targetDate,
    extendTo: k.isActive ? recovery.options(k, ledger, today).extendTo : null,
  );
}

/// Sessions waiting for «احتسب؟» for khatmas in `ask` mode (the quiet line
/// under the reader is phase 6; the khatma's details can count them too).
final pendingCreditsProvider = FutureProvider<List<PendingCredit>>((ref) async {
  ref.watch(khatmahChangesProvider);
  final book = await ref.watch(khatmahBookProvider.future);
  return book.pending();
});

/// A limit the reader can act on (twenty khatmas with reminders): its
/// message is shown as it is.
class KhatmaLimitException implements Exception {
  const KhatmaLimitException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Whether the app is in the background (a completion found by listening
/// with the screen off gets a notification instead of the dialog).
bool _inBackground() {
  final state = WidgetsBinding.instance.lifecycleState;
  return state != null && state != AppLifecycleState.resumed;
}

/// Records reading and listening, keeps the khatmas, their reminders and
/// the home screen widget up to date.
class KhatmaService {
  KhatmaService(this._ref);

  final Ref _ref;

  MushafRepository get _mushaf => _ref.read(mushafRepositoryProvider);
  KhatmahStore get _store => _ref.read(khatmahStoreProvider);
  Future<KhatmahBook> get _book => _ref.read(khatmahBookProvider.future);

  AppLocalizations get _l => lookupAppLocalizations(
    _ref.read(settingsProvider).locale ?? const Locale('ar'),
  );

  Day get _today =>
      Day.logical(DateTime.now(), _ref.read(settingsProvider).dayStartHour);

  bool _prepared = false;
  Future<void>? _preparing;

  /// Once per run: the khatmas made before v5 carried over, one primary
  /// khatma, the caches rebuilt.
  Future<void> _prepare(KhatmahBook book) async {
    if (_prepared) return;
    final pending = _preparing;
    if (pending != null) return pending;
    final preparation = _prepareOnce(book);
    _preparing = preparation;
    try {
      await preparation;
    } on Object {
      _preparing = null;
      rethrow;
    }
  }

  Future<void> _prepareOnce(KhatmahBook book) async {
    final editions = {for (final k in await _store.khatmahs()) k.edition};
    final rows = await (_ref
        .read(userDatabaseProvider)
        .select(_ref.read(userDatabaseProvider).khatmas)
        .get());
    editions.addAll([for (final r in rows) r.edition]);
    final maps = <String, EditionPageMap?>{
      for (final e in editions)
        e: await _ref.read(editionPagesProvider(editionNamed(e)).future),
    };
    await book.prepare((e) => maps[e]);
    _prepared = true;
    _preparing = null;
  }

  Future<KhatmaStatus?> status() async {
    final book = await _book;
    await _prepare(book);
    final edition = _ref.read(editionProvider);
    final pages =
        await _ref.read(editionPagesProvider(edition).future) ??
        book.index.madina1441;
    return statusOf(book, _today, edition, pages);
  }

  Future<List<KhatmaStatus>> openStatuses() async {
    final book = await _book;
    await _prepare(book);
    final edition = _ref.read(editionProvider);
    final pages =
        await _ref.read(editionPagesProvider(edition).future) ??
        book.index.madina1441;
    final plans = await book.store.khatmahs(open: true);
    plans.sort((a, b) {
      if (a.isPrimary == b.isPrimary) return 0;
      return a.isPrimary ? -1 : 1;
    });
    final statuses = <KhatmaStatus>[];
    for (final plan in plans) {
      final status = await statusOf(
        book,
        _today,
        edition,
        pages,
        khatmah: plan,
      );
      if (status != null) statuses.add(status);
    }
    return statuses;
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

  /// The verses reading [page] of [edition] completes (none when the
  /// edition's pages are not at hand).
  Future<IntervalSet> versesOfPage(int page, MushafEdition edition) async {
    final pages = await _ref.read(editionPagesProvider(edition).future);
    return pages?.versesReadOn([page]) ?? IntervalSet.empty;
  }

  /// Adds [verses] to session [session] and counts them for the khatmas.
  Future<void> _record(
    String session,
    IntervalSet verses,
    DateTime at, {
    required SessionSource source,
    EntryPoint entry = EntryPoint.other,
    String? edition,
    String mode = 'page',
  }) async {
    if (verses.isEmpty) return;
    final book = await _book;
    await _prepare(book);
    final change = await book.record(
      session: session,
      verses: verses,
      at: at,
      source: source,
      entry: entry,
      edition: edition,
      mode: mode,
    );
    if (change.completed.isNotEmpty || change.started.isNotEmpty) {
      _ref.read(khatmahEventsProvider.notifier).completed(change);
    }
    await refresh(completed: change.completed);
  }

  /// A page stayed on screen long enough: the verses it completes count
  /// for the khatmas.
  Future<void> pageRead(
    PageRead r, {
    EntryPoint entry = EntryPoint.other,
  }) async => _record(
    r.session,
    await versesOfPage(r.page, editionNamed(r.edition)),
    r.at,
    source: SessionSource.reader,
    entry: entry,
    edition: r.edition,
  );

  /// Verses read in «آية آية» or the continuous view.
  Future<void> versesRead(
    VersesRead r, {
    EntryPoint entry = EntryPoint.other,
    String mode = 'verse',
    String? edition,
  }) => _record(
    r.session,
    r.verses,
    r.at,
    source: SessionSource.reader,
    entry: entry,
    edition: edition,
    mode: mode,
  );

  /// Counts the verses heard to their end while listening.
  late final ListeningCounter _listening = ListeningCounter(
    onHeard: (r) => unawaited(
      _record(
        r.session,
        r.verses,
        r.at,
        source: SessionSource.audio,
        mode: 'audio',
      ).catchError((Object _) {}),
    ),
    onSessionEnd: (session, start, end, verses) => unawaited(
      () async {
        final book = await _book;
        await book.endSession(
          SessionRecord(
            uuid: session,
            start: start,
            end: end,
            ranges: verses,
            activeSeconds: end.difference(start).inSeconds,
            source: SessionSource.audio,
            mode: 'audio',
          ),
        );
      }().catchError((Object _) {}),
    ),
  );

  /// The recitation started or stopped playing.
  void recitationPlaying(bool on) => _listening.playing(on);

  /// Verse [ayah] of [surah] (numbered as in the edition being read) was
  /// recited to its end. Counted when «احتساب الاستماع» is on.
  Future<void> verseRecited(int surah, int ayah) async {
    try {
      if (!_ref.read(settingsProvider).countListening) return;
      final index = await _ref.read(quranIndexProvider.future);
      final edition = _ref.read(editionProvider);
      final riwaya = edition.isRiwaya
          ? await _ref.read(editionRiwayaDataProvider(edition).future)
          : null;
      final ids = edition.isRiwaya
          ? (riwaya == null
                ? IntervalSet.empty
                : riwayaVerseInHafs(riwaya, index, surah, ayah))
          : IntervalSet.of([index.idOf(surah, ayah)]);
      _listening.heard(ids);
    } catch (_) {
      // No verse index here (tests without content.db): nothing counted.
    }
  }

  /// A reading session ended: written with its times, pages and verses.
  Future<void> sessionEnded(
    ReadingSpan s, {
    EntryPoint entry = EntryPoint.other,
  }) async {
    final book = await _book;
    await book.endSession(
      SessionRecord(
        uuid: s.session,
        start: s.start,
        end: s.end,
        ranges: s.verses,
        activeSeconds: s.activeSeconds,
        pages: s.pages,
        entryPoint: entry,
        mode: s.mode,
        edition: s.edition.isEmpty ? null : s.edition,
      ),
    );
  }

  /// Starts a khatma of the whole Quran as the primary one, setting aside
  /// the one still open (the current screen asks first). [dailyPortion] is
  /// in [unit]s of [edition].
  Future<void> create({
    required String title,
    required MushafEdition edition,
    required PortionUnit unit,
    required Day start,
    required Day target,
    double? dailyPortion,
    int? reminderTime,
  }) async {
    final book = await _book;
    final pages =
        await _ref.read(editionPagesProvider(edition).future) ??
        book.index.madina1441;
    final total = book.index.totalWeight;
    final perUnit = switch (unit) {
      PortionUnit.juz => total / 30,
      PortionUnit.hizb => total / 60,
      PortionUnit.page => total / pages.textPages.length,
    };
    final days = target.difference(start) + 1;
    await createPlan(
      Khatmah(
        uuid: newUuid(),
        title: title,
        startDate: start,
        targetDate: target,
        pacing: dailyPortion == null
            ? PacingMode.endDate
            : PacingMode.dailyAmount,
        dailyWeight: dailyPortion == null
            ? total / max(1, days)
            : dailyPortion * perUnit,
        unit: switch (unit) {
          PortionUnit.juz => WirdUnit.juz,
          PortionUnit.hizb => WirdUnit.hizb,
          PortionUnit.page => WirdUnit.page,
        },
        isPrimary: true,
        edition: edition.name,
        reminderTime: reminderTime,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<Khatmah> createPlan(Khatmah plan) async {
    final book = await _book;
    await _prepare(book);
    final open = await book.store.khatmahs(open: true);
    if (plan.reminderTime != null &&
        open.where((k) => k.reminderTime != null).length >=
            maxKhatmaReminderPlans) {
      throw KhatmaLimitException(_l.khatmaReminderPlanLimit);
    }
    final made = await book.create(
      plan.copyWith(
        uuid: newUuid(),
        isPrimary: plan.isPrimary || open.isEmpty,
        createdAt: () => DateTime.now(),
      ),
    );
    final reminderTime = made.reminderTime;
    if (reminderTime != null) {
      await _ref.read(reminderSchedulerProvider).requestPermission();
    }
    await refresh();
    return made;
  }

  Future<void> delete(String uuid) async {
    await (await _book).cancel(uuid);
    await refresh();
  }

  Future<void> setReminder(int? minutes, {String? uuid}) async {
    final book = await _book;
    final k = uuid == null
        ? await book.primary()
        : await book.store.byUuid(uuid);
    if (k == null) return;
    if (minutes != null) {
      if (k.reminderTime == null && k.isOpen) {
        final open = await book.store.khatmahs(open: true);
        final scheduled = open
            .where((plan) => plan.reminderTime != null)
            .length;
        if (scheduled >= maxKhatmaReminderPlans) {
          throw KhatmaLimitException(_l.khatmaReminderPlanLimit);
        }
      }
      await _ref.read(reminderSchedulerProvider).requestPermission();
    }
    await book.edit(k.copyWith(reminderTime: () => minutes));
    await refresh();
  }

  /// Today's portion read in a printed mushaf (or another app): a manual
  /// session for the primary khatma.
  Future<void> markTodayRead({String? uuid}) async {
    final s = uuid == null ? await status() : await statusFor(uuid);
    final w = s?.wird;
    if (s == null || w == null) return;
    await markRead(s.khatmah.uuid, w.ranges);
  }

  Future<KhatmaStatus?> statusFor(String uuid) async {
    final book = await _book;
    await _prepare(book);
    final plan = await book.store.byUuid(uuid);
    if (plan == null || !plan.isOpen) return null;
    final edition = _ref.read(editionProvider);
    final pages =
        await _ref.read(editionPagesProvider(edition).future) ??
        book.index.madina1441;
    return statusOf(book, _today, edition, pages, khatmah: plan);
  }

  /// «تحديد كمقروء» of a page, a range or a portion for khatma [uuid].
  Future<void> markRead(String uuid, IntervalSet verses) async {
    final book = await _book;
    final k = await _store.byUuid(uuid);
    if (k == null) return;
    final change = await book.markRead(k, verses);
    if (change.completed.isNotEmpty) {
      _ref.read(khatmahEventsProvider.notifier).completed(change);
    }
    await refresh(completed: change.completed);
  }

  /// «احتسب» / «لا» for a session waiting in `ask` mode, and «تراجع».
  Future<void> acceptPending(PendingCredit p) async {
    final change = await (await _book).accept(p);
    if (change.completed.isNotEmpty) {
      _ref.read(khatmahEventsProvider.notifier).completed(change);
    }
    await refresh(completed: change.completed);
  }

  Future<void> declinePending(PendingCredit p) async =>
      (await _book).decline(p);

  Future<void> undo(String session, String khatmaUuid) async {
    await (await _book).undo(session, khatmaUuid);
    await refresh();
  }

  Future<void> pause(String uuid) async {
    await (await _book).pause(uuid);
    await refresh();
  }

  Future<void> resume(String uuid) async {
    await (await _book).resume(uuid);
    await refresh();
  }

  Future<void> setPrimary(String uuid) async {
    await (await _book).setPrimary(uuid);
    await refresh();
  }

  Future<void> updatePlan(Khatmah plan) async {
    await (await _book).edit(plan);
    await refresh();
  }

  Future<void> _plan(
    Khatmah Function(Recovery r, Khatmah k, Ledger l) f, {
    String? uuid,
  }) async {
    final book = await _book;
    final k = uuid == null
        ? await book.primary()
        : await book.store.byUuid(uuid);
    if (k == null) return;
    await book.edit(f(book.recovery, k, await book.ledger(k)));
    await refresh();
  }

  /// Catch-up: what is left spread over the days left.
  Future<void> spreadRest({String? uuid}) =>
      _plan((r, k, l) => r.spreadRest(k, l, _today), uuid: uuid);

  /// Catch-up: the daily amount stays and the end date moves.
  Future<void> moveTarget({String? uuid}) =>
      _plan((r, k, l) => r.extend(k, l, _today), uuid: uuid);

  /// Catch-up: all of it today.
  Future<void> catchUpToday({String? uuid}) =>
      _plan((r, k, l) => r.allToday(k, l, _today), uuid: uuid);

  /// Catch-up: over the fewest days that add at most 25% a day.
  Future<void> catchUpGradually({String? uuid}) =>
      _plan((r, k, l) => r.spread(k, l, _today), uuid: uuid);

  /// The answer to «finish early, or a lighter portion?».
  Future<void> answerAhead(AheadChoice choice, {String? uuid}) =>
      _plan((r, k, l) => r.answerAhead(k, choice), uuid: uuid);

  /// Schedules the next days' reminders again (rolling) and rewrites the
  /// home screen widget. Run on start, on resume and after every change.
  Future<void> refresh({List<Khatmah> completed = const []}) async {
    _ref.read(todayProvider.notifier).refresh();
    final statuses = await openStatuses();
    final s =
        statuses.where((status) => status.khatmah.isPrimary).firstOrNull ??
        statuses.firstOrNull;
    final l = _l;
    final digits = NumberFormatter(
      _ref.read(settingsProvider).locale ?? const Locale('ar'),
    );
    final today = _today;
    final upcoming = <Day, PageRange>{};
    if (s != null && !s.complete) {
      final book = await _book;
      final snap = Snapper(book.index, s.pages, quarters: !s.edition.isRiwaya);
      final plan = book.planner.upcoming(
        s.khatmah,
        s.ledger,
        today,
        snap,
        count: reminderDaysAhead,
      );
      for (final MapEntry(key: day, value: w) in plan.entries) {
        upcoming[day] = (
          from: s.pages.pageOf(w.from),
          to: s.pages.lastPageOf(w.to),
        );
      }
    }

    // Reminders.
    final book = await _book;
    final settings = _ref.read(settingsProvider);
    final reminderPlans = statuses
        .where(
          (status) =>
              status.khatmah.isActive &&
              !status.complete &&
              status.row.reminderTime != null,
        )
        .toList();
    final reminderNow = DateTime.now();
    final candidates = <PlannedReminder>[];
    final noticesById = <int, ReminderNotice>{};

    ReminderNotice noticeFor(Khatmah plan, PlannedReminder reminder) {
      final range = reminder.range;
      final (title, body) = switch (reminder.type) {
        KhatmaReminderType.completion => (
          l.khatmaReminderCompletedTitle(plan.title),
          l.khatmaReminderCompletedBody,
        ),
        KhatmaReminderType.recovery => (
          l.khatmaReminderRecoveryTitle(plan.title),
          l.khatmaReminderRecoveryBody(digits(range!.from), digits(range.to)),
        ),
        KhatmaReminderType.target => (
          l.khatmaReminderTargetTitle(plan.title),
          l.khatmaReminderTargetBody,
        ),
        KhatmaReminderType.portion => (
          l.khatmaReminderForPlan(plan.title),
          l.khatmaReminderBody(digits(range!.from), digits(range.to)),
        ),
        KhatmaReminderType.missed => (
          l.khatmaReminderMissedTitle(plan.title),
          l.khatmaReminderMissedBody(digits(range!.from), digits(range.to)),
        ),
      };
      final path = reminder.type == KhatmaReminderType.completion
          ? '/${plan.uuid}'
          : '/${plan.uuid}/continue';
      return (
        plan: reminder,
        title: title,
        body: body,
        payload: Uri(scheme: 'tibyan', host: 'khatmah', path: path).toString(),
      );
    }

    for (var i = 0; i < reminderPlans.length; i++) {
      final status = reminderPlans[i];
      final minutes = status.row.reminderTime!;
      final snap = Snapper(
        book.index,
        status.pages,
        quarters: !status.edition.isRiwaya,
      );
      final plan = book.planner.upcoming(
        status.khatmah,
        status.ledger,
        today,
        snap,
        count: khatmaReminderDaysAhead,
      );
      final portions = <Day, PageRange>{
        for (final MapEntry(key: day, value: wird) in plan.entries)
          day: (
            from: status.pages.pageOf(wird.from),
            to: status.pages.lastPageOf(wird.to),
          ),
      };
      final plannedPortions = portionReminders(
        now: reminderNow,
        today: today,
        minutes: minutes,
        portions: portions,
        last: status.khatmah.targetDate,
        days: khatmaReminderDaysAhead,
        idBase: khatmaReminderId(i, 0, KhatmaReminderType.portion),
        idStep: khatmaReminderTypesPerDay,
        dayStartHour: settings.dayStartHour,
        planIndex: i,
        planKey: status.khatmah.uuid,
      );
      final todayPortion = status.todayPortion;
      for (final portion in plannedPortions) {
        final useRecovery =
            status.recovery.suggest &&
            portion.day == today &&
            todayPortion != null;
        final reminder = useRecovery
            ? PlannedReminder(
                id: khatmaReminderId(i, 0, KhatmaReminderType.recovery),
                at: portion.at,
                day: portion.day,
                range: portion.range,
                planIndex: i,
                planKey: status.khatmah.uuid,
                type: KhatmaReminderType.recovery,
              )
            : portion;
        candidates.add(reminder);
        noticesById[reminder.id] = noticeFor(status.khatmah, reminder);
      }

      final todayReminder = plannedPortions
          .where((reminder) => reminder.day == today)
          .firstOrNull;
      if (todayPortion != null && todayReminder != null) {
        final missed = missedPortionReminder(
          now: reminderNow,
          today: today,
          minutes: minutes,
          range: todayReminder.range!,
          planIndex: i,
          planKey: status.khatmah.uuid,
          dayStartHour: settings.dayStartHour,
        );
        if (missed != null) {
          candidates.add(missed);
          noticesById[missed.id] = noticeFor(status.khatmah, missed);
        }
      }

      final target = status.khatmah.targetDate;
      if (target != null) {
        final targetDay = target.add(-1);
        final dayOffset = targetDay.difference(today);
        if (dayOffset >= 0 &&
            dayOffset < khatmaReminderDaysAhead &&
            status.khatmah.readsOn(targetDay)) {
          final at = reminderAt(targetDay, minutes, settings.dayStartHour);
          if (at.isAfter(reminderNow)) {
            final targetReminder = PlannedReminder(
              id: khatmaReminderId(i, dayOffset, KhatmaReminderType.target),
              at: at,
              day: targetDay,
              planIndex: i,
              planKey: status.khatmah.uuid,
              type: KhatmaReminderType.target,
            );
            candidates.add(targetReminder);
            noticesById[targetReminder.id] = noticeFor(
              status.khatmah,
              targetReminder,
            );
          }
        }
      }
    }

    final completionPlans = completed.isNotEmpty && _inBackground()
        ? completed
              .where((plan) => plan.reminderTime != null)
              .take(maxKhatmaReminderPlans)
              .toList()
        : const <Khatmah>[];
    for (var i = 0; i < completionPlans.length; i++) {
      final plan = completionPlans[i];
      final reminder = PlannedReminder(
        id: khatmaCompletionIdBase + i,
        at: reminderNow.add(const Duration(seconds: 2)),
        day: today,
        planIndex: reminderPlans.length + i,
        planKey: plan.uuid,
        type: KhatmaReminderType.completion,
      );
      candidates.add(reminder);
      noticesById[reminder.id] = noticeFor(plan, reminder);
    }

    final selected = limitKhatmaReminders(
      candidates,
      planCount: max(1, reminderPlans.length + completionPlans.length),
    );
    final notices = [
      for (final reminder in selected) noticesById[reminder.id]!,
    ];
    try {
      await _ref
          .read(reminderSchedulerProvider)
          .replace(notices, channel: l.khatmaReminderChannel);
    } catch (error, stackTrace) {
      debugPrint('Khatma reminder scheduling failed: $error\n$stackTrace');
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
            edition: s?.edition.name ?? '',
            days: days,
            idle: s == null
                ? l.widgetNoKhatma
                : s.complete
                ? l.khatmaComplete
                : l.khatmaTodayDone,
          ),
        );
  }

  /// The destination for Khatma links. The old `khatma?page=…` payload
  /// remains supported for reminders and widgets already on devices.
  Future<String> routeFor(Uri uri, {EntryPoint? entry}) async {
    final source = entry ?? khatmaEntryOfLink(uri);
    if (uri.host == 'khatmat') return '/khatma';
    if (uri.host == 'khatmah') {
      final segments = uri.pathSegments;
      if (segments.isEmpty) return '/khatma';
      final uuid = segments.first;
      if (segments.length == 1) {
        return Uri(path: '/khatma', queryParameters: {'plan': uuid}).toString();
      }
      if (segments.length == 2 && segments[1] == 'continue') {
        return _continueRoute(uuid, source);
      }
      return '/khatma';
    }
    if (uri.host == 'reader') {
      final plan = uri.queryParameters['plan'];
      return _readerRoute(
        planUuid: plan == null || plan.isEmpty ? null : plan,
        ayahId: int.tryParse(uri.queryParameters['ayah'] ?? ''),
        entry: source,
      );
    }

    final page = int.tryParse(uri.queryParameters['page'] ?? '');
    if (page == null) return '/khatma';
    final from = editionNamed(uri.queryParameters['edition'] ?? '');
    final now = _ref.read(editionProvider);
    final pages = await pagesIn(page, from, now);
    return mushafLocation(
      pages.isEmpty ? page : pages.reduce(min),
      entry: source,
    );
  }

  Future<String> _continueRoute(String uuid, EntryPoint entry) async =>
      _readerRoute(planUuid: uuid, entry: entry);

  Future<String> _readerRoute({
    String? planUuid,
    int? ayahId,
    required EntryPoint entry,
  }) async {
    final book = await _book;
    await _prepare(book);
    final plan = planUuid == null
        ? await book.primary()
        : await book.store.byUuid(planUuid);
    if (planUuid != null && (plan == null || !plan.isOpen)) return '/khatma';

    final target =
        ayahId != null && ayahId >= 1 && ayahId <= book.index.ayahCount
        ? ayahId
        : plan == null
        ? null
        : book.engine.resolveContinue(await book.ledger(plan));
    if (target == null) return '/khatma';

    final edition = _ref.read(editionProvider);
    final pages = await _ref.read(editionPagesProvider(edition).future);
    // Navigation turns to the page; it never selects the verse.
    final page = (pages ?? book.index.madina1441).pageOf(target);
    return mushafLocation(page, entry: entry);
  }
}

/// Khatmas completed (and started again) by the latest reading, for the
/// screens to greet (the completion screen is phase 7).
class KhatmahEvents extends Notifier<BookChange?> {
  @override
  BookChange? build() => null;

  void completed(BookChange change) => state = change;

  void seen() => state = null;
}

final khatmahEventsProvider = NotifierProvider<KhatmahEvents, BookChange?>(
  KhatmahEvents.new,
);

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
