import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/app.dart';
import 'package:tibyan/core/flags/feature_flags.dart';
import 'package:tibyan/core/router/app_router.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/features/audio/recitation.dart';
import 'package:tibyan/features/books/books_providers.dart';
import 'package:tibyan/features/books/data/book_pack.dart';
import 'package:tibyan/features/mushaf/data/page_pack.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';

/// Book packs on the storage screen (a file of its own: the app is
/// pumped once per file here).
void main() {
  testWidgets('an installed book pack is listed with its kind', (tester) async {
    SharedPreferences.setMockInitialValues({'settings.onboardingDone': true});
    final registry = await ThemeRegistry.load(rootBundle);
    final flags = await FeatureFlags.load(rootBundle);
    final prefs = await SharedPreferences.getInstance();
    final root = Directory.systemTemp.createTempSync('storage_books');
    const installed = BookPackSpec(
      id: 'tafsir-test-v1',
      url: 'https://example.invalid/tafsir-test-v1.pack.db',
      sha256: '',
      bytes: 2000000,
      kind: BookKind.tafsir,
      title: 'تفسير تجريبي',
    );
    const offered = BookPackSpec(
      id: 'wujuh-test-v1',
      url: 'https://example.invalid/wujuh-test-v1.pack.db',
      sha256: '',
      bytes: 1000000,
      kind: BookKind.wujuhNazair,
      title: 'كتاب وجوه تجريبي',
    );
    final dir = Directory(p.join(root.path, 'packs', installed.id))
      ..createSync(recursive: true);
    File(p.join(dir.path, 'book.db')).writeAsBytesSync(List.filled(2000000, 1));
    File(p.join(dir.path, '.installed')).writeAsStringSync('');
    final container = ProviderContainer(
      overrides: [
        themeRegistryProvider.overrideWithValue(registry),
        featureFlagsProvider.overrideWithValue(flags),
        sharedPreferencesProvider.overrideWithValue(prefs),
        packRootProvider.overrideWithValue(root),
        allRecitersProvider.overrideWith((ref) async => const []),
        bookPackSpecsProvider.overrideWithValue(const [installed, offered]),
        bookDownloadsProvider.overrideWith(_NoDownloads.new),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TibyanApp()),
    );
    await tester.pump(const Duration(seconds: 2));
    container.read(appRouterProvider).go('/settings/storage');
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('كتاب «تفسير تجريبي»'), findsOneWidget);
    expect(find.textContaining('· تفسير'), findsOneWidget);
    expect(find.text('كتاب «كتاب وجوه تجريبي»'), findsOneWidget);
    expect(find.textContaining('· الوجوه والنظائر'), findsOneWidget);
  });
}

/// No background downloader in a widget test.
class _NoDownloads extends BookDownloads {
  @override
  Map<String, PackProgress> build() => const {};
}
