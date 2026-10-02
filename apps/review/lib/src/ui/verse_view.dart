import 'package:flutter/material.dart';

import '../model/model.dart';

/// The mushaf font (KFGQPC Hafs 2.0) for its own text.
const mushafFont = 'KFGQPCHafs';

/// Verses as in the mushaf (KFGQPC text, verbatim), with the linked words of
/// the first verse marked when the link has a word range.
class VerseView extends StatelessWidget {
  const VerseView({super.key, required this.verses, required this.link});

  final List<Verse> verses;
  final Link link;

  @override
  Widget build(BuildContext context) {
    final mark = Theme.of(context).colorScheme.primaryContainer;
    final spans = <InlineSpan>[];
    for (final v in verses) {
      final marked = link.wordFrom != null && v.ayah == link.ayahFrom;
      if (!marked) {
        spans.add(TextSpan(text: '${v.displayText} '));
        continue;
      }
      final parts = v.displayText.trim().split(RegExp(r'\s+'));
      for (var i = 0; i < parts.length; i++) {
        final n = i + 1; // 1-based word; the last part is the verse-number glyph
        final inRange = n >= link.wordFrom! && n <= (link.wordTo ?? link.wordFrom!) && i < parts.length - 1;
        spans.add(TextSpan(
          text: '${parts[i]} ',
          style: inRange ? TextStyle(backgroundColor: mark) : null,
        ));
      }
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(children: spans),
        style: const TextStyle(fontFamily: mushafFont, fontSize: 26, height: 2),
      ),
    );
  }
}
