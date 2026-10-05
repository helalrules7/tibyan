import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/flags/feature_flags.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/books/books_providers.dart';
import 'package:tibyan/features/books/data/book_pack.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/word_study/data/word_study_repository.dart';
import 'package:tibyan/features/word_study/word_study_sheet.dart';
import 'package:tibyan/l10n/app_localizations.dart';

import '../books/fake_pack.dart';

/// The sheets, drawn from the real bundled database.
void main() {
  late ContentDatabase db;

  setUpAll(() {
    db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
  });
  tearDownAll(() => db.close());

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool wujuh = false,
    List<BookPack> packs = const [],
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    final registry = (await tester.runAsync(
      () => ThemeRegistry.load(rootBundle),
    ))!;
    await tester.binding.setSurfaceSize(const Size(420, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentDatabaseProvider.overrideWithValue(db),
          themeRegistryProvider.overrideWithValue(registry),
          sharedPreferencesProvider.overrideWithValue(prefs!),
          featureFlagsProvider.overrideWithValue(
            FeatureFlags({Feature.wujuhNazair.key: wujuh}),
          ),
          installedBookPacksProvider.overrideWithValue(packs),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTheme(
            style: registry.byId(registry.defaultStyleId),
            mode: ThemeModeId.light,
            uiFont: UiFont.plex,
          ),
          home: Scaffold(body: child),
        ),
      ),
    );
    // The queries run on the database's own isolate, off the test clock.
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
  }

  /// The book's entries for a verse, read straight from the database.
  Future<List<GharibRow>> entries(WidgetTester tester, int s, int a) async =>
      (await tester.runAsync(
        () => WordStudyRepository(db).gharibOfVerse(s, a),
      ))!;

  testWidgets('al-Rahman: meaning, root, lemma and where the root occurs', (
    tester,
  ) async {
    await pump(tester, const WordStudySheet(surah: 1, ayah: 1, word: 3));

    expect(find.text('دراسة الكلمة'), findsOneWidget);
    // The book's entry, verbatim, with its source.
    final rahman = (await entries(tester, 1, 1))[1];
    expect((rahman.wordFrom, rahman.wordTo), (3, 3));
    expect(
      find.textContaining(rahman.body, findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('نقاية'), findsOneWidget);
    // The corpus's root and lemma, with its source.
    expect(find.byKey(const ValueKey('root')), findsOneWidget);
    expect(find.text('ر ح م'), findsOneWidget);
    expect(
      find.textContaining(
        '\u0631\u0651\u064e\u062d\u0652\u0645\u064e\u0670\u0646',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.textContaining('corpus.quran.com'), findsOneWidget);
    // Where the root occurs: its count, then the verses (1:1 first).
    // 339 words of ر ح م in 313 verses.
    expect(find.text('الكلمات: ٣٣٩، الآيات: ٣١٣'), findsOneWidget);
    // The header and the first verse where the root occurs.
    expect(find.text('سورة الفاتحة، الآية ١'), findsNWidgets(2));
  });

  testWidgets('choosing another word of the verse studies it', (tester) async {
    await pump(tester, const WordStudySheet(surah: 1, ayah: 1));
    expect(find.text('اختر كلمة من كلمات الآية'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('word-2')));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    expect(find.text('أ ل ه'), findsOneWidget);
    // The book's first entry covers words 1 and 2 (bismi-llahi).
    final first = (await entries(tester, 1, 1)).first;
    expect(find.textContaining(first.body, findRichText: true), findsOneWidget);
  });

  testWidgets('a word without an entry shows none', (tester) async {
    // لِلَّهِ in 1:2: the book explains ٱلۡحَمۡدُ and ٱلۡعَٰلَمِينَ only.
    await pump(tester, const WordStudySheet(surah: 1, ayah: 2, word: 2));
    expect(
      find.text('لا شرح لهذه الكلمة في «الميسر في غريب القرآن».'),
      findsOneWidget,
    );
    final hamd = (await entries(tester, 1, 2)).first;
    expect(hamd.wordFrom, 1);
    expect(find.textContaining(hamd.body, findRichText: true), findsNothing);
  });

  testWidgets('word meanings of a verse list the book\'s entries', (
    tester,
  ) async {
    await pump(tester, const VerseMeaningsSheet(verses: [(surah: 1, ayah: 7)]));
    expect(find.text('معاني الكلمات'), findsOneWidget);
    for (final e in await entries(tester, 1, 7)) {
      expect(find.textContaining(e.body, findRichText: true), findsOneWidget);
    }
    expect(find.textContaining('نقاية'), findsOneWidget);
  });

  group('al-Damghani\'s senses of the word (wujuh)', () {
    late BookPack pack;
    setUp(() => pack = BookPack(fakeBooksPackDb()));
    tearDown(() => pack.close());

    testWidgets('the senses linked to this word, under their word header', (
      tester,
    ) async {
      await pump(
        tester,
        const WordStudySheet(surah: 1, ayah: 1, word: 3),
        wujuh: true,
        packs: [pack],
      );
      expect(find.text('الوجوه والنظائر'), findsOneWidget);
      // The header once, verbatim, then each sense verbatim.
      expect(find.text(fakeWordText, findRichText: true), findsOneWidget);
      expect(find.text(fakeWajh1, findRichText: true), findsOneWidget);
      expect(find.text(fakeWajh2, findRichText: true), findsOneWidget);
      expect(
        find.text('«كتاب وجوه تجريبي»، مؤلف تجريبي، تحقيق محقق تجريبي، ص ٧'),
        findsNWidgets(2),
      );
      expect(find.textContaining('ص ٨'), findsOneWidget);
    });

    testWidgets('a sense tied to another word is not shown', (tester) async {
      await pump(
        tester,
        const WordStudySheet(surah: 1, ayah: 1, word: 2),
        wujuh: true,
        packs: [pack],
      );
      expect(find.text(fakeWajh1, findRichText: true), findsNothing);
      expect(find.text(fakeWajh2, findRichText: true), findsOneWidget);
    });

    testWidgets('a sense whose header is not reviewed shows without one', (
      tester,
    ) async {
      await pump(
        tester,
        const WordStudySheet(surah: 1, ayah: 2, word: 1),
        wujuh: true,
        packs: [pack],
      );
      expect(find.text(fakeWajhOrphan, findRichText: true), findsOneWidget);
      // Its own heading (the book's), not another word's header text.
      expect(
        find.text('كلمة أخرى على وجهين', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining(fakeWordText), findsNothing);
    });

    testWidgets('nothing when the flag is off, without a pack, or for a '
        'verse without senses', (tester) async {
      await pump(
        tester,
        const WordStudySheet(surah: 1, ayah: 1, word: 3),
        packs: [pack],
      );
      expect(find.text('الوجوه والنظائر'), findsNothing);
      await pump(
        tester,
        const WordStudySheet(surah: 1, ayah: 1, word: 3),
        wujuh: true,
      );
      expect(find.text('الوجوه والنظائر'), findsNothing);
      await pump(
        tester,
        const WordStudySheet(surah: 1, ayah: 3, word: 1),
        wujuh: true,
        packs: [pack],
      );
      expect(find.text('الوجوه والنظائر'), findsNothing);
    });
  });
}
