import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/db/content_database.dart';
import '../../../core/db/user_database.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/mushaf_repository.dart';
import '../mushaf_providers.dart';
import 'download_screen.dart';
import 'widgets/fasil_sheet.dart';
import 'widgets/go_to_page.dart';
import 'widgets/illuminated_frame.dart';
import 'widgets/mushaf_page.dart';
import 'widgets/old_mushaf_page.dart';
import 'widgets/page_interaction.dart';
import 'widgets/verse_services.dart';

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

  /// Reading is immersive: no bars until the reader touches the page.
  bool _chrome = false;
  int? _scrubPage;

  /// The selection: two ends on the current page, in either order.
  VerseKey? _selA;
  VerseKey? _selB;

  @override
  void initState() {
    super.initState();
    if (widget.selectSurah != null && widget.selectAyah != null) {
      _selA = _selB = (surah: widget.selectSurah!, ayah: widget.selectAyah!);
    }
    _open();
    if (ref.read(settingsProvider).keepScreenOn) WakelockPlus.enable();
    _applySystemBars();
  }

  void _applySystemBars() {
    SystemChrome.setEnabledSystemUIMode(
      _chrome ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    );
  }

  void _setChrome(bool on) {
    if (on == _chrome) return;
    setState(() => _chrome = on);
    _applySystemBars();
  }

  Future<void> _open() async {
    final edition = ref.read(editionProvider);
    final saved = await ref.read(userDatabaseProvider).position();
    var page = widget.initialPage;
    if (page == null && saved != null) {
      page = saved.edition == edition.name
          ? saved.page
          : (await ref
                    .read(mushafRepositoryProvider)
                    .ayah(saved.surah, saved.ayah))
                .pageIn(edition);
    }
    final start = (page ?? 1).clamp(1, mushafPageCount);
    if (!mounted) return;
    setState(() {
      _page = start;
      _controller = PageController(initialPage: start - 1);
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onPageChanged(int index) async {
    setState(() {
      _page = index + 1;
      _selA = _selB = null;
    });
    final ayahs = await ref.read(pageAyahsProvider(index + 1).future);
    if (ayahs.isEmpty) return;
    await ref
        .read(userDatabaseProvider)
        .savePosition(
          edition: ref.read(editionProvider).name,
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
    final oldEdition = ref.watch(editionProvider) == MushafEdition.madina1405;
    final illuminated =
        ref
            .watch(themeRegistryProvider)
            .byId(ref.watch(settingsProvider).styleId)
            .frame
            .outerStyle ==
        'illuminated';

    final marks = <VerseKey, Color>{
      for (final m
          in ref.watch(bookmarkSetsProvider).value ?? const <BookmarkSetRow>[])
        (surah: m.surah, ayah: m.ayah): Color(m.color),
    };

    Widget pageAt(int i) {
      final interaction = PageInteraction(
        selection: i + 1 == _page ? _selectionOn(i + 1) : const {},
        marks: marks,
        onTap: () {
          if (_selA != null) {
            setState(() => _selA = _selB = null);
          } else {
            _setChrome(!_chrome);
          }
        },
        onVerseLongPress: (v) {
          HapticFeedback.selectionClick();
          _setChrome(false);
          setState(() => _selA = _selB = v);
        },
        onMarkerTap: (v) => _setMark(MarkKind.reading, v, i + 1, auto: true),
        onHandleDrag: (start, v) =>
            setState(() => start ? _selA = v : _selB = v),
      );
      final pageWidget = oldEdition
          ? OldMushafPage(page: i + 1, interaction: interaction)
          : MushafPage(page: i + 1, interaction: interaction);
      if (!illuminated) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: pageWidget,
        );
      }
      final info = ref.watch(frameInfoProvider(i + 1)).value;
      void openIndex(String tab) {
        final a = ref.read(pageAyahsProvider(i + 1)).value?.firstOrNull;
        context.push(
          '/mushaf/index?tab=$tab&p=${i + 1}'
          '${a == null ? '' : '&s=${a.surah}'}'
          '${info == null ? '' : '&j=${info.juz}&h=${info.hizb}'}',
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
        child: IlluminatedFrame(
          info: info,
          onJuzTap: () => openIndex('juz'),
          onHizbTap: () => openIndex('hizb'),
          onSurahTap: () => openIndex('surahs'),
          onPageTap: _goToPage,
          child: pageWidget,
        ),
      );
    }

    final scrubbing = _scrubPage ?? _page;
    final range = _range();
    return Scaffold(
      backgroundColor: t.bg,
      body: Stack(
        children: [
          SafeArea(
            child: _controller == null
                ? const Center(child: CircularProgressIndicator())
                // The mushaf opens from the right in every interface language.
                : Directionality(
                    textDirection: TextDirection.rtl,
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: mushafPageCount,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, i) => pageAt(i),
                    ),
                  ),
          ),
          if (_chrome) ...[
            // A light veil so the controls read as a layer over the page.
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _setChrome(false),
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopControls(
                items: [
                  (
                    Icons.list_alt,
                    l.indexTitle,
                    () => context.push('/mushaf/index'),
                  ),
                  (
                    Icons.bookmarks_outlined,
                    l.fawasilTitle,
                    () => context.push('/mushaf/fawasil'),
                  ),
                  (
                    Icons.notes,
                    l.viewContinuous,
                    () => context.go(
                      '/mushaf/continuous?s=${first?.surah ?? 1}&a=${first?.number ?? 1}',
                    ),
                  ),
                  (
                    Icons.info_outline,
                    l.aboutMushafTitle,
                    () => context.push('/mushaf/about'),
                  ),
                  (
                    Icons.tune,
                    l.settingsTitle,
                    () => context.push('/settings'),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomControls(
                page: scrubbing,
                label: _scrubLabel(context, scrubbing, surahs),
                onChanged: (p) => setState(() => _scrubPage = p),
                onChangeEnd: (p) {
                  setState(() => _scrubPage = null);
                  _controller?.jumpToPage(p - 1);
                },
              ),
            ),
          ],
          if (range != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VerseServicesPanel(
                verses: range,
                surahs: surahs,
                onMark: (kind) => _setMark(kind, range.first, _page),
                onSaveToFasil: () => showSaveToFasil(
                  context,
                  ref,
                  verse: range.first,
                  page: _page,
                ),
                onClose: () => setState(() => _selA = _selB = null),
              ),
            ),
        ],
      ),
    );
  }

  /// Verses between the two selection ends on the current page, in order.
  List<VerseKey>? _range() {
    if (_selA == null || _selB == null) return null;
    final ayahs = ref.watch(pageAyahsProvider(_page)).value;
    if (ayahs == null) return [_selA!];
    final keys = [for (final a in ayahs) (surah: a.surah, ayah: a.number)];
    final ia = keys.indexOf(_selA!);
    final ib = keys.indexOf(_selB!);
    if (ia < 0 || ib < 0) return [_selA!];
    return keys.sublist(ia < ib ? ia : ib, (ia < ib ? ib : ia) + 1);
  }

  Set<VerseKey> _selectionOn(int page) => {...?_range()};

  Future<void> _setMark(
    MarkKind kind,
    VerseKey v,
    int page, {
    bool auto = false,
  }) async {
    final l = AppLocalizations.of(context);
    final name = switch (kind) {
      MarkKind.reading => l.markReading,
      MarkKind.review => l.markReview,
      MarkKind.hifz => l.markHifz,
      MarkKind.tadabbur => l.markTadabbur,
    };
    HapticFeedback.lightImpact();
    await ref
        .read(userDatabaseProvider)
        .setMark(kind, name: name, surah: v.surah, ayah: v.ayah, page: page);
    if (!mounted) return;
    final surahs = ref.read(surahsProvider).value;
    final sName = surahs == null ? '' : surahName(context, surahs[v.surah - 1]);
    final digits = NumberFormatter(Localizations.localeOf(context));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1600),
          content: Text(
            auto
                ? l.autoFasil(sName, digits(v.ayah))
                : l.markMoved(name, sName, digits(v.ayah)),
          ),
        ),
      );
  }

  Future<void> _goToPage() async {
    final page = await showGoToPage(context, current: _page);
    if (page != null) _controller?.jumpToPage(page - 1);
  }

  String _scrubLabel(BuildContext context, int page, List<SurahRow>? surahs) {
    final first = ref.watch(pageAyahsProvider(page)).value?.firstOrNull;
    final digits = NumberFormatter(Localizations.localeOf(context));
    if (first == null || surahs == null) return digits(page);
    return '${surahName(context, surahs[first.surah - 1])} : ${digits(page)}';
  }
}

/// Destinations shown at the top when the reader touches the page.
class _TopControls extends StatelessWidget {
  const _TopControls({required this.items});

  final List<(IconData, String, VoidCallback)> items;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Material(
      color: t.paper,
      elevation: 2,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          child: Row(
            children: [
              for (final (icon, label, onTap) in items)
                Expanded(
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: t.muted, size: 24),
                          const SizedBox(height: 3),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: t.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page scrubber: drag to any page; a bubble shows the surah and page.
class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.page,
    required this.label,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final int page;
  final String label;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    final l = AppLocalizations.of(context);
    return Material(
      color: t.paper,
      elevation: 2,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: t.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.border),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: t.ink,
                  ),
                ),
              ),
              // Page 1 on the right, like the mushaf.
              SizedBox(
                width: double.infinity,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Slider(
                    activeColor: t.control,
                    inactiveColor: t.border,
                    min: 1,
                    max: mushafPageCount.toDouble(),
                    divisions: mushafPageCount - 1,
                    value: page.toDouble(),
                    semanticFormatterCallback: (v) => l.pageOf('${v.round()}'),
                    onChanged: (v) => onChanged(v.round()),
                    onChangeEnd: (v) => onChangeEnd(v.round()),
                  ),
                ),
              ),
            ],
          ),
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
