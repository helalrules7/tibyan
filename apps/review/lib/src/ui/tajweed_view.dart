import 'package:flutter/material.dart';

import '../model/model.dart';
import 'verse_view.dart' show mushafFont;

/// One rule on one letter, as tools/import_tajweed_review.py writes it at
/// the end of each line of a `tajweed_verse` entry: `[rule word:letter:part]`.
class TajweedMark {
  const TajweedMark(this.rule, this.word, this.letter, this.part);

  final String rule;

  /// From 1, ۞ not counted.
  final int word;

  /// From 0: a base character with the marks that follow it.
  final int letter;

  /// `body` (the letter) or `marks` (only its marks).
  final String part;

  static final _line = RegExp(r'\[([a-z_0-9]+) (\d+):(\d+):(body|marks)\]\s*$');

  static List<TajweedMark> parse(String text) => [
        for (final line in text.split('\n'))
          if (_line.firstMatch(line) case final m?)
            TajweedMark(m[1]!, int.parse(m[2]!), int.parse(m[3]!), m[4]!),
      ];
}

/// Preview colours, one per rule (tools/verify_tajweed.py), so a reader can
/// tell neighbouring rules apart; the app's own palette is the reader's.
const tajweedColours = <String, Color>{
  'hamzat_wasl': Color(0xFF8A8A8A),
  'lam_shamsiyyah': Color(0xFF8A8A8A),
  'silent': Color(0xFF8A8A8A),
  'madd_2': Color(0xFFC58A00),
  'madd_246': Color(0xFFE07000),
  'madd_muttasil': Color(0xFFC62828),
  'madd_munfasil': Color(0xFFE53935),
  'madd_6': Color(0xFF8B0000),
  'ghunnah': Color(0xFF2E7D32),
  'ikhfa': Color(0xFF43A047),
  'ikhfa_shafawi': Color(0xFF43A047),
  'iqlab': Color(0xFF00897B),
  'idghaam_ghunnah': Color(0xFF1B5E20),
  'idghaam_no_ghunnah': Color(0xFF6D4C41),
  'idghaam_shafawi': Color(0xFF1B5E20),
  'idghaam_mutajanisayn': Color(0xFF757575),
  'idghaam_mutaqaribayn': Color(0xFF757575),
  'qalqalah': Color(0xFF1565C0),
};

/// The app's names for the rules (lib/l10n/app_ar.arb, tajweed*).
const tajweedNames = <String, String>{
  'hamzat_wasl': 'همزة الوصل',
  'lam_shamsiyyah': 'اللام الشمسية',
  'silent': 'الحروف التي لا تُنطق',
  'madd_2': 'المد الطبيعي',
  'madd_246': 'المد العارض واللين',
  'madd_muttasil': 'المد المتصل',
  'madd_munfasil': 'المد المنفصل',
  'madd_6': 'المد اللازم',
  'ghunnah': 'الغنة',
  'ikhfa': 'الإخفاء',
  'ikhfa_shafawi': 'الإخفاء الشفوي',
  'iqlab': 'الإقلاب',
  'idghaam_ghunnah': 'الإدغام بغنة',
  'idghaam_no_ghunnah': 'الإدغام بلا غنة',
  'idghaam_shafawi': 'الإدغام الشفوي',
  'idghaam_mutajanisayn': 'إدغام المتجانسين',
  'idghaam_mutaqaribayn': 'إدغام المتقاربين',
  'qalqalah': 'القلقلة',
};

final _letter = RegExp(r'\p{L}', unicode: true);

/// Character spans of a word's letters (build_tajweed.letters).
List<(int, int)> letterSpans(String word) {
  final out = <List<int>>[];
  for (var i = 0; i < word.length; i++) {
    if (_letter.hasMatch(word[i]) || out.isEmpty) {
      out.add([i, i + 1]);
    } else {
      out.last[1] = i + 1;
    }
  }
  return [for (final s in out) (s[0], s[1])];
}

/// The verse in the mushaf font, each letter the data gives a rule to drawn
/// in that rule's colour (only its marks when the rule is on the marks).
/// A letter with two rules takes the first; the list under it has both.
class TajweedVerseView extends StatelessWidget {
  const TajweedVerseView({super.key, required this.verse, required this.marks});

  final Verse verse;
  final List<TajweedMark> marks;

  @override
  Widget build(BuildContext context) {
    final byLetter = <(int, int), TajweedMark>{};
    for (final m in marks) {
      byLetter.putIfAbsent((m.word, m.letter), () => m);
    }
    final tokens = verse.displayText.trim().split(RegExp(r'\s+'));
    final spans = <InlineSpan>[];
    var word = 0;
    for (var t = 0; t < tokens.length; t++) {
      final token = tokens[t];
      final counted = t < tokens.length - 1 && token != '۞';
      if (!counted) {
        spans.add(TextSpan(text: '$token '));
        continue;
      }
      word++;
      final letters = letterSpans(token);
      for (var l = 0; l < letters.length; l++) {
        final (start, end) = letters[l];
        final m = byLetter[(word, l)];
        final colour = m == null ? null : tajweedColours[m.rule];
        if (colour == null) {
          spans.add(TextSpan(text: token.substring(start, end)));
        } else if (m!.part == 'marks') {
          spans.add(TextSpan(text: token.substring(start, start + 1)));
          spans.add(TextSpan(text: token.substring(start + 1, end), style: TextStyle(color: colour)));
        } else {
          spans.add(TextSpan(text: token.substring(start, end), style: TextStyle(color: colour)));
        }
      }
      spans.add(const TextSpan(text: ' '));
    }
    final present = <String>{for (final m in marks) m.rule};
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Directionality(
        textDirection: TextDirection.rtl,
        child: Text.rich(
          TextSpan(children: spans),
          style: const TextStyle(fontFamily: mushafFont, fontSize: 34, height: 2.1),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 12, runSpacing: 4, children: [
        for (final r in tajweedColours.keys)
          if (present.contains(r))
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 12, height: 12, color: tajweedColours[r]),
              const SizedBox(width: 4),
              Text(tajweedNames[r] ?? r, style: Theme.of(context).textTheme.bodySmall),
            ]),
      ]),
    ]);
  }
}
