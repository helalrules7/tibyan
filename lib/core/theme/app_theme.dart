import 'package:flutter/material.dart';

import 'theme_tokens.dart';

/// Interface font families the user can choose in settings.
enum UiFont {
  plex('IBMPlexSansArabic'),
  kfgqpcAn('KFGQPCAN'),
  changa('Changa');

  const UiFont(this.family);
  final String family;
}

/// Theme values that Material's [ColorScheme] has no slot for.
/// Widgets read these instead of hard-coding colours.
class TibyanTokens extends ThemeExtension<TibyanTokens> {
  const TibyanTokens({
    required this.style,
    required this.mode,
    required this.colors,
  });

  final TibyanStyle style;
  final ThemeModeId mode;
  final ModeTokens colors;

  @override
  TibyanTokens copyWith({
    TibyanStyle? style,
    ThemeModeId? mode,
    ModeTokens? colors,
  }) => TibyanTokens(
    style: style ?? this.style,
    mode: mode ?? this.mode,
    colors: colors ?? this.colors,
  );

  @override
  TibyanTokens lerp(ThemeExtension<TibyanTokens>? other, double t) =>
      t < 0.5 ? this : (other as TibyanTokens? ?? this);
}

extension TibyanThemeX on BuildContext {
  TibyanTokens get tokens => Theme.of(this).extension<TibyanTokens>()!;
}

/// Builds Material [ThemeData] from one style and one mode.
ThemeData buildTheme({
  required TibyanStyle style,
  required ThemeModeId mode,
  required UiFont uiFont,
}) {
  final t = style.modes[mode]!;
  final brightness = mode.isLight ? Brightness.light : Brightness.dark;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: t.control,
    onPrimary: t.onControl,
    secondary: t.goldText,
    onSecondary: t.paper,
    tertiary: t.accent,
    onTertiary: t.accentFg,
    error: brightness == Brightness.light
        ? const Color(0xFF9B2C1F)
        : const Color(0xFFF2B2A6),
    onError: brightness == Brightness.light
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF3A0B05),
    surface: t.paper,
    onSurface: t.ink,
    onSurfaceVariant: t.muted,
    outline: t.border,
    outlineVariant: t.border,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor: t.bg,
    fontFamily: uiFont.family,
    fontFamilyFallback: const ['IBMPlexSansArabic', 'IBMPlexSans'],
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );

  return base.copyWith(
    extensions: [TibyanTokens(style: style, mode: mode, colors: t)],
    appBarTheme: AppBarTheme(
      backgroundColor: t.bg,
      foregroundColor: t.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: t.paper,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(style.radii.card),
        side: BorderSide(color: t.border),
      ),
    ),
    dividerTheme: DividerThemeData(color: t.border, space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: t.goldText,
      textColor: t.ink,
      minVerticalPadding: 12,
    ),
    // Selected states use the dedicated control colour, never the surah
    // header colour (which is white or near the paper colour in some styles).
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? t.control : t.muted,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? t.control : null,
      ),
      checkColor: WidgetStatePropertyAll(t.onControl),
      side: BorderSide(color: t.muted, width: 2),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? t.onControl : t.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? t.control : t.paper,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? t.control : t.muted,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: t.control,
      linearTrackColor: t.border,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: t.control,
        foregroundColor: t.onControl,
        minimumSize: const Size(48, 48),
      ),
    ),
  );
}
