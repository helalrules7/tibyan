import 'package:flutter_test/flutter_test.dart';
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
    expect(WidgetAction.search.route, '/search');
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
