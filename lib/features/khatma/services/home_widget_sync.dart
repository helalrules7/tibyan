import 'package:flutter/foundation.dart';
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

abstract interface class HomeWidgetSync {
  Future<void> write(WidgetData data);

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
}

/// The `home_widget` plugin: Android's `KhatmaWidgetProvider` and the iOS
/// `TibyanWidget` extension read these keys.
class PluginHomeWidgetSync implements HomeWidgetSync {
  /// iOS App Group shared with the widget extension (docs/HOME_WIDGET.md).
  static const appGroup = 'group.app.tibyan.tibyan';
  static const androidProvider = 'app.tibyan.tibyan.KhatmaWidgetProvider';
  static const iosKind = 'TibyanWidget';

  @override
  Future<void> write(WidgetData data) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HomeWidget.setAppGroupId(appGroup);
      }
      await HomeWidget.saveWidgetData<String>('title', data.title);
      await HomeWidget.saveWidgetData<String>('idle', data.idle);
      await HomeWidget.saveWidgetData<String>('edition', data.edition);
      // One entry per day: `portion_yyyy-MM-dd` and so on.
      await HomeWidget.saveWidgetData<String>(
        'days',
        [for (final d in data.days.keys) d.key].join(','),
      );
      for (final MapEntry(key: d, value: v) in data.days.entries) {
        await HomeWidget.saveWidgetData<String>('portion_${d.key}', v.portion);
        await HomeWidget.saveWidgetData<String>('ref_${d.key}', v.reference);
        await HomeWidget.saveWidgetData<String>(
          'uri_${d.key}',
          widgetUri(v.page, data.edition).toString(),
        );
      }
      await HomeWidget.updateWidget(
        qualifiedAndroidName: androidProvider,
        iOSName: iosKind,
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
}
