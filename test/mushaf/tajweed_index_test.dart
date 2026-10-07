import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';
import 'package:tibyan/features/mushaf/data/tajweed.dart';
import 'package:tibyan/features/mushaf/data/tajweed_index.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/mushaf/presentation/tajweed_index_screen.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/tajweed_legend.dart';
import 'package:tibyan/features/share_image/share_text_runs.dart';
import 'package:tibyan/l10n/app_localizations.dart';

/// The tajweed index of «About this mushaf», against the real bundled
/// database: every letter of every rule is shown, on its own word, in the
/// stored text, without a character added or changed.
void main() {
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

  test('the counts cover the 18 rules and every tajweed letter', () async {
    final counts = await repo.tajweedRuleCounts();
    expect(counts.keys.toSet(), {for (final r in TajweedRule.values) r.key});
    final total = await db
        .customSelect(
          "SELECT COUNT(*) AS n FROM tajweed_letter WHERE riwaya = 'hafs'",
        )
        .getSingle();
    expect(
      counts.values.fold<int>(0, (sum, c) => sum + c.letters),
      total.read<int>('n'),
    );
  });

  test('each rule lists its verses in mushaf order, every letter shown on '
      'its own word of the stored text', () async {
    final counts = await repo.tajweedRuleCounts();
    for (final rule in TajweedRule.values) {
      final places = await repo.tajweedPlaces(rule.key);
      expect(places.length, counts[rule.key]!.verses, reason: rule.key);
      expect(
        places.fold<int>(0, (sum, p) => sum + p.letters.length),
        counts[rule.key]!.letters,
        reason: rule.key,
      );
      var last = (0, 0);
      for (final p in places) {
        final at = (p.surah, p.ayah);
        expect(
          at.$1 > last.$1 || (at.$1 == last.$1 && at.$2 > last.$2),
          isTrue,
          reason: '${rule.key} $at after $last',
        );
        last = at;
        final verse = await repo.ayah(p.surah, p.ayah);
        expect(p.text, verse.displayText);
        expect(p.page1441, verse.page);
        expect(p.page1405, verse.page1405);
        expect(p.pageShamarly, verse.pageShamarly);

        final tokens = tajweedTokens(p);
        // Only whole space-separated pieces of the stored text, in order.
        final pieces = p.text.split(' ');
        var from = 0;
        for (final t in tokens) {
          final i = pieces.indexOf(t.text, from);
          expect(i, greaterThanOrEqualTo(0), reason: '${rule.key} $at');
          from = i + 1;
        }
        // Every letter lands on a letter of a shown word.
        for (final l in p.letters) {
          final t = tokens.lastWhere(
            (t) => t.firstWord <= l.word,
            orElse: () => fail('${rule.key} $at: word ${l.word} not shown'),
          );
          final words = [
            for (final w in t.text.split(nbsp))
              if (w.isNotEmpty && w != '۞') w,
          ];
          final word = words[l.word - t.firstWord];
          expect(
            l.letter,
            lessThan(letterSpans(word).length),
            reason: '${rule.key} $at word ${l.word}',
          );
        }
        // Colouring changes no character, and colours something.
        for (final t in tokens) {
          final runs = tokenRuns(
            t.text,
            firstWord: t.firstWord,
            endsVerse: t.endsVerse,
            letters: [
              for (final l in p.letters)
                ShareTajweedLetter(
                  word: l.word,
                  letter: l.letter,
                  marksOnly: l.marksOnly,
                  color: const Color(0xFFFF0000),
                ),
            ],
          );
          expect(runs.map((r) => r.$1).join(), t.text);
        }
        expect(
          tokens.any(
            (t) => tokenRuns(
              t.text,
              firstWord: t.firstWord,
              endsVerse: t.endsVerse,
              letters: [
                for (final l in p.letters)
                  ShareTajweedLetter(
                    word: l.word,
                    letter: l.letter,
                    marksOnly: l.marksOnly,
                    color: const Color(0xFFFF0000),
                  ),
              ],
            ).any((r) => r.$2 != null),
          ),
          isTrue,
          reason: '${rule.key} $at',
        );
      }
    }
  });

  test('a verse is on its page in each Hafs edition', () {
    const p = TajweedPlace(
      surah: 1,
      ayah: 1,
      text: '',
      letters: [],
      page1441: 1,
      page1405: 2,
      pageShamarly: 3,
    );
    expect(p.pageIn(MushafEdition.madina1441), 1);
    expect(p.pageIn(MushafEdition.madina1405), 2);
    expect(p.pageIn(MushafEdition.shamarly), 3);
    expect(TajweedPlace.parseLetters('3:0:body 4:2:marks'), [
      (word: 3, letter: 0, marksOnly: false),
      (word: 4, letter: 2, marksOnly: true),
    ]);
  });

  Future<void> pumpIndex(
    WidgetTester tester, {
    MushafEdition edition = MushafEdition.madina1441,
    Locale locale = const Locale('ar'),
  }) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    rootBundle.clear();
    final registry = (await tester.runAsync(
      () => ThemeRegistry.load(rootBundle),
    ))!;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              Scaffold(body: ListView(children: const [TajweedIndexCard()])),
        ),
        GoRoute(
          path: '/mushaf/about/tajweed',
          builder: (context, state) => TajweedRuleScreen(
            rule: TajweedRule.byKey(state.uri.queryParameters['rule']!)!,
          ),
        ),
      ],
    );
    await tester.binding.setSurfaceSize(const Size(420, 2400));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeRegistryProvider.overrideWithValue(registry),
          sharedPreferencesProvider.overrideWithValue(sp),
          contentDatabaseProvider.overrideWithValue(db),
          editionProvider.overrideWithValue(edition),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTheme(
            style: registry.byId('zakhrafa'),
            mode: ThemeModeId.light,
            uiFont: UiFont.plex,
          ),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('the index lists every rule and opens its places', (
    tester,
  ) async {
    await pumpIndex(tester);
    await tester.tap(find.text('أحكام التجويد: ألوانها ومواضعها'));
    await settle(tester);
    final l = lookupAppLocalizations(const Locale('ar'));
    for (final rule in TajweedRule.values) {
      expect(find.text(tajweedRuleName(l, rule)), findsOneWidget);
    }
    // The madd lazim: 121 verses, the first al-Fatiha 7 on page 1.
    expect(find.text('الآيات: 121 · الحروف الملونة: 141'), findsOneWidget);
    await tester.tap(find.text(l.tajweedMadd6));
    await settle(tester);
    expect(find.byType(TajweedRuleScreen), findsOneWidget);
    expect(find.text('الفاتحة 7 · الصفحة 1'), findsOneWidget);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('a riwaya edition shows the colours without Hafs places', (
    tester,
  ) async {
    await pumpIndex(tester, edition: MushafEdition.warsh);
    await tester.tap(find.text('أحكام التجويد: ألوانها ومواضعها'));
    await settle(tester);
    final l = lookupAppLocalizations(const Locale('ar'));
    expect(find.text(l.tajweedNoDataRiwaya), findsOneWidget);
    final tile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, l.tajweedMadd6),
    );
    expect(tile.onTap, isNull);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}

/// Lets the database's futures and the route change finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }
}
