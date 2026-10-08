import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';

/// The pictures of a shared passage, one at a time, in reading order: the
/// next picture lies to the left, as the next page of the mushaf does, in
/// every interface language.
///
/// Turned by a swipe, a mouse or trackpad drag, the mouse wheel (one notch,
/// one picture), the arrow and Page Up/Down keys (left and Page Down go
/// forward, as in the mushaf), and the previous/next buttons either side of
/// the picture, disabled at the ends. Small dots show where one is when
/// there are only a few.
class ShareCarousel extends StatefulWidget {
  const ShareCarousel({
    super.key,
    required this.count,
    required this.itemBuilder,
    this.onPageChanged,
  });

  final int count;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int>? onPageChanged;

  /// Up to this many pictures, dots under them show which one is shown.
  static const maxDots = 12;

  @override
  State<ShareCarousel> createState() => _ShareCarouselState();
}

class _ShareCarouselState extends State<ShareCarousel> {
  final _controller = PageController();
  int _page = 0;

  /// When the mouse wheel last turned a picture: one notch, one picture.
  DateTime _lastWheelTurn = DateTime(0);

  @override
  void didUpdateWidget(ShareCarousel old) {
    super.didUpdateWidget(old);
    if (_page >= widget.count && widget.count > 0) {
      _page = widget.count - 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _turn(int by) {
    final to = _page + by;
    if (to < 0 || to >= widget.count || !_controller.hasClients) return;
    _controller.animateToPage(
      to,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// The mouse wheel turns the picture: down or right is forward. A
  /// trackpad swipe comes as a drag instead.
  void _onWheel(PointerSignalEvent e) {
    if (e is! PointerScrollEvent || e.kind == PointerDeviceKind.trackpad) {
      return;
    }
    final now = DateTime.now();
    if (now.difference(_lastWheelTurn) < const Duration(milliseconds: 350)) {
      return;
    }
    final d = e.scrollDelta.dy.abs() >= e.scrollDelta.dx.abs()
        ? e.scrollDelta.dy
        : -e.scrollDelta.dx;
    if (d.abs() < 1) return;
    _lastWheelTurn = now;
    _turn(d > 0 ? 1 : -1);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final many = widget.count > 1;
    final pages = Listener(
      onPointerSignal: many ? _onWheel : null,
      child: ScrollConfiguration(
        // A mouse and a trackpad drag the pictures like a finger.
        behavior: ScrollConfiguration.of(context)
            .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
        child: PageView.builder(
          controller: _controller,
          itemCount: widget.count,
          onPageChanged: (i) {
            setState(() => _page = i);
            widget.onPageChanged?.call(i);
          },
          itemBuilder: widget.itemBuilder,
        ),
      ),
    );
    if (!many) return pages;
    Widget button({required bool forward}) {
      final enabled = forward ? _page < widget.count - 1 : _page > 0;
      return IconButton(
        key: ValueKey(forward ? 'share-next' : 'share-previous'),
        tooltip: forward ? l.shareNextImage : l.sharePreviousImage,
        // Forward is to the left, as in the mushaf. The chevrons mirror in
        // this right-to-left row: chevron_right is drawn pointing left.
        icon: Icon(forward ? Icons.chevron_right : Icons.chevron_left),
        iconSize: 32,
        onPressed: enabled ? () => _turn(forward ? 1 : -1) : null,
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _turn(1),
        const SingleActivator(LogicalKeyboardKey.pageDown): () => _turn(1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _turn(-1),
        const SingleActivator(LogicalKeyboardKey.pageUp): () => _turn(-1),
      },
      child: Focus(
        autofocus: true,
        // The pictures read from the right, whatever the interface.
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    button(forward: false),
                    Expanded(child: pages),
                    button(forward: true),
                  ],
                ),
              ),
              if (widget.count <= ShareCarousel.maxDots)
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < widget.count; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _page ? 9 : 6,
                            height: i == _page ? 9 : 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _page
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
