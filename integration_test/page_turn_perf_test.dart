// Frame times of page turns, per scenario and page-turn effect: a plain
// page, a page with an active fasil (each look), a page with only faded
// "ghost" fawasil from other pages, memorization masks, the 1405 and
// Shamarly editions (when their packs install), and the two-page spread
// (on a tablet).
//
// Run in profile mode on a device or emulator:
//   flutter drive --profile -d <device> \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/page_turn_perf_test.dart \
//     [--dart-define=PERF_SET=phone|tablet|editions]
//
// Prints one line per case:
//   PERF <scenario> <effect> frames=… build=avg/p90/p99 raster=avg/p90/p99
//   total=avg/p90/p99 jank60=…% jank120=…%
// where total is build start to raster end, jank60 the frames over
// 16.7 ms (build or raster), jank120 over 8.3 ms.
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tibyan/app.dart';
import 'package:tibyan/core/router/app_router.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/features/home/whats_new.dart'
    show whatsNewId, whatsNewSeenKey;
import 'package:tibyan/features/hifz/data/memorize_prefs.dart';
import 'package:tibyan/features/hifz/domain/memorize_session.dart';
import 'package:tibyan/features/mushaf/data/page_pack.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/mushaf/presentation/mushaf_screen.dart';
import 'package:tibyan/features/mushaf/presentation/navigation.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/page_turn_effect.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/mushaf_page.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/route_settle.dart';
import 'package:tibyan/main.dart' as app;

const _set = String.fromEnvironment('PERF_SET', defaultValue: 'phone');

/// Comma-separated scenario names (as printed) to run; empty = all.
const _only = String.fromEnvironment('PERF_ONLY');

/// Comma-separated page-turn effects to run; empty = all.
const _effects = String.fromEnvironment('PERF_EFFECTS');

/// How many times each case runs (one line each), for medians.
const _repeat = int.fromEnvironment('PERF_REPEAT', defaultValue: 1);

/// A fix to time against the old way in the same run, case by case:
/// `fade`, `memo`, `precache`, `reuse`, `artcache` or `defer`; each case then runs twice, the
/// old way (`~old`) and the new (`~new`).
const _abFix = String.fromEnvironment('PERF_AB');

/// Bake every page anew in every case (cold opens), whatever the A/B.
const _cold = bool.fromEnvironment('PERF_COLD');

List<String> get _abs => _abFix.isEmpty ? const [''] : const ['old', 'new'];

String _tag(String ab) => ab.isEmpty ? '' : '~$ab';

void _setAb(String ab) {
  final old = ab == 'old';
  PageTurnEffect.debugLayerFade = old && _abFix == 'fade';
  MushafScreen.debugFreshFawasil = old && _abFix == 'memo';
  PageTurnEffect.debugLazySnapshots = old && _abFix == 'precache';
  debugMushafKeyedByUri = old && _abFix == 'reuse';
  MushafPage.debugNoArtCache = _cold || (old && _abFix == 'artcache');
  debugNoNeighbourDefer = old && _abFix == 'defer';
}

bool _wanted(String scenario) =>
    _only.isEmpty || _only.split(',').contains(scenario);

List<PageTurn> get _effectList => [
  for (final e in PageTurn.values)
    if (_effects.isEmpty || _effects.split(',').contains(e.name)) e,
];

Future<void> pumpFor(WidgetTester t, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

String stats(List<double> v) {
  if (v.isEmpty) return '-';
  final s = [...v]..sort();
  double p(double q) => s[(s.length * q).floor().clamp(0, s.length - 1)];
  final avg = v.reduce((a, b) => a + b) / v.length;
  return '${avg.toStringAsFixed(1)}/${p(.9).toStringAsFixed(1)}/'
      '${p(.99).toStringAsFixed(1)}';
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('page-turn frame times', (t) async {
    SharedPreferences.setMockInitialValues({
      'settings.onboardingDone': true,
      'settings.mode': 'light',
      'settings.defaultsRev': 1,
      // The «what's new» sheet would cover the home screen.
      whatsNewSeenKey: whatsNewId,
    });
    unawaited(app.main());
    while (find.byType(TibyanApp).evaluate().isEmpty) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await pumpFor(t, const Duration(seconds: 3));
    final c = ProviderScope.containerOf(t.element(find.byType(TibyanApp)));
    final s = c.read(settingsProvider.notifier);
    final db = c.read(userDatabaseProvider);
    final memo = c.read(memorizePrefsProvider.notifier);
    var n = 0;

    Future<void> marks(List<(String, int, int, int, int)> list) async {
      for (final m in await db.watchBookmarkSets().first) {
        await db.deleteBookmarkSet(m.id);
      }
      for (final (name, color, surah, ayah, page) in list) {
        await db.addBookmarkSet(
          name: name,
          color: color,
          surah: surah,
          ayah: ayah,
          page: page,
        );
      }
    }

    final timings = <FrameTiming>[];
    void collect(List<FrameTiming> f) => timings.addAll(f);

    Future<void> run(String scenario, {bool memorize = false}) async {
      if (!_wanted(scenario)) return;
      for (final effect in _effectList) {
        for (final ab in [for (var r = 0; r < _repeat; r++) ..._abs]) {
          _setAb(ab);
          await s.setPageTurn(effect);
          c
              .read(appRouterProvider)
              .go('/mushaf?page=50${memorize ? '&memorize=1' : ''}&n=${n++}');
          await pumpFor(t, const Duration(seconds: 3));
          // A loaded host can be slow to open the page view.
          for (var i = 0; i < 150; i++) {
            if (find.byType(PageView).evaluate().isNotEmpty) break;
            await t.pump(const Duration(milliseconds: 100));
          }
          // One unmeasured pair: first-show entrances, shader warm-up.
          Future<void> turn(int i) async {
            final pager = find.byType(PageView).first;
            await t.fling(pager, Offset(i.isEven ? 320 : -320, 0), 1400);
            await pumpFor(t, const Duration(milliseconds: 1200));
          }

          // The very first turn after opening, timed on its own: what a
          // reader feels first (snapshots, shaders not ready yet).
          timings.clear();
          SchedulerBinding.instance.addTimingsCallback(collect);
          await turn(0);
          SchedulerBinding.instance.removeTimingsCallback(collect);
          final first = [...timings];
          await turn(1);
          timings.clear();
          SchedulerBinding.instance.addTimingsCallback(collect);
          for (var i = 0; i < 6; i++) {
            await turn(i);
          }
          await pumpFor(t, const Duration(milliseconds: 500));
          SchedulerBinding.instance.removeTimingsCallback(collect);
          double ms(Duration d) => d.inMicroseconds / 1000;
          final build = [for (final f in timings) ms(f.buildDuration)];
          final raster = [for (final f in timings) ms(f.rasterDuration)];
          final total = [for (final f in timings) ms(f.totalSpan)];
          int over(int us) => timings
              .where(
                (f) =>
                    f.buildDuration.inMicroseconds > us ||
                    f.rasterDuration.inMicroseconds > us,
              )
              .length;
          String pct(int k) => timings.isEmpty
              ? '-'
              : (100 * k / timings.length).toStringAsFixed(1);
          debugPrint(
            'PERF $scenario${_tag(ab)} ${effect.name} frames=${timings.length} '
            'build=${stats(build)} raster=${stats(raster)} '
            'total=${stats(total)} jank60=${pct(over(16667))}% '
            'jank120=${pct(over(8333))}%',
          );
          final fBuild = [for (final f in first) ms(f.buildDuration)];
          final fRaster = [for (final f in first) ms(f.rasterDuration)];
          double mx(List<double> v) =>
              v.isEmpty ? 0 : v.reduce((a, b) => a > b ? a : b);
          debugPrint(
            'PERF-FIRST $scenario${_tag(ab)} ${effect.name} frames=${first.length} '
            'buildmax=${mx(fBuild).toStringAsFixed(1)} '
            'rastermax=${mx(fRaster).toStringAsFixed(1)} '
            'jank60=${first.where((f) => f.buildDuration.inMicroseconds > 16667 || f.rasterDuration.inMicroseconds > 16667).length}',
          );
        }
      }
    }

    // Two fawasil on page 50 (the page read) and none elsewhere.
    const active = [
      ('حفظ', 0xFF1D2F55, 3, 1, 50),
      ('تلاوة', 0xFFC69A3A, 3, 5, 50),
    ];
    // Four fawasil far away: pages 49–51 show only their faded stubs.
    const ghosts = [
      ('حفظ', 0xFF1D2F55, 18, 1, 293),
      ('تلاوة', 0xFFC69A3A, 36, 1, 440),
      ('مراجعة', 0xFFEFE3C6, 67, 1, 562),
      ('ورد', 0xFF2E5E4A, 2, 255, 42),
    ];

    if (_set == 'index') {
      // From the index into the mushaf: what a tap on a surah does (its
      // first page looked up, then the route), timed to the target page's
      // first frame and to the end of the transition.
      Future<void> nav(String scenario) async {
        if (!_wanted(scenario)) return;
        c.read(appRouterProvider).go('/mushaf?page=10');
        await pumpFor(t, const Duration(seconds: 2));
        for (final effect in _effectList) {
          for (final ab in [for (var r = 0; r < _repeat; r++) ..._abs]) {
            _setAb(ab);
            await s.setPageTurn(effect);
            final lookup = <double>[], ttff = <double>[], settle = <double>[];
            // Frames until the transition settles, and the worst frame of
            // the first turn right after landing (onto a neighbour).
            final trans = <FrameTiming>[];
            final turnMax = <double>[];
            timings.clear();
            for (final (surah, page) in [(3, 50), (18, 293), (36, 440)]) {
              // As the reader does: the index pushed over the page.
              unawaited(c.read(appRouterProvider).push('/mushaf/index'));
              await pumpFor(t, const Duration(seconds: 2));
              // Engine frame clock, the same as FrameTiming's (reports come
              // in batches, so frames are told apart by time, not count).
              final from =
                  SchedulerBinding.instance.currentSystemFrameTimeStamp;
              SchedulerBinding.instance.addTimingsCallback(collect);
              final sw = Stopwatch()..start();
              final p = await c.read(versePageProvider((surah, 1)).future);
              lookup.add(sw.elapsedMicroseconds / 1000);
              c.read(appRouterProvider).go(mushafLocation(p));
              bool shown() => find
                  .byWidgetPredicate((w) => w is MushafPage && w.page == page)
                  .evaluate()
                  .isNotEmpty;
              while (!shown() && sw.elapsed.inSeconds < 10) {
                await t.pump(const Duration(milliseconds: 1));
              }
              await t.pump(const Duration(milliseconds: 1));
              ttff.add(sw.elapsedMicroseconds / 1000);
              var idle = 0;
              while (idle < 3 && sw.elapsed.inSeconds < 10) {
                await t.pump(const Duration(milliseconds: 16));
                idle = SchedulerBinding.instance.transientCallbackCount == 0
                    ? idle + 1
                    : 0;
              }
              settle.add(sw.elapsedMicroseconds / 1000);
              final atSettle =
                  SchedulerBinding.instance.currentSystemFrameTimeStamp;
              await pumpFor(t, const Duration(milliseconds: 300));
              SchedulerBinding.instance.removeTimingsCallback(collect);
              trans.addAll(
                timings.where((f) {
                  final v = f.timestampInMicroseconds(FramePhase.vsyncStart);
                  return v > from.inMicroseconds &&
                      v <= atSettle.inMicroseconds;
                }),
              );
              final kept = [...timings];
              timings.clear();
              SchedulerBinding.instance.addTimingsCallback(collect);
              await t.fling(
                find.byType(PageView).first,
                const Offset(320, 0),
                1400,
              );
              await pumpFor(t, const Duration(milliseconds: 1200));
              SchedulerBinding.instance.removeTimingsCallback(collect);
              turnMax.add(
                timings.fold<double>(
                  0,
                  (m, f) => f.rasterDuration.inMicroseconds / 1000 > m
                      ? f.rasterDuration.inMicroseconds / 1000
                      : m,
                ),
              );
              timings
                ..clear()
                ..addAll(kept);
            }
            double ms(Duration d) => d.inMicroseconds / 1000;
            final build = [for (final f in timings) ms(f.buildDuration)];
            final raster = [for (final f in timings) ms(f.rasterDuration)];
            final janky = timings
                .where(
                  (f) =>
                      f.buildDuration.inMicroseconds > 16667 ||
                      f.rasterDuration.inMicroseconds > 16667,
                )
                .length;
            debugPrint(
              'PERF index-$scenario${_tag(ab)} ${effect.name} frames=${timings.length} '
              'lookup=${stats(lookup)} ttff=${stats(ttff)} '
              'settle=${stats(settle)} build=${stats(build)} '
              'raster=${stats(raster)} jank60=$janky '
              'transframes=${trans.length} transraster=${stats([for (final f in trans) ms(f.rasterDuration)])} '
              'transjank=${trans.where((f) => f.buildDuration.inMicroseconds > 16667 || f.rasterDuration.inMicroseconds > 16667).length} '
              'turnmax=${stats(turnMax)}',
            );
          }
        }
      }

      await marks(const []);
      await nav('nomarks');
      await marks([...active, ...ghosts]);
      await s.setFasilStyle(FasilStyle.ribbon);
      await nav('marks-ribbon');
      await s.setFasilStyle(FasilStyle.tab);
      await nav('marks-tab');
      await marks(const []);
      return;
    }

    if (_set == 'home') {
      // Home «متابعة القراءة»: from the home screen into the mushaf at the
      // saved position (page 293), as the card's tap does. A: an ornate
      // (art) frame with two fawasil on the page, B: the plain frame with
      // them, C: the plain frame and no fawasil.
      final db2 = c.read(userDatabaseProvider);
      await db2.savePosition(
        edition: MushafEdition.madina1441.name,
        view: 'page',
        surah: 18,
        ayah: 1,
        page: 293,
      );
      Future<void> home(String scenario) async {
        if (!_wanted(scenario)) return;
        for (final ab in [for (var r = 0; r < _repeat; r++) ..._abs]) {
          _setAb(ab);
          c.read(appRouterProvider).go('/');
          await pumpFor(t, const Duration(seconds: 2));
          timings.clear();
          SchedulerBinding.instance.addTimingsCallback(collect);
          final from = SchedulerBinding.instance.currentSystemFrameTimeStamp;
          final sw = Stopwatch()..start();
          c.read(appRouterProvider).go('/mushaf?entry=home');
          bool shown() => find
              .byWidgetPredicate((w) => w is MushafPage && w.page == 293)
              .evaluate()
              .isNotEmpty;
          while (!shown() && sw.elapsed.inSeconds < 10) {
            await t.pump(const Duration(milliseconds: 1));
          }
          await t.pump(const Duration(milliseconds: 1));
          final ttff = sw.elapsedMicroseconds / 1000;
          var idle = 0;
          while (idle < 3 && sw.elapsed.inSeconds < 10) {
            await t.pump(const Duration(milliseconds: 16));
            idle = SchedulerBinding.instance.transientCallbackCount == 0
                ? idle + 1
                : 0;
          }
          final settle = sw.elapsedMicroseconds / 1000;
          final atSettle =
              SchedulerBinding.instance.currentSystemFrameTimeStamp;
          await pumpFor(t, const Duration(milliseconds: 300));
          SchedulerBinding.instance.removeTimingsCallback(collect);
          final trans = [
            for (final f in timings)
              if (f.timestampInMicroseconds(FramePhase.vsyncStart) >
                      from.inMicroseconds &&
                  f.timestampInMicroseconds(FramePhase.vsyncStart) <=
                      atSettle.inMicroseconds)
                f,
          ];
          final kept = [...timings];
          timings.clear();
          SchedulerBinding.instance.addTimingsCallback(collect);
          await t.fling(
            find.byType(PageView).first,
            const Offset(320, 0),
            1400,
          );
          await pumpFor(t, const Duration(milliseconds: 1200));
          SchedulerBinding.instance.removeTimingsCallback(collect);
          final turnMax = timings.fold<double>(
            0,
            (m, f) => f.rasterDuration.inMicroseconds / 1000 > m
                ? f.rasterDuration.inMicroseconds / 1000
                : m,
          );
          timings
            ..clear()
            ..addAll(kept);
          double ms(Duration d) => d.inMicroseconds / 1000;
          final build = [for (final f in timings) ms(f.buildDuration)];
          final raster = [for (final f in timings) ms(f.rasterDuration)];
          double sum(List<double> v) =>
              v.isEmpty ? 0 : v.reduce((a, b) => a + b);
          final janky = timings
              .where(
                (f) =>
                    f.buildDuration.inMicroseconds > 16667 ||
                    f.rasterDuration.inMicroseconds > 16667,
              )
              .length;
          debugPrint(
            'PERF home-$scenario${_tag(ab)} frames=${timings.length} '
            'ttff=${ttff.toStringAsFixed(1)} '
            'settle=${settle.toStringAsFixed(1)} build=${stats(build)} '
            'raster=${stats(raster)} buildsum=${sum(build).toStringAsFixed(0)} '
            'rastersum=${sum(raster).toStringAsFixed(0)} jank60=$janky '
            'transframes=${trans.length} '
            'transraster=${stats([for (final f in trans) ms(f.rasterDuration)])} '
            'transjank=${trans.where((f) => f.buildDuration.inMicroseconds > 16667 || f.rasterDuration.inMicroseconds > 16667).length} '
            'turnmax=${turnMax.toStringAsFixed(1)}',
          );
        }
      }

      await s.setPageTurn(PageTurn.curl);
      await s.setFasilStyle(FasilStyle.ribbon);
      await marks([
        ('حفظ', 0xFF1D2F55, 18, 1, 293),
        ('تلاوة', 0xFFC69A3A, 18, 5, 293),
      ]);
      await s.setStyle('hijazi');
      await home('A-ornate-fasil');
      await s.setStyle('simple');
      await home('B-plain-fasil');
      await marks(const []);
      await home('C-plain-nofasil');
      return;
    }

    if (_set == 'editions') {
      await marks(const []);
      for (final ed in [MushafEdition.madina1405, MushafEdition.shamarly]) {
        final keep = c.listen(editionDownloadProvider(ed), (_, _) {});
        if (c.read(editionDownloadProvider(ed)).phase != PackPhase.installed) {
          unawaited(c.read(editionDownloadProvider(ed).notifier).start());
          final end = DateTime.now().add(const Duration(minutes: 20));
          while (c.read(editionDownloadProvider(ed)).phase !=
                  PackPhase.installed &&
              DateTime.now().isBefore(end)) {
            await t.pump(const Duration(milliseconds: 500));
          }
        }
        keep.close();
        if (c.read(editionDownloadProvider(ed)).phase != PackPhase.installed) {
          debugPrint('PERF ${ed.name} not installed');
          continue;
        }
        await s.setEdition(ed);
        await pumpFor(t, const Duration(seconds: 1));
        await run('${ed.name}/plain');
        await marks(active);
        await s.setFasilStyle(FasilStyle.ribbon);
        await run('${ed.name}/active-ribbon');
        await marks(const []);
      }
      await s.setEdition(MushafEdition.madina1441);
      return;
    }

    if (_set == 'tablet') await s.setTwoPageSpread(true);

    await marks(const []);
    await run('plain');
    await marks(active);
    for (final style in FasilStyle.values) {
      await s.setFasilStyle(style);
      await run('active-${style.name}');
    }
    await marks(ghosts);
    for (final style in [FasilStyle.ribbon, FasilStyle.tab]) {
      await s.setFasilStyle(style);
      await run('ghost-${style.name}');
    }
    if (_set == 'phone') {
      await marks(const []);
      await memo.setStyle(MaskStyle.all);
      await run('memorize', memorize: true);
    }
    await marks(const []);
  }, timeout: const Timeout(Duration(minutes: 60)));
}
