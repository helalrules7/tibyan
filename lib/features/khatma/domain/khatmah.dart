import 'dart:convert';
import 'dart:math';

import 'day.dart';
import 'interval_set.dart';
import 'quran_index.dart';

/// What a khatma covers.
enum KhatmahKind { fullQuran, partial, dailyWird, custom }

/// How its pace is set: a number of days, an end date, an amount a day,
/// or an amount a day with no end.
enum PacingMode { duration, endDate, dailyAmount, openEnded }

/// [adaptive]: each day's portion is worked out at the start of the day
/// from what is left. [fixed]: the whole schedule is laid out once.
enum ScheduleMode { adaptive, fixed }

/// What a day's portion is shown in and rounded to.
enum WirdUnit { page, rub, hizb, juz }

/// How reading is counted for a khatma: at once, after asking, or only
/// when marked by hand.
enum CountingMode { auto, ask, manual }

enum KhatmahStatus { active, paused, completed, cancelled }

/// The answer to «finish early, or a lighter portion?».
enum AheadChoice { finishEarly, lighter }

enum SessionSource { reader, audio, manual }

/// Where reading was opened from.
enum EntryPoint {
  khatmahContinue,
  home,
  widget,
  notification,
  bookmark,
  search,
  tafsir,
  memorization,
  lastRead,
  other;

  /// Opened at a verse found elsewhere: only what is read after the page
  /// it opened on counts.
  bool get countsOnlyAfterLanding =>
      this == search || this == tafsir || this == memorization;
}

/// How an attribution was made. [declined]: an «ask» answered no, kept so
/// it is not asked again (it counts for nothing).
enum DecidedBy { auto, userAccepted, manual, declined }

T? enumNamed<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}

/// A stretch a khatma was paused, both days included; [to] null while it
/// lasts.
class PausePeriod {
  const PausePeriod(this.from, [this.to]);

  final Day from;
  final Day? to;

  bool covers(Day d) => !d.isBefore(from) && (to == null || !d.isAfter(to!));
}

/// A catch-up the reader chose (Recovery): [days] days from [from], each
/// with [extra] weight more than the plan's daily amount.
class RecoveryChoice {
  const RecoveryChoice({
    required this.from,
    required this.days,
    required this.extra,
  });

  final Day from;
  final int days;
  final double extra;

  bool covers(Day d) => !d.isBefore(from) && d.difference(from) < days;

  String toJson() =>
      jsonEncode({'from': from.key, 'days': days, 'extra': extra});

  static RecoveryChoice? fromJson(String? text) {
    if (text == null || text.isEmpty) return null;
    try {
      final m = jsonDecode(text) as Map<String, dynamic>;
      return RecoveryChoice(
        from: Day.parse(m['from'] as String),
        days: m['days'] as int,
        extra: (m['extra'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// A khatma's plan, free of storage: its verses and starting point, its
/// pace and schedule, and how its reading is counted.
class Khatmah {
  const Khatmah({
    required this.uuid,
    required this.title,
    this.kind = KhatmahKind.fullQuran,
    this.rangeStart = 1,
    this.rangeEnd = 6236,
    int? startAt,
    this.pacing = PacingMode.endDate,
    this.schedule = ScheduleMode.adaptive,
    this.dailyWeight,
    required this.startDate,
    this.targetDate,
    this.planFrom,
    this.unit = WirdUnit.page,
    this.restWeekdays = const {},
    this.counting = CountingMode.auto,
    this.isPrimary = false,
    this.status = KhatmahStatus.active,
    this.autoRestart = false,
    this.presetId,
    this.aheadChoice,
    this.recovery,
    this.edition = 'madina1441',
    this.reminderTime,
    this.pauses = const [],
    this.createdAt,
    this.completedAt,
  }) : startAt = startAt ?? rangeStart;

  final String uuid;
  final String title;
  final KhatmahKind kind;

  /// Its verses, `ayah.id`, both ends included.
  final int rangeStart;
  final int rangeEnd;

  /// Where reading starts: the order runs from here to [rangeEnd], then
  /// from [rangeStart] to the verse before it.
  final int startAt;
  final PacingMode pacing;
  final ScheduleMode schedule;

  /// The planned amount a day, in Madina pages.
  final double? dailyWeight;
  final Day startDate;

  /// The last day of the plan; null for an open-ended one.
  final Day? targetDate;

  /// The day the pace is counted from (a catch-up moves it); [startDate]
  /// when null.
  final Day? planFrom;
  final WirdUnit unit;

  /// `DateTime.weekday` values with no portion.
  final Set<int> restWeekdays;
  final CountingMode counting;
  final bool isPrimary;
  final KhatmahStatus status;
  final bool autoRestart;
  final String? presetId;
  final AheadChoice? aheadChoice;
  final RecoveryChoice? recovery;

  /// The edition it was made in: for showing only.
  final String edition;
  final int? reminderTime;
  final List<PausePeriod> pauses;
  final DateTime? createdAt;
  final DateTime? completedAt;

  Day get paceFrom => planFrom ?? startDate;

  KhatmahOrder get order => KhatmahOrder(rangeStart, rangeEnd, startAt);
  IntervalSet get range => IntervalSet.range(rangeStart, rangeEnd);

  bool get isActive => status == KhatmahStatus.active;
  bool get isOpen =>
      status == KhatmahStatus.active || status == KhatmahStatus.paused;

  bool pausedOn(Day d) => pauses.any((p) => p.covers(d));

  bool restsOn(Day d) => restWeekdays.contains(d.start.weekday);

  /// A day with a portion: not a rest day, not paused.
  bool readsOn(Day d) => !restsOn(d) && !pausedOn(d);

  Khatmah copyWith({
    String? uuid,
    String? title,
    KhatmahKind? kind,
    int? rangeStart,
    int? rangeEnd,
    int? startAt,
    PacingMode? pacing,
    ScheduleMode? schedule,
    double? Function()? dailyWeight,
    Day? startDate,
    Day? Function()? targetDate,
    Day? Function()? planFrom,
    WirdUnit? unit,
    Set<int>? restWeekdays,
    CountingMode? counting,
    bool? isPrimary,
    KhatmahStatus? status,
    bool? autoRestart,
    String? Function()? presetId,
    AheadChoice? Function()? aheadChoice,
    RecoveryChoice? Function()? recovery,
    String? edition,
    int? Function()? reminderTime,
    List<PausePeriod>? pauses,
    DateTime? Function()? createdAt,
    DateTime? Function()? completedAt,
  }) => Khatmah(
    uuid: uuid ?? this.uuid,
    title: title ?? this.title,
    kind: kind ?? this.kind,
    rangeStart: rangeStart ?? this.rangeStart,
    rangeEnd: rangeEnd ?? this.rangeEnd,
    startAt: startAt ?? this.startAt,
    pacing: pacing ?? this.pacing,
    schedule: schedule ?? this.schedule,
    dailyWeight: dailyWeight == null ? this.dailyWeight : dailyWeight(),
    startDate: startDate ?? this.startDate,
    targetDate: targetDate == null ? this.targetDate : targetDate(),
    planFrom: planFrom == null ? this.planFrom : planFrom(),
    unit: unit ?? this.unit,
    restWeekdays: restWeekdays ?? this.restWeekdays,
    counting: counting ?? this.counting,
    isPrimary: isPrimary ?? this.isPrimary,
    status: status ?? this.status,
    autoRestart: autoRestart ?? this.autoRestart,
    presetId: presetId == null ? this.presetId : presetId(),
    aheadChoice: aheadChoice == null ? this.aheadChoice : aheadChoice(),
    recovery: recovery == null ? this.recovery : recovery(),
    edition: edition ?? this.edition,
    reminderTime: reminderTime == null ? this.reminderTime : reminderTime(),
    pauses: pauses ?? this.pauses,
    createdAt: createdAt == null ? this.createdAt : createdAt(),
    completedAt: completedAt == null ? this.completedAt : completedAt(),
  );
}

/// `5` → {5}; `1,5` → {1, 5}.
Set<int> parseWeekdays(String text) => {
  for (final p in text.split(','))
    if (int.tryParse(p.trim()) case final d? when d >= 1 && d <= 7) d,
};

String weekdaysText(Set<int> days) => (days.toList()..sort()).join(',');

/// The part of a reading session counted for a khatma (an attribution).
class Credit {
  const Credit({
    required this.sessionUuid,
    required this.khatmaUuid,
    required this.ranges,
    required this.newWeight,
    required this.decidedBy,
    required this.day,
    required this.at,
    this.undone = false,
  });

  final String sessionUuid;
  final String khatmaUuid;

  /// The verses counted (new to the khatma when counted).
  final IntervalSet ranges;
  final double newWeight;
  final DecidedBy decidedBy;
  final bool undone;

  /// The session's logical day, and when it started.
  final Day day;
  final DateTime at;

  /// Counted: not undone, not declined.
  bool get counts => !undone && decidedBy != DecidedBy.declined;

  Credit copyWith({
    IntervalSet? ranges,
    double? newWeight,
    DecidedBy? decidedBy,
    bool? undone,
  }) => Credit(
    sessionUuid: sessionUuid,
    khatmaUuid: khatmaUuid,
    ranges: ranges ?? this.ranges,
    newWeight: newWeight ?? this.newWeight,
    decidedBy: decidedBy ?? this.decidedBy,
    day: day,
    at: at,
    undone: undone ?? this.undone,
  );
}

/// A khatma's reading order: from [startAt] to [end], then from [start]
/// to the verse before [startAt]. Every position-based calculation (the
/// frontier, the days' portions) goes through it.
class KhatmahOrder {
  KhatmahOrder(this.start, this.end, int startAt)
    : startAt = startAt < start || startAt > end ? start : startAt;

  final int start;
  final int end;
  final int startAt;

  int get length => end - start + 1;

  /// The position (0-based) of verse [id] in the order.
  int indexOf(int id) {
    assert(id >= start && id <= end);
    return id >= startAt ? id - startAt : end - startAt + 1 + id - start;
  }

  /// The verse at position [k].
  int idAt(int k) {
    assert(k >= 0 && k < length);
    final first = end - startAt + 1;
    return k < first ? startAt + k : start + k - first;
  }

  /// The order's two runs of verses, in reading order.
  List<AyahRange> get segments => [
    (from: startAt, to: end),
    if (startAt > start) (from: start, to: startAt - 1),
  ];

  /// The verses at positions [a] … [b] (both included), as verse runs.
  IntervalSet span(int a, int b) {
    if (b < a) return IntervalSet.empty;
    final from = idAt(max(0, a));
    final to = idAt(min(length - 1, b));
    if (from <= to) return IntervalSet.range(from, to);
    return IntervalSet([(from: from, to: end), (from: start, to: to)]);
  }

  /// The first verse in the order not in [covered]; null when every verse
  /// is.
  int? frontier(IntervalSet covered) {
    for (final s in segments) {
      final gap = covered.firstGap(s.from, s.to);
      if (gap != null) return gap;
    }
    return null;
  }
}

/// What a khatma's attributions add up to: its coverage, and what each
/// logical day added. Replayed in the order the sessions started, so the
/// weight a day added never counts a verse twice, and undoing a credit
/// gives the numbers as they were without it. The caches (khatma_coverage,
/// daily_stat) are this, kept.
class Ledger {
  factory Ledger(
    Khatmah khatmah,
    Iterable<Credit> credits,
    QuranIndex index, {
    Map<String, int> sessionSeconds = const {},
  }) {
    final counted = [
      for (final c in credits)
        if (c.counts && c.khatmaUuid == khatmah.uuid) c,
    ]..sort(_byTime);
    final range = khatmah.range;
    var covered = IntervalSet.empty;
    final weights = <Day, double>{};
    final sessions = <Day, Set<String>>{};
    final seconds = <Day, int>{};
    for (final c in counted) {
      final fresh = c.ranges.intersect(range).subtract(covered);
      covered = covered.union(fresh);
      weights[c.day] = (weights[c.day] ?? 0) + fresh.weigh(index.weightOf);
      if ((sessions[c.day] ??= {}).add(c.sessionUuid)) {
        seconds[c.day] =
            (seconds[c.day] ?? 0) + (sessionSeconds[c.sessionUuid] ?? 0);
      }
    }
    return Ledger._(
      khatmah,
      counted,
      covered,
      covered.weigh(index.weightOf),
      weights,
      {for (final e in sessions.entries) e.key: e.value.length},
      seconds,
    );
  }

  Ledger._(
    this.khatmah,
    this._credits,
    this.covered,
    this.coveredWeight,
    this.dailyWeight,
    this.dailySessions,
    this.dailySeconds,
  );

  static int _byTime(Credit a, Credit b) {
    final t = a.at.compareTo(b.at);
    return t != 0 ? t : a.sessionUuid.compareTo(b.sessionUuid);
  }

  final Khatmah khatmah;
  final List<Credit> _credits;

  /// The khatma's verses read.
  final IntervalSet covered;
  final double coveredWeight;

  /// Weight newly read on each logical day, sessions and seconds.
  final Map<Day, double> dailyWeight;
  final Map<Day, int> dailySessions;
  final Map<Day, int> dailySeconds;

  /// The coverage before [day] began (credits of earlier days).
  IntervalSet coveredBefore(Day day) => IntervalSet([
    for (final c in _credits)
      if (c.day.isBefore(day)) ...c.ranges.intersect(khatmah.range).ranges,
  ]);

  /// The first unread verse in the khatma's order; null once complete.
  int? get frontier => khatmah.order.frontier(covered);

  bool get complete =>
      covered.containsRange(khatmah.rangeStart, khatmah.rangeEnd);

  double weightOn(Day d) => dailyWeight[d] ?? 0;
}
