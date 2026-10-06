import 'package:flutter/material.dart';

import '../../../../core/db/content_database.dart';
import '../../../../core/db/user_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../mushaf_screen.dart';
import 'illuminated_frame.dart';
import 'mushaf_page.dart';

/// Services for the selected verses: listening, tafsir and translation,
/// the four one-tap marks, copying and sharing (as text and as a picture of
/// the page) and saving to a named fasil.
class VerseServicesPanel extends StatelessWidget {
  const VerseServicesPanel({
    super.key,
    required this.verses,
    required this.surahs,
    required this.onMark,
    required this.onSaveToFasil,
    required this.onClose,
    required this.onMultiSelect,
    required this.onTafsir,
    required this.onListen,
    required this.onWordStudy,
    required this.onWordMeanings,
    this.onReflect,
    this.onCopy,
    this.onShareText,
    this.onShareImage,
    this.preview,
    this.similarCount = 0,
    this.onSimilar,
    this.asbabCount = 0,
    this.onAsbab,
    this.onTafsirAudio,
    this.munasabatCount = 0,
    this.onMunasabat,
    this.embedded = false,
  });

  /// Inside focus mode's window: no sheet of its own (no handle, no close
  /// button), the window around it is the surface.
  final bool embedded;

  /// «استمع للتفسير»: shown only when a tafsir recording has the selected
  /// verse (the feature is on and its index lists the verse).
  final VoidCallback? onTafsirAudio;

  /// Reviewed occasions of revelation of the selected verse («أسباب
  /// النزول»); the button shows only when there are some (the feature is
  /// on and a reviewed pack has entries for the verse).
  final int asbabCount;
  final VoidCallback? onAsbab;

  /// Reviewed munasabat of the selected verse («المناسبات»), shown like
  /// [asbabCount].
  final int munasabatCount;
  final VoidCallback? onMunasabat;

  /// Passages similar to the selected verse (mutashabihat); the button
  /// shows only when there are some.
  final int similarCount;
  final VoidCallback? onSimilar;

  final List<VerseKey> verses;
  final List<SurahRow>? surahs;
  final ValueChanged<MarkKind> onMark;
  final VoidCallback onSaveToFasil;
  final VoidCallback onClose;
  final VoidCallback onMultiSelect;
  final VoidCallback onTafsir;
  final VoidCallback onListen;

  /// Word study: the next tap on the page picks the word.
  /// Null where the edition has no word data (the riwaya editions): the
  /// button is shown disabled.
  final VoidCallback? onWordStudy;

  /// The meanings of the selected verses' words («الميسر في غريب القرآن»).
  final VoidCallback onWordMeanings;

  /// Writes a note on the first selected verse (tadabbur journal).
  final VoidCallback? onReflect;

  /// Copy and share the selected verses. A null callback hides its button
  /// (the riwaya editions have no text that reads right outside the app).
  final VoidCallback? onCopy;
  final VoidCallback? onShareText;
  final VoidCallback? onShareImage;

  /// The reader's chosen texts for the first selected verse (a translation
  /// or al-Muyassar), shown under the title; null for the Arabic only.
  final Widget? preview;

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

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!embedded) ...[
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
        ],
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l.servicesTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
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
            if (!embedded)
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
          ],
        ),
        if (preview != null)
          Container(
            constraints: const BoxConstraints(maxHeight: 140),
            margin: const EdgeInsets.only(top: 4),
            child: SingleChildScrollView(child: preview),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onListen,
                icon: const Icon(Icons.play_arrow),
                label: Text(l.listen),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: onTafsir,
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(l.tafsirTitle),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onWordStudy,
                icon: const Icon(Icons.touch_app_outlined),
                label: Text(l.wordStudy),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onWordMeanings,
                icon: const Icon(Icons.notes),
                label: Text(l.wordMeanings),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
        if (onTafsirAudio != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onTafsirAudio,
            icon: const Icon(Icons.headphones_outlined),
            label: Text(l.tafsirAudioListen),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
        if (asbabCount > 0 && onAsbab != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onAsbab,
            icon: const Icon(Icons.history_edu_outlined),
            label: Text(l.asbabCount(digits(asbabCount))),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
        if (munasabatCount > 0 && onMunasabat != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onMunasabat,
            icon: const Icon(Icons.link),
            label: Text(l.munasabatCount(digits(munasabatCount))),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
        if (similarCount > 0 && onSimilar != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onSimilar,
            icon: const Icon(Icons.compare_arrows),
            label: Text(l.similarCount(digits(similarCount))),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
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
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onMultiSelect,
                icon: const Icon(Icons.format_line_spacing),
                label: Text(l.multiSelect),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
            if (onReflect != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReflect,
                  icon: const Icon(Icons.edit_note_outlined),
                  label: Text(l.journalAdd),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (onCopy != null || onShareText != null || onShareImage != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (onCopy != null)
                Expanded(
                  child: _ShareButton(
                    icon: Icons.copy_outlined,
                    label: l.copyVerses,
                    onTap: onCopy!,
                  ),
                ),
              if (onShareText != null)
                Expanded(
                  child: _ShareButton(
                    icon: Icons.ios_share,
                    label: l.shareVerseText,
                    onTap: onShareText!,
                  ),
                ),
              if (onShareImage != null)
                Expanded(
                  child: _ShareButton(
                    icon: Icons.image_outlined,
                    label: l.shareVerseImage,
                    onTap: onShareImage!,
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: onSaveToFasil,
          icon: const Icon(Icons.bookmark_add_outlined),
          label: Text(l.fasilSaveHere),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      ],
    );
    if (embedded) return body;
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
          child: body,
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
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
