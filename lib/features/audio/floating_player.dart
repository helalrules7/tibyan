import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/mushaf_providers.dart';
import 'player_bar.dart';
import 'recitation.dart';

/// The small players over the mushaf («شكل المشغل»): the focus pill
/// ([PlayerStyle.pill]) or the single round button ([PlayerStyle.button]).
/// Either can be dragged anywhere over [room] (the whole screen); where it
/// is left is saved, and it is kept inside the screen when the screen's
/// size changes. It takes touches only on itself.
class FloatingPlayer extends ConsumerStatefulWidget {
  const FloatingPlayer({super.key, required this.style});

  /// [PlayerStyle.pill] or [PlayerStyle.button].
  final PlayerStyle style;

  /// Where it sits until it is moved: its centre, as fractions of the
  /// screen, low in the middle.
  static const defaultPosition = Offset(0.5, 0.9);

  /// Room kept between it and the screen's edges (inside the safe area).
  static const margin = 8.0;

  /// Its size on screen, for [style] and elderly mode.
  static Size sizeOf(PlayerStyle style, {required bool elderly}) =>
      style == PlayerStyle.pill
      ? (elderly ? const Size(324, 76) : const Size(148, 48))
      : (elderly ? const Size(96, 100) : const Size(56, 56));

  /// Where its top left corner goes in a room of [size] with [padding] (the
  /// safe area), its centre at [at] (fractions of the room) kept inside.
  static Offset place(Offset at, Size size, EdgeInsets padding, Size own) {
    double clamp(double v, double lo, double hi) =>
        hi < lo ? (lo + hi) / 2 : v.clamp(lo, hi);
    final x = clamp(
      at.dx * size.width,
      padding.left + margin + own.width / 2,
      size.width - padding.right - margin - own.width / 2,
    );
    final y = clamp(
      at.dy * size.height,
      padding.top + margin + own.height / 2,
      size.height - padding.bottom - margin - own.height / 2,
    );
    return Offset(x - own.width / 2, y - own.height / 2);
  }

  @override
  ConsumerState<FloatingPlayer> createState() => _FloatingPlayerState();
}

class _FloatingPlayerState extends ConsumerState<FloatingPlayer> {
  /// Its centre while it is dragged (fractions of the room); null at rest.
  Offset? _dragging;

  /// A finger is on it: it is drawn fully opaque.
  bool _touched = false;

  @override
  Widget build(BuildContext context) {
    final elderly = context.tokens.elderly;
    final own = FloatingPlayer.sizeOf(widget.style, elderly: elderly);
    final padding = MediaQuery.paddingOf(context);
    final saved =
        ref.watch(settingsProvider.select((s) => s.playerPosition)) ??
        FloatingPlayer.defaultPosition;
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        // The centre drawn for [want] (fractions), kept inside the screen.
        Offset kept(Offset want) {
          final at = FloatingPlayer.place(want, size, padding, own);
          return Offset(
            (at.dx + own.width / 2) / size.width,
            (at.dy + own.height / 2) / size.height,
          );
        }

        final at = FloatingPlayer.place(_dragging ?? saved, size, padding, own);
        // Read at the time of the gesture, not of the last frame: a drag's
        // events can come faster than frames.
        Offset centre() => kept(_dragging ?? saved);
        return Stack(
          children: [
            Positioned(
              key: const ValueKey('floating-player'),
              left: at.dx,
              top: at.dy,
              width: own.width,
              height: own.height,
              child: Listener(
                onPointerDown: (_) => setState(() => _touched = true),
                onPointerUp: (_) => setState(() => _touched = false),
                onPointerCancel: (_) => setState(() => _touched = false),
                child: GestureDetector(
                  onPanStart: (_) => setState(() => _dragging = centre()),
                  onPanUpdate: (d) => setState(() {
                    final c = centre();
                    _dragging = kept(
                      Offset(
                        c.dx + d.delta.dx / size.width,
                        c.dy + d.delta.dy / size.height,
                      ),
                    );
                  }),
                  onPanEnd: (_) {
                    // Kept where it is drawn: inside the screen.
                    final kept = centre();
                    setState(() => _dragging = null);
                    ref.read(settingsProvider.notifier).setPlayerPosition(kept);
                  },
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: _touched || _dragging != null ? 1 : 0.4,
                    child: widget.style == PlayerStyle.pill
                        ? const _PlayerPill()
                        : const _PlayerButton(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The focus pill: play or pause, the player's settings, and a small ×
/// that stops the recitation (and so closes the pill). In elderly mode
/// each button carries its name.
class _PlayerPill extends ConsumerWidget {
  const _PlayerPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final elderly = context.tokens.elderly;
    final s = ref.watch(recitationProvider);
    final c = ref.read(recitationProvider.notifier);
    Widget button(
      IconData icon,
      String label,
      VoidCallback onTap, {
      double size = 22,
    }) => Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: elderly ? 36 : 22,
          child: SizedBox(
            width: elderly ? 104 : 44,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: elderly ? 28 : size, color: t.playerFg),
                if (elderly)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(fontSize: 13, color: t.playerFg),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    return Material(
      color: t.player,
      elevation: 0,
      shape: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            s.loading
                ? SizedBox(
                    width: elderly ? 104 : 44,
                    child: Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: t.playerFg,
                          semanticsLabel: l.loadingLabel,
                        ),
                      ),
                    ),
                  )
                : button(
                    s.playing ? Icons.pause : Icons.play_arrow,
                    s.playing ? l.pause : l.resume,
                    c.toggle,
                    size: 26,
                  ),
            button(
              Icons.tune,
              l.playerSettings,
              () => showPlayerSheet(context),
            ),
            button(Icons.close, l.stopListening, c.stop, size: 18),
          ],
        ),
      ),
    );
  }
}

/// The single button: a tap plays or pauses, a long press opens a small
/// menu (the player's settings, the full player, stop, close), and a ring
/// around it fills with the progress through the surah.
class _PlayerButton extends ConsumerWidget {
  const _PlayerButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final elderly = context.tokens.elderly;
    final s = ref.watch(recitationProvider);
    final c = ref.read(recitationProvider.notifier);
    final count = ref.watch(surahAyahCountProvider(s.surah)).value;
    final progress = count == null || count == 0 || s.ayah == null
        ? 0.0
        : (s.ayah! / count).clamp(0.0, 1.0);
    final label = s.playing ? l.pause : l.resume;
    final dimension = elderly ? 72.0 : 56.0;

    Future<void> menu() async {
      final box = context.findRenderObject() as RenderBox?;
      final overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox?;
      if (box == null || overlay == null) return;
      final rect = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
      final chosen = await showMenu<_ButtonMenu>(
        context: context,
        position: RelativeRect.fromRect(rect, Offset.zero & overlay.size),
        items: [
          for (final (v, icon, name) in [
            (_ButtonMenu.settings, Icons.tune, l.playerSettings),
            (_ButtonMenu.full, Icons.open_in_full, l.playerFull),
            (_ButtonMenu.stop, Icons.stop, l.stopListening),
            (
              _ButtonMenu.close,
              Icons.close,
              MaterialLocalizations.of(context).closeButtonLabel,
            ),
          ])
            PopupMenuItem(
              value: v,
              child: Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 12),
                  Flexible(child: Text(name)),
                ],
              ),
            ),
        ],
      );
      if (!context.mounted) return;
      switch (chosen) {
        case _ButtonMenu.settings:
          await showPlayerSheet(context);
        case _ButtonMenu.full:
          await showFullPlayer(context);
        case _ButtonMenu.stop:
          await c.stop();
        case _ButtonMenu.close || null:
          break;
      }
    }

    return Semantics(
      button: true,
      label: label,
      onTap: c.toggle,
      onLongPress: menu,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: c.toggle,
        onLongPress: menu,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: dimension,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: progress,
                  disc: t.player,
                  track: t.playerFg.withValues(alpha: 0.3),
                  fill: t.playerFg,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: SizedBox.expand(
                    child: Center(
                      child: s.loading
                          ? SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: t.playerFg,
                                semanticsLabel: l.loadingLabel,
                              ),
                            )
                          : Icon(
                              s.playing ? Icons.pause : Icons.play_arrow,
                              size: elderly ? 34 : 28,
                              color: t.playerFg,
                            ),
                    ),
                  ),
                ),
              ),
            ),
            if (elderly)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: t.player,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: t.playerFg),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _ButtonMenu { settings, full, stop, close }

/// The single button's [disc], and the ring inside its edge: [progress]
/// (0..1) through the surah, from the top, clockwise.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.disc,
    required this.track,
    required this.fill,
  });

  final double progress;
  final Color disc;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 3.5;
    canvas.drawOval(Offset.zero & size, Paint()..color = disc);
    final rect = (Offset.zero & size).deflate(3 + stroke / 2);
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = fill,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.disc != disc ||
      old.track != track ||
      old.fill != fill;
}

/// Today's player bar in a sheet, from the single button's menu; it closes
/// when the recitation stops.
Future<void> showFullPlayer(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: Colors.transparent,
  elevation: 0,
  builder: (_) => const _FullPlayerSheet(),
);

class _FullPlayerSheet extends ConsumerWidget {
  const _FullPlayerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(recitationProvider.select((s) => s.active), (_, active) {
      if (!active) Navigator.of(context).maybePop();
    });
    return const SafeArea(
      child: Padding(padding: EdgeInsets.all(12), child: PlayerBar()),
    );
  }
}
