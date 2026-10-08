import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/flags/feature_flags.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/books/books_providers.dart';
import 'package:tibyan/features/books/data/book_pack.dart';
import 'package:tibyan/features/books/presentation/book_section.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/verse_services.dart';
import 'package:tibyan/l10n/app_localizations.dart';

import 'fake_pack.dart';

void main() {
  late BookPack pack;
  setUp(() => pack = BookPack(fakeBooksPackDb()));
  tearDown(() => pack.close());

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Map<String, bool> flags = const {},
    List<BookPack>? packs,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    final registry = await tester.runAsync(
      () => ThemeRegistry.load(rootBundle),
    );
    await tester.binding.setSurfaceSize(const Size(420, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeRegistryProvider.overrideWithValue(registry!),
          sharedPreferencesProvider.overrideWithValue(prefs!),
          featureFlagsProvider.overrideWithValue(FeatureFlags(flags)),
          installedBookPacksProvider.overrideWithValue(packs ?? [pack]),
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
          home: Scaffold(
            body: SingleChildScrollView(child: SelectionArea(child: child)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// The text spans of the rich text that reads exactly [text].
  List<TextSpan> spansOf(WidgetTester tester, String text) {
    final body = tester.widget<RichText>(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText() == text,
      ),
    );
    final out = <TextSpan>[];
    body.text.visitChildren((s) {
      if (s is TextSpan && s.text != null) out.add(s);
      return true;
    });
    return out;
  }

  final munasabatOn = {Feature.munasabat.key: true};

  group('munasabat', () {
    const section = BookSection(
      spec: BookSectionSpec.munasabat,
      surah: 2,
      ayah: 3,
    );

    testWidgets('each entry verbatim, the verses it covers, its citation', (
      tester,
    ) async {
      await pump(tester, section, flags: munasabatOn);
      expect(find.text('المناسبات'), findsOneWidget);
      expect(find.text(fakeMunasabaText, findRichText: true), findsOneWidget);
      expect(find.text('الآيات ٢–٣'), findsOneWidget);
      expect(find.text('«كتاب مناسبات تجريبي»، مؤلف تجريبي'), findsOneWidget);
      // Only the munasabat book.
      expect(find.textContaining('نص تفسير'), findsNothing);
    });

    testWidgets('hidden when the flag is off', (tester) async {
      await pump(tester, section);
      expect(find.text('المناسبات'), findsNothing);
      expect(find.textContaining('نص مناسبة'), findsNothing);
    });

    testWidgets('hidden when no reviewed pack is installed', (tester) async {
      await pump(tester, section, flags: munasabatOn, packs: []);
      expect(find.text('المناسبات'), findsNothing);
    });

    testWidgets('hidden for a verse with no entry', (tester) async {
      await pump(
        tester,
        const BookSection(spec: BookSectionSpec.munasabat, surah: 2, ayah: 4),
        flags: munasabatOn,
      );
      expect(find.text('المناسبات'), findsNothing);
    });

    testWidgets('the verse panel offers it only when there are entries', (
      tester,
    ) async {
      Widget panel(int count) => VerseServicesPanel(
        verses: const [(surah: 2, ayah: 2)],
        surahs: null,
        onMark: (_) {},
        onSaveToFasil: () {},
        onClose: () {},
        onMultiSelect: () {},
        onTafsir: () {},
        onListen: () {},
        onWordStudy: null,
        onWordMeanings: () {},
        munasabatCount: count,
        onMunasabat: () {},
      );
      await pump(tester, panel(1), flags: munasabatOn);
      expect(find.text('المناسبات (١)'), findsOneWidget);
      await pump(tester, panel(0), flags: munasabatOn);
      expect(find.textContaining('المناسبات'), findsNothing);
    });
  });

  group('book tafsir', () {
    Widget section(int ayah, {String source = 'test_tafsir_a'}) => BookSection(
      spec: BookSectionSpec.tafsir,
      surah: 2,
      ayah: ayah,
      source: source,
      title: 'تفسير تجريبي أول',
    );

    testWidgets('a passage on several verses shows once, with its range; '
        '﴿ ﴾ quotes coloured, { } left as they are', (tester) async {
      await pump(tester, section(3));
      expect(find.text('تفسير تجريبي أول'), findsOneWidget);
      expect(find.text('الآيات ١–٥'), findsOneWidget);
      expect(find.text('[2.1-5]', findRichText: true), findsOneWidget);
      expect(find.text('«تفسير تجريبي أول»، مؤلف تجريبي'), findsOneWidget);

      final spans = spansOf(tester, fakeTafsirText);
      final gold = tester
          .element(find.byType(BookSection))
          .tokens
          .colors
          .goldText;
      expect(
        spans.where((s) => s.text == 'نص آية تجريبي').single.style?.color,
        gold,
      );
      final braces = spans.where((s) => s.text!.contains('{')).single;
      expect(braces.text, contains('{نص بين معقوفين}'));
      expect(braces.style?.color, isNot(gold));
    });

    testWidgets('a surah\'s introduction shows on its first verse only', (
      tester,
    ) async {
      await pump(tester, section(1));
      expect(find.text(fakeSurahIntro, findRichText: true), findsOneWidget);
      expect(find.text('الآيات ١–٢٨٦'), findsOneWidget);
      await pump(tester, section(2));
      expect(find.text(fakeSurahIntro, findRichText: true), findsNothing);
      expect(find.text(fakeTafsirText, findRichText: true), findsOneWidget);
    });

    testWidgets('a passage on one verse has no range', (tester) async {
      await pump(tester, section(6));
      expect(find.text(fakeTafsirText2, findRichText: true), findsOneWidget);
      expect(find.textContaining('الآيات'), findsNothing);
    });

    testWidgets('one book at a time', (tester) async {
      await pump(tester, section(1, source: 'test_tafsir_b'));
      expect(
        find.text(fakeOtherTafsirText, findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('نص تفسير تجريبي'), findsNothing);
    });

    testWidgets('nothing without a pack or for a verse without a passage', (
      tester,
    ) async {
      await pump(tester, section(3), packs: []);
      expect(find.text('تفسير تجريبي أول'), findsNothing);
      await pump(tester, section(7));
      expect(find.text('تفسير تجريبي أول'), findsNothing);
    });
  });

  group('the storage names each kind', () {
    testWidgets('kind titles', (tester) async {
      await pump(tester, const SizedBox());
      final l = AppLocalizations.of(tester.element(find.byType(SizedBox)));
      expect(bookKindTitle(l, BookKind.asbabNuzul), 'أسباب النزول');
      expect(bookKindTitle(l, BookKind.tafsir), 'تفسير');
      expect(bookKindTitle(l, BookKind.munasabat), 'المناسبات');
      expect(bookKindTitle(l, BookKind.wujuhNazair), 'الوجوه والنظائر');
    });
  });
}
