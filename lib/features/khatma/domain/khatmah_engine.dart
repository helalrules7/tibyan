import 'day.dart';
import 'interval_set.dart';
import 'khatmah.dart';
import 'quran_index.dart';

/// What a session's verses would add to one khatma: [ranges] (new to it)
/// weighing [newWeight]. [decidedBy] is null while it waits for the
/// reader's answer (a khatma in `ask` mode).
class Attribution {
  const Attribution({
    required this.khatmaUuid,
    required this.ranges,
    required this.newWeight,
    this.decidedBy,
  });

  final String khatmaUuid;
  final IntervalSet ranges;
  final double newWeight;
  final DecidedBy? decidedBy;

  bool get pending => decidedBy == null;
}

/// A session waiting for «احتسب؟» for a khatma in `ask` mode.
class PendingCredit {
  const PendingCredit({
    required this.sessionUuid,
    required this.khatmaUuid,
    required this.ranges,
    required this.newWeight,
    required this.day,
    required this.at,
  });

  final String sessionUuid;
  final String khatmaUuid;
  final IntervalSet ranges;
  final double newWeight;
  final Day day;
  final DateTime at;
}

/// What happens to a khatma once its last verse is read.
class Completion {
  const Completion(this.done, this.next);

  /// The khatma, completed.
  final Khatmah done;

  /// The khatma started again in its place (`autoRestart`), if any.
  final Khatmah? next;
}

/// The khatmas' rules, free of storage and screens: counting a session's
/// verses for each khatma (Attribution), progress, the frontier and where
/// to continue, completion and starting again, pausing and resuming, and
/// which khatma is the primary one.
class KhatmahEngine {
  const KhatmahEngine(this.index);

  final QuranIndex index;

  /// The weight of [k]'s verses.
  double totalWeight(Khatmah k) => index.weightOf(k.rangeStart, k.rangeEnd);

  /// The share of [k] read, 0 … 1, by weight.
  double progress(Ledger l) {
    final total = totalWeight(l.khatmah);
    return total <= 0 ? 0 : (l.coveredWeight / total).clamp(0.0, 1.0);
  }

  /// Weight left to read.
  double remaining(Ledger l) =>
      (totalWeight(l.khatmah) - l.coveredWeight).clamp(0.0, double.infinity);

  /// The first unread verse in the khatma's order (null once complete).
  int? frontier(Ledger l) => l.frontier;

  /// Where «continue» opens: the frontier, or the start once complete.
  int resolveContinue(Ledger l) => l.frontier ?? l.khatmah.startAt;

  // Attribution.

  /// What the verses of a session (from the reader or the recitation)
  /// add to each khatma: the verses in its range it has not read yet.
  /// `auto` khatmas count them at once; `ask` ones wait for an answer
  /// (pending); `manual` ones and khatmas not active get nothing. The same
  /// reading may count for several khatmas.
  List<Attribution> attribute(
    IntervalSet verses,
    Iterable<Khatmah> khatmahs,
    IntervalSet Function(Khatmah k) coverage,
  ) {
    final out = <Attribution>[];
    for (final k in khatmahs) {
      if (!k.isActive || k.counting == CountingMode.manual) continue;
      final fresh = verses.intersect(k.range).subtract(coverage(k));
      if (fresh.isEmpty) continue;
      out.add(
        Attribution(
          khatmaUuid: k.uuid,
          ranges: fresh,
          newWeight: fresh.weigh(index.weightOf),
          decidedBy: k.counting == CountingMode.auto ? DecidedBy.auto : null,
        ),
      );
    }
    return out;
  }

  /// Marked read by hand («تحديد كمقروء»): counts for [k] whatever its
  /// counting mode.
  Attribution? markRead(IntervalSet verses, Khatmah k, IntervalSet coverage) {
    final fresh = verses.intersect(k.range).subtract(coverage);
    if (fresh.isEmpty) return null;
    return Attribution(
      khatmaUuid: k.uuid,
      ranges: fresh,
      newWeight: fresh.weigh(index.weightOf),
      decidedBy: DecidedBy.manual,
    );
  }

  /// Sessions still waiting for an answer for the `ask` khatmas among
  /// [khatmahs]: read or heard (not marked by hand) since the khatma was
  /// made, with no attribution to it yet (a declined one is an answer),
  /// and something new for it.
  List<PendingCredit> pending({
    required Iterable<Khatmah> khatmahs,
    required Iterable<
      ({String uuid, IntervalSet ranges, DateTime start, Day day, bool manual})
    >
    sessions,
    required Iterable<Credit> credits,
    required IntervalSet Function(Khatmah k) coverage,
  }) {
    final answered = {for (final c in credits) (c.sessionUuid, c.khatmaUuid)};
    final out = <PendingCredit>[];
    for (final k in khatmahs) {
      if (!k.isActive || k.counting != CountingMode.ask) continue;
      final since = k.createdAt;
      for (final s in sessions) {
        if (s.manual || answered.contains((s.uuid, k.uuid))) continue;
        if (since != null && s.start.isBefore(since)) continue;
        final fresh = s.ranges.intersect(k.range).subtract(coverage(k));
        if (fresh.isEmpty) continue;
        out.add(
          PendingCredit(
            sessionUuid: s.uuid,
            khatmaUuid: k.uuid,
            ranges: fresh,
            newWeight: fresh.weigh(index.weightOf),
            day: s.day,
            at: s.start,
          ),
        );
      }
    }
    return out;
  }

  /// «تراجع»: the attribution no longer counts. Rebuilding the ledger
  /// without it gives every number as it was before.
  Credit undo(Credit c) => c.copyWith(undone: true);

  // Completion.

  /// [k]'s last verse is read: it is completed on [now], and with
  /// `autoRestart` a new one with the same plan starts from the start of
  /// its range on [today] (it takes over as the primary one).
  Completion complete(
    Khatmah k, {
    required DateTime now,
    required Day today,
    required String Function() newUuid,
  }) {
    final done = k.copyWith(
      status: KhatmahStatus.completed,
      completedAt: () => now,
      isPrimary: k.autoRestart ? false : k.isPrimary,
    );
    if (!k.autoRestart) return Completion(done, null);
    final days = k.targetDate?.difference(k.startDate);
    final next = k.copyWith(
      uuid: newUuid(),
      startDate: today,
      targetDate: () => days == null ? null : today.add(days),
      planFrom: () => null,
      startAt: k.rangeStart,
      status: KhatmahStatus.active,
      isPrimary: k.isPrimary,
      aheadChoice: () => null,
      recovery: () => null,
      pauses: const [],
      createdAt: () => now,
      completedAt: () => null,
    );
    return Completion(done, next);
  }

  // Pause and resume.

  /// Paused from [today]: no portion, no reminders, its days not counted.
  Khatmah pause(Khatmah k, Day today) {
    if (k.status != KhatmahStatus.active) return k;
    return k.copyWith(
      status: KhatmahStatus.paused,
      pauses: [...k.pauses, PausePeriod(today)],
    );
  }

  /// Back from a pause on [today]: the pause ends the day before, and the
  /// end date moves on by the days it lasted.
  Khatmah resume(Khatmah k, Day today) {
    if (k.status != KhatmahStatus.paused) return k;
    final pauses = [...k.pauses];
    var paused = 0;
    final i = pauses.lastIndexWhere((p) => p.to == null);
    if (i >= 0) {
      final from = pauses[i].from;
      final last = today.add(-1);
      if (last.isBefore(from)) {
        pauses.removeAt(i);
      } else {
        pauses[i] = PausePeriod(from, last);
        paused = last.difference(from) + 1;
      }
    }
    return k.copyWith(
      status: KhatmahStatus.active,
      pauses: pauses,
      targetDate: () => k.targetDate?.add(paused),
    );
  }

  // The primary khatma.

  /// [uuid] becomes the primary khatma; the others are not. The primary
  /// one counts reading at once; a khatma that was primary and counted
  /// at once now asks.
  List<Khatmah> setPrimary(List<Khatmah> all, String uuid) => [
    for (final k in all)
      if (k.uuid == uuid)
        k.copyWith(
          isPrimary: true,
          counting: k.counting == CountingMode.manual
              ? CountingMode.manual
              : CountingMode.auto,
        )
      else if (k.isPrimary)
        k.copyWith(
          isPrimary: false,
          counting: k.counting == CountingMode.auto
              ? CountingMode.ask
              : k.counting,
        )
      else
        k,
  ];

  /// Keeps exactly one primary khatma among the open ones: when none is
  /// (the primary one was completed or deleted), the oldest open one
  /// takes its place. Returns only the khatmas that changed.
  List<Khatmah> ensurePrimary(List<Khatmah> all) {
    final open = [
      for (final k in all)
        if (k.isOpen) k,
    ];
    final primaries = [
      for (final k in open)
        if (k.isPrimary) k,
    ];
    final changed = <Khatmah>[];
    // Closed khatmas are never primary.
    for (final k in all) {
      if (!k.isOpen && k.isPrimary) changed.add(k.copyWith(isPrimary: false));
    }
    if (primaries.length == 1 || open.isEmpty) return changed;
    if (primaries.isEmpty) {
      final first = open.first;
      changed.add(
        first.copyWith(
          isPrimary: true,
          counting: first.counting == CountingMode.ask
              ? CountingMode.auto
              : first.counting,
        ),
      );
      return changed;
    }
    // More than one: the oldest stays.
    for (final k in primaries.skip(1)) {
      changed.add(k.copyWith(isPrimary: false));
    }
    return changed;
  }

  /// The counting mode a new khatma starts with: the primary one counts at
  /// once, any other asks (4.3).
  static CountingMode defaultCounting({required bool primary}) =>
      primary ? CountingMode.auto : CountingMode.ask;
}
