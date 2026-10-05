import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/books/data/book_pack.dart';

import 'fake_pack.dart';

void main() {
  late BookPack pack;
  setUp(() => pack = BookPack(fakeBooksPackDb()));
  tearDown(() => pack.close());

  List<int> ids(
    int s,
    int a, {
    String? kind,
    String? source,
    Set<String>? entryKinds,
    int? word,
  }) => [
    for (final e in pack.entriesFor(
      s,
      a,
      kind: kind,
      source: source,
      entryKinds: entryKinds,
      word: word,
    ))
      e.id,
  ];

  test('a passage on a range carries that range, on each of its verses', () {
    for (final a in [1, 3, 5]) {
      final e = pack
          .entriesFor(2, a, source: 'test_tafsir_a', entryKinds: {'passage'})
          .single;
      expect(e.id, 10);
      expect((e.link!.ayahFrom, e.link!.ayahTo), (1, 5));
      expect(e.link!.isRange, isTrue);
      expect(e.text, fakeTafsirText);
    }
    final single = pack
        .entriesFor(2, 6, source: 'test_tafsir_a', entryKinds: {'passage'})
        .single;
    expect(single.link!.isRange, isFalse);
  });

  test('one book, or every book of a kind', () {
    expect(ids(2, 1, kind: BookKind.tafsir), [9, 10, 20]);
    expect(ids(2, 1, source: 'test_tafsir_b'), [20]);
    expect(ids(2, 2, kind: BookKind.munasabat), [30]);
    expect(ids(2, 2, kind: BookKind.tafsir), [9, 10]);
    expect([
      for (final s in pack.sourcesOf(BookKind.tafsir)) s.key,
    ], unorderedEquals(['test_tafsir_a', 'test_tafsir_b']));
  });

  test('senses by word: a link with words covers those words only', () {
    const wajh = {EntryKind.wajh};
    // Sense 41 names word 3; sense 42 names no word (the whole verse).
    expect(ids(1, 1, entryKinds: wajh, word: 3), [41, 42]);
    expect(ids(1, 1, entryKinds: wajh, word: 2), [42]);
    // The word header is linked too, but only senses are asked for.
    expect(ids(1, 1, entryKinds: wajh), [41, 42]);
    expect(ids(1, 1), [40, 41, 42]);
  });

  test('a sense comes under its reviewed word header, never a guess', () {
    final senses = pack.entriesFor(1, 1, entryKinds: {EntryKind.wajh});
    for (final s in senses) {
      final parent = pack.parentOf(s, kind: EntryKind.word);
      expect(parent?.id, 40);
      expect(parent?.text, fakeWordText);
    }
    // Its header's reviewer is its editor: no header, not an earlier one.
    final orphan = pack.entriesFor(1, 2).single;
    expect(orphan.id, 44);
    expect(pack.parentOf(orphan, kind: EntryKind.word), isNull);
  });

  test('a link with words covers them across a range', () {
    const l = BookLink(
      surah: 2,
      ayahFrom: 3,
      ayahTo: 4,
      wordFrom: 5,
      wordTo: 2,
    );
    expect(l.coversWord(3, 4), isFalse);
    expect(l.coversWord(3, 5), isTrue);
    expect(l.coversWord(3, 40), isTrue);
    expect(l.coversWord(4, 1), isTrue);
    expect(l.coversWord(4, 3), isFalse);
  });
}
