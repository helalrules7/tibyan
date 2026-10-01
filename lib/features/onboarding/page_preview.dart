import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/theme_tokens.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart';
import '../mushaf/presentation/widgets/theme_art.dart';

/// A real mushaf page (page 1, KFGQPC artwork, bundled) inside the chosen
/// style's frame and colours. Used on the first-launch style screen and in
/// the theme picker.
class RealPagePreview extends ConsumerWidget {
  const RealPagePreview({
    super.key,
    required this.style,
    required this.mode,
    required this.semanticLabel,
    this.width = 240,
  });

  final TibyanStyle style;
  final ThemeModeId mode;
  final String semanticLabel;
  final double width;

  /// A theme's frame is drawn at this size and scaled down, so a small
  /// preview shows it as it looks around a page.
  static const _artSize = Size(300, 390);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = style.modes[mode]!;
    final page = SvgPicture.asset(
      'assets/themes/preview_page001.svg',
      fit: BoxFit.contain,
      colorFilter: mode.isLight
          ? null
          : ColorFilter.mode(t.ink, BlendMode.srcIn),
    );
    final Widget body;
    if (style.art != null) {
      final art = ref
          .watch(themeArtProvider((style: style.id, mode: mode)))
          .value;
      final inset = art?.layout(_artSize).inset ?? style.art!.band;
      body = FittedBox(
        child: SizedBox.fromSize(
          size: _artSize,
          child: CustomPaint(
            painter: ArtFramePainter(art: art, paper: t.paper),
            child: Padding(padding: EdgeInsets.all(inset + 12), child: page),
          ),
        ),
      );
    } else {
      // Zakhrafa: its own illuminated frame, drawn at the same size.
      body = FittedBox(
        child: SizedBox.fromSize(
          size: _artSize,
          child: ZakhrafaFramePreview(
            paper: t.paper,
            rule: t.marker,
            child: Padding(padding: const EdgeInsets.all(6), child: page),
          ),
        ),
      );
    }
    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(width: width, height: width * 1.3, child: body),
    );
  }
}
