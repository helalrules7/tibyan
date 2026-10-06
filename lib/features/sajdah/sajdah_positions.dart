import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/app_settings.dart';
import '../mushaf/data/riwaya_data.dart';
import '../mushaf/mushaf_providers.dart';

/// A verse by surah and number, in the count of the edition being read.
typedef SajdahKey = ({int surah, int ayah});

/// The sajdah sign ۩ (U+06E9) that the KFGQPC texts print at a verse of
/// prostration.
const sajdahSign = '۩';

/// The verses of prostration of the edition being read, numbered as its
/// pages and its recitations number them.
///
/// Hafs: the `ayah.sajda` column of content.db (Tanzil's metadata, 15
/// verses). A riwaya: the verses whose KFGQPC text, as shipped in its
/// pack, carries the sajdah sign ۩. Hafs positions are never carried over
/// to a riwaya: a riwaya without marks has none.
class SajdahPositions {
  SajdahPositions(Iterable<SajdahKey> verses, this._surahCounts)
    : verses = Set.unmodifiable(verses);

  /// The verses of a riwaya edition whose text carries [sajdahSign].
  factory SajdahPositions.ofRiwaya(
    Iterable<RiwayaVerse> verses,
    List<int> surahCounts,
  ) => SajdahPositions([
    for (final v in verses)
      if (v.text.contains(sajdahSign)) v.key,
  ], surahCounts);

  static final none = SajdahPositions(const [], const []);

  final Set<SajdahKey> verses;

  /// Verses in each surah (index 0 = al-Fatiha), to find the verse before
  /// a surah's first.
  final List<int> _surahCounts;

  bool isSajdah(int surah, int ayah) =>
      verses.contains((surah: surah, ayah: ayah));

  /// The verse of prostration just before [surah]:[ayah], or null. The
  /// verse before a surah's first is the last of the surah before it.
  SajdahKey? before(int surah, int ayah) {
    final SajdahKey prev;
    if (ayah > 1) {
      prev = (surah: surah, ayah: ayah - 1);
    } else if (surah > 1 && surah - 2 < _surahCounts.length) {
      prev = (surah: surah - 1, ayah: _surahCounts[surah - 2]);
    } else {
      return null;
    }
    return verses.contains(prev) ? prev : null;
  }
}

/// The verses of prostration of the edition being read; none for a riwaya
/// whose pack is not installed yet.
final sajdahPositionsProvider = FutureProvider<SajdahPositions>((ref) async {
  final edition = ref.watch(editionProvider);
  if (edition.isRiwaya) {
    final data = await ref.watch(riwayaDataProvider.future);
    if (data == null) return SajdahPositions.none;
    return SajdahPositions.ofRiwaya(data.verses, data.surahCounts);
  }
  return ref.watch(hafsSajdahPositionsProvider.future);
});

/// The Hafs verses of prostration (the `ayah.sajda` column), for the
/// screens that show the Hafs text whatever the edition («آية آية»).
final hafsSajdahPositionsProvider = FutureProvider<SajdahPositions>((
  ref,
) async {
  final rows = await ref.watch(mushafRepositoryProvider).sajdaVerses();
  final surahs = await ref.watch(surahsProvider.future);
  return SajdahPositions(
    [for (final r in rows) (surah: r.surah, ayah: r.number)],
    [for (final s in surahs) s.ayahCount],
  );
});
