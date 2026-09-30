import 'dart:ui';

/// A visual style loaded from `assets/themes/<id>.json`: Zakhrafa, drawn
/// by the app, and the heritage themes, whose frame, surah header and
/// verse marker are SVG art ([art]). Adding a style means adding a JSON
/// file (and its art), not code.
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
    this.art,
    this.opening,
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

  /// The theme's frame, surah header and verse marker; null for Zakhrafa,
  /// which keeps its own illuminated frame.
  final ThemeArt? art;

  /// Asset of the frame drawn around the opening pages (al-Fatiha, the
  /// start of al-Baqarah) and the cover: a picture with a transparent
  /// panel for the page and two cartouches; see [OpeningArtLayout].
  final String? opening;

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
      art: json['art'] == null
          ? null
          : ThemeArt.fromJson(json['art'] as Map<String, dynamic>),
      opening: json['opening'] as String?,
    );
  }
}

/// A theme's art: SVG files in `assets/themes/` (from quran-assets, drawn
/// as they are) and, per mode, the colour of each class of the art. Only
/// the fill of a `class="cN"` group and the stroke of the `class="line"`
/// group change; classes not listed keep their drawn colour.
class ThemeArt {
  const ThemeArt({
    required this.frame,
    required this.header,
    required this.marker,
    required this.band,
    required this.colours,
  });

  final ArtFrameFiles frame;

  /// Surah header; its name box is the SVG's `data-slot`.
  final String header;

  /// Verse-end marker; its number box is the SVG's `data-slot`.
  final String marker;

  /// Depth of the frame's edge on screen (px).
  final double band;

  final Map<ThemeModeId, ArtColours> colours;

  factory ThemeArt.fromJson(Map<String, dynamic> json) {
    final frame = json['frame'] as Map<String, dynamic>;
    final modes = json['modes'] as Map<String, dynamic>;
    return ThemeArt(
      frame: ArtFrameFiles.fromJson(frame),
      header: json['header'] as String,
      marker: json['marker'] as String,
      band: (frame['band'] as num).toDouble(),
      colours: {
        for (final mode in ThemeModeId.values)
          mode: ArtColours.fromJson(modes[mode.name] as Map<String, dynamic>),
      },
    );
  }
}

/// A frame cut into slices (the top-left corner, one repeat of the top
/// edge and one of the left edge), or drawn whole when it has none.
class ArtFrameFiles {
  const ArtFrameFiles.slices({
    required String this.corner,
    required String this.edgeH,
    required String this.edgeV,
  }) : whole = null;

  const ArtFrameFiles.whole(String this.whole)
    : corner = null,
      edgeH = null,
      edgeV = null;

  final String? corner;
  final String? edgeH;
  final String? edgeV;
  final String? whole;

  List<String> get files =>
      whole != null ? [whole!] : [corner!, edgeH!, edgeV!];

  factory ArtFrameFiles.fromJson(Map<String, dynamic> json) =>
      json['whole'] != null
      ? ArtFrameFiles.whole(json['whole'] as String)
      : ArtFrameFiles.slices(
          corner: json['corner'] as String,
          edgeH: json['edgeH'] as String,
          edgeV: json['edgeV'] as String,
        );
}

/// Class colours of the frame, header and marker in one mode.
class ArtColours {
  const ArtColours({
    required this.frame,
    required this.header,
    required this.marker,
  });

  final Map<String, Color> frame;
  final Map<String, Color> header;
  final Map<String, Color> marker;

  factory ArtColours.fromJson(Map<String, dynamic> json) {
    Map<String, Color> map(String key) => {
      for (final e in (json[key] as Map<String, dynamic>? ?? const {}).entries)
        e.key: parseHexColor(e.value as String),
    };
    return ArtColours(
      frame: map('frame'),
      header: map('header'),
      marker: map('marker'),
    );
  }
}

/// The colour modes every style must define. Bright white is a light mode
/// whose screen and paper are pure white.
enum ThemeModeId {
  light,
  white,
  night,
  black;

  /// Dark ink on a light paper (light and bright white).
  bool get isLight => this == light || this == white;
}

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
    required this.control,
    required this.onControl,
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

  /// Selected state of controls (radio, switch, check box, filled button,
  /// progress). Must be at least 3:1 against paper and background.
  final Color control;

  /// Text and icons drawn on [control]. Must be at least 4.5:1 against it.
  final Color onControl;

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
      control: c('control'),
      onControl: c('onControl'),
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
