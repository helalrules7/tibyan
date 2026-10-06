import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mushaf_repository.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../hifz/domain/strength.dart';
import '../../hifz/hifz_providers.dart';
import '../../hifz/presentation/strength_style.dart';
import '../../khatma/khatma_providers.dart';
import '../data/riwaya_data.dart';
import '../mushaf_providers.dart';
import 'navigation.dart';
import 'widgets/illuminated_frame.dart' show NumberFormatter;

/// A verse's cell for the hifz map: `surah:ayah`, its surah, and its pages
/// in the new Madina, old Madina and Shamarly editions (the Shamarly's
/// first and last: a verse may run over a page break).
typedef VerseCell = (String, int, int, int, int, int);

/// The pages of [edition] a verse is on, from its [cell]. A riwaya's
/// pages come from its pack ([riwaya]); null when they are not known.
List<int> verseCellPages(
  VerseCell cell,
  MushafEdition edition, [
  RiwayaData? riwaya,
]) {
  final (ref, _, p1441, p1405, sh0, sh1) = cell;
  return switch (edition) {
    MushafEdition.madina1441 => [p1441],
    MushafEdition.madina1405 => [p1405],
    MushafEdition.shamarly => [for (var p = sh0; p <= sh1; p++) p],
    _ when riwaya != null => [_riwayaPage(riwaya, ref)],
    _ => const [],
  };
}

int _riwayaPage(RiwayaData riwaya, String ref) {
  final (surah, ayah) = parseVerseRef(ref);
  final k = editionKeyOf(riwaya, surah, ayah);
  return riwaya.pageOf(k.surah, k.ayah);
}

/// The pages of [to] read in a khatma kept in [from], whose pages [read]:
/// a page counts once every verse on it is on a page read. A riwaya's
/// khatma counts only in that riwaya (its pages cannot be told apart in
/// another edition, nor another's in it).
Set<int> readPagesIn(
  Set<int> read, {
  required MushafEdition from,
  required MushafEdition to,
  required List<VerseCell> cells,
}) {
  if (from == to) return read;
  if (from.isRiwaya || to.isRiwaya) return const {};
  final all = <int, bool>{};
  for (final c in cells) {
    final done = verseCellPages(c, from).every(read.contains);
    for (final p in verseCellPages(c, to)) {
      all[p] = (all[p] ?? true) && done;
    }
  }
  return {
    for (final e in all.entries)
      if (e.value) e.key,
  };
}

/// What the pages map shows of one page.
@immutable
class PageMark {
  const PageMark({
    this.read = false,
    this.strength = Strength.none,
    this.marks = const [],
  });

  /// Read in the current khatma.
  final bool read;

  /// The memorization strength of its weakest memorized verse.
  final Strength strength;

  /// The colours of the bookmarks and fawasil on it.
  final List<Color> marks;
}

/// The pages of the edition being read, grouped by juz, with what each
/// one holds for the reader.
@immutable
class PagesMapData {
  const PagesMapData({
    required this.pageCount,
    required this.juzStarts,
    required this.pages,
    required this.khatma,
  });

  final int pageCount;

  /// The page each juz starts on, juz 1 first.
  final List<int> juzStarts;
  final Map<int, PageMark> pages;

  /// Whether a khatma is under way (its pages are marked read).
  final bool khatma;

  PageMark of(int page) => pages[page] ?? const PageMark();

  /// The pages of each juz, juz 1 first: from its start to the page before
  /// the next juz's (the pages before juz 1, a cover, go with it).
  List<(int juz, int first, int last)> groups() {
    final out = <(int, int, int)>[];
    for (var j = 0; j < juzStarts.length; j++) {
      final first = j == 0 ? 1 : juzStarts[j];
      final last = j + 1 < juzStarts.length ? juzStarts[j + 1] - 1 : pageCount;
      if (last >= first) out.add((j + 1, first, last));
    }
    return out;
  }
}

/// The map of the edition being read: its khatma progress, the hifz
/// strengths (as the hifz map colours them) and the marks, by page.
final pagesMapProvider = FutureProvider<PagesMapData>((ref) async {
  final edition = ref.watch(editionProvider);
  final riwaya = await ref.watch(riwayaDataProvider.future);
  final cells = await ref.watch(verseCellsProvider.future);
  final strengths = await ref.watch(verseStrengthsProvider.future);
  final status = await ref.watch(khatmaStatusProvider.future);
  final marks = await ref.watch(bookmarkSetsProvider.future);
  final starts = riwaya != null
      ? [for (final v in riwaya.juzStarts()) v.page]
      : [
          for (final j in await ref.watch(juzStartsProvider.future))
            j.ayah.pageIn(edition),
        ];

  final byRef = {for (final c in cells) c.$1: c};
  List<int> pagesOf(String ref) {
    final c = byRef[ref];
    if (c != null) return verseCellPages(c, edition, riwaya);
    return riwaya == null ? const [] : [_riwayaPage(riwaya, ref)];
  }

  final levels = cellStrengths(strengths, pagesOf);
  final read = status == null
      ? const <int>{}
      : readPagesIn(
          status.read,
          from: status.edition,
          to: edition,
          cells: cells,
        );
  final marked = <int, List<Color>>{};
  for (final m in marks) {
    for (final p in pagesOf(verseRef(m.surah, m.ayah))) {
      (marked[p] ??= []).add(Color(m.color));
    }
  }
  return PagesMapData(
    pageCount: edition.pageCount,
    juzStarts: starts,
    khatma: status != null,
    pages: {
      for (var p = 1; p <= edition.pageCount; p++)
        if (read.contains(p) || levels[p] != null || marked[p] != null)
          p: PageMark(
            read: read.contains(p),
            strength: levels[p] ?? Strength.none,
            marks: marked[p] ?? const [],
          ),
    },
  );
});

/// The index's pages tab: every page of the edition being read, by juz,
/// coloured by its memorization strength, ticked where the khatma has
/// read it, flagged where a mark is, the reader's page ringed. A tap
/// opens the page.
class PagesMap extends ConsumerStatefulWidget {
  const PagesMap({super.key, this.current});

  /// The page the reader came from.
  final int? current;

  @override
  ConsumerState<PagesMap> createState() => _PagesMapState();
}

class _PagesMapState extends ConsumerState<PagesMap> {
  ScrollController? _scroll;

  static const _header = 40.0;
  static const _gap = 6.0;
  static const _side = 12.0;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(pagesMapProvider).value;
    if (data == null) return Center(child: Text(l.loadingLabel));
    final groups = data.groups();
    return Column(
      children: [
        _Legend(khatma: data.khatma),
        const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              // Cells about 46 px, never fewer than five a row; at most a
              // juz (twenty pages) a row on a wide screen.
              final width = box.maxWidth - 2 * _side;
              final count = ((width + _gap) / (46 + _gap)).floor().clamp(5, 20);
              final cell = (width - _gap * (count - 1)) / count;
              final row = cell.clamp(44.0, 56.0);
              double groupHeight(int pages) {
                final rows = (pages + count - 1) ~/ count;
                return _header + rows * row + (rows - 1) * _gap + _gap;
              }

              _scroll ??= ScrollController(
                initialScrollOffset: () {
                  final page = widget.current;
                  if (page == null) return 0.0;
                  var y = 0.0;
                  for (final (_, first, last) in groups) {
                    if (page >= first && page <= last) {
                      final r = (page - first) ~/ count;
                      // The current row a little below the top.
                      return (y + _header + r * (row + _gap) - row * 1.5).clamp(
                        0.0,
                        double.infinity,
                      );
                    }
                    y += groupHeight(last - first + 1);
                  }
                  return 0.0;
                }(),
              );
              return CustomScrollView(
                controller: _scroll,
                slivers: [
                  for (final (juz, first, last) in groups) ...[
                    SliverToBoxAdapter(
                      child: _JuzHeader(
                        juz: juz,
                        first: first,
                        last: last,
                        read: data.khatma
                            ? [
                                for (var p = first; p <= last; p++)
                                  if (data.of(p).read) p,
                              ].length
                            : null,
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(_side, 0, _side, _gap),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: count,
                          mainAxisExtent: row,
                          mainAxisSpacing: _gap,
                          crossAxisSpacing: _gap,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _PageCell(
                            page: first + i,
                            mark: data.of(first + i),
                            current: first + i == widget.current,
                            onTap: () => openPage(context, ref, first + i),
                          ),
                          childCount: last - first + 1,
                        ),
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The juz's name, its pages, and how many of them the khatma has read.
class _JuzHeader extends StatelessWidget {
  const _JuzHeader({
    required this.juz,
    required this.first,
    required this.last,
    required this.read,
  });

  final int juz;
  final int first;
  final int last;
  final int? read;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final total = last - first + 1;
    return Semantics(
      header: true,
      child: SizedBox(
        height: _PagesMapState._header,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _PagesMapState._side),
          child: Row(
            children: [
              Text(
                l.juzLabel(digits(juz)),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: t.ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l.pagesRange(digits(first), digits(last)),
                style: TextStyle(fontSize: 12, color: t.muted),
              ),
              const Spacer(),
              if (read case final n? when n > 0)
                Text(
                  l.pagesMapJuzRead(digits(n), digits(total)),
                  style: TextStyle(fontSize: 12, color: t.muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageCell extends StatelessWidget {
  const _PageCell({
    required this.page,
    required this.mark,
    required this.current,
    required this.onTap,
  });

  final int page;
  final PageMark mark;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tokens = context.tokens;
    final t = tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final strength = mark.strength;
    final memorized = strength != Strength.none;
    final fill = memorized
        ? strengthFill(strength, tokens.mode)
        : mark.read
        ? readFill(context)
        : t.paper;
    final ink = memorized ? strengthInk(strength, tokens.mode, t.ink) : t.ink;
    final spoken = [
      l.pageOf(digits(page)),
      if (current) l.pagesMapCurrent,
      if (mark.read) l.pagesMapRead,
      if (memorized) strengthLabel(l, strength),
      if (mark.marks.isNotEmpty) l.pagesMapMarked,
    ].join('، ');
    return Semantics(
      button: true,
      selected: current,
      label: spoken,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: current
              ? BorderSide(color: t.control, width: 2.5)
              : BorderSide(color: t.border, width: 0.8),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        digits(page),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: current
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: ink,
                        ),
                      ),
                    ),
                    if (mark.read || memorized)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (mark.read)
                            Icon(
                              Icons.check,
                              size: 11,
                              color: memorized ? ink : t.control,
                            ),
                          if (memorized)
                            StrengthBars(
                              strength: strength,
                              color: ink,
                              height: 8,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              if (mark.marks.isNotEmpty)
                PositionedDirectional(
                  top: -1,
                  end: 3,
                  child: Icon(
                    Icons.bookmark,
                    size: 13,
                    color: mark.marks.first,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The fill of a page read in the khatma and not memorized: a light wash
/// of the theme's control colour.
Color readFill(BuildContext context) {
  final tokens = context.tokens;
  return Color.alphaBlend(
    tokens.colors.control.withValues(alpha: tokens.mode.isLight ? 0.16 : 0.3),
    tokens.colors.paper,
  );
}

/// What the colours and marks mean, in one or two short lines.
class _Legend extends StatelessWidget {
  const _Legend({required this.khatma});

  final bool khatma;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tokens = context.tokens;
    final t = tokens.colors;
    const text = TextStyle(fontSize: 11.5, height: 1.2);
    Widget item(Widget swatch, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: 4),
        Text(label, style: text),
      ],
    );
    Widget box({Color? fill, BorderSide? side, Widget? child}) => Container(
      width: 22,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill ?? t.paper,
        borderRadius: BorderRadius.circular(4),
        border: Border.fromBorderSide(
          side ?? BorderSide(color: t.border, width: 0.8),
        ),
      ),
      child: child,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          item(
            box(side: BorderSide(color: t.control, width: 2)),
            l.pagesMapCurrent,
          ),
          if (khatma)
            item(
              box(
                fill: readFill(context),
                child: Icon(Icons.check, size: 11, color: t.control),
              ),
              l.pagesMapRead,
            ),
          item(
            Icon(Icons.bookmark, size: 15, color: t.goldText),
            l.pagesMapMarked,
          ),
          for (final s in Strength.values.skip(1))
            item(
              box(
                fill: strengthFill(s, tokens.mode),
                child: StrengthBars(
                  strength: s,
                  color: strengthInk(s, tokens.mode, t.ink),
                  height: 9,
                ),
              ),
              strengthLabel(l, s),
            ),
        ],
      ),
    );
  }
}
