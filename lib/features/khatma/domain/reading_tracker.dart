import 'dart:math';

import 'interval_set.dart';

/// A page shown in the page view long enough to count as read.
typedef PageRead = ({int page, String edition, DateTime at, String session});

/// Verses (`ayah.id`) read in «آية آية» or the continuous view, or heard.
typedef VersesRead = ({IntervalSet verses, DateTime at, String session});

/// A stretch of reading.
typedef ReadingSpan = ({
  DateTime start,
  DateTime end,
  int pages,
  String edition,
  String session,

  /// Time spent reading: idle stretches and time covered by another
  /// screen left out.
  int activeSeconds,

  /// `page`, `scroll`, `verse` or `continuous`.
  String mode,

  /// Verses read in the verse views (pages are in [pages]).
  IntervalSet verses,
});

/// A random id for a session (RFC 4122 version 4).
String randomSessionId() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = [for (final x in b) x.toRadixString(16).padLeft(2, '0')].join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

/// Follows a reading view and says what was read.
///
/// - **Pages** ([show]): a page counts once it has stayed on screen for
///   [minDwell] times its weight (in Madina pages, [pageWeight]), and never
///   less than [minPageDwell]; two facing pages need the time of both.
///   Flipping past pages counts nothing.
/// - **One verse at a time** ([showVerse]): a verse counts after [minDwell]
///   times its weight ([verseWeight]), and never less than [minVerseDwell].
/// - **The continuous view** ([showVerses]): each verse in the reading zone
///   gathers time while it is there, and counts once it has enough.
///
/// A session runs from the first thing shown until the view is left or the
/// app hidden ([end]). Its active time stops after [idleAfter] without a
/// touch or a turn ([touch]), and while another screen covers the view
/// ([freeze]) or while it is in a hifz test or recitation mode
/// ([suspend]): then nothing counts, and what is on screen starts its wait
/// again when the view is back. Opened at a verse found elsewhere (search,
/// tafsir, hifz), only what comes after the page or verse it landed on
/// counts ([onlyAfterPage], [onlyAfterVerse]).
///
/// Nothing is stored here: the callbacks do that.
class ReadingTracker {
  ReadingTracker({
    required this.onPageRead,
    required this.onSessionEnd,
    this.onVersesRead,
    DateTime Function()? clock,
    this.minDwell = const Duration(seconds: 20),
    this.minSession = const Duration(seconds: 20),
    this.idleAfter = const Duration(minutes: 3),
    double Function(int page, String edition)? pageWeight,
    double Function(int id)? verseWeight,
    String Function()? newSession,
    this.mode = 'page',
  }) : _now = clock ?? DateTime.now,
       _pageWeight = pageWeight ?? _one,
       _verseWeight = verseWeight ?? _oneVerse,
       _newSession = newSession ?? randomSessionId;

  static double _one(int page, String edition) => 1;
  static double _oneVerse(int id) => 1 / 15;

  /// The least a page, and a verse, must stay on screen.
  static const minPageDwell = Duration(seconds: 5);
  static const minVerseDwell = Duration(seconds: 2);

  final void Function(PageRead read) onPageRead;
  final void Function(ReadingSpan span) onSessionEnd;
  final void Function(VersesRead read)? onVersesRead;
  final DateTime Function() _now;

  /// The time a whole Madina page needs (the reading speed).
  Duration minDwell;

  /// Shorter visits with nothing read are not recorded.
  final Duration minSession;
  final Duration idleAfter;
  final double Function(int page, String edition) _pageWeight;
  final double Function(int id) _verseWeight;
  final String Function() _newSession;

  /// `page`, `scroll` (auto-scroll), `verse` or `continuous`.
  String mode;

  /// Only pages after this one count (the page a search opened).
  int? onlyAfterPage;

  /// Only verses after this one count.
  int? onlyAfterVerse;

  DateTime? _sessionStart;
  String? _session;
  String _edition = '';
  int? _page;

  /// The facing page of a spread, shown with [_page].
  int? _also;
  DateTime? _shownAt;
  final Set<int> _read = {};

  int? _verse;
  DateTime? _verseAt;
  final Set<int> _verses = {};

  /// The continuous view: verses in the reading zone since [_zoneSince],
  /// and the time each has gathered.
  Set<int> _zone = const {};
  DateTime? _zoneSince;
  final Map<int, Duration> _gathered = {};

  bool _frozen = false;
  bool _suspended = false;
  Duration _active = Duration.zero;
  DateTime? _accountedTo;
  DateTime? _lastTouch;

  bool get _paused => _frozen || _suspended;

  /// The session under way, if any.
  String? get session => _session;

  void _begin(DateTime now) {
    if (_sessionStart != null) return;
    _sessionStart = now;
    _session = _newSession();
    _accountedTo = now;
    _lastTouch = now;
    _active = Duration.zero;
  }

  /// Adds the active time up to [now]: none while paused, and none past
  /// [idleAfter] since the last touch.
  void _account(DateTime now) {
    final from = _accountedTo;
    if (_sessionStart == null || from == null) return;
    if (!_paused) {
      final limit = _lastTouch!.add(idleAfter);
      final until = now.isBefore(limit) ? now : limit;
      if (until.isAfter(from)) _active += until.difference(from);
    }
    _accountedTo = now;
  }

  /// The reader touched or turned something: the active time goes on.
  void touch() {
    final now = _now();
    _account(now);
    _lastTouch = now;
  }

  Duration _pageDwell(List<int> pages) {
    var w = 0.0;
    for (final p in pages) {
      w += _pageWeight(p, _edition);
    }
    final need = minDwell * w;
    final least = minPageDwell * pages.length;
    return need < least ? least : need;
  }

  Duration _verseDwell(int id) {
    final need = minDwell * _verseWeight(id);
    return need < minVerseDwell ? minVerseDwell : need;
  }

  /// [page] of [edition] is now on screen; [also], the page facing it in
  /// a spread.
  void show(int page, String edition, {int? also}) {
    final now = _now();
    _commit(now);
    if (_sessionStart != null && _edition != edition) end();
    _begin(now);
    _account(now);
    _lastTouch = now;
    _edition = edition;
    _page = page;
    _also = also;
    _shownAt = _paused ? null : now;
  }

  /// No page is on screen (a cover): the page before counts if it stayed
  /// long enough; the session goes on.
  void leavePage() {
    _commit(_now());
    _page = null;
    _also = null;
  }

  /// «آية آية»: verse [id] is on screen.
  void showVerse(int id, {String edition = ''}) {
    final now = _now();
    _commitVerse(now);
    _begin(now);
    _account(now);
    _lastTouch = now;
    if (edition.isNotEmpty) _edition = edition;
    _verse = id;
    _verseAt = _paused ? null : now;
  }

  /// The continuous view: [ids] are the verses in the reading zone now.
  void showVerses(Iterable<int> ids, {String edition = ''}) {
    final now = _now();
    _gather(now);
    _begin(now);
    _account(now);
    if (edition.isNotEmpty) _edition = edition;
    _zone = ids.toSet();
    _zoneSince = _paused ? null : now;
  }

  /// Another screen now covers the view (true), or is gone (false).
  void freeze(bool on) => _pause(on, suspend: false);

  /// A hifz test or recitation mode is under way (true), or over.
  void suspend(bool on) => _pause(on, suspend: true);

  void _pause(bool on, {required bool suspend}) {
    final was = _paused;
    final now = _now();
    if (on && !was) {
      // What stayed long enough before counts; the rest waits.
      _commit(now);
      _commitVerse(now);
      _gather(now);
    }
    _account(now);
    if (suspend) {
      _suspended = on;
    } else {
      _frozen = on;
    }
    if (was && !_paused) {
      // Back: what is on screen starts its wait again.
      _lastTouch = now;
      if (_page != null) _shownAt = now;
      if (_verse != null) _verseAt = now;
      if (_zone.isNotEmpty) _zoneSince = now;
    } else if (_paused) {
      _shownAt = null;
      _verseAt = null;
      _zoneSince = null;
    }
  }

  /// The view is left or hidden: what is on screen counts if it stayed
  /// long enough, and the session is recorded.
  void end() {
    final start = _sessionStart;
    if (start == null) return;
    final now = _now();
    _commit(now);
    _commitVerse(now);
    _gather(now);
    _account(now);
    if (_read.isNotEmpty || _verses.isNotEmpty || _active >= minSession) {
      onSessionEnd((
        start: start,
        end: now,
        pages: _read.length,
        edition: _edition,
        session: _session!,
        activeSeconds: _active.inSeconds,
        mode: mode,
        verses: IntervalSet.of(_verses),
      ));
    }
    _sessionStart = null;
    _session = null;
    _page = null;
    _also = null;
    _shownAt = null;
    _verse = null;
    _verseAt = null;
    _zone = const {};
    _zoneSince = null;
    _gathered.clear();
    _read.clear();
    _verses.clear();
    _accountedTo = null;
  }

  void _commit(DateTime now) {
    final page = _page;
    final shown = _shownAt;
    if (page == null || shown == null) return;
    final pages = [page, ?_also];
    if (now.difference(shown) >= _pageDwell(pages)) {
      for (final p in pages) {
        final after = onlyAfterPage;
        if (after != null && p <= after) continue;
        if (_read.add(p)) {
          onPageRead((page: p, edition: _edition, at: now, session: _session!));
        }
      }
    }
    // Counted once per showing.
    _shownAt = null;
  }

  void _commitVerse(DateTime now) {
    final id = _verse;
    final shown = _verseAt;
    if (id == null || shown == null) return;
    if (now.difference(shown) >= _verseDwell(id)) _readVerses([id], now);
    _verseAt = null;
  }

  void _gather(DateTime now) {
    final since = _zoneSince;
    if (since == null || _zone.isEmpty) return;
    final add = now.difference(since);
    final done = <int>[];
    for (final id in _zone) {
      final total = (_gathered[id] ?? Duration.zero) + add;
      _gathered[id] = total;
      if (total >= _verseDwell(id)) done.add(id);
    }
    _zoneSince = now;
    _readVerses(done, now);
  }

  void _readVerses(List<int> ids, DateTime now) {
    final fresh = [
      for (final id in ids)
        if ((onlyAfterVerse == null || id > onlyAfterVerse!) && _verses.add(id))
          id,
    ];
    if (fresh.isEmpty) return;
    onVersesRead?.call((
      verses: IntervalSet.of(fresh),
      at: now,
      session: _session!,
    ));
  }
}

/// Verses heard to their end while listening (decision: listening counts
/// when the setting is on). A session runs while the recitation plays;
/// a verse skipped or jumped over never reaches [heard].
class ListeningCounter {
  ListeningCounter({
    required this.onHeard,
    required this.onSessionEnd,
    DateTime Function()? clock,
    String Function()? newSession,
  }) : _now = clock ?? DateTime.now,
       _newSession = newSession ?? randomSessionId;

  final void Function(VersesRead read) onHeard;

  /// (session, start, end, verses heard).
  final void Function(
    String session,
    DateTime start,
    DateTime end,
    IntervalSet verses,
  )
  onSessionEnd;
  final DateTime Function() _now;
  final String Function() _newSession;

  String? _session;
  DateTime? _start;
  IntervalSet _heard = IntervalSet.empty;

  /// The recitation started or stopped playing.
  void playing(bool on) {
    if (on) {
      if (_session != null) return;
      _session = _newSession();
      _start = _now();
      _heard = IntervalSet.empty;
      return;
    }
    final s = _session;
    if (s == null) return;
    _session = null;
    if (_heard.isNotEmpty) onSessionEnd(s, _start!, _now(), _heard);
  }

  /// The verses ([ids], `ayah.id`) of the verse just recited to its end.
  void heard(IntervalSet ids) {
    if (ids.isEmpty) return;
    if (_session == null) playing(true);
    final fresh = ids.subtract(_heard);
    if (fresh.isEmpty) return;
    _heard = _heard.union(fresh);
    onHeard((verses: fresh, at: _now(), session: _session!));
  }
}
