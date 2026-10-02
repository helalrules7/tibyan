import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../mushaf/data/mushaf_repository.dart';
import '../../mushaf/mushaf_providers.dart';
import '../../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import '../data/hifz_repository.dart';
import '../hifz_providers.dart';

/// The mutashabihat links' row in content.db `source`.
const _similarSourceKey = 'waqar144-mutashabihat';

/// The verses that resemble [surah]:[ayah] (mutashabihat), each shown as
/// its own text from the content database. Links only: no note or
/// commentary is ever shown.
Future<void> showSimilarSheet(
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
    builder: (context, scroll) =>
        SimilarVersesView(surah: surah, ayah: ayah, controller: scroll),
  ),
);

final _similarProvider = FutureProvider.autoDispose
    .family<List<SimilarGroup>, (int, int)>(
      (ref, v) => ref.watch(hifzRepositoryProvider).similar(v.$1, v.$2),
    );

class SimilarVersesView extends ConsumerWidget {
  const SimilarVersesView({
    super.key,
    required this.surah,
    required this.ayah,
    this.controller,
  });

  final int surah;
  final int ayah;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final groups = ref.watch(_similarProvider((surah, ayah)));
    final surahs = ref.watch(surahsProvider).value;
    final source = ref
        .watch(sourcesProvider)
        .value
        ?.where((s) => s.key == _similarSourceKey)
        .firstOrNull;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final arabic = Localizations.localeOf(context).languageCode == 'ar';

    String place(List<AyahRow> verses) {
      final first = verses.first;
      final last = verses.last;
      final s = surahs?[first.surah - 1];
      final name = s == null
          ? '${first.surah}'
          : (arabic ? s.nameAr : s.nameEn);
      if (first.id == last.id) return '$name ${digits(first.number)}';
      if (first.surah == last.surah) {
        return l.verseRange(name, digits(first.number), digits(last.number));
      }
      return '$name ${digits(first.number)} – ${digits(last.number)}';
    }

    Widget passage(SimilarPassage p, {bool own = false}) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: own ? t.highlight.withValues(alpha: 0.12) : t.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: own ? t.control : t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            own
                ? '${l.similarThisVerse} · ${place(p.verses)}'
                : place(p.verses),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: t.goldText,
            ),
          ),
          const SizedBox(height: 4),
          _VerseText(verses: p.verses),
          if (p.next != null) ...[
            const SizedBox(height: 4),
            Text(
              l.similarFollowing,
              style: TextStyle(fontSize: 12, color: t.muted),
            ),
            Opacity(opacity: 0.6, child: _VerseText(verses: [p.next!])),
          ],
        ],
      ),
    );

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(l.similarVerses, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...switch (groups) {
          AsyncData(:final value) => [
            for (final g in value) ...[
              passage(g.passage, own: true),
              for (final s in g.similar) passage(s),
              const SizedBox(height: 8),
            ],
          ],
          AsyncError() => [const SizedBox.shrink()],
          _ => [const Center(child: CircularProgressIndicator())],
        },
        if (source != null)
          Text(
            source.attribution,
            style: TextStyle(fontSize: 11, color: t.muted),
          ),
      ],
    );
  }
}

/// Verses in the KFGQPC Hafs font, each with its number glyph, verbatim.
class _VerseText extends StatelessWidget {
  const _VerseText({required this.verses});

  final List<AyahRow> verses;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Text.rich(
      TextSpan(
        children: [
          for (final a in verses) ...[
            TextSpan(text: '${a.displayBody} '),
            TextSpan(
              text: '${a.displayNumber} ',
              style: TextStyle(color: t.marker),
            ),
          ],
        ],
      ),
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: 'UthmanicHafs',
        fontSize: 21,
        height: 1.9,
        color: t.ink,
      ),
    );
  }
}
