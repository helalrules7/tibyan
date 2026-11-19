import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps the app running through a gap in the recitation where nothing
/// plays: the silence between repetitions (a paused player and a timer)
/// and the next surah's file loading. In the background iOS suspends an
/// app whose audio stopped, so the timer or the load that would start the
/// sound again never ran and the recitation died there. On iOS each gap
/// runs inside a background task (ios/Runner/AppDelegate.swift,
/// KeepAliveChannel; iOS allows about 30 s, the longest silence is 20 s).
/// Elsewhere, or when the channel fails, the work simply runs.
class RecitationKeepAlive {
  RecitationKeepAlive({MethodChannel? channel, bool? enabled})
    : _channel = channel ?? const MethodChannel('app.tibyan/keep_alive'),
      _enabled =
          enabled ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

  final MethodChannel _channel;
  final bool _enabled;

  /// Runs [work], the app kept running until it ends.
  Future<T> during<T>(Future<T> Function() work) async {
    final id = await _begin();
    try {
      return await work();
    } finally {
      if (id != null) unawaited(_end(id));
    }
  }

  Future<int?> _begin() async {
    if (!_enabled) return null;
    try {
      return await _channel.invokeMethod<int>('begin');
    } catch (_) {
      return null;
    }
  }

  Future<void> _end(int id) async {
    try {
      await _channel.invokeMethod<void>('end', id);
    } catch (_) {
      // Ending a task that already expired is harmless.
    }
  }
}

final keepAliveProvider = Provider<RecitationKeepAlive>(
  (ref) => RecitationKeepAlive(),
);
