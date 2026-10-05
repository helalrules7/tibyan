/// A page shown in the page view long enough to count as read.
typedef PageRead = ({int page, String edition, DateTime at});

/// A stretch of reading in the page view.
typedef ReadingSpan = ({
  DateTime start,
  DateTime end,
  int pages,
  String edition,
});

/// Follows the page view: a page counts as read once it has stayed on
/// screen for [minDwell]; a session runs from the first page shown until
/// the reader leaves the page view or the app goes to the background.
///
/// Nothing is stored here: [onPageRead] and [onSessionEnd] do that.
class ReadingTracker {
  ReadingTracker({
    required this.onPageRead,
    required this.onSessionEnd,
    DateTime Function()? clock,
    this.minDwell = const Duration(seconds: 15),
    this.minSession = const Duration(seconds: 20),
  }) : _now = clock ?? DateTime.now;

  final void Function(PageRead read) onPageRead;
  final void Function(ReadingSpan span) onSessionEnd;
  final DateTime Function() _now;
  final Duration minDwell;

  /// Shorter visits with no page read are not recorded.
  final Duration minSession;

  DateTime? _sessionStart;
  String? _edition;
  int? _page;

  /// The facing page of a spread, shown with [_page].
  int? _also;
  DateTime? _shownAt;
  final Set<int> _read = {};

  /// [page] of [edition] is now on screen; [also], the page facing it in
  /// a spread. Two pages on screen both count once they have stayed twice
  /// as long ([minDwell] for each).
  void show(int page, String edition, {int? also}) {
    final now = _now();
    _commit(now);
    if (_edition != null && _edition != edition) end();
    _sessionStart ??= now;
    _edition = edition;
    _page = page;
    _also = also;
    _shownAt = now;
  }

  /// No page is on screen (a cover): the page before counts if it stayed
  /// long enough; the session goes on.
  void leavePage() {
    _commit(_now());
    _page = null;
    _also = null;
  }

  /// The page view is left or hidden: the page on screen counts if it
  /// stayed long enough, and the session is recorded.
  void end() {
    final start = _sessionStart;
    if (start == null) return;
    final now = _now();
    _commit(now);
    if (_read.isNotEmpty || now.difference(start) >= minSession) {
      onSessionEnd((
        start: start,
        end: now,
        pages: _read.length,
        edition: _edition!,
      ));
    }
    _sessionStart = null;
    _page = null;
    _shownAt = null;
    _read.clear();
  }

  void _commit(DateTime now) {
    final page = _page;
    final shown = _shownAt;
    if (page == null || shown == null) return;
    final pages = [page, ?_also];
    if (now.difference(shown) >= minDwell * pages.length) {
      for (final p in pages) {
        if (_read.add(p)) onPageRead((page: p, edition: _edition!, at: now));
      }
    }
    // Counted once per showing.
    _shownAt = null;
  }
}
