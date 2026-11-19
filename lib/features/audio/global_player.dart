import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'player_bar.dart';
import 'recitation.dart';

/// The recitation's controls on every screen while it plays.
///
/// The mushaf draws its own player (in the reader's chosen shape, and out
/// of the way of its tools), so it is left out; the first-launch steps too.
/// Elsewhere the bar sits at the foot of the window, and the screen below
/// is told the bottom is taken, so its own SafeArea keeps content clear.
class GlobalPlayer extends ConsumerStatefulWidget {
  const GlobalPlayer({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<GlobalPlayer> createState() => _GlobalPlayerState();
}

class _GlobalPlayerState extends ConsumerState<GlobalPlayer> {
  /// The bar and the gap around it.
  static const double _height = 76;

  // The location is read from the route information, which changes after
  // a navigation (the delegate's own notices come during a build).
  late String _path = _read();

  // Above the navigator there is no overlay for the buttons' tooltips: the
  // bar brings its own, made once.
  late final OverlayEntry _entry = OverlayEntry(
    builder: (context) {
      final bottom = MediaQuery.paddingOf(context).bottom;
      return Positioned(
        left: 12,
        right: 12,
        bottom: 12 + bottom,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: PlayerBar(
              sheetContext: () =>
                  widget.router.routerDelegate.navigatorKey.currentContext,
            ),
          ),
        ),
      );
    },
  );

  /// The top screen's path. The route information alone goes stale after
  /// a pushed screen is popped (it still names the popped one), which
  /// showed this bar over the mushaf's own: two players.
  String _read() {
    try {
      return widget.router.state.uri.path;
    } catch (_) {
      return widget.router.routeInformationProvider.value.uri.path;
    }
  }

  void _changed() {
    final path = _read();
    if (path == _path || !mounted) return;
    // After this frame: never mark this widget dirty while one builds. The
    // latest location then (two navigations may come in one frame), and a
    // frame asked for, since a post-frame callback does not ask for one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _path = _read());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void initState() {
    super.initState();
    widget.router.routeInformationProvider.addListener(_changed);
    widget.router.routerDelegate.addListener(_changed);
  }

  @override
  void dispose() {
    widget.router.routeInformationProvider.removeListener(_changed);
    widget.router.routerDelegate.removeListener(_changed);
    super.dispose();
  }

  static bool _hidden(String path) =>
      path == '/mushaf' || path == '/splash' || path.startsWith('/onboarding');

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(recitationProvider.select((s) => s.active));
    final show = active && !_hidden(_path);
    final mq = MediaQuery.of(context);
    // The same tree whether the bar shows or not, so the app below keeps
    // its state when listening starts or stops.
    return Stack(
      children: [
        MediaQuery(
          data: show
              ? mq.copyWith(
                  padding: mq.padding.copyWith(
                    bottom: mq.padding.bottom + _height,
                  ),
                  viewPadding: mq.viewPadding.copyWith(
                    bottom: mq.viewPadding.bottom + _height,
                  ),
                )
              : mq,
          child: widget.child,
        ),
        // Always in the tree (hidden when not needed): the overlay and its
        // one entry live as long as the app. It covers the whole window
        // and paints nothing but the bar, so the bar's tooltips show above
        // every control and taps elsewhere reach the screen below.
        Positioned.fill(
          child: Offstage(
            offstage: !show,
            child: Overlay(initialEntries: [_entry]),
          ),
        ),
      ],
    );
  }
}
