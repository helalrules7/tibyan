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

/// The name of a kind of book, as its section is titled.
String bookKindTitle(AppLocalizations l, String kind) => switch (kind) {
  BookKind.asbabNuzul => l.asbabTitle,
  BookKind.munasabat => l.munasabatTitle,
  BookKind.wujuhNazair => l.wujuhTitle,
  BookKind.tafsir => l.bookKindTafsir,
  _ => kind,
};

/// Opens one book section of a (Hafs) verse in a sheet.
Future<void> showBookSheet(
  BuildContext context, {
  required BookSectionSpec spec,
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
        children: [BookSection(spec: spec, surah: surah, ayah: ayah)],
      ),
    ),
  ),
);

/// One book section of a verse («أسباب النزول»، «المناسبات»، a book
/// tafsir, «الوجوه والنظائر»): each reviewed entry of the installed packs,
/// its text exactly as the book has it, then where it is from. Nothing at
/// all when the section's flag is off, no reviewed pack is installed or
/// the verse (or word) has no entry.
class BookSection extends ConsumerWidget {
  const BookSection({
    super.key,
    required this.spec,
    required this.surah,
    required this.ayah,
    this.title,
    this.source,
    this.word,
    this.titleSize = 17,
  });

  final BookSectionSpec spec;
  final int surah;
  final int ayah;

  /// The heading (the kind's name when null).
  final String? title;

  /// One book only (its key).
  final String? source;

  /// One word of the verse (1-based).
  final int? word;
  final double titleSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(
      bookEntriesProvider((
        spec: spec,
        surah: surah,
        ayah: ayah,
        source: source,
        word: word,
      )),
    );
    if (entries.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final parentKind = spec.parentKind;
    final packs = parentKind == null
        ? const <BookPack>[]
        : ref.watch(installedBookPacksProvider);
    final children = <Widget>[];
    int? lastParent;
    for (final e in entries) {
      final parent = parentKind == null
          ? null
          : bookParentOf(packs, e, kind: parentKind);
      if (children.isNotEmpty) children.add(const SizedBox(height: 12));
      if (parent != null && parent.id != lastParent) {
        children
          ..add(BookEntryCard(entry: parent, asContext: true))
          ..add(const SizedBox(height: 8));
      }
      lastParent = parent?.id;
      children.add(
        BookEntryCard(
          entry: e,
          showRange: spec.showRange,
          showSection: parent == null,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title ?? bookKindTitle(l, spec.kind),
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: t.goldText,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...children,
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
/// the publisher's own citation wording when it has one. Other brackets
/// (OpenITI texts quote verses between { }) are left as they are.
class BookEntryCard extends ConsumerWidget {
  const BookEntryCard({
    super.key,
    required this.entry,
    this.showRange = false,
    this.showSection = true,
    this.asContext = false,
  });

  final BookEntry entry;

  /// Says which verses the entry covers when it covers several.
  final bool showRange;

  /// Shows the book's heading of the entry (it is copied either way).
  final bool showSection;

  /// Shown as the context of the entries under it (a word header): a
  /// lighter card.
  final bool asContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final settings = ref.watch(settingsProvider);
    final digits = NumberFormatter(Localizations.localeOf(context));
    final family = settings.tafsirFont == TafsirFont.naskh
        ? 'UthmanTahaNaskh'
        : settings.uiFont.family;
    final size = 19.0 * settings.tafsirFontScale * (asContext ? 0.9 : 1);
    final body = TextStyle(
      fontFamily: family,
      fontSize: size,
      height: 1.9,
      color: asContext ? t.muted : t.ink,
    );
    final quote = TextStyle(color: t.goldText);
    final citation = bookCitation(l, digits, entry);
    final custom = entry.source.citation;
    final copy = [?entry.section, entry.text, '', citation, ?custom].join('\n');
    final link = entry.link;
    final range = showRange && link != null && link.isRange
        ? l.bookEntryVerses(digits(link.ayahFrom), digits(link.ayahTo))
        : null;
    final section = showSection ? entry.section : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: asContext ? null : t.bg,
        border: asContext ? Border.all(color: t.border) : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: section == null
                    ? const SizedBox.shrink()
                    : Text.rich(
                        TextSpan(
                          children: quranQuoteSpans(section, quoteStyle: quote),
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
          if (range != null) ...[
            Text(
              range,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: t.goldText,
              ),
            ),
            const SizedBox(height: 4),
          ],
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
