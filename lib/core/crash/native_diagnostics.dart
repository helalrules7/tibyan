import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// The system's own crash and hang reports for this app (iOS MetricKit,
/// kept by ios/Runner/AppDelegate.swift, DiagnosticsChannel). iOS hands
/// them over on a later launch, including crashes Sentry could not see: a
/// crash before Dart started, or while the app was suspended in the
/// background. They hold the app's stack, the OS and device model, never
/// anything about the reader.
///
/// They are taken off the device at each launch, and sent to our crash
/// server only when [send] (the reader agreed to crash reports and the
/// reporter runs); otherwise they are dropped unread.
Future<void> forwardNativeDiagnostics({
  required bool send,
  Future<List<String>> Function()? take,
  Future<void> Function(String json)? capture,
}) async {
  if (take == null && (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS)) {
    return;
  }
  final List<String> payloads;
  try {
    payloads = await (take ?? _take)();
  } catch (_) {
    return;
  }
  if (!send) return;
  for (final json in payloads) {
    try {
      await (capture ?? _capture)(json);
    } catch (_) {
      // Reporting is best effort; a failed send must not crash the reporter.
    }
  }
}

const _channel = MethodChannel('app.tibyan/diagnostics');

Future<List<String>> _take() async =>
    (await _channel.invokeListMethod<String>('take')) ?? const [];

Future<void> _capture(String json) => Sentry.captureEvent(
  SentryEvent(
    level: SentryLevel.fatal,
    message: SentryMessage('MetricKit diagnostic (${diagnosticKinds(json)})'),
    tags: const {'source': 'metrickit'},
  ),
  withScope: (scope) => scope.addAttachment(
    SentryAttachment.fromUint8List(
      utf8.encode(json),
      'metrickit.json',
      contentType: 'application/json',
    ),
  ),
);

/// The kinds of report in a payload, e.g. `crash` or `crash, hang`.
@visibleForTesting
String diagnosticKinds(String json) {
  try {
    final map = jsonDecode(json) as Map<String, dynamic>;
    const names = {
      'crashDiagnostics': 'crash',
      'hangDiagnostics': 'hang',
      'cpuExceptionDiagnostics': 'cpu',
      'diskWriteExceptionDiagnostics': 'disk',
      'appLaunchDiagnostics': 'launch',
    };
    final kinds = [
      for (final e in names.entries)
        if ((map[e.key] as List?)?.isNotEmpty ?? false) e.value,
    ];
    return kinds.isEmpty ? 'other' : kinds.join(', ');
  } catch (_) {
    return 'unreadable';
  }
}
