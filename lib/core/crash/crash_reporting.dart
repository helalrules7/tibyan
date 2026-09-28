import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Crash reporting is off by default. It starts only when the user opts
/// in AND a DSN was provided at build time
/// (`--dart-define-from-file=.env` with `SENTRY_DSN=...`).
///
/// No personal data is sent: no user, no IP, no screenshots, no
/// breadcrumbs, no request data. View hierarchy capture is off by default.
class CrashReporting {
  static const _dsn = String.fromEnvironment('SENTRY_DSN');
  static bool _running = false;

  static bool get isAvailable => _dsn.isNotEmpty;

  static Future<void> apply({required bool optIn}) async {
    if (!isAvailable) return;
    if (optIn && !_running) {
      await SentryFlutter.init((options) {
        options.dsn = _dsn;
        options.sendDefaultPii = false;
        options.attachScreenshot = false;
        options.enableAutoPerformanceTracing = false;
        options.tracesSampleRate = 0;
        options.beforeSend = (event, hint) {
          event.user = null;
          event.breadcrumbs = const [];
          event.request = null;
          return event;
        };
      });
      _running = true;
    } else if (!optIn && _running) {
      await Sentry.close();
      _running = false;
    }
  }

  static void debugLog(Object message) {
    if (kDebugMode) debugPrint('[crash] $message');
  }
}
