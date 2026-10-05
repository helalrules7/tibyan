import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import '../books_providers.dart';
import '../data/book_pack.dart';
import 'quran_quotes.dart';

/// Opens «أسباب النزول» of a (Hafs) verse in a sheet.
Future<void> showAsbabSheet(
  BuildContext context, {
  required int surah,
  required int ayah,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.7,
    maxChildSize: 0.95,
    builder: (context, scroll) => SelectionArea(
      child: ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [AsbabSection(surah: surah, ayah: ayah)],
      ),
    ),
  ),
);

/// «أسباب النزول» of one verse: each reviewed entry of the installed
/// packs, its text exactly as the book has it, then where it is from.
/// Nothing at all when the feature is off, no reviewed pack is installed
/// or the verse has no entry.
class AsbabSection extends ConsumerWidget {
  const AsbabSection({super.key, required this.surah, required this.ayah});

  final int surah;
  final int ayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(asbabProvider((surah: surah, ayah: ayah)));
    if (entries.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l.asbabTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: t.goldText,
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final (i, e) in entries.indexed) ...[
          if (i > 0) const SizedBox(height: 12),
          BookEntryCard(entry: e),
        ],
      ],
    );
  }
}

/// The citation line of an entry: book, author, editor, publisher,
/// edition, volume and page, as the pack's source row gives them.
String bookCitation(AppLocalizations l, NumberFormatter digits, BookEntry e) {
  final s = e.source;
  final page = e.page == null
      ? null
      : e.pageEnd != null && e.pageEnd != e.page
      ? l.bookCitationPages(digits(e.page!), digits(e.pageEnd!))
      : l.bookCitationPage(digits(e.page!));
  return [
    '«${s.title}»',
    s.author,
    if (s.tahqiq != null) l.bookCitationTahqiq(s.tahqiq!),
    ?s.publisher,
    ?s.edition,
    if (e.volume != null) l.bookCitationVolume(digits(e.volume!)),
    ?page,
  ].join('، ');
}

/// One entry of a book: its heading and text verbatim, the verses it
/// quotes between ﴿ ﴾ in a colour of their own, then the citation and
/// the publisher's own citation wording when it has one.
class BookEntryCard extends ConsumerWidget {
  const BookEntryCard({super.key, required this.entry});

  final BookEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final settings = ref.watch(settingsProvider);
    final digits = NumberFormatter(Localizations.localeOf(context));
    final family = settings.tafsirFont == TafsirFont.naskh
        ? 'UthmanTahaNaskh'
        : settings.uiFont.family;
    final size = 19.0 * settings.tafsirFontScale;
    final body = TextStyle(
      fontFamily: family,
      fontSize: size,
      height: 1.9,
      color: t.ink,
    );
    final quote = TextStyle(color: t.goldText);
    final citation = bookCitation(l, digits, entry);
    final custom = entry.source.citation;
    final copy = [?entry.section, entry.text, '', citation, ?custom].join('\n');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: entry.section == null
                    ? const SizedBox.shrink()
                    : Text.rich(
                        TextSpan(
                          children: quranQuoteSpans(
                            entry.section!,
                            quoteStyle: quote,
                          ),
                        ),
                        textDirection: TextDirection.rtl,
                        style: body.copyWith(
                          fontSize: size * 0.85,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              IconButton(
                tooltip: l.copyText,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.copy, size: 18, color: t.muted),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: copy));
                  if (!context.mounted) return;
                  ScaffoldMessenger.maybeOf(context)
                      ?.showSnackBar(SnackBar(content: Text(l.copied)));
                },
              ),
            ],
          ),
          // The book's paragraphs are its line breaks, kept as they are.
          Text.rich(
            TextSpan(children: quranQuoteSpans(entry.text, quoteStyle: quote)),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.justify,
            style: body,
          ),
          const SizedBox(height: 10),
          Text(
            citation,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 12, color: t.muted),
          ),
          if (custom != null) ...[
            const SizedBox(height: 4),
            Text(
              custom,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 12, color: t.muted),
            ),
          ],
        ],
      ),
    );
  }
}
