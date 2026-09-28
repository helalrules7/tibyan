import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
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

class IndexScreen extends ConsumerStatefulWidget {
  const IndexScreen({super.key});

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
    final ayah = r.ayah.clamp(1, surahs[r.surah - 1].ayahCount);
    final row = await ref.read(mushafRepositoryProvider).ayah(r.surah, ayah);
    if (!mounted) return;
    openVerse(context, ref, surah: r.surah, ayah: ayah, page: row.page);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final surahs = ref.watch(surahsProvider).value;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.indexTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l.tabSurahs),
              Tab(text: l.tabJuz),
              Tab(text: l.tabPages),
            ],
          ),
        ),
        body: surahs == null
            ? Center(child: Text(l.loadingLabel))
            : TabBarView(
                children: [
                  _surahTab(context, surahs),
                  _JuzTab(surahs: surahs),
                  const _PagesTab(),
                ],
              ),
      ),
    );
  }

  Widget _surahTab(BuildContext context, List<SurahRow> surahs) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final verseRef = parseVerseRef(_query);
    final q = _fold(_query.trim());
    final shown = [
      for (final s in surahs)
        if (q.isEmpty ||
            _fold(s.nameAr).contains(q) ||
            _fold(s.nameEn).contains(q) ||
            '${s.id}' == q)
          s,
    ];
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
        Expanded(
          child: ListView(
            children: [
              if (verseRef != null &&
                  verseRef.surah >= 1 &&
                  verseRef.surah <= 114)
                ListTile(
                  leading: const Icon(Icons.arrow_back),
                  title: Text(
                    '${l.surahWord(surahName(context, surahs[verseRef.surah - 1]))} ${verseRef.ayah}',
                  ),
                  onTap: () => _goToRef(verseRef, surahs),
                ),
              for (final s in shown)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: t.headBg,
                    foregroundColor: t.headFg,
                    child: Text(
                      '${s.id}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  title: Text(surahName(context, s)),
                  subtitle: Text(
                    '${s.revelation == 'meccan' ? l.meccan : l.medinan} · ${l.ayahCount('${s.ayahCount}')}',
                    style: TextStyle(color: t.muted),
                  ),
                  trailing: Text(
                    l.pageShort('${s.startPage}'),
                    style: TextStyle(color: t.muted),
                  ),
                  onTap: () => openVerse(
                    context,
                    ref,
                    surah: s.id,
                    ayah: 1,
                    page: s.startPage,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JuzTab extends ConsumerWidget {
  const _JuzTab({required this.surahs});

  final List<SurahRow> surahs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final starts = ref.watch(juzStartsProvider).value;
    if (starts == null) return Center(child: Text(l.loadingLabel));
    return ListView(
      children: [
        for (final j in starts)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: t.headBg,
              foregroundColor: t.headFg,
              child: Text('${j.juz}', style: const TextStyle(fontSize: 13)),
            ),
            title: Text(l.juzLabel('${j.juz}')),
            subtitle: Text(
              l.juzStartsAt(
                surahName(context, surahs[j.ayah.surah - 1]),
                '${j.ayah.number}',
              ),
              style: TextStyle(color: t.muted),
            ),
            trailing: Text(
              l.pageShort('${j.ayah.page}'),
              style: TextStyle(color: t.muted),
            ),
            onTap: () => openVerse(
              context,
              ref,
              surah: j.ayah.surah,
              ayah: j.ayah.number,
              page: j.ayah.page,
            ),
          ),
      ],
    );
  }
}

class _PagesTab extends ConsumerWidget {
  const _PagesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 72,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: mushafPageCount,
      itemBuilder: (context, i) => Semantics(
        button: true,
        label: l.pageOf('${i + 1}'),
        excludeSemantics: true,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () async {
            final first = (await ref.read(pageAyahsProvider(i + 1).future))
                .first;
            if (!context.mounted) return;
            openVerse(
              context,
              ref,
              surah: first.surah,
              ayah: first.number,
              page: i + 1,
            );
          },
          child: Text('${i + 1}'),
        ),
      ),
    );
  }
}
