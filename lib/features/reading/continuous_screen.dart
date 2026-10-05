import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/content_database.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/data/mushaf_repository.dart';
import '../mushaf/mushaf_providers.dart';
import '../mushaf/presentation/mushaf_screen.dart' show surahName;
import '../mushaf/presentation/navigation.dart';
import 'under_verse.dart';

/// The continuous view: a surah verse after verse in the KFGQPC text, with
/// the reader's choice under each verse (a translation or two, al-Muyassar,
/// or nothing). It opens at [ayah]. The text is the Hafs text whatever
/// edition is being read (docs/features/translation_under_ayah.md).
class ContinuousScreen extends ConsumerWidget {
  const ContinuousScreen({super.key, required this.surah, this.ayah = 1});

  final int surah;
  final int ayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final surahs = ref.watch(surahsProvider).value;
    final row = surahs == null || surah < 1 || surah > surahs.length
        ? null
        : surahs[surah - 1];
    final ayahs = ref.watch(surahAyahsProvider(surah)).value;
    final riwaya = ref.watch(editionProvider).isRiwaya;

    return Scaffold(
      backgroundColor: t.paper,
      appBar: AppBar(
        title: Text(row == null ? '' : l.surahWord(surahName(context, row))),
        actions: [
          IconButton(
            tooltip: l.underVerseTitle,
            icon: const Icon(Icons.translate),
            onPressed: () => showUnderVerseChooser(context),
          ),
          IconButton(
            tooltip: l.sectionMushaf,
            icon: const Icon(Icons.auto_stories_outlined),
            onPressed: () => openVerse(context, ref, surah: surah, ayah: ayah),
          ),
        ],
      ),
      body: ayahs == null
          ? Center(
              child: CircularProgressIndicator(semanticsLabel: l.loadingLabel),
            )
          : _VerseList(
              key: ValueKey('$surah:$ayah'),
              surah: surah,
              ayah: ayah,
              ayahs: ayahs,
              riwaya: riwaya,
              surahCount: surahs?.length ?? 114,
            ),
    );
  }
}

class _VerseList extends ConsumerWidget {
  const _VerseList({
    super.key,
    required this.surah,
    required this.ayah,
    required this.ayahs,
    required this.riwaya,
    required this.surahCount,
  });

  final int surah;
  final int ayah;
  final List<AyahRow> ayahs;
  final bool riwaya;
  final int surahCount;

  static const _center = ValueKey('center');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final basmala = ref.watch(basmalaProvider).value;

    // The list from its top: the header, the verses, the way on.
    final items = <Widget>[
      _Header(
        basmala: surah != 1 && surah != 9 ? basmala : null,
        note: riwaya ? l.hafsTextNote : null,
      ),
      for (final a in ayahs) _VerseTile(verse: a),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Row(
          children: [
            if (surah > 1)
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      context.pushReplacement('/read?s=${surah - 1}'),
                  child: Text(l.previousSurah),
                ),
              ),
            if (surah > 1 && surah < surahCount) const SizedBox(width: 12),
            if (surah < surahCount)
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      context.pushReplacement('/read?s=${surah + 1}'),
                  child: Text(l.nextSurah),
                ),
              ),
          ],
        ),
      ),
    ];
    // Opens at the verse: what is above it grows upward from the centre.
    final at = ayahs.indexWhere((a) => a.number == ayah);
    final center = at <= 0 ? 0 : at + 1;
    final above = items.sublist(0, center).reversed.toList();
    final below = items.sublist(center);

    return SelectionArea(
      child: CustomScrollView(
        center: _center,
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => above[i],
              childCount: above.length,
            ),
          ),
          SliverList(
            key: _center,
            delegate: SliverChildBuilderDelegate(
              (context, i) => below[i],
              childCount: below.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.basmala, this.note});

  final String? basmala;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        children: [
          if (note != null)
            Text(note!, style: TextStyle(color: t.muted, fontSize: 12)),
          if (basmala != null)
            Text(
              basmala!,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'UthmanicHafs',
                fontSize: 24,
                height: 2,
                color: t.ink,
              ),
            ),
        ],
      ),
    );
  }
}

class _VerseTile extends StatelessWidget {
  const _VerseTile({required this.verse});

  final AyahRow verse;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return InkWell(
      // A tap opens the verse's tafsir and translations.
      onTap: () =>
          context.push('/mushaf/tafsir?s=${verse.surah}&a=${verse.number}'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.border, width: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${verse.displayBody} '),
                  TextSpan(
                    text: verse.displayNumber,
                    style: TextStyle(color: t.marker),
                  ),
                ],
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontFamily: 'UthmanicHafs',
                fontSize: 24,
                height: 2,
                color: t.ink,
              ),
            ),
            UnderVerseTexts(surah: verse.surah, ayah: verse.number),
          ],
        ),
      ),
    );
  }
}
