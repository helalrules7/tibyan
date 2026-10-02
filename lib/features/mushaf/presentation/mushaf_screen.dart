import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import '../../audio/player_bar.dart';
import '../../audio/recitation.dart';
import '../../hifz/data/hifz_repository.dart';
import '../../hifz/domain/recitation_test.dart';
import '../../hifz/domain/strength.dart';
import '../../hifz/hifz_providers.dart';
import '../../hifz/presentation/hifz_sheets.dart';
import '../../hifz/presentation/similar_sheet.dart';
import '../../word_study/word_pick.dart';
import '../../word_study/word_study_sheet.dart';
import '../../khatma/domain/reading_tracker.dart';
import '../../khatma/khatma_providers.dart';
import '../../khatma/presentation/journal_screen.dart';
import '../data/mushaf_repository.dart';
import '../mushaf_providers.dart';
import 'download_screen.dart';
import 'widgets/art_frame.dart';
import 'widgets/fasil_sheet.dart';
import 'widgets/go_to_page.dart';
import 'widgets/illuminated_frame.dart';
import 'widgets/mushaf_page.dart';
import 'widgets/ornate_pages.dart';
import 'widgets/old_mushaf_page.dart';
import 'widgets/page_interaction.dart';
import 'widgets/shamarly_page.dart';
import 'widgets/verse_services.dart';

/// Name of a surah in the interface language (names from Tanzil metadata).
String surahName(BuildContext context, SurahRow s) =>
    Localizations.localeOf(context).languageCode == 'ar' ? s.nameAr : s.nameEn;

/// The page view of the chosen edition.
class MushafScreen extends ConsumerStatefulWidget {
  const MushafScreen({
    super.key,
    this.initialPage,
    this.selectSurah,
    this.selectAyah,
    this.hifzUnit,
    this.hifzFrom,
    this.hifzTo,
  });

  final int? initialPage;
  final int? selectSurah;
  final int? selectAyah;

  /// A hifz test: the unit kind (`page`, `quarter`, `surah`) and its first
  /// and last verse (`surah:ayah`). The page opens with its verses
  /// covered, revealed word by word, and the unit is graded at the end.
  final String? hifzUnit;
  final String? hifzFrom;
  final String? hifzTo;

  @override
  ConsumerState<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends ConsumerState<MushafScreen>
    with SingleTickerProviderStateMixin {
  PageController? _controller;
  int _page = 1;

  /// Reading is immersive: no bars until the reader touches the page.
  bool _chrome = false;
  int? _scrubPage;

  /// The selection: two ends on the current page, in either order.
  VerseKey? _selA;
  VerseKey? _selB;

  /// Multi-verse selection: the handles are shown and every other control
  /// waits until the reader taps Done.
  bool _multi = false;

  /// Recitation mode: verses stay covered until revealed.
  bool _recite = false;
  final Set<VerseKey> _revealed = {};

  /// Hifz test (word by word): unlike recitation mode, it goes on across
  /// pages (a unit may span several) until it is graded or closed.
  late bool _testing = _hifzKind != null && widget.hifzFrom != null;
  final RecitationTest _test = RecitationTest();

  HifzUnitKind? get _hifzKind =>
      HifzUnitKind.values.asNameMap()[widget.hifzUnit ?? ''];

  /// Word study: the next tap on the page picks a word to study.
  bool _pickWord = false;

  /// Touch reading: the verse the reader last tapped is shaded.
  bool get _touchReading => ref.read(settingsProvider).touchReading;
  VerseKey? _touched;

  /// Auto-scroll: pages stacked vertically, moving at [_speed].
  bool _autoScroll = false;
  bool _paused = false;
  int _speed = 3;
  ScrollController? _vertical;
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  double _pageExtent = 1;

  /// Counts pages read (for the khatma) and the time spent reading (for
  /// the reports).
  late final ReadingTracker _tracker;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    final service = ref.read(khatmaServiceProvider);
    _tracker = ReadingTracker(
      onPageRead: service.pageRead,
      onSessionEnd: service.sessionEnded,
    );
    _lifecycle = AppLifecycleListener(onHide: _tracker.end, onShow: _trackPage);
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

  /// A tap on the page, its frame or the space around it: clears the
  /// selection, or shows and hides the menus.
  void _onPageTap() {
    if (_multi) return;
    if (_selA != null) {
      setState(() => _selA = _selB = null);
    } else {
      _setChrome(!_chrome);
    }
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
    final start = (page ?? 1).clamp(_first, edition.pageCount);
    if (!mounted) return;
    setState(() {
      _page = start;
      _controller = PageController(initialPage: start - _first);
    });
    _trackPage();
  }

  void _trackPage() {
    if (_page >= 1) {
      _tracker.show(_page, ref.read(editionProvider).name);
    } else {
      _tracker.leavePage();
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _tracker.end();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _ticker?.dispose();
    _vertical?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onPageChanged(int index) async {
    setState(() {
      _page = index + _first;
      _selA = _selB = null;
      _multi = false;
      _pickWord = false;
      // Recitation mode is for one page: turning the page ends it.
      _recite = false;
      _revealed.clear();
      _test.newPage();
    });
    _trackPage();
    if (_page < 1) return;
    final ayahs = await ref.read(pageAyahsProvider(_page).future);
    if (ayahs.isEmpty) return;
    await ref
        .read(userDatabaseProvider)
        .savePosition(
          edition: ref.read(editionProvider).name,
          view: 'page',
          surah: ayahs.first.surah,
          ayah: ayahs.first.number,
          page: _page,
        );
  }

  /// In the Zakhrafa style the mushaf opens with a cover as page 0.
  /// The Madina editions open with the app's cover as page 0. The
  /// Shamarly edition has its own cover as page 1, shown in the same frame,
  /// so it starts there.
  int get _first => ref.read(editionProvider) == MushafEdition.shamarly ? 1 : 0;

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(pagesInstalledProvider)) return const DownloadScreen();
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final surahs = ref.watch(surahsProvider).value;
    final edition = ref.watch(editionProvider);
    final pageCount = edition.pageCount;
    // Page numbers differ between editions: reopen at the same verse.
    ref.listen(editionProvider, (_, _) => _open());

    final marks = <VerseKey, Color>{
      for (final m
          in ref.watch(bookmarkSetsProvider).value ?? const <BookmarkSetRow>[])
        (surah: m.surah, ayah: m.ayah): Color(m.color),
    };

    final settings = ref.watch(settingsProvider);
    // The current page's verses: recitation mode hides them, and after an
    // edition change they arrive later, so the page must rebuild then.
    ref.watch(pageAyahsProvider(_page));
    final recitation = ref.watch(recitationProvider);
    ref.listen(recitationProvider.select((r) => (r.surah, r.ayah, r.word)), (
      before,
      now,
    ) {
      if (now.$2 == null) return;
      // While a file loads, the verse reported is the new file's start
      // until it is placed at the verse: following it turned the page to
      // the surah's first page whenever the reader changed reciter.
      if (ref.read(recitationProvider).loading) return;
      // Words matter only where a verse can run over a page break.
      final verse = before?.$1 != now.$1 || before?.$2 != now.$2;
      if (verse || edition == MushafEdition.shamarly) {
        _follow((surah: now.$1, ayah: now.$2!), now.$3);
      }
    });
    final markerImages = ref.watch(markerImagesProvider).value;
    // «Follows the theme»: the theme's own marker, or Zakhrafa's rosette.
    final themeArt = settings.markerStyle == MarkerStyle.theme
        ? watchThemeArt(context, ref)
        : null;
    final markerStyle = settings.markerStyle != MarkerStyle.theme
        ? settings.markerStyle
        : context.tokens.style.art != null
        ? MarkerStyle.theme
        : MarkerStyle.rosette16;
    final markerLook =
        markerStyle == MarkerStyle.traditional && settings.markerTint == null
        ? null
        : MarkerLook(
            style: markerStyle,
            image: markerImages?[markerStyle],
            art: themeArt?.marker,
            tint: settings.markerTint == null
                ? null
                : Color(settings.markerTint!),
            paper: t.paper,
            ink: t.ink,
          );

    Widget pageAt(int i) {
      final pg = i + _first;
      if (pg == 0) return CoverPage(onTap: () => _setChrome(!_chrome));
      if (edition == MushafEdition.shamarly && pg == 1) {
        return CoverPage(onTap: () => _setChrome(!_chrome));
      }
      // The first two pages of the text (al-Fatiha, the opening of
      // al-Baqarah) sit in the ornate opening frame.
      final openingSurah = switch (edition) {
        MushafEdition.shamarly => pg == 2 || pg == 3 ? pg - 1 : null,
        _ => pg <= 2 ? pg : null,
      };
      final testUnits = _testing && pg == _page
          ? ref.watch(pageRevealUnitsProvider(pg)).value ??
                const <VerseKey, RevealUnits>{}
          : const <VerseKey, RevealUnits>{};
      final testCovers = _testing && pg == _page
          ? _test.covers(_pageKeys(pg), testUnits)
          : null;
      final interaction = PageInteraction(
        // The reader's selection, or else the verse being recited.
        selection: pg == _page && _selA != null
            ? _selectionOn(pg)
            : recitation.active && recitation.ayah != null
            ? {(surah: recitation.surah, ayah: recitation.ayah!)}
            : const {},
        marks: marks,
        onTap: _onPageTap,
        onVerseLongPress: (v) {
          HapticFeedback.selectionClick();
          _setChrome(false);
          setState(() {
            _selA = _selB = v;
            _pickWord = false;
          });
        },
        onMarkerTap: (v) => _toggleMark(v, pg),
        onVerseTap: _touchReading && !_multi
            ? (v) => setState(() => _touched = v)
            : null,
        touched: _touchReading ? _touched : null,
        touchColor: _touchReading
            ? (context.tokens.mode.isLight
                  ? const Color(0x33D0453B)
                  : const Color(0x40FF8A80))
            : null,
        onHandleDrag: (start, v) =>
            setState(() => start ? _selA = v : _selB = v),
        markerLook: markerLook,
        // Recitation mode covers the page being drawn, whatever the page
        // count says: after an edition change the two can differ for a
        // moment (turning the page ends the mode anyway).
        hidden: _testing
            ? testCovers?.hidden
            : _recite
            ? _hiddenOn(pg)
            : null,
        hiddenWords: _testing
            ? testCovers?.pieces ?? const {}
            : _recite
            ? _wordsOf(_hiddenOn(pg), pg)
            : const {},
        revealedWords: _testing
            ? _test.shownPieces(_pageKeys(pg), testUnits)
            : const {},
        // A tap shows a covered verse, or covers it again; in a hifz test
        // it shows the verse's next word.
        onHiddenTap: (v) => setState(
          () => _testing
              ? _test.revealPiece(v, testUnits[v])
              : _revealed.contains(v)
              ? _revealed.remove(v)
              : _revealed.add(v),
        ),
        ornateOpening: openingSurah != null,
        showHandles: _multi,
        divineNames: settings.highlightDivineNames
            ? ref.watch(divineNameBoxesProvider(pg)).value ?? const []
            : const [],
        divineColor: settings.highlightDivineNames
            ? (context.tokens.mode.isLight
                  ? const Color(0xFFC62828)
                  : const Color(0xFFFF8A80))
            : null,
        activeWord: recitation.active && recitation.word != null
            ? _union(
                ref.watch(pageWordBoxesProvider(pg)).value?[(
                  recitation.surah,
                  recitation.ayah!,
                  recitation.word!,
                )],
              )
            : null,
        emphasisLines:
            ref.watch(frameInfoProvider(pg)).value?.basmalaLines ?? const {},
        onPick: _pickWord && pg == _page
            ? (point, verse) => _pickAt(pg, point, verse)
            : null,
      );
      final tools = _ReadingTools(
        touchReading: _touchReading,
        onTouchReading: _toggleTouchReading,
        listening: recitation.active,
        onListen: _listenFromPage,
        recite: _recite || _testing,
        onRecite: () => _testing
            ? _closeTest()
            : _recite
            ? setState(() {
                _recite = false;
                _revealed.clear();
              })
            : _startRecite(),
      );
      final pageWidget = switch (edition) {
        MushafEdition.madina1441 => MushafPage(
          page: pg,
          interaction: interaction,
        ),
        MushafEdition.madina1405 => OldMushafPage(
          page: pg,
          interaction: interaction,
        ),
        MushafEdition.shamarly => ShamarlyMushafPage(
          page: pg,
          interaction: interaction,
        ),
      };
      final info = ref.watch(frameInfoProvider(pg)).value;
      void openIndex(String tab) {
        final a = ref.read(pageAyahsProvider(pg)).value?.firstOrNull;
        context.push(
          '/mushaf/index?tab=$tab&p=$pg'
          '${a == null ? '' : '&s=${a.surah}'}'
          '${info == null ? '' : '&j=${info.juz}&h=${info.hizb}'}',
        );
      }

      if (openingSurah != null) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
          child: OpeningPage(
            page: pg,
            surah: openingSurah,
            // Recitation mode: the next page's first word would give it away.
            catchword: _recite || _testing ? null : info?.catchword,
            onPageTap: _goToPage,
            onSurahTap: () => openIndex('surahs'),
            tools: tools,
            child: pageWidget,
          ),
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
          tools: tools,
          showCatchword: !_recite && !_testing,
          linePadding: edition == MushafEdition.shamarly
              ? shamarlyLinePadding
              : null,
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
          // The frame and the space above and below the page open the
          // menus too; a tap on the page itself or on a frame label is
          // taken by that (deeper) widget first.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onPageTap,
            child: SafeArea(
              // While listening, the page sits above the player bar so the
              // catchword and the reading tools stay visible.
              minimum: EdgeInsets.only(
                bottom: recitation.active && !_autoScroll
                    ? MediaQuery.paddingOf(context).bottom + 80
                    : 0,
              ),
              child: _autoScroll
                  ? LayoutBuilder(
                      builder: (context, box) {
                        _pageExtent = box.maxHeight;
                        _vertical ??= ScrollController(
                          initialScrollOffset: (_page - _first) * box.maxHeight,
                        );
                        return ListView.builder(
                          controller: _vertical,
                          itemExtent: box.maxHeight,
                          itemCount: pageCount + 1 - _first,
                          itemBuilder: (context, i) => pageAt(i),
                        );
                      },
                    )
                  : _controller == null
                  ? const Center(child: CircularProgressIndicator())
                  // The mushaf opens from the right in every interface language.
                  : Directionality(
                      textDirection: TextDirection.rtl,
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: pageCount + 1 - _first,
                        // The pages either side are built and their images
                        // decoded before they are turned to, so a page turn
                        // does not stop on a spinner.
                        allowImplicitScrolling: true,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, i) => pageAt(i),
                      ),
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
                  (Icons.home_outlined, l.homeTitle, () => context.go('/')),
                  (
                    Icons.search_outlined,
                    l.sectionSearch,
                    () => context.push('/search'),
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
                pageCount: pageCount,
                label: _scrubLabel(context, scrubbing, surahs),
                onChanged: (p) => setState(() => _scrubPage = p),
                onChangeEnd: (p) {
                  setState(() => _scrubPage = null);
                  _controller?.jumpToPage(p - _first);
                },
                onRecite: _startRecite,
                onListen: _listenFromPage,
                onGoTo: _goToPage,
                onAutoScroll: _startAutoScroll,
              ),
            ),
          ],
          if (_autoScroll)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: _AutoScrollBar(
                  paused: _paused,
                  speed: _speed,
                  onPause: () => setState(() => _paused = !_paused),
                  onSlower: () =>
                      setState(() => _speed = (_speed - 1).clamp(1, 10)),
                  onFaster: () =>
                      setState(() => _speed = (_speed + 1).clamp(1, 10)),
                  onClose: _stopAutoScroll,
                ),
              ),
            ),
          if (recitation.active && range == null && !_multi && !_chrome)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: const SafeArea(top: false, child: PlayerBar()),
            ),
          // The chosen edition is still downloading: say so, and that the
          // new Madina edition is read meanwhile.
          if (ref.watch(chosenEditionProvider) != edition && !_chrome)
            const Positioned(
              top: 0,
              left: 24,
              right: 24,
              child: SafeArea(child: DownloadingBanner()),
            ),
          if (_multi)
            Positioned(
              top: 0,
              left: 16,
              right: 16,
              child: SafeArea(
                child: _MultiSelectBar(
                  count: range?.length ?? 1,
                  onDone: () => setState(() => _multi = false),
                ),
              ),
            ),
          if (_testing && !_chrome)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: SafeArea(top: false, child: _testBar(context, surahs)),
            ),
          if (_pickWord)
            Positioned(
              top: 0,
              left: 16,
              right: 16,
              child: SafeArea(
                child: _WordPickBar(
                  onCancel: () => setState(() => _pickWord = false),
                ),
              ),
            ),
          if (range != null && !_multi)
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
                onMultiSelect: () {
                  _setChrome(false);
                  setState(() => _multi = true);
                },
                onListen: () {
                  final one = range.length == 1;
                  setState(() => _selA = _selB = null);
                  ref
                      .read(recitationProvider.notifier)
                      .play(
                        range.first.surah,
                        from: range.first.ayah,
                        // Several verses: that stretch, repeated as set.
                        to: one ? null : range.last.ayah,
                      );
                },
                onTafsir: () => context.push(
                  '/mushaf/tafsir?s=${range.first.surah}&a=${range.first.ayah}',
                ),
                onWordStudy: () {
                  _setChrome(false);
                  setState(() {
                    _selA = _selB = null;
                    _pickWord = true;
                  });
                },
                onWordMeanings: () => showVerseMeanings(
                  context,
                  verses: [
                    for (final v in range) (surah: v.surah, ayah: v.ayah),
                  ],
                ),
                similarCount: range.length == 1
                    ? ref
                              .watch(
                                similarCountProvider((
                                  range.first.surah,
                                  range.first.ayah,
                                )),
                              )
                              .value ??
                          0
                    : 0,
                onSimilar: () => showSimilarSheet(
                  context,
                  surah: range.first.surah,
                  ayah: range.first.ayah,
                ),
                onReflect: () => showReflectionSheet(
                  context,
                  surah: range.first.surah,
                  ayah: range.first.ayah,
                ),
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

  /// Word study: the word under [point] (edition units) on [page]. A verse
  /// without word boxes there opens with its words to choose from; a tap
  /// outside any verse keeps waiting for a word.
  void _pickAt(int page, Offset point, VerseKey? verse) {
    final boxes = ref.read(pageWordBoxesProvider(page)).value ?? const {};
    final slop = ref.read(editionProvider) == MushafEdition.madina1441
        ? 2.0
        : 6.0;
    final hit =
        wordUnder(boxes, point, verse: verse, slop: slop) ??
        wordUnder(boxes, point, slop: slop);
    if (hit == null && verse == null) return;
    HapticFeedback.selectionClick();
    setState(() => _pickWord = false);
    showWordStudy(
      context,
      surah: hit?.$1 ?? verse!.surah,
      ayah: hit?.$2 ?? verse!.ayah,
      word: hit?.$3,
    );
  }

  /// Word boxes of [verses] on [page], by verse (edition units).
  Map<VerseKey, List<Rect>> _wordsOf(Set<VerseKey> verses, int page) {
    final boxes = ref.watch(pageWordBoxesProvider(page)).value ?? const {};
    final out = <VerseKey, List<Rect>>{};
    for (final MapEntry(key: (s, a, _), value: pieces) in boxes.entries) {
      final k = (surah: s, ayah: a);
      if (verses.contains(k)) (out[k] ??= []).addAll(pieces);
    }
    return out;
  }

  static Rect? _union(List<Rect>? pieces) =>
      pieces?.reduce((a, b) => a.expandToInclude(b));

  /// Starts listening from the first verse on the current page.
  void _listenFromPage() {
    final a = ref.read(pageAyahsProvider(_page)).value?.firstOrNull;
    if (a == null) return;
    _setChrome(false);
    ref.read(recitationProvider.notifier).play(a.surah, from: a.number);
  }

  /// Turns to the page of the verse being recited. A Shamarly verse may
  /// run over a page break: the page then follows the recited [word] when
  /// its box is known, and otherwise stays where the verse starts.
  Future<void> _follow(VerseKey v, int? word) async {
    if (!ref.read(settingsProvider).followRecitation || _autoScroll) return;
    if (_selA != null || _multi) return;
    final edition = ref.read(editionProvider);
    final repo = ref.read(mushafRepositoryProvider);
    final row = await repo.ayah(v.surah, v.ayah);
    var page = row.pageIn(edition);
    if (edition == MushafEdition.shamarly && row.pageShamarlyEnd != page) {
      final pages = await repo.shamarlyWordPages(v.surah, v.ayah);
      if (word != null && pages[word] != null) {
        page = pages[word]!;
      } else if (_page >= row.pageShamarly && _page <= row.pageShamarlyEnd) {
        return; // already on a page of this verse
      }
    }
    if (!mounted || page == _page) return;
    _controller?.animateToPage(
      page - _first,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

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

  /// The verses of [page]; watched, so the page rebuilds when they arrive.
  List<VerseKey> _pageKeys(int page) => [
    for (final a
        in ref.watch(pageAyahsProvider(page)).value ?? const <AyahRow>[])
      (surah: a.surah, ayah: a.number),
  ];

  Set<VerseKey> _hiddenOn(int page) => {
    for (final k in _pageKeys(page))
      if (!_revealed.contains(k)) k,
  };

  void _toggleTouchReading() {
    HapticFeedback.selectionClick();
    final on = !_touchReading;
    ref.read(settingsProvider.notifier).setTouchReading(on);
    setState(() => _touched = null);
    if (on) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1800),
            content: Text(l.touchReadingOn),
          ),
        );
    }
  }

  /// Hifz test toolbar: reveal word by word or verse by verse, judge
  /// each verse, see its similar verses, and grade the unit.
  Widget _testBar(BuildContext context, List<SurahRow>? surahs) {
    final l = AppLocalizations.of(context);
    final digits = NumberFormatter(Localizations.localeOf(context));
    final units = ref.watch(pageRevealUnitsProvider(_page)).value ?? const {};
    final current = _test.current;
    final remembered = _test.results.values
        .where((r) => r == VerseResult.remembered)
        .length;
    final missed = _test.results.length - remembered;
    return _TestBar(
      verse: current == null || surahs == null
          ? null
          : '${surahName(context, surahs[current.surah - 1])} ${digits(current.ayah)}',
      result: current == null ? null : _test.results[current],
      byLine: current != null && units[current]?.byWord == false,
      counts: _test.results.isEmpty
          ? null
          : l.testCounts(digits(remembered), digits(missed)),
      similar: current == null
          ? 0
          : ref
                    .watch(similarCountProvider((current.surah, current.ayah)))
                    .value ??
                0,
      onSimilar: current == null
          ? null
          : () => showSimilarSheet(
              context,
              surah: current.surah,
              ayah: current.ayah,
            ),
      onNextWord: () =>
          setState(() => _test.revealNext(_pageKeys(_page), _units)),
      onNextVerse: () =>
          setState(() => _test.revealNextVerse(_pageKeys(_page), _units)),
      onAll: () => setState(() => _test.revealAll(_pageKeys(_page), _units)),
      onRemembered: current == null
          ? null
          : () => _judge(current, VerseResult.remembered),
      onMissed: current == null
          ? null
          : () => _judge(current, VerseResult.missed),
      onGrade: _gradeUnit,
      onClose: _closeTest,
    );
  }

  /// The reader judged a verse: kept for the unit's grade, and saved to
  /// the verse's strength on the hifz map.
  Future<void> _judge(VerseKey v, VerseResult r) async {
    HapticFeedback.selectionClick();
    setState(() => _test.grade(v, r, _pageKeys(_page), _units));
    await saveVerseResults(ref.read(userDatabaseProvider), {v: r});
  }

  /// Grades the unit under test (in a hifz test) or else the current page,
  /// and schedules its next review.
  Future<void> _gradeUnit() async {
    final repo = ref.read(hifzRepositoryProvider);
    final edition = ref.read(editionProvider);
    final kind = _hifzKind;
    final HifzUnit? unit;
    if (kind != null && widget.hifzFrom != null && widget.hifzTo != null) {
      final verses = await repo.versesOf(widget.hifzFrom!, widget.hifzTo!);
      unit = verses.isEmpty ? null : HifzUnit(kind, verses.first, verses.last);
    } else {
      unit = await repo.unit(HifzUnitKind.page, _page, edition);
    }
    if (unit == null || !mounted) return;
    final l = AppLocalizations.of(context);
    final digits = NumberFormatter(Localizations.localeOf(context));
    final surahs = ref.read(surahsProvider).value;
    final title = switch (unit.kind) {
      HifzUnitKind.page => l.pageOf(digits(_page)),
      HifzUnitKind.quarter => l.hifzQuarter(digits(unit.from.hizbQuarter)),
      HifzUnitKind.surah => l.surahWord(
        surahs == null ? '' : surahName(context, surahs[unit.from.surah - 1]),
      ),
    };
    final inUnit = {
      for (final e in _test.results.entries)
        if (_inRange(e.key, unit)) e.key: e.value,
    };
    final remembered = inUnit.values
        .where((r) => r == VerseResult.remembered)
        .length;
    final grade = await showGradeSheet(
      context,
      title: title,
      suggested: suggestGrade(inUnit.values),
      counts: inUnit.isEmpty
          ? null
          : l.testCounts(
              digits(remembered),
              digits(inUnit.length - remembered),
            ),
    );
    if (grade == null || !mounted) return;
    final review = await gradeUnit(
      db: ref.read(userDatabaseProvider),
      repo: repo,
      kind: unit.kind,
      fromRef: unit.fromRef,
      toRef: unit.toRef,
      grade: grade,
      results: inUnit,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l.gradeSaved(reviewDate(context, review.due))),
        ),
      );
    _closeTest();
  }

  static bool _inRange(VerseKey v, HifzUnit u) {
    int order(int s, int a) => s * 1000 + a;
    final x = order(v.surah, v.ayah);
    return x >= order(u.from.surah, u.from.number) &&
        x <= order(u.to.surah, u.to.number);
  }

  /// Ends the hifz test and returns to where it was opened from.
  void _closeTest() {
    setState(() {
      _testing = false;
      _test.newPage();
    });
    if (context.canPop()) context.pop();
  }

  Map<VerseKey, RevealUnits> get _units =>
      ref.read(pageRevealUnitsProvider(_page)).value ?? const {};

  void _startRecite() {
    _setChrome(false);
    setState(() {
      _recite = true;
      _revealed.clear();
      _selA = _selB = null;
      _multi = false;
    });
  }

  void _startAutoScroll() {
    _setChrome(false);
    setState(() {
      _autoScroll = true;
      _paused = false;
      _recite = false;
      _selA = _selB = null;
      _multi = false;
      _vertical?.dispose();
      _vertical = null;
    });
    _ticker ??= createTicker(_tick);
    _lastTick = Duration.zero;
    _ticker!.start();
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    final c = _vertical;
    if (_paused || c == null || !c.hasClients) return;
    final next = (c.offset + dt * 7.0 * _speed).clamp(
      0.0,
      c.position.maxScrollExtent,
    );
    c.jumpTo(next);
    final page = (next / _pageExtent + 0.5).floor() + _first;
    if (page != _page) _onPageChanged(page - _first);
  }

  void _stopAutoScroll() {
    _ticker?.stop();
    final page = _page;
    setState(() {
      _autoScroll = false;
      _controller?.dispose();
      _controller = PageController(initialPage: page - _first);
    });
  }

  /// Tapping a verse marker sets the reading mark there, or removes the
  /// marks already on that verse.
  Future<void> _toggleMark(VerseKey v, int page) async {
    final db = ref.read(userDatabaseProvider);
    final here = [
      for (final m
          in ref.read(bookmarkSetsProvider).value ?? const <BookmarkSetRow>[])
        if (m.surah == v.surah && m.ayah == v.ayah) m,
    ];
    if (here.isEmpty) return _setMark(MarkKind.reading, v, page, auto: true);
    HapticFeedback.lightImpact();
    for (final m in here) {
      await db.deleteBookmarkSet(m.id);
    }
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1400),
          content: Text(l.markRemoved),
        ),
      );
  }

  Future<void> _goToPage() async {
    final page = await showGoToPage(
      context,
      current: _page,
      max: ref.read(editionProvider).pageCount,
    );
    if (page != null) _controller?.jumpToPage(page - _first);
  }

  String _scrubLabel(BuildContext context, int page, List<SurahRow>? surahs) {
    final first = ref.watch(pageAyahsProvider(page)).value?.firstOrNull;
    final digits = NumberFormatter(Localizations.localeOf(context));
    if (first == null || surahs == null) return digits(page);
    return '${surahName(context, surahs[first.surah - 1])} : ${digits(page)}';
  }
}

/// Touch reading, listening from the top of the page and hiding the
/// verses, just under the page number.
class _ReadingTools extends StatelessWidget {
  const _ReadingTools({
    required this.touchReading,
    required this.recite,
    required this.listening,
    required this.onTouchReading,
    required this.onListen,
    required this.onRecite,
  });

  final bool touchReading;
  final bool recite;
  final bool listening;
  final VoidCallback onTouchReading;
  final VoidCallback onListen;
  final VoidCallback onRecite;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    Widget button(IconData icon, String label, bool on, VoidCallback onTap) =>
        Semantics(
          button: true,
          toggled: on,
          label: label,
          child: Tooltip(
            message: label,
            child: InkResponse(
              onTap: onTap,
              radius: 18,
              child: Container(
                width: 30,
                height: 22,
                decoration: BoxDecoration(
                  color: on ? t.control.withValues(alpha: 0.15) : null,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: on ? t.control : t.border,
                    width: 0.8,
                  ),
                ),
                child: Icon(icon, size: 15, color: on ? t.control : t.muted),
              ),
            ),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(
          Icons.touch_app_outlined,
          l.touchReading,
          touchReading,
          onTouchReading,
        ),
        const SizedBox(width: 10),
        button(
          Icons.headphones_outlined,
          l.listenFromPage,
          listening,
          onListen,
        ),
        const SizedBox(width: 10),
        button(Icons.visibility_off_outlined, l.reciteMode, recite, onRecite),
      ],
    );
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
    required this.pageCount,
    required this.label,
    required this.onChanged,
    required this.onChangeEnd,
    required this.onRecite,
    required this.onListen,
    required this.onGoTo,
    required this.onAutoScroll,
  });

  final int page;
  final int pageCount;
  final String label;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;
  final VoidCallback onRecite;
  final VoidCallback onListen;
  final VoidCallback onGoTo;
  final VoidCallback onAutoScroll;

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
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: l.reciteMode,
                    onPressed: onRecite,
                    icon: const Icon(Icons.visibility_outlined),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: l.listen,
                    onPressed: onListen,
                    icon: const Icon(Icons.headphones_outlined),
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: onGoTo,
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: Text(l.goToPage),
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    tooltip: l.autoScroll,
                    onPressed: onAutoScroll,
                    icon: const Icon(Icons.keyboard_double_arrow_down),
                  ),
                ],
              ),
              const SizedBox(height: 6),
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
                    fontFamily: 'KFGQPCAN',
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
                    max: pageCount.toDouble(),
                    divisions: pageCount - 1,
                    value: page.clamp(1, pageCount).toDouble(),
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

/// Shown while the reader drags the selection handles.
class _MultiSelectBar extends StatelessWidget {
  const _MultiSelectBar({required this.count, required this.onDone});

  final int count;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    return Material(
      color: t.paper,
      elevation: 6,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  '${l.multiSelectHint} · ${count == 2 ? l.twoVerses : l.versesCount(digits(count))}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            FilledButton(onPressed: onDone, child: Text(l.doneLabel)),
          ],
        ),
      ),
    );
  }
}

/// Word study: asks for a word to be tapped.
class _WordPickBar extends StatelessWidget {
  const _WordPickBar({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    return Material(
      color: t.paper,
      elevation: 6,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
        child: Row(
          children: [
            Icon(Icons.touch_app_outlined, color: t.goldText),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l.wordPickHint,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            TextButton(onPressed: onCancel, child: Text(l.cancel)),
          ],
        ),
      ),
    );
  }
}

/// Hifz test toolbar.
class _TestBar extends StatelessWidget {
  const _TestBar({
    required this.verse,
    required this.result,
    required this.byLine,
    required this.counts,
    required this.similar,
    required this.onSimilar,
    required this.onNextWord,
    required this.onNextVerse,
    required this.onAll,
    required this.onRemembered,
    required this.onMissed,
    required this.onGrade,
    required this.onClose,
  });

  /// The verse being recited, named; null before the first reveal.
  final String? verse;
  final VerseResult? result;

  /// The current verse is revealed line by line (no word boxes).
  final bool byLine;
  final String? counts;

  /// Passages similar to the current verse.
  final int similar;
  final VoidCallback? onSimilar;
  final VoidCallback onNextWord;
  final VoidCallback onNextVerse;
  final VoidCallback onAll;
  final VoidCallback? onRemembered;
  final VoidCallback? onMissed;
  final VoidCallback onGrade;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    return Material(
      color: t.paper,
      elevation: 6,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (verse != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            verse!,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (counts != null)
                            Text(
                              counts!,
                              style: TextStyle(fontSize: 12, color: t.muted),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (similar > 0)
                    TextButton.icon(
                      onPressed: onSimilar,
                      icon: const Icon(Icons.compare_arrows, size: 18),
                      label: Text(l.similarCount(digits(similar))),
                    ),
                ],
              ),
              if (byLine)
                Text(
                  l.revealByLine,
                  style: TextStyle(fontSize: 12, color: t.muted),
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _JudgeButton(
                      label: l.verseRemembered,
                      icon: Icons.check,
                      chosen: result == VerseResult.remembered,
                      onPressed: onRemembered,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _JudgeButton(
                      label: l.verseMissed,
                      icon: Icons.close,
                      chosen: result == VerseResult.missed,
                      onPressed: onMissed,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onNextWord,
                    child: Text(l.revealNextWord),
                  ),
                ),
                IconButton(
                  tooltip: l.revealNextVerse,
                  onPressed: onNextVerse,
                  icon: const Icon(Icons.keyboard_double_arrow_left),
                ),
                IconButton(
                  tooltip: l.revealAll,
                  onPressed: onAll,
                  icon: const Icon(Icons.visibility_outlined),
                ),
                IconButton(
                  tooltip: l.gradeUnit,
                  onPressed: onGrade,
                  icon: const Icon(Icons.grading),
                ),
                IconButton(
                  tooltip: l.endRecite,
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// «حفظت» or «أخطأت» for the current verse; filled once chosen.
class _JudgeButton extends StatelessWidget {
  const _JudgeButton({
    required this.label,
    required this.icon,
    required this.chosen,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool chosen;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: chosen,
    child: chosen
        ? FilledButton.tonalIcon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
          ),
  );
}

/// Auto-scroll toolbar.
class _AutoScrollBar extends StatelessWidget {
  const _AutoScrollBar({
    required this.paused,
    required this.speed,
    required this.onPause,
    required this.onSlower,
    required this.onFaster,
    required this.onClose,
  });

  final bool paused;
  final int speed;
  final VoidCallback onPause;
  final VoidCallback onSlower;
  final VoidCallback onFaster;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    return Material(
      color: t.paper,
      elevation: 6,
      borderRadius: BorderRadius.circular(32),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            IconButton.filled(
              tooltip: paused ? l.resume : l.pause,
              onPressed: onPause,
              icon: Icon(paused ? Icons.play_arrow : Icons.pause),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l.speedLabel(digits(speed)),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: l.slower,
              onPressed: onSlower,
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 4),
            IconButton.filledTonal(
              tooltip: l.faster,
              onPressed: onFaster,
              icon: const Icon(Icons.add),
            ),
            IconButton(
              tooltip: l.stopAutoScroll,
              onPressed: onClose,
              icon: const Icon(Icons.close),
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
