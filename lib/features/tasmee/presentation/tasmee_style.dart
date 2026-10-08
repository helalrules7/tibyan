import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_tokens.dart';
import '../../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;

/// The word-state colours of the tasmee, drawn on the word's own letters,
/// per mode. Correct words keep the page's ink.
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

  /// Read wrongly or passed over, then read correctly: a calm green.
  final Color corrected;
  final Color doubtful;

  /// Shown by the hint button.
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

extension TasmeeContext on BuildContext {
  TasmeeStateColors get tasmeeColors =>
      TasmeeStateColors.of(tokens.mode, tokens.colors);

  /// A whole number in the interface's digits.
  String digits(int v) => NumberFormatter(Localizations.localeOf(this))(v);

  /// A percentage in the interface's digits and sign.
  String percent(int v) => Localizations.localeOf(this).languageCode == 'ar'
      ? '${digits(v)}٪'
      : '$v%';

  /// mm:ss in the interface's digits.
  String clock(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return NumberFormatter(Localizations.localeOf(this)).decimal('$m:$s');
  }
}

/// A round control with its label under it (the panel's buttons).
class TasmeeRoundButton extends StatelessWidget {
  const TasmeeRoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.size = 48,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    final c = t.control;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Column(
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
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                child: SizedBox.square(
                  dimension: size,
                  child: Icon(
                    icon,
                    color: filled ? t.onControl : c,
                    size: size * 0.46,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: t.muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A rounded strip with an icon, a line of text and an optional action
/// (a verse's result, the stop-to-correct notice).
class TasmeeBanner extends StatelessWidget {
  const TasmeeBanner({
    super.key,
    required this.color,
    required this.icon,
    required this.text,
    this.action,
    this.onAction,
  });

  final Color color;
  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 34),
        padding: const EdgeInsetsDirectional.only(start: 10, end: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
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
                maxLines: 2,
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
                onPressed: onAction,
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
      ),
    );
  }
}

/// The small gold heading over a group of fields.
class TasmeeSectionLabel extends StatelessWidget {
  const TasmeeSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: TextStyle(
          color: context.tokens.colors.goldText,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

/// A bottom sheet's frame: paper, rounded top, a grab handle.
class TasmeeSheetFrame extends StatelessWidget {
  const TasmeeSheetFrame({
    super.key,
    required this.children,
    this.maxWidth = 560,
  });

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Material(
          color: t.paper,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
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
      ),
    );
  }
}
