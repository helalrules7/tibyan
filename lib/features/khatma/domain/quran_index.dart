import 'dart:typed_data';

/// One verse as content.db holds it, only what the khatma needs: its
/// numbers, its pages in the three Hafs editions, its juz and hizb quarter,
/// and the letters of its text (see [lettersOf]).
class AyahFacts {
  const AyahFacts({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.page,
    required this.page1405,
    required this.shamarlyStart,
    required this.shamarlyEnd,
    required this.juz,
    required this.quarter,
    required this.letters,
  });

  /// `ayah.id`: 1 … 6236 in mushaf order.
  final int id;
  final int surah;
  final int ayah;

  /// Page in the new Madina edition (1441H): no verse runs over a page.
  final int page;
  final int page1405;

  /// Shamarly: the page the verse starts on and the page it ends on.
  final int shamarlyStart;
  final int shamarlyEnd;
  final int juz;

  /// Hizb quarter, 1 … 240.
  final int quarter;

  /// Letters of the verse's search text (see [lettersOf]).
  final int letters;
}

final _space = RegExp(r'\s');

/// The length used for a verse's weight (decision 3): its `text_search`
/// without the basmala printed before it ([basmalaPrefix] characters,
/// `search_basmala_prefix`) and without spaces.
int lettersOf(String textSearch, int basmalaPrefix) {
  final body = basmalaPrefix > 0 && basmalaPrefix <= textSearch.length
      ? textSearch.substring(basmalaPrefix)
      : textSearch;
  return body.replaceAll(_space, '').length;
}

/// The Quran's verses by their global number (`ayah.id`, 1 … 6236) and
/// everything derived from it: (surah, verse), pages per edition, juz,
/// hizb and quarter, and each verse's weight.
///
/// A verse's weight is its share of its page in the new Madina edition
/// (1441H, where no verse runs over a page): its letters over the letters
/// of all the verses on that page. Each page weighs 1 and the whole Quran
/// 604, so weights are "Madina pages" whatever edition is being read.
///
/// Built from content.db's rows at runtime (no asset, no table).
class QuranIndex {
  factory QuranIndex(List<AyahFacts> rows) {
    final sorted = [...rows]..sort((a, b) => a.id.compareTo(b.id));
    for (var i = 0; i < sorted.length; i++) {
      if (sorted[i].id != i + 1) {
        throw ArgumentError('verse ids must run 1..n without gaps');
      }
    }
    return QuranIndex._(sorted);
  }

  QuranIndex._(List<AyahFacts> rows)
    : _rows = List.unmodifiable(rows),
      _cum = Float64List(rows.length + 1) {
    final pageLetters = <int, int>{};
    for (final r in rows) {
      pageLetters[r.page] = (pageLetters[r.page] ?? 0) + r.letters;
    }
    final pageCounts = <int, int>{};
    for (final r in rows) {
      pageCounts[r.page] = (pageCounts[r.page] ?? 0) + 1;
    }
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final total = pageLetters[r.page]!;
      // A page of verses without letters (never in content.db) shares
      // its weight evenly.
      final w = total == 0 ? 1 / pageCounts[r.page]! : r.letters / total;
      _cum[i + 1] = _cum[i] + w;
    }
    var surah = 0;
    final firsts = <int>[];
    for (final r in rows) {
      if (r.surah != surah) {
        surah = r.surah;
        firsts.add(r.id);
      }
    }
    _surahFirst = List.unmodifiable(firsts);
    surahEnds = _ends((r) => r.surah);
    juzEnds = _ends((r) => r.juz);
    quarterEnds = _ends((r) => r.quarter);
    hizbEnds = _ends((r) => (r.quarter - 1) ~/ 4);
    madina1441 = EditionPageMap(
      edition: 'madina1441',
      pageCount: 604,
      startPage: [for (final r in rows) r.page],
    );
    madina1405 = EditionPageMap(
      edition: 'madina1405',
      pageCount: 604,
      startPage: [for (final r in rows) r.page1405],
    );
    shamarly = EditionPageMap(
      edition: 'shamarly',
      pageCount: 522,
      startPage: [for (final r in rows) r.shamarlyStart],
      endPage: [for (final r in rows) r.shamarlyEnd],
    );
  }

  final List<AyahFacts> _rows;

  /// `_cum[i]`: the weight of verses 1 … i.
  final Float64List _cum;
  late final List<int> _surahFirst;

  /// The last verse of each surah (114), juz (30), hizb (60) and hizb
  /// quarter (240), in order.
  late final List<int> surahEnds;
  late final List<int> juzEnds;
  late final List<int> hizbEnds;
  late final List<int> quarterEnds;

  /// The pages of the three Hafs editions.
  late final EditionPageMap madina1441;
  late final EditionPageMap madina1405;
  late final EditionPageMap shamarly;

  List<int> _ends(int Function(AyahFacts) key) {
    final out = <int>[];
    for (var i = 0; i < _rows.length; i++) {
      if (i + 1 == _rows.length || key(_rows[i + 1]) != key(_rows[i])) {
        out.add(_rows[i].id);
      }
    }
    return List.unmodifiable(out);
  }

  int get ayahCount => _rows.length;
  int get surahCount => _surahFirst.length;

  /// All 604 pages.
  double get totalWeight => _cum[_rows.length];

  AyahFacts facts(int id) => _rows[_check(id) - 1];

  int _check(int id) {
    if (id < 1 || id > _rows.length) {
      throw RangeError.range(id, 1, _rows.length, 'id');
    }
    return id;
  }

  /// The global number of verse [ayah] of [surah].
  int idOf(int surah, int ayah) {
    if (surah < 1 || surah > _surahFirst.length) {
      throw RangeError.range(surah, 1, _surahFirst.length, 'surah');
    }
    final first = _surahFirst[surah - 1];
    final next = surah < _surahFirst.length
        ? _surahFirst[surah]
        : _rows.length + 1;
    if (ayah < 1 || first + ayah - 1 >= next) {
      throw RangeError.range(ayah, 1, next - first, 'ayah');
    }
    return first + ayah - 1;
  }

  ({int surah, int ayah}) keyOf(int id) {
    final r = facts(id);
    return (surah: r.surah, ayah: r.ayah);
  }

  /// First verse of [surah].
  int surahFirst(int surah) => _surahFirst[surah - 1];

  /// Verses in [surah].
  int ayahCountOf(int surah) =>
      (surah < _surahFirst.length ? _surahFirst[surah] : _rows.length + 1) -
      _surahFirst[surah - 1];

  int juzOf(int id) => facts(id).juz;
  int quarterOf(int id) => facts(id).quarter;
  int hizbOf(int id) => (facts(id).quarter - 1) ~/ 4 + 1;

  /// The weight of verse [id].
  double weight(int id) => _cum[_check(id)] - _cum[id - 1];

  /// The weight of verses [from] … [to] (0 when [to] is before [from]).
  double weightOf(int from, int to) {
    if (to < from) return 0;
    return _cum[_check(to)] - _cum[_check(from) - 1];
  }

  /// The first verse at or after [from] where the weight from [from]
  /// reaches [w]: the verse in which the [w]th page from [from] ends. The
  /// last verse when the Quran ends first.
  int ayahAtWeightOffset(int from, double w) {
    _check(from);
    final goal = _cum[from - 1] + w - 1e-9;
    var lo = from, hi = _rows.length;
    if (_cum[hi] < goal) return hi;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_cum[mid] >= goal) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    return lo;
  }

  /// The pages of a Hafs edition by its name (`MushafEdition.name`), or
  /// null for a riwaya edition (its pages come from its pack).
  EditionPageMap? hafsPages(String edition) => switch (edition) {
    'madina1441' => madina1441,
    'madina1405' => madina1405,
    'shamarly' => shamarly,
    _ => null,
  };
}

/// One edition's pages, by the global verse number: the page each verse
/// starts on and the page it ends on (they differ only where a verse runs
/// over a page, in the Shamarly edition and in some riwaya pages).
class EditionPageMap {
  EditionPageMap({
    required this.edition,
    required this.pageCount,
    required List<int> startPage,
    List<int>? endPage,
  }) : _start = Int32List.fromList(startPage),
       _end = Int32List.fromList(endPage ?? startPage) {
    if (_start.length != _end.length) {
      throw ArgumentError('start and end pages differ in length');
    }
    final from = <int, int>{};
    final to = <int, int>{};
    final ends = <int, int>{};
    for (var i = 0; i < _start.length; i++) {
      final id = i + 1;
      for (var p = _start[i]; p <= _end[i]; p++) {
        from[p] ??= id;
        to[p] = id;
      }
      ends[_end[i]] = id;
    }
    _from = from;
    _to = to;
    _pagesWithText = (from.keys.toList()..sort());
    pageEnds = List.unmodifiable(ends.values.toSet().toList()..sort());
  }

  /// `MushafEdition.name`.
  final String edition;

  /// Printed pages, numbered from 1 (covers included).
  final int pageCount;
  final Int32List _start;
  final Int32List _end;
  late final Map<int, int> _from;
  late final Map<int, int> _to;
  late final List<int> _pagesWithText;

  /// The verse that ends each page, in order: where a day's portion may
  /// end "at the end of a page". A page whose last verse runs on to the
  /// next page ends at the verse before it.
  late final List<int> pageEnds;

  int get ayahCount => _start.length;

  /// The first and last pages with text (Shamarly: 2 and 522).
  int get firstPage => _pagesWithText.first;
  int get lastPage => _pagesWithText.last;

  /// Pages with text, in order.
  List<int> get textPages => _pagesWithText;

  /// The page verse [id] starts on.
  int pageOf(int id) => _start[id - 1];

  /// The page verse [id] ends on.
  int lastPageOf(int id) => _end[id - 1];

  /// The verses with any part on [page], or null for a page without text.
  ({int from, int to})? ayahsOn(int page) {
    final f = _from[page];
    return f == null ? null : (from: f, to: _to[page]!);
  }

  /// Every page holding a part of verses [from] … [to].
  Set<int> pagesOf(int from, int to) {
    if (to < from) return const {};
    return {
      for (var p = pageOf(from); p <= lastPageOf(to); p++)
        if (_from.containsKey(p)) p,
    };
  }

  /// The weight of [page] in Madina pages: the verses on it (a verse
  /// running over a page counts on both).
  double weightOfPage(int page, QuranIndex index) {
    final r = ayahsOn(page);
    return r == null ? 0 : index.weightOf(r.from, r.to);
  }
}
