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

/// Not a test: draws a few pages of each edition with the tajweed colouring
/// on, in every mode, through the app's own page widgets, into
/// `$TAJWEED_PERF_OUT/<edition>_p<NNN>_<mode>.png` (default
/// build/tajweed_perf), so the drawing can be compared before and after a
/// change to it (pixel for pixel). Runs only with RENDER_TAJWEED_PERF=1 and
/// the page sources in tools/.cache (images_1024.zip,
/// shamarly/shamarly-pages-archive-org.zip).
void main() {
  final run = Platform.environment['RENDER_TAJWEED_PERF'] == '1';
  final outPath =
      Platform.environment['TAJWEED_PERF_OUT'] ?? 'build/tajweed_perf';
  const shots = [
    (MushafEdition.madina1441, 50),
    (MushafEdition.madina1441, 187),
    (MushafEdition.madina1405, 50),
    (MushafEdition.shamarly, 44),
  ];

  testWidgets(
    'render tajweed pages in every mode',
    (tester) async {
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
      final out = Directory(outPath)..createSync(recursive: true);
      final root = Directory.systemTemp.createTempSync('tajweed_perf');
      String n3(int pg) => pg.toString().padLeft(3, '0');

      // Pack folders as the app keeps them once installed.
      final newDir = Directory(p.join(root.path, 'packs', 'pages-hafs-1441-v1'))
        ..createSync(recursive: true);
      final newZip = ZipDecoder().decodeBytes(
        File('assets/packs/pages-hafs-1441-v1.zip').readAsBytesSync(),
      );
      final oldDir = Directory(
        p.join(root.path, 'packs', 'pages-hafs-1405-qurancom-1024'),
      )..createSync(recursive: true);
      final oldZip = ZipDecoder().decodeStream(
        InputFileStream('tools/.cache/images_1024.zip'),
      );
      final shDir = Directory(
        p.join(root.path, 'packs', 'pages-hafs-shamarly-v1'),
      )..createSync(recursive: true);
      final shZip = ZipDecoder().decodeStream(
        InputFileStream('tools/.cache/shamarly/shamarly-pages-archive-org.zip'),
      );
      for (final (edition, pg) in shots) {
        switch (edition) {
          case MushafEdition.madina1441:
            final e = newZip.findFile('${n3(pg)}.svg.xz')!;
            File(p.join(newDir.path, e.name)).writeAsBytesSync(e.content);
          case MushafEdition.madina1405:
            final e = oldZip.findFile('width_1024/page${n3(pg)}.png')!;
            File(p.join(oldDir.path, 'p${n3(pg)}.png'))
                .writeAsBytesSync(e.content);
          default:
            final name = '${n3(pg)}.png';
            File(p.join(shDir.path, name))
                .writeAsBytesSync(shZip.findFile(name)!.content);
        }
      }
      File(p.join(oldDir.path, 'ayahinfo.db')).writeAsBytesSync(
        oldZip.findFile('databases/ayahinfo_1024.db')!.content,
      );
      for (final d in [newDir, oldDir, shDir]) {
        File(p.join(d.path, '.installed')).writeAsStringSync('x');
      }

      Future<void> shoot(
        MushafEdition edition,
        int page,
        ThemeModeId mode,
      ) async {
        final data = await tester.runAsync(
          () => repo.tajweedPage(edition, page),
        );
        final interaction = PageInteraction(
          selection: const {},
          marks: const {},
          onTap: () {},
          onVerseLongPress: (_) {},
          onMarkerTap: (_) {},
          onHandleDrag: (_, _) {},
          tajweedColor: (r) =>
              tajweedHueOf(r, const {})?.on(darkPaper: !mode.isLight),
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
                mode: mode,
                uiFont: UiFont.changa,
              ),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('ar'),
              home: RepaintBoundary(
                key: boundary,
                child: ColoredBox(
                  color: style.modes[mode]!.paper,
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
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final bytes = await tester.runAsync(() async {
          final image = await object.toImage(pixelRatio: 2);
          final d = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          return d!.buffer.asUint8List();
        });
        File('${out.path}/${edition.name}_p${n3(page)}_${mode.name}.png')
            .writeAsBytesSync(bytes!);
      }

      // The surface is drawn at a device pixel ratio of 2, so the baked
      // pages are blitted one to one.
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(1120, 1720);
      addTearDown(tester.view.reset);
      for (final (edition, pg) in shots) {
        for (final mode in ThemeModeId.values) {
          await shoot(edition, pg, mode);
        }
      }
      await tester.runAsync(() => db.close());
    },
    skip: !run,
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
