import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/content_database.dart';
import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/mushaf_providers.dart';
import '../tafsir/tafsir_screen.dart' show commentaryEditionsProvider;

/// The chosen texts (translations, or al-Muyassar) of every verse of a
/// surah, keyed by (source id, verse): one query per surah.
final surahUnderVerseProvider =
    FutureProvider.family<Map<(int, int), CommentaryRow>, int>((ref, surah) {
      final ids = ref.watch(settingsProvider.select((s) => s.underVerse));
      return ref.watch(mushafRepositoryProvider).commentaryOfSurah(surah, ids);
    });

/// The texts chosen to show under a verse (Hafs numbers), each in its own
/// direction and font, smaller and quieter than the Quran text, justified
/// (docs/features/translation_under_ayah.md §4). Nothing when the reader
/// chose the Arabic only.
class UnderVerseTexts extends ConsumerWidget {
  const UnderVerseTexts({super.key, required this.surah, required this.ayah});

  final int surah;
  final int ayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    if (settings.underVerse.isEmpty) return const SizedBox.shrink();
    final t = context.tokens.colors;
    final editions = {
      for (final e
          in ref.watch(commentaryEditionsProvider).value ??
              const <CommentaryEditionRow>[])
        e.sourceId: e,
    };
    final rows = ref.watch(surahUnderVerseProvider(surah)).value;
    if (rows == null) return const SizedBox.shrink();
    final arabicUi = Localizations.localeOf(context).languageCode == 'ar';
    final showNames = settings.underVerse.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final id in settings.underVerse)
          if (rows[(id, ayah)] case final row?)
            Builder(
              builder: (context) {
                final e = editions[id];
                final rtl = e?.direction != 'ltr';
                final family = !rtl
                    ? 'IBMPlexSans'
                    : settings.tafsirFont == TafsirFont.naskh
                    ? 'UthmanTahaNaskh'
                    : settings.uiFont.family;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showNames && e != null)
                        Text(
                          arabicUi ? e.nameAr : e.nameEn,
                          style: TextStyle(fontSize: 11, color: t.muted),
                        ),
                      Text(
                        row.body,
                        textDirection: rtl
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontFamily: family,
                          fontSize:
                              (rtl ? 16.0 : 14.5) * settings.tafsirFontScale,
                          height: rtl ? 1.8 : 1.5,
                          color: t.muted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      ],
    );
  }
}

/// Chooses what shows under each verse: the Arabic only, one or two
/// translations, or al-Muyassar; and, on wide screens, whether it shows
/// beside the page.
Future<void> showUnderVerseChooser(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const SafeArea(child: _UnderVerseChooser()),
    );

class _UnderVerseChooser extends ConsumerWidget {
  const _UnderVerseChooser();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final settings = ref.watch(settingsProvider);
    final c = ref.read(settingsProvider.notifier);
    final editions =
        ref.watch(commentaryEditionsProvider).value ??
        const <CommentaryEditionRow>[];
    final arabicUi = Localizations.localeOf(context).languageCode == 'ar';
    final translations = [
      for (final e in editions)
        if (e.kind == 'translation') e,
    ];
    final tafsir = editions.where((e) => e.kind == 'tafsir').firstOrNull;
    final chosen = settings.underVerse;
    final mode = chosen.isEmpty
        ? 0
        : tafsir != null && chosen.contains(tafsir.sourceId)
        ? 2
        : 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l.underVerseTitle,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          RadioGroup<int>(
            groupValue: mode,
            onChanged: (m) => c.setUnderVerse(switch (m) {
              1 => [if (translations.isNotEmpty) translations.first.sourceId],
              2 => [if (tafsir != null) tafsir.sourceId],
              _ => const [],
            }),
            child: Column(
              children: [
                RadioListTile<int>(value: 0, title: Text(l.underArabicOnly)),
                RadioListTile<int>(value: 1, title: Text(l.underTranslation)),
                if (mode == 1)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.underTranslationHint,
                          style: TextStyle(color: t.muted, fontSize: 12),
                        ),
                        for (final e in translations)
                          CheckboxListTile(
                            value: chosen.contains(e.sourceId),
                            title: Text(arabicUi ? e.nameAr : e.nameEn),
                            // Two at most; at least one in this mode.
                            onChanged: (on) {
                              final next = [...chosen];
                              if (on == true) {
                                if (next.length >= 2) next.removeAt(0);
                                next.add(e.sourceId);
                              } else if (next.length > 1) {
                                next.remove(e.sourceId);
                              }
                              c.setUnderVerse(next);
                            },
                          ),
                      ],
                    ),
                  ),
                if (tafsir != null)
                  RadioListTile<int>(value: 2, title: Text(l.underMuyassar)),
              ],
            ),
          ),
          const Divider(),
          SwitchListTile(
            value: settings.splitTranslation,
            onChanged: c.setSplitTranslation,
            title: Text(l.splitTranslationLabel),
            subtitle: Text(
              l.splitTranslationHint,
              style: TextStyle(color: t.muted),
            ),
          ),
        ],
      ),
    );
  }
}
