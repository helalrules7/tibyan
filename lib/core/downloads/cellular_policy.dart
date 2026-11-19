import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_controller.dart';
import 'background_downloads.dart';

/// The connection the phone is on, as far as downloads care.
enum NetKind { wifi, cellular, none, other }

/// Wi‑Fi or Ethernet wins over mobile data when both are up (the system
/// sends traffic over the unmetered one).
NetKind netKindOf(List<ConnectivityResult> results) {
  if (results.contains(ConnectivityResult.wifi) ||
      results.contains(ConnectivityResult.ethernet)) {
    return NetKind.wifi;
  }
  if (results.contains(ConnectivityResult.mobile)) return NetKind.cellular;
  if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
    return NetKind.none;
  }
  return NetKind.other;
}

/// Phones only: desktops have no mobile data to save.
bool get cellularPolicyApplies =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Downloads wait for Wi‑Fi unless the reader allowed mobile data, always
/// (the setting) or for now (the banner, until Wi‑Fi is back).
bool wifiOnly({required bool alwaysAllowed, required bool allowedForNow}) =>
    !alwaysAllowed && !allowedForNow;

/// A download that is still to run: queued, running or retrying. One the
/// reader paused stays paused and is not counted.
bool isPending(TaskStatus s) =>
    s == TaskStatus.enqueued ||
    s == TaskStatus.running ||
    s == TaskStatus.waitingToRetry;

/// The bytes still to fetch of [records] (only those whose size is known),
/// and how many are pending.
({int count, int bytes}) pendingOf(Iterable<TaskRecord> records) {
  var count = 0;
  var bytes = 0;
  for (final r in records) {
    if (!isPending(r.status)) continue;
    count++;
    if (r.expectedFileSize > 0) {
      final done = r.progress.clamp(0.0, 1.0);
      bytes += (r.expectedFileSize * (1 - done)).round();
    }
  }
  return (count: count, bytes: bytes);
}

@immutable
class CellularState {
  const CellularState({
    this.net = NetKind.other,
    this.allowedForNow = false,
    this.dismissed = false,
  });

  final NetKind net;

  /// The reader chose «متابعة عبر البيانات» on this mobile connection.
  final bool allowedForNow;

  /// The reader chose «انتظار Wi‑Fi»: the banner stays away until the
  /// next time the phone goes from Wi‑Fi to mobile data.
  final bool dismissed;

  CellularState copyWith({
    NetKind? net,
    bool? allowedForNow,
    bool? dismissed,
  }) => CellularState(
    net: net ?? this.net,
    allowedForNow: allowedForNow ?? this.allowedForNow,
    dismissed: dismissed ?? this.dismissed,
  );
}

/// Whether the «downloads paused» banner shows.
bool showCellularBanner({
  required bool applies,
  required CellularState state,
  required bool alwaysAllowed,
  required int pending,
}) =>
    applies &&
    state.net == NetKind.cellular &&
    wifiOnly(
      alwaysAllowed: alwaysAllowed,
      allowedForNow: state.allowedForNow,
    ) &&
    !state.dismissed &&
    pending > 0;

/// Holds downloads on mobile data, like WhatsApp and Google Drive: every
/// background download (recitations, mushaf pages, books, models) waits
/// for Wi‑Fi, and the reader is asked before mobile data is used. Playing
/// a recitation without downloading it is not held.
class CellularPolicy extends Notifier<CellularState> {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  RequireWiFi? _applied;

  @override
  CellularState build() {
    if (!cellularPolicyApplies) return const CellularState();
    final connectivity = Connectivity();
    _sub = connectivity.onConnectivityChanged.listen(_onNet);
    ref.onDispose(() => _sub?.cancel());
    unawaited(connectivity.checkConnectivity().then(_onNet, onError: (_) {}));
    ref.listen(
      settingsProvider.select((s) => s.cellularDownloads),
      (_, _) => _apply(),
    );
    scheduleMicrotask(_apply);
    return const CellularState();
  }

  void _onNet(List<ConnectivityResult> results) {
    final net = netKindOf(results);
    if (net == state.net) return;
    // Back on Wi‑Fi: the next mobile connection asks again.
    state = net == NetKind.cellular
        ? state.copyWith(net: net)
        : CellularState(net: net);
    _apply();
  }

  /// The reader allowed mobile data until Wi‑Fi is back.
  void allowForNow() {
    state = state.copyWith(allowedForNow: true);
    _apply();
  }

  /// The reader chose to wait for Wi‑Fi.
  void dismiss() => state = state.copyWith(dismissed: true);

  Future<void> _apply() async {
    if (!cellularPolicyApplies) return;
    final only = wifiOnly(
      alwaysAllowed: ref.read(settingsProvider).cellularDownloads,
      allowedForNow: state.allowedForNow,
    );
    final want = only ? RequireWiFi.forAllTasks : RequireWiFi.forNoTasks;
    if (want == _applied) return;
    _applied = want;
    try {
      // Queued and running tasks are rescheduled under the new rule.
      await ref.read(backgroundDownloadsProvider).dl.requireWiFi(want);
    } catch (_) {
      _applied = null;
    }
  }
}

final cellularPolicyProvider = NotifierProvider<CellularPolicy, CellularState>(
  CellularPolicy.new,
);
