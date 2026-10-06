import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/db/content_database.dart';
import '../../../core/db/user_database.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../books/books_providers.dart';
import '../../books/presentation/asbab_section.dart';
import '../../books/presentation/book_section.dart';
import '../../content_extras/verse_audio_index.dart';
import '../../audio/player_bar.dart';
import '../../audio/recitation.dart';
import '../../hifz/data/hifz_repository.dart';
import '../../hifz/domain/recitation_test.dart';
import '../../hifz/domain/strength.dart';
import '../../hifz/hifz_providers.dart';
import '../../hifz/presentation/hifz_sheets.dart';
import '../../hifz/presentation/similar_sheet.dart';
import '../../word_study/data/word_study_repository.dart';
import '../../word_study/word_pick.dart';
import '../../word_study/word_study_providers.dart';
import '../../word_study/word_study_sheet.dart';
import '../../khatma/domain/reading_tracker.dart';
import '../../khatma/khatma_providers.dart';
import '../../khatma/presentation/journal_screen.dart';
import '../data/mushaf_repository.dart';
import '../data/tajweed.dart';
import '../data/riwaya_data.dart';
import '../data/verse_image.dart';
import '../data/verse_share.dart';
import '../../reading/under_verse.dart';
import '../mushaf_providers.dart';
import 'download_screen.dart';
import 'page_spreads.dart';
import 'widgets/art_frame.dart';
import 'widgets/fasil_sheet.dart';
import 'widgets/go_to_page.dart';
import 'widgets/illuminated_frame.dart';
import 'widgets/mushaf_page.dart';
import 'widgets/ornate_pages.dart';
import 'widgets/old_mushaf_page.dart';
import 'widgets/page_interaction.dart';
import 'widgets/shamarly_page.dart';
import 'widgets/tajweed_legend.dart';
import 'widgets/verse_services.dart';

part 'mushaf_screen_controls.dart';
part 'mushaf_screen_hifz.dart';
part 'mushaf_screen_panes.dart';

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
    this.listen = false,
  });

  /// Start the recitation from the first verse of the opening page (the
  /// home screen widget's «استماع» button).
  final bool listen;

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

  /// The pages of the selection's two ends: a stretch of verses may run
  /// over page breaks (turn the page while selecting, tap a verse to extend).
  int _pageA = 1;
  int _pageB = 1;

  /// A picture of a selection over several pages turns the pages itself:
  /// the selection must survive that.
  bool _stacking = false;

  /// Most pages one selection may cover.
  static const _maxSelectionPages = 6;

  /// Two pages side by side, like an open mushaf (a wide screen held
  /// sideways); [_controller]'s index is then a spread, not a page.
  bool _spread = false;

  /// Each page is drawn inside its own boundary, so a picture of the
  /// selected verses can be cut from the page being read (one key per page:
  /// a key moving between pages would clash while pages turn).
  final Map<int, GlobalKey> _captureKeys = {};

  /// True while the page is drawn without its selection, for that picture.
  bool _capturing = false;

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
    // Positions and verses from elsewhere in the app are in Hafs numbers; a
    // riwaya edition shows the riwaya verse that holds them.
    final riwaya = await ref.read(riwayaDataProvider.future);
    if (riwaya != null &&
        widget.selectSurah != null &&
        widget.selectAyah != null &&
        mounted) {
      final k = editionKeyOf(riwaya, widget.selectSurah!, widget.selectAyah!);
      setState(() => _selA = _selB = k);
    }
    var page = widget.initialPage;
    if (page == null && saved != null) {
      page = saved.edition == edition.name
          ? saved.page
          : await ref.read(versePageProvider((saved.surah, saved.ayah)).future);
    }
    final start = (page ?? 1).clamp(_first, edition.pageCount);
    if (!mounted) return;
    setState(() {
      _page = start;
      if (_selA != null) _pageA = _pageB = start;
      _controller = PageController(initialPage: _indexOf(start));
    });
    _trackPage();
    if (widget.listen) {
      // After the page's verses are loaded.
      await ref.read(pageAyahsProvider(_page).future);
      if (mounted) _listenFromPage();
    }
  }

  void _trackPage() {
    if (_page >= 1) {
      final shown = _pagesAt(_indexOf(_page));
      _tracker.show(
        _page,
        ref.read(editionProvider).name,
        also: shown.length > 1 ? shown.last : null,
      );
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

  /// The pager turned to [index] (a page, or a spread).
  Future<void> _onPageChanged(int index) => _showPage(_pagesAt(index).first);

  Future<void> _showPage(int page) async {
    setState(() {
      _page = page;
      // Turning the page while selecting keeps the selection, so it can be
      // extended onto the next page.
      if (!_multi && !_stacking) _selA = _selB = null;
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
    // Kept in Hafs numbers, so any edition can reopen at the same verse.
    final hafs = hafsKeyOf(await ref.read(riwayaDataProvider.future), (
      surah: ayahs.first.surah,
      ayah: ayahs.first.number,
    ));
    // Screen readers hear where the turn landed: the surah and the page.
    if (mounted && MediaQuery.accessibleNavigationOf(context)) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        _scrubLabel(context, _page, ref.read(surahsProvider).value),
        Directionality.of(context),
      );
    }
    await ref
        .read(userDatabaseProvider)
        .savePosition(
          edition: ref.read(editionProvider).name,
          view: 'page',
          surah: hafs.surah,
          ayah: hafs.ayah,
          page: _page,
        );
  }

  /// The riwaya data of the edition being read, once loaded; null in the
  /// Hafs editions.
  RiwayaData? get _riwaya => ref.read(riwayaDataProvider).value;

  /// The first page that opens a spread: pages 1 and 2 (the opening
  /// pages) face each other in the Madina editions, 2 and 3 in the
  /// Shamarly; the pages before it (the covers) stand alone.
  int get _spreadBase =>
      ref.read(editionProvider) == MushafEdition.shamarly ? 2 : 1;

  PageSpreads get _spreads => PageSpreads(
    first: _first,
    base: _spreadBase,
    pageCount: ref.read(editionProvider).pageCount,
    spread: _spread,
  );

  /// The pager's index of [page].
  int _indexOf(int page) => _spreads.indexOf(page);

  /// The pages shown at the pager's [index], right to left.
  List<int> _pagesAt(int index) => _spreads.pagesAt(index);

  /// Whether [page] is on screen now (in a spread, either page).
  bool _onScreen(int page) => _pagesAt(_indexOf(_page)).contains(page);

  /// Switches between single pages and spreads, keeping the page.
  void _setSpread(bool on) {
    if (on == _spread || !mounted) return;
    final page = _page;
    final old = _controller;
    setState(() {
      _spread = on;
      _controller = PageController(initialPage: _indexOf(page));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
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

    // Bookmarks are kept in Hafs numbers; a riwaya page shows each on the
    // riwaya verse that holds it.
    final riwaya = ref.watch(riwayaDataProvider).value;
    final marks = <VerseKey, Color>{
      for (final m
          in ref.watch(bookmarkSetsProvider).value ?? const <BookmarkSetRow>[])
        editionKeyOf(riwaya, m.surah, m.ayah): Color(m.color),
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
            artTint: t.artTint,
          );

    Widget pageOf(int pg) {
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
        selection: _capturing
            ? const {}
            : _selA != null
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
            _pageA = _pageB = pg;
            _pickWord = false;
          });
        },
        onMarkerTap: (v) => _toggleMark(v, pg),
        // Selecting several verses: a tap on a verse (on this page or a later
        // or earlier one) extends the selection to it.
        onVerseTap: _multi
            ? (v) => _extendTo(v, pg)
            : _touchReading
            ? (v) => setState(() => _touched = v)
            : null,
        touched: _touchReading ? _touched : null,
        touchColor: _touchReading
            ? (context.tokens.mode.isLight
                  ? const Color(0x33D0453B)
                  : const Color(0x40FF8A80))
            : null,
        onHandleDrag: (start, v) => setState(() {
          if (start) {
            _selA = v;
            _pageA = pg;
          } else {
            _selB = v;
            _pageB = pg;
          }
        }),
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
        showHandles: _multi && !_capturing,
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
        // Screen readers: each verse by its surah and number, then its
        // text as stored (Tanzil's plain text, which reads aloud well).
        verseLabel: (v) => l.verseLabel(
          surahs == null ? '' : surahName(context, surahs[v.surah - 1]),
          NumberFormatter(Localizations.localeOf(context))(v.ayah),
        ),
        verseText: (v) => ref
            .read(pageAyahsProvider(pg))
            .value
            ?.where((a) => a.surah == v.surah && a.number == v.ayah)
            .firstOrNull
            ?.textSearch,
        tajweedColor: settings.tajweedColors
            ? (rule) => tajweedHueOf(
                rule,
                settings.tajweedHues,
              )?.on(darkPaper: !context.tokens.mode.isLight)
            : null,
        tajweed: settings.tajweedColors
            ? ref.watch(tajweedPageProvider(pg)).value ?? ''
            : '',
      );
      // Elderly mode: no small icon-only tools on the page; the same tools
      // are labelled buttons in the bottom bar.
      final tools = context.tokens.elderly
          ? null
          : _ReadingTools(
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
              tajweed: editionHasTajweed(edition)
                  ? settings.tajweedColors
                  : null,
              onTajweed: () => ref
                  .read(settingsProvider.notifier)
                  .setTajweedColors(!settings.tajweedColors),
              onTajweedLegend: () => showTajweedLegend(context),
            );
      final pageBody = switch (edition) {
        MushafEdition.madina1405 => OldMushafPage(
          page: pg,
          interaction: interaction,
        ),
        MushafEdition.shamarly => ShamarlyMushafPage(
          page: pg,
          interaction: interaction,
        ),
        // The new Madina edition and the riwaya editions: KFGQPC's SVG
        // page artwork. Keyed by edition so a switch loads the other pages.
        _ => MushafPage(
          key: ValueKey('${edition.name}/$pg'),
          page: pg,
          interaction: interaction,
        ),
      };
      final pageWidget = RepaintBoundary(
        key: _captureKeys.putIfAbsent(pg, GlobalKey.new),
        child: pageBody,
      );
      final info = ref.watch(frameInfoProvider(pg)).value;
      void openIndex(String tab) {
        final a = ref.read(pageAyahsProvider(pg)).value?.firstOrNull;
        context.push(
          '/mushaf/index?tab=$tab&p=$pg'
          '${a == null ? '' : '&s=${a.surah}'}'
          '${info == null ? '' : '&j=${info.juz}'}'
          '${info?.hizb == null ? '' : '&h=${info!.hizb}'}',
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

    Widget pageAt(int i) => pageOf(i + _first);

    final scrubbing = _scrubPage ?? _page;
    final range = _range();
    return _keyboard(
      Scaffold(
        backgroundColor: t.bg,
        body: Stack(
          children: [
            // The frame and the space above and below the page open the
            // menus too; a tap on the page itself or on a frame label is
            // taken by that (deeper) widget first.
            // Wide screens may show the chosen texts beside the page.
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
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
                                  initialScrollOffset:
                                      (_page - _first) * box.maxHeight,
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
                          ? Center(
                              child: CircularProgressIndicator(
                                semanticsLabel: l.loadingLabel,
                              ),
                            )
                          // The mushaf opens from the right in every interface language.
                          : Directionality(
                              textDirection: TextDirection.rtl,
                              child: LayoutBuilder(
                                builder: (context, box) {
                                  // A wide screen held sideways shows two
                                  // pages; not in a hifz test, which is one
                                  // page at a time.
                                  final spread =
                                      settings.twoPageSpread &&
                                      !_testing &&
                                      box.maxWidth > box.maxHeight &&
                                      box.maxWidth >= 800;
                                  if (spread != _spread) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback(
                                          (_) => _setSpread(spread),
                                        );
                                  }
                                  // A mouse and a trackpad drag the pages
                                  // like a finger; the wheel turns them.
                                  return Listener(
                                    onPointerSignal: _onWheel,
                                    child: ScrollConfiguration(
                                      behavior: ScrollConfiguration.of(context)
                                          .copyWith(
                                            dragDevices: PointerDeviceKind
                                                .values
                                                .toSet(),
                                          ),
                                      child: PageView.builder(
                                        controller: _controller,
                                        itemCount: _spreads.count,
                                        // The pages either side are built and their images
                                        // decoded before they are turned to, so a page turn
                                        // does not stop on a spinner.
                                        allowImplicitScrolling: true,
                                        onPageChanged: _onPageChanged,
                                        itemBuilder: (context, i) {
                                          final pages = _pagesAt(i);
                                          if (pages.length == 1) {
                                            return pageOf(pages.single);
                                          }
                                          // Right page first: the mushaf opens
                                          // from the right.
                                          return Row(
                                            textDirection: TextDirection.rtl,
                                            children: [
                                              for (final pg in pages)
                                                Expanded(child: pageOf(pg)),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                ),
                if (settings.splitTranslation &&
                    settings.underVerse.isNotEmpty &&
                    !_autoScroll &&
                    MediaQuery.sizeOf(context).width >= 900)
                  _SidePane(page: _page, riwaya: _riwaya),
              ],
            ),
            if (_chrome) ...[
              // A light veil so the controls read as a layer over the page.
              Positioned.fill(
                child: Semantics(
                  button: true,
                  label: l.hideMenus,
                  onTap: () => _setChrome(false),
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => _setChrome(false),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.28),
                    ),
                  ),
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
                    _controller?.jumpToPage(_indexOf(p));
                  },
                  onRecite: _startRecite,
                  onListen: _listenFromPage,
                  onGoTo: _goToPage,
                  onAutoScroll: _startAutoScroll,
                  onContinuous: _openContinuous,
                  onOneVerse: _openOneVerse,
                  touchReading: _touchReading,
                  onTouchReading: _toggleTouchReading,
                  recite: _recite,
                  listening: recitation.active,
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
                  onMark: (kind) =>
                      _setMark(kind, range.first, _rangeFirstPage(range)),
                  onSaveToFasil: () => showSaveToFasil(
                    context,
                    ref,
                    verse: hafsKeyOf(_riwaya, range.first),
                    page: _rangeFirstPage(range),
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
                  // Tafsir and translation are keyed by Hafs numbers; from a
                  // riwaya the screen also names the verse as read there.
                  onTafsir: () {
                    final v = range.first;
                    final h = hafsKeyOf(_riwaya, v);
                    final r = ref.read(editionProvider).riwaya;
                    context.push(
                      '/mushaf/tafsir?s=${h.surah}&a=${h.ayah}'
                      '${r == Riwaya.hafs ? '' : '&r=${r.name}&ra=${v.ayah}'}',
                    );
                  },
                  // Word study reads the Hafs text's words: on a riwaya's
                  // pages it needs the pack's word boxes, and opens only
                  // for a word that is exactly a Hafs word (_pickAt).
                  onWordStudy:
                      edition.isRiwaya && !(_riwaya?.hasWordBoxes ?? false)
                      ? null
                      : () {
                          _setChrome(false);
                          setState(() {
                            _selA = _selB = null;
                            _pickWord = true;
                          });
                        },
                  // Meanings and reflections are kept by Hafs verse: a riwaya
                  // verse opens those of the Hafs verses it covers.
                  onWordMeanings: () => showVerseMeanings(
                    context,
                    verses: [
                      for (final v in range)
                        ...?_riwaya?.toHafs(v.surah, v.ayah),
                      if (_riwaya == null)
                        for (final v in range) (surah: v.surah, ayah: v.ayah),
                    ],
                  ),
                  similarCount: range.length == 1
                      ? ref
                                .watch(
                                  similarCountProvider((
                                    hafsKeyOf(_riwaya, range.first).surah,
                                    hafsKeyOf(_riwaya, range.first).ayah,
                                  )),
                                )
                                .value ??
                            0
                      : 0,
                  onSimilar: () {
                    final h = hafsKeyOf(_riwaya, range.first);
                    showSimilarSheet(context, surah: h.surah, ayah: h.ayah);
                  },
                  // Occasions of revelation are kept by Hafs verse.
                  asbabCount: range.length == 1
                      ? ref
                            .watch(
                              asbabProvider((
                                surah: hafsKeyOf(_riwaya, range.first).surah,
                                ayah: hafsKeyOf(_riwaya, range.first).ayah,
                              )),
                            )
                            .length
                      : 0,
                  onAsbab: () {
                    final h = hafsKeyOf(_riwaya, range.first);
                    showAsbabSheet(context, surah: h.surah, ayah: h.ayah);
                  },
                  // A tafsir read aloud, by Hafs verse (flag tafsir_audio).
                  onTafsirAudio: range.length != 1
                      ? null
                      : switch (ref
                            .watch(
                              tafsirAudioForVerseProvider((
                                surah: hafsKeyOf(_riwaya, range.first).surah,
                                ayah: hafsKeyOf(_riwaya, range.first).ayah,
                              )),
                            )
                            .value
                            ?.firstOrNull) {
                          (final index, _) => () {
                            final h = hafsKeyOf(_riwaya, range.first);
                            setState(() => _selA = _selB = null);
                            ref
                                .read(recitationProvider.notifier)
                                .playTafsir(index, h.surah, h.ayah);
                          },
                          null => null,
                        },
                  munasabatCount: range.length == 1
                      ? ref
                            .watch(
                              munasabatProvider((
                                surah: hafsKeyOf(_riwaya, range.first).surah,
                                ayah: hafsKeyOf(_riwaya, range.first).ayah,
                              )),
                            )
                            .length
                      : 0,
                  onMunasabat: () {
                    final h = hafsKeyOf(_riwaya, range.first);
                    showBookSheet(
                      context,
                      spec: BookSectionSpec.munasabat,
                      surah: h.surah,
                      ayah: h.ayah,
                    );
                  },
                  onReflect: () {
                    final h = hafsKeyOf(_riwaya, range.first);
                    showReflectionSheet(context, surah: h.surah, ayah: h.ayah);
                  },
                  // The text is Tanzil's, which is the Hafs text: a riwaya
                  // edition shares only the picture of its page.
                  onCopy: edition.isRiwaya ? null : () => _copyVerses(range),
                  onShareText: edition.isRiwaya
                      ? null
                      : () => _shareVerseText(range),
                  onShareImage: () => _shareVerseImage(range),
                  preview: settings.underVerse.isEmpty
                      ? null
                      : UnderVerseTexts(
                          surah: hafsKeyOf(_riwaya, range.first).surah,
                          ayah: hafsKeyOf(_riwaya, range.first).ayah,
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Keys for a keyboard (desktop, or a tablet's): the arrows and page
  /// keys turn the page (the mushaf opens from the right, so left is
  /// forward), space starts and pauses the recitation, G goes to a page,
  /// / or Ctrl/Cmd+F searches, Escape clears the selection or the menus.
  /// Turns [by] pages (positive is forward: to the left).
  void _turn(int by) {
    final c = _controller;
    if (c == null || _autoScroll) return;
    c.animateToPage(
      (c.page?.round() ?? 0) + by,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// When the mouse wheel last turned a page: one notch, one page.
  DateTime _lastWheelTurn = DateTime(0);

  /// The mouse wheel turns the page: down or right is forward. A trackpad
  /// swipe comes as a drag instead (see the page view's scroll behaviour).
  void _onWheel(PointerSignalEvent e) {
    if (e is! PointerScrollEvent || e.kind == PointerDeviceKind.trackpad) {
      return;
    }
    final now = DateTime.now();
    if (now.difference(_lastWheelTurn) < const Duration(milliseconds: 350)) {
      return;
    }
    final d = e.scrollDelta.dy.abs() >= e.scrollDelta.dx.abs()
        ? e.scrollDelta.dy
        : -e.scrollDelta.dx;
    if (d.abs() < 1) return;
    _lastWheelTurn = now;
    _turn(d > 0 ? 1 : -1);
  }

  Widget _keyboard(Widget child) {
    void turn(int by) => _turn(by);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => turn(1),
        const SingleActivator(LogicalKeyboardKey.pageDown): () => turn(1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => turn(-1),
        const SingleActivator(LogicalKeyboardKey.pageUp): () => turn(-1),
        const SingleActivator(LogicalKeyboardKey.space): () {
          final r = ref.read(recitationProvider);
          r.active
              ? unawaited(ref.read(recitationProvider.notifier).toggle())
              : _listenFromPage();
        },
        const SingleActivator(LogicalKeyboardKey.keyG): _goToPage,
        const SingleActivator(LogicalKeyboardKey.slash): () =>
            context.push('/search'),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
            context.push('/search'),
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () =>
            context.push('/search'),
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_selA != null || _multi) {
            setState(() {
              _selA = _selB = null;
              _multi = false;
            });
          } else {
            _setChrome(!_chrome);
          }
        },
      },
      child: Focus(autofocus: true, child: child),
    );
  }

  /// Extends the selection to [v] on [page] (selecting several verses).
  void _extendTo(VerseKey v, int page) {
    if ((page - _pageA).abs() >= _maxSelectionPages) return;
    setState(() {
      _selB = v;
      _pageB = page;
    });
  }

  int get _firstSelPage => _pageA < _pageB ? _pageA : _pageB;
  int get _lastSelPage => _pageA < _pageB ? _pageB : _pageA;

  /// The verses between the two selection ends, in order, over the pages
  /// they lie on.
  List<VerseKey>? _range() {
    if (_selA == null || _selB == null) return null;
    final keys = <VerseKey>[];
    for (var p = _firstSelPage; p <= _lastSelPage; p++) {
      final ayahs = ref.watch(pageAyahsProvider(p)).value;
      if (ayahs == null) return [_selA!];
      keys.addAll([for (final a in ayahs) (surah: a.surah, ayah: a.number)]);
    }
    final ia = keys.indexOf(_selA!);
    final ib = keys.indexOf(_selB!);
    if (ia < 0 || ib < 0) return [_selA!];
    return keys.sublist(ia < ib ? ia : ib, (ia < ib ? ib : ia) + 1);
  }

  /// The page the selection's first verse is on.
  int _rangeFirstPage(List<VerseKey> range) {
    for (var p = _firstSelPage; p <= _lastSelPage; p++) {
      final ayahs = ref.read(pageAyahsProvider(p)).value ?? const [];
      if (ayahs.any(
        (a) => a.surah == range.first.surah && a.number == range.first.ayah,
      )) {
        return p;
      }
    }
    return _page;
  }

  Set<VerseKey> _selectionOn(int page) => {...?_range()};

  /// Word study: the word under [point] (edition units) on [page]. A verse
  /// without word boxes there opens with its words to choose from; a tap
  /// outside any verse keeps waiting for a word. On a riwaya's pages only
  /// a word is taken ([_pickRiwayaWord]): the verse's words to choose
  /// from would be Hafs's.
  void _pickAt(int page, Offset point, VerseKey? verse) {
    final boxes = ref.read(pageWordBoxesProvider(page)).value ?? const {};
    final edition = ref.read(editionProvider);
    // Page units in the SVG editions, image pixels in the others.
    final slop = edition == MushafEdition.madina1441 || edition.isRiwaya
        ? 2.0
        : 6.0;
    final hit =
        wordUnder(boxes, point, verse: verse, slop: slop) ??
        wordUnder(boxes, point, slop: slop);
    final riwaya = _riwaya;
    if (edition.isRiwaya && riwaya != null) {
      if (hit != null) unawaited(_pickRiwayaWord(riwaya, hit));
      return;
    }
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

  /// Word study from a riwaya's page: the word picked is studied as the
  /// Hafs word it is when that is certain ([RiwayaData.hafsWord]: the
  /// same verse, word and letters); any other word says why it has none.
  Future<void> _pickRiwayaWord(RiwayaData riwaya, (int, int, int) hit) async {
    final (surah, ayah, word) = hit;
    HapticFeedback.selectionClick();
    setState(() => _pickWord = false);
    final hafs = riwaya.toHafs(surah, ayah);
    (int, int, int)? target;
    if (hafs.length == 1) {
      final row = await ref.read(
        verseRowProvider((surah: hafs.first.surah, ayah: hafs.first.ayah))
            .future,
      );
      target = riwaya.hafsWord(surah, ayah, word, verseWords(row));
    }
    if (!mounted) return;
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).riwayaWordNoStudy)),
      );
      return;
    }
    showWordStudy(context, surah: target.$1, ayah: target.$2, word: target.$3);
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
    if (edition.isRiwaya) {
      // A riwaya's recitations are numbered by the riwaya, like its pages.
      final page = _riwaya?.pageOf(v.surah, v.ayah);
      if (!mounted || page == null || _onScreen(page)) return;
      _controller?.animateToPage(
        _indexOf(page),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      return;
    }
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
    if (!mounted || _onScreen(page)) return;
    _controller?.animateToPage(
      _indexOf(page),
      // Elderly mode: a slower turn that is easy to follow.
      duration: Duration(milliseconds: context.tokens.elderly ? 700 : 350),
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
    // Marks are kept in Hafs numbers; the message names the verse as read.
    final hafs = hafsKeyOf(_riwaya, v);
    await ref
        .read(userDatabaseProvider)
        .setMark(
          kind,
          name: name,
          surah: hafs.surah,
          ayah: hafs.ayah,
          page: page,
        );
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
    if (page != _page) _showPage(page);
  }

  void _stopAutoScroll() {
    _ticker?.stop();
    final page = _page;
    setState(() {
      _autoScroll = false;
      _controller?.dispose();
      _controller = PageController(initialPage: _indexOf(page));
    });
  }

  /// Tapping a verse marker sets the reading mark there, or removes the
  /// marks already on that verse.
  Future<void> _toggleMark(VerseKey v, int page) async {
    final db = ref.read(userDatabaseProvider);
    final riwaya = _riwaya;
    final here = [
      for (final m
          in ref.read(bookmarkSetsProvider).value ?? const <BookmarkSetRow>[])
        if (editionKeyOf(riwaya, m.surah, m.ayah) == v) m,
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

  /// The selected verses as Tanzil's rows (Hafs editions).
  String _verseText(List<VerseKey> range) {
    final l = AppLocalizations.of(context);
    final surahs = ref.read(surahsProvider).value;
    final ayahs = [
      for (var p = _firstSelPage; p <= _lastSelPage; p++)
        ...?ref.read(pageAyahsProvider(p)).value,
    ];
    return composeVerseText(
      verses: [
        for (final k in range)
          ...ayahs.where((a) => a.surah == k.surah && a.number == k.ayah),
      ],
      surahLabel: (s) =>
          l.surahWord(surahs == null ? '' : surahName(context, surahs[s - 1])),
      digits: NumberFormatter(Localizations.localeOf(context)).call,
      range: (s, a, b) => l.verseRange(s, a, b),
    );
  }

  Future<void> _copyVerses(List<VerseKey> range) async {
    final text = _verseText(range);
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    messenger.showSnackBar(SnackBar(content: Text(l.copied)));
  }

  Rect? _shareOrigin() {
    final box = context.findRenderObject();
    return box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
  }

  Future<void> _shareVerseText(List<VerseKey> range) async {
    final origin = _shareOrigin();
    await SharePlus.instance.share(
      ShareParams(text: _verseText(range), sharePositionOrigin: origin),
    );
  }

  /// A picture of the selected verses cut from the page as it is drawn
  /// (its theme, ink and paper), without a frame or caption. A stretch over
  /// a page break turns the pages and joins the pieces in one picture.
  Future<void> _shareVerseImage(List<VerseKey> range) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final paper = context.tokens.colors.paper;
    final origin = _shareOrigin();
    final from = _firstSelPage;
    final to = _lastSelPage;
    final startPage = _page;
    messenger.showSnackBar(SnackBar(content: Text(l.sharePreparing)));

    final pieces = <ui.Image>[];
    _stacking = true;
    try {
      for (var p = from; p <= to; p++) {
        if (!_onScreen(p)) {
          _controller?.jumpToPage(_indexOf(p));
          // The page builds, and its verses load.
          for (var i = 0; i < 20 && (!_onScreen(p) || !mounted); i++) {
            await SchedulerBinding.instance.endOfFrame;
          }
          if (!mounted) return;
          await ref.read(pageAyahsProvider(p).future);
          await SchedulerBinding.instance.endOfFrame;
          await SchedulerBinding.instance.endOfFrame;
        }
        final piece = await captureSelectionPicture(
          key: _captureKeys.putIfAbsent(p, GlobalKey.new),
          paper: paper,
          clean: () async {
            setState(() => _capturing = true);
            await SchedulerBinding.instance.endOfFrame;
          },
          restore: () async {
            if (mounted) setState(() => _capturing = false);
          },
        );
        if (piece != null) pieces.add(piece);
      }
      if (_page != startPage && mounted) {
        _controller?.jumpToPage(_indexOf(startPage));
        await SchedulerBinding.instance.endOfFrame;
      }
    } finally {
      _stacking = false;
    }
    File? file;
    if (pieces.isNotEmpty) {
      final one = pieces.length == 1
          ? pieces.first
          : await stackVertically(pieces, paper);
      file = await savePng(one);
      for (final p in pieces) {
        p.dispose();
      }
      if (!identical(one, pieces.first)) one.dispose();
    }
    messenger.hideCurrentSnackBar();
    if (file == null) {
      messenger.showSnackBar(SnackBar(content: Text(l.shareImageFailed)));
      return;
    }
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], sharePositionOrigin: origin),
    );
  }

  /// «آية آية» at the first verse of this page (Hafs numbers).
  Future<void> _openOneVerse() async {
    final a = ref.read(pageAyahsProvider(_page)).value?.firstOrNull;
    if (a == null) return;
    final h = hafsKeyOf(_riwaya, (surah: a.surah, ayah: a.number));
    _setChrome(false);
    context.go('/verse?s=${h.surah}&a=${h.ayah}');
  }

  /// The continuous view at the first verse of this page (Hafs numbers).
  Future<void> _openContinuous() async {
    final a = ref.read(pageAyahsProvider(_page)).value?.firstOrNull;
    if (a == null) return;
    final h = hafsKeyOf(_riwaya, (surah: a.surah, ayah: a.number));
    _setChrome(false);
    await context.push('/read?s=${h.surah}&a=${h.ayah}');
  }

  Future<void> _goToPage() async {
    final page = await showGoToPage(
      context,
      current: _page,
      max: ref.read(editionProvider).pageCount,
    );
    if (page != null) _controller?.jumpToPage(_indexOf(page));
  }

  String _scrubLabel(BuildContext context, int page, List<SurahRow>? surahs) {
    final first = ref.watch(pageAyahsProvider(page)).value?.firstOrNull;
    final digits = NumberFormatter(Localizations.localeOf(context));
    if (first == null || surahs == null) return digits(page);
    return '${surahName(context, surahs[first.surah - 1])} : ${digits(page)}';
  }
}
