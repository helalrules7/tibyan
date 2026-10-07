import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/router/app_router.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/features/khatma/domain/khatmah.dart';
import 'package:tibyan/features/khatma/khatma_providers.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/mushaf/presentation/navigation.dart';
import 'package:tibyan/features/khatma/domain/day.dart';
import 'package:tibyan/features/khatma/services/home_widget_sync.dart';

void main() {
  test('an action link names its action', () {
    expect(
      widgetActionOf(Uri.parse('tibyan://action/listen')),
      WidgetAction.listen,
    );
    expect(widgetActionOf(Uri.parse('tibyan://action/nope')), isNull);
    expect(widgetActionOf(Uri.parse('tibyan://khatma?page=3')), isNull);
    expect(widgetActionOf(null), isNull);
  });

  test('every action opens a route the router knows', () {
    final routes = {
      for (final a in WidgetAction.values) a: Uri.parse(a.route).path,
    };
    expect(routes[WidgetAction.listen], '/mushaf');
    expect(WidgetAction.listen.route, contains('listen=1'));
    expect(WidgetAction.continueReading.route, contains('entry=widget'));
    expect(WidgetAction.listen.route, contains('entry=widget'));
    expect(WidgetAction.search.route, '/search');
  });

  test('deep-link sources are attached to reader entries', () {
    expect(
      khatmaEntryOfLink(Uri.parse('tibyan://khatma?page=3&homeWidget')),
      EntryPoint.widget,
    );
    expect(
      khatmaEntryOfLink(Uri.parse('tibyan://khatma?page=3')),
      EntryPoint.notification,
    );
    expect(
      khatmaEntryOfLink(Uri.parse('tibyan://khatmah/plan/continue')),
      EntryPoint.khatmahContinue,
    );
    expect(
      khatmaEntryOfLink(Uri.parse('tibyan://reader?ayah=255&plan=plan')),
      EntryPoint.khatmahContinue,
    );
  });

  test('router readiness can be awaited without a launch-time delay', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ready = container.read(appRouterReadyProvider);
    final signal = ready.future;
    expect(ready.isCompleted, isFalse);

    markAppRouterReady(ready);
    await signal;
    markAppRouterReady(ready);

    expect(ready.isCompleted, isTrue);
  });

  test(
    'khatmat and individual khatma links retain their route target',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(khatmaServiceProvider);

      expect(await service.routeFor(Uri.parse('tibyan://khatmat')), '/khatma');
      expect(
        await service.routeFor(Uri.parse('tibyan://khatmah/plan-1')),
        '/khatma?plan=plan-1',
      );
    },
  );

  group('the old tibyan://khatma?page=&edition= link still works', () {
    late ProviderContainer container;
    late KhatmaService service;
    late String edition;
    setUp(() {
      container = ProviderContainer(
        overrides: [editionProvider.overrideWithValue(MushafEdition.shamarly)],
      );
      service = container.read(khatmaServiceProvider);
      edition = MushafEdition.shamarly.name;
    });
    tearDown(() => container.dispose());

    test('a reminder already scheduled opens its page', () async {
      final route = await service.routeFor(
        Uri.parse('tibyan://khatma?page=42&edition=$edition'),
      );
      final uri = Uri.parse(route);
      expect(uri.path, '/mushaf');
      expect(uri.queryParameters['page'], '42');
      expect(uri.queryParameters['entry'], 'notification');
      // Navigation turns the page; it selects no verse.
      expect(uri.queryParameters.containsKey('s'), isFalse);
    });

    test('a widget already on the home screen opens its page', () async {
      final route = await service.routeFor(widgetUri(7, edition));
      final uri = Uri.parse(route);
      expect(uri.queryParameters['page'], '7');
      expect(uri.queryParameters['entry'], 'widget');
    });

    test('without a page, or with a bad one, the khatmas', () async {
      expect(await service.routeFor(Uri.parse('tibyan://khatma')), '/khatma');
      expect(
        await service.routeFor(Uri.parse('tibyan://khatma?page=x')),
        '/khatma',
      );
      expect(
        await service.routeFor(Uri.parse('tibyan://khatmah/plan-1/oops')),
        '/khatma',
      );
      expect(await service.routeFor(Uri.parse('tibyan://khatmah')), '/khatma');
    });

    test('the widget actions host is a widget entry', () {
      expect(
        khatmaEntryOfLink(Uri.parse('tibyan://action/continue')),
        EntryPoint.widget,
      );
      expect(khatmaEntryOfLink(Uri.parse('tibyan://other')), EntryPoint.other);
    });
  });

  test('queued actions are read in order and unknown ones dropped', () {
    expect(parsePending('portion_done, bogus,search'), [
      WidgetAction.portionDone,
      WidgetAction.search,
    ]);
    expect(parsePending(''), isEmpty);
  });

  test('widget entries: shared keys and one set per day', () {
    final day = Day.parse('2026-10-04');
    final entries = widgetEntries(
      WidgetData(
        title: 'ختمة',
        edition: 'madina1441',
        idle: 'تم',
        days: {day: (portion: 'ص ٣', reference: 'البقرة ٥', page: 3)},
      ),
    );
    expect(entries['title'], 'ختمة');
    expect(entries['days'], '2026-10-04');
    expect(entries['portion_2026-10-04'], 'ص ٣');
    expect(entries['uri_2026-10-04'], contains('page=3'));
  });
}
