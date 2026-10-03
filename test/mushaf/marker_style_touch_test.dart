import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/mushaf_page.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/page_interaction.dart';
import 'package:tibyan/l10n/app_localizations.dart';

/// Changing the verse-marker shape redraws the page without its printed
/// markers; a tap must still reach the page afterwards.
void main() {
  testWidgets('the page answers taps after the marker shape changes', (
    tester,
  ) async {
    final db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
    final root = Directory.systemTemp.createTempSync('marker');
    final dir = Directory(p.join(root.path, 'packs', 'pages-hafs-1441-v1'))
      ..createSync(recursive: true);
    final zip = ZipDecoder().decodeBytes(
      File('assets/packs/pages-hafs-1441-v1.zip').readAsBytesSync(),
    );
    final entry = zip.findFile('050.svg.xz')!;
    File(p.join(dir.path, entry.name)).writeAsBytesSync(entry.content);
    final registry = await tester.runAsync(
      () => ThemeRegistry.load(rootBundle),
    );
    final style = registry!.byId(registry.defaultStyleId);

    var taps = 0;
    Widget app(MarkerLook? look) => ProviderScope(
      overrides: [
        contentDatabaseProvider.overrideWithValue(db),
        packRootProvider.overrideWithValue(root),
        editionProvider.overrideWithValue(MushafEdition.madina1441),
      ],
      child: MaterialApp(
        theme: buildTheme(
          style: style,
          mode: ThemeModeId.light,
          uiFont: UiFont.changa,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ar'),
        home: MushafPage(
          page: 50,
          interaction: PageInteraction(
            selection: const {},
            marks: const {},
            markerLook: look,
            onTap: () => taps++,
            onVerseLongPress: (_) {},
            onMarkerTap: (_) {},
            onHandleDrag: (_, _) {},
          ),
        ),
      ),
    );

    Future<void> settle() async {
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
    }

    await tester.binding.setSurfaceSize(const Size(360, 640));
    await tester.pumpWidget(app(null));
    await settle();
    await tester.tapAt(const Offset(180, 320));
    await tester.pump();
    expect(taps, 1);

    await tester.pumpWidget(
      app(
        const MarkerLook(
          style: MarkerStyle.rosette16,
          image: null,
          tint: null,
          paper: Colors.white,
          ink: Colors.black,
        ),
      ),
    );
    await settle();
    expect(tester.takeException(), isNull);
    await tester.tapAt(const Offset(180, 320));
    await tester.pump();
    expect(taps, 2);
    await tester.runAsync(() => db.close());
  });
}
