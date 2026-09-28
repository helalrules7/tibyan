import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/db/content_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../mushaf_providers.dart';

/// Identifies a verse.
typedef VerseKey = ({int surah, int ayah});

/// One page of the new Madina edition: the KFGQPC page artwork (unchanged),
/// coloured for the current mode, with the selected verse highlighted.
class MushafPage extends ConsumerStatefulWidget {
  const MushafPage({
    super.key,
    required this.page,
    required this.selected,
    required this.onVerseTap,
    required this.onBackgroundTap,
  });

  final int page;
  final VerseKey? selected;
  final ValueChanged<VerseKey> onVerseTap;
  final VoidCallback onBackgroundTap;

  @override
  ConsumerState<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends ConsumerState<MushafPage> {
  late Future<(String, List<AyahPolygonRow>)> _load;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  @override
  void didUpdateWidget(MushafPage old) {
    super.didUpdateWidget(old);
    if (old.page != widget.page) _load = _fetch();
  }

  Future<(String, List<AyahPolygonRow>)> _fetch() async {
    final svg = await ref.read(pageStoreProvider).svg(widget.page);
    final polys = await ref
        .read(mushafRepositoryProvider)
        .polygons(widget.page);
    return (svg, polys);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return FutureBuilder(
      future: _load,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final (svg, polys) = snap.data!;
        final viewBox = _viewBox(svg);
        final outlines = [
          for (final p in polys)
            (key: (surah: p.surah, ayah: p.number), path: parseOutline(p.path)),
        ];
        return Center(
          child: AspectRatio(
            aspectRatio: viewBox.width / viewBox.height,
            child: LayoutBuilder(
              builder: (context, box) {
                final scale = box.maxWidth / viewBox.width;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) {
                    final point = d.localPosition / scale;
                    for (final o in outlines) {
                      if (o.path.contains(point)) {
                        widget.onVerseTap(o.key);
                        return;
                      }
                    }
                    widget.onBackgroundTap();
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Semantics(
                        label: AppLocalizations.of(context)
                            .pageOf('${widget.page}'),
                        image: true,
                        child: SvgPicture.string(
                          svg,
                          fit: BoxFit.contain,
                          colorFilter: tokens.mode == ThemeModeId.light
                              ? null
                              : ColorFilter.mode(
                                  tokens.colors.ink,
                                  BlendMode.srcIn,
                                ),
                        ),
                      ),
                      if (widget.selected != null)
                        IgnorePointer(
                          child: CustomPaint(
                            painter: _HighlightPainter(
                              paths: [
                                for (final o in outlines)
                                  if (o.key == widget.selected) o.path,
                              ],
                              scale: scale,
                              color: tokens.colors.highlight,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  static Size _viewBox(String svg) {
    final m = RegExp(r'viewBox="([\d.\s-]+)"').firstMatch(svg);
    if (m == null) return const Size(345, 550);
    final v = m
        .group(1)!
        .trim()
        .split(RegExp(r'\s+'))
        .map(double.parse)
        .toList();
    return Size(v[2], v[3]);
  }
}

/// Parses the outline format of the verse polygons: "M x y L x y ... Z",
/// possibly several sub-paths.
Path parseOutline(String d) {
  final path = Path();
  final tokens = d.trim().split(RegExp(r'\s+'));
  var i = 0;
  while (i < tokens.length) {
    final t = tokens[i];
    if (t == 'M' || t == 'L') {
      final x = double.parse(tokens[i + 1]);
      final y = double.parse(tokens[i + 2]);
      t == 'M' ? path.moveTo(x, y) : path.lineTo(x, y);
      i += 3;
    } else if (t == 'Z') {
      path.close();
      i += 1;
    } else {
      i += 1;
    }
  }
  return path;
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter({
    required this.paths,
    required this.scale,
    required this.color,
  });

  final List<Path> paths;
  final double scale;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale);
    final paint = Paint()..color = color;
    for (final p in paths) {
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(_HighlightPainter old) =>
      old.paths != paths || old.scale != scale || old.color != color;
}
