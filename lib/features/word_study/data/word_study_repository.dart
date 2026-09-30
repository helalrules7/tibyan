import 'package:drift/drift.dart';

import '../../../core/db/content_database.dart';

/// A verse where a root occurs, and which of its words carry it.
class RootOccurrence {
  const RootOccurrence({required this.ayah, required this.words});

  final AyahRow ayah;

  /// Word numbers (as in `word_box`), in order.
  final List<int> words;
}

/// Every place a root occurs: the verses in mushaf order, and the number
/// of words.
class RootOccurrences {
  const RootOccurrences({required this.verses, required this.wordCount});

  final List<RootOccurrence> verses;
  final int wordCount;
}

/// Read-only access to the word study tables: each word's root and lemma
/// (Quranic Arabic Corpus) and the entries of «الميسر في غريب القرآن».
class WordStudyRepository {
  WordStudyRepository(this._db);

  final ContentDatabase _db;

  /// Root, lemma and part of speech of one word; null when the corpus has
  /// none for it (or its verse is not mapped).
  Future<WordRootRow?> wordRoot(int surah, int ayah, int word) =>
      (_db.select(_db.wordRoot)..where(
            (t) =>
                t.surah.equals(surah) &
                t.ayah.equals(ayah) &
                t.word.equals(word),
          ))
          .getSingleOrNull();

  /// The book's entries for one verse, in its order.
  Future<List<GharibRow>> gharibOfVerse(int surah, int ayah) =>
      (_db.select(_db.gharib)
            ..where((t) => t.surah.equals(surah) & t.ayah.equals(ayah))
            ..orderBy([(t) => OrderingTerm.asc(t.ord)]))
          .get();

  /// Every verse where [root] occurs, in mushaf order.
  Future<RootOccurrences> rootOccurrences(String root) async {
    final rows = await _db
        .customSelect(
          'SELECT a.id AS id, w.word AS word FROM word_root w '
          'JOIN ayah a ON a.surah = w.surah AND a.number = w.ayah '
          'WHERE w.root = ? ORDER BY a.id, w.word',
          variables: [Variable.withString(root)],
          readsFrom: {_db.wordRoot, _db.ayah},
        )
        .get();
    final words = <int, List<int>>{};
    for (final r in rows) {
      (words[r.read<int>('id')] ??= []).add(r.read<int>('word'));
    }
    final ayahs =
        await (_db.select(_db.ayah)
              ..where((t) => t.id.isIn(words.keys))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return RootOccurrences(
      verses: [
        for (final a in ayahs) RootOccurrence(ayah: a, words: words[a.id]!),
      ],
      wordCount: rows.length,
    );
  }
}

/// The entries that explain word [word]: those tied to a span of words
/// that includes it. Entries kept on the verse only are not among them.
List<GharibRow> meaningsOfWord(List<GharibRow> verse, int word) => [
  for (final g in verse)
    if (g.wordFrom != null && g.wordFrom! <= word && word <= g.wordTo!) g,
];

/// Words of a verse as numbered in the word boxes: the words of the
/// KFGQPC text, without the verse number and the hizb sign.
List<String> verseWords(AyahRow a) {
  final text = a.displayText;
  final body = text.substring(0, text.lastIndexOf(RegExp('[  ]')));
  return [
    for (final w in body.split(RegExp('[  ]')))
      if (w.isNotEmpty && w != '۞') w,
  ];
}
