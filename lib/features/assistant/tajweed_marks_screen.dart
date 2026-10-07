import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/data/tajweed.dart';
import '../mushaf/data/tajweed_index.dart';
import '../mushaf/mushaf_providers.dart';
import '../mushaf/presentation/mushaf_screen.dart' show surahName;
import '../mushaf/presentation/navigation.dart';
import '../mushaf/presentation/widgets/tajweed_legend.dart';
import '../share_image/share_text_runs.dart';

/// Where the tajweed marks (the rules with their colours) open.
const tajweedMarksLocation = '/assistant/tajweed';

/// Where the places of rule [rule] open.
String tajweedRuleLocation(TajweedRule rule) =>
    '$tajweedMarksLocation/rule?rule=${rule.key}';

/// A rule's colour as the pages draw it now (the reader's choice or the
/// default), on the current paper; null when the rule is left uncoloured.
Color? _drawnColor(BuildContext context, WidgetRef ref, TajweedRule rule) {
  final hues = ref.watch(settingsProvider.select((s) => s.tajweedHues));
  return tajweedHueOf(rule, hues)?.on(darkPaper: !context.tokens.mode.isLight);
}

/// «علامات التجويد», the Assistant's first helper: each rule of Tibyan's
/// tajweed data with its colour and reach, opening the list of its places.
class TajweedMarksScreen extends ConsumerWidget {
  const TajweedMarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final counts = ref.watch(tajweedRuleCountsProvider).value;
    // The riwaya editions have no tajweed data: the colours are listed,
    // the places (Hafs verses) are not offered.
    final hasData = editionHasTajweed(ref.watch(editionProvider));
    return Scaffold(
      appBar: AppBar(title: Text(l.tajweedMarksTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        l.tajweedMarksSubtitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.tajweedMarksHint,
                      style: TextStyle(color: t.muted, height: 1.6),
                    ),
                  ],
                ),
              ),
              if (!hasData)
                ListTile(
                  leading: Icon(Icons.info_outline, color: t.muted),
                  title: Text(
                    l.tajweedNoDataRiwaya,
                    style: TextStyle(color: t.muted, fontSize: 13),
                  ),
                ),
              for (final rule in tajweedLegendOrder)
                ListTile(
                  leading: TajweedSwatch(_drawnColor(context, ref, rule)),
                  title: Text(tajweedRuleName(l, rule)),
                  subtitle: switch (counts?[rule.key]) {
                    final c? => Text(
                      l.tajweedRuleCount('${c.verses}', '${c.letters}'),
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                    null => null,
                  },
                  trailing: hasData ? const Icon(Icons.chevron_right) : null,
                  onTap: hasData
                      ? () => context.push(tajweedRuleLocation(rule))
                      : null,
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  '${l.tajweedIndexColorNote}\n${l.tajweedSourceNote}',
                  style: TextStyle(color: t.muted, fontSize: 12, height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every verse a tajweed rule falls in, in mushaf order: the words it is
/// on, its letters in the rule's colour, and the verse's page in the
/// edition being read. Tapping a verse opens its page.
class TajweedRuleScreen extends ConsumerWidget {
  const TajweedRuleScreen({super.key, required this.rule});

  final TajweedRule rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final edition = ref.watch(editionProvider);
    final color = _drawnColor(context, ref, rule);
    final count = ref.watch(tajweedRuleCountsProvider).value?[rule.key];
    final surahs = ref.watch(surahsProvider).value;
    final places = editionHasTajweed(edition)
        ? ref.watch(tajweedPlacesProvider(rule.key))
        : const AsyncValue<List<TajweedPlace>>.data([]);

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TajweedSwatch(color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tajweedRuleName(l, rule),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          if (count != null) ...[
            const SizedBox(height: 8),
            Text(l.tajweedRuleCount('${count.verses}', '${count.letters}')),
          ],
          const SizedBox(height: 8),
          if (!editionHasTajweed(edition))
            Text(l.tajweedNoDataRiwaya, style: TextStyle(color: t.muted)),
          if (places.value?.any((p) => p.letters.any((x) => x.marksOnly)) ??
              false)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l.tajweedMarksInkNote,
                style: TextStyle(color: t.muted, fontSize: 12, height: 1.6),
              ),
            ),
          Text(
            '${l.tajweedIndexColorNote}\n${l.tajweedSourceNote}',
            style: TextStyle(color: t.muted, fontSize: 12, height: 1.6),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(tajweedRuleName(l, rule))),
      body: switch (places) {
        AsyncData(:final value) => ListView.builder(
          itemCount: value.length + 1,
          itemBuilder: (context, i) => i == 0
              ? header
              : _PlaceTile(
                  place: value[i - 1],
                  color: color ?? t.ink,
                  surahName: surahs == null
                      ? '${value[i - 1].surah}'
                      : surahName(context, surahs[value[i - 1].surah - 1]),
                  page: value[i - 1].pageIn(edition),
                ),
        ),
        AsyncError() => ListView(
          children: [
            header,
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.tajweedIndexLoadError),
            ),
          ],
        ),
        _ => ListView(
          children: [
            header,
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      },
    );
  }
}

/// One verse of a rule's index: the pieces of the verse that hold its
/// letters, exactly as stored, with the letters coloured.
class _PlaceTile extends ConsumerWidget {
  const _PlaceTile({
    required this.place,
    required this.color,
    required this.surahName,
    required this.page,
  });

  final TajweedPlace place;
  final Color color;
  final String surahName;
  final int page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final letters = [
      for (final x in place.letters)
        ShareTajweedLetter(
          word: x.word,
          letter: x.letter,
          marksOnly: x.marksOnly,
          color: color,
        ),
    ];
    return ListTile(
      title: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          textDirection: TextDirection.rtl,
          spacing: 14,
          runSpacing: 2,
          children: [
            for (final token in tajweedTokens(place))
              Text.rich(
                TextSpan(
                  children: [
                    for (final (text, c) in tokenRuns(
                      token.text,
                      firstWord: token.firstWord,
                      endsVerse: token.endsVerse,
                      letters: letters,
                      number: t.marker,
                    ))
                      TextSpan(
                        text: text,
                        style: c == null ? null : TextStyle(color: c),
                      ),
                  ],
                ),
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'UthmanicHafs',
                  fontSize: 24,
                  height: 1.8,
                  color: t.ink,
                ),
              ),
          ],
        ),
      ),
      subtitle: Text(
        l.tajweedPlaceAt(surahName, '${place.ayah}', '$page'),
        style: TextStyle(color: t.muted),
      ),
      onTap: () =>
          openVerse(context, ref, surah: place.surah, ayah: place.ayah),
    );
  }
}
