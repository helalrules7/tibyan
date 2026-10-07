import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/tasmee_report.dart';
import '../domain/tasmee_session_request.dart';
import 'spectrum_bars.dart';
import 'tasmee_session_controller.dart';
import 'tasmee_style.dart';

/// What the panel's buttons do.
class PanelActions {
  const PanelActions({
    required this.onMain,
    required this.onEnd,
    required this.onHint,
    required this.onSkipWaiting,
    required this.onOpenSettings,
    required this.onTouchTest,
  });

  final VoidCallback? onMain;
  final VoidCallback? onEnd;

  /// Null hides the hint button (its feature flag is off).
  final VoidCallback? onHint;
  final VoidCallback onSkipWaiting;
  final VoidCallback onOpenSettings;
  final VoidCallback onTouchTest;
}

/// The recording panel under the page: part of the layout, never over the
/// page. The session's state, the live spectrum, the verse's accuracy and
/// the controls.
class RecordingPanel extends StatelessWidget {
  const RecordingPanel({
    super.key,
    required this.session,
    required this.actions,
    this.side = false,
  });

  final TasmeeSessionController session;
  final PanelActions actions;

  /// Laptop: drawn in the side column, not as a sheet under the page.
  final bool side;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    final elderly = context.tokens.elderly;
    final body = session.phase == TasmeePhase.micDenied
        ? _MicDenied(actions: actions)
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusRow(session: session, actions: actions),
              SizedBox(height: side ? 14 : 8),
              SpectrumBars(
                bands: session.bands,
                height: side ? 56 : (elderly ? 44 : 36),
                active: session.phase == TasmeePhase.listening,
              ),
              SizedBox(height: side ? 16 : 10),
              _Controls(session: session, actions: actions, side: side),
            ],
          );
    if (side) return body;
    return DecoratedBox(
      key: const ValueKey('tasmee-panel'),
      decoration: BoxDecoration(
        color: t.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: t.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.tokens.mode.isLight ? 0.06 : 0.3,
            ),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: body,
        ),
      ),
    );
  }
}

/// «Verse 7 · 91% · one mistake».
String verseResultText(BuildContext context, VerseReport v) {
  final l = AppLocalizations.of(context);
  final errors = v.wrong + v.skipped + v.corrected;
  final detail = switch (errors) {
    0 => l.tasmeeNoMistakes,
    1 => l.tasmeeOneMistake,
    _ => l.tasmeeMistakes(context.digits(errors)),
  };
  final acc = v.accuracy;
  return l.tasmeeVerseResult(
    context.digits(v.ayah),
    acc == null ? '–' : context.percent((acc * 100).round()),
    detail,
  );
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.session, required this.actions});

  final TasmeeSessionController session;
  final PanelActions actions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final c = context.tasmeeColors;
    final s = session;
    if (s.stopToCorrect) {
      return TasmeeBanner(
        color: c.wrong,
        icon: Icons.replay,
        text: l.tasmeeReReadWord,
        action: l.tasmeeSkipWord,
        onAction: actions.onSkipWaiting,
      );
    }
    final toast = s.toast;
    if (toast != null && s.phase != TasmeePhase.finished) {
      final good = (toast.accuracy ?? 0) >= 0.9;
      return TasmeeBanner(
        color: good ? c.corrected : c.skipped,
        icon: good ? Icons.check_circle : Icons.error_outline,
        text: verseResultText(context, toast),
      );
    }
    final verse = s.currentVerseFirst;
    final verseCount = s.words.map((w) => w.verseId).toSet().length;
    final verseNumber =
        s.words.map((w) => w.verseId).toSet().toList().indexOf(verse.verseId) +
        1;
    final verseMode = s.mode == TasmeeMode.verseByVerse;
    final text = switch (s.phase) {
      TasmeePhase.loading => l.tasmeeModelLoad,
      TasmeePhase.needsModel => l.tasmeeModelMissing,
      TasmeePhase.listening =>
        verseMode
            ? l.tasmeeListeningVerse(context.digits(verse.ayah))
            : l.tasmeeListening,
      TasmeePhase.ready || TasmeePhase.paused when verseMode => l.tasmeeVerseOf(
        context.digits(verseNumber),
        context.digits(verseCount),
      ),
      TasmeePhase.ready => l.tasmeeNotListening,
      TasmeePhase.paused => l.tasmeePaused,
      TasmeePhase.finishing => l.tasmeeFinishing,
      TasmeePhase.finished => l.tasmeeSessionComplete,
      TasmeePhase.micDenied => l.tasmeeMicOff,
    };
    final listening = s.phase == TasmeePhase.listening;
    return Semantics(
      liveRegion: true,
      container: true,
      child: SizedBox(
        height: 30,
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: listening ? c.wrong : t.muted,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: t.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (s.error != null)
              Tooltip(
                message: s.error!,
                child: Icon(Icons.error_outline, size: 18, color: c.wrong),
              ),
            const SizedBox(width: 6),
            Icon(Icons.timer_outlined, size: 16, color: t.muted),
            const SizedBox(width: 4),
            Semantics(
              label: l.tasmeeElapsed,
              child: Text(
                context.clock(s.elapsed),
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: t.muted,
                  fontSize: 14,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.session,
    required this.actions,
    required this.side,
  });

  final TasmeeSessionController session;
  final PanelActions actions;
  final bool side;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final elderly = context.tokens.elderly && !side;
    final big = elderly ? 72.0 : 62.0;
    final small = elderly ? 56.0 : 46.0;
    final s = session;
    final verseMode = s.mode == TasmeeMode.verseByVerse;
    final (icon, label) = switch (s.phase) {
      TasmeePhase.needsModel => (Icons.download, l.tasmeeDownloadShort),
      TasmeePhase.listening when verseMode => (Icons.check, l.tasmeeVerseDone),
      TasmeePhase.listening => (Icons.pause, l.tasmeePause),
      TasmeePhase.paused when !verseMode => (Icons.mic, l.tasmeeResume),
      TasmeePhase.finished => (Icons.summarize_outlined, l.tasmeeSummary),
      _ when verseMode => (Icons.mic, l.tasmeeReciteVerse),
      _ => (Icons.mic, l.tasmeeStart),
    };
    final finished = s.phase == TasmeePhase.finished;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: VerseRing(
              ayah: s.currentVerseFirst.ayah,
              accuracy: finished
                  ? switch (s.report.accuracy) {
                      final a? => (a * 100).round(),
                      null => null,
                    }
                  : s.currentAccuracy,
              overall: finished,
              size: elderly ? 54 : 46,
            ),
          ),
        ),
        TasmeeRoundButton(
          key: const ValueKey('tasmee-main'),
          icon: icon,
          label: label,
          filled: true,
          size: big,
          onPressed:
              s.phase == TasmeePhase.finishing || s.phase == TasmeePhase.loading
              ? null
              : actions.onMain,
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (actions.onHint != null && !finished) ...[
                Flexible(
                  child: TasmeeRoundButton(
                    key: const ValueKey('tasmee-hint'),
                    icon: Icons.lightbulb_outline,
                    label: l.tasmeeHint,
                    size: small,
                    onPressed:
                        s.cursorWord == null ||
                            s.phase == TasmeePhase.needsModel
                        ? null
                        : actions.onHint,
                  ),
                ),
                SizedBox(width: elderly ? 10 : 12),
              ],
              Flexible(
                child: TasmeeRoundButton(
                  key: const ValueKey('tasmee-end'),
                  icon: finished ? Icons.close : Icons.stop_rounded,
                  label: finished ? l.tasmeeClose : l.tasmeeEnd,
                  size: small,
                  onPressed: s.phase == TasmeePhase.finishing
                      ? null
                      : actions.onEnd,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Accuracy of the verse being recited (or, at the end, of the session)
/// as a small ring.
class VerseRing extends StatelessWidget {
  const VerseRing({
    super.key,
    required this.ayah,
    required this.accuracy,
    this.overall = false,
    this.size = 48,
  });

  final int ayah;
  final int? accuracy;
  final bool overall;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final acc = accuracy;
    final title = overall
        ? l.tasmeeAccuracy
        : l.tasmeeVerseNumber(context.digits(ayah));
    final note = overall ? l.tasmeeWholeSession : l.tasmeeThisVerse;
    return Semantics(
      label: l.tasmeeRingSemantics(
        title,
        note,
        acc == null ? '–' : context.percent(acc),
      ),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.square(
                  dimension: size,
                  child: CircularProgressIndicator(
                    value: (acc ?? 0) / 100,
                    strokeWidth: 3.5,
                    color: (acc ?? 100) >= 90
                        ? t.goldText
                        : context.tasmeeColors.skipped,
                    backgroundColor: t.border,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  acc == null ? '–' : context.percent(acc),
                  style: TextStyle(
                    color: t.ink,
                    fontSize: size * 0.27,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.muted, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MicDenied extends StatelessWidget {
  const _MicDenied({required this.actions});

  final PanelActions actions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final c = context.tasmeeColors;
    return Column(
      key: const ValueKey('tasmee-mic-denied'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.wrong.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic_off, color: c.wrong, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.tasmeeMicOff,
                    style: TextStyle(
                      color: t.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.tasmeeMicPrivacy,
                    style: TextStyle(
                      color: t.muted,
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: actions.onOpenSettings,
          icon: const Icon(Icons.settings_outlined),
          label: Text(l.tasmeeOpenDeviceSettings),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: actions.onTouchTest,
          child: Text(l.tasmeeTestByTouch),
        ),
      ],
    );
  }
}
