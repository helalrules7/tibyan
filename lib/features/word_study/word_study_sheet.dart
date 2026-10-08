import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/content_database.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../books/books_providers.dart';
import '../books/presentation/book_section.dart';
import '../books/presentation/quran_quotes.dart';
import '../mushaf/data/mushaf_repository.dart';
import '../mushaf/mushaf_providers.dart';
import '../mushaf/presentation/mushaf_screen.dart';
import '../mushaf/presentation/source_names.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart';
import 'data/word_study_repository.dart';
import 'word_study_providers.dart';
import '../mushaf/presentation/navigation.dart';
import '../khatma/domain/khatmah.dart' show EntryPoint;

/// Opens «دراسة الكلمة» for a word of a verse; [word] null lets the reader
/// choose one of the verse's words first.
Future<void> showWordStudy(
  BuildContext context, {
  required int surah,
  required int ayah,
  int? word,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.72,
    minChildSize: 0.4,
    maxChildSize: 0.95,
    builder: (context, scroll) =>
        WordStudySheet(surah: surah, ayah: ayah, word: word, scroll: scroll),
  ),
);

/// Opens «معاني الكلمات»: the book's entries for [verses], in order.
Future<void> showVerseMeanings(
  BuildContext context, {
  required List<VerseRef> verses,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.6,
    minChildSize: 0.3,
    maxChildSize: 0.95,
    builder: (sheet, scroll) => VerseMeaningsSheet(
      verses: verses,
      scroll: scroll,
      // The sheet closes first; the word study opens from the caller's
      // context, which stays mounted.
      onStudy: (g) {
        Navigator.of(sheet).pop();
        if (!context.mounted) return;
        showWordStudy(context, surah: g.surah, ayah: g.ayah, word: g.wordFrom);
      },
    ),
  ),
);

/// The credit line of a source, in the interface language.
String? _credit(BuildContext context, List<SourceRow>? sources, String key) {
  final lang = Localizations.localeOf(context).languageCode;
  final named = sourceText(key, lang)?.credit;
  if (named != null) return named;
  for (final s in sources ?? const <SourceRow>[]) {
    if (s.key == key) return s.attribution;
  }
  return null;
}

const _gharibKey = 'nuqayah-almuyassar-gharib';
const _corpusKey = 'quranic-corpus';

/// The word, its meaning in «الميسر في غريب القرآن», its root and lemma
/// (Quranic Arabic Corpus), and every verse where the root occurs.
/// Everything shown is quoted from those sources; a word without an entry
/// shows none.
class WordStudySheet extends ConsumerStatefulWidget {
  const WordStudySheet({
    super.key,
    required this.surah,
    required this.ayah,
    this.word,
    this.scroll,
  });

  final int surah;
  final int ayah;
  final int? word;
  final ScrollController? scroll;

  @override
  ConsumerState<WordStudySheet> createState() => _WordStudySheetState();
}

class _WordStudySheetState extends ConsumerState<WordStudySheet> {
  late int? _word = widget.word;

  VerseRef get _verse => (surah: widget.surah, ayah: widget.ayah);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final surahs = ref.watch(surahsProvider).value;
    final sources = ref.watch(sourcesProvider).value;
    final row = ref.watch(verseRowProvider(_verse)).value;
    final words = row == null ? const <String>[] : verseWords(row);
    final gharib = ref.watch(verseGharibProvider(_verse)).value;
    final word = _word != null && _word! <= words.length ? _word : null;
    final root = word == null
        ? null
        : ref.watch(
            wordRootProvider((
              surah: widget.surah,
              ayah: widget.ayah,
              word: word,
            )),
          );
    final rootText = root?.value?.root;
    final occurrences = rootText == null
        ? null
        : ref.watch(rootOccurrencesProvider(rootText));
    final name = surahs == null
        ? ''
        : surahName(context, surahs[widget.surah - 1]);
    const quran = TextStyle(fontFamily: 'UthmanicHafs', height: 1.8);

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: t.goldText,
          ),
        ),
      ),
    );

    Widget note(String text) =>
        Text(text, style: TextStyle(fontSize: 13, color: t.muted, height: 1.6));

    Widget credit(String key) {
      final c = _credit(context, sources, key);
      return c == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(c, style: TextStyle(fontSize: 11, color: t.muted)),
            );
    }

    final meanings = word == null || gharib == null
        ? const <GharibRow>[]
        : meaningsOfWord(gharib, word);
    final found = occurrences?.value;
    // al-Damghani's senses of this word here, from a reviewed pack.
    final BookQuery? wujuh = word == null
        ? null
        : (
            spec: BookSectionSpec.wujuh,
            surah: widget.surah,
            ayah: widget.ayah,
            source: null,
            word: word,
          );
    final hasWujuh =
        wujuh != null && ref.watch(bookEntriesProvider(wujuh)).isNotEmpty;

    return CustomScrollView(
      controller: widget.scroll,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          sliver: SliverList.list(
            children: [
              Semantics(
                header: true,
                child: Text(
                  l.wordStudy,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                l.wordStudyVerse(l.surahWord(name), digits(widget.ayah)),
                style: TextStyle(fontSize: 12, color: t.muted),
              ),
              const SizedBox(height: 10),
              // The verse's words: the one studied is marked; any other can
              // be chosen from here.
              Wrap(
                textDirection: TextDirection.rtl,
                spacing: 4,
                runSpacing: 2,
                children: [
                  for (final (i, w) in words.indexed)
                    ChoiceChip(
                      key: ValueKey('word-${i + 1}'),
                      label: Text(
                        w,
                        style: quran.copyWith(fontSize: 18, color: t.ink),
                      ),
                      selected: word == i + 1,
                      showCheckmark: false,
                      selectedColor: t.highlight,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _word = i + 1),
                    ),
                ],
              ),
              if (word == null) ...[
                const SizedBox(height: 12),
                note(l.wordStudyChoose),
              ] else ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    words[word - 1],
                    textDirection: TextDirection.rtl,
                    style: quran.copyWith(fontSize: 38, color: t.ink),
                  ),
                ),
                section(l.wordMeaningTitle),
                if (gharib != null && meanings.isEmpty)
                  note(l.wordNoMeaning)
                else ...[
                  for (final g in meanings) _GharibEntry(entry: g),
                  if (meanings.isNotEmpty) credit(_gharibKey),
                ],
                section(l.wordRootTitle),
                if (root != null && root.hasValue)
                  ...switch (root.value) {
                    null => [note(l.wordNoCorpusData)],
                    final r => [
                      if (r.root != null)
                        Text(
                          r.root!,
                          key: const ValueKey('root'),
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 26,
                            wordSpacing: 6,
                            fontWeight: FontWeight.w700,
                            color: t.ink,
                          ),
                        )
                      else
                        note(l.wordNoRoot),
                      if (r.lemma != null)
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${l.wordLemma}: ',
                                style: TextStyle(fontSize: 13, color: t.muted),
                              ),
                              TextSpan(
                                text: r.lemma,
                                style: quran.copyWith(
                                  fontSize: 22,
                                  color: t.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      credit(_corpusKey),
                    ],
                  },
                if (hasWujuh)
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: BookSection(
                      spec: BookSectionSpec.wujuh,
                      surah: widget.surah,
                      ayah: widget.ayah,
                      word: word,
                      titleSize: 15,
                    ),
                  ),
                if (rootText != null) ...[
                  section(l.rootOccurrencesTitle),
                  if (found != null)
                    note(
                      l.rootOccurrencesCount(
                        digits(found.wordCount),
                        digits(found.verses.length),
                      ),
                    ),
                  const SizedBox(height: 6),
                ],
              ],
            ],
          ),
        ),
        if (word != null && found != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.builder(
              itemCount: found.verses.length,
              itemBuilder: (context, i) => _Occurrence(
                occurrence: found.verses[i],
                surahs: surahs,
                current:
                    found.verses[i].ayah.surah == widget.surah &&
                    found.verses[i].ayah.number == widget.ayah,
              ),
            ),
          )
        else
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

/// One entry of the book: the quoted words between ﴿ ﴾ and the
/// explanation after them, both verbatim.
class _GharibEntry extends StatelessWidget {
  const _GharibEntry({required this.entry});

  final GharibRow entry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            // The brackets in the text font: the Hafs font draws them as
            // verse ornaments.
            ...quranQuoteSpans(
              '$quoteOpen${entry.phrase}$quoteClose',
              quoteStyle: TextStyle(
                fontFamily: 'UthmanicHafs',
                fontSize: 20,
                color: t.goldText,
              ),
              bracketStyle: TextStyle(color: t.goldText),
            ),
            const TextSpan(text: ': '),
            TextSpan(text: entry.body),
          ],
        ),
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'UthmanTahaNaskh',
          fontSize: 18,
          height: 1.9,
          color: t.ink,
        ),
      ),
    );
  }
}

/// A verse where the root occurs, its root words marked; a tap opens its
/// page with the verse selected.
class _Occurrence extends ConsumerWidget {
  const _Occurrence({
    required this.occurrence,
    required this.surahs,
    required this.current,
  });

  final RootOccurrence occurrence;
  final List<SurahRow>? surahs;
  final bool current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final a = occurrence.ayah;
    final words = verseWords(a);
    final name = surahs == null ? '' : surahName(context, surahs![a.surah - 1]);
    return Card(
      color: current ? t.highlight : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // A Hafs verse: in a riwaya edition, the page of the riwaya verse
          // that holds it.
          final router = GoRouter.of(context);
          final navigator = Navigator.of(context);
          final page = await ref.read(
            versePageProvider((a.surah, a.number)).future,
          );
          navigator.pop();
          router.go(
            mushafLocation(
              page,
              surah: a.surah,
              ayah: a.number,
              entry: EntryPoint.search,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.wordStudyVerse(l.surahWord(name), digits(a.number)),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: t.goldText,
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    for (final (i, w) in words.indexed) ...[
                      TextSpan(
                        text: w,
                        style: occurrence.words.contains(i + 1)
                            ? TextStyle(backgroundColor: t.highlight)
                            : null,
                      ),
                      const TextSpan(text: ' '),
                    ],
                    TextSpan(
                      text: a.displayNumber,
                      style: TextStyle(color: t.marker),
                    ),
                  ],
                ),
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'UthmanicHafs',
                  fontSize: 19,
                  height: 1.9,
                  color: t.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «معاني الكلمات»: every entry of the book for the chosen verses, in its
/// order. An entry tied to words opens their word study.
class VerseMeaningsSheet extends ConsumerWidget {
  const VerseMeaningsSheet({
    super.key,
    required this.verses,
    this.scroll,
    this.onStudy,
  });

  final List<VerseRef> verses;
  final ScrollController? scroll;

  /// Opens the word study of an entry tied to words.
  final ValueChanged<GharibRow>? onStudy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final surahs = ref.watch(surahsProvider).value;
    final sources = ref.watch(sourcesProvider).value;
    final credit = _credit(context, sources, _gharibKey);
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Semantics(
          header: true,
          child: Text(
            l.wordMeanings,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        for (final v in verses) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 4),
            child: Text(
              l.wordStudyVerse(
                l.surahWord(
                  surahs == null ? '' : surahName(context, surahs[v.surah - 1]),
                ),
                digits(v.ayah),
              ),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: t.goldText,
              ),
            ),
          ),
          ...switch (ref.watch(verseGharibProvider(v)).value) {
            null => const [SizedBox(height: 24)],
            final entries when entries.isEmpty => [
              Text(
                l.verseNoMeanings,
                style: TextStyle(fontSize: 13, color: t.muted),
              ),
            ],
            final entries => [
              for (final g in entries)
                InkWell(
                  onTap: g.wordFrom == null || onStudy == null
                      ? null
                      : () => onStudy!(g),
                  child: _GharibEntry(entry: g),
                ),
            ],
          },
        ],
        if (credit != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(credit, style: TextStyle(fontSize: 11, color: t.muted)),
          ),
      ],
    );
  }
}
