import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/search/search_engine.dart';

void main() {
  scopeTests();
  test('diacritics and common spelling differences are ignored', () {
    expect(normalize('ٱلرَّحۡمَٰنِ'), normalize('الرحمن'));
    expect(normalize('إِلَىٰ'), 'الي');
    expect(normalize('رحمة'), normalize('رحمه'));
    expect(normalize('أُولَـٰئِكَ'), normalize('اولئك'));
  });

  test('references by numbers or by name', () {
    final names = {
      1: ['الفاتحة', 'Al-Faatiha'],
      2: ['البقرة', 'Al-Baqara'],
      36: ['يس', 'Yaseen'],
    };
    expect(parseReference('2:255', names), (surah: 2, ayah: 255));
    expect(parseReference('٢:٢٥٥', names), (surah: 2, ayah: 255));
    expect(parseReference('2 255', names), (surah: 2, ayah: 255));
    expect(parseReference('البقرة 255', names), (surah: 2, ayah: 255));
    expect(parseReference('سورة البقرة', names), (surah: 2, ayah: null));
    expect(parseReference('بقره ٢٥٥', names), (surah: 2, ayah: 255));
    expect(parseReference('al-baqara 3', names), (surah: 2, ayah: 3));
    expect(parseReference('يس', names), (surah: 36, ayah: null));
    expect(parseReference('الرحمن الرحيم', names), isNull);
    expect(parseReference('200:1', names), isNull);
  });

  test('search over the whole Quran text', () async {
    final db = ContentDatabase(
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
    await db.close();
    final verses = [
      for (final r in rows)
        SearchVerse(
          r.read<int>('surah'),
          r.read<int>('number'),
          r
              .read<String>('text_search')
              .substring(r.read<int>('search_basmala_prefix')),
        ),
    ];
    expect(verses.length, 6236);

    // Ayat al-Kursi, typed with or without diacritics.
    final kursi = search(verses, 'الحي القيوم لا تأخذه سنة');
    expect(kursi.map((h) => (h.surah, h.ayah)), [(2, 255)]);
    expect(search(verses, 'ٱلۡحَيُّ ٱلۡقَيُّومُۚ لَا تَأۡخُذُهُۥ'), isNotEmpty);

    // Every hit really contains the query.
    final hits = search(verses, 'الرحمن الرحيم');
    expect(hits, isNotEmpty);
    for (final h in hits) {
      final v = verses.firstWhere(
        (v) => v.surah == h.surah && v.ayah == h.ayah,
      );
      expect(v.folded, contains(normalize('الرحمن الرحيم')));
      expect(h.words, isNotEmpty);
      expect(h.words.every((i) => i < v.words.length), isTrue);
    }
    // Too short to search.
    expect(search(verses, 'ا'), isEmpty);
  });
}

void scopeTests() {
  final verses = [
    SearchVerse(2, 255, 'الله لا اله الا هو', juz: 3),
    SearchVerse(3, 2, 'الله لا اله الا هو', juz: 3),
    SearchVerse(20, 8, 'الله لا اله الا هو', juz: 16),
  ];
  test('a scope keeps the search to a surah or a juz', () {
    expect(searchIn(verses, 'اله', const WholeMushaf()), hasLength(3));
    expect(searchIn(verses, 'اله', const InSurah(3)).map((h) => h.surah), [3]);
    expect(searchIn(verses, 'اله', const InJuz(3)).map((h) => h.surah), [2, 3]);
    expect(searchIn(verses, 'اله', const InJuz(30)), isEmpty);
  });
}
