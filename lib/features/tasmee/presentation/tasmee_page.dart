import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart' show PageFill;
import '../../../core/theme/app_theme.dart';
import '../../mushaf/mushaf_providers.dart';
import '../../mushaf/presentation/widgets/mushaf_page.dart';
import '../../mushaf/presentation/widgets/page_interaction.dart';
import '../domain/alignment_engine.dart';
import '../domain/expected_words.dart';
import 'tasmee_style.dart';

/// What the page shows of the session: each word's state, the words shown
/// by a hint, the word the reader is on.
class TasmeePageState {
  const TasmeePageState({
    required this.statusOf,
    this.hinted = const {},
    this.cursor,
    this.waitingAt,
    this.revealAll = false,
  });

  final WordStatus Function(int index) statusOf;
  final Set<int> hinted;

  /// The next word to read (a caret before it); null when not listening.
  final int? cursor;

  /// Stop to correct: the wrong word waited on (ringed).
  final int? waitingAt;

  /// The session is over: words never reached are shown too, faded.
  final bool revealAll;
}

/// One page of the new Madina edition (1441) as the session sees it: the
/// range's words covered in place until they are recited, each shown word
/// in its state's colour on its own letters, and the rest of the page
/// faded. The page artwork is the app's own, unchanged.
class TasmeePage extends ConsumerWidget {
  const TasmeePage({
    super.key,
    required this.page,
    required this.words,
    required this.state,
  });

  final int page;

  /// The session's words printed on [page], in order.
  final List<ExpectedWord> words;
  final TasmeePageState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boxes = ref.watch(pageWordBoxesProvider(page)).value;
    final t = context.tokens.colors;
    final c = context.tasmeeColors;
    final s = state;

    final hidden = <VerseKey>{};
    final hiddenWords = <VerseKey, List<Rect>>{};
    final revealedWords = <VerseKey, List<Rect>>{};
    final tints = <Color, List<Rect>>{};
    final marks = <(_Mark, Rect)>[];
    final inRange = <VerseKey>{};

    void tint(Color colour, List<Rect> rects) =>
        (tints[colour] ??= []).addAll(rects);

    if (boxes != null) {
      final byVerse = <VerseKey, List<ExpectedWord>>{};
      for (final w in words) {
        (byVerse[(surah: w.surah, ayah: w.ayah)] ??= []).add(w);
      }
      for (final MapEntry(key: v, value: ws) in byVerse.entries) {
        inRange.add(v);
        final covered = <Rect>[];
        final shown = <Rect>[];
        for (final w in ws) {
          final rects = boxes[(w.surah, w.ayah, w.word)] ?? const <Rect>[];
          final status = s.statusOf(w.index);
          final hint = s.hinted.contains(w.index);
          if (status == WordStatus.hidden && !hint && !s.revealAll) {
            covered.addAll(rects);
            if (w.index == s.cursor && rects.isNotEmpty) {
              marks.add((_Mark.caret, _union(rects)));
            }
            continue;
          }
          shown.addAll(rects);
          if (hint) {
            tint(c.hint, rects);
            if (rects.isNotEmpty) marks.add((_Mark.hint, _union(rects)));
            continue;
          }
          switch (status) {
            case WordStatus.correct:
              break;
            case WordStatus.wrong:
              tint(c.wrong, rects);
              if (w.index == s.waitingAt && rects.isNotEmpty) {
                marks.add((_Mark.ring, _union(rects)));
              }
            case WordStatus.skipped:
              tint(c.skipped, rects);
              if (rects.isNotEmpty) marks.add((_Mark.dashed, _union(rects)));
            case WordStatus.correctedAfterError:
              tint(c.corrected, rects);
            case WordStatus.doubtful:
              tint(c.doubtful, rects);
              if (rects.isNotEmpty) marks.add((_Mark.dotted, _union(rects)));
            case WordStatus.hidden:
              // Never reached; the session is over.
              tint(t.muted.withValues(alpha: 0.55), rects);
          }
        }
        if (covered.isNotEmpty) {
          hidden.add(v);
          hiddenWords[v] = covered;
          if (shown.isNotEmpty) revealedWords[v] = shown;
        }
      }
      // The rest of the page, outside the range, is faded.
      for (final MapEntry(key: (surah, ayah, _), value: rects)
          in boxes.entries) {
        if (!inRange.contains((surah: surah, ayah: ayah))) {
          tint(t.muted.withValues(alpha: 0.5), rects);
        }
      }
    }

    final interaction = PageInteraction(
      selection: const {},
      marks: const {},
      onTap: () {},
      onVerseLongPress: (_) {},
      onMarkerTap: (_) {},
      onHandleDrag: (_, _) {},
      hidden: hidden,
      hiddenWords: hiddenWords,
      revealedWords: revealedWords,
      wordTints: tints,
      fill: PageFill.lines,
      wordOverlay: marks.isEmpty
          ? null
          : (canvas, toScreen) =>
                _paintMarks(canvas, marks, toScreen, c, t.goldText, t.paper),
    );
    // Frameless, as in focus mode: the lines fill the width at the
    // glyphs' own proportions, on the theme's paper.
    return Semantics(
      container: true,
      label: _pageLabel(context, s),
      child: ColoredBox(
        color: t.paper,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: PageGround(
            color: t.paper,
            child: MushafPage(
              key: ValueKey('tasmee/$page'),
              page: page,
              interaction: interaction,
            ),
          ),
        ),
      ),
    );
  }

  String? _pageLabel(BuildContext context, TasmeePageState s) {
    final shown = words
        .where((w) => s.statusOf(w.index) != WordStatus.hidden || s.revealAll)
        .map((w) => w.display);
    return shown.isEmpty ? null : shown.join(' ');
  }

  static Rect _union(List<Rect> rects) =>
      rects.reduce((a, b) => a.expandToInclude(b));
}

enum _Mark { caret, ring, dashed, dotted, hint }

void _paintMarks(
  Canvas canvas,
  List<(_Mark, Rect)> marks,
  Rect Function(Rect) toScreen,
  TasmeeStateColors c,
  Color gold,
  Color paper,
) {
  for (final (kind, box) in marks) {
    final r = toScreen(box);
    switch (kind) {
      case _Mark.caret:
        // A soft caret at the start (right) of the next word, and a faint
        // baseline where it will appear.
        final y = r.center.dy;
        canvas
          ..drawLine(
            Offset(r.right + 2, y - r.height * 0.32),
            Offset(r.right + 2, y + r.height * 0.32),
            Paint()
              ..color = gold
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round,
          )
          ..drawLine(
            Offset(r.right - 2, r.bottom + 1),
            Offset(r.right - r.width * 0.6, r.bottom + 1),
            Paint()
              ..color = gold.withValues(alpha: 0.35)
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round,
          );
      case _Mark.ring:
        final rr = RRect.fromRectAndRadius(
          r.inflate(3),
          const Radius.circular(6),
        );
        canvas
          ..drawRRect(rr, Paint()..color = c.wrong.withValues(alpha: 0.10))
          ..drawRRect(
            rr,
            Paint()
              ..color = c.wrong
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4,
          );
      case _Mark.dashed:
        final path = Path()
          ..addRRect(
            RRect.fromRectAndRadius(r.inflate(2), const Radius.circular(5)),
          );
        final paint = Paint()
          ..color = c.skipped
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3;
        for (final metric in path.computeMetrics()) {
          for (var d = 0.0; d < metric.length; d += 6) {
            canvas.drawPath(metric.extractPath(d, d + 3.5), paint);
          }
        }
      case _Mark.dotted:
        final p = Paint()..color = c.doubtful;
        for (var x = r.left; x < r.right; x += 4.5) {
          canvas.drawCircle(Offset(x + 1, r.bottom + 3), 1.1, p);
        }
      case _Mark.hint:
        final radius = math.max(4.0, math.min(6.5, r.height * 0.22));
        final centre = Offset(r.center.dx, r.top - radius * 0.6);
        canvas.drawCircle(centre, radius, Paint()..color = c.hint);
        final icon = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(Icons.lightbulb.codePoint),
            style: TextStyle(
              fontFamily: Icons.lightbulb.fontFamily,
              package: Icons.lightbulb.fontPackage,
              fontSize: radius * 1.5,
              color: paper,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        icon.paint(canvas, centre - Offset(icon.width / 2, icon.height / 2));
    }
  }
}
