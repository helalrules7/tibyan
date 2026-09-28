import 'dart:ui';

/// A visual style (Classic, Manuscript, Royal, Calm) loaded from
/// `assets/themes/<id>.json`. Adding a style means adding a JSON file,
/// not code.
class TibyanStyle {
  const TibyanStyle({
    required this.id,
    required this.version,
    required this.name,
    required this.description,
    required this.surahHeaderFont,
    required this.frame,
    required this.ornaments,
    required this.radii,
    required this.modes,
  });

  final String id;
  final int version;
  final Map<String, String> name;
  final Map<String, String> description;
  final String surahHeaderFont;
  final FrameSpec frame;
  final OrnamentSpec ornaments;
  final RadiiSpec radii;
  final Map<ThemeModeId, ModeTokens> modes;

  String localizedName(String languageCode) =>
      name[languageCode] ?? name['ar'] ?? id;

  String localizedDescription(String languageCode) =>
      description[languageCode] ?? description['ar'] ?? '';

  factory TibyanStyle.fromJson(Map<String, dynamic> json) {
    final modesJson = json['modes'] as Map<String, dynamic>;
    return TibyanStyle(
      id: json['id'] as String,
      version: json['version'] as int,
      name: Map<String, String>.from(json['name'] as Map),
      description: Map<String, String>.from(json['description'] as Map),
      surahHeaderFont: (json['fonts'] as Map)['surahHeader'] as String,
      frame: FrameSpec.fromJson(json['frame'] as Map<String, dynamic>),
      ornaments: OrnamentSpec.fromJson(
        json['ornaments'] as Map<String, dynamic>,
      ),
      radii: RadiiSpec.fromJson(json['radii'] as Map<String, dynamic>),
      modes: {
        for (final mode in ThemeModeId.values)
          mode: ModeTokens.fromJson(
            modesJson[mode.name] as Map<String, dynamic>,
          ),
      },
    );
  }
}

/// The three colour modes every style must define.
enum ThemeModeId { light, night, black }

class ModeTokens {
  const ModeTokens({
    required this.bg,
    required this.paper,
    required this.ink,
    required this.muted,
    required this.border,
    required this.frame,
    required this.marker,
    required this.goldText,
    required this.headBg,
    required this.headFg,
    required this.accent,
    required this.accentFg,
    required this.player,
    required this.playerFg,
    required this.highlight,
  });

  /// Screen background.
  final Color bg;

  /// Mushaf paper and cards.
  final Color paper;

  /// Quran text and primary text.
  final Color ink;

  /// Secondary interface text.
  final Color muted;

  /// Hairlines and card borders.
  final Color border;

  /// Decorative page frame (not required to meet contrast).
  final Color frame;

  /// Verse markers (must be at least 3:1 against paper).
  final Color marker;

  /// Gold-coloured text (labels, numbers).
  final Color goldText;

  /// Surah header band background and foreground.
  final Color headBg;
  final Color headFg;

  /// Accent button background and foreground.
  final Color accent;
  final Color accentFg;

  /// Audio player bar background and foreground.
  final Color player;
  final Color playerFg;

  /// Selected-verse highlight (translucent).
  final Color highlight;

  factory ModeTokens.fromJson(Map<String, dynamic> json) {
    Color c(String key) => parseHexColor(json[key] as String);
    return ModeTokens(
      bg: c('bg'),
      paper: c('paper'),
      ink: c('ink'),
      muted: c('muted'),
      border: c('border'),
      frame: c('frame'),
      marker: c('marker'),
      goldText: c('goldText'),
      headBg: c('headBg'),
      headFg: c('headFg'),
      accent: c('accent'),
      accentFg: c('accentFg'),
      player: c('player'),
      playerFg: c('playerFg'),
      highlight: c('highlight'),
    );
  }
}

class FrameSpec {
  const FrameSpec({
    required this.outerWidth,
    required this.outerStyle,
    required this.innerWidth,
    required this.gap,
    required this.radius,
    required this.innerRadius,
    required this.corner,
  });

  final double outerWidth;

  /// `solid` or `double`.
  final String outerStyle;
  final double innerWidth;
  final double gap;
  final double radius;
  final double innerRadius;

  /// Corner ornament: `star8` or `none`.
  final String corner;

  factory FrameSpec.fromJson(Map<String, dynamic> json) => FrameSpec(
    outerWidth: (json['outerWidth'] as num).toDouble(),
    outerStyle: json['outerStyle'] as String,
    innerWidth: (json['innerWidth'] as num).toDouble(),
    gap: (json['gap'] as num).toDouble(),
    radius: (json['radius'] as num).toDouble(),
    innerRadius: (json['innerRadius'] as num).toDouble(),
    corner: json['corner'] as String,
  );
}

class OrnamentSpec {
  const OrnamentSpec({
    required this.surahHeader,
    required this.ayahMarker,
    required this.density,
  });

  final String surahHeader;
  final String ayahMarker;

  /// `minimal`, `medium` or `rich`.
  final String density;

  factory OrnamentSpec.fromJson(Map<String, dynamic> json) => OrnamentSpec(
    surahHeader: json['surahHeader'] as String,
    ayahMarker: json['ayahMarker'] as String,
    density: json['density'] as String,
  );
}

class RadiiSpec {
  const RadiiSpec({
    required this.card,
    required this.sheet,
    required this.chip,
    required this.surahHeader,
  });

  final double card;
  final double sheet;
  final double chip;
  final double surahHeader;

  factory RadiiSpec.fromJson(Map<String, dynamic> json) => RadiiSpec(
    card: (json['card'] as num).toDouble(),
    sheet: (json['sheet'] as num).toDouble(),
    chip: (json['chip'] as num).toDouble(),
    surahHeader: (json['surahHeader'] as num).toDouble(),
  );
}

/// Parses `#RRGGBB` or `#RRGGBBAA`.
Color parseHexColor(String hex) {
  final value = hex.replaceFirst('#', '');
  if (value.length == 6) {
    return Color(int.parse('FF$value', radix: 16));
  }
  if (value.length == 8) {
    final rgb = value.substring(0, 6);
    final alpha = value.substring(6, 8);
    return Color(int.parse('$alpha$rgb', radix: 16));
  }
  throw FormatException('Invalid colour: $hex');
}
