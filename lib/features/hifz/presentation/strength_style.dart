import 'package:flutter/material.dart';

import '../../../core/theme/theme_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/strength.dart';

/// The four strength colours step in lightness as well as hue (light mode:
/// light for weak, dark for strong; the other modes the reverse), so they
/// stay apart for colour-blind readers and in greyscale. Each cell also
/// carries [StrengthBars] and a spoken label.
Color strengthFill(Strength s, ThemeModeId mode) {
  final light = mode == ThemeModeId.light;
  return switch (s) {
    Strength.none => Colors.transparent,
    Strength.weak => light ? const Color(0xFFF7D9CB) : const Color(0xFF5C2A1E),
    Strength.fair => light ? const Color(0xFFEBB65E) : const Color(0xFF8C6418),
    Strength.good => light ? const Color(0xFF4C9A76) : const Color(0xFF3F9A72),
    Strength.strong =>
      light ? const Color(0xFF1B5640) : const Color(0xFF9BE0BC),
  };
}

/// Text and marks drawn on a strength fill.
Color strengthInk(Strength s, ThemeModeId mode, Color ink) {
  if (s == Strength.none) return ink;
  return strengthFill(s, mode).computeLuminance() > 0.3
      ? const Color(0xFF1A1A1A)
      : Colors.white;
}

String strengthLabel(AppLocalizations l, Strength s) => switch (s) {
  Strength.none => l.strengthNone,
  Strength.weak => l.strengthWeak,
  Strength.fair => l.strengthFair,
  Strength.good => l.strengthGood,
  Strength.strong => l.strengthStrong,
};

/// The strength as one to four rising bars, readable without colour.
class StrengthBars extends StatelessWidget {
  const StrengthBars({
    super.key,
    required this.strength,
    required this.color,
    this.height = 8,
  });

  final Strength strength;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 1; i <= 4; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 0.75),
            width: height * 0.32,
            height: height * (0.4 + 0.15 * i),
            decoration: BoxDecoration(
              color: i <= strength.level ? color : null,
              border: i <= strength.level
                  ? null
                  : Border.all(
                      color: color.withValues(alpha: 0.45),
                      width: 0.6,
                    ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
      ],
    ),
  );
}
