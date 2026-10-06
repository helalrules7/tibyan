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
/// («مدنية · ترتيبها في النزول ٨٧ · نزلت بعد المطففين»).
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
    this.mushaf,
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

  /// The page and line of each word of the passage in its printed mushaf
  /// (by surah, verse and word), when they are known: a passage on more
  /// than one picture is then split as the mushaf is, page by page and
  /// line by line ([paginateByMushaf]).
  final Map<(int, int, int), MushafPlace>? mushaf;

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
    this._heads, {
    required this.byMushaf,
    double? linePitch,
  }) : _linePitch = linePitch ?? fontSize * _pitch;

  static const width = 1536.0;
  static const height = 2048.0;
  static const size = Size(width, height);

  /// Room on each side of the text.
  static const margin = 132.0;
  static const textWidth = width - 2 * margin;

  static const _headerTop = 72.0;

  /// The header's height, unless its info line needs more room
  /// ([layoutHeader]).
  static const headerHeight = 236.0;
  static const _basmalaHeight = 150.0;
  static const _footerTop = 1856.0;
  static const _gapAfterHeader = 44.0;
  static const _textBottom = _footerTop - 36;

  /// The footer's band, from its rule to the bottom edge.
  static const _footerHeight = height - _footerTop;

  /// Room between the text and the footer's rule on a picture trimmed to
  /// its text.
  static const _gapBeforeFooter = 96.0;

  /// The text's sizes, largest first: a passage that fits on one picture
  /// takes the largest size it fits at; a longer one the last.
  static const fontSizes = [92.0, 84.0, 76.0, 68.0, 62.0];

  /// The labels' font (the surah's line, the footer), for their words:
  /// their digits are in the passage's mushaf font ([labelRuns]).
  static const _uiFont = 'Changa';

  /// Line pitch, in font sizes.
  static const _pitch = 1.95;

  /// The least line pitch of a passage laid out as its mushaf's pages, in
  /// font sizes: a page of fifteen lines then still fits a picture at the
  /// size its longest line allows.
  static const _mushafPitch = 1.6;

  /// The least space between two words, in font sizes.
  static const _space = 0.26;

  final SharePassage passage;
  final double fontSize;
  final List<ShareToken> tokens;
  final List<ui.Paragraph> _words;
  final List<double> _widths;
  final List<SharePageLayout> pages;
  final ui.Image? _logo;

  /// The header of each surah of the passage, laid out.
  final Map<int, ShareHeaderLayout> _heads;

  /// The height of surah [surah]'s header.
  double headerHeightOf(int surah) =>
      _heads[surah]?.rect.height ?? headerHeight;

  /// Surah [surah]'s header as laid out on its pictures.
  ShareHeaderLayout? headerOf(int surah) => _heads[surah];

  /// Laid out as the printed mushaf: each picture one page of it, each
  /// line one of its lines ([paginateByMushaf]).
  final bool byMushaf;

  /// From one line's middle to the next one's.
  final double _linePitch;

  int get pageCount => pages.length;

  /// The size of image [page]: a passage on one picture is only as tall as
  /// its header, basmala, text and footer need; a passage on several keeps
  /// the full 3:4 size on every one.
  Size sizeOf(int page) {
    if (pages.length > 1 || byMushaf) return size;
    final layout = pages[page];
    final basmala = layout.firstOfSurah && passage.hasBasmala(layout.surah);
    final h =
        _headerTop +
        headerHeightOf(layout.surah) +
        _gapAfterHeader +
        (basmala ? _basmalaHeight : 0) +
        layout.lines.length * _linePitch +
        _gapBeforeFooter +
        _footerHeight;
    return Size(width, h < height ? h.ceilToDouble() : height);
  }

  /// Lays [passage] out. [logo] is the Tibyan mark for the footers.
  ///
  /// A passage that fits on one picture takes the largest size it fits at,
  /// its lines flowed to the picture's width. A longer one is split as its
  /// printed mushaf when the places of its words are known
  /// ([SharePassage.mushaf]): one picture for each page, one line for each
  /// line, all at one size, the largest at which the longest line fits the
  /// text's width. Otherwise its lines are flowed at the smallest size.
  factory ShareDocument.build(SharePassage passage, {ui.Image? logo}) {
    final heads = {
      for (final MapEntry(key: surah, value: h) in passage.headers.entries)
        surah: layoutHeader(h, digits: passage.fontFamily),
    };
    double headOf(int surah) => heads[surah]?.rect.height ?? headerHeight;
    final tokens = tokenize(passage.verses);
    final firstWords = tokenFirstWords(tokens);

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
      final pages = _paginate(
        passage,
        tokens,
        [for (final w in widths) w * k],
        s,
        headOf,
      );
      // A little room is kept, since the measured widths only scale
      // nearly with the size.
      if (pages.length == 1 &&
          pages.first.lines.length <
              _capacity(
                s,
                withBasmala: true,
                headerHeight: headOf(pages.first.surah),
              )) {
        chosen = s;
        break;
      }
    }
    if (chosen == base) {
      final flowed = _paginate(passage, tokens, widths, base, headOf);
      final places = passage.mushaf;
      final mushaf = flowed.length > 1 && places != null
          ? paginateByMushaf(
              tokens: tokens,
              verses: passage.verses,
              placeOf: (s, a, w) => places[(s, a, w)],
            )
          : null;
      if (mushaf == null) {
        return ShareDocument._(
          passage,
          base,
          tokens,
          words,
          widths,
          flowed,
          logo,
          heads,
          byMushaf: false,
        );
      }
      for (final p in words) {
        p.dispose();
      }
      return _byMushaf(passage, tokens, mushaf, paragraphs, logo, heads);
    }
    words = paragraphs(chosen);
    widths = [for (final p in words) _widthOf(p)];
    final pages = _paginate(passage, tokens, widths, chosen, headOf);
    return ShareDocument._(
      passage,
      chosen,
      tokens,
      words,
      widths,
      pages,
      logo,
      heads,
      byMushaf: false,
    );
  }

  /// [pages], the passage split as its mushaf, at the largest size (up to
  /// the first of [fontSizes]) at which the longest line fits the text's
  /// width and the fullest picture its height.
  static ShareDocument _byMushaf(
    SharePassage passage,
    List<ShareToken> tokens,
    List<SharePageLayout> pages,
    List<ui.Paragraph> Function(double size) paragraphs,
    ui.Image? logo,
    Map<int, ShareHeaderLayout> heads,
  ) {
    double room(SharePageLayout p) =>
        _textBottom -
        _textTop(
          withBasmala: p.firstOfSurah && passage.hasBasmala(p.surah),
          headerHeight: heads[p.surah]?.rect.height ?? headerHeight,
        );
    // The least room a line has on any picture.
    var perLine = double.infinity;
    for (final p in pages) {
      perLine = math.min(perLine, room(p) / p.lines.length);
    }
    double widest(List<double> widths, double size) {
      var most = 0.0;
      for (final p in pages) {
        for (final l in p.lines) {
          var used = size * _space * (l.length - 1);
          for (var i = l.from; i < l.to; i++) {
            used += widths[i];
          }
          most = math.max(most, used);
        }
      }
      return most;
    }

    const probe = 60.0;
    var words = paragraphs(probe);
    var size =
        probe * textWidth / widest([for (final p in words) _widthOf(p)], probe);
    size = math.min(size, perLine / _mushafPitch);
    size = math.min(size, fontSizes.first);
    var widths = <double>[];
    // The measured widths scale only nearly with the size: shrink until the
    // longest line fits.
    for (var tries = 0; ; tries++) {
      size = (size * 2).floorToDouble() / 2;
      for (final p in words) {
        p.dispose();
      }
      words = paragraphs(size);
      widths = [for (final p in words) _widthOf(p)];
      final most = widest(widths, size);
      if (most <= textWidth || tries == 4) break;
      size = math.min(size - 0.5, size * textWidth / most);
    }
    return ShareDocument._(
      passage,
      size,
      tokens,
      words,
      widths,
      pages,
      logo,
      heads,
      byMushaf: true,
      linePitch: math.min(size * _pitch, perLine),
    );
  }

  static double _widthOf(ui.Paragraph p) {
    p.layout(const ui.ParagraphConstraints(width: double.infinity));
    final w = p.maxIntrinsicWidth.ceilToDouble() + 2;
    p.layout(ui.ParagraphConstraints(width: w));
    return w;
  }

  /// Where the text's room starts: under the header (of [headerHeight]),
  /// and the basmala.
  static double _textTop({
    required bool withBasmala,
    required double headerHeight,
  }) =>
      _headerTop +
      headerHeight +
      _gapAfterHeader +
      (withBasmala ? _basmalaHeight : 0);

  static int _capacity(
    double size, {
    required bool withBasmala,
    required double headerHeight,
  }) =>
      ((_textBottom -
                  _textTop(
                    withBasmala: withBasmala,
                    headerHeight: headerHeight,
                  )) /
              (size * _pitch))
          .floor();

  static List<SharePageLayout> _paginate(
    SharePassage passage,
    List<ShareToken> tokens,
    List<double> widths,
    double size,
    double Function(int surah) headerHeightOf,
  ) => paginate(
    tokens: tokens,
    verses: passage.verses,
    widths: widths,
    width: textWidth,
    space: size * _space,
    capacity: ({required withBasmala, required surah}) => _capacity(
      size,
      withBasmala: withBasmala,
      headerHeight: headerHeightOf(surah),
    ),
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

  /// A label in [family]; its digits, when [digits] is given, in that font
  /// (the mushaf's), at [digitScale] times the size, on the same baseline
  /// and within the lines' height of [family].
  static ui.Paragraph _label(
    String text, {
    required String family,
    required double size,
    required Color color,
    String? digits,
    double digitScale = 1,
    double width = textWidth,
    ui.FontWeight weight = ui.FontWeight.w400,
    ui.TextAlign align = ui.TextAlign.center,
    int? maxLines = 1,
    double? lineHeight,
  }) {
    final b = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textDirection: ui.TextDirection.rtl,
        textAlign: align,
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        maxLines: maxLines,
        ellipsis: '…',
        strutStyle: digits == null
            ? null
            : ui.StrutStyle(
                fontFamily: family,
                fontSize: size,
                height: lineHeight,
                forceStrutHeight: true,
              ),
      ),
    );
    final runs = digits == null
        ? [(text, family)]
        : labelRuns(text, words: family, digits: digits);
    for (final (run, font) in runs) {
      final isDigits = font != family;
      b
        ..pushStyle(
          ui.TextStyle(
            color: color,
            fontFamily: font,
            fontSize: isDigits ? size * digitScale : size,
            fontWeight: isDigits ? ui.FontWeight.w400 : weight,
            // The KFGQPC fonts join a run of digits into a verse-end
            // marker (their «rlig»): here they are plain numbers.
            fontFeatures: isDigits
                ? const [ui.FontFeature.disable('rlig')]
                : null,
          ),
        )
        ..addText(run)
        ..pop();
    }
    return b.build()..layout(ui.ParagraphConstraints(width: width));
  }

  /// The width of the widest line of any picture, its words at their
  /// natural spacing.
  double get widestLine {
    var most = 0.0;
    for (final p in pages) {
      for (final l in p.lines) {
        var used = fontSize * _space * (l.length - 1);
        for (var i = l.from; i < l.to; i++) {
          used += _widths[i];
        }
        if (used > most) most = used;
      }
    }
    return most;
  }

  /// From one line's middle to the next one's.
  double get linePitch => _linePitch;

  /// The text drawn on image [page]: its tokens, joined as they stand in
  /// the verses.
  String textOf(int page) =>
      joinTokens(tokens.sublist(pages[page].from, pages[page].to));

  /// Draws image [page] at [sizeOf] it.
  void paint(Canvas canvas, int page) {
    final layout = pages[page];
    final pictureSize = sizeOf(page);
    // The footer keeps its place from the bottom edge.
    final footerTop = pictureSize.height - _footerHeight;
    canvas.drawRect(
      Offset.zero & pictureSize,
      Paint()..color = ShareBrand.paper,
    );
    final head = _heads[layout.surah];
    if (head == null) {
      paintCartouche(canvas, cartoucheRect(headerHeight));
    } else {
      paintCartouche(canvas, head.rect);
      canvas
        ..drawParagraph(head.title, head.titleOffset)
        ..drawParagraph(head.info, head.infoOffset);
    }

    var top = _headerTop + headerHeightOf(layout.surah) + _gapAfterHeader;
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
    final room = footerTop - (_footerTop - _textBottom) - top;
    if (block < room) top += (room - block) / 2;
    final space = fontSize * _space;
    for (final line in layout.lines) {
      // Each line centred across, its words at their natural spacing.
      final plain = ShareLine(line.from, line.to, justified: false);
      final xs = placeLine(_widths, plain, textWidth, space);
      var used = space * (line.length - 1);
      for (var i = line.from; i < line.to; i++) {
        used += _widths[i];
      }
      final inset = used < textWidth ? (textWidth - used) / 2 : 0.0;
      for (var i = line.from; i < line.to; i++) {
        final p = _words[i];
        final right = width - margin - inset - xs[i - line.from];
        canvas.drawParagraph(
          p,
          Offset(right - _widths[i], top + (pitch - p.height) / 2),
        );
      }
      top += pitch;
    }
    _paintFooter(canvas, page, footerTop);
  }

  /// The cartouche of a header of [height], across the picture.
  static Rect cartoucheRect(double height) =>
      Rect.fromLTWH(96, _headerTop, width - 192, height);

  /// The width of the surah's info line, within the flat top and bottom of
  /// the medallion (644 wide).
  static const infoWidth = 640.0;

  /// The info line's sizes: on one line, down to the least; then on two
  /// lines; then on three at the least size, the cartouche taller.
  static const infoSizes = [34.0, 32.0, 30.0, 28.0, 26.0, 24.0];
  static const infoSizesWrapped = [26.0, 24.0];
  static const infoLeastSize = 24.0;

  /// The info line's line height, in font sizes. Changa's ascent and
  /// descent shared out over it (1.0 and 0.5), each line's box holds its
  /// ink: letters with their marks and the enlarged digits reach 0.98
  /// above the baseline and 0.45 below (measured on all 114 headers).
  static const infoLineHeight = 1.5;

  /// How far the title's ink reaches below its baseline, in its font size:
  /// at most 0.49 (measured on all 114 titles).
  static const _titleDescent = 0.5;

  /// [header] laid out: its title at its fixed size; its info line at the
  /// largest size at which it fits the medallion on one line (down to the
  /// last of [infoSizes]); else on two lines, at the largest of
  /// [infoSizesWrapped] at which they fit; else at [infoLeastSize] on the
  /// fewest lines it takes (two or three), the cartouche and the medallion
  /// made taller for them. A wrapped line starts the order of revelation on
  /// a line of its own when that takes no more lines. The info line never runs past the medallion and
  /// is never cut. Its digits are in the passage's mushaf font [digits].
  static ShareHeaderLayout layoutHeader(
    ShareSurahHeader header, {
    required String digits,
  }) {
    final title = _label(
      header.title,
      family: 'UthmanTahaNaskh',
      size: _titleSize,
      color: ShareBrand.ink,
      weight: ui.FontWeight.w700,
      width: 760,
    );
    Offset titleAt(Rect r) =>
        Offset(r.center.dx - 380, r.top + 84 - title.height / 2);
    Rect room(Rect r) =>
        infoRoom(r, titleBaseline: titleAt(r).dy + title.alphabeticBaseline);
    // On more than one line, the order of revelation starts a line of its
    // own when that takes no more lines.
    final broken = header.info.replaceFirst(' · ', '\n');
    ui.Paragraph at(double size, int? lines, {bool breakFirst = false}) =>
        _label(
          breakFirst ? broken : header.info,
          family: _uiFont,
          size: size,
          color: ShareBrand.brown,
          digits: digits,
          digitScale: _digitScale,
          width: infoWidth,
          maxLines: lines,
          lineHeight: infoLineHeight,
        );

    final base = room(cartoucheRect(headerHeight));
    ui.Paragraph? info;
    var size = infoLeastSize;
    for (final s in infoSizes) {
      final p = at(s, 1);
      if (p.maxIntrinsicWidth <= infoWidth && p.height <= base.height) {
        (info, size) = (p, s);
        break;
      }
      p.dispose();
    }
    if (info == null) {
      wrapped:
      for (final s in infoSizesWrapped) {
        for (final breakFirst in [true, false]) {
          final p = at(s, 2, breakFirst: breakFirst);
          if (!p.didExceedMaxLines && p.height <= base.height) {
            (info, size) = (p, s);
            break wrapped;
          }
          p.dispose();
        }
      }
    }
    var height = headerHeight;
    if (info == null) {
      // The fewest lines it takes: the cartouche grows by what they need
      // beyond its room.
      fewest:
      for (var lines = 2; ; lines++) {
        for (final breakFirst in [true, false]) {
          final p = at(infoLeastSize, lines, breakFirst: breakFirst);
          if (!p.didExceedMaxLines || (lines >= 12 && !breakFirst)) {
            info = p;
            break fewest;
          }
          p.dispose();
        }
      }
      height += math.max(0.0, info.height - base.height).ceilToDouble();
    }
    final rect = cartoucheRect(height);
    final r = room(rect);
    return ShareHeaderLayout._(
      rect: rect,
      title: title,
      titleOffset: titleAt(rect),
      info: info,
      infoOffset: Offset(
        r.center.dx - infoWidth / 2,
        r.top + (r.height - info.height) / 2,
      ),
      infoRoom: r,
      infoSize: size,
    );
  }

  /// The room of a header's info line in cartouche [r]: as wide as
  /// [infoWidth], centred, within the medallion's flat top and bottom; from
  /// under the ink of the title (its baseline [titleBaseline]) to a little
  /// above the medallion's inner line.
  static Rect infoRoom(Rect r, {required double titleBaseline}) {
    final m = Medallion.of(r);
    return Rect.fromLTRB(
      r.center.dx - infoWidth / 2,
      titleBaseline + _titleSize * _titleDescent + 4,
      r.center.dx + infoWidth / 2,
      m.innerBottom - 3,
    );
  }

  static const _titleSize = 70.0;

  /// The mushaf font's digits beside the labels' letters: the KFGQPC
  /// digits are drawn small (to sit inside a verse-end marker), so they
  /// are enlarged to stand about as tall as the letters.
  static const _digitScale = 2.3;

  void _paintFooter(Canvas canvas, int page, double y) {
    final rule = Paint()
      ..color = ShareBrand.gold
      ..strokeWidth = 2;
    canvas
      ..drawLine(Offset(margin, y), Offset(width / 2 - 26, y), rule)
      ..drawLine(Offset(width / 2 + 26, y), Offset(width - margin, y), rule);
    _diamond(canvas, Offset(width / 2, y), 11, ShareBrand.gold);

    final mid = y + 96;
    final ref = _label(
      passage.reference,
      family: _uiFont,
      size: 44,
      color: ShareBrand.brown,
      digits: passage.fontFamily,
      digitScale: _digitScale,
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
        digits: passage.fontFamily,
        digitScale: _digitScale,
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
    final s = sizeOf(page);
    return picture
        .toImage(s.width.toInt(), s.height.toInt())
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
    for (final h in _heads.values) {
      h.dispose();
    }
  }
}

/// A surah's header laid out ([ShareDocument.layoutHeader]).
class ShareHeaderLayout {
  ShareHeaderLayout._({
    required this.rect,
    required this.title,
    required this.titleOffset,
    required this.info,
    required this.infoOffset,
    required this.infoRoom,
    required this.infoSize,
  });

  /// The cartouche: [ShareDocument.headerHeight] tall, or taller for an
  /// info line that needs more room.
  final Rect rect;

  final ui.Paragraph title;
  final Offset titleOffset;

  /// The info line («مكية إلا … · ترتيبها في النزول … · نزلت بعد …»), laid
  /// out [ShareDocument.infoWidth] wide, its lines centred.
  final ui.Paragraph info;
  final Offset infoOffset;

  /// The room the info line has ([ShareDocument.infoRoom]).
  final Rect infoRoom;
  final double infoSize;

  /// The info paragraph's box on the picture.
  Rect get infoBox => infoOffset & Size(ShareDocument.infoWidth, info.height);

  int get infoLineCount => info.computeLineMetrics().length;

  void dispose() {
    title.dispose();
    info.dispose();
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

/// The medallion of a cartouche: between the end panels, pointed at both
/// ends.
class Medallion {
  const Medallion._(this.left, this.right, this.cy, this.half, this.lean);

  /// The medallion of cartouche [r]. The end panels keep their width when
  /// the cartouche is taller than [ShareDocument.headerHeight], and the
  /// points their slope, so the medallion's flat top and bottom keep their
  /// length.
  factory Medallion.of(Rect r) {
    final inner = r.deflate(12);
    final panel = math.min(inner.height - 14, _panelSide);
    final left = inner.left + 7 + panel + 26;
    final right = inner.right - 7 - panel - 26;
    final half = (inner.height - 14) / 2 - 6;
    return Medallion._(
      left,
      right,
      inner.center.dy,
      half,
      math.min(half, _baseHalf) * 1.15,
    );
  }

  /// The side of the end panels, and the medallion's half height, in a
  /// cartouche [ShareDocument.headerHeight] tall.
  static const _panelSide = ShareDocument.headerHeight - 24 - 14;
  static const _baseHalf = _panelSide / 2 - 6;

  final double left;
  final double right;
  final double cy;
  final double half;

  /// How far in from each end the points reach the flat top and bottom.
  final double lean;

  /// The flat top and bottom, from left to right.
  double get flatLeft => left + lean;
  double get flatRight => right - lean;

  /// The inner line, drawn 9 inside the outline.
  double get innerTop => cy - half + 9;
  double get innerBottom => cy + half - 9;

  ui.Path path(double inset) {
    final l = left + inset, rt = right - inset, h = half - inset;
    final lean = this.lean * h / half;
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
}

/// The header cartouche, drawn with lines and arcs (Tibyan's own design): a
/// double frame, a rosette panel at each end, and a pointed central
/// medallion for the surah's name. A cartouche taller than
/// [ShareDocument.headerHeight] keeps its panels' width and its points'
/// slope ([Medallion.of]).
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

  // The end panels, square in a cartouche of the usual height, with a
  // rosette each.
  final side = math.min(inner.height - 14, Medallion._panelSide);
  final panels = [
    Rect.fromLTWH(inner.left + 7, inner.top + 7, side, inner.height - 14),
    Rect.fromLTWH(
      inner.right - 7 - side,
      inner.top + 7,
      side,
      inner.height - 14,
    ),
  ];
  for (final p in panels) {
    canvas.drawRect(p, pale);
    canvas.drawRect(p, thin);
    _rosette(canvas, p.center, side * 0.40, gold, thin);
  }

  // Between the panels: the medallion, pointed at both ends.
  final m = Medallion.of(r);
  canvas
    ..drawPath(m.path(0), paper)
    ..drawPath(m.path(0), gold)
    ..drawPath(m.path(9), thin);
  // Small diamonds where the medallion points.
  _diamond(canvas, Offset(m.left - 12, m.cy), 7, ShareBrand.gold);
  _diamond(canvas, Offset(m.right + 12, m.cy), 7, ShareBrand.gold);
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
