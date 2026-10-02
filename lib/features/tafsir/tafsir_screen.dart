import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/content_database.dart';
import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/data/mushaf_repository.dart';
import '../mushaf/mushaf_providers.dart';
import '../mushaf/presentation/mushaf_screen.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart';
import '../mushaf/presentation/widgets/mushaf_page.dart';
import 'kashida_text.dart';

final commentaryEditionsProvider = FutureProvider<List<CommentaryEditionRow>>(
  (ref) => ref.watch(mushafRepositoryProvider).commentaryEditions(),
);

final verseCommentaryProvider =
    FutureProvider.family<Map<int, CommentaryRow>, VerseKey>(
      (ref, v) =>
          ref.watch(mushafRepositoryProvider).commentary(v.surah, v.ayah),
    );

/// Tafsir and translations of one verse; swipe or use the arrows to move
/// through the surah. Every text is shown exactly as its source has it,
/// with the source's credit under it.
class TafsirScreen extends ConsumerStatefulWidget {
  const TafsirScreen({super.key, required this.surah, required this.ayah});

  final int surah;
  final int ayah;

  @override
  ConsumerState<TafsirScreen> createState() => _TafsirScreenState();
}

class _TafsirScreenState extends ConsumerState<TafsirScreen> {
  late final PageController _pages = PageController(
    initialPage: widget.ayah - 1,
  );
  late int _ayah = widget.ayah;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int delta, int count) {
    final next = _ayah - 1 + delta;
    if (next < 0 || next >= count) return;
    _pages.animateToPage(
      next,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final surah = ref.watch(surahsProvider).value?[widget.surah - 1];
    final ayahs = ref.watch(surahAyahsProvider(widget.surah)).value;
    final count = surah?.ayahCount ?? 0;

    return Scaffold(
      backgroundColor: t.paper,
      appBar: AppBar(
        title: Text(
          surah == null
              ? l.tafsirTitle
              : '${l.surahWord(surahName(context, surah))} · ${digits(_ayah)}',
        ),
        actions: [
          IconButton(
            tooltip: l.tafsirSettings,
            icon: const Icon(Icons.text_fields),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (_) => const _TafsirSettingsSheet(),
            ),
          ),
        ],
      ),
      body: ayahs == null
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pages,
              itemCount: ayahs.length,
              onPageChanged: (i) => setState(() => _ayah = i + 1),
              itemBuilder: (context, i) => _VersePage(ayah: ayahs[i]),
            ),
      bottomNavigationBar: SafeArea(
        child: Row(
          children: [
            IconButton(
              tooltip: l.previousVerse,
              onPressed: _ayah > 1 ? () => _go(-1, count) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            const Spacer(),
            Semantics(
              liveRegion: true,
              label: l.verseCounter(digits(_ayah), digits(count)),
              excludeSemantics: true,
              child: Text(
                '${digits(_ayah)} / ${digits(count)}',
                style: TextStyle(color: t.muted),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: l.nextVerse,
              onPressed: _ayah < count ? () => _go(1, count) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersePage extends ConsumerWidget {
  const _VersePage({required this.ayah});

  final AyahRow ayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final settings = ref.watch(settingsProvider);
    final editions = ref.watch(commentaryEditionsProvider).value;
    final entries = ref
        .watch(verseCommentaryProvider((surah: ayah.surah, ayah: ayah.number)))
        .value;
    final sources = {
      for (final s in ref.watch(sourcesProvider).value ?? <SourceRow>[])
        s.id: s,
    };
    if (editions == null || entries == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final shown = [
      for (final e in editions)
        if (!settings.hiddenCommentaries.contains(e.sourceId) &&
            entries[e.sourceId] != null)
          e,
    ];
    final cards = [
      for (final e in shown)
        _CommentaryCard(
          edition: e,
          entry: entries[e.sourceId]!,
          source: sources[e.sourceId],
        ),
    ];

    return SelectionArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Wide screens show the texts side by side for comparison.
          final wide = constraints.maxWidth >= 720 && cards.length > 1;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: t.border),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${ayah.displayBody} '),
                      TextSpan(
                        text: ayah.displayNumber,
                        style: TextStyle(color: t.marker),
                      ),
                    ],
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: 24,
                    height: 2,
                    color: t.ink,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (cards.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l.tafsirNoneShown,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: t.muted),
                  ),
                )
              else if (wide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, c) in cards.indexed) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(child: c),
                      ],
                    ],
                  ),
                )
              else
                for (final (i, c) in cards.indexed) ...[
                  if (i > 0) const SizedBox(height: 12),
                  c,
                ],
            ],
          );
        },
      ),
    );
  }
}

class _CommentaryCard extends ConsumerWidget {
  const _CommentaryCard({
    required this.edition,
    required this.entry,
    required this.source,
  });

  final CommentaryEditionRow edition;
  final CommentaryRow entry;
  final SourceRow? source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final settings = ref.watch(settingsProvider);
    final arabicUi = Localizations.localeOf(context).languageCode == 'ar';
    final rtl = edition.direction == 'rtl';
    final family = !rtl
        ? 'IBMPlexSans'
        : settings.tafsirFont == TafsirFont.naskh
        ? 'UthmanTahaNaskh'
        : settings.uiFont.family;
    final size = (rtl ? 19.0 : 16.0) * settings.tafsirFontScale;
    final dir = rtl ? TextDirection.rtl : TextDirection.ltr;
    final bodyStyle = TextStyle(
      fontFamily: family,
      fontSize: size,
      height: rtl ? 1.9 : 1.6,
      color: t.ink,
    );
    final s = source;
    final credit = s == null
        ? null
        : [
            s.attribution,
            // The version is shown once, even when the credit names it.
            if (s.version == null)
              l.sourceRetrieved(s.retrievedAt)
            else if (!s.attribution.contains(s.version!))
              l.sourceVersion(s.version!),
          ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                child: Text(
                  arabicUi ? edition.nameAr : edition.nameEn,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: t.ink,
                  ),
                ),
              ),
              IconButton(
                tooltip: l.copyText,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.copy, size: 18, color: t.muted),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: entry.body));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l.copied)));
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (rtl && settings.tafsirKashida)
            // Selection would copy the added tatweels; the copy button
            // gives the original text instead.
            SelectionContainer.disabled(
              child: KashidaText(entry.body, style: bodyStyle),
            )
          else
            Text(
              entry.body,
              textDirection: dir,
              textAlign: TextAlign.justify,
              style: bodyStyle,
            ),
          if (entry.footnotes != null) ...[
            const SizedBox(height: 10),
            Text(
              l.tafsirFootnotes,
              style: TextStyle(fontSize: 12, color: t.muted),
            ),
            const SizedBox(height: 4),
            Text(
              entry.footnotes!,
              textDirection: dir,
              style: TextStyle(
                fontFamily: family,
                fontSize: size * 0.8,
                height: 1.5,
                color: t.muted,
              ),
            ),
          ],
          if (credit != null) ...[
            const SizedBox(height: 10),
            Text(
              credit,
              textDirection: dir,
              style: TextStyle(fontSize: 11, color: t.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _TafsirSettingsSheet extends ConsumerWidget {
  const _TafsirSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final editions = ref.watch(commentaryEditionsProvider).value ?? const [];
    final arabicUi = Localizations.localeOf(context).languageCode == 'ar';

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Semantics(
            header: true,
            child: Text(
              l.tafsirFontLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<TafsirFont>(
            segments: [
              ButtonSegment(
                value: TafsirFont.naskh,
                label: Text(l.tafsirFontNaskh),
              ),
              ButtonSegment(
                value: TafsirFont.interface,
                label: Text(l.tafsirFontInterface),
              ),
            ],
            selected: {settings.tafsirFont},
            onSelectionChanged: (v) => controller.setTafsirFont(v.first),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              l.tafsirTextSize,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Slider(
            value: settings.tafsirFontScale,
            semanticFormatterCallback: (v) => '${(v * 100).round()}%',
            min: 0.8,
            max: 1.8,
            divisions: 10,
            onChanged: controller.setTafsirFontScale,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.tafsirKashida),
            subtitle: Text(l.tafsirKashidaHint),
            value: settings.tafsirKashida,
            onChanged: controller.setTafsirKashida,
          ),
          Text(l.tafsirShown, style: Theme.of(context).textTheme.titleSmall),
          for (final e in editions)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(arabicUi ? e.nameAr : e.nameEn),
              value: !settings.hiddenCommentaries.contains(e.sourceId),
              onChanged: (v) => controller.setCommentaryShown(e.sourceId, v),
            ),
        ],
      ),
    );
  }
}
