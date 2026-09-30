import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/content_database.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/data/mushaf_repository.dart';
import '../mushaf/mushaf_providers.dart';
import '../mushaf/presentation/mushaf_screen.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart';
import 'search_engine.dart';

/// Every verse's searchable text, loaded once.
final searchVersesProvider = FutureProvider<List<SearchVerse>>((ref) async {
  final rows = await ref.watch(mushafRepositoryProvider).searchRows();
  return [
    for (final r in rows)
      SearchVerse(
        r.surah,
        r.number,
        r.textSearch.substring(r.searchBasmalaPrefix),
      ),
  ];
});

/// Every verse, for showing results in the mushaf's own text.
final allAyahsProvider = FutureProvider<Map<(int, int), AyahRow>>((ref) async {
  final rows = await ref.watch(mushafRepositoryProvider).searchRows();
  return {for (final r in rows) (r.surah, r.number): r};
});

const _historyKey = 'search.history';
const _historyMax = 20;

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _field = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _field.dispose();
    super.dispose();
  }

  List<String> get _history =>
      ref.read(sharedPreferencesProvider).getStringList(_historyKey) ?? [];

  Future<void> _remember(String q) async {
    final t = q.trim();
    if (t.length < 2) return;
    final h = [t, ..._history.where((x) => x != t)].take(_historyMax).toList();
    await ref.read(sharedPreferencesProvider).setStringList(_historyKey, h);
  }

  void _changed(String q) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => setState(() => _query = q),
    );
  }

  Future<void> _open(int surah, int ayah) async {
    await _remember(_field.text);
    final row = await ref.read(mushafRepositoryProvider).ayah(surah, ayah);
    if (!mounted) return;
    final page = row.pageIn(ref.read(editionProvider));
    context.go('/mushaf?page=$page&s=$surah&a=$ayah');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final surahs = ref.watch(surahsProvider).value;
    final verses = ref.watch(searchVersesProvider).value;
    final names = {
      for (final s in surahs ?? const <SurahRow>[]) s.id: [s.nameAr, s.nameEn],
    };
    final ref0 = _query.isEmpty ? null : parseReference(_query, names);
    final hits = verses == null || _query.isEmpty
        ? const <SearchHit>[]
        : search(verses, _query);
    final total = hits.fold<int>(0, (n, h) => n + h.count);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _field,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l.searchHint,
            border: InputBorder.none,
          ),
          onChanged: _changed,
          onSubmitted: (q) {
            setState(() => _query = q);
            _remember(q);
          },
        ),
        actions: [
          if (_field.text.isNotEmpty)
            IconButton(
              tooltip: l.cancel,
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _field.clear();
                _query = '';
              }),
            ),
        ],
      ),
      body: _query.isEmpty
          ? _History(
              items: _history,
              onPick: (q) {
                _field.text = q;
                setState(() => _query = q);
              },
              onClear: () async {
                await ref.read(sharedPreferencesProvider).remove(_historyKey);
                setState(() {});
              },
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (ref0 != null && surahs != null)
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.bookmark_outline, color: t.goldText),
                      title: Text(
                        ref0.ayah == null
                            ? l.surahWord(
                                surahName(context, surahs[ref0.surah - 1]),
                              )
                            : '${l.surahWord(surahName(context, surahs[ref0.surah - 1]))} · ${digits(ref0.ayah!)}',
                      ),
                      subtitle: Text(l.searchGoTo),
                      onTap: () {
                        final max = surahs[ref0.surah - 1].ayahCount;
                        _open(ref0.surah, (ref0.ayah ?? 1).clamp(1, max));
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    hits.isEmpty
                        ? (ref0 == null ? l.searchNothing : '')
                        : l.searchCount(digits(total), digits(hits.length)),
                    style: TextStyle(color: t.muted),
                  ),
                ),
                for (final h in hits.take(300))
                  _Result(
                    hit: h,
                    surahs: surahs,
                    onTap: () => _open(h.surah, h.ayah),
                  ),
                if (hits.length > 300)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      l.searchMore(digits(hits.length - 300)),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: t.muted),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Result extends ConsumerWidget {
  const _Result({required this.hit, required this.surahs, required this.onTap});

  final SearchHit hit;
  final List<SurahRow>? surahs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final row = ref.watch(allAyahsProvider).value?[(hit.surah, hit.ayah)];
    final name = surahs == null
        ? ''
        : surahName(context, surahs![hit.surah - 1]);
    // The mushaf's own words; the matched ones are marked when the two
    // texts split into the same number of words.
    final words = row == null
        ? const <String>[]
        : row.displayBody.split(' ').where((w) => w != '۞').toList();
    final search = row?.textSearch
        .substring(row.searchBasmalaPrefix)
        .split(' ')
        .length;
    final mark = search == words.length;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${l.surahWord(name)} · ${digits(hit.ayah)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: t.goldText,
                ),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    for (final (i, w) in words.indexed) ...[
                      TextSpan(
                        text: w,
                        style: mark && hit.words.contains(i)
                            ? TextStyle(
                                backgroundColor: t.highlight,
                                color: t.ink,
                              )
                            : null,
                      ),
                      const TextSpan(text: ' '),
                    ],
                    if (row != null)
                      TextSpan(
                        text: row.displayNumber,
                        style: TextStyle(color: t.marker),
                      ),
                  ],
                ),
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'UthmanicHafs',
                  fontSize: 20,
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

class _History extends StatelessWidget {
  const _History({
    required this.items,
    required this.onPick,
    required this.onClear,
  });

  final List<String> items;
  final ValueChanged<String> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l.searchIntro,
            textAlign: TextAlign.center,
            style: TextStyle(color: t.muted, height: 1.7),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        ListTile(
          title: Text(l.searchHistory, style: TextStyle(color: t.muted)),
          trailing: TextButton(
            onPressed: onClear,
            child: Text(l.searchClearHistory),
          ),
        ),
        for (final q in items)
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(q),
            onTap: () => onPick(q),
          ),
      ],
    );
  }
}
