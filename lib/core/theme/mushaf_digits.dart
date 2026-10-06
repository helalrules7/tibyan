import 'package:flutter/widgets.dart';

/// [text] in the interface's font, its numbers in the mushaf's (KFGQPC
/// Hafs) digits: a verse's number reads as it does on the page.
class MushafDigitsText extends StatelessWidget {
  const MushafDigitsText(
    this.text, {
    super.key,
    this.style,
    this.semanticsLabel,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final String? semanticsLabel;
  final TextAlign? textAlign;

  /// The KFGQPC digits are drawn small (to sit inside a verse-end marker):
  /// enlarged to stand about as tall as the letters beside them.
  static const digitScale = 2.3;

  static final _digits = RegExp('[٠-٩0-9]+');

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    final size = base.fontSize ?? 14;
    final digits = TextStyle(
      fontFamily: 'UthmanicHafs',
      fontSize: size * digitScale,
      fontWeight: FontWeight.w400,
      // The font joins a run of digits into a verse-end marker (its
      // «rlig»): here they are plain numbers.
      fontFeatures: const [FontFeature.disable('rlig')],
    );
    final spans = <InlineSpan>[];
    var at = 0;
    for (final m in _digits.allMatches(text)) {
      if (m.start > at) spans.add(TextSpan(text: text.substring(at, m.start)));
      spans.add(TextSpan(text: m[0], style: digits));
      at = m.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return Text.rich(
      TextSpan(children: spans),
      style: style,
      textAlign: textAlign,
      semanticsLabel: semanticsLabel ?? text,
      // The larger digits do not make the line taller.
      strutStyle: StrutStyle(
        fontFamily: base.fontFamily,
        fontSize: size,
        height: base.height,
        forceStrutHeight: true,
      ),
    );
  }
}
