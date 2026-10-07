import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/settings/settings_controller.dart';
import '../domain/alignment_engine.dart';
import '../domain/tasmee_session_request.dart';
import '../domain/word_match.dart';

/// The last session, for «continue»: the verses it covered and how far the
/// reader got. Verses only (the same in every edition); no audio, no words.
class LastTasmee {
  const LastTasmee({
    required this.fromSurah,
    required this.fromAyah,
    required this.toSurah,
    required this.toAyah,
    required this.reachedSurah,
    required this.reachedAyah,
    required this.accuracy,
  });

  final int fromSurah;
  final int fromAyah;
  final int toSurah;
  final int toAyah;

  /// The last verse the reader reached.
  final int reachedSurah;
  final int reachedAyah;

  /// Overall accuracy in percent; null when nothing could be judged.
  final int? accuracy;

  /// The reader reached the end of the range.
  bool get completed => reachedSurah == toSurah && reachedAyah == toAyah;

  Map<String, Object?> toJson() => {
    'from': [fromSurah, fromAyah],
    'to': [toSurah, toAyah],
    'reached': [reachedSurah, reachedAyah],
    'accuracy': accuracy,
  };

  static LastTasmee? fromJson(Object? json) {
    if (json is! Map) return null;
    List<int>? pair(Object? v) =>
        v is List && v.length == 2 && v.every((e) => e is int)
        ? v.cast<int>()
        : null;
    final from = pair(json['from']);
    final to = pair(json['to']);
    final reached = pair(json['reached']);
    final accuracy = json['accuracy'];
    if (from == null || to == null || reached == null) return null;
    if (accuracy != null && accuracy is! int) return null;
    return LastTasmee(
      fromSurah: from[0],
      fromAyah: from[1],
      toSurah: to[0],
      toAyah: to[1],
      reachedSurah: reached[0],
      reachedAyah: reached[1],
      accuracy: accuracy as int?,
    );
  }
}

/// The reader's choices for the audio tasmee (Settings › Tasmee).
class TasmeeSettings {
  const TasmeeSettings({
    this.mode = TasmeeMode.continuous,
    this.onError = ErrorBehavior.continueReading,
    this.toastSeconds = 3,
    this.vibration = true,
    this.strictness = MatchStrictness.medium,
    this.firstUseSeen = false,
    this.last,
  });

  final TasmeeMode mode;
  final ErrorBehavior onError;

  /// How long a verse's result stays in the panel, 1 to 10 seconds.
  final int toastSeconds;
  final bool vibration;
  final MatchStrictness strictness;

  /// The notice «it checks your memorisation, not your tajweed» was read.
  final bool firstUseSeen;
  final LastTasmee? last;

  static const minToast = 1;
  static const maxToast = 10;
}

final tasmeeSettingsProvider =
    NotifierProvider<TasmeeSettingsController, TasmeeSettings>(
      TasmeeSettingsController.new,
    );

class TasmeeSettingsController extends Notifier<TasmeeSettings> {
  static const _kMode = 'tasmee.mode';
  static const _kOnError = 'tasmee.onError';
  static const _kToast = 'tasmee.toastSeconds';
  static const _kVibration = 'tasmee.vibration';
  static const _kStrictness = 'tasmee.strictness';
  static const _kFirstUse = 'tasmee.firstUseSeen';
  static const _kLast = 'tasmee.last';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  TasmeeSettings build() {
    final p = ref.watch(sharedPreferencesProvider);
    T byName<T extends Enum>(List<T> values, String key, T fallback) =>
        values.asNameMap()[p.getString(key)] ?? fallback;
    LastTasmee? last;
    try {
      final raw = p.getString(_kLast);
      if (raw != null) last = LastTasmee.fromJson(jsonDecode(raw));
    } on FormatException {
      last = null;
    }
    return TasmeeSettings(
      mode: byName(TasmeeMode.values, _kMode, TasmeeMode.continuous),
      onError: byName(
        ErrorBehavior.values,
        _kOnError,
        ErrorBehavior.continueReading,
      ),
      toastSeconds: (p.getInt(_kToast) ?? 3).clamp(
        TasmeeSettings.minToast,
        TasmeeSettings.maxToast,
      ),
      vibration: p.getBool(_kVibration) ?? true,
      strictness: byName(
        MatchStrictness.values,
        _kStrictness,
        MatchStrictness.medium,
      ),
      firstUseSeen: p.getBool(_kFirstUse) ?? false,
      last: last,
    );
  }

  TasmeeSettings _copy({
    TasmeeMode? mode,
    ErrorBehavior? onError,
    int? toastSeconds,
    bool? vibration,
    MatchStrictness? strictness,
    bool? firstUseSeen,
    LastTasmee? Function()? last,
  }) => TasmeeSettings(
    mode: mode ?? state.mode,
    onError: onError ?? state.onError,
    toastSeconds: toastSeconds ?? state.toastSeconds,
    vibration: vibration ?? state.vibration,
    strictness: strictness ?? state.strictness,
    firstUseSeen: firstUseSeen ?? state.firstUseSeen,
    last: last == null ? state.last : last(),
  );

  Future<void> setMode(TasmeeMode v) async {
    state = _copy(mode: v);
    await _prefs.setString(_kMode, v.name);
  }

  Future<void> setOnError(ErrorBehavior v) async {
    state = _copy(onError: v);
    await _prefs.setString(_kOnError, v.name);
  }

  Future<void> setToastSeconds(int v) async {
    final s = v.clamp(TasmeeSettings.minToast, TasmeeSettings.maxToast);
    state = _copy(toastSeconds: s);
    await _prefs.setInt(_kToast, s);
  }

  Future<void> setVibration(bool v) async {
    state = _copy(vibration: v);
    await _prefs.setBool(_kVibration, v);
  }

  Future<void> setStrictness(MatchStrictness v) async {
    state = _copy(strictness: v);
    await _prefs.setString(_kStrictness, v.name);
  }

  Future<void> setFirstUseSeen() async {
    state = _copy(firstUseSeen: true);
    await _prefs.setBool(_kFirstUse, true);
  }

  Future<void> setLast(LastTasmee v) async {
    state = _copy(last: () => v);
    await _prefs.setString(_kLast, jsonEncode(v.toJson()));
  }

  /// «Clear the history»: what the app keeps of past sessions.
  Future<void> clearHistory() async {
    state = _copy(last: () => null);
    await _prefs.remove(_kLast);
  }
}
