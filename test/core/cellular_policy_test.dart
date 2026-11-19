import 'package:background_downloader/background_downloader.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/downloads/cellular_policy.dart';

TaskRecord _rec(TaskStatus s, double progress, int size) => TaskRecord(
  DownloadTask(url: 'https://example.org/x', taskId: '$s$progress$size'),
  s,
  progress,
  size,
);

void main() {
  test('Wi‑Fi or Ethernet wins over mobile data', () {
    expect(
      netKindOf([ConnectivityResult.mobile, ConnectivityResult.wifi]),
      NetKind.wifi,
    );
    expect(netKindOf([ConnectivityResult.ethernet]), NetKind.wifi);
    expect(netKindOf([ConnectivityResult.mobile]), NetKind.cellular);
    expect(netKindOf([ConnectivityResult.none]), NetKind.none);
    expect(netKindOf([]), NetKind.none);
    expect(netKindOf([ConnectivityResult.vpn]), NetKind.other);
  });

  test('downloads wait for Wi‑Fi unless mobile data is allowed', () {
    expect(wifiOnly(alwaysAllowed: false, allowedForNow: false), isTrue);
    expect(wifiOnly(alwaysAllowed: true, allowedForNow: false), isFalse);
    expect(wifiOnly(alwaysAllowed: false, allowedForNow: true), isFalse);
  });

  test('pending counts queued, running and retrying, not paused', () {
    final p = pendingOf([
      _rec(TaskStatus.running, 0.5, 2000),
      _rec(TaskStatus.enqueued, 0, -1),
      _rec(TaskStatus.waitingToRetry, 0, 1000),
      _rec(TaskStatus.paused, 0, 9000),
      _rec(TaskStatus.complete, 1, 9000),
    ]);
    expect(p.count, 3);
    expect(p.bytes, 2000);
  });

  group('banner', () {
    const cell = CellularState(net: NetKind.cellular);
    bool show(CellularState s, {bool always = false, int pending = 1}) =>
        showCellularBanner(
          applies: true,
          state: s,
          alwaysAllowed: always,
          pending: pending,
        );

    test('shows on mobile data with downloads waiting', () {
      expect(show(cell), isTrue);
    });
    test('hidden on Wi‑Fi, with nothing waiting, or once answered', () {
      expect(show(const CellularState(net: NetKind.wifi)), isFalse);
      expect(show(cell, pending: 0), isFalse);
      expect(show(cell, always: true), isFalse);
      expect(show(cell.copyWith(allowedForNow: true)), isFalse);
      expect(show(cell.copyWith(dismissed: true)), isFalse);
    });
    test('never on desktops', () {
      expect(
        showCellularBanner(
          applies: false,
          state: cell,
          alwaysAllowed: false,
          pending: 1,
        ),
        isFalse,
      );
    });
  });
}
