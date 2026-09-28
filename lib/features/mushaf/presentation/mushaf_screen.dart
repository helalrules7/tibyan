import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/db/content_database.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../mushaf_providers.dart';
import 'download_screen.dart';
import 'widgets/fasil_sheet.dart';
import 'widgets/mushaf_page.dart';

const mushafPageCount = 604;

/// Name of a surah in the interface language (names from Tanzil metadata).
String surahName(BuildContext context, SurahRow s) =>
    Localizations.localeOf(context).languageCode == 'ar' ? s.nameAr : s.nameEn;

/// The page view of the new Madina edition.
class MushafScreen extends ConsumerStatefulWidget {
  const MushafScreen({
    super.key,
    this.initialPage,
    this.selectSurah,
    this.selectAyah,
  });

  final int? initialPage;
  final int? selectSurah;
  final int? selectAyah;

  @override
  ConsumerState<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends ConsumerState<MushafScreen> {
  PageController? _controller;
  int _page = 1;
  bool _chrome = true;
  VerseKey? _selected;

  @override
  void initState() {
    super.initState();
    if (widget.selectSurah != null && widget.selectAyah != null) {
      _selected = (surah: widget.selectSurah!, ayah: widget.selectAyah!);
    }
    _open();
    if (ref.read(settingsProvider).keepScreenOn) WakelockPlus.enable();
  }

  Future<void> _open() async {
    final saved = await ref.read(userDatabaseProvider).position();
    final page = (widget.initialPage ?? saved?.page ?? 1).clamp(
      1,
      mushafPageCount,
    );
    if (!mounted) return;
    setState(() {
      _page = page;
      _controller = PageController(initialPage: page - 1);
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onPageChanged(int index) async {
    setState(() {
      _page = index + 1;
      _selected = null;
    });
    final ayahs = await ref.read(pageAyahsProvider(index + 1).future);
    if (ayahs.isEmpty) return;
    await ref
        .read(userDatabaseProvider)
        .savePosition(
          edition: MushafEdition.madina1441.name,
          view: 'page',
          surah: ayahs.first.surah,
          ayah: ayahs.first.number,
          page: index + 1,
        );
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(pagesInstalledProvider)) return const DownloadScreen();
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final surahs = ref.watch(surahsProvider).value;
    final first = ref.watch(pageAyahsProvider(_page)).value?.firstOrNull;
    final title = first == null || surahs == null
        ? ''
        : l.surahWord(surahName(context, surahs[first.surah - 1]));
    final oldEdition =
        ref.watch(settingsProvider).edition == MushafEdition.madina1405;

    return Scaffold(
      backgroundColor: t.paper,
      appBar: _chrome
          ? AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  if (first != null)
                    Text(
                      l.juzPage('${first.juz}', '$_page'),
                      style: TextStyle(fontSize: 12, color: t.muted),
                    ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: l.viewContinuous,
                  icon: const Icon(Icons.notes),
                  onPressed: () => context.go(
                    '/mushaf/continuous?s=${first?.surah ?? 1}&a=${first?.number ?? 1}',
                  ),
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
                IconButton(
                  tooltip: l.aboutMushafTitle,
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => context.push('/mushaf/about'),
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (oldEdition && _chrome)
              MaterialBanner(
                content: Text(l.editionComingSoon),
                actions: const [SizedBox.shrink()],
              ),
            Expanded(
              child: _controller == null
                  ? const Center(child: CircularProgressIndicator())
                  // The mushaf opens from the right in every interface language.
                  : Directionality(
                      textDirection: TextDirection.rtl,
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: mushafPageCount,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: MushafPage(
                            page: i + 1,
                            selected: i + 1 == _page ? _selected : null,
                            onVerseTap: (v) => setState(() {
                              _selected = v == _selected ? null : v;
                              _chrome = true;
                            }),
                            onBackgroundTap: () => setState(() {
                              if (_selected != null) {
                                _selected = null;
                              } else {
                                _chrome = !_chrome;
                              }
                            }),
                          ),
                        ),
                      ),
                    ),
            ),
            if (_selected != null)
              VerseBar(
                verse: _selected!,
                surahs: surahs,
                onSave: () => showSaveToFasil(
                  context,
                  ref,
                  verse: _selected!,
                  page: _page,
                ),
                onClose: () => setState(() => _selected = null),
              )
            else if (_chrome)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  l.tapVerseHint,
                  style: TextStyle(color: t.muted, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class VerseBar extends StatelessWidget {
  const VerseBar({
    super.key,
    required this.verse,
    required this.surahs,
    required this.onSave,
    required this.onClose,
  });

  final VerseKey verse;
  final List<SurahRow>? surahs;
  final VoidCallback onSave;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final name = surahs == null
        ? ''
        : surahName(context, surahs![verse.surah - 1]);
    return Material(
      color: t.player,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  '${l.surahWord(name)} · ${l.verseSelected('${verse.ayah}')}',
                  style: TextStyle(
                    color: t.playerFg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: l.fasilSaveHere,
              onPressed: onSave,
              icon: Icon(Icons.bookmark_add_outlined, color: t.playerFg),
            ),
            IconButton(
              tooltip: l.cancel,
              onPressed: onClose,
              icon: Icon(Icons.close, color: t.playerFg),
            ),
          ],
        ),
      ),
    );
  }
}
