import 'package:drift/drift.dart' show Variable;

import '../../../core/db/content_database.dart';
import '../domain/expected_words.dart';
import '../domain/recitation_range.dart';

/// Reads the words of a recitation range from content.db: the verse index
/// (`ayah`), the KFGQPC text (`ayah.display_text`) and the page of every
/// word (`word_box`, the new edition, 1441H). Read only.
class TasmeeWordsRepository {
  TasmeeWordsRepository(this._db);

  final ContentDatabase _db;
  List<VerseIndexEntry>? _index;

  /// Every verse, in mushaf order (read once).
  Future<List<VerseIndexEntry>> verseIndex() async => _index ??= [
    for (final r
        in await _db
            .customSelect(
              'SELECT id, surah, number, juz, hizb_quarter, page '
              'FROM ayah ORDER BY id',
            )
            .get())
      VerseIndexEntry(
        id: r.read<int>('id'),
        surah: r.read<int>('surah'),
        ayah: r.read<int>('number'),
        juz: r.read<int>('juz'),
        hizbQuarter: r.read<int>('hizb_quarter'),
        page: r.read<int>('page'),
      ),
  ];

  /// The words the reader is expected to say for [range], in order.
  Future<List<ExpectedWord>> expectedWords(RecitationRange range) async {
    final verses = range.versesIn(await verseIndex());
    if (verses.isEmpty) return const [];
    final first = verses.first.id, last = verses.last.id;
    final text = {
      for (final r
          in await _db
              .customSelect(
                'SELECT id, display_text FROM ayah WHERE id BETWEEN ? AND ?',
                variables: [Variable.withInt(first), Variable.withInt(last)],
              )
              .get())
        r.read<int>('id'): r.read<String>('display_text'),
    };
    final pages = <int, List<int>>{};
    for (final r
        in await _db
            .customSelect(
              'SELECT a.id, w.page FROM word_box w '
              'JOIN ayah a ON a.surah = w.surah AND a.number = w.ayah '
              'WHERE a.id BETWEEN ? AND ? ORDER BY a.id, w.word',
              variables: [Variable.withInt(first), Variable.withInt(last)],
            )
            .get()) {
      (pages[r.read<int>('id')] ??= []).add(r.read<int>('page'));
    }
    return buildExpectedWords(range, [
      for (final v in verses)
        VerseSource(v, text[v.id]!, pages[v.id] ?? const []),
    ]);
  }
}
