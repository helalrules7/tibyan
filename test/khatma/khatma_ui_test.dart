import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tibyan/core/db/user_database.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/khatma/data/khatmah_book.dart';
import 'package:tibyan/features/khatma/data/khatmah_store.dart';
import 'package:tibyan/features/khatma/domain/day.dart';
import 'package:tibyan/features/khatma/domain/interval_set.dart';
import 'package:tibyan/features/khatma/domain/khatmah.dart';
import 'package:tibyan/features/khatma/domain/quran_index.dart';
import 'package:tibyan/features/khatma/khatma_providers.dart';
import 'package:tibyan/features/khatma/presentation/khatma_screen.dart';
import 'package:tibyan/features/khatma/presentation/new_khatma_screen.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/l10n/app_localizations.dart';

import 'support.dart';

const _previewSizes = {'phone': Size(390, 844), 'large': Size(768, 1024)};

late QuranIndex _index;
late ThemeData _theme;
late AppLocalizations _en;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    _index = await realIndex();
    final themes = await ThemeRegistry.load(rootBundle);
    _theme = buildTheme(
      style: themes.byId(themes.defaultStyleId),
      mode: ThemeModeId.light,
      uiFont: UiFont.changa,
    );
    _en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets(
    'new-plan wizard advances through planning, schedule, and review',
    (tester) async {
      await tester.binding.setSurfaceSize(_previewSizes['phone']!);
      await tester.pumpWidget(_wizardApp());
      await tester.pumpAndSettle();

      expect(find.text(_en.khatmaStepPlan), findsNWidgets(2));
      expect(find.text(_en.khatmaNameLabel), findsOneWidget);

      await tester.tap(find.text(_en.continueLabel));
      await tester.pumpAndSettle();
      expect(find.text(_en.khatmaStepSchedule), findsWidgets);
      expect(find.text(_en.khatmaEndDateLabel), findsOneWidget);

      await tester.tap(find.text(_en.continueLabel));
      await tester.pumpAndSettle();
      expect(find.text(_en.khatmaStepReview), findsWidgets);
      expect(find.text(_en.khatmaStart), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('active-plan statistics switch between week, month, and year', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(_previewSizes['phone']!);
    final active = await _makeStatus(completed: false);
    await tester.pumpWidget(
      _statusApp(
        KhatmaScreen(selectedPlanId: active.khatmah.uuid),
        active: active,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.khatmaTabStats));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_en.khatmaStatsWeek));
    await tester.pumpAndSettle();
    expect(_firstGridItemCount(tester), 14);

    await tester.tap(find.text(_en.khatmaStatsMonth));
    await tester.pumpAndSettle();
    expect(_firstGridItemCount(tester), inInclusiveRange(35, 44));

    await tester.tap(find.text(_en.khatmaStatsYear));
    await tester.pumpAndSettle();
    expect(_firstGridItemCount(tester), inInclusiveRange(1, 12));
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed plan opens its read-only statistics from history', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(_previewSizes['phone']!);
    final completed = await _makeStatus(completed: true);
    final router = GoRouter(
      initialLocation: '/khatma',
      routes: [
        GoRoute(
          path: '/khatma',
          builder: (context, state) =>
              KhatmaScreen(selectedPlanId: state.uri.queryParameters['plan']),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_routerApp(router, completed: completed));
    await tester.pumpAndSettle();

    final planTitle = find.text(completed.row.title);
    await tester.ensureVisible(planTitle);
    await tester.tap(planTitle);
    await tester.pumpAndSettle();

    expect(find.text(_en.khatmaStatsWeek), findsOneWidget);
    expect(find.text(_en.khatmaStatsMonth), findsOneWidget);
    expect(find.text(_en.khatmaStatsYear), findsOneWidget);
    await tester.tap(find.text(_en.khatmaStatsYear));
    await tester.pumpAndSettle();
    expect(_firstGridItemCount(tester), inInclusiveRange(1, 12));
    expect(tester.takeException(), isNull);
  });

  for (final entry in _previewSizes.entries) {
    final previewEnabled =
        Platform.environment['RENDER_KHATMA_PREVIEWS'] == '1';
    testWidgets('render ${entry.key} Khatmah plan preview', (tester) async {
      final out = Directory('build/khatmah_previews')
        ..createSync(recursive: true);
      final planBoundary = GlobalKey();
      await _capturePreview(
        tester,
        out,
        '${entry.key}_plan.png',
        entry.value,
        _wizardApp(boundaryKey: planBoundary),
        planBoundary,
      );
    }, skip: !previewEnabled);

    testWidgets('render ${entry.key} active statistics previews', (
      tester,
    ) async {
      final out = Directory('build/khatmah_previews')
        ..createSync(recursive: true);
      final active = await _makeStatus(completed: false);
      final activeBoundary = GlobalKey();
      await _capturePreview(
        tester,
        out,
        '${entry.key}_active_month.png',
        entry.value,
        _statusApp(
          KhatmaScreen(selectedPlanId: active.khatmah.uuid),
          active: active,
          boundaryKey: activeBoundary,
        ),
        activeBoundary,
      );
      await tester.tap(find.text(_en.khatmaTabStats));
      await tester.pumpAndSettle();
      await _captureCurrent(
        tester,
        out,
        '${entry.key}_active_month.png',
        boundaryKey: activeBoundary,
      );
      for (final period in [
        (label: _en.khatmaStatsWeek, file: 'week'),
        (label: _en.khatmaStatsYear, file: 'year'),
      ]) {
        await tester.tap(find.text(period.label));
        await tester.pumpAndSettle();
        await _captureCurrent(
          tester,
          out,
          '${entry.key}_active_${period.file}.png',
          boundaryKey: activeBoundary,
        );
      }
    }, skip: !previewEnabled);

    testWidgets('render ${entry.key} completed statistics preview', (
      tester,
    ) async {
      final out = Directory('build/khatmah_previews')
        ..createSync(recursive: true);
      final completed = await _makeStatus(completed: true);
      final completedBoundary = GlobalKey();
      await _capturePreview(
        tester,
        out,
        '${entry.key}_completed_month.png',
        entry.value,
        _statusApp(
          KhatmaScreen(selectedPlanId: completed.khatmah.uuid),
          completed: completed,
          boundaryKey: completedBoundary,
        ),
        completedBoundary,
      );
    }, skip: !previewEnabled);
  }
}

Widget _wizardApp({Key? boundaryKey}) => ProviderScope(
  overrides: [
    quranIndexProvider.overrideWith((ref) async => _index),
    surahsProvider.overrideWith((ref) async => const []),
    editionProvider.overrideWithValue(MushafEdition.madina1441),
    editionPagesProvider.overrideWith(
      (ref, edition) async => _index.madina1441,
    ),
    todayProvider.overrideWith(_FixedToday.new),
  ],
  child: _materialApp(const NewKhatmaScreen(), boundaryKey: boundaryKey),
);

Widget _statusApp(
  Widget home, {
  KhatmaStatus? active,
  KhatmaStatus? completed,
  Key? boundaryKey,
}) => ProviderScope(
  overrides: [
    khatmaStatusesProvider.overrideWith(
      (ref) async => active == null ? [] : [active],
    ),
    completedKhatmasProvider.overrideWith(
      (ref) => Stream.value(completed == null ? [] : [completed.row]),
    ),
    completedKhatmaStatusProvider.overrideWith(
      (ref, uuid) async => completed?.khatmah.uuid == uuid ? completed : null,
    ),
  ],
  child: _materialApp(home, boundaryKey: boundaryKey),
);

Widget _materialApp(Widget home, {Key? boundaryKey}) => RepaintBoundary(
  key: boundaryKey,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: _theme,
    home: home,
  ),
);

Widget _routerApp(GoRouter router, {required KhatmaStatus completed}) =>
    ProviderScope(
      overrides: [
        khatmaStatusesProvider.overrideWith((ref) async => []),
        completedKhatmasProvider.overrideWith(
          (ref) => Stream.value([completed.row]),
        ),
        completedKhatmaStatusProvider.overrideWith(
          (ref, uuid) async =>
              completed.khatmah.uuid == uuid ? completed : null,
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: _theme,
        routerConfig: router,
      ),
    );

Future<KhatmaStatus> _makeStatus({required bool completed}) async {
  final now = DateTime.now();
  final today = Day.logical(now, 3);
  final uuid = completed ? 'completed-ui-fixture' : 'active-ui-fixture';
  final verses = completed
      ? IntervalSet.range(1, 1)
      : _index.madina1441.versesReadOn([1]);
  final db = UserDatabase(NativeDatabase.memory());
  try {
    final store = KhatmahStore(db);
    final book = KhatmahBook(
      store: store,
      index: _index,
      clock: () => now,
      newUuid: () => uuid,
    );
    await book.create(
      Khatmah(
        uuid: uuid,
        title: completed ? 'Completed sample plan' : 'Active sample plan',
        kind: completed ? KhatmahKind.partial : KhatmahKind.fullQuran,
        rangeStart: 1,
        rangeEnd: completed ? 1 : 6236,
        dailyWeight: completed ? 1 : 20,
        startDate: today,
        targetDate: today.add(29),
        isPrimary: true,
        createdAt: now,
      ),
    );
    final session = 'session-$uuid';
    await store.putSession(
      SessionRecord(
        uuid: session,
        start: now,
        end: now.add(const Duration(seconds: 90)),
        activeSeconds: 90,
        pages: 1,
        ranges: verses,
        edition: MushafEdition.madina1441.name,
      ),
    );
    await book.record(
      session: session,
      verses: verses,
      at: now.add(const Duration(seconds: 90)),
      edition: MushafEdition.madina1441.name,
    );
    return (await statusOf(
      book,
      today,
      MushafEdition.madina1441,
      _index.madina1441,
      khatmah: await store.byUuid(uuid),
    ))!;
  } finally {
    await db.close();
  }
}

Future<void> _capturePreview(
  WidgetTester tester,
  Directory out,
  String filename,
  Size size,
  Widget app,
  GlobalKey boundaryKey,
) async {
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  await _captureCurrent(tester, out, filename, boundaryKey: boundaryKey);
}

Future<void> _captureCurrent(
  WidgetTester tester,
  Directory out,
  String filename, {
  GlobalKey? boundaryKey,
}) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    boundaryKey == null
        ? find.byType(RepaintBoundary).first
        : find.byKey(boundaryKey),
  );
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  });
  if (bytes == null) throw StateError('Could not encode preview image.');
  File('${out.path}/$filename').writeAsBytesSync(bytes);
}

int _firstGridItemCount(WidgetTester tester) {
  final grids = tester.widgetList<GridView>(find.byType(GridView));
  return grids.first.childrenDelegate.estimatedChildCount!;
}

class _FixedToday extends TodayNotifier {
  @override
  Day build() => Day.logical(DateTime.now(), 3);
}
