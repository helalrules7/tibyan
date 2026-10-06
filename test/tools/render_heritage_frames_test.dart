import 'dart:convert';
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
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/illuminated_frame.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/mushaf_page.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/old_mushaf_page.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/page_interaction.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/shamarly_page.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/theme_art.dart';
import 'package:tibyan/l10n/app_localizations.dart';

/// Not a test: draws real text pages of each edition in the heritage
/// themes' frames, with the theme's verse markers, at a phone size and a
/// two-page spread, through the app's own frame and page widgets, into
/// `$HERITAGE_FRAMES_OUT/<theme>_<edition>_p<NNN>_<size>[_frame].png`
/// (`_frame`: the same with the page left out, so the page's own ink is
/// what differs; `_art`: the frame's art alone, without the labels). Runs only with RENDER_HERITAGE_FRAMES=1 and the page
/// sources in tools/.cache (images_1024.zip,
/// shamarly/shamarly-pages-archive-org.zip).
void main() {
  final run = Platform.environment['RENDER_HERITAGE_FRAMES'] == '1';
  final outPath =
      Platform.environment['HERITAGE_FRAMES_OUT'] ?? 'build/heritage_frames';
  final only = Platform.environment['HERITAGE_FRAMES_THEMES']?.split(',');
  const themes = [
    'seljuk',
    'umayyad',
    'timurid',
    'hijazi',
    'fatimid',
    'andalusi',
    'mamluk',
    'abbasid',
  ];
  const shots = [
    (MushafEdition.madina1441, 50),
    (MushafEdition.madina1441, 400),
    (MushafEdition.madina1405, 50),
    (MushafEdition.shamarly, 44),
  ];
  const sizes = {'phone': Size(393, 852), 'spread': Size(1400, 1000)};

  testWidgets(
    'render heritage frames',
    (tester) async {
      final db = ContentDatabase(
        NativeDatabase(
          File('assets/db/content.db'),
          setup: (raw) => raw.execute('PRAGMA query_only = ON'),
        ),
      );
      final registry = await tester.runAsync(
        () => ThemeRegistry.load(rootBundle),
      );
      // The app's fonts, so the labels and the verse numbers are drawn.
      await tester.runAsync(() async {
        final manifest = jsonDecode(
          await rootBundle.loadString('FontManifest.json'),
        ) as List<dynamic>;
        for (final f in manifest.cast<Map<String, dynamic>>()) {
          final loader = FontLoader(f['family'] as String);
          for (final a in (f['fonts'] as List).cast<Map<String, dynamic>>()) {
            loader.addFont(
              rootBundle.load(Uri.decodeFull(a['asset'] as String)),
            );
          }
          await loader.load();
        }
      });
      final out = Directory(outPath)..createSync(recursive: true);
      final root = Directory.systemTemp.createTempSync('heritage_frames');
      const madina = [50, 51, 400, 401];
      const shamarly = [44, 45];

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
        File(p.join(oldDir.path, 'p${pg.toString().padLeft(3, '0')}.png'))
            .writeAsBytesSync(e.content);
      }
      File(p.join(oldDir.path, 'ayahinfo.db')).writeAsBytesSync(
        oldZip.findFile('databases/ayahinfo_1024.db')!.content,
      );
      File(p.join(oldDir.path, '.installed')).writeAsStringSync('x');

      final shDir = Directory(
        p.join(root.path, 'packs', 'pages-hafs-shamarly-v1'),
      )..createSync(recursive: true);
      final shZip = ZipDecoder().decodeStream(
        InputFileStream('tools/.cache/shamarly/shamarly-pages-archive-org.zip'),
      );
      for (final pg in shamarly) {
        final name = '${pg.toString().padLeft(3, '0')}.png';
        File(p.join(shDir.path, name))
            .writeAsBytesSync(shZip.findFile(name)!.content);
      }
      File(p.join(shDir.path, '.installed')).writeAsStringSync('x');

      const mode = ThemeModeId.light;
      for (final id in themes) {
        if (only != null && !only.contains(id)) continue;
        final style = registry!.byId(id);
        final tokens = style.modes[mode]!;
        final art = await tester.runAsync(() => loadThemeArt(style.art!, mode));
        final look = MarkerLook(
          style: MarkerStyle.theme,
          image: null,
          art: art!.marker,
          tint: null,
          paper: tokens.paper,
          ink: tokens.ink,
        );
        final interaction = PageInteraction(
          selection: const {},
          marks: const {},
          onTap: () {},
          onVerseLongPress: (_) {},
          onMarkerTap: (_) {},
          onHandleDrag: (_, _) {},
          markerLook: look,
        );
        for (final (edition, page) in shots) {
          for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
            for (final variant in ['', '_frame', '_art']) {
              final frameOnly = variant.isNotEmpty;
              final spread = sizeName == 'spread';
              final pages = spread ? [page, page + 1] : [page];
              Widget pageBody(int pg) => frameOnly
                  ? const SizedBox.expand()
                  : switch (edition) {
                      MushafEdition.madina1405 => OldMushafPage(
                        page: pg,
                        interaction: interaction,
                      ),
                      MushafEdition.shamarly => ShamarlyMushafPage(
                        page: pg,
                        interaction: interaction,
                      ),
                      _ => MushafPage(page: pg, interaction: interaction),
                    };
              Widget pageOf(int pg) => Consumer(
                builder: (context, ref, _) => Padding(
                  padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
                  child: IlluminatedFrame(
                    info: variant == '_art'
                        ? null
                        : ref.watch(frameInfoProvider(pg)).value,
                    showCatchword: false,
                    linePadding: edition == MushafEdition.shamarly
                        ? shamarlyLinePadding
                        : null,
                    child: pageBody(pg),
                  ),
                ),
              );
              await tester.binding.setSurfaceSize(size);
              // The frame is drawn into an image at this ratio: the same as
              // the capture's, so every render draws it to the same pixels.
              tester.view.devicePixelRatio = 2;
              final boundary = GlobalKey();
              await tester.pumpWidget(
                ProviderScope(
                  key: UniqueKey(),
                  overrides: [
                    themeRegistryProvider.overrideWithValue(registry),
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
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    locale: const Locale('ar'),
                    home: RepaintBoundary(
                      key: boundary,
                      child: Material(
                        color: tokens.bg,
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              for (final pg in pages)
                                Expanded(child: pageOf(pg)),
                            ],
                          ),
                        ),
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
                final d = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                image.dispose();
                return d!.buffer.asUint8List();
              });
              final n = page.toString().padLeft(3, '0');
              File(
                '${out.path}/${id}_${edition.name}_p${n}_$sizeName'
                '$variant.png',
              ).writeAsBytesSync(bytes!);
            }
          }
        }
      }
      await tester.runAsync(() => db.close());
    },
    skip: !run,
    timeout: const Timeout(Duration(minutes: 40)),
  );
}
