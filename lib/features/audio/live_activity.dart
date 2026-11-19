import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The Live Activity's buttons (iOS 17+), as the channel names them.
enum RecitationCommand { toggle, previous, next }

/// What the recitation's Live Activity shows: names and numbers only (the
/// reciter, the surah, the verse number and the surah's verse count for
/// the progress bar), never the Quran's text.
@immutable
class RecitationActivityContent {
  const RecitationActivityContent({
    required this.reciter,
    required this.surah,
    required this.verse,
    required this.playing,
    required this.playLabel,
    required this.pauseLabel,
    required this.rtl,
    this.ayah = 0,
    this.ayahCount = 0,
    this.previousLabel = '',
    this.nextLabel = '',
  });

  final String reciter;
  final String surah;
  final String verse;
  final bool playing;
  final String playLabel;
  final String pauseLabel;
  final bool rtl;

  /// The verse being recited (0: not known, no progress bar or verse
  /// buttons) and the surah's verse count, from the app's surah data.
  final int ayah;
  final int ayahCount;

  /// Accessibility labels of the previous / next verse buttons.
  final String previousLabel;
  final String nextLabel;

  Map<String, Object> toMap() => {
    'reciter': reciter,
    'surah': surah,
    'verse': verse,
    'playing': playing,
    'playLabel': playLabel,
    'pauseLabel': pauseLabel,
    'rtl': rtl,
    'ayah': ayah,
    'ayahCount': ayahCount,
    'previousLabel': previousLabel,
    'nextLabel': nextLabel,
  };

  @override
  bool operator ==(Object other) =>
      other is RecitationActivityContent &&
      other.reciter == reciter &&
      other.surah == surah &&
      other.verse == verse &&
      other.playing == playing &&
      other.playLabel == playLabel &&
      other.pauseLabel == pauseLabel &&
      other.rtl == rtl &&
      other.ayah == ayah &&
      other.ayahCount == ayahCount &&
      other.previousLabel == previousLabel &&
      other.nextLabel == nextLabel;

  @override
  int get hashCode => Object.hash(
    reciter,
    surah,
    verse,
    playing,
    playLabel,
    pauseLabel,
    rtl,
    ayah,
    ayahCount,
    previousLabel,
    nextLabel,
  );
}

/// The platform side of the Live Activity.
abstract interface class RecitationActivityHost {
  Future<void> update(RecitationActivityContent content);
  Future<void> end();
  set onCommand(void Function(RecitationCommand command)? handler);
}

/// iOS (16.2+, ios/Runner/LiveActivityChannel.swift) through
/// `app.tibyan/live_activity`. A failure is ignored: the Live Activity is
/// an extra, the recitation never depends on it.
class ChannelRecitationActivity implements RecitationActivityHost {
  ChannelRecitationActivity({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('app.tibyan/live_activity') {
    _channel.setMethodCallHandler((call) async {
      final command = RecitationCommand.values
          .where((c) => c.name == call.method)
          .firstOrNull;
      if (command != null) _onCommand?.call(command);
      return null;
    });
  }

  final MethodChannel _channel;
  void Function(RecitationCommand command)? _onCommand;

  @override
  set onCommand(void Function(RecitationCommand command)? handler) =>
      _onCommand = handler;

  @override
  Future<void> update(RecitationActivityContent content) async {
    try {
      await _channel.invokeMethod<bool>('update', content.toMap());
    } catch (_) {
      // Live Activities are optional (disabled or unsupported OS).
    }
  }

  @override
  Future<void> end() async {
    try {
      await _channel.invokeMethod<bool>('end');
    } catch (_) {
      // Live Activities are optional (disabled or unsupported OS).
    }
  }
}

/// Keeps the Live Activity in step with the recitation: shown while the
/// player is active, updated only when what it shows changes (the verse,
/// play/pause), ended when the player goes. Calls are sent one after the
/// other, never piled up.
class RecitationActivitySync {
  RecitationActivitySync(this._host);

  final RecitationActivityHost _host;
  RecitationActivityContent? _shown;
  Future<void> _last = Future.value();

  /// Ends one left over from an earlier run (the app was closed).
  Future<void> start() => _enqueue(_host.end);

  /// [content] null: the recitation has stopped.
  Future<void> show(RecitationActivityContent? content) {
    if (content == _shown) return _last;
    final had = _shown != null;
    _shown = content;
    if (content == null) return had ? _enqueue(_host.end) : _last;
    return _enqueue(() => _host.update(content));
  }

  Future<void> _enqueue(Future<void> Function() call) =>
      _last = _last.then((_) => call()).catchError((_) {});

  /// Off: during a recitation iOS already shows its own Now Playing card on
  /// the lock screen (from the media session), and a Live Activity beside it
  /// showed the same recitation twice. [start] still ends one left over
  /// from an older build.
  static const bool showsRecitation = false;

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}
