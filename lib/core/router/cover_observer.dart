import 'package:flutter/widgets.dart';

/// Tells a screen when another full screen covers it and when it is back
/// on top: the reading tracker stops while the tafsir, the index or the
/// continuous view is pushed over the mushaf. Dialogs and sheets
/// ([PopupRoute]s) do not cover it.
class CoverObserver extends NavigatorObserver {
  final _subs =
      <
        Route<dynamic>,
        ({Set<Route<dynamic>> above, void Function(bool) onChange})
      >{};

  /// [onChange] gets true when a screen is pushed over [route], and false
  /// when the last one is gone.
  void subscribe(Route<dynamic> route, void Function(bool covered) onChange) {
    _subs[route] = (above: <Route<dynamic>>{}, onChange: onChange);
  }

  void unsubscribe(Route<dynamic> route) => _subs.remove(route);

  bool _covers(Route<dynamic>? r) => r != null && r is! PopupRoute;

  void _cover(Route<dynamic> route) {
    if (!_covers(route)) return;
    for (final MapEntry(key: owner, value: s) in _subs.entries) {
      if (owner == route) continue;
      if (s.above.add(route) && s.above.length == 1) s.onChange(true);
    }
  }

  void _uncover(Route<dynamic> route) {
    _subs.remove(route);
    for (final s in _subs.values) {
      if (s.above.remove(route) && s.above.isEmpty) s.onChange(false);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _cover(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _uncover(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _uncover(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _cover(newRoute);
    if (oldRoute != null) _uncover(oldRoute);
  }
}

/// The app router's: one for the root navigator.
final coverObserver = CoverObserver();
