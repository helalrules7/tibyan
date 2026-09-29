import 'dart:math' as math;

import 'package:flutter/material.dart';

const tatweel = 'ـ';

/// Letters that never join the letter after them.
const _rightJoiningOnly = 'اأإآٱدذرزوؤةءى';

bool _isArabicLetter(int c) =>
    (c >= 0x0621 && c <= 0x064A && c != 0x0640) ||
    c == 0x0671 ||
    (c >= 0x06A9 && c <= 0x06CC);

/// Harakat, Quranic marks and the superscript alef: they sit on a letter.
bool _isMark(int c) =>
    (c >= 0x064B && c <= 0x065F) || c == 0x0670 || (c >= 0x06D6 && c <= 0x06ED);

/// Offsets in [line] where a tatweel may go: between two joined letters of
/// one word, after the first letter's marks. None inside brackets (the
/// tafsir quotes Quran words there), none that would break lam-alef.
List<int> kashidaSlots(String line) {
  final slots = <int>[];
  var depth = 0;
  final units = line.codeUnits;
  for (var i = 0; i < units.length; i++) {
    final c = units[i];
    if (c == 0x28 || c == 0xFD3F || c == 0x7B || c == 0x5B) depth++;
    if (c == 0x29 || c == 0xFD3E || c == 0x7D || c == 0x5D) {
      depth = math.max(0, depth - 1);
    }
    if (depth > 0 || !_isArabicLetter(c)) continue;
    if (_rightJoiningOnly.contains(String.fromCharCode(c))) continue;
    var j = i + 1;
    while (j < units.length && _isMark(units[j])) {
      j++;
    }
    if (j >= units.length) continue;
    final n = units[j];
    if (!_isArabicLetter(n) || n == 0x0621) continue;
    // lam + alef forms a ligature; a tatweel would split it.
    if (c == 0x0644 && 'اأإآٱ'.contains(String.fromCharCode(n))) continue;
    slots.add(j);
  }
  return slots;
}

/// Removes what [insertKashidas] added, given the text it was applied to.
/// Tatweels already in the source text stay.
String removeAddedKashidas(String stretched, String original) {
  final out = StringBuffer();
  var j = 0;
  for (var i = 0; i < stretched.length; i++) {
    if (j < original.length && stretched[i] == original[j]) {
      out.write(stretched[i]);
      j++;
    }
  }
  return out.toString();
}

/// Inserts [count] tatweels into [line], spread over its words: the last
/// slot of each word first, one per word per round, at most three per slot.
String insertKashidas(String line, int count) {
  if (count <= 0) return line;
  final slots = kashidaSlots(line);
  if (slots.isEmpty) return line;
  // Group slots by word, keeping each word's last slot first.
  final words = <List<int>>[];
  var wordStart = -1;
  for (final s in slots) {
    final start = line.lastIndexOf(' ', s) + 1;
    if (start != wordStart) {
      words.add([]);
      wordStart = start;
    }
    words.last.insert(0, s);
  }
  final added = <int, int>{};
  var left = count;
  for (var round = 0; left > 0 && round < 3; round++) {
    for (final w in words) {
      if (left == 0) break;
      final slot = w[round % w.length];
      if ((added[slot] ?? 0) >= 3) continue;
      added[slot] = (added[slot] ?? 0) + 1;
      left--;
    }
  }
  final out = StringBuffer();
  for (var i = 0; i < line.length; i++) {
    final n = added[i];
    if (n != null) out.write(tatweel * n);
    out.write(line[i]);
  }
  return out.toString();
}

/// Justified Arabic text that stretches words with tatweel instead of
/// widening spaces. Display only: the text given is never changed, and
/// removing every tatweel added here gives it back exactly.
class KashidaText extends StatelessWidget {
  const KashidaText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final stretched = <String>[];
        for (final paragraph in text.split('\n')) {
          stretched.add(_stretch(paragraph, width, scaler));
        }
        return Text(
          stretched.join('\n'),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
          style: style,
        );
      },
    );
  }

  String _stretch(String paragraph, double width, TextScaler scaler) {
    TextPainter painter(String s) => TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.rtl,
      textScaler: scaler,
    );
    double widthOf(String s) {
      final t = painter(s)..layout();
      final w = t.width;
      t.dispose();
      return w;
    }

    final unit = widthOf(tatweel);
    final p = painter(paragraph)..layout(maxWidth: width);
    final metrics = p.computeLineMetrics();
    if (unit <= 0 || metrics.length < 2) {
      p.dispose();
      return paragraph;
    }
    final out = StringBuffer();
    var offset = 0;
    for (var i = 0; i < metrics.length; i++) {
      final range = p.getLineBoundary(TextPosition(offset: offset));
      final end = math.max(range.end, offset + 1).clamp(0, paragraph.length);
      final line = paragraph.substring(offset, end);
      // The last line keeps its natural width.
      if (i == metrics.length - 1) {
        out.write(line);
      } else {
        final trimmed = line.trimRight();
        final natural = widthOf(trimmed);
        // Keep a small margin so the line never wraps differently.
        final count = ((width - natural) / unit - 0.5).floor();
        out.write(insertKashidas(trimmed, count));
        out.write(line.substring(trimmed.length));
      }
      offset = end;
      if (offset >= paragraph.length) break;
    }
    if (offset < paragraph.length) out.write(paragraph.substring(offset));
    p.dispose();
    return out.toString();
  }
}
