import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/db/content_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../mushaf_providers.dart';
import 'page_interaction.dart';

/// Identifies a verse.
typedef VerseKey = ({int surah, int ayah});

/// One page of the new Madina edition: the KFGQPC page artwork (unchanged),
/// coloured for the current mode, with the selection, marked verse
/// markers and selection handles drawn over it.
class MushafPage extends ConsumerStatefulWidget {
  const MushafPage({super.key, required this.page, required this.interaction});

  final int page;
  final PageInteraction interaction;

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
    final x = widget.interaction;
    final l = AppLocalizations.of(context);
    return FutureBuilder(
      future: _load,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final (svg, polys) = snap.data!;
        final viewBox = _viewBox(svg);
        final verses = [
          for (final p in polys)
            (
              key: (surah: p.surah, ayah: p.number),
              path: parseOutline(p.path),
              rects: outlineRects(p.path),
              marker: p.markerX == null ? null : Offset(p.markerX!, p.markerY!),
            ),
        ];
        VerseKey? verseAt(Offset point) {
          for (final v in verses) {
            if (v.path.contains(point)) return v.key;
          }
          return null;
        }

        VerseKey? markerAt(Offset point) {
          for (final v in verses) {
            final m = v.marker;
            if (m != null && (m - point).distance <= _markerRadius + 3) {
              return v.key;
            }
          }
          return null;
        }

        return Center(
          child: AspectRatio(
            aspectRatio: viewBox.width / viewBox.height,
            child: LayoutBuilder(
              builder: (context, box) {
                final scale = box.maxWidth / viewBox.width;
                final selected = [
                  for (final v in verses)
                    if (x.selection.contains(v.key)) v,
                ];
                final handles = <Widget>[];
                if (selected.isNotEmpty) {
                  // Right-to-left: the selection starts at the top right of
                  // its first verse and ends at the bottom left of its last.
                  final first = selected.first.rects.first;
                  final last = selected.last.rects.last;
                  final box0 = context.findRenderObject();
                  void drag(bool start, Offset global) {
                    final ro = box0 is RenderBox
                        ? box0
                        : context.findRenderObject() as RenderBox?;
                    if (ro == null) return;
                    final v = verseAt(ro.globalToLocal(global) / scale);
                    if (v != null) x.onHandleDrag(start, v);
                  }

                  handles
                    ..add(
                      Positioned(
                        left: first.right * scale - 22,
                        top: first.top * scale - 34,
                        child: SelectionHandle(
                          start: true,
                          label: l.selectionStart,
                          onDrag: (g) => drag(true, g),
                        ),
                      ),
                    )
                    ..add(
                      Positioned(
                        left: last.left * scale - 22,
                        top: last.bottom * scale - 10,
                        child: SelectionHandle(
                          start: false,
                          label: l.selectionEnd,
                          onDrag: (g) => drag(false, g),
                        ),
                      ),
                    );
                }
                final look = x.markerLook;
                final transform = Matrix4.diagonal3Values(scale, scale, 1);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (look != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _CallbackPainter((canvas) {
                              canvas.transform(transform.storage);
                              for (final v in verses) {
                                if (v.marker != null) {
                                  look.paintUnder(
                                    canvas,
                                    v.marker!,
                                    _markerRadius,
                                  );
                                }
                              }
                            }),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (d) {
                          final point = d.localPosition / scale;
                          if (x.hidden != null) {
                            final v = verseAt(point);
                            if (v != null && x.hidden!.contains(v)) {
                              x.onHiddenTap?.call(v);
                              return;
                            }
                          }
                          final m = markerAt(point);
                          m != null ? x.onMarkerTap(m) : x.onTap();
                        },
                        onLongPressStart: (d) {
                          final v = verseAt(d.localPosition / scale);
                          if (v != null) x.onVerseLongPress(v);
                        },
                        child: Semantics(
                          label: l.pageOf('${widget.page}'),
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
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: SelectionPainter(
                            paths: [for (final v in selected) v.path],
                            rings: [
                              for (final v in verses)
                                if (v.marker != null &&
                                    x.marks.containsKey(v.key))
                                  (v.marker!, _markerRadius, x.marks[v.key]!),
                            ],
                            highlight: tokens.colors.highlight,
                            transform: Matrix4.diagonal3Values(scale, scale, 1),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _CallbackPainter((canvas) {
                            canvas.transform(transform.storage);
                            if (look != null) {
                              for (final v in verses) {
                                if (v.marker != null) {
                                  look.paintOver(
                                    canvas,
                                    v.marker!,
                                    _markerRadius,
                                    v.key.ayah,
                                  );
                                }
                              }
                            }
                            final hidden = x.hidden;
                            if (hidden != null) {
                              final cover = Paint()
                                ..color = tokens.colors.paper;
                              final line = Paint()
                                ..color = tokens.colors.border
                                ..strokeWidth = 1.2;
                              for (final v in verses) {
                                if (!hidden.contains(v.key)) continue;
                                canvas.drawPath(v.path, cover);
                                for (final r in v.rects) {
                                  canvas.drawLine(
                                    Offset(r.left + 4, r.center.dy),
                                    Offset(r.right - 4, r.center.dy),
                                    line,
                                  );
                                }
                              }
                            }
                          }),
                        ),
                      ),
                    ),
                    ...handles,
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Verse-end marker radius in page units.
  static const _markerRadius = 7.5;

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

/// Bounds of each sub-path of a verse outline, in reading order.
List<Rect> outlineRects(String d) {
  final rects = <Rect>[];
  final tokens = d.trim().split(RegExp(r'\s+'));
  var xs = <double>[];
  var ys = <double>[];
  var i = 0;
  while (i < tokens.length) {
    final t = tokens[i];
    if (t == 'M' || t == 'L') {
      xs.add(double.parse(tokens[i + 1]));
      ys.add(double.parse(tokens[i + 2]));
      i += 3;
    } else {
      if (t == 'Z' && xs.isNotEmpty) {
        rects.add(
          Rect.fromLTRB(
            xs.reduce((a, b) => a < b ? a : b),
            ys.reduce((a, b) => a < b ? a : b),
            xs.reduce((a, b) => a > b ? a : b),
            ys.reduce((a, b) => a > b ? a : b),
          ),
        );
        xs = [];
        ys = [];
      }
      i += 1;
    }
  }
  rects.sort(
    (a, b) =>
        a.top != b.top ? a.top.compareTo(b.top) : b.right.compareTo(a.right),
  );
  return rects;
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

class _CallbackPainter extends CustomPainter {
  _CallbackPainter(this.draw);

  final void Function(Canvas canvas) draw;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CallbackPainter old) => true;
}
