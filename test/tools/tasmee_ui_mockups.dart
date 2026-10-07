// PROTOTYPE, NOT APP CODE. Design mockups for the audio tasmee screens
// (docs/plan/TIBYAN_RECITATION_PLAN.md, phase 4). Nothing in lib/ imports
// this file; only test/tools/render_tasmee_ui_test.dart draws it, into PNGs
// for review. The mushaf page itself is the app's real MushafPage, drawn
// by that test and passed in here as an image ([PageShot]).

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;

// ---------------------------------------------------------------------------
// State colours
// ---------------------------------------------------------------------------

/// The word-state colours, per mode. Correct words keep the page's ink.
class TasmeeStateColors {
  const TasmeeStateColors({
    required this.wrong,
    required this.skipped,
    required this.corrected,
    required this.doubtful,
    required this.hint,
  });

  final Color wrong;
  final Color skipped;
  final Color corrected;
  final Color doubtful;
  final Color hint;

  static TasmeeStateColors of(ThemeModeId mode, ModeTokens t) => mode.isLight
      ? TasmeeStateColors(
          wrong: const Color(0xFFB3261E),
          skipped: const Color(0xFF9A5B00),
          corrected: const Color(0xFF2E6B57),
          doubtful: t.muted,
          hint: const Color(0xFF3B6A93),
        )
      : TasmeeStateColors(
          wrong: const Color(0xFFFF8A80),
          skipped: const Color(0xFFF0B45A),
          corrected: const Color(0xFF8FCBB5),
          doubtful: t.muted,
          hint: const Color(0xFF9CC3E6),
        );
}

extension _Ctx on BuildContext {
  ModeTokens get t => tokens.colors;
  TasmeeStateColors get states => TasmeeStateColors.of(tokens.mode, t);
  bool get ar => Localizations.localeOf(this).languageCode == 'ar';
  String n(int v) => NumberFormatter(Localizations.localeOf(this))(v);
  String s(String a, String e) => ar ? a : e;
  String pct(int v) => ar ? '${n(v)}٪' : '$v%';
}

// ---------------------------------------------------------------------------
// Spectrum: FFT bands from PCM (what the app would compute per frame)
// ---------------------------------------------------------------------------

/// In-place iterative radix-2 FFT.
void _fft(Float64List re, Float64List im) {
  final n = re.length;
  for (var i = 1, j = 0; i < n; i++) {
    var bit = n >> 1;
    for (; j & bit != 0; bit >>= 1) {
      j ^= bit;
    }
    j ^= bit;
    if (i < j) {
      final tr = re[i];
      re[i] = re[j];
      re[j] = tr;
      final ti = im[i];
      im[i] = im[j];
      im[j] = ti;
    }
  }
  for (var len = 2; len <= n; len <<= 1) {
    final ang = -2 * math.pi / len;
    final wr = math.cos(ang), wi = math.sin(ang);
    for (var i = 0; i < n; i += len) {
      var cr = 1.0, ci = 0.0;
      for (var k = 0; k < len ~/ 2; k++) {
        final ar = re[i + k + len ~/ 2] * cr - im[i + k + len ~/ 2] * ci;
        final ai = re[i + k + len ~/ 2] * ci + im[i + k + len ~/ 2] * cr;
        re[i + k + len ~/ 2] = re[i + k] - ar;
        im[i + k + len ~/ 2] = im[i + k] - ai;
        re[i + k] += ar;
        im[i + k] += ai;
        final nr = cr * wr - ci * wi;
        ci = cr * wi + ci * wr;
        cr = nr;
      }
    }
  }
}

/// [bands] log-spaced band levels (0 to 1) of the last 512 samples of
/// 16 kHz [pcm], 90 Hz to 5 kHz, on a fixed dBFS scale (-70 dB is silent,
/// -15 dB full), so silence stays flat. About 10k multiply-adds per call:
/// at 30 calls a second it is nothing next to the recogniser.
List<double> spectrumBands(Int16List pcm, {int bands = 18}) {
  const n = 512, rate = 16000, lo = 250.0, hi = 4500.0;
  final re = Float64List(n), im = Float64List(n);
  final start = pcm.length - n;
  for (var i = 0; i < n; i++) {
    final w = 0.5 - 0.5 * math.cos(2 * math.pi * i / (n - 1));
    re[i] = pcm[start + i] / 32768.0 * w;
  }
  _fft(re, im);
  final out = <double>[];
  for (var b = 0; b < bands; b++) {
    final f0 = lo * math.pow(hi / lo, b / bands);
    final f1 = lo * math.pow(hi / lo, (b + 1) / bands);
    final k0 = (f0 * n / rate).floor().clamp(1, n ~/ 2 - 1);
    final k1 = math.max(k0 + 1, (f1 * n / rate).ceil()).clamp(2, n ~/ 2);
    var peak = 0.0;
    for (var k = k0; k < k1; k++) {
      final mag = math.sqrt(re[k] * re[k] + im[k] * im[k]) / (n / 4);
      peak = math.max(peak, mag);
    }
    final db = 20 * math.log(peak + 1e-9) / math.ln10;
    out.add(((db + 70) / 55).clamp(0.0, 1.0));
  }
  return out;
}

/// A deterministic voiced sound: harmonics of [f0] shaped by [formants].
Int16List syntheticVoice({
  double f0 = 150,
  List<double> formants = const [650, 1150, 2600],
  double gain = 1,
  int seed = 7,
}) {
  const n = 1024, rate = 16000;
  final rng = math.Random(seed);
  final phases = List.generate(40, (_) => rng.nextDouble() * 2 * math.pi);
  final out = Int16List(n);
  for (var i = 0; i < n; i++) {
    final t = i / rate;
    var v = 0.0;
    for (var k = 1; k * f0 < 5200; k++) {
      final f = k * f0;
      var env = 0.0;
      for (final (j, fm) in formants.indexed) {
        final bw = 90.0 + 60 * j;
        env += math.exp(-math.pow(f - fm, 2) / (2 * bw * bw)) / (1 + j * 0.8);
      }
      v +=
          0.16 *
          gain *
          (env + 0.02) *
          math.sin(2 * math.pi * f * t + phases[k % 40]);
    }
    v += (rng.nextDouble() - 0.5) * 0.004;
    out[i] = (v.clamp(-1.0, 1.0) * 32767).round();
  }
  return out;
}

/// Calm mirrored bars: low frequencies in the middle, spreading out.
class SpectrumBars extends StatelessWidget {
  const SpectrumBars({
    super.key,
    required this.bands,
    this.height = 40,
    this.active = true,
  });

  final List<double> bands;
  final double height;
  final bool active;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: CustomPaint(
      painter: _BarsPainter(
        bands,
        active ? context.t.control : context.t.border,
        context.t.border,
        active,
      ),
      size: Size.infinite,
    ),
  );
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.bands, this.color, this.rest, this.active);

  final List<double> bands;
  final Color color;
  final Color rest;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final mirrored = [...bands.reversed, ...bands];
    const gap = 3.0;
    final w = (size.width - gap * (mirrored.length - 1)) / mirrored.length;
    final bar = math.min(w, 6.0);
    final total = bar * mirrored.length + gap * (mirrored.length - 1);
    var x = (size.width - total) / 2;
    final mid = size.height / 2;
    for (final v0 in mirrored) {
      final v = active ? v0 : 0.0;
      final h = math.max(bar, v * size.height);
      final paint = Paint()
        ..color = v < 0.08 ? rest : color.withValues(alpha: 0.35 + 0.65 * v);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x + bar / 2, mid),
            width: bar,
            height: h,
          ),
          Radius.circular(bar / 2),
        ),
        paint,
      );
      x += bar + gap;
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => true;
}

// ---------------------------------------------------------------------------
// The page, as drawn by the app, with the word marks on top
// ---------------------------------------------------------------------------

enum WordMarkKind {
  skippedFrame,
  doubtfulUnderline,
  wrongRing,
  cursor,
  hintBadge,
}

class WordMark {
  const WordMark(this.rect, this.kind);

  /// Logical pixels inside the page slot.
  final Rect rect;
  final WordMarkKind kind;
}

/// The real page (an image of MushafPage in its frame) and the marks the
/// proposal adds over words. [onSize] reports the room it is given, so the
/// page can be drawn at exactly that size.
class PageSlot extends StatelessWidget {
  const PageSlot({super.key, this.image, this.marks = const [], this.onSize});

  final ui.Image? image;
  final List<WordMark> marks;
  final ValueChanged<Size>? onSize;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      onSize?.call(c.biggest);
      if (image == null) return const SizedBox.expand();
      return Stack(
        children: [
          Positioned.fill(
            child: RawImage(image: image, fit: BoxFit.fill),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _MarksPainter(marks, context.states, context.t),
            ),
          ),
        ],
      );
    },
  );
}

class _MarksPainter extends CustomPainter {
  _MarksPainter(this.marks, this.c, this.t);

  final List<WordMark> marks;
  final TasmeeStateColors c;
  final ModeTokens t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final m in marks) {
      final r = m.rect;
      switch (m.kind) {
        case WordMarkKind.skippedFrame:
          _dashed(
            canvas,
            RRect.fromRectAndRadius(r.inflate(3), const Radius.circular(5)),
            Paint()
              ..color = c.skipped
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.3,
          );
        case WordMarkKind.doubtfulUnderline:
          final p = Paint()..color = c.doubtful;
          for (var x = r.left; x < r.right; x += 4.5) {
            canvas.drawCircle(Offset(x + 1, r.bottom + 4), 1.1, p);
          }
        case WordMarkKind.wrongRing:
          canvas.drawRRect(
            RRect.fromRectAndRadius(r.inflate(4), const Radius.circular(6)),
            Paint()..color = c.wrong.withValues(alpha: 0.10),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(r.inflate(4), const Radius.circular(6)),
            Paint()
              ..color = c.wrong
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4,
          );
        case WordMarkKind.cursor:
          final y = r.center.dy;
          final paint = Paint()
            ..color = t.goldText
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round;
          // A soft caret at the start (right) of the next word.
          canvas.drawLine(
            Offset(r.right + 3, y - r.height * 0.32),
            Offset(r.right + 3, y + r.height * 0.32),
            paint,
          );
          // And a faint baseline where the word will appear.
          canvas.drawLine(
            Offset(r.right - 2, r.bottom + 2),
            Offset(r.right - r.width * 0.6, r.bottom + 2),
            Paint()
              ..color = t.goldText.withValues(alpha: 0.35)
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round,
          );
        case WordMarkKind.hintBadge:
          final centre = Offset(r.center.dx, r.top - 6);
          canvas.drawCircle(centre, 6.5, Paint()..color = c.hint);
          final tp = TextPainter(
            text: TextSpan(
              text: String.fromCharCode(Icons.lightbulb.codePoint),
              style: TextStyle(
                fontFamily: Icons.lightbulb.fontFamily,
                package: Icons.lightbulb.fontPackage,
                fontSize: 10,
                color: t.paper,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  void _dashed(Canvas canvas, RRect r, Paint paint) {
    final path = Path()..addRRect(r);
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 6) {
        canvas.drawPath(metric.extractPath(d, d + 3.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MarksPainter old) => true;
}

// ---------------------------------------------------------------------------
// Session screen (proposal)
// ---------------------------------------------------------------------------

enum PanelState { listening, paused, stopToCorrect, verseByVerse, micDenied }

/// What the screen shows about the session (all made up for the mockup,
/// except the surah name and the verse numbers, which come from the
/// content database).
class SessionInfo {
  const SessionInfo({
    required this.surahName,
    required this.fromAyah,
    required this.toAyah,
    required this.progress,
    required this.elapsed,
    required this.currentAyah,
    required this.currentAccuracy,
    this.toastAyah,
    this.toastAccuracy,
    this.toastErrors = 0,
    this.verseByVerse = false,
    this.hintOn = true,
    this.verseRows = const [],
  });

  final String surahName;
  final int fromAyah;
  final int toAyah;
  final double progress;
  final Duration elapsed;
  final int currentAyah;
  final int currentAccuracy;
  final int? toastAyah;
  final int? toastAccuracy;
  final int toastErrors;
  final bool verseByVerse;
  final bool hintOn;

  /// Laptop side panel: verse number and accuracy (null: not read yet).
  final List<(int, int?)> verseRows;
}

class SessionTopBar extends StatelessWidget {
  const SessionTopBar({super.key, required this.info});

  final SessionInfo info;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mode = info.verseByVerse
        ? context.s('آية بآية', 'Verse by verse')
        : context.s('متصل', 'Continuous');
    return Material(
      color: t.bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 54,
            child: Row(
              children: [
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.close, color: t.ink),
                  tooltip: context.s('إغلاق', 'Close'),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.s(
                          'تسميع · ${info.surahName}',
                          'Recite · ${info.surahName}',
                        ),
                        style: TextStyle(
                          color: t.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        context.s(
                          'الآيات ${context.n(info.fromAyah)}–${context.n(info.toAyah)} · $mode',
                          'Verses ${info.fromAyah}–${info.toAyah} · $mode',
                        ),
                        style: TextStyle(
                          color: t.muted,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.help_outline, color: t.ink),
                  tooltip: context.s('المساعدة', 'Help'),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          // How much of the range has been recited.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: info.progress,
                minHeight: 3,
                color: t.goldText,
                backgroundColor: t.border,
              ),
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

/// Accuracy of the verse being recited, as a small ring.
class VerseRing extends StatelessWidget {
  const VerseRing({
    super.key,
    required this.ayah,
    required this.accuracy,
    this.size = 48,
  });

  final int ayah;
  final int accuracy;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Row(
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
                  value: accuracy / 100,
                  strokeWidth: 3.5,
                  color: accuracy >= 90 ? t.goldText : context.states.skipped,
                  backgroundColor: t.border,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                context.pct(accuracy),
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
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.s('الآية ${context.n(ayah)}', 'Verse $ayah'),
              style: TextStyle(
                color: t.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              context.s('دقة الآية', 'this verse'),
              style: TextStyle(color: t.muted, fontSize: 11.5),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    this.filled = false,
    this.size = 48,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = t.control;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: filled ? c : t.paper,
          shape: CircleBorder(
            side: filled
                ? BorderSide.none
                : BorderSide(color: t.border, width: 1.2),
          ),
          elevation: filled ? 2 : 0,
          shadowColor: c.withValues(alpha: 0.4),
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              icon,
              color: filled ? t.onControl : c,
              size: size * 0.46,
            ),
          ),
        ),
        ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: t.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// The bottom recording panel: part of the layout, under the page, never
/// over it.
class RecordingPanel extends StatelessWidget {
  const RecordingPanel({
    super.key,
    required this.state,
    required this.info,
    required this.bands,
  });

  final PanelState state;
  final SessionInfo info;
  final List<double> bands;

  String _clock(BuildContext context) {
    final m = info.elapsed.inMinutes, s = info.elapsed.inSeconds % 60;
    final text =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return NumberFormatter(Localizations.localeOf(context)).decimal(text);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final elderly = context.tokens.elderly;
    return DecoratedBox(
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
          child: state == PanelState.micDenied
              ? _MicDenied()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _statusRow(context),
                    const SizedBox(height: 8),
                    SpectrumBars(
                      bands: bands,
                      height: elderly ? 44 : 36,
                      active:
                          state == PanelState.listening ||
                          state == PanelState.stopToCorrect,
                    ),
                    const SizedBox(height: 10),
                    _controls(context, elderly),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _statusRow(BuildContext context) {
    final t = context.t;
    final c = context.states;
    if (state == PanelState.stopToCorrect) {
      return _Banner(
        color: c.wrong,
        icon: Icons.replay,
        text: context.s(
          'أعد قراءة الكلمة المعلّمة بالأحمر',
          'Re-read the word marked in red',
        ),
        action: context.s('تجاوزها', 'Skip it'),
      );
    }
    if (info.toastAyah != null) {
      final good = info.toastAccuracy! >= 90;
      final detail = info.toastErrors == 0
          ? context.s('بلا أخطاء', 'no mistakes')
          : info.toastErrors == 1
          ? context.s('خطأ واحد', 'one mistake')
          : context.s(
              '${context.n(info.toastErrors)} أخطاء',
              '${info.toastErrors} mistakes',
            );
      return _Banner(
        color: good ? c.corrected : c.skipped,
        icon: good ? Icons.check_circle : Icons.error_outline,
        text: context.s(
          'الآية ${context.n(info.toastAyah!)} · ${context.pct(info.toastAccuracy!)} · $detail',
          'Verse ${info.toastAyah} · ${info.toastAccuracy}% · $detail',
        ),
        soft: true,
      );
    }
    final listening = state == PanelState.listening;
    return SizedBox(
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
          Text(
            switch (state) {
              PanelState.paused => context.s('متوقف مؤقتا', 'Paused'),
              PanelState.verseByVerse => context.s(
                'الآية ${context.n(info.currentAyah)} من ${context.n(info.toAyah)}: اضغط وسمّعها',
                'Verse ${info.currentAyah} of ${info.toAyah}: tap and recite it',
              ),
              _ => context.s('أستمع إليك', 'Listening'),
            },
            style: TextStyle(
              color: t.ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Icon(Icons.timer_outlined, size: 16, color: t.muted),
          const SizedBox(width: 4),
          Text(
            _clock(context),
            style: TextStyle(
              color: t.muted,
              fontSize: 14,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls(BuildContext context, bool elderly) {
    final big = elderly ? 72.0 : 62.0;
    final small = elderly ? 56.0 : 46.0;
    final main = switch (state) {
      PanelState.paused => _RoundButton(
        icon: Icons.mic,
        label: context.s('متابعة', 'Resume'),
        filled: true,
        size: big,
      ),
      PanelState.verseByVerse => _RoundButton(
        icon: Icons.mic,
        label: context.s('سمّع الآية', 'Recite verse'),
        filled: true,
        size: big,
      ),
      _ => _RoundButton(
        icon: Icons.pause,
        label: context.s('إيقاف مؤقت', 'Pause'),
        filled: true,
        size: big,
      ),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: VerseRing(
              ayah: info.currentAyah,
              accuracy: info.currentAccuracy,
              size: elderly ? 54 : 46,
            ),
          ),
        ),
        main,
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (info.hintOn) ...[
                _RoundButton(
                  icon: Icons.lightbulb_outline,
                  label: context.s('تلميح', 'Hint'),
                  size: small,
                ),
                SizedBox(width: elderly ? 10 : 12),
              ],
              _RoundButton(
                icon: Icons.stop_rounded,
                label: context.s('إنهاء', 'Finish'),
                size: small,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.icon,
    required this.text,
    this.action,
    this.soft = false,
  });

  final Color color;
  final IconData icon;
  final String text;
  final String? action;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      height: 34,
      padding: const EdgeInsetsDirectional.only(start: 10, end: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: soft ? 0.12 : 0.14),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: t.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: color,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                action!,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _MicDenied extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
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
                color: context.states.wrong.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic_off, color: context.states.wrong, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.s(
                      'الميكروفون غير مسموح',
                      'Microphone access is off',
                    ),
                    style: TextStyle(
                      color: t.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.s(
                      'التسميع يسمع قراءتك على جهازك فقط. لا يُرسل الصوت ولا يُحفظ.',
                      'Recitation listens on this device only. Nothing is sent or kept.',
                    ),
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
          onPressed: () {},
          icon: const Icon(Icons.settings_outlined),
          label: Text(context.s('افتح إعدادات الجهاز', 'Open device settings')),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () {},
          child: Text(
            context.s(
              'اختبر حفظك باللمس بدلا من ذلك',
              'Test yourself by tapping instead',
            ),
          ),
        ),
      ],
    );
  }
}

/// The whole session screen, phone layout.
class SessionScreenMock extends StatelessWidget {
  const SessionScreenMock({
    super.key,
    required this.page,
    required this.state,
    required this.info,
    required this.bands,
    this.sheet,
  });

  final Widget page;
  final PanelState state;
  final SessionInfo info;
  final List<double> bands;

  /// A modal sheet over the screen (summary, first-use notice).
  final Widget? sheet;

  @override
  Widget build(BuildContext context) {
    final body = Scaffold(
      backgroundColor: context.t.bg,
      body: Column(
        children: [
          SafeArea(bottom: false, child: SessionTopBar(info: info)),
          Expanded(child: page),
          RecordingPanel(state: state, info: info, bands: bands),
        ],
      ),
    );
    if (sheet == null) return body;
    return Stack(
      children: [
        body,
        Positioned.fill(
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.38)),
        ),
        Align(alignment: Alignment.bottomCenter, child: sheet),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sheets
// ---------------------------------------------------------------------------

class SheetFrame extends StatelessWidget {
  const SheetFrame({super.key, required this.children, this.maxWidth = 560});

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Material(
        color: t.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: t.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _sectionLabel(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(
    text,
    style: TextStyle(
      color: context.t.goldText,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: context.ar ? 0 : 0.3,
    ),
  ),
);

class _Choice extends StatelessWidget {
  const _Choice(this.label, {this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      height: 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: selected ? t.control : t.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? t.control : t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? t.onControl : t.ink,
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented(this.options, this.selected, {this.icons = const []});

  final List<String> options;
  final int selected;
  final List<IconData> icons;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          for (final (i, o) in options.indexed)
            Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == selected ? t.paper : null,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: i == selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                  border: i == selected ? Border.all(color: t.border) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (i < icons.length) ...[
                      Icon(
                        icons[i],
                        size: 16,
                        color: i == selected ? t.control : t.muted,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      o,
                      style: TextStyle(
                        color: i == selected ? t.ink : t.muted,
                        fontSize: 13.5,
                        fontWeight: i == selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value, {this.flex = 1, this.stepper = false});

  final String label;
  final String value;
  final int flex;
  final bool stepper;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Expanded(
      flex: flex,
      child: Container(
        height: 54,
        padding: const EdgeInsetsDirectional.only(start: 12, end: 6),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: t.muted, fontSize: 11.5)),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (stepper)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.keyboard_arrow_up, size: 18, color: t.goldText),
                  Icon(Icons.keyboard_arrow_down, size: 18, color: t.goldText),
                ],
              )
            else
              Icon(Icons.unfold_more, size: 18, color: t.goldText),
          ],
        ),
      ),
    );
  }
}

/// The range modal: the eight kinds, the fields of the chosen kind, a live
/// summary, the mode and what a mistake does.
class SetupSheetMock extends StatelessWidget {
  const SetupSheetMock({
    super.key,
    required this.kind,
    required this.fields,
    required this.summary,
    required this.resume,
  });

  /// Index into the eight kinds.
  final int kind;
  final List<List<(String, String, bool)>> fields;
  final String summary;
  final String resume;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final kinds = context.ar
        ? [
            'سورة',
            'جزء',
            'حزب',
            'نصف حزب',
            'ربع حزب',
            '٣ أرباع حزب',
            'صفحات',
            'آيات',
          ]
        : [
            'Surah',
            'Juz',
            'Hizb',
            'Half hizb',
            'Quarter',
            '¾ hizb',
            'Pages',
            'Verses',
          ];
    return SheetFrame(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.s('تسميع جديد', 'New recitation'),
                style: TextStyle(
                  color: t.ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(Icons.close, color: t.muted),
          ],
        ),
        const SizedBox(height: 10),
        // Pick up where the last session ended.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: t.highlight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.history, size: 18, color: t.goldText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  resume,
                  style: TextStyle(
                    color: t.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                context.s('أكمل', 'Continue'),
                style: TextStyle(
                  color: t.goldText,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                context.ar ? Icons.chevron_left : Icons.chevron_right,
                size: 18,
                color: t.goldText,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionLabel(context, context.s('النطاق', 'Range')),
        for (var row = 0; row < 2; row++) ...[
          Row(
            children: [
              for (var i = row * 4; i < row * 4 + 4; i++) ...[
                Expanded(child: _Choice(kinds[i], selected: i == kind)),
                if (i % 4 != 3) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: 6),
        for (final row in fields) ...[
          Row(
            children: [
              for (final (i, (label, value, stepper)) in row.indexed) ...[
                _Field(label, value, flex: stepper ? 2 : 3, stepper: stepper),
                if (i < row.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Icon(Icons.auto_stories_outlined, size: 16, color: t.muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                summary,
                style: TextStyle(color: t.muted, fontSize: 12.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionLabel(context, context.s('الطريقة', 'Mode')),
        _Segmented(
          [
            context.s('متصل', 'Continuous'),
            context.s('آية بآية', 'Verse by verse'),
          ],
          0,
          icons: const [Icons.waves, Icons.format_list_numbered],
        ),
        const SizedBox(height: 12),
        _sectionLabel(context, context.s('عند الخطأ', 'On a mistake')),
        _Segmented([
          context.s('تابع وعلّمه', 'Mark and go on'),
          context.s('توقّف للتصحيح', 'Stop to correct'),
        ], 0),
        const SizedBox(height: 6),
        Text(
          context.s(
            'القيم الافتراضية من الإعدادات › التسميع',
            'Defaults come from Settings › Recitation',
          ),
          style: TextStyle(color: t.muted, fontSize: 11.5),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.mic),
          label: Text(context.s('ابدأ التسميع', 'Start reciting')),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            textStyle: TextStyle(
              fontFamily: Theme.of(context).textTheme.labelLarge?.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class SummaryRow {
  const SummaryRow(this.ayah, this.accuracy, this.excerpt, this.marks);

  final int ayah;
  final int accuracy;

  /// The verse's first words, as stored (Uthmani), from the content
  /// database.
  final String excerpt;

  /// Counts by state: wrong, skipped, corrected, doubtful, hint.
  final (int, int, int, int, int) marks;
}

class SummarySheetMock extends StatelessWidget {
  const SummarySheetMock({
    super.key,
    required this.title,
    required this.duration,
    required this.accuracy,
    required this.counts,
    required this.rows,
  });

  final String title;
  final String duration;
  final int accuracy;
  final (int, int, int, int, int) counts;
  final List<SummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.states;
    Widget chip(Color color, String label, int n, {bool dotted = false}) =>
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                '$label ${context.n(n)}',
                style: TextStyle(
                  color: t.ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
    final (wrong, skipped, corrected, doubtful, hint) = counts;
    return SheetFrame(
      children: [
        Row(
          children: [
            SizedBox.square(
              dimension: 84,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.square(
                    dimension: 84,
                    child: CircularProgressIndicator(
                      value: accuracy / 100,
                      strokeWidth: 7,
                      color: t.goldText,
                      backgroundColor: t.border,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.pct(accuracy),
                        style: TextStyle(
                          color: t.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        context.s('الدقة', 'accuracy'),
                        style: TextStyle(color: t.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.s('انتهى التسميع', 'Recitation finished'),
                    style: TextStyle(
                      color: t.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(title, style: TextStyle(color: t.ink, fontSize: 14)),
                  Text(
                    duration,
                    style: TextStyle(color: t.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            chip(c.wrong, context.s('خطأ', 'Wrong'), wrong),
            chip(c.skipped, context.s('متجاوزة', 'Skipped'), skipped),
            chip(c.corrected, context.s('صُحّحت', 'Corrected'), corrected),
            chip(c.hint, context.s('بتلميح', 'Hinted'), hint),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          context.s(
            'كلمات مشكوك فيها: ${context.n(doubtful)}، لم تُحسب عليك (سماع غير واضح).',
            '$doubtful words were unclear to the recogniser and did not count.',
          ),
          style: TextStyle(color: t.muted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        _sectionLabel(
          context,
          context.s('آيات تحتاج مراجعة', 'Verses to review'),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: t.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              for (final (i, r) in rows.indexed) ...[
                if (i > 0) Divider(height: 1, color: t.border),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: t.marker),
                        ),
                        child: Text(
                          context.n(r.ayah),
                          style: TextStyle(
                            color: t.ink,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                r.excerpt,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  color: t.ink,
                                  fontSize: 17,
                                  height: 1.6,
                                  fontFamily: 'KFGQPC Hafs Uthmanic Script',
                                ),
                              ),
                            ),
                            Text(' …', style: TextStyle(color: t.muted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      for (final (n, col) in [
                        (r.marks.$1, c.wrong),
                        (r.marks.$2, c.skipped),
                        (r.marks.$3, c.corrected),
                        (r.marks.$5, c.hint),
                      ])
                        if (n > 0)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 3),
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: col,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      const SizedBox(width: 6),
                      Text(
                        context.pct(r.accuracy),
                        style: TextStyle(
                          color: t.ink,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(
                        context.ar ? Icons.chevron_left : Icons.chevron_right,
                        color: t.muted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(context.s('تم', 'Done')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.replay),
                label: Text(
                  context.s('سمّع هذه الآيات ثانية', 'Recite these again'),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          context.s(
            'تُحفظ النتيجة في سجل التسميع. لا يُحفظ أي صوت.',
            'The result is kept in your recitation log. No audio is kept.',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(color: t.muted, fontSize: 11.5),
        ),
      ],
    );
  }
}

class FirstUseSheetMock extends StatelessWidget {
  const FirstUseSheetMock({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.states;
    Widget point(IconData icon, Color color, String title, String body) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: t.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      body,
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
        );
    return SheetFrame(
      children: [
        Icon(Icons.graphic_eq, size: 34, color: t.goldText),
        const SizedBox(height: 8),
        Text(
          context.s(
            'التسميع يختبر حفظك، لا تجويدك',
            'Recitation checks your memory, not your tajweed',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: t.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        point(
          Icons.spellcheck,
          c.corrected,
          context.s(
            'يتحقق من الكلمات وترتيبها',
            'It checks the words and their order',
          ),
          context.s(
            'هل قرأت ما في المصحف كلمة كلمة؟',
            'Did you read what is in the mushaf, word by word?',
          ),
        ),
        point(
          Icons.block,
          c.wrong,
          context.s(
            'لا يقيّم التجويد ولا أحكام الأداء',
            'It does not judge tajweed',
          ),
          context.s(
            'ولا المخارج ولا المدود ولا الوقف والابتداء.',
            'Nor makharij, madd, or where you stop and start.',
          ),
        ),
        point(
          Icons.lock_outline,
          t.goldText,
          context.s('يعمل على جهازك', 'It runs on your device'),
          context.s(
            'صوتك لا يُرسل إلى أي خادم ولا يُحفظ.',
            'Your voice is never sent anywhere or kept.',
          ),
        ),
        point(
          Icons.more_horiz,
          c.doubtful,
          context.s('قد يخطئ في السماع', 'It can mishear'),
          context.s(
            'الكلمة التي يشك فيها تُعلَّم بنقاط خفيفة ولا تُحسب عليك.',
            'A word it is unsure of gets a dotted line and does not count against you.',
          ),
        ),
        const SizedBox(height: 4),
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: Text(context.s('فهمت، ابدأ', 'Got it, start')),
        ),
        TextButton(
          onPressed: () {},
          child: Text(context.s('المزيد في المساعدة', 'More in Help')),
        ),
      ],
    );
  }
}

/// Model download: consent with size and attribution, or the download
/// under way.
class ModelSheetMock extends StatelessWidget {
  const ModelSheetMock({super.key, required this.attribution, this.progress});

  final String attribution;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    const totalMb = 132;
    Widget fact(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: t.goldText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: t.ink, fontSize: 13.5)),
          ),
        ],
      ),
    );
    return SheetFrame(
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: t.highlight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.download_for_offline_outlined,
                color: t.goldText,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.s('نموذج التسميع', 'Recitation model'),
                    style: TextStyle(
                      color: t.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    context.s(
                      '${context.n(totalMb)} م.ب · مرة واحدة',
                      '$totalMb MB · one time',
                    ),
                    style: TextStyle(color: t.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        fact(
          Icons.wifi_off,
          context.s('يعمل بعدها بلا إنترنت', 'Works offline afterwards'),
        ),
        fact(
          Icons.mic_none,
          context.s(
            'صوتك يبقى على جهازك، لا يُرسل ولا يُحفظ',
            'Your voice stays on this device',
          ),
        ),
        fact(
          Icons.delete_outline,
          context.s(
            'تحذفه متى شئت من الإعدادات › التسميع',
            'Remove it any time in Settings',
          ),
        ),
        const SizedBox(height: 4),
        if (progress == null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: t.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.s(
                      'التنزيل عبر Wi‑Fi فقط',
                      'Download on Wi‑Fi only',
                    ),
                    style: TextStyle(color: t.ink, fontSize: 13.5),
                  ),
                ),
                Switch(value: true, onChanged: (_) {}),
              ],
            ),
          )
        else ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: t.control,
              backgroundColor: t.border,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                context.s(
                  '${context.n((totalMb * progress!).round())} من ${context.n(totalMb)} م.ب',
                  '${(totalMb * progress!).round()} of $totalMb MB',
                ),
                style: TextStyle(color: t.ink, fontSize: 13),
              ),
              const Spacer(),
              Text(
                context.s('يكمل في الخلفية', 'Continues in the background'),
                style: TextStyle(color: t.muted, fontSize: 12),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: t.bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: t.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  attribution,
                  style: TextStyle(
                    color: t.muted,
                    fontSize: 11.5,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (progress == null)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text(context.s('ليس الآن', 'Not now')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: Text(
                    context.s(
                      'نزّل (${context.n(totalMb)} م.ب)',
                      'Download ($totalMb MB)',
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            ],
          )
        else
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: Text(context.s('إلغاء التنزيل', 'Cancel download')),
          ),
      ],
    );
  }
}

/// Laptop: the page in the middle, the recording panel beside it.
class LaptopSessionMock extends StatelessWidget {
  const LaptopSessionMock({
    super.key,
    required this.page,
    required this.info,
    required this.bands,
  });

  final Widget page;
  final SessionInfo info;
  final List<double> bands;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.states;
    return Scaffold(
      backgroundColor: t.bg,
      body: Column(
        children: [
          SessionTopBar(info: info),
          Expanded(
            child: Row(
              children: [
                const Spacer(),
                SizedBox(
                  width: 560,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: page,
                  ),
                ),
                const SizedBox(width: 28),
                SizedBox(
                  width: 340,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18, bottom: 18),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: t.paper,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: t.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          RecordingPanelBody(info: info, bands: bands),
                          const SizedBox(height: 18),
                          _sectionLabel(context, context.s('الآيات', 'Verses')),
                          Expanded(
                            child: ListView(
                              children: [
                                for (final (ayah, acc) in info.verseRows)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 64,
                                          child: Text(
                                            context.s(
                                              'الآية ${context.n(ayah)}',
                                              'Verse $ayah',
                                            ),
                                            style: TextStyle(
                                              color: ayah == info.currentAyah
                                                  ? t.goldText
                                                  : t.ink,
                                              fontSize: 13,
                                              fontWeight:
                                                  ayah == info.currentAyah
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: acc == null
                                                  ? 0
                                                  : acc / 100,
                                              minHeight: 6,
                                              color: acc == null || acc >= 90
                                                  ? t.goldText
                                                  : c.skipped,
                                              backgroundColor: t.border,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 46,
                                          child: Text(
                                            acc == null
                                                ? '–'
                                                : context.pct(acc),
                                            textAlign: TextAlign.end,
                                            style: TextStyle(
                                              color: acc == null
                                                  ? t.muted
                                                  : t.ink,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The panel's content without its sheet, for the laptop side column.
class RecordingPanelBody extends StatelessWidget {
  const RecordingPanelBody({
    super.key,
    required this.info,
    required this.bands,
  });

  final SessionInfo info;
  final List<double> bands;

  @override
  Widget build(BuildContext context) {
    final panel = RecordingPanel(
      state: PanelState.listening,
      info: info,
      bands: bands,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        panel._statusRow(context),
        const SizedBox(height: 14),
        SpectrumBars(bands: bands, height: 56),
        const SizedBox(height: 16),
        panel._controls(context, false),
      ],
    );
  }
}

/// One mode's state colours on its paper, with words from the page.
class PaletteCard extends StatelessWidget {
  const PaletteCard({super.key, required this.title, required this.sample});

  final String title;

  /// A real word of the page, drawn in each state.
  final String sample;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.states;
    Widget row(String label, Color color, {Widget? deco}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: TextStyle(color: t.muted, fontSize: 12)),
          ),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (deco != null) Positioned.fill(child: deco),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      sample,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        height: 1.5,
                        fontFamily: 'KFGQPC Hafs Uthmanic Script',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: t.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: t.goldText,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          row(context.s('صحيحة', 'Correct'), t.ink),
          row(context.s('خطأ', 'Wrong'), c.wrong),
          row(
            context.s('متجاوزة', 'Skipped'),
            c.skipped,
            deco: CustomPaint(painter: _DashedFrame(c.skipped)),
          ),
          row(context.s('صُحّحت بعد خطأ', 'Corrected'), c.corrected),
          row(
            context.s('مشكوك فيها', 'Unsure'),
            c.doubtful,
            deco: CustomPaint(painter: _DottedLine(c.doubtful)),
          ),
          row(context.s('كُشفت بتلميح', 'Hinted'), c.hint),
        ],
      ),
    );
  }
}

class _DashedFrame extends CustomPainter {
  _DashedFrame(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(2),
      const Radius.circular(6),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (final m in (Path()..addRRect(r)).computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 6) {
        canvas.drawPath(m.extractPath(d, d + 3.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedFrame old) => false;
}

class _DottedLine extends CustomPainter {
  _DottedLine(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (var x = 8.0; x < size.width - 6; x += 4.5) {
      canvas.drawCircle(Offset(x, size.height - 4), 1.1, p);
    }
  }

  @override
  bool shouldRepaint(_DottedLine old) => false;
}
