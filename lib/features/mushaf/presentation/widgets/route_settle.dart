import 'dart:async';

import 'package:flutter/widgets.dart';

/// Marks a page built beside the one shown (the pager's neighbours), whose
/// drawing can wait until the screen's route transition ends: baking the
/// page shown and its two neighbours during the entrance made the
/// transition's frames late (index jump, home «متابعة القراءة»).
class PageNeighbourScope extends InheritedWidget {
  const PageNeighbourScope({
    super.key,
    required this.neighbour,
    required super.child,
  });

  final bool neighbour;

  /// Whether [context] is in a neighbour page. Read without a dependency:
  /// it only matters when a page starts drawing.
  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PageNeighbourScope>()?.neighbour ??
      false;

  @override
  bool updateShouldNotify(PageNeighbourScope old) => false;
}

/// Completes once the route holding [context] is neither entering nor
/// being uncovered (a route above it popping); at once when it is still.
/// Listens to the animations' status only (no timer): a route animation
/// always ends, by completing or by being dismissed.
Future<void> routeSettled(BuildContext context) {
  if (!context.mounted) return Future.value();
  final route = ModalRoute.of(context);
  final busy = [
    route?.animation,
    route?.secondaryAnimation,
  ].whereType<Animation<double>>().where((a) => a.isAnimating).toList();
  if (busy.isEmpty) return Future.value();
  final done = Completer<void>();
  var left = busy.length;
  for (final a in busy) {
    void listen(AnimationStatus _) {
      if (a.isAnimating) return;
      a.removeStatusListener(listen);
      if (--left == 0 && !done.isCompleted) done.complete();
    }

    a.addStatusListener(listen);
  }
  return done.future;
}

/// [routeSettled] for a page marked by [PageNeighbourScope]; at once for
/// the page shown.
Future<void> neighbourSettled(BuildContext context) =>
    !debugNoNeighbourDefer && PageNeighbourScope.of(context)
    ? routeSettled(context)
    : Future.value();

/// The measuring harness's switch to draw neighbours at once (the old
/// way), to time both in one run.
@visibleForTesting
bool debugNoNeighbourDefer = false;
