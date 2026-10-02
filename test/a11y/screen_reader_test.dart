import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/db/user_database.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/home/home_screen.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/mushaf_page.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/page_interaction.dart';
import 'package:tibyan/features/search/search_screen.dart';
import 'package:tibyan/features/search/semantic/meaning_providers.dart';
import 'package:tibyan/features/settings/settings_screen.dart';
import 'package:tibyan/l10n/app_localizations.dart';
import 'package:tibyan/features/khatma/khatma_providers.dart';
import 'package:tibyan/features/hifz/hifz_providers.dart';

/// TalkBack / VoiceOver: the main screens have every control labelled and
/// large enough, with readable text, and the mushaf page names its verses.
void main() {
  late ContentDatabase db;
  late Directory root;
  setUpAll(() {
    db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
    root = Directory.systemTemp.createTempSync('a11y');
  });
  tearDownAll(() => db.close());

  Future<void> settle(WidgetTester tester, [int rounds = 8]) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
  }

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    Map<String, Object> prefs = const {},
    List overrides = const [],
  }) async {
    final registry = (await tester.runAsync(
      () => ThemeRegistry.load(rootBundle),
    ))!;
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    final user = UserDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(user.close));
    await tester.binding.setSurfaceSize(const Size(420, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentDatabaseProvider.overrideWithValue(db),
          userDatabaseProvider.overrideWithValue(user),
          themeRegistryProvider.overrideWithValue(registry),
          sharedPreferencesProvider.overrideWithValue(sp),
          packRootProvider.overrideWithValue(root),
          // No drift stream (its timers outlive the test).
          readingPositionProvider.overrideWith((ref) => Stream.value(null)),
          ...overrides.cast(),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTheme(
            style: registry.byId(registry.defaultStyleId),
            mode: ThemeModeId.light,
            uiFont: UiFont.changa,
          ),
          home: home,
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> guidelines(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  testWidgets('home: tiles are labelled buttons that can be activated', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    // No khatma and no reviews due: both come from database streams that
    // would leave a timer pending when the test ends.
    await pump(
      tester,
      const HomeScreen(),
      overrides: [
        khatmaStatusProvider.overrideWith((ref) async => null),
        srsItemsProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    await guidelines(tester);
    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp('^البحث'))),
      isSemantics(label: 'البحث. افتح', isButton: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp('^تبيان'))),
      isSemantics(isHeader: true),
    );
    handle.dispose();
  });

  testWidgets('settings: labelled, large enough, readable', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const SettingsScreen());
    await guidelines(tester);
    // The elderly-mode switch says what it is and whether it is on.
    final node = tester.getSemantics(find.text('وضع كبار السن'));
    expect(node.label, contains('وضع كبار السن'));
    handle.dispose();
  });

  testWidgets('search by words: results name the verse; the count is live', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const SearchScreen());
    await tester.enterText(find.byType(TextField), 'الصمد');
    await tester.pump(const Duration(milliseconds: 300));
    await settle(tester);
    // The card reads «سورة الإخلاص، الآية ٢» first, then the verse.
    expect(
      find.bySemanticsLabel(RegExp('^سورة الإخلاص، الآية ٢')),
      findsOneWidget,
    );
    await guidelines(tester);
    handle.dispose();
  });

  testWidgets('search by meaning: the pack offer and keyword results', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      const SearchScreen(),
      prefs: {'search.mode': 'meaning'},
      overrides: [semanticInstalledProvider.overrideWithValue(false)],
    );
    expect(find.text('تنزيل الحزمة'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'patience prayer');
    await tester.pump(const Duration(milliseconds: 300));
    await settle(tester, 30);
    // Every result names its verse, and the text that matched is shown
    // with its source.
    expect(find.textContaining('طابق في'), findsWidgets);
    expect(find.bySemanticsLabel(RegExp(r'^سورة .+، الآية ')), findsWidgets);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('the mushaf page names each verse and acts on it', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final dir = Directory(p.join(root.path, 'packs', 'pages-hafs-1441-v1'))
      ..createSync(recursive: true);
    final zip = ZipDecoder().decodeBytes(
      File('assets/packs/pages-hafs-1441-v1.zip').readAsBytesSync(),
    );
    final entry = zip.findFile('604.svg.xz')!;
    File(p.join(dir.path, entry.name)).writeAsBytesSync(entry.content);
    VerseKey? selected;
    VerseKey? marked;
    var taps = 0;
    await pump(
      tester,
      MushafPage(
        page: 604,
        interaction: PageInteraction(
          selection: const {},
          marks: const {},
          onTap: () => taps++,
          onVerseLongPress: (v) => selected = v,
          onMarkerTap: (v) => marked = v,
          onHandleDrag: (_, _) {},
          verseLabel: (v) => 'سورة ${v.surah}، الآية ${v.ayah}',
          verseText: (v) => 'نص ${v.ayah}',
        ),
      ),
      overrides: [editionProvider.overrideWithValue(MushafEdition.madina1441)],
    );
    await settle(tester, 30);
    // Page 604: al-Ikhlas, al-Falaq and an-Nas, 15 verses.
    final labels = [
      for (var a = 1; a <= 6; a++) 'سورة 114، الآية $a',
      for (var a = 1; a <= 4; a++) 'سورة 112، الآية $a',
    ];
    for (final label in labels) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    final node = tester.getSemantics(
      find.bySemanticsLabel('سورة 113، الآية 1'),
    );
    expect(node.value, 'نص 1');
    // A double tap selects the verse (opens its services).
    tester.binding.performSemanticsAction(
      SemanticsActionEvent(
        type: SemanticsAction.tap,
        viewId: tester.view.viewId,
        nodeId: node.id,
      ),
    );
    expect(selected, (surah: 113, ayah: 1));
    // The custom action sets the reading mark.
    final action = node.getSemanticsData().customSemanticsActionIds!.single;
    tester.binding.performSemanticsAction(
      SemanticsActionEvent(
        type: SemanticsAction.customAction,
        viewId: tester.view.viewId,
        nodeId: node.id,
        arguments: action,
      ),
    );
    expect(marked, (surah: 113, ayah: 1));
    // The nodes take no touches: a tap still reaches the page.
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(taps, 1);
    handle.dispose();
  });
}
