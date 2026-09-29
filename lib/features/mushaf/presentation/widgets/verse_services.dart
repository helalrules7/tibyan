import 'package:flutter/material.dart';

import '../../../../core/db/content_database.dart';
import '../../../../core/db/user_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../mushaf_screen.dart';
import 'illuminated_frame.dart';
import 'mushaf_page.dart';

/// Services for the selected verses: the four one-tap marks and saving to
/// a named fasil. Services whose data is not enabled yet (tafsir,
/// translation, recitation, copy and share) are not shown.
class VerseServicesPanel extends StatelessWidget {
  const VerseServicesPanel({
    super.key,
    required this.verses,
    required this.surahs,
    required this.onMark,
    required this.onSaveToFasil,
    required this.onClose,
  });

  final List<VerseKey> verses;
  final List<SurahRow>? surahs;
  final ValueChanged<MarkKind> onMark;
  final VoidCallback onSaveToFasil;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final first = verses.first;
    final last = verses.last;
    final name = surahs == null
        ? ''
        : surahName(context, surahs![first.surah - 1]);
    final count = verses.length == 2
        ? l.twoVerses
        : l.versesCount(digits(verses.length));
    final title = verses.length == 1
        ? '${l.surahWord(name)} · ${l.verseSelected(digits(first.ayah))}'
        : first.surah == last.surah
        ? '${l.verseRange(name, digits(first.ayah), digits(last.ayah))} · $count'
        : count;
    final marks = [
      (MarkKind.reading, l.markReading),
      (MarkKind.review, l.markReview),
      (MarkKind.hifz, l.markHifz),
      (MarkKind.tadabbur, l.markTadabbur),
    ];

    return Material(
      color: t.paper,
      elevation: 12,
      shadowColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: t.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.servicesTitle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            title,
                            style: TextStyle(fontSize: 12, color: t.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l.cancel,
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final (kind, label) in marks)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _MarkButton(
                          color: Color(kind.color),
                          label: label,
                          onTap: () => onMark(kind),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: onSaveToFasil,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(l.fasilSaveHere),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarkButton extends StatelessWidget {
  const _MarkButton({
    required this.color,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Material(
      color: t.bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bookmark, color: color, size: 26),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 12, color: t.ink)),
            ],
          ),
        ),
      ),
    );
  }
}
