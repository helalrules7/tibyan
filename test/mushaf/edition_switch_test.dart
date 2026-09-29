import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/features/mushaf/data/page_pack.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('switching edition follows that edition\'s pages', () async {
    SharedPreferences.setMockInitialValues({'settings.edition': 'madina1441'});
    final root = Directory.systemTemp.createTempSync('packs');
    // Only the new Madina edition is on the device.
    Directory(p.join(root.path, 'packs', PagePackSpec.madina1441.id))
        .createSync(recursive: true);
    File(p.join(root.path, 'packs', PagePackSpec.madina1441.id, '.installed'))
        .writeAsStringSync('x');
    final container = ProviderContainer(
      overrides: [
        themeRegistryProvider.overrideWithValue(
          await ThemeRegistry.load(rootBundle),
        ),
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        packRootProvider.overrideWithValue(root),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(installedEditionsProvider), {
      MushafEdition.madina1441,
    });
    expect(container.read(pageDownloadProvider).phase, PackPhase.installed);

    await container
        .read(settingsProvider.notifier)
        .setEdition(MushafEdition.shamarly);
    // Not "installed" any more: the Shamarly pages are still to download.
    expect(container.read(pageDownloadProvider).phase, PackPhase.idle);
    expect(
      container.read(installedEditionsProvider),
      isNot(contains(MushafEdition.shamarly)),
    );
  });
}
