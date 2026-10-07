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
import 'package:tibyan/features/mushaf/presentation/widgets/tajweed_legend.dart';
import 'package:tibyan/features/share_image/share_text_runs.dart';
import 'package:tibyan/features/assistant/tajweed_marks_screen.dart';
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
        // Something is coloured, unless the rule is on marks only here
        // (those stay in ink in written text, see tokenRuns).
        if (p.letters.every((l) => l.marksOnly)) continue;
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

  test(
    'a rule on marks only leaves its letter in ink: al-Baqarah 19',
    () async {
      const red = Color(0xFFFF0000);
      final place = (await repo.tajweedPlaces(TajweedRule.iqlab.key))
          .singleWhere((p) => p.surah == 2 && p.ayah == 19);
      // The iqlab: the small meem over the ta of «مُحِيطُۢ» (word 18, its
      // marks only) and the ba of «بِٱلۡكَٰفِرِينَ» (word 19, the letter).
      expect(place.letters, contains((word: 18, letter: 3, marksOnly: true)));
      expect(place.letters, contains((word: 19, letter: 0, marksOnly: false)));
      final letters = [
        for (final l in place.letters)
          ShareTajweedLetter(
            word: l.word,
            letter: l.letter,
            marksOnly: l.marksOnly,
            color: red,
          ),
      ];
      final tokens = tajweedTokens(place);
      final muhit = tokens.singleWhere((t) => t.firstWord == 18);
      expect(muhit.text, 'مُحِيطُۢ');
      final runs = tokenRuns(
        muhit.text,
        firstWord: 18,
        endsVerse: muhit.endsVerse,
        letters: letters,
      );
      // Nothing of the word is coloured: not the ta, not its marks.
      expect(runs, [('مُحِيطُۢ', null)]);
      final bi = tokens.singleWhere((t) => t.firstWord == 19);
      final biRuns = tokenRuns(
        bi.text,
        firstWord: 19,
        endsVerse: bi.endsVerse,
        letters: letters,
      );
      expect(biRuns.first, ('بِ', red));
      expect(biRuns.map((r) => r.$1).join(), bi.text);
    },
  );

  test('no letter of the written text is coloured by a rule on marks '
      'only, in any verse', () async {
    const body = Color(0xFF00AA00);
    const marks = Color(0xFFFF0000);
    final rows = await db
        .customSelect(
          'SELECT a.display_text AS text, '
          "group_concat(t.word || ':' || t.letter || ':' || t.part, ' ') "
          'AS letters FROM tajweed_letter t '
          'JOIN ayah a ON a.surah = t.surah AND a.number = t.ayah '
          "WHERE t.riwaya = 'hafs' GROUP BY t.surah, t.ayah",
        )
        .get();
    var marksOnly = 0;
    var bodyLetters = 0;
    for (final r in rows) {
      final text = r.read<String>('text');
      final letters = TajweedPlace.parseLetters(r.read<String>('letters'));
      final shown = [
        for (final l in letters)
          ShareTajweedLetter(
            word: l.word,
            letter: l.letter,
            marksOnly: l.marksOnly,
            color: l.marksOnly ? marks : body,
          ),
      ];
      final bodies = {
        for (final l in letters)
          if (!l.marksOnly) (l.word, l.letter),
      };
      marksOnly += letters.where((l) => l.marksOnly).length;
      final tokens = text.split(' ');
      var word = 1;
      for (var i = 0; i < tokens.length; i++) {
        final endsVerse = i == tokens.length - 1;
        final runs = tokenRuns(
          tokens[i],
          firstWord: word,
          endsVerse: endsVerse,
          letters: shown,
        );
        expect(runs.map((r) => r.$1).join(), tokens[i]);
        expect(runs.where((r) => r.$2 == marks), isEmpty, reason: text);
        // Character by character: a letter is coloured only by a rule on
        // the letter itself.
        final colors = [for (final (t, c) in runs) ...List.filled(t.length, c)];
        var offset = 0;
        var w = word;
        final pieces = tokens[i].split(nbsp);
        for (var k = 0; k < pieces.length; k++) {
          final piece = pieces[k];
          if (wordsInToken(
                piece,
                endsVerse: endsVerse && k == pieces.length - 1,
              ) ==
              1) {
            final spans = letterSpans(piece);
            for (var li = 0; li < spans.length; li++) {
              final (s, e) = spans[li];
              final coloured = bodies.contains((w, li));
              if (coloured) bodyLetters++;
              for (var c = s; c < e; c++) {
                expect(
                  colors[offset + c],
                  coloured ? body : isNull,
                  reason: '$text word $w letter $li',
                );
              }
            }
            w++;
          }
          offset += piece.length + 1;
        }
        word += wordsInToken(tokens[i], endsVerse: endsVerse);
      }
    }
    expect(marksOnly, 13509);
    expect(bodyLetters, greaterThan(0));
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
          builder: (context, state) => const TajweedMarksScreen(),
        ),
        GoRoute(
          path: '/assistant/tajweed/rule',
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
