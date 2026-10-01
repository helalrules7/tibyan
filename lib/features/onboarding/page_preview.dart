import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_graphics/vector_graphics.dart';

import '../../core/theme/theme_tokens.dart';
import '../mushaf/data/compiled_svg.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart';
import '../mushaf/presentation/widgets/theme_art.dart';

/// The artwork used for every preview: a real mushaf page (page 1, KFGQPC,
/// bundled).
const _pageAsset = 'assets/themes/preview_page001.svg';

/// It is 185 KB of SVG, and the theme picker shows it once per style. Parsed
/// per card this cost 115 ms a card on the UI isolate — a measured second for
/// the picker's nine cards. Compiled once here, on the worker isolates, and
/// the ink colour is applied over it as a paint-time filter instead, so one
/// picture serves every style and mode.
Future<PictureInfo> _pageOne(Ref ref) async {
  final svg = await rootBundle.loadString(_pageAsset);
  return compiledSvgPicture(svg, name: 'preview page 1');
}

final _pageOneProvider = FutureProvider<PictureInfo>(_pageOne);

/// A real mushaf page inside the chosen style's frame and colours. Used on
/// the first-launch style screen and in the theme picker.
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
    final page = CustomPaint(
      painter: PreviewPagePainter(ref.watch(_pageOneProvider).value),
      child: const SizedBox.expand(),
    );
    final inked = mode.isLight
        ? page
        : ColorFiltered(
            colorFilter: ColorFilter.mode(t.ink, BlendMode.srcIn),
            child: page,
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
            child: Padding(padding: EdgeInsets.all(inset + 12), child: inked),
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
            child: Padding(padding: const EdgeInsets.all(6), child: inked),
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

/// Draws the preview page into whatever box it is given, as `BoxFit.contain`
/// would.
class PreviewPagePainter extends CustomPainter {
  const PreviewPagePainter(this.page);

  /// Null until the artwork has been compiled, which is off the UI isolate.
  final PictureInfo? page;

  @override
  void paint(Canvas canvas, Size size) {
    final info = page;
    if (info == null) return;
    final fitted = applyBoxFit(BoxFit.contain, info.size, size);
    final box = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    canvas
      ..save()
      ..translate(box.left, box.top)
      ..scale(
        fitted.destination.width / info.size.width,
        fitted.destination.height / info.size.height,
      )
      ..drawPicture(info.picture)
      ..restore();
  }

  @override
  bool shouldRepaint(PreviewPagePainter old) => old.page != page;

  @override
  bool hitTest(ui.Offset position) => false;
}
