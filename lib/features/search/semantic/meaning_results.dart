import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../mushaf/data/mushaf_repository.dart';
import '../../mushaf/data/page_pack.dart';
import '../../mushaf/mushaf_providers.dart';
import '../../mushaf/presentation/mushaf_screen.dart';
import '../../mushaf/presentation/widgets/illuminated_frame.dart';
import '../../tafsir/tafsir_screen.dart';
import '../search_screen.dart' show allAyahsProvider;
import 'meaning_providers.dart';
import 'meaning_search.dart';

/// «بالمعنى»: verses found through the meaning texts, each with its own
/// text and, under it, the text that matched, exactly as stored, with the
/// name of its source. Offers the pack while only keywords are available.
class MeaningResults extends ConsumerWidget {
  const MeaningResults({super.key, required this.query, required this.onOpen});

  final String query;
  final void Function(int surah, int ayah) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final installed = ref.watch(semanticInstalledProvider);
    final searcher = ref.watch(meaningSearcherProvider);
    final q = query.trim();
    final results = q.length < 2 ? null : ref.watch(meaningResultsProvider(q));
    final broken =
        installed && searcher.hasValue && !searcher.requireValue.semantic;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (!installed) const _PackCard(),
        if (broken) _Note(text: l.semanticPackError, icon: Icons.error_outline),
        if (installed && searcher.isLoading)
          _Note(text: l.semanticPackLoading, icon: Icons.hourglass_top),
        if (results == null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l.searchMeaningIntro,
              style: TextStyle(color: t.muted, height: 1.7),
            ),
          )
        else
          ...results.when(
            loading: () => [
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [_Note(text: '$e', icon: Icons.error_outline)],
            data: (hits) => [
              Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    hits.isEmpty
                        ? l.searchNothing
                        : '${l.searchMeaningCount(digits(hits.length))}'
                              '${searcher.value?.semantic ?? false ? ' · ${l.semanticResultsNote}' : ''}',
                    style: TextStyle(color: t.muted),
                  ),
                ),
              ),
              for (final h in hits)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MeaningResultCard(
                    hit: h,
                    onTap: () => onOpen(h.surah, h.ayah),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// One verse found by meaning.
class MeaningResultCard extends ConsumerWidget {
  const MeaningResultCard({super.key, required this.hit, required this.onTap});

  final MeaningHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final arabicUi = Localizations.localeOf(context).languageCode == 'ar';
    final surahs = ref.watch(surahsProvider).value;
    final row = ref.watch(allAyahsProvider).value?[(hit.surah, hit.ayah)];
    final entry = ref
        .watch(verseCommentaryProvider((surah: hit.surah, ayah: hit.ayah)))
        .value?[hit.sourceId];
    final edition = ref
        .watch(commentaryEditionsProvider)
        .value
        ?.where((e) => e.sourceId == hit.sourceId)
        .firstOrNull;
    final name = surahs == null
        ? ''
        : surahName(context, surahs[hit.surah - 1]);
    final rtl = edition?.direction != 'ltr';
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                label: l.verseLabel(name, digits(hit.ayah)),
                excludeSemantics: true,
                child: Text(
                  '${l.surahWord(name)} · ${digits(hit.ayah)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: t.goldText,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (row != null)
                Text(
                  '${row.displayBody} ${row.displayNumber}',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: 20,
                    height: 1.9,
                    color: t.ink,
                  ),
                ),
              if (edition != null && entry != null) ...[
                const Divider(height: 16),
                Text(
                  l.searchMatchedIn(arabicUi ? edition.nameAr : edition.nameEn),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.muted,
                  ),
                ),
                const SizedBox(height: 2),
                // The matched text as stored, never shortened or changed.
                Text(
                  entry.body,
                  textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: rtl ? 'UthmanTahaNaskh' : 'IBMPlexSans',
                    fontSize: rtl ? 16 : 14,
                    height: rtl ? 1.8 : 1.5,
                    color: t.ink,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Offers the pack, then follows its download.
class _PackCard extends ConsumerWidget {
  const _PackCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final progress = ref.watch(semanticDownloadProvider);
    final size = digits((PagePackSpec.semantic.bytes / 1e6).round());
    final busy =
        progress.phase == PackPhase.downloading ||
        progress.phase == PackPhase.verifying ||
        progress.phase == PackPhase.installing;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.semanticPackOffer(size), style: TextStyle(color: t.ink)),
            const SizedBox(height: 10),
            if (busy) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  progress.phase == PackPhase.downloading
                      ? l.semanticPackDownloading(
                          digits((progress.fraction * 100).round()),
                        )
                      : l.semanticPackVerifying,
                  style: TextStyle(color: t.muted),
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: progress.phase == PackPhase.downloading
                    ? progress.fraction
                    : null,
                semanticsLabel: l.semanticPackName,
              ),
            ] else ...[
              if (progress.phase == PackPhase.failed)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l.semanticPackFailed,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.icon(
                  onPressed: () =>
                      ref.read(semanticDownloadProvider.notifier).start(),
                  icon: const Icon(Icons.download),
                  label: Text(l.semanticPackDownload),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ExcludeSemantics(child: Icon(icon, color: t.muted)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: TextStyle(color: t.muted)),
            ),
          ],
        ),
      ),
    );
  }
}
