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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/app.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/db/user_database.dart';
import 'package:tibyan/core/flags/feature_flags.dart';
import 'package:tibyan/core/router/app_router.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/features/home/whats_new.dart';
import 'package:tibyan/features/khatma/data/khatmah_book.dart';
import 'package:tibyan/features/khatma/data/khatmah_store.dart';
import 'package:tibyan/features/khatma/domain/day.dart';
import 'package:tibyan/features/khatma/domain/khatmah.dart';
import 'package:tibyan/features/khatma/khatma_providers.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/l10n/app_localizations.dart';

import '../khatma/support.dart';

/// Not a test: draws the khatma screens of phases 6–9 through the app's
/// router, in Arabic with the bundled fonts, light and night, at a phone
/// and a laptop size, into `$KHATMAH_REVIEW_OUT/<name>.png`: the list with
/// two plans, the three wizard steps, a plan's details (plan and statistics
/// tabs), the completion dialog, the reader's «ورد اليوم» indicator (menus
/// and focus mode) and «ask» line, and the home cards (normal and elderly).
/// Runs only with RENDER_KHATMAH_REVIEW=1; KHATMAH_REVIEW_ONLY limits it to
/// names containing one of its comma-separated words.
void main() {
  final run = Platform.environment['RENDER_KHATMAH_REVIEW'] == '1';
  final outPath =
      Platform.environment['KHATMAH_REVIEW_OUT'] ??
      'build/khatmah_review_previews';
  final only = Platform.environment['KHATMAH_REVIEW_ONLY']?.split(',');
  const sizes = {
    'phone': (Size(393, 852), 59.0, 34.0),
    'laptop': (Size(1440, 900), 0.0, 0.0),
  };

  testWidgets(
    'render khatmah review previews',
    (tester) async {
      for (final m in ['toggle', 'isEnabled']) {
        tester.binding.defaultBinaryMessenger.setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.$m',
          (_) async => const StandardMessageCodec().encodeMessage(<Object?>[
            m == 'isEnabled' ? false : null,
          ]),
        );
      }
      final db = ContentDatabase(
        NativeDatabase(
          File('assets/db/content.db'),
          setup: (raw) => raw.execute('PRAGMA query_only = ON'),
        ),
      );
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
      final registry = (await tester.runAsync(
        () => ThemeRegistry.load(rootBundle),
      ))!;
      final flags = (await tester.runAsync(
        () => FeatureFlags.load(rootBundle),
      ))!;
      final index = (await tester.runAsync(realIndex))!;
      final ar = (await tester.runAsync(
        () => AppLocalizations.delegate.load(const Locale('ar')),
      ))!;
      final out = Directory(outPath)..createSync(recursive: true);
      final root = Directory.systemTemp.createTempSync('khatmah_review');
      final pagesDir = Directory(
        p.join(root.path, 'packs', 'pages-hafs-1441-v1'),
      )..createSync(recursive: true);
      await tester.runAsync(() async {
        final zip = ZipDecoder().decodeStream(
          InputFileStream('assets/packs/pages-hafs-1441-v1.zip'),
        );
        for (final e in zip.files) {
          if (!e.isFile) continue;
          File(p.join(pagesDir.path, e.name)).writeAsBytesSync(e.content);
        }
      });
      File(p.join(pagesDir.path, '.installed')).writeAsStringSync('x');

      bool wanted(String name) =>
          only == null || only.any((w) => name.contains(w));

      const primaryId = 'review-primary';
      const otherId = 'review-baqarah';

      /// Two open plans: the primary full khatma, 10 days in with today's
      /// portion begun, and a Baqarah plan in `ask` mode with yesterday's
      /// reading waiting for an answer.
      Future<int> seed(UserDatabase user) async {
        final now = DateTime.now();
        final today = Day.logical(now, 3);
        final store = KhatmahStore(user);
        var n = 0;
        final book = KhatmahBook(
          store: store,
          index: index,
          clock: () => now,
          newUuid: () => 'review-${n++}',
        );
        final pages = index.madina1441;
        await book.create(
          Khatmah(
            uuid: primaryId,
            title: 'ختمة الشهر',
            kind: KhatmahKind.fullQuran,
            rangeStart: 1,
            rangeEnd: index.ayahCount,
            dailyWeight: 20,
            startDate: today.add(-10),
            targetDate: today.add(19),
            isPrimary: true,
            reminderTime: 20 * 60,
            createdAt: now.subtract(const Duration(days: 10)),
          ),
        );
        var page = 1;
        Future<void> read(Day day, int count, {int? from}) async {
          final first = from ?? page;
          final verses = pages.versesReadOn([
            for (var i = first; i < first + count; i++) i,
          ]);
          if (from == null) page += count;
          final at = day.start.add(const Duration(hours: 9));
          final session = 'session-${day.year}-${day.month}-${day.day}-$first';
          await store.putSession(
            SessionRecord(
              uuid: session,
              start: at,
              end: at.add(Duration(minutes: count)),
              activeSeconds: count * 40,
              pages: count,
              ranges: verses,
              edition: 'madina1441',
            ),
          );
          await book.record(
            session: session,
            verses: verses,
            at: at.add(Duration(minutes: count)),
            edition: 'madina1441',
          );
        }

        // Ten days of reading, two of them missed: nothing marks them.
        for (var d = 10; d >= 1; d--) {
          if (d == 6 || d == 3) continue;
          await read(today.add(-d), 20);
        }
        await book.create(
          Khatmah(
            uuid: otherId,
            title: 'سورة البقرة',
            kind: KhatmahKind.partial,
            rangeStart: index.idOf(2, 1),
            rangeEnd: index.idOf(2, 286),
            startAt: index.idOf(2, 1),
            dailyWeight: 4,
            startDate: today.add(-2),
            targetDate: today.add(10),
            counting: CountingMode.ask,
            createdAt: now.subtract(const Duration(days: 2)),
          ),
        );
        // Yesterday: three pages of al-Baqarah, not yet counted for it.
        await read(today.add(-1), 3, from: 2);
        // Today: four pages of the portion.
        await read(today, 4);
        return page - 4;
      }

      Future<void> shot(
        String name,
        String location,
        String size, {
        Map<String, Object> prefs = const {},
        Future<void> Function(ProviderContainer c)? act,
      }) async {
        if (!wanted(name)) return;
        final (logical, top, bottom) = sizes[size]!;
        SharedPreferences.setMockInitialValues({
          'settings.onboardingDone': true,
          'settings.language': 'ar',
          'settings.style': 'zakhrafa',
          'settings.mode': 'light',
          whatsNewSeenKey: whatsNewId,
          ...prefs,
        });
        final shared = (await tester.runAsync(SharedPreferences.getInstance))!;
        final user = UserDatabase(NativeDatabase.memory());
        await tester.runAsync(() => seed(user));
        await tester.binding.setSurfaceSize(logical);
        tester.view.devicePixelRatio = 2;
        tester.view.padding = FakeViewPadding(top: top * 2, bottom: bottom * 2);
        tester.view.viewPadding = FakeViewPadding(
          top: top * 2,
          bottom: bottom * 2,
        );
        final container = ProviderContainer(
          overrides: [
            themeRegistryProvider.overrideWithValue(registry),
            featureFlagsProvider.overrideWithValue(flags),
            sharedPreferencesProvider.overrideWithValue(shared),
            contentDatabaseProvider.overrideWithValue(db),
            userDatabaseProvider.overrideWithValue(user),
            packRootProvider.overrideWithValue(root),
            readingPositionProvider.overrideWith((ref) => Stream.value(null)),
          ],
        );
        final boundary = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: UncontrolledProviderScope(
              key: UniqueKey(),
              container: container,
              child: const TibyanApp(),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 2));
        container.read(appRouterProvider).go(location);
        Future<void> settle() async {
          for (var i = 0; i < 40; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 50)),
            );
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        await settle();
        if (act != null) {
          await act(container);
          await settle();
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
        File('${out.path}/$name.png').writeAsBytesSync(bytes!);
        await tester.pumpWidget(const SizedBox());
        container.dispose();
        tester.takeException();
      }

      Future<void> tapText(String text) async {
        final f = find.text(text);
        if (f.evaluate().isEmpty) return;
        await tester.ensureVisible(f.first);
        await tester.pump();
        await tester.tap(f.first, warnIfMissed: false);
      }

      // The page today's portion goes on from (the seed reads 4 pages today
      // after 160).
      const readerPage = 165;
      for (final mode in ['light', 'night']) {
        for (final size in sizes.keys) {
          final s = '${mode}_$size';
          final prefs = <String, Object>{'settings.mode': mode};
          await shot('list_$s', '/khatma', size, prefs: prefs);
          await shot('wizard1_$s', '/khatma/new', size, prefs: prefs);
          await shot(
            'wizard2_$s',
            '/khatma/new',
            size,
            prefs: prefs,
            act: (_) => tapText(ar.continueLabel),
          );
          await shot(
            'wizard3_$s',
            '/khatma/new',
            size,
            prefs: prefs,
            act: (_) async {
              await tapText(ar.continueLabel);
              for (var i = 0; i < 10; i++) {
                await tester.pump(const Duration(milliseconds: 100));
              }
              await tapText(ar.continueLabel);
            },
          );
          await shot('plan_$s', '/khatma?plan=$primaryId', size, prefs: prefs);
          await shot(
            'plan_ask_$s',
            '/khatma?plan=$otherId',
            size,
            prefs: prefs,
          );
          await shot(
            'stats_$s',
            '/khatma?plan=$primaryId',
            size,
            prefs: prefs,
            act: (_) => tapText(ar.khatmaTabStats),
          );
          await shot(
            'completion_$s',
            '/khatma?plan=$primaryId',
            size,
            prefs: prefs,
            act: (c) async {
              final k = await tester.runAsync(
                () =>
                    KhatmahStore(c.read(userDatabaseProvider)).byUuid(otherId),
              );
              c
                  .read(khatmahEventsProvider.notifier)
                  .completed(BookChange(completed: [k!]));
            },
          );
          await shot('reports_$s', '/khatma/reports', size, prefs: prefs);
          await shot(
            'reader_menus_$s',
            '/mushaf?page=$readerPage',
            size,
            prefs: prefs,
            act: (_) async {
              final (logical, top, _) = sizes[size]!;
              // The space above the page: the menus, not a verse.
              await tester.tapAt(Offset(logical.width / 2, top / 2 + 20));
            },
          );
          await shot(
            'reader_ask_$s',
            '/mushaf?page=$readerPage',
            size,
            prefs: prefs,
          );
          await shot(
            'reader_focus_$s',
            '/mushaf?page=$readerPage',
            size,
            prefs: {...prefs, 'settings.focusMode': true},
          );
          await shot('home_$s', '/', size, prefs: prefs);
          await shot(
            'home_elderly_$s',
            '/',
            size,
            prefs: {...prefs, 'settings.elderlyMode': true},
          );
        }
      }
      // Let the app's last timers run out.
      await tester.pump(const Duration(seconds: 20));
      await tester.runAsync(db.close);
    },
    skip: !run,
    timeout: const Timeout(Duration(minutes: 60)),
  );
}
