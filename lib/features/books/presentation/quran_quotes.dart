import 'package:flutter/painting.dart';

/// A piece of a book's text: plain, or a verse the book quotes between
/// ﴿ ﴾ (the brackets included, so the pieces joined give the text back
/// byte for byte).
class QuoteSegment {
  const QuoteSegment(this.text, {required this.quote});

  final String text;
  final bool quote;

  /// The quoted words without the brackets ('' for plain text).
  String get inner => quote ? text.substring(1, text.length - 1) : '';

  @override
  bool operator ==(Object other) =>
      other is QuoteSegment && other.text == text && other.quote == quote;

  @override
  int get hashCode => Object.hash(text, quote);

  @override
  String toString() => quote ? 'quote($text)' : 'plain($text)';
}

const quoteOpen = '﴿';
const quoteClose = '﴾';

/// Splits [text] at the verses it quotes between ﴿ ﴾. Display only: the
/// text is never changed. A ﴿ that is never closed, or a ﴾ that was never
/// opened, stays plain text; a ﴿ inside a quotation is part of it.
List<QuoteSegment> splitQuranQuotes(String text) {
  final out = <QuoteSegment>[];
  var plainStart = 0;
  var i = 0;
  while (i < text.length) {
    final open = text.indexOf(quoteOpen, i);
    if (open < 0) break;
    final close = text.indexOf(quoteClose, open + 1);
    if (close < 0) break;
    if (open > plainStart) {
      out.add(QuoteSegment(text.substring(plainStart, open), quote: false));
    }
    out.add(QuoteSegment(text.substring(open, close + 1), quote: true));
    plainStart = i = close + 1;
  }
  if (plainStart < text.length) {
    out.add(QuoteSegment(text.substring(plainStart), quote: false));
  }
  return out;
}

/// [text] as spans, its ﴿ ﴾ quotations in [quoteStyle] (the brackets in
/// [bracketStyle], or [quoteStyle] when null). Plain text takes the
/// surrounding style.
List<InlineSpan> quranQuoteSpans(
  String text, {
  required TextStyle quoteStyle,
  TextStyle? bracketStyle,
}) => [
  for (final s in splitQuranQuotes(text))
    if (!s.quote)
      TextSpan(text: s.text)
    else ...[
      TextSpan(text: quoteOpen, style: bracketStyle ?? quoteStyle),
      TextSpan(text: s.inner, style: quoteStyle),
      TextSpan(text: quoteClose, style: bracketStyle ?? quoteStyle),
    ],
];
