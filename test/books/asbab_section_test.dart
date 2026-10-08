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
import 'package:tibyan/features/books/presentation/asbab_section.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/verse_services.dart';
import 'package:tibyan/l10n/app_localizations.dart';

import 'fake_pack.dart';

void main() {
  late BookPack pack;
  setUp(() => pack = fakePack());
  tearDown(() => pack.close());

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool flag = true,
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
          featureFlagsProvider.overrideWithValue(
            FeatureFlags({Feature.asbabNuzul.key: flag}),
          ),
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

  testWidgets('shows each entry verbatim, its quotes coloured, and where '
      'it is from', (tester) async {
    await pump(tester, const AsbabSection(surah: 2, ayah: 1));

    expect(find.text('أسباب النزول'), findsOneWidget);
    // The text as stored, line break and all, in one rich text.
    final body = tester.widget<RichText>(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText() == fakeText1,
      ),
    );
    final quoted = <TextSpan>[];
    body.text.visitChildren((s) {
      if (s is TextSpan && s.text != null && s.text!.contains('نص آية')) {
        quoted.add(s);
      }
      return true;
    });
    final plain = <TextSpan>[];
    body.text.visitChildren((s) {
      if (s is TextSpan && s.text != null && s.text!.startsWith('نص تجريبي')) {
        plain.add(s);
      }
      return true;
    });
    final context = tester.element(find.byType(AsbabSection));
    expect(quoted.single.style?.color, context.tokens.colors.goldText);
    expect(plain.first.style?.color, isNot(context.tokens.colors.goldText));

    // Citation line: book, author, publisher, edition, page; then the
    // publisher's own wording exactly.
    expect(
      find.text('«كتاب تجريبي»، مؤلف تجريبي، ناشر تجريبي، الطبعة الأولى، ص ١٢'),
      findsOneWidget,
    );
    expect(find.textContaining('ص ١٥–١٦'), findsOneWidget);
    expect(find.text(fakeCitation), findsNWidgets(2));
    // The heading, verbatim.
    expect(find.text('عنوان ﴿تجريبي﴾', findRichText: true), findsOneWidget);
    // Only the asbab book's entries.
    expect(find.textContaining('نص كتاب آخر'), findsNothing);
  });

  testWidgets('copy gives the text exactly, with its citation', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pump(tester, const AsbabSection(surah: 2, ayah: 3));
    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();
    expect(copied, contains(fakeText1));
    expect(copied, startsWith('عنوان ﴿تجريبي﴾\n$fakeText1\n'));
    expect(copied, endsWith(fakeCitation));
  });

  testWidgets('hidden when the flag is off', (tester) async {
    await pump(tester, const AsbabSection(surah: 2, ayah: 1), flag: false);
    expect(find.text('أسباب النزول'), findsNothing);
    expect(find.textContaining('نص تجريبي'), findsNothing);
  });

  testWidgets('hidden when no reviewed pack is installed', (tester) async {
    await pump(tester, const AsbabSection(surah: 2, ayah: 1), packs: []);
    expect(find.text('أسباب النزول'), findsNothing);
  });

  testWidgets('hidden for a verse with no entry', (tester) async {
    await pump(tester, const AsbabSection(surah: 2, ayah: 6));
    expect(find.text('أسباب النزول'), findsNothing);
  });

  testWidgets('the verse panel offers it only when there are entries', (
    tester,
  ) async {
    Widget panel(int count) => VerseServicesPanel(
      verses: const [(surah: 2, ayah: 1)],
      surahs: null,
      onMark: (_) {},
      onSaveToFasil: () {},
      onClose: () {},
      onMultiSelect: () {},
      onTafsir: () {},
      onListen: () {},
      onWordStudy: null,
      onWordMeanings: () {},
      asbabCount: count,
      onAsbab: () {},
    );
    await pump(tester, panel(2));
    expect(find.text('أسباب النزول (٢)'), findsOneWidget);
    await pump(tester, panel(0));
    expect(find.textContaining('أسباب النزول'), findsNothing);
  });
}
