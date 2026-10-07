import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/db/user_database.dart';
import 'package:tibyan/core/flags/feature_flags.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/l10n/app_localizations.dart';

/// The real content database (read only) and the 1441 pages a test needs,
/// unpacked once into a temporary pack folder.
class TasmeeTestData {
  TasmeeTestData._(this.db, this.root);

  final ContentDatabase db;
  final Directory root;

  static TasmeeTestData open({List<int> pages = const [3]}) {
    final db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
    final root = Directory.systemTemp.createTempSync('tasmee_test');
    final dir = Directory(p.join(root.path, 'packs', 'pages-hafs-1441-v1'))
      ..createSync(recursive: true);
    final zip = ZipDecoder().decodeBytes(
      File('assets/packs/pages-hafs-1441-v1.zip').readAsBytesSync(),
    );
    for (final page in pages) {
      final entry = zip.findFile('${page.toString().padLeft(3, '0')}.svg.xz')!;
      File(p.join(dir.path, entry.name)).writeAsBytesSync(entry.content);
    }
    File(p.join(dir.path, '.installed')).writeAsStringSync('test');
    return TasmeeTestData._(db, root);
  }

  Future<void> close() async {
    await db.close();
    if (root.existsSync()) root.deleteSync(recursive: true);
  }
}

/// A provider container over [data] with the given preferences.
Future<ProviderContainer> tasmeeContainer(
  WidgetTester tester,
  TasmeeTestData data, {
  Map<String, Object> prefs = const {},
  List overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({
    'settings.onboardingDone': true,
    'settings.language': 'ar',
    ...prefs,
  });
  final registry = (await tester.runAsync(
    () => ThemeRegistry.load(rootBundle),
  ))!;
  final flags = (await tester.runAsync(() => FeatureFlags.load(rootBundle)))!;
  final shared = await SharedPreferences.getInstance();
  final user = UserDatabase(NativeDatabase.memory());
  addTearDown(() => tester.runAsync(user.close));
  final container = ProviderContainer(
    overrides: [
      themeRegistryProvider.overrideWithValue(registry),
      featureFlagsProvider.overrideWithValue(flags),
      sharedPreferencesProvider.overrideWithValue(shared),
      contentDatabaseProvider.overrideWithValue(data.db),
      userDatabaseProvider.overrideWithValue(user),
      packRootProvider.overrideWithValue(data.root),
      readingPositionProvider.overrideWith((ref) => Stream.value(null)),
      ...overrides.cast(),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// The app's theme for [mode], in the default style.
ThemeData tasmeeTheme(
  ProviderContainer container, {
  ThemeModeId mode = ThemeModeId.light,
  bool elderly = false,
  String style = 'zakhrafa',
}) => buildTheme(
  style: container.read(themeRegistryProvider).byId(style),
  mode: mode,
  uiFont: UiFont.plex,
  elderly: elderly,
);

/// [home] in a MaterialApp with the app's localisations and [theme].
Widget tasmeeApp(
  ProviderContainer container,
  Widget home, {
  required ThemeData theme,
  String lang = 'ar',
  GlobalKey? boundary,
}) => RepaintBoundary(
  key: boundary,
  child: UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(lang),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: theme,
      home: home,
    ),
  ),
);

/// Lets async loads (database, page artwork, baking) finish.
Future<void> settle(WidgetTester tester, {int rounds = 20}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}
