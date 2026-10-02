import 'fsrs.dart';

/// How firmly a verse, page or surah is memorized, for the hifz map.
/// [none] is not memorized (no row); the four others are stored as 1..4.
enum Strength {
  none,
  weak,
  fair,
  good,
  strong;

  int get level => index;

  static Strength of(int? level) =>
      level == null ? none : Strength.values[level.clamp(0, 4)];

  /// From a unit's FSRS stability (days to 90% recall): under 3 days weak,
  /// under 2 weeks fair, under 2 months good, beyond that strong.
  static Strength fromStability(double days) => days < 3
      ? weak
      : days < 14
      ? fair
      : days < 60
      ? good
      : strong;
}

/// A verse checked in a recitation test.
enum VerseResult { remembered, missed }

/// The verse's strength after a test: a missed verse becomes weak; a
/// remembered one becomes at least fair.
Strength afterVerseTest(Strength before, VerseResult r) =>
    r == VerseResult.missed
    ? Strength.weak
    : (before.level < Strength.fair.level ? Strength.fair : before);

/// The grade suggested for a unit from its verse results: no verse missed
/// is good; up to a quarter missed is hard; more is again. The reader
/// chooses; this only preselects.
Grade suggestGrade(Iterable<VerseResult> results) {
  final all = results.toList();
  if (all.isEmpty) return Grade.good;
  final missed = all.where((r) => r == VerseResult.missed).length;
  if (missed == 0) return Grade.good;
  return missed / all.length <= 0.25 ? Grade.hard : Grade.again;
}

/// Strength of each cell of the map (a page or a surah) from the
/// strengths of its verses: the weakest memorized verse, so weak spots
/// show; cells with no memorized verse are [Strength.none].
/// [cellOf] gives a verse's cells (a Shamarly verse may span two pages).
Map<int, Strength> cellStrengths(
  Map<String, int> verseStrengths,
  Iterable<int> Function(String verseRef) cellOf,
) {
  final out = <int, Strength>{};
  for (final e in verseStrengths.entries) {
    final s = Strength.of(e.value);
    if (s == Strength.none) continue;
    for (final cell in cellOf(e.key)) {
      final old = out[cell];
      if (old == null || s.level < old.level) out[cell] = s;
    }
  }
  return out;
}

/// `surah:ayah`, the reference used in the hifz tables.
String verseRef(int surah, int ayah) => '$surah:$ayah';

(int, int) parseVerseRef(String ref) {
  final i = ref.indexOf(':');
  return (int.parse(ref.substring(0, i)), int.parse(ref.substring(i + 1)));
}
