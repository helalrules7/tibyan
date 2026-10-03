import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/contrast.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';
import 'package:tibyan/features/mushaf/data/svg_contours.dart';
import 'package:tibyan/features/mushaf/data/tajweed.dart';

/// A page of the bundled new-edition pack, as SVG text.
String packPage(int page) {
  final zip = ZipDecoder().decodeBytes(
    File('assets/packs/pages-hafs-1441-v1.zip').readAsBytesSync(),
  );
  final entry = zip.findFile('${page.toString().padLeft(3, '0')}.svg.xz')!;
  return utf8.decode(XZDecoder().decodeBytes(entry.content));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('rules and data rows', () {
    test('rule numbers follow tools/build_tajweed.py RULES', () {
      // The order the build numbers the rules in; a change there must be
      // made here too.
      expect([for (final r in TajweedRule.values) r.key], [
        'hamzat_wasl', 'lam_shamsiyyah', 'silent', //
        'madd_2', 'madd_246', 'madd_muttasil', 'madd_munfasil', 'madd_6',
        'ghunnah', 'ikhfa', 'ikhfa_shafawi', 'iqlab',
        'idghaam_ghunnah', 'idghaam_no_ghunnah', 'idghaam_shafawi',
        'idghaam_mutajanisayn', 'idghaam_mutaqaribayn',
        'qalqalah',
      ]);
      expect(TajweedRule.byKey('qalqalah'), TajweedRule.qalqalah);
    });

    test('new-edition rows: whole contours and contours clipped to a letter', () {
      final e = parseTajweedContours('8,120;5,121,10.5,14.25;');
      expect(e, hasLength(2));
      expect(e[0], (rule: TajweedRule.ghunnah, contour: 120, x0: null, x1: null));
      expect(e[1].rule, TajweedRule.maddMuttasil);
      expect((e[1].x0, e[1].x1), (10.5, 14.25));
      expect(parseTajweedContours(''), isEmpty);
    });

    test('page-image rows: rule and box in image pixels', () {
      final e = parseTajweedRects('17,1,2,30,40;0,5,6,7,8');
      expect(e.first, (TajweedRule.qalqalah, const Rect.fromLTRB(1, 2, 30, 40)));
      expect(e.last.$1, TajweedRule.hamzatWasl);
      expect(parseTajweedRects(''), isEmpty);
    });
  });

  group('colours', () {
    test('defaults, a chosen colour, and a rule turned off', () {
      expect(tajweedHueOf(TajweedRule.qalqalah, const {}), TajweedHue.blue);
      expect(tajweedHueOf(TajweedRule.madd2, const {}), TajweedHue.amber);
      expect(tajweedHueOf(TajweedRule.silent, const {}), TajweedHue.violet);
      // A reader's earlier choice stays, grey included.
      expect(
        tajweedHueOf(TajweedRule.silent, const {'silent': 'grey'}),
        TajweedHue.grey,
      );
      expect(tajweedHueOf(TajweedRule.madd2, const {'madd_2': ''}), isNull);
      expect(
        tajweedHueOf(TajweedRule.qalqalah, const {'qalqalah': 'purple'}),
        TajweedHue.purple,
      );
      expect(tajweedHueOf(TajweedRule.ghunnah, const {'ghunnah': ''}), isNull);
      expect(
        tajweedHueOf(TajweedRule.madd2, const {'madd_2': 'gold'}),
        TajweedHue.gold,
      );
    });

    test('every colour is at least 3:1 on every style\'s paper', () async {
      final registry = await ThemeRegistry.load(rootBundle);
      for (final style in registry.styles) {
        for (final MapEntry(key: mode, value: tokens) in style.modes.entries) {
          for (final hue in TajweedHue.values) {
            final c = hue.on(darkPaper: !mode.isLight);
            expect(
              contrastRatio(c, tokens.paper),
              greaterThanOrEqualTo(3),
              reason: '${hue.name} on ${style.id} ${mode.name}',
            );
          }
        }
      }
    });

    test('every rule has a default colour, none of them grey', () {
      // Grey cannot be told from the ink: black ink on light paper, light
      // ink at night. Every default is a clear hue in both shades.
      for (final rule in TajweedRule.values) {
        final hue = defaultTajweedHues[rule];
        expect(hue, isNotNull, reason: rule.key);
        for (final dark in [false, true]) {
          final c = hue!.on(darkPaper: dark);
          final rgb = [c.r, c.g, c.b];
          final chroma =
              rgb.reduce((a, b) => a > b ? a : b) -
              rgb.reduce((a, b) => a < b ? a : b);
          expect(chroma, greaterThan(0.25), reason: '${rule.key} $dark');
        }
      }
    });

    test('the riwaya editions have no tajweed data', () {
      for (final e in MushafEdition.values) {
        expect(editionHasTajweed(e), !e.isRiwaya, reason: e.name);
      }
    });

    test('the default colours also differ in lightness', () {
      final used = {...defaultTajweedHues.values.whereType<TajweedHue>()};
      for (final dark in [false, true]) {
        final shades = [for (final h in used) h.on(darkPaper: dark)];
        for (var i = 0; i < shades.length; i++) {
          for (var j = i + 1; j < shades.length; j++) {
            expect(
              contrastRatio(shades[i], shades[j]),
              greaterThanOrEqualTo(1.05),
              reason: '${used.elementAt(i).name} / ${used.elementAt(j).name}'
                  ' (${dark ? 'dark' : 'light'})',
            );
          }
        }
      }
    });
  });

  group('page contours', () {
    test('relative commands, implicit line segments and smooth curves', () {
      final paths = subpaths('m10 10 5 0 0 5z m-5 0 l2 0 v2 h-2z M0 0 c1 1 2 2 3 3 s1 1 2 2');
      expect(paths, hasLength(3));
      expect(paths[0].$2.getBounds(), const Rect.fromLTRB(10, 10, 15, 15));
      // After z the pen is back at (10, 10): the second subpath starts at (5, 10).
      expect(paths[1].$2.getBounds(), const Rect.fromLTRB(5, 10, 7, 12));
      expect(paths[2].$2.getBounds().right, closeTo(5, 1e-9));
      expect(subpaths('m0 0 1 1 m 1 1 1 1', keep: (n) => n == 1).single.$1, 1);
    });

    test('transforms apply and verse outlines are left out', () {
      const svg =
          '<svg><g transform="matrix(2 0 0 -2 0 100)">'
          '<g id="ayah_markers"><path d="M0 0 L1 1"/></g>'
          '<g id="content"><g transform="translate(10 5)">'
          '<path d="m0 0 l4 0 0 2z m1 1 l1 0 0 1z" fill="#000"/></g>'
          '<path class="ayahPolygon" d="M0 0 L9 9 Z"/></g></g></svg>';
      final c = pageContours(svg);
      expect(c.keys, [0, 1]);
      expect(c[0]!.getBounds(), const Rect.fromLTRB(20, 86, 28, 90));
      expect(pageContours(svg, wanted: {1}).keys, [1]);
    });

    test('page 3 has the contours tools/build_word_boxes.py counts', () {
      final svg = packPage(3);
      final all = pageContours(svg);
      // read_page() on 003.svg: 1354 contours, the first with bounds
      // (211.78, 490.20)-(221.45, 500.68) counting control points.
      expect(all.length, 1354);
      final b = all[0]!.getBounds();
      expect(b.left, closeTo(211.78, 0.6));
      expect(b.bottom, closeTo(500.68, 0.6));
    });
  });

  group('content.db', () {
    late ContentDatabase db;
    late MushafRepository repo;
    setUpAll(() {
      db = ContentDatabase(
        NativeDatabase(
          File('assets/db/content.db'),
          setup: (raw) => raw.execute('PRAGMA query_only = ON'),
        ),
      );
      repo = MushafRepository(db);
    });
    tearDownAll(() => db.close());

    test('every edition has tajweed rows that point at real shapes', () async {
      final svg = packPage(3);
      final contours = pageContours(svg);
      final rows = parseTajweedContours(
        await repo.tajweedPage(MushafEdition.madina1441, 3),
      );
      expect(rows, isNotEmpty);
      for (final r in rows) {
        expect(contours.containsKey(r.contour), isTrue);
        if (r.x0 != null) expect(r.x1!, greaterThan(r.x0!));
      }
      // Al-Baqara 2:6 opens page 3: «إِنَّ» has a ghunnah.
      expect(rows.any((r) => r.rule == TajweedRule.ghunnah), isTrue);
      final paths = tajweedPaths(svg, rows);
      expect(paths.keys, contains(TajweedRule.hamzatWasl));

      for (final edition in [MushafEdition.madina1405, MushafEdition.shamarly]) {
        final rects = parseTajweedRects(await repo.tajweedPage(edition, 5));
        expect(rects, isNotEmpty, reason: edition.name);
        for (final (_, r) in rects) {
          expect(r.width, greaterThan(0));
          expect(r.height, greaterThan(0));
        }
      }
      // Every placed letter comes from the one letter table (Hafs only,
      // source 18: cpfair), and the file is the schema drift expects.
      final letters = await db
          .customSelect(
            'SELECT riwaya, source, COUNT(*) AS n FROM tajweed_letter '
            'GROUP BY riwaya, source',
          )
          .get();
      expect(letters, hasLength(1));
      expect(letters.single.read<String>('riwaya'), 'hafs');
      expect(letters.single.read<int>('source'), 18);
      expect(letters.single.read<int>('n'), greaterThan(70000));
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data.values.single, db.schemaVersion);
      // Opening pages are coloured too.
      expect(await repo.tajweedPage(MushafEdition.madina1441, 1), isNotEmpty);
      expect(await repo.tajweedPage(MushafEdition.madina1405, 1), isNotEmpty);
    });
  });

  group('settings', () {
    Future<ProviderContainer> container(Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues(prefs);
      final registry = await ThemeRegistry.load(rootBundle);
      final sp = await SharedPreferences.getInstance();
      return ProviderContainer(
        overrides: [
          themeRegistryProvider.overrideWithValue(registry),
          sharedPreferencesProvider.overrideWithValue(sp),
        ],
      );
    }

    test('off by default, with the default colours', () async {
      final s = (await container({})).read(settingsProvider);
      expect(s.tajweedColors, isFalse);
      expect(s.tajweedHues, isEmpty);
    });

    test('turning it on and choosing colours is saved and restored', () async {
      final c = await container({});
      final ctrl = c.read(settingsProvider.notifier);
      await ctrl.setTajweedColors(true);
      await ctrl.setTajweedHue('qalqalah', 'purple');
      await ctrl.setTajweedHue('ghunnah', '');
      await ctrl.setTajweedHue('madd_6', 'teal');
      await ctrl.setTajweedHue('madd_6', null);
      final sp = await SharedPreferences.getInstance();
      final again = await container({
        for (final k in sp.getKeys()) k: sp.get(k)!,
      });
      final s = again.read(settingsProvider);
      expect(s.tajweedColors, isTrue);
      expect(s.tajweedHues, {'qalqalah': 'purple', 'ghunnah': ''});
      expect(tajweedHueOf(TajweedRule.ghunnah, s.tajweedHues), isNull);

      await again.read(settingsProvider.notifier).resetTajweedHues();
      expect(again.read(settingsProvider).tajweedHues, isEmpty);
    });
  });
}
