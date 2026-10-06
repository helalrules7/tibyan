import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui' show Canvas, Color, Offset, Paint, Rect, Size;

import 'share_layout.dart';
import 'share_text_runs.dart';

/// The fixed look of the shared pictures (Tibyan's own, not the reader's
/// theme).
abstract final class ShareBrand {
  static const paper = Color(0xFFF7EDDE);
  static const ink = Color(0xFF1E1915);
  static const brown = Color(0xFF7A4A26);
  static const gold = Color(0xFFA8804C);
  static const goldPale = Color(0xFFEBDCC0);

  /// The divine name, as the pages colour it on light paper.
  static const divine = Color(0xFFC62828);
}

/// A surah's header: its title («سورة البقرة») and the line under it
/// («مدنية · ترتيبها في النزول ٨٧»).
class ShareSurahHeader {
  const ShareSurahHeader({required this.title, required this.info});

  final String title;
  final String info;
}

/// What a passage shared as pictures holds, every text already chosen.
class SharePassage {
  const SharePassage({
    required this.verses,
    required this.headers,
    required this.fontFamily,
    required this.basmala,
    required this.reference,
    required this.pageLabel,
    this.tajweed = const {},
    this.divineNames = false,
  });

  /// Verbatim from the source, in order.
  final List<ShareVerse> verses;

  /// By surah number.
  final Map<int, ShareSurahHeader> headers;

  /// The font of the verses' text (the KFGQPC font of their riwaya).
  final String fontFamily;

  /// The basmala as the text has it (without a number), or null when the
  /// source has none to show (the riwaya editions).
  final String? basmala;

  /// The passage («البقرة ١–٥»), in every footer.
  final String reference;

  /// «١ من ٤»: image [index] (from 0) of [count].
  final String Function(int index, int count) pageLabel;

  /// Tajweed letters by (surah, verse); empty when tajweed is off.
  final Map<(int, int), List<ShareTajweedLetter>> tajweed;

  /// Colour the divine name.
  final bool divineNames;

  /// The basmala line opens a surah's first image, except before
  /// at-Tawba, which has none, and al-Fatiha, whose first verse is the
  /// basmala itself (shown as that verse, with its number).
  bool hasBasmala(int surah) => basmala != null && surah != 1 && surah != 9;
}

/// The passage laid out on 1536 x 2048 pictures, ready to draw.
class ShareDocument {
  ShareDocument._(
    this.passage,
    this.fontSize,
    this.tokens,
    this._words,
    this._widths,
    this.pages,
    this._logo,
  );

  static const width = 1536.0;
  static const height = 2048.0;
  static const size = Size(width, height);

  /// Room on each side of the text.
  static const margin = 132.0;
  static const textWidth = width - 2 * margin;

  static const _headerTop = 72.0;
  static const _headerHeight = 236.0;
  static const _basmalaHeight = 150.0;
  static const _footerTop = 1856.0;
  static const _gapAfterHeader = 44.0;
  static const _textBottom = _footerTop - 36;

  /// The text's sizes, largest first: a passage that fits on one picture
  /// takes the largest size it fits at; a longer one the last.
  static const fontSizes = [92.0, 84.0, 76.0, 68.0, 62.0];

  /// The labels' font (the surah's line, the footer): one with the dash
  /// and the Arabic-Indic digits.
  static const _uiFont = 'IBMPlexSansArabic';

  /// Line pitch, in font sizes.
  static const _pitch = 1.95;

  /// The least space between two words, in font sizes.
  static const _space = 0.26;

  final SharePassage passage;
  final double fontSize;
  final List<ShareToken> tokens;
  final List<ui.Paragraph> _words;
  final List<double> _widths;
  final List<SharePageLayout> pages;
  final ui.Image? _logo;

  int get pageCount => pages.length;
  double get _linePitch => fontSize * _pitch;

  /// Lays [passage] out. [logo] is the Tibyan mark for the footers.
  factory ShareDocument.build(SharePassage passage, {ui.Image? logo}) {
    final tokens = tokenize(passage.verses);
    // The first word number of each token in its verse.
    final firstWords = <int>[];
    var word = 1;
    for (var i = 0; i < tokens.length; i++) {
      if (i > 0 && tokens[i].verse != tokens[i - 1].verse) word = 1;
      firstWords.add(word);
      word += wordsInToken(tokens[i].text, endsVerse: tokens[i].endsVerse);
    }

    List<ui.Paragraph> paragraphs(double size) => [
      for (var i = 0; i < tokens.length; i++)
        _paragraph(
          tokenRuns(
            tokens[i].text,
            firstWord: firstWords[i],
            endsVerse: tokens[i].endsVerse,
            letters: () {
              final v = passage.verses[tokens[i].verse];
              return passage.tajweed[(v.surah, v.ayah)] ?? const [];
            }(),
            divine: passage.divineNames ? ShareBrand.divine : null,
            number: ShareBrand.brown,
          ),
          passage.fontFamily,
          size,
          ShareBrand.ink,
        ),
    ];

    // Widths scale with the size: measure once, at the smallest size, to
    // choose the size; then lay out with the chosen size's own widths.
    final base = fontSizes.last;
    var words = paragraphs(base);
    var widths = [for (final p in words) _widthOf(p)];
    var chosen = base;
    for (final s in fontSizes) {
      if (s == base) break;
      final k = s / base;
      final pages = _paginate(passage, tokens, [
        for (final w in widths) w * k,
      ], s);
      // A little room is kept, since the measured widths only scale
      // nearly with the size.
      if (pages.length == 1 &&
          pages.first.lines.length < _capacity(s, withBasmala: true)) {
        chosen = s;
        break;
      }
    }
    if (chosen != base) {
      words = paragraphs(chosen);
      widths = [for (final p in words) _widthOf(p)];
    }
    final pages = _paginate(passage, tokens, widths, chosen);
    return ShareDocument._(passage, chosen, tokens, words, widths, pages, logo);
  }

  static double _widthOf(ui.Paragraph p) {
    p.layout(const ui.ParagraphConstraints(width: double.infinity));
    final w = p.maxIntrinsicWidth.ceilToDouble() + 2;
    p.layout(ui.ParagraphConstraints(width: w));
    return w;
  }

  static int _capacity(double size, {required bool withBasmala}) {
    final top =
        _headerTop +
        _headerHeight +
        _gapAfterHeader +
        (withBasmala ? _basmalaHeight : 0);
    return ((_textBottom - top) / (size * _pitch)).floor();
  }

  static List<SharePageLayout> _paginate(
    SharePassage passage,
    List<ShareToken> tokens,
    List<double> widths,
    double size,
  ) => paginate(
    tokens: tokens,
    verses: passage.verses,
    widths: widths,
    width: textWidth,
    space: size * _space,
    capacity: ({required withBasmala}) =>
        _capacity(size, withBasmala: withBasmala),
    hasBasmala: passage.hasBasmala,
  );

  static ui.Paragraph _paragraph(
    List<(String, Color?)> runs,
    String family,
    double size,
    Color ink,
  ) {
    final b = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textDirection: ui.TextDirection.rtl,
        textAlign: ui.TextAlign.right,
        fontFamily: family,
        fontSize: size,
        maxLines: 1,
      ),
    );
    for (final (text, color) in runs) {
      b
        ..pushStyle(
          ui.TextStyle(color: color ?? ink, fontFamily: family, fontSize: size),
        )
        ..addText(text)
        ..pop();
    }
    return b.build();
  }

  static ui.Paragraph _label(
    String text, {
    required String family,
    required double size,
    required Color color,
    double width = textWidth,
    ui.FontWeight weight = ui.FontWeight.w400,
    ui.TextAlign align = ui.TextAlign.center,
  }) {
    final b =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textDirection: ui.TextDirection.rtl,
              textAlign: align,
              fontFamily: family,
              fontSize: size,
              fontWeight: weight,
              maxLines: 1,
              ellipsis: '…',
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: color,
              fontFamily: family,
              fontSize: size,
              fontWeight: weight,
            ),
          )
          ..addText(text);
    return b.build()..layout(ui.ParagraphConstraints(width: width));
  }

  /// The text drawn on image [page]: its tokens, joined as they stand in
  /// the verses.
  String textOf(int page) =>
      joinTokens(tokens.sublist(pages[page].from, pages[page].to));

  /// Draws image [page] at 1536 x 2048.
  void paint(Canvas canvas, int page) {
    final layout = pages[page];
    canvas.drawRect(Offset.zero & size, Paint()..color = ShareBrand.paper);
    final header = passage.headers[layout.surah];
    _paintHeader(canvas, header);

    var top = _headerTop + _headerHeight + _gapAfterHeader;
    if (layout.firstOfSurah && passage.hasBasmala(layout.surah)) {
      final b = _label(
        passage.basmala!,
        family: passage.fontFamily,
        size: fontSize * 0.78,
        color: ShareBrand.brown,
      );
      canvas.drawParagraph(
        b,
        Offset(margin, top + (_basmalaHeight - b.height) / 2 - 10),
      );
      top += _basmalaHeight;
    }

    final pitch = _linePitch;
    final block = layout.lines.length * pitch;
    // The text sits in the middle of its room.
    final room = _textBottom - top;
    if (block < room) top += (room - block) / 2;
    final space = fontSize * _space;
    for (final line in layout.lines) {
      final xs = placeLine(_widths, line, textWidth, space);
      for (var i = line.from; i < line.to; i++) {
        final p = _words[i];
        final right = width - margin - xs[i - line.from];
        canvas.drawParagraph(
          p,
          Offset(right - _widths[i], top + (pitch - p.height) / 2),
        );
      }
      top += pitch;
    }
    _paintFooter(canvas, page);
  }

  void _paintHeader(Canvas canvas, ShareSurahHeader? header) {
    const r = Rect.fromLTWH(96, _headerTop, width - 192, _headerHeight);
    paintCartouche(canvas, r);
    if (header == null) return;
    final title = _label(
      header.title,
      family: 'UthmanTahaNaskh',
      size: 70,
      color: ShareBrand.ink,
      weight: ui.FontWeight.w700,
      width: 760,
    );
    canvas.drawParagraph(
      title,
      Offset(r.center.dx - 380, r.top + 54 - title.height / 2 + 30),
    );
    final info = _label(
      header.info,
      family: _uiFont,
      size: 34,
      color: ShareBrand.brown,
      width: 760,
    );
    canvas.drawParagraph(
      info,
      Offset(r.center.dx - 380, r.bottom - 58 - info.height / 2),
    );
  }

  void _paintFooter(Canvas canvas, int page) {
    const y = _footerTop;
    final rule = Paint()
      ..color = ShareBrand.gold
      ..strokeWidth = 2;
    canvas
      ..drawLine(const Offset(margin, y), Offset(width / 2 - 26, y), rule)
      ..drawLine(
        Offset(width / 2 + 26, y),
        const Offset(width - margin, y),
        rule,
      );
    _diamond(canvas, const Offset(width / 2, y), 11, ShareBrand.gold);

    const mid = y + 96;
    final ref = _label(
      passage.reference,
      family: _uiFont,
      size: 44,
      color: ShareBrand.brown,
      width: 620,
      align: ui.TextAlign.right,
    );
    canvas.drawParagraph(
      ref,
      Offset(width - margin - 620, mid - ref.height / 2),
    );
    if (pages.length > 1) {
      final n = _label(
        passage.pageLabel(page, pages.length),
        family: _uiFont,
        size: 38,
        color: ShareBrand.brown,
        width: 300,
      );
      canvas.drawParagraph(n, Offset(width / 2 - 150, mid - n.height / 2));
    }
    final logo = _logo;
    if (logo != null) {
      const h = 104.0;
      final w = h * logo.width / logo.height;
      canvas.drawImageRect(
        logo,
        Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
        Rect.fromLTWH(margin, mid - h / 2, w, h),
        Paint()
          ..filterQuality = ui.FilterQuality.high
          ..colorFilter = const ui.ColorFilter.mode(
            ShareBrand.ink,
            ui.BlendMode.srcIn,
          ),
      );
    }
  }

  /// Image [page] as a picture.
  Future<ui.Image> image(int page) {
    final recorder = ui.PictureRecorder();
    paint(Canvas(recorder), page);
    final picture = recorder.endRecording();
    return picture
        .toImage(width.toInt(), height.toInt())
        .whenComplete(picture.dispose);
  }

  /// Image [page] as PNG bytes.
  Future<Uint8List> png(int page) async {
    final img = await image(page);
    try {
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      img.dispose();
    }
  }

  void dispose() {
    for (final p in _words) {
      p.dispose();
    }
  }
}

void _diamond(Canvas canvas, Offset c, double r, Color color) {
  canvas.drawPath(
    ui.Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r, c.dy)
      ..close(),
    Paint()..color = color,
  );
}

/// The header cartouche, drawn with lines and arcs (Tibyan's own design): a
/// double frame, a rosette panel at each end, and a pointed central
/// medallion for the surah's name.
void paintCartouche(Canvas canvas, Rect r) {
  final gold = Paint()
    ..color = ShareBrand.gold
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 3;
  final thin = Paint()
    ..color = ShareBrand.gold
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.6;
  final pale = Paint()..color = ShareBrand.goldPale;
  final paper = Paint()..color = ShareBrand.paper;

  final outer = ui.RRect.fromRectAndRadius(r, const ui.Radius.circular(14));
  canvas
    ..drawRRect(outer, pale)
    ..drawRRect(outer, gold);
  final inner = r.deflate(12);
  canvas
    ..drawRect(inner, paper)
    ..drawRect(inner, thin)
    ..drawRect(inner.deflate(7), thin);

  // The end panels, square, with a rosette each.
  final side = inner.height - 14;
  final panels = [
    Rect.fromLTWH(inner.left + 7, inner.top + 7, side, side),
    Rect.fromLTWH(inner.right - 7 - side, inner.top + 7, side, side),
  ];
  for (final p in panels) {
    canvas.drawRect(p, pale);
    canvas.drawRect(p, thin);
    _rosette(canvas, p.center, side * 0.40, gold, thin);
  }

  // Between the panels: the medallion, pointed at both ends.
  final left = panels[0].right + 26;
  final right = panels[1].left - 26;
  final cy = inner.center.dy;
  final half = (inner.height - 14) / 2 - 6;
  ui.Path medallion(double inset) {
    final l = left + inset, rt = right - inset, h = half - inset;
    final lean = h * 1.15;
    return ui.Path()
      ..moveTo(l, cy)
      ..cubicTo(
        l + lean * 0.35,
        cy - h * 0.15,
        l + lean * 0.55,
        cy - h,
        l + lean,
        cy - h,
      )
      ..lineTo(rt - lean, cy - h)
      ..cubicTo(
        rt - lean * 0.55,
        cy - h,
        rt - lean * 0.35,
        cy - h * 0.15,
        rt,
        cy,
      )
      ..cubicTo(
        rt - lean * 0.35,
        cy + h * 0.15,
        rt - lean * 0.55,
        cy + h,
        rt - lean,
        cy + h,
      )
      ..lineTo(l + lean, cy + h)
      ..cubicTo(l + lean * 0.55, cy + h, l + lean * 0.35, cy + h * 0.15, l, cy)
      ..close();
  }

  canvas
    ..drawPath(medallion(0), paper)
    ..drawPath(medallion(0), gold)
    ..drawPath(medallion(9), thin);
  // Small diamonds where the medallion points.
  _diamond(canvas, Offset(left - 12, cy), 7, ShareBrand.gold);
  _diamond(canvas, Offset(right + 12, cy), 7, ShareBrand.gold);
}

void _rosette(Canvas canvas, Offset c, double r, Paint stroke, Paint thin) {
  canvas
    ..drawCircle(c, r, stroke)
    ..drawCircle(c, r * 0.82, thin);
  const petals = 8;
  for (var i = 0; i < petals; i++) {
    final a = i * 2 * math.pi / petals;
    final tip = c + Offset(math.cos(a), math.sin(a)) * (r * 0.72);
    final side1 =
        c + Offset(math.cos(a + 0.42), math.sin(a + 0.42)) * (r * 0.34);
    final side2 =
        c + Offset(math.cos(a - 0.42), math.sin(a - 0.42)) * (r * 0.34);
    canvas.drawPath(
      ui.Path()
        ..moveTo(c.dx, c.dy)
        ..quadraticBezierTo(side1.dx, side1.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(side2.dx, side2.dy, c.dx, c.dy)
        ..close(),
      thin,
    );
  }
  canvas
    ..drawCircle(c, r * 0.16, Paint()..color = stroke.color)
    ..drawCircle(c, r * 0.07, Paint()..color = ShareBrand.paper);
}
