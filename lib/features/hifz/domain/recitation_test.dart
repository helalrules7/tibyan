import 'dart:ui' show Rect;

import 'strength.dart';

/// A verse (the same record type as the mushaf's VerseKey).
typedef TestVerse = ({int surah, int ayah});

/// The pieces a covered verse is revealed in, in reading order, in the
/// edition's page units: one per word where the page has the verse's word
/// boxes ([byWord]), otherwise one per line of the verse.
class RevealUnits {
  const RevealUnits(this.pieces, {required this.byWord});

  final List<List<Rect>> pieces;
  final bool byWord;

  int get length => pieces.length;
}

/// A word-by-word recitation test on one page: which pieces of each verse
/// are revealed, and how the reader judged each verse. Reveals are per
/// page; the verse results last the whole session.
class RecitationTest {
  final Map<TestVerse, int> _shown = {};
  final Map<TestVerse, VerseResult> results = {};

  /// The verse being recited: the last one revealed into or tapped.
  TestVerse? current;

  int shown(TestVerse v) => _shown[v] ?? 0;

  /// A verse without known pieces counts as one piece.
  static int _length(RevealUnits? u) =>
      u == null || u.length == 0 ? 1 : u.length;

  bool isRevealed(TestVerse v, RevealUnits? u) => shown(v) >= _length(u);

  /// Reveals the next piece of the first verse (in [order]) that is not
  /// fully revealed; returns that verse, or null when all are revealed.
  TestVerse? revealNext(
    List<TestVerse> order,
    Map<TestVerse, RevealUnits> units,
  ) {
    for (final v in order) {
      if (!isRevealed(v, units[v])) {
        _shown[v] = shown(v) + 1;
        return current = v;
      }
    }
    return null;
  }

  /// Reveals the next piece of [v] (the reader tapped it).
  void revealPiece(TestVerse v, RevealUnits? u) {
    current = v;
    if (!isRevealed(v, u)) _shown[v] = shown(v) + 1;
  }

  /// Reveals the rest of [v].
  void revealVerse(TestVerse v, RevealUnits? u) {
    current = v;
    _shown[v] = _length(u);
  }

  /// Reveals the next whole verse.
  TestVerse? revealNextVerse(
    List<TestVerse> order,
    Map<TestVerse, RevealUnits> units,
  ) {
    for (final v in order) {
      if (!isRevealed(v, units[v])) {
        revealVerse(v, units[v]);
        return v;
      }
    }
    return null;
  }

  void revealAll(List<TestVerse> order, Map<TestVerse, RevealUnits> units) {
    for (final v in order) {
      _shown[v] = _length(units[v]);
    }
  }

  /// Records the reader's judgement of [v] and reveals it all; the next
  /// verse becomes current.
  void grade(
    TestVerse v,
    VerseResult r,
    List<TestVerse> order,
    Map<TestVerse, RevealUnits> units,
  ) {
    results[v] = r;
    _shown[v] = _length(units[v]);
    final i = order.indexOf(v);
    current = i >= 0 && i + 1 < order.length ? order[i + 1] : null;
  }

  /// A new page: nothing revealed there yet.
  void newPage() {
    _shown.clear();
    current = null;
  }

  /// The pieces already shown of each verse that is still partly covered.
  Map<TestVerse, List<Rect>> shownPieces(
    List<TestVerse> order,
    Map<TestVerse, RevealUnits> units,
  ) => {
    for (final v in order)
      if (units[v] case final u? when shown(v) > 0 && !isRevealed(v, u))
        v: [for (final p in u.pieces.take(shown(v))) ...p],
  };

  /// What to cover on the page: the verses not fully revealed, and for
  /// each the pieces still covered (absent: the whole verse).
  ({Set<TestVerse> hidden, Map<TestVerse, List<Rect>> pieces}) covers(
    List<TestVerse> order,
    Map<TestVerse, RevealUnits> units,
  ) {
    final hidden = <TestVerse>{};
    final pieces = <TestVerse, List<Rect>>{};
    for (final v in order) {
      final u = units[v];
      if (isRevealed(v, u)) continue;
      hidden.add(v);
      if (u != null && u.length > 0) {
        pieces[v] = [for (final p in u.pieces.skip(shown(v))) ...p];
      }
    }
    return (hidden: hidden, pieces: pieces);
  }
}
