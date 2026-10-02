import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_database.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/mushaf_repository.dart';
import '../mushaf_providers.dart';
import 'mushaf_screen.dart';
import 'navigation.dart';

/// Removes Arabic marks and unifies alef forms, for matching surah names.
String _fold(String s) => s
    .replaceAll(RegExp('[ً-ْٰـ]'), '')
    .replaceAll(RegExp('[آأإٱ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .toLowerCase();

/// A "surah:ayah" reference such as 2:255, 2 255 or ٢:٢٥٥.
({int surah, int ayah})? parseVerseRef(String input) {
  final latin = input.replaceAllMapped(
    RegExp('[٠-٩]'),
    (m) => '${m[0]!.codeUnitAt(0) - 0x0660}',
  );
  final m = RegExp(r'^\s*(\d{1,3})\s*[:：.\s]\s*(\d{1,3})\s*$')
      .firstMatch(latin);
  if (m == null) return null;
  return (surah: int.parse(m[1]!), ayah: int.parse(m[2]!));
}

enum IndexTab { surahs, juz, hizb, pages, marks }

/// Row height in the index lists, fixed so the current row can be
/// scrolled into view before it is built.
const _rowExtent = 72.0;

class IndexScreen extends ConsumerStatefulWidget {
  const IndexScreen({
    super.key,
    this.tab = IndexTab.surahs,
    this.surah,
    this.juz,
    this.hizb,
    this.page,
  });

  final IndexTab tab;

  /// The reader's current place, highlighted and scrolled to.
  final int? surah;
  final int? juz;
  final int? hizb;
  final int? page;

  @override
  ConsumerState<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends ConsumerState<IndexScreen> {
  String _query = '';

  Future<void> _goToRef(
    ({int surah, int ayah}) r,
    List<SurahRow> surahs,
  ) async {
    if (r.surah < 1 || r.surah > 114) return;
    // In a riwaya edition, a typed reference is in the riwaya's own count.
    final riwaya = await ref.read(riwayaDataProvider.future);
    if (!mounted) return;
    if (riwaya != null) {
      final ayah = r.ayah.clamp(1, riwaya.surahCounts[r.surah - 1]);
      await openPage(context, ref, riwaya.pageOf(r.surah, ayah));
      return;
    }
    final ayah = r.ayah.clamp(1, surahs[r.surah - 1].ayahCount);
    await openVerse(context, ref, surah: r.surah, ayah: ayah);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final surahs = ref.watch(surahsProvider).value;
    final riwaya = ref.watch(riwayaDataProvider).value;

    return DefaultTabController(
      length: IndexTab.values.length,
      initialIndex: widget.tab.index,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.indexTitle),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l.tabSurahs),
              Tab(text: l.tabJuz),
              Tab(text: l.tabHizb),
              Tab(text: l.tabPages),
              Tab(text: l.tabMarks),
            ],
          ),
        ),
        body: surahs == null
            ? Center(child: Text(l.loadingLabel))
            : TabBarView(
                children: [
                  _surahTab(context, surahs),
                  _StartsTab(
                    surahs: surahs,
                    // A riwaya edition: its own juz starts (KFGQPC).
                    starts: riwaya != null
                        ? [for (final v in riwaya.juzStarts()) riwaya.row(v)]
                        : ref
                              .watch(juzStartsProvider)
                              .value
                              ?.map((j) => j.ayah)
                              .toList(),
                    current: widget.juz,
                    title: (n) => l.juzLabel('$n'),
                  ),
                  // The riwayat's hizb divisions are not in their sources.
                  if (riwaya != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(l.riwayaGaps, textAlign: TextAlign.center),
                      ),
                    )
                  else
                    _StartsTab(
                      surahs: surahs,
                      starts: ref.watch(hizbStartsProvider).value,
                      current: widget.hizb,
                      title: (n) => l.hizbLabel('$n'),
                    ),
                  _PagesTab(current: widget.page),
                  _MarksTab(surahs: surahs),
                ],
              ),
      ),
    );
  }

  Widget _surahTab(BuildContext context, List<SurahRow> surahs) {
    final l = AppLocalizations.of(context);
    final verseRef = parseVerseRef(_query);
    final pageNumber = int.tryParse(
      _query.trim().replaceAllMapped(
        RegExp('[\u0660-\u0669]'),
        (m) => '${m[0]!.codeUnitAt(0) - 0x0660}',
      ),
    );
    final q = _fold(_query.trim());
    final shown = [
      for (final s in surahs)
        if (q.isEmpty ||
            _fold(s.nameAr).contains(q) ||
            _fold(s.nameEn).contains(q) ||
            '${s.id}' == q)
          s,
    ];
    final extras = <Widget>[
      if (verseRef != null && verseRef.surah >= 1 && verseRef.surah <= 114)
        ListTile(
          leading: const Icon(Icons.arrow_back),
          title: Text(
            '${l.surahWord(surahName(context, surahs[verseRef.surah - 1]))} ${verseRef.ayah}',
          ),
          onTap: () => _goToRef(verseRef, surahs),
        ),
      if (pageNumber != null &&
          pageNumber >= 1 &&
          pageNumber <= ref.watch(editionProvider).pageCount)
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(l.pageOf('$pageNumber')),
          onTap: () => openPage(context, ref, pageNumber),
        ),
    ];
    final current = q.isEmpty ? widget.surah : null;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l.indexSearchHint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
            onSubmitted: (_) {
              if (verseRef != null) _goToRef(verseRef, surahs);
            },
          ),
        ),
        ...extras,
        Expanded(
          child: _CurrentList(
            count: shown.length,
            currentIndex: current == null
                ? null
                : shown.indexWhere((s) => s.id == current),
            itemBuilder: (context, i, isCurrent) {
              final s = shown[i];
              return _Row(
                current: isCurrent,
                badge: '${s.id}',
                title: surahName(context, s),
                // The edition's own count and page (a riwaya differs).
                subtitle:
                    '${s.revelation == 'meccan' ? l.meccan : l.medinan} · ${l.ayahCount('${ref.watch(surahAyahCountProvider(s.id)).value ?? s.ayahCount}')}',
                trailing: l.pageShort(
                  '${ref.watch(surahStartPageProvider(s.id)).value ?? s.startPageIn(ref.watch(editionProvider))}',
                ),
                onTap: () => openVerse(context, ref, surah: s.id, ayah: 1),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A list with fixed row heights that opens scrolled to the current row.
class _CurrentList extends StatefulWidget {
  const _CurrentList({
    required this.count,
    required this.currentIndex,
    required this.itemBuilder,
  });

  final int count;
  final int? currentIndex;
  final Widget Function(BuildContext context, int index, bool current)
  itemBuilder;

  @override
  State<_CurrentList> createState() => _CurrentListState();
}

class _CurrentListState extends State<_CurrentList> {
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: widget.currentIndex == null || widget.currentIndex! < 0
        ? 0
        // Leave two rows above the current one visible.
        : ((widget.currentIndex! - 2) * _rowExtent).clamp(0, double.infinity),
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scroll,
      itemExtent: _rowExtent,
      itemCount: widget.count,
      itemBuilder: (context, i) =>
          widget.itemBuilder(context, i, i == widget.currentIndex),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.current,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final bool current;
  final String badge;
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    final weight = current ? FontWeight.w800 : FontWeight.w400;
    return Semantics(
      selected: current,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Material(
          color: current ? t.highlight : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: current
                ? BorderSide(color: t.control, width: 2)
                : BorderSide.none,
          ),
          child: ListTile(
            onTap: onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            leading: CircleAvatar(
              backgroundColor: current ? t.control : t.headBg,
              foregroundColor: current ? t.onControl : t.headFg,
              child: Text(badge, style: const TextStyle(fontSize: 13)),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: current ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(color: t.muted, fontWeight: weight),
            ),
            trailing: Text(
              trailing,
              style: TextStyle(color: t.muted, fontWeight: weight),
            ),
          ),
        ),
      ),
    );
  }
}

/// Juz or hizb starts.
class _StartsTab extends ConsumerWidget {
  const _StartsTab({
    required this.surahs,
    required this.starts,
    required this.current,
    required this.title,
  });

  final List<SurahRow> surahs;
  final List<AyahRow>? starts;
  final int? current;
  final String Function(int n) title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final list = starts;
    if (list == null) return Center(child: Text(l.loadingLabel));
    return _CurrentList(
      count: list.length,
      currentIndex: current == null ? null : current! - 1,
      itemBuilder: (context, i, isCurrent) {
        final a = list[i];
        // Rows of a riwaya edition carry its own numbers and page.
        final page = a.pageIn(ref.watch(editionProvider));
        return _Row(
          current: isCurrent,
          badge: '${i + 1}',
          title: title(i + 1),
          subtitle: l.juzStartsAt(
            surahName(context, surahs[a.surah - 1]),
            '${a.number}',
          ),
          trailing: l.pageShort('$page'),
          onTap: () => openPage(context, ref, page),
        );
      },
    );
  }
}

class _PagesTab extends ConsumerStatefulWidget {
  const _PagesTab({this.current});

  final int? current;

  @override
  ConsumerState<_PagesTab> createState() => _PagesTabState();
}

class _PagesTabState extends ConsumerState<_PagesTab> {
  ScrollController? _scroll;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    return LayoutBuilder(
      builder: (context, box) {
        const extent = 72.0;
        final perRow = ((box.maxWidth - 24 + 8) / (extent + 8)).ceil();
        final cell = (box.maxWidth - 24 - 8 * (perRow - 1)) / perRow;
        _scroll ??= ScrollController(
          initialScrollOffset: widget.current == null
              ? 0
              : (((widget.current! - 1) ~/ perRow - 2) * (cell + 8)).clamp(
                  0,
                  double.infinity,
                ),
        );
        return GridView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: extent,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: ref.watch(editionProvider).pageCount,
          itemBuilder: (context, i) {
            final current = i + 1 == widget.current;
            return Semantics(
              button: true,
              selected: current,
              label: l.pageOf('${i + 1}'),
              excludeSemantics: true,
              onTap: () => openPage(context, ref, i + 1),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: current ? t.control : null,
                  foregroundColor: current ? t.onControl : null,
                  side: current ? BorderSide(color: t.control, width: 2) : null,
                ),
                onPressed: () => openPage(context, ref, i + 1),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontWeight: current ? FontWeight.w800 : FontWeight.w400,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// The reader's marks: the four fixed marks and named fawasil, updated as
/// they are set from the page view.
class _MarksTab extends ConsumerWidget {
  const _MarksTab({required this.surahs});

  final List<SurahRow> surahs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final marks = ref.watch(bookmarkSetsProvider).value;
    if (marks == null) return Center(child: Text(l.loadingLabel));
    if (marks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l.noMarks,
            textAlign: TextAlign.center,
            style: TextStyle(color: t.muted, height: 1.7),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final m in marks)
          ListTile(
            leading: Icon(Icons.bookmark, color: Color(m.color), size: 30),
            title: Text(
              m.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l.fasilLastAt(
                surahName(context, surahs[m.surah - 1]),
                '${m.ayah}',
                // The page in the edition shown now, not the one it was
                // set in.
                '${ref.watch(versePageProvider((m.surah, m.ayah))).value ?? m.page}',
              ),
              style: TextStyle(color: t.muted),
            ),
            onTap: () => openVerse(context, ref, surah: m.surah, ayah: m.ayah),
          ),
      ],
    );
  }
}
