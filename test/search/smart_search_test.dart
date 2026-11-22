import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/search/search_engine.dart';
import 'package:tibyan/features/word_study/data/word_study_repository.dart';

/// Every verse text here is read from content.db, never typed.
void main() {
  late ContentDatabase db;
  late List<SearchVerse> verses;
  late Map<int, List<String>> names;

  setUpAll(() async {
    db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
    final rows = await db
        .customSelect(
          'SELECT surah, number, text_search, search_basmala_prefix FROM ayah',
        )
        .get();
    verses = [
      for (final r in rows)
        SearchVerse(
          r.read<int>('surah'),
          r.read<int>('number'),
          r
              .read<String>('text_search')
              .substring(r.read<int>('search_basmala_prefix')),
        ),
    ];
    names = {
      for (final s in await db.select(db.surah).get())
        s.id: [s.nameAr, s.nameEn],
    };
  });
  tearDownAll(() => db.close());

  Future<String> displayText(int surah, int ayah) async =>
      (await db
              .customSelect(
                'SELECT display_text FROM ayah WHERE surah = ? AND number = ?',
                variables: [Variable.withInt(surah), Variable.withInt(ayah)],
              )
              .getSingle())
          .read<String>('display_text');

  group('verse numbers', () {
    test('2:255, name then number, number then name', () {
      final baqara = names[2]!.first;
      expect(parseReference('2:255', names), (surah: 2, ayah: 255));
      expect(parseReference('$baqara 255', names), (surah: 2, ayah: 255));
      expect(parseReference('255 $baqara', names), (surah: 2, ayah: 255));
      expect(parseReference('٢٥٥ $baqara', names), (surah: 2, ayah: 255));
      expect(parseReference('سورة $baqara', names), (surah: 2, ayah: null));
      expect(parseReference('255', names), isNull);
    });
  });

  group('diacritics and letter variants', () {
    test('the mushaf text with its marks finds the plain verse', () async {
      // Two words of Ayat al-Kursi, as printed (diacritics, wasla, marks).
      final words = (await displayText(2, 255)).split(' ');
      final typed = words.sublist(3, 5).join(' ');
      final hits = search(verses, typed).map((h) => (h.surah, h.ayah));
      expect(hits, contains((2, 255)));
    });

    test('hamza, alif, ya, ta marbuta and tatweel fold together', () {
      String fold(String s) => normalize(s);
      expect(fold('أ'), fold('ا'));
      expect(fold('إ'), fold('ا'));
      expect(fold('آ'), fold('ا'));
      expect(fold('ٱ'), fold('ا'));
      expect(fold('ى'), fold('ي'));
      expect(fold('ة'), fold('ه'));
      expect(fold('بـــب'), fold('بب'));
    });

    test('a verse word typed with other variants still matches', () {
      // A real word, its letters swapped for their variants and stretched.
      final kursi = verses.firstWhere((v) => v.surah == 2 && v.ayah == 255);
      final word = kursi.words.firstWhere(
        (w) => w.contains('ا') && w.length > 3,
      );
      final variant = word.replaceFirst('ا', 'أ').split('').join('ـ');
      final hits = search(verses, variant).map((h) => (h.surah, h.ayah));
      expect(hits, contains((2, 255)));
    });
  });

  group('root', () {
    test('a root typed with or without spaces', () async {
      final repo = WordStudyRepository(db);
      final roots = await repo.roots();
      expect(roots.length, greaterThan(1000));
      // The root of the third word of al-Fatiha 1, as the corpus gives it.
      final stored = (await repo.wordRoot(1, 1, 3))!.root!;
      expect(matchRoot(stored, roots), stored);
      expect(matchRoot(stored.replaceAll(' ', ''), roots), stored);
      expect(matchRoot('', roots), isNull);
      expect(matchRoot('2:255', roots), isNull);

      final found = await repo.rootOccurrences(stored);
      expect(
        found.verses.map((o) => (o.ayah.surah, o.ayah.number)),
        contains((1, 1)),
      );
      final fatiha = found.verses.firstWhere(
        (o) => o.ayah.surah == 1 && o.ayah.number == 1,
      );
      expect(fatiha.words, contains(3));
      expect(
        found.wordCount,
        found.verses.fold<int>(0, (n, o) => n + o.words.length),
      );
    });

    test('a hamza root matches typed with a bare alif', () async {
      final repo = WordStudyRepository(db);
      final roots = await repo.roots();
      final hamza = roots.firstWhere((r) => r.contains('أ'));
      expect(matchRoot(hamza.replaceAll('أ', 'ا'), roots), hamza);
    });
  });
}
