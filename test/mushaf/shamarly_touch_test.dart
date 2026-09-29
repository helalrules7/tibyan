import 'dart:io';

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
import 'package:tibyan/features/mushaf/presentation/widgets/shamarly_page.dart';
import 'package:tibyan/l10n/app_localizations.dart';

/// Touching a verse on the Shamarly opening pages, drawn from the real page
/// images (tools/.cache; skipped where they are not on disk, as in CI).
void main() {
  final pages = Directory('tools/.cache/shamarly/pages');

  for (final (page, verse) in [(2, (surah: 1, ayah: 5)), (3, null)]) {
    testWidgets(
      'long-pressing the middle of Shamarly page $page selects a verse',
      (tester) async {
        final db = ContentDatabase(
          NativeDatabase(
            File('assets/db/content.db'),
            setup: (raw) => raw.execute('PRAGMA query_only = ON'),
          ),
        );
        final root = Directory.systemTemp.createTempSync('shamarly');
        final dir = Directory(
          p.join(root.path, 'packs', 'pages-hafs-shamarly-v1'),
        )..createSync(recursive: true);
        final name = '${page.toString().padLeft(3, '0')}.png';
        File(p.join(pages.path, name)).copySync(p.join(dir.path, name));
        final registry = await tester.runAsync(
          () => ThemeRegistry.load(rootBundle),
        );
        final style = registry!.byId(registry.defaultStyleId);

        VerseKey? pressed;
        await tester.binding.setSurfaceSize(const Size(360, 700));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              contentDatabaseProvider.overrideWithValue(db),
              packRootProvider.overrideWithValue(root),
              editionProvider.overrideWithValue(MushafEdition.shamarly),
            ],
            child: MaterialApp(
              theme: buildTheme(
                style: style,
                mode: ThemeModeId.light,
                uiFont: UiFont.kfgqpcAn,
              ),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('ar'),
              home: ShamarlyMushafPage(
                page: page,
                interaction: PageInteraction(
                  selection: const {},
                  marks: const {},
                  onTap: () {},
                  onVerseLongPress: (v) => pressed = v,
                  onMarkerTap: (_) {},
                  onHandleDrag: (_, _) {},
                ),
              ),
            ),
          ),
        );
        // The page loads its image and geometry off the test clock.
        for (
          var i = 0;
          i < 20 && find.byType(GestureDetector).evaluate().isEmpty;
          i++
        ) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump();
        }
        await tester.longPressAt(const Offset(180, 350));
        await tester.pump();
        if (verse != null) {
          expect(pressed, verse);
        } else {
          expect(pressed, isNotNull);
        }
        await tester.runAsync(() => db.close());
      },
      skip: !pages.existsSync(),
    );
  }
}
