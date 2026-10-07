/// What the reader recites in one session of audio tasmee: one of the eight
/// kinds of range of the plan, on the new Madina mushaf (1441H).
///
/// A range is resolved against the verse index ([VerseIndexEntry], from
/// content.db `ayah`) to the verses it covers; a page range also cuts the
/// verses at its first and last page, word by word ([containsWord]).
library;

/// The fields of a content.db `ayah` row that place a verse in the
/// divisions of the mushaf.
class VerseIndexEntry {
  const VerseIndexEntry({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.juz,
    required this.hizbQuarter,
    required this.page,
  });

  /// 1..6236 in mushaf order.
  final int id;
  final int surah;
  final int ayah;

  /// 1..30.
  final int juz;

  /// 1..240: quarter q is in hizb (q - 1) ~/ 4 + 1.
  final int hizbQuarter;

  /// The page of the new edition (1441H) where the verse starts.
  final int page;

  /// 1..60.
  int get hizb => (hizbQuarter - 1) ~/ 4 + 1;

  /// 1..4 within [hizb].
  int get quarterInHizb => (hizbQuarter - 1) % 4 + 1;
}

/// The last page of the new edition.
const lastMushafPage = 604;

/// The eight kinds of range of the plan.
enum RecitationRangeKind {
  surah,
  juz,
  hizb,
  quarter,
  halfHizb,
  threeQuartersHizb,
  pages,
  verses,
}

sealed class RecitationRange {
  const RecitationRange();

  RecitationRangeKind get kind;

  /// Whether the whole of [verse] is in the range; for a page range,
  /// whether any of its words may be (see [containsWord]).
  bool containsVerse(VerseIndexEntry verse);

  /// Whether a word of a verse in the range, on [page], is in the range.
  /// Only a page range cuts verses.
  bool containsWord(VerseIndexEntry verse, int page) => containsVerse(verse);

  /// Throws [RangeError] when the range does not exist in the mushaf.
  void validate();

  /// The verses of the range, in mushaf order, from [index] (every verse,
  /// in order). For a page range this includes the verse that starts on
  /// the page before and runs onto the first page of the range.
  List<VerseIndexEntry> versesIn(List<VerseIndexEntry> index) {
    validate();
    return [
      for (final v in index)
        if (containsVerse(v)) v,
    ];
  }
}

/// One surah.
final class SurahRange extends RecitationRange {
  const SurahRange(this.surah);
  final int surah;

  @override
  RecitationRangeKind get kind => RecitationRangeKind.surah;

  @override
  bool containsVerse(VerseIndexEntry verse) => verse.surah == surah;

  @override
  void validate() => RangeError.checkValueInInterval(surah, 1, 114, 'surah');

  @override
  bool operator ==(Object other) => other is SurahRange && other.surah == surah;
  @override
  int get hashCode => Object.hash(SurahRange, surah);
  @override
  String toString() => 'SurahRange($surah)';
}

/// One juz.
final class JuzRange extends RecitationRange {
  const JuzRange(this.juz);
  final int juz;

  @override
  RecitationRangeKind get kind => RecitationRangeKind.juz;

  @override
  bool containsVerse(VerseIndexEntry verse) => verse.juz == juz;

  @override
  void validate() => RangeError.checkValueInInterval(juz, 1, 30, 'juz');

  @override
  bool operator ==(Object other) => other is JuzRange && other.juz == juz;
  @override
  int get hashCode => Object.hash(JuzRange, juz);
  @override
  String toString() => 'JuzRange($juz)';
}

/// Quarters [fromQuarter]..[toQuarter] (1..4) of one hizb: the hizb, a
/// quarter of it, a half or three quarters. The four kinds of the plan are
/// the named constructors.
final class HizbPartRange extends RecitationRange {
  const HizbPartRange._(this.hizb, this.fromQuarter, this.toQuarter);

  /// A whole hizb (1..60).
  const HizbPartRange.hizb(int hizb) : this._(hizb, 1, 4);

  /// One quarter: [quarter] 1..240, counted through the mushaf (as the
  /// `hizb_quarter` column).
  HizbPartRange.quarter(int quarter)
    : this._(
        (quarter - 1) ~/ 4 + 1,
        (quarter - 1) % 4 + 1,
        (quarter - 1) % 4 + 1,
      );

  /// The first ([half] 1) or second ([half] 2) half of a hizb.
  HizbPartRange.half(int hizb, int half)
    : this._(hizb, half == 2 ? 3 : 1, half == 2 ? 4 : 2);

  /// Three quarters of a hizb, from its first quarter, or from its second
  /// when [fromSecond].
  const HizbPartRange.threeQuarters(int hizb, {bool fromSecond = false})
    : this._(hizb, fromSecond ? 2 : 1, fromSecond ? 4 : 3);

  final int hizb;
  final int fromQuarter;
  final int toQuarter;

  @override
  RecitationRangeKind get kind => switch (toQuarter - fromQuarter + 1) {
    4 => RecitationRangeKind.hizb,
    3 => RecitationRangeKind.threeQuartersHizb,
    2 => RecitationRangeKind.halfHizb,
    _ => RecitationRangeKind.quarter,
  };

  /// The first quarter (1..240) through the mushaf.
  int get firstQuarter => (hizb - 1) * 4 + fromQuarter;
  int get lastQuarter => (hizb - 1) * 4 + toQuarter;

  @override
  bool containsVerse(VerseIndexEntry verse) =>
      verse.hizbQuarter >= firstQuarter && verse.hizbQuarter <= lastQuarter;

  @override
  void validate() {
    RangeError.checkValueInInterval(hizb, 1, 60, 'hizb');
    RangeError.checkValueInInterval(fromQuarter, 1, 4, 'fromQuarter');
    RangeError.checkValueInInterval(toQuarter, fromQuarter, 4, 'toQuarter');
  }

  @override
  bool operator ==(Object other) =>
      other is HizbPartRange &&
      other.hizb == hizb &&
      other.fromQuarter == fromQuarter &&
      other.toQuarter == toQuarter;
  @override
  int get hashCode => Object.hash(HizbPartRange, hizb, fromQuarter, toQuarter);
  @override
  String toString() => 'HizbPartRange($hizb, $fromQuarter..$toQuarter)';
}

/// Pages [from]..[to] of the new edition, word by word: a verse that runs
/// over the first or last page is cut there.
final class PageRange extends RecitationRange {
  const PageRange(this.from, [int? to]) : to = to ?? from;
  final int from;
  final int to;

  @override
  RecitationRangeKind get kind => RecitationRangeKind.pages;

  @override
  bool containsVerse(VerseIndexEntry verse) =>
      // A verse that starts on the page before may end on [from].
      verse.page >= from - 1 && verse.page <= to;

  @override
  bool containsWord(VerseIndexEntry verse, int page) =>
      page >= from && page <= to;

  @override
  void validate() {
    RangeError.checkValueInInterval(from, 1, lastMushafPage, 'from');
    RangeError.checkValueInInterval(to, from, lastMushafPage, 'to');
  }

  @override
  bool operator ==(Object other) =>
      other is PageRange && other.from == from && other.to == to;
  @override
  int get hashCode => Object.hash(PageRange, from, to);
  @override
  String toString() => 'PageRange($from..$to)';
}

/// From one verse to another, both included, possibly across surahs.
final class VerseRange extends RecitationRange {
  const VerseRange({
    required this.fromSurah,
    required this.fromAyah,
    required this.toSurah,
    required this.toAyah,
  });

  final int fromSurah;
  final int fromAyah;
  final int toSurah;
  final int toAyah;

  @override
  RecitationRangeKind get kind => RecitationRangeKind.verses;

  int _key(int surah, int ayah) => surah * 1000 + ayah;

  @override
  bool containsVerse(VerseIndexEntry verse) {
    final k = _key(verse.surah, verse.ayah);
    return k >= _key(fromSurah, fromAyah) && k <= _key(toSurah, toAyah);
  }

  @override
  void validate() {
    RangeError.checkValueInInterval(fromSurah, 1, 114, 'fromSurah');
    RangeError.checkValueInInterval(toSurah, fromSurah, 114, 'toSurah');
    RangeError.checkValueInInterval(fromAyah, 1, 286, 'fromAyah');
    RangeError.checkValueInInterval(toAyah, 1, 286, 'toAyah');
    if (_key(toSurah, toAyah) < _key(fromSurah, fromAyah)) {
      throw RangeError('The range ends before it starts');
    }
  }

  @override
  List<VerseIndexEntry> versesIn(List<VerseIndexEntry> index) {
    final verses = super.versesIn(index);
    bool has(int s, int a) => verses.any((v) => v.surah == s && v.ayah == a);
    if (!has(fromSurah, fromAyah) || !has(toSurah, toAyah)) {
      throw RangeError('No such verse: $this');
    }
    return verses;
  }

  @override
  bool operator ==(Object other) =>
      other is VerseRange &&
      other.fromSurah == fromSurah &&
      other.fromAyah == fromAyah &&
      other.toSurah == toSurah &&
      other.toAyah == toAyah;
  @override
  int get hashCode =>
      Object.hash(VerseRange, fromSurah, fromAyah, toSurah, toAyah);
  @override
  String toString() => 'VerseRange($fromSurah:$fromAyah..$toSurah:$toAyah)';
}
