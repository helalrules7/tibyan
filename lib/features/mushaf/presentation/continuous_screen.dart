import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/db/content_database.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/mushaf_repository.dart';
import '../mushaf_providers.dart';
import 'mushaf_screen.dart';
import 'widgets/fasil_sheet.dart';
import 'widgets/mushaf_page.dart';

/// Arabic-Indic digits for verse numbers.
String arabicDigits(int n) => n
    .toString()
    .split('')
    .map((d) => String.fromCharCode(0x0660 + int.parse(d)))
    .join();

/// Continuous reading of one surah in the Amiri Quran font. The verse text
/// is Tanzil's, verbatim; only the verse-end sign and number are added.
class ContinuousScreen extends ConsumerStatefulWidget {
  const ContinuousScreen({super.key, required this.surah, this.ayah});

  final int surah;
  final int? ayah;

  @override
  ConsumerState<ContinuousScreen> createState() => _ContinuousScreenState();
}

class _ContinuousScreenState extends ConsumerState<ContinuousScreen> {
  final _pageKeys = <int, GlobalKey>{};
  final _recognizers = <TapGestureRecognizer>[];
  VerseKey? _selected;
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    if (widget.ayah != null) {
      _selected = (surah: widget.surah, ayah: widget.ayah!);
    }
    if (ref.read(settingsProvider).keepScreenOn) WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  void _save(AyahRow a) => ref
      .read(userDatabaseProvider)
      .savePosition(
        edition: ref.read(settingsProvider).edition.name,
        view: 'continuous',
        surah: a.surah,
        ayah: a.number,
        page: a.page,
      );

  void _scrollToTarget(List<AyahRow> ayahs) {
    if (_scrolled) return;
    _scrolled = true;
    final target = widget.ayah == null
        ? ayahs.first
        : ayahs.firstWhere(
            (a) => a.number == widget.ayah,
            orElse: () => ayahs.first,
          );
    _save(target);
    if (widget.ayah == null || widget.ayah == 1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _pageKeys[target.page]?.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final settings = ref.watch(settingsProvider);
    final surahs = ref.watch(surahsProvider).value;
    final ayahs = ref.watch(surahAyahsProvider(widget.surah)).value;
    final surah = surahs?[widget.surah - 1];

    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    if (ayahs != null) _scrollToTarget(ayahs);

    final quranStyle = TextStyle(
      fontFamily: 'AmiriQuran',
      fontSize: 24 * settings.quranFontScale,
      height: 2.1,
      color: t.ink,
    );

    // One paragraph per mushaf page, so a verse can be scrolled to.
    final byPage = <int, List<AyahRow>>{};
    for (final a in ayahs ?? const <AyahRow>[]) {
      byPage.putIfAbsent(a.page, () => []).add(a);
    }

    return Scaffold(
      backgroundColor: t.paper,
      appBar: AppBar(
        title: Text(
          surah == null ? '' : l.surahWord(surahName(context, surah)),
        ),
        actions: [
          if (ref.watch(pagesInstalledProvider))
            IconButton(
              tooltip: l.viewPage,
              icon: const Icon(Icons.auto_stories_outlined),
              onPressed: () {
                final a = _selected == null
                    ? ayahs?.first
                    : ayahs?.firstWhere((x) => x.number == _selected!.ayah);
                context.go('/mushaf?page=${a?.page ?? 1}');
              },
            ),
          IconButton(
            tooltip: l.indexTitle,
            icon: const Icon(Icons.list_alt),
            onPressed: () => context.push('/mushaf/index'),
          ),
          IconButton(
            tooltip: l.fawasilTitle,
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () => context.push('/mushaf/fawasil'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ayahs == null || surah == null
                  ? Center(child: Text(l.loadingLabel))
                  : Directionality(
                      textDirection: TextDirection.rtl,
                      // Not lazy: every page paragraph needs a context so a
                      // verse can be scrolled into view.
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SurahHeader(surah: surah),
                            if (ayahs.first.basmalaPrefix > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  ayahs.first.verseText
                                      .substring(0, ayahs.first.basmalaPrefix)
                                      .trim(),
                                  textAlign: TextAlign.center,
                                  style: quranStyle,
                                ),
                              ),
                            for (final entry in byPage.entries) ...[
                              Text.rich(
                                key: _pageKeys.putIfAbsent(
                                  entry.key,
                                  GlobalKey.new,
                                ),
                                TextSpan(
                                  children: [
                                    for (final a in entry.value)
                                      _verseSpan(a, t.highlight, t.marker),
                                  ],
                                ),
                                textAlign: TextAlign.justify,
                                style: quranStyle,
                              ),
                              _PageDivider(page: entry.key),
                            ],
                            _SurahNav(surah: widget.surah),
                          ],
                        ),
                      ),
                    ),
            ),
            if (_selected != null && surahs != null)
              VerseBar(
                verse: _selected!,
                surahs: surahs,
                onSave: () {
                  final a = ayahs!.firstWhere(
                    (x) => x.number == _selected!.ayah,
                  );
                  showSaveToFasil(
                    context,
                    ref,
                    verse: _selected!,
                    page: a.page,
                  );
                },
                onClose: () => setState(() => _selected = null),
              ),
          ],
        ),
      ),
    );
  }

  InlineSpan _verseSpan(AyahRow a, Color highlight, Color marker) {
    final key = (surah: a.surah, ayah: a.number);
    final recognizer = TapGestureRecognizer()
      ..onTap = () {
        setState(() => _selected = _selected == key ? null : key);
        if (_selected != null) _save(a);
      };
    _recognizers.add(recognizer);
    final selected = key == _selected;
    return TextSpan(
      recognizer: recognizer,
      style: selected ? TextStyle(backgroundColor: highlight) : null,
      semanticsLabel: null,
      children: [
        TextSpan(text: a.displayText),
        TextSpan(
          text: ' ۝${arabicDigits(a.number)} ',
          style: TextStyle(color: marker),
        ),
      ],
    );
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surah});

  final SurahRow surah;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: t.headBg,
        border: Border.all(color: t.frame, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            l.surahWord(surahName(context, surah)),
            style: TextStyle(
              color: t.headFg,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${surah.revelation == 'meccan' ? l.meccan : l.medinan} · ${l.ayahCount('${surah.ayahCount}')}',
            style: TextStyle(color: t.headFg, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PageDivider extends StatelessWidget {
  const _PageDivider({required this.page});

  final int page;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Divider(color: t.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              AppLocalizations.of(context).pageShort('$page'),
              style: TextStyle(color: t.muted, fontSize: 11),
            ),
          ),
          Expanded(child: Divider(color: t.border)),
        ],
      ),
    );
  }
}

class _SurahNav extends StatelessWidget {
  const _SurahNav({required this.surah});

  final int surah;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          if (surah > 1)
            IconButton.outlined(
              tooltip: MaterialLocalizations.of(context).previousPageTooltip,
              onPressed: () => context.go('/mushaf/continuous?s=${surah - 1}'),
              icon: const Icon(Icons.chevron_right),
            ),
          const Spacer(),
          if (surah < 114)
            IconButton.outlined(
              tooltip: MaterialLocalizations.of(context).nextPageTooltip,
              onPressed: () => context.go('/mushaf/continuous?s=${surah + 1}'),
              icon: const Icon(Icons.chevron_left),
            ),
        ],
      ),
    );
  }
}
