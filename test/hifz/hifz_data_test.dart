import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/ayahinfo_database.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/db/user_database.dart';
import 'package:tibyan/features/hifz/data/hifz_store.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/features/hifz/data/hifz_repository.dart';
import 'package:tibyan/features/hifz/domain/fsrs.dart';
import 'package:tibyan/features/hifz/domain/strength.dart';
import 'package:tibyan/features/hifz/hifz_providers.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';

/// Runs against the real bundled content database.
void main() {
  late ContentDatabase content;
  late HifzRepository repo;

  setUpAll(() {
    content = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
    repo = HifzRepository(content);
  });
  tearDownAll(() => content.close());

  group('units', () {
    test('a page is its verses in the edition being read', () async {
      for (final e in [MushafEdition.madina1441, MushafEdition.madina1405]) {
        final u = (await repo.unit(HifzUnitKind.page, 2, e))!;
        expect((u.fromRef, u.toRef), ('2:1', '2:5'), reason: e.name);
      }
      // Shamarly page 3 opens al-Baqarah; 2:16 runs from page 4 into 5.
      var u = (await repo.unit(HifzUnitKind.page, 3, MushafEdition.shamarly))!;
      expect((u.fromRef, u.toRef), ('2:1', '2:4'));
      u = (await repo.unit(HifzUnitKind.page, 5, MushafEdition.shamarly))!;
      expect(u.fromRef, '2:16');
      expect(
        await repo.unit(HifzUnitKind.page, 605, MushafEdition.madina1441),
        isNull,
      );
    });

    test('quarters and surahs', () async {
      final q = (await repo.unit(
        HifzUnitKind.quarter,
        1,
        MushafEdition.shamarly,
      ))!;
      expect((q.fromRef, q.toRef), ('1:1', '2:25'));
      final s = (await repo.unit(
        HifzUnitKind.surah,
        67,
        MushafEdition.madina1441,
      ))!;
      expect((s.fromRef, s.toRef), ('67:1', '67:30'));
      expect((await repo.versesOf('67:1', '67:30')).length, 30);
      expect((await repo.versesOf('1:7', '2:2')).length, 3);
    });

    test('every verse has its cells for the map', () async {
      final cells = await repo.verseCells();
      expect(cells.length, 6236);
      expect(cells.first, ('1:1', 1, 1, 1, 2, 2));
      expect(cells.last.$1, '114:6');
    });
  });

  group('mutashabihat', () {
    test('content.db carries the links and their source', () async {
      final version = await content
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.data.values.single, content.schemaVersion);
      final n = await content
          .customSelect('SELECT COUNT(*) AS n FROM mutashabih')
          .getSingle();
      expect(n.read<int>('n'), greaterThan(2000));
      final source = (await MushafRepository(
        content,
      ).sources()).singleWhere((s) => s.key == 'waqar144-mutashabihat');
      expect(source.url, contains('Quran_Mutashabihat_Data'));
    });

    test('2:3 resembles 8:3, 27:3 and 31:4, shown as their own text', () async {
      expect(await repo.similarCount(2, 3), 3);
      final groups = await repo.similar(2, 3);
      expect(groups, hasLength(1));
      final g = groups.single;
      expect(g.passage.verses.single.number, 3);
      expect(
        [
          for (final p in g.similar)
            '${p.verses.first.surah}:${p.verses.first.number}',
        ],
        ['8:3', '27:3', '31:4'],
      );
      // The text is the verse row itself, verbatim.
      final row = await MushafRepository(content).ayah(8, 3);
      expect(g.similar.first.verses.single.displayText, row.displayText);
    });

    test('links are found in both directions', () async {
      // 8:3 is listed with 2:3 as a resembling verse of 2:3 and back.
      final back = await repo.similar(8, 3);
      expect(
        back.expand((g) => g.similar).map((p) => p.verses.first.id),
        contains(10),
      );
      expect(await repo.similarCount(1, 1), 0);
    });
  });

  group('reveal pieces', () {
    ProviderContainer container(
      MushafEdition edition, {
      AyahInfoDatabase? ayahInfo,
    }) {
      final c = ProviderContainer(
        overrides: [
          contentDatabaseProvider.overrideWithValue(content),
          editionProvider.overrideWithValue(edition),
          ayahInfoDatabaseProvider.overrideWithValue(ayahInfo),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('new edition: every verse word by word, in word order', () async {
      final c = container(MushafEdition.madina1441);
      final units = await c.read(pageRevealUnitsProvider(2).future);
      expect(units.length, 5);
      expect(units.values.every((u) => u.byWord), isTrue);
      expect(units[(surah: 2, ayah: 2)]!.length, 7);
      expect(units[(surah: 2, ayah: 4)]!.length, 12);
      // Opening page 1 too.
      final fatiha = await c.read(pageRevealUnitsProvider(1).future);
      expect(fatiha.length, 7);
      expect(fatiha.values.every((u) => u.byWord), isTrue);
    });

    test('Shamarly: unsure splits go line by line; a verse crossing a '
        'page reveals the words on this page', () async {
      final c = container(MushafEdition.shamarly);
      final p3 = await c.read(pageRevealUnitsProvider(3).future);
      expect(p3[(surah: 2, ayah: 2)]!.byWord, isTrue);
      // 2:3's split is not reviewed yet (level 1): its lines.
      expect(p3[(surah: 2, ayah: 3)]!.byWord, isFalse);
      expect(p3[(surah: 2, ayah: 3)]!.length, greaterThan(0));
      final p4 = await c.read(pageRevealUnitsProvider(4).future);
      expect(p4[(surah: 2, ayah: 16)]!.byWord, isTrue);
      expect(p4[(surah: 2, ayah: 16)]!.length, 5);
      final p5 = await c.read(pageRevealUnitsProvider(5).future);
      expect(p5[(surah: 2, ayah: 16)]!.length, 6);
    });

    test('old edition: glyph boxes per word, else per line', () async {
      final info = AyahInfoDatabase(NativeDatabase.memory());
      addTearDown(info.close);
      await info.customStatement(
        'CREATE TABLE glyphs (glyph_id INTEGER PRIMARY KEY, page_number INTEGER, '
        'line_number INTEGER, sura_number INTEGER, ayah_number INTEGER, '
        'position INTEGER, min_x INTEGER, max_x INTEGER, min_y INTEGER, '
        'max_y INTEGER)',
      );
      var id = 0;
      Future<void> glyph(int line, int ayah, int pos, int x0, int x1) =>
          info.customStatement(
            'INSERT INTO glyphs VALUES (?,?,?,?,?,?,?,?,?,?)',
            [++id, 2, line, 2, ayah, pos, x0, x1, line * 100, line * 100 + 60],
          );
      // 2:1 is one word and its marker: matched word by word.
      await glyph(1, 1, 1, 500, 600);
      await glyph(1, 1, 2, 460, 490);
      // 2:2 has seven words, but only two glyph positions here: no match,
      // so its two lines are the pieces.
      await glyph(1, 2, 1, 100, 400);
      await glyph(2, 2, 2, 300, 900);
      await glyph(2, 2, 3, 250, 280);
      final c = container(MushafEdition.madina1405, ayahInfo: info);
      final units = await c.read(pageRevealUnitsProvider(2).future);
      expect(units[(surah: 2, ayah: 1)]!.byWord, isTrue);
      expect(units[(surah: 2, ayah: 1)]!.length, 1);
      final lines = units[(surah: 2, ayah: 2)]!;
      expect(lines.byWord, isFalse);
      expect(lines.length, 2);
      expect(lines.pieces[0].single.top, 100);
      expect(lines.pieces[1].single.left, 250);
      expect(lines.pieces[1].single.right, 900);
    });
  });

  group('grading', () {
    late UserDatabase user;
    setUp(() => user = UserDatabase(NativeDatabase.memory()));
    tearDown(() => user.close());

    test('a first grade creates the unit and sets its verses', () async {
      final now = DateTime(2026, 10, 2, 9);
      final review = await gradeUnit(
        db: user,
        repo: repo,
        kind: HifzUnitKind.page,
        fromRef: '2:1',
        toRef: '2:5',
        grade: Grade.good,
        results: {(surah: 2, ayah: 4): VerseResult.missed},
        now: now,
      );
      expect(review.due, DateTime(2026, 10, 6));
      final item = (await user.srsItem('page', '2:1', '2:5'))!;
      expect(item.reps, 1);
      expect(item.lapses, 0);
      expect(item.uuid, hasLength(36));
      final s = await user.verseStrengths(['2:1', '2:4', '2:5', '2:6']);
      expect(s, {'2:1': 2, '2:4': 1, '2:5': 2});
      expect(dueToday([item], DateTime(2026, 10, 5, 23)), isEmpty);
      expect(dueToday([item], DateTime(2026, 10, 6, 0, 1)), [item]);

      // Forgotten at the next review: a lapse, and due again tomorrow.
      final again = await gradeUnit(
        db: user,
        repo: repo,
        kind: HifzUnitKind.page,
        fromRef: '2:1',
        toRef: '2:5',
        grade: Grade.again,
        results: const {},
        now: DateTime(2026, 10, 6, 9),
      );
      expect(again.due, DateTime(2026, 10, 7));
      final after = (await user.srsItem('page', '2:1', '2:5'))!;
      expect((after.reps, after.lapses), (2, 1));
      expect(await user.verseStrengths(['2:1']), {'2:1': 1});
    });

    test('verse results update the map strengths', () async {
      await user.setVerseStrengths({'1:1': 4, '1:2': 1});
      await saveVerseResults(user, {
        (surah: 1, ayah: 1): VerseResult.missed,
        (surah: 1, ayah: 2): VerseResult.remembered,
        (surah: 1, ayah: 3): VerseResult.remembered,
      });
      expect(await user.watchVerseStrengths().first, {
        '1:1': 1,
        '1:2': 2,
        '1:3': 2,
      });
    });
  });
}
