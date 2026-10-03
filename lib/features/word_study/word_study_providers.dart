import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/content_database.dart';
import '../mushaf/mushaf_providers.dart';
import 'data/word_study_repository.dart';

final wordStudyRepositoryProvider = Provider<WordStudyRepository>(
  (ref) => WordStudyRepository(ref.watch(contentDatabaseProvider)),
);

typedef VerseRef = ({int surah, int ayah});
typedef WordRef = ({int surah, int ayah, int word});

final verseRowProvider = FutureProvider.family<AyahRow, VerseRef>(
  (ref, v) => ref.watch(mushafRepositoryProvider).ayah(v.surah, v.ayah),
);

final verseGharibProvider = FutureProvider.family<List<GharibRow>, VerseRef>(
  (ref, v) =>
      ref.watch(wordStudyRepositoryProvider).gharibOfVerse(v.surah, v.ayah),
);

final wordRootProvider = FutureProvider.family<WordRootRow?, WordRef>(
  (ref, w) =>
      ref.watch(wordStudyRepositoryProvider).wordRoot(w.surah, w.ayah, w.word),
);

final rootOccurrencesProvider = FutureProvider.family<RootOccurrences, String>(
  (ref, root) => ref.watch(wordStudyRepositoryProvider).rootOccurrences(root),
);
