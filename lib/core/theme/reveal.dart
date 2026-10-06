import 'package:flutter/widgets.dart';

/// Whether the platform asks for less motion: animations turned off, or a
/// screen reader or switch access in use.
bool reduceMotion(BuildContext context) =>
    (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
    (MediaQuery.maybeAccessibleNavigationOf(context) ?? false);

/// Shows and hides [child] with a short fade and a small slide from
/// [from] (a fraction of its own size), as the reading screen's bars come
/// and go on a tap. With less motion asked for ([reduceMotion]) it appears
/// and disappears at once.
///
/// [child] may be null once hidden: the last one shown stays on screen,
/// untouchable and silent, until it has faded out; then nothing is left.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.visible,
    required this.child,
    this.from = const Offset(0, 0.25),
  });

  static const duration = Duration(milliseconds: 200);

  final bool visible;
  final Widget? child;
  final Offset from;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: Reveal.duration,
    value: widget.visible ? 1 : 0,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );
  Widget? _last;

  @override
  void didUpdateWidget(Reveal old) {
    super.didUpdateWidget(old);
    if (widget.visible == old.visible) return;
    if (reduceMotion(context)) {
      _controller.value = widget.visible ? 1 : 0;
    } else if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.visible && widget.child != null) _last = widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isDismissed) {
          _last = null;
          return const SizedBox.shrink();
        }
        final child = _last;
        if (child == null) return const SizedBox.shrink();
        final shown = widget.visible;
        return FadeTransition(
          opacity: _curve,
          child: SlideTransition(
            position: Tween(begin: widget.from, end: Offset.zero)
                .animate(_curve),
            child: IgnorePointer(
              ignoring: !shown,
              child: ExcludeSemantics(excluding: !shown, child: child),
            ),
          ),
        );
      },
    );
  }
}
