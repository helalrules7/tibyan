import 'package:flutter/material.dart';

import 'contrast.dart';
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
    this.elderly = false,
  });

  final TibyanStyle style;
  final ThemeModeId mode;
  final ModeTokens colors;

  /// Elderly mode is on: larger targets and stronger contrast.
  final bool elderly;

  @override
  TibyanTokens copyWith({
    TibyanStyle? style,
    ThemeModeId? mode,
    ModeTokens? colors,
    bool? elderly,
  }) => TibyanTokens(
    style: style ?? this.style,
    mode: mode ?? this.mode,
    colors: colors ?? this.colors,
    elderly: elderly ?? this.elderly,
  );

  @override
  TibyanTokens lerp(ThemeExtension<TibyanTokens>? other, double t) =>
      t < 0.5 ? this : (other as TibyanTokens? ?? this);
}

extension TibyanThemeX on BuildContext {
  TibyanTokens get tokens => Theme.of(this).extension<TibyanTokens>()!;
}

/// Smallest touch target in elderly mode (logical pixels).
const elderlyTarget = 56.0;

/// Text is never smaller than this factor in elderly mode.
const elderlyTextScale = 1.25;

/// A mode's colours with stronger contrast, for elderly mode: secondary
/// text, gold text and markers reach 7:1 against the paper and the
/// screen, hairlines 3:1, controls 4.5:1 and what is drawn on them 7:1.
/// The theme keeps its character; only colours below these move, toward
/// the ink (or black or white on a control).
ModeTokens elderlyTokens(ModeTokens t) {
  final grounds = [t.paper, t.bg];
  final (control, onControl) = strongPair(
    towardContrast(t.control, t.ink, grounds, 4.5),
    t.onControl,
    7,
  );
  final (accent, accentFg) = strongPair(
    towardContrast(t.accent, t.ink, grounds, 4.5),
    t.accentFg,
    7,
  );
  final (player, playerFg) = strongPair(t.player, t.playerFg, 7);
  final (headBg, headFg) = strongPair(t.headBg, t.headFg, 7);
  return ModeTokens(
    bg: t.bg,
    paper: t.paper,
    ink: towardContrast(t.ink, extremeAgainst(t.paper), grounds, 7),
    muted: towardContrast(t.muted, t.ink, grounds, 7),
    border: towardContrast(t.border, t.ink, grounds, 3),
    frame: t.frame,
    marker: towardContrast(t.marker, t.ink, [t.paper], 4.5),
    goldText: towardContrast(t.goldText, t.ink, grounds, 7),
    headBg: headBg,
    headFg: headFg,
    accent: accent,
    accentFg: accentFg,
    player: player,
    playerFg: playerFg,
    highlight: t.highlight,
    control: control,
    onControl: onControl,
  );
}

/// Elderly mode's page transition: a plain cross-fade, slower than the
/// default, so the change of screen is easy to follow.
class ElderlyPageTransitionsBuilder extends PageTransitionsBuilder {
  const ElderlyPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 550);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 450);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
    child: child,
  );
}

/// Builds Material [ThemeData] from one style and one mode. [elderly]
/// gives elderly mode's stronger colours and larger targets.
ThemeData buildTheme({
  required TibyanStyle style,
  required ThemeModeId mode,
  required UiFont uiFont,
  bool elderly = false,
}) {
  final base0 = style.modes[mode]!;
  final t = elderly ? elderlyTokens(base0) : base0;
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

  const target = Size(elderlyTarget, elderlyTarget);
  const wide = Size(88, elderlyTarget);
  final themed = base.copyWith(
    extensions: [
      TibyanTokens(style: style, mode: mode, colors: t, elderly: elderly),
    ],
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
  if (!elderly) return themed;
  const transitions = ElderlyPageTransitionsBuilder();
  return themed.copyWith(
    visualDensity: VisualDensity.standard,
    iconTheme: themed.iconTheme.copyWith(size: 28),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: target, iconSize: 28),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: t.control,
        foregroundColor: t.onControl,
        minimumSize: wide,
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: t.control,
        minimumSize: wide,
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.control,
        minimumSize: wide,
        side: BorderSide(color: t.control, width: 1.5),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(minimumSize: target),
    ),
    listTileTheme: themed.listTileTheme.copyWith(
      minTileHeight: 64,
      minLeadingWidth: 32,
    ),
    sliderTheme: themed.sliderTheme.copyWith(
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
      trackHeight: 6,
    ),
    dividerTheme: DividerThemeData(color: t.border, space: 1, thickness: 1.5),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: transitions,
        TargetPlatform.iOS: transitions,
        TargetPlatform.macOS: transitions,
        TargetPlatform.linux: transitions,
        TargetPlatform.windows: transitions,
        TargetPlatform.fuchsia: transitions,
      },
    ),
  );
}
