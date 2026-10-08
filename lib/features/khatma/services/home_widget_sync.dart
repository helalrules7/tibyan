import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../domain/day.dart';

/// What the home screen widget shows on one day.
typedef WidgetDay = ({String portion, String reference, int page});

/// The widget's data: today's portion and a verse reference, written ahead
/// for the coming days so the widget stays right when the app is not
/// opened (it picks the entry of the current day).
class WidgetData {
  const WidgetData({
    required this.title,
    required this.edition,
    required this.days,
    required this.idle,
  });

  final String title;
  final String edition;
  final Map<Day, WidgetDay> days;

  /// Shown on days with nothing due, or with no khatma.
  final String idle;
}

/// The URI a tap on the widget opens: `tibyan://khatma?page=12&edition=…`.
/// `homeWidget` marks it as a widget tap for the plugin on iOS.
Uri widgetUri(int page, String edition) => Uri(
  scheme: 'tibyan',
  host: 'khatma',
  queryParameters: {'page': '$page', 'edition': edition, 'homeWidget': ''},
);

/// What the actions widget's buttons do. Each opens the app on [route]
/// (`tibyan://action/<name>`); `portion_done` does not open it: the widget
/// queues it and the app applies it the next time it runs (see
/// [HomeWidgetSync.takePending]).
enum WidgetAction {
  continueReading('continue', '/mushaf?entry=widget'),
  listen('listen', '/mushaf?listen=1&entry=widget'),
  search('search', '/search'),
  khatma('khatma', '/khatma'),
  hifz('hifz', '/hifz'),
  portionDone('portion_done', '/khatma');

  const WidgetAction(this.key, this.route);
  final String key;
  final String route;

  static WidgetAction? of(String key) =>
      WidgetAction.values.where((a) => a.key == key).firstOrNull;
}

/// The action a `tibyan://action/<name>` URI names, if it is one.
WidgetAction? widgetActionOf(Uri? uri) => uri == null || uri.host != 'action'
    ? null
    : WidgetAction.of(uri.pathSegments.firstOrNull ?? '');

/// The keys the platform widgets read, in one flat map: `title`, `idle`,
/// `edition`, `days`, and per day `portion_`, `ref_` and `uri_`.
Map<String, String> widgetEntries(WidgetData data) => {
  'title': data.title,
  'idle': data.idle,
  'edition': data.edition,
  // One entry per day: `portion_yyyy-MM-dd` and so on.
  'days': [for (final d in data.days.keys) d.key].join(','),
  for (final MapEntry(key: d, value: v) in data.days.entries) ...{
    'portion_${d.key}': v.portion,
    'ref_${d.key}': v.reference,
    'uri_${d.key}': widgetUri(v.page, data.edition).toString(),
  },
};

abstract interface class HomeWidgetSync {
  Future<void> write(WidgetData data);

  /// Actions queued by the widget while the app was not running (a button
  /// that must not open it), oldest first; the queue is emptied.
  Future<List<WidgetAction>> takePending();

  /// The URI of the widget tap that opened the app, if one did.
  Future<Uri?> launchUri();

  /// Widget taps while the app runs.
  Stream<Uri?> get taps;
}

class NoHomeWidget implements HomeWidgetSync {
  WidgetData? last;

  @override
  Future<void> write(WidgetData data) async => last = data;

  @override
  Future<Uri?> launchUri() async => null;

  @override
  Stream<Uri?> get taps => const Stream.empty();

  final List<WidgetAction> pending = [];

  @override
  Future<List<WidgetAction>> takePending() async {
    final out = [...pending];
    pending.clear();
    return out;
  }
}

/// The `home_widget` plugin: Android's `KhatmaWidgetProvider` and the iOS
/// `TibyanWidget` extension read these keys.
class PluginHomeWidgetSync implements HomeWidgetSync {
  /// iOS App Group shared with the widget extension (docs/HOME_WIDGET.md).
  static const appGroup = 'group.app.tibyan.tibyan';
  static const androidProvider = 'app.tibyan.tibyan.KhatmaWidgetProvider';
  static const iosKind = 'TibyanWidget';

  /// The actions widget: its own provider and extension.
  static const androidActionsProvider =
      'app.tibyan.tibyan.ActionsWidgetProvider';
  static const iosActionsKind = 'TibyanActionsWidget';

  @override
  Future<void> write(WidgetData data) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HomeWidget.setAppGroupId(appGroup);
      }
      for (final MapEntry(key: k, value: v) in widgetEntries(data).entries) {
        await HomeWidget.saveWidgetData<String>(k, v);
      }
      await HomeWidget.updateWidget(
        qualifiedAndroidName: androidProvider,
        iOSName: iosKind,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: androidActionsProvider,
        iOSName: iosActionsKind,
      );
    } catch (_) {
      // No widget support (or the iOS extension is not set up yet).
    }
  }

  @override
  Future<Uri?> launchUri() async {
    try {
      return await HomeWidget.initiallyLaunchedFromHomeWidget();
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<Uri?> get taps => HomeWidget.widgetClicked;

  @override
  Future<List<WidgetAction>> takePending() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HomeWidget.setAppGroupId(appGroup);
      }
      final raw = await HomeWidget.getWidgetData<String>(pendingKey);
      if (raw == null || raw.isEmpty) return const [];
      await HomeWidget.saveWidgetData<String>(pendingKey, '');
      return parsePending(raw);
    } catch (_) {
      return const [];
    }
  }
}

/// The key the widgets append queued actions to (comma separated).
const pendingKey = 'pending_actions';

List<WidgetAction> parsePending(String raw) => [
  for (final k in raw.split(',')) ?WidgetAction.of(k.trim()),
];

/// macOS: the system's WidgetKit widgets read the same keys from the App
/// Group, written through the app's own channel (`home_widget` has no
/// macOS support), and the app's `tibyan://` links arrive on it too.
class MacHomeWidgetSync implements HomeWidgetSync {
  MacHomeWidgetSync() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'link') {
        _links.add(Uri.tryParse(call.arguments as String? ?? ''));
      }
    });
  }

  static const _channel = MethodChannel('app.tibyan/widget');
  final _links = StreamController<Uri?>.broadcast();

  @override
  Future<void> write(WidgetData data) async {
    try {
      await _channel.invokeMethod<void>('save', widgetEntries(data));
    } catch (_) {
      // No widget extension in this build.
    }
  }

  @override
  Future<Uri?> launchUri() async {
    try {
      final link = await _channel.invokeMethod<String>('initialLink');
      return link == null ? null : Uri.tryParse(link);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<Uri?> get taps => _links.stream;

  @override
  Future<List<WidgetAction>> takePending() async {
    try {
      final raw = await _channel.invokeMethod<String>('takePending');
      return raw == null ? const [] : parsePending(raw);
    } catch (_) {
      return const [];
    }
  }
}
