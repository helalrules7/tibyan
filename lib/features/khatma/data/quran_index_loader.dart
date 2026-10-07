import '../../../core/db/content_database.dart';
import '../../mushaf/data/riwaya_data.dart';
import '../domain/interval_set.dart';
import '../domain/quran_index.dart';

/// Reads the verses' facts from content.db (6236 small rows) and builds
/// the index. Run once and kept in memory (`quranIndexProvider`).
Future<QuranIndex> loadQuranIndex(ContentDatabase db) async {
  final rows = await db
      .customSelect(
        'SELECT id, surah, number, page, page_1405, page_shamarly, '
        'page_shamarly_end, juz, hizb_quarter, text_search, '
        'search_basmala_prefix FROM ayah ORDER BY id',
      )
      .get();
  return QuranIndex([
    for (final r in rows)
      AyahFacts(
        id: r.read<int>('id'),
        surah: r.read<int>('surah'),
        ayah: r.read<int>('number'),
        page: r.read<int>('page'),
        page1405: r.read<int>('page_1405'),
        shamarlyStart: r.read<int>('page_shamarly'),
        shamarlyEnd: r.read<int>('page_shamarly_end'),
        juz: r.read<int>('juz'),
        quarter: r.read<int>('hizb_quarter'),
        letters: lettersOf(
          r.read<String>('text_search'),
          r.read<int>('search_basmala_prefix'),
        ),
      ),
  ]);
}

/// A riwaya edition's pages in Hafs verse numbers, from its pack: a Hafs
/// verse is on every page holding a part of a riwaya verse that covers it.
/// A Hafs verse the riwaya does not count (the basmala of al-Fatiha) goes
/// with the riwaya verse that follows it, as [RiwayaData.fromHafs] does.
EditionPageMap riwayaPages(String edition, RiwayaData data, QuranIndex index) {
  // The pages of each riwaya verse: where it starts, and every page whose
  // outlines hold a part of it.
  final pagesOf = <RiwayaKey, (int, int)>{};
  void see(RiwayaKey k, int page) {
    final had = pagesOf[k];
    pagesOf[k] = had == null
        ? (page, page)
        : (had.$1 < page ? had.$1 : page, had.$2 > page ? had.$2 : page);
  }

  for (final v in data.verses) {
    see(v.key, v.page);
  }
  for (final e in data.polygonsByPage.entries) {
    for (final p in e.value) {
      final k = (surah: p.surah, ayah: p.number);
      if (pagesOf.containsKey(k)) see(k, e.key);
    }
  }

  final start = List<int>.filled(index.ayahCount, 0);
  final end = List<int>.filled(index.ayahCount, 0);
  for (final v in data.verses) {
    final span = pagesOf[v.key]!;
    for (final h in v.hafs) {
      final id = _idOrNull(index, h.surah, h.ayah);
      if (id == null) continue;
      final i = id - 1;
      start[i] = start[i] == 0 || span.$1 < start[i] ? span.$1 : start[i];
      end[i] = span.$2 > end[i] ? span.$2 : end[i];
    }
  }
  // Hafs verses no riwaya verse covers: with the riwaya verse holding
  // their start (the one after them).
  for (var i = 0; i < start.length; i++) {
    if (start[i] != 0) continue;
    final key = index.keyOf(i + 1);
    final span = pagesOf[data.fromHafs(key.surah, key.ayah)];
    if (span != null) {
      start[i] = span.$1;
      end[i] = span.$2;
    }
  }
  // A verse the pack does not hold (a partial pack, in tests) keeps the
  // page of the verse before it, so pages never run backwards.
  var last = 1;
  for (var i = 0; i < start.length; i++) {
    if (start[i] == 0) {
      start[i] = end[i] = last;
    } else {
      if (start[i] < last) start[i] = last;
      if (end[i] < start[i]) end[i] = start[i];
      last = start[i];
    }
  }
  return EditionPageMap(
    edition: edition,
    pageCount: data.pageCount,
    startPage: start,
    endPage: end,
  );
}

int? _idOrNull(QuranIndex index, int surah, int ayah) {
  try {
    return index.idOf(surah, ayah);
  } on RangeError {
    return null;
  }
}

/// The Hafs verses (`ayah.id`) a riwaya verse covers, with any Hafs verse
/// the riwaya does not count that goes with it (the basmala of
/// al-Fatiha goes with Warsh 1:1).
IntervalSet riwayaVerseInHafs(
  RiwayaData data,
  QuranIndex index,
  int surah,
  int ayah,
) {
  final v = data.verse(surah, ayah);
  if (v == null) return IntervalSet.empty;
  final ids = <int>{for (final h in v.hafs) ?_idOrNull(index, h.surah, h.ayah)};
  if (surah >= 1 && surah <= index.surahCount) {
    // The Hafs verses of the surah some riwaya verse covers.
    final covered = <int>{
      for (var n = 1; n <= data.surahCounts[surah - 1]; n++)
        for (final h in data.verse(surah, n)?.hafs ?? const <RiwayaKey>[])
          h.ayah,
    };
    for (var a = 1; a <= index.ayahCountOf(surah); a++) {
      // Not counted by the riwaya: it goes with the riwaya verse holding
      // the Hafs verse just after it.
      final mine = {for (final h in v.hafs) h.ayah};
      final next = [for (var b = a + 1; b <= a + 3; b++) b]
          .where(covered.contains)
          .firstOrNull;
      if (!covered.contains(a) && next != null && mine.contains(next)) {
        ids.add(index.idOf(surah, a));
      }
    }
  }
  return IntervalSet.of(ids);
}
