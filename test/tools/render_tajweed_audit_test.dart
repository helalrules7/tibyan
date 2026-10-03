import 'dart:io';
import 'dart:ui' as ui;

import 'package:archive/archive_io.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';
import 'package:tibyan/features/mushaf/data/tajweed.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/mushaf_page.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/old_mushaf_page.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/page_interaction.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/shamarly_page.dart';
import 'package:tibyan/l10n/app_localizations.dart';

/// Not a test: draws real pages of each edition with the tajweed colouring
/// on (default colours, light paper) and off, through the app's own page
/// widgets, into `build/tajweed_audit/app_<edition>_p<NNN>_<on|off>.png`,
/// for tools/audit_tajweed.py and a human to check where the colours land.
/// Runs only with RENDER_TAJWEED_AUDIT=1 and the page sources in
/// tools/.cache (images_1024.zip, shamarly/shamarly-pages-archive-org.zip).
void main() {
  final run = Platform.environment['RENDER_TAJWEED_AUDIT'] == '1';
  const madina = [2, 3, 50, 106, 187, 300, 450, 582, 604];
  const shamarly = [2, 3, 5, 44, 90, 162, 260, 390, 504, 522, 32, 103];

  testWidgets('render tajweed audit pages', (tester) async {
    final db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
    final repo = MushafRepository(db);
    final registry = await tester.runAsync(
      () => ThemeRegistry.load(rootBundle),
    );
    final style = registry!.byId(registry.defaultStyleId);
    final out = Directory('build/tajweed_audit')..createSync(recursive: true);
    final root = Directory.systemTemp.createTempSync('tajweed_audit');

    // Pack folders as the app keeps them once installed.
    final newDir = Directory(p.join(root.path, 'packs', 'pages-hafs-1441-v1'))
      ..createSync(recursive: true);
    final newZip = ZipDecoder().decodeBytes(
      File('assets/packs/pages-hafs-1441-v1.zip').readAsBytesSync(),
    );
    for (final pg in madina) {
      final e = newZip.findFile('${pg.toString().padLeft(3, '0')}.svg.xz')!;
      File(p.join(newDir.path, e.name)).writeAsBytesSync(e.content);
    }
    File(p.join(newDir.path, '.installed')).writeAsStringSync('x');

    final oldDir = Directory(
      p.join(root.path, 'packs', 'pages-hafs-1405-qurancom-1024'),
    )..createSync(recursive: true);
    final oldZip = ZipDecoder().decodeStream(
      InputFileStream('tools/.cache/images_1024.zip'),
    );
    for (final pg in madina) {
      final e = oldZip.findFile(
        'width_1024/page${pg.toString().padLeft(3, '0')}.png',
      )!;
      File(
        p.join(oldDir.path, 'p${pg.toString().padLeft(3, '0')}.png'),
      ).writeAsBytesSync(e.content);
    }
    File(p.join(oldDir.path, 'ayahinfo.db')).writeAsBytesSync(
      oldZip.findFile('databases/ayahinfo_1024.db')!.content,
    );
    File(p.join(oldDir.path, '.installed')).writeAsStringSync('x');

    final shDir = Directory(p.join(root.path, 'packs', 'pages-hafs-shamarly-v1'))
      ..createSync(recursive: true);
    final shZip = ZipDecoder().decodeStream(
      InputFileStream('tools/.cache/shamarly/shamarly-pages-archive-org.zip'),
    );
    for (final pg in shamarly) {
      final name = '${pg.toString().padLeft(3, '0')}.png';
      File(p.join(shDir.path, name)).writeAsBytesSync(
        shZip.findFile(name)!.content,
      );
    }
    File(p.join(shDir.path, '.installed')).writeAsStringSync('x');

    Color? colour(TajweedRule r) =>
        tajweedHueOf(r, const {})?.on(darkPaper: false);

    Future<void> shoot(MushafEdition edition, int page, bool on) async {
      final data = on
          ? await tester.runAsync(() => repo.tajweedPage(edition, page))
          : '';
      final interaction = PageInteraction(
        selection: const {},
        marks: const {},
        onTap: () {},
        onVerseLongPress: (_) {},
        onMarkerTap: (_) {},
        onHandleDrag: (_, _) {},
        tajweedColor: on ? colour : null,
        tajweed: data ?? '',
      );
      final boundary = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            contentDatabaseProvider.overrideWithValue(db),
            packRootProvider.overrideWithValue(root),
            editionProvider.overrideWithValue(edition),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(
              style: style,
              mode: ThemeModeId.light,
              uiFont: UiFont.changa,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),
            home: RepaintBoundary(
              key: boundary,
              child: ColoredBox(
                color: Colors.white,
                child: switch (edition) {
                  MushafEdition.madina1405 => OldMushafPage(
                    page: page,
                    interaction: interaction,
                  ),
                  MushafEdition.shamarly => ShamarlyMushafPage(
                    page: page,
                    interaction: interaction,
                  ),
                  _ => MushafPage(page: page, interaction: interaction),
                },
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 40; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }
      final object =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await object.toImage(pixelRatio: 2);
        final d = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        return d!.buffer.asUint8List();
      });
      final n = page.toString().padLeft(3, '0');
      File(
        '${out.path}/app_${edition.name}_p${n}_${on ? 'on' : 'off'}.png',
      ).writeAsBytesSync(bytes!);
    }

    await tester.binding.setSurfaceSize(const Size(560, 860));
    for (final (edition, pages) in [
      (MushafEdition.madina1441, madina),
      (MushafEdition.madina1405, madina),
      (MushafEdition.shamarly, shamarly),
    ]) {
      for (final pg in pages) {
        await shoot(edition, pg, false);
        await shoot(edition, pg, true);
      }
    }
    await tester.runAsync(() => db.close());
  }, skip: !run, timeout: const Timeout(Duration(minutes: 20)));
}
