import 'dart:async';

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
import '../../../core/theme/reveal.dart';
import '../../../l10n/app_localizations.dart';
import '../../books/books_providers.dart';
import '../../books/presentation/asbab_section.dart';
import '../../books/presentation/book_section.dart';
import '../../content_extras/verse_audio_index.dart';
import '../../audio/floating_player.dart';
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
import '../../khatma/domain/khatmah.dart' show EntryPoint;
import '../../khatma/domain/reading_tracker.dart';
import '../../../core/router/cover_observer.dart';
import '../../khatma/khatma_providers.dart';
import '../../khatma/presentation/journal_screen.dart';
import '../data/mushaf_repository.dart';
import '../data/tajweed.dart';
import '../data/riwaya_data.dart';
import '../data/verse_share.dart';
import '../../share_image/share_preview_screen.dart';
import '../../reading/under_verse.dart';
import '../../sajdah/sajdah_card.dart';
import '../../sajdah/sajdah_positions.dart';
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
import 'widgets/reading_bar.dart';
import 'widgets/shamarly_page.dart';
import 'widgets/tajweed_legend.dart';
import 'widgets/verse_services.dart';

part 'mushaf_screen_controls.dart';
part 'mushaf_screen_focus.dart';
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
    this.entry = EntryPoint.other,
  });

  /// Where the reading was opened from: from a search, a tafsir or the
  /// hifz, the khatma counts only the pages after the one it landed on.
  final EntryPoint entry;

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

  /// The pager's index the reading bar shows while a page is being turned:
  /// the bar follows [_page] only once the pager settles.
  int? _barHold;

  /// Reading is immersive: no bars until the reader touches the page.
  bool _chrome = false;

  /// Focus mode: the reading tools under the page are shown (the top
  /// bar's tools button); a tap on the page hides them. The reader's
  /// choice is kept ([AppSettings.focusToolsShown]); «القائمة» has no such
  /// tools.
  bool get _focusTools {
    // The build watches the settings, so this follows them.
    final s = ref.read(settingsProvider);
    return s.focusToolsShown && s.focusTools == FocusTools.button;
  }

  void _setFocusTools(bool shown) =>
      ref.read(settingsProvider.notifier).setFocusToolsShown(shown);

  /// The verse the «القائمة» window was opened on, shaded while it is open.
  VerseKey? _menuVerse;

  /// Focus mode is on (see [AppSettings.focusMode]).
  bool get _focus => ref.read(settingsProvider).focusMode;
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

  /// Most pages one selection may cover.
  static const _maxSelectionPages = 6;

  /// Two pages side by side, like an open mushaf (a wide screen held
  /// sideways); [_controller]'s index is then a spread, not a page.
  bool _spread = false;

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

  /// The reader's speed, kept between openings
  /// ([AppSettings.autoScrollSpeed]).
  int get _speed => ref.read(settingsProvider).autoScrollSpeed;
  ScrollController? _vertical;
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  double _pageExtent = 1;

  /// Counts pages read (for the khatma) and the time spent reading (for
  /// the reports).
  late final ReadingTracker _tracker;
  late final AppLifecycleListener _lifecycle;

  /// No sajdah card during a hifz test; read now, as ref is not usable in
  /// dispose.
  late final SajdahMuted _sajdahMuted = ref.read(sajdahMutedProvider.notifier);

  @override
  void initState() {
    super.initState();
    if (_testing) _muteSajdah(true);
    _container; // read now: ref is not usable in dispose
    final service = ref.read(khatmaServiceProvider);
    _tracker = ReadingTracker(
      onPageRead: (r) => unawaited(
        service.pageRead(r, entry: widget.entry).catchError((_) {}),
      ),
      onSessionEnd: (s) => unawaited(
        service.sessionEnded(s, entry: widget.entry).catchError((_) {}),
      ),
      pageWeight: _pageWeight,
      minDwell: Duration(
        seconds: ref.read(settingsProvider).readingSpeed.secondsPerPage,
      ),
    );
    // The weights of the pages, at hand before the first page counts.
    ref.read(quranIndexProvider.future).ignore();
    ref.read(editionPagesProvider(ref.read(editionProvider)).future).ignore();
    _lifecycle = AppLifecycleListener(onHide: _tracker.end, onShow: _trackPage);
    if (widget.selectSurah != null && widget.selectAyah != null) {
      _selA = _selB = (surah: widget.selectSurah!, ayah: widget.selectAyah!);
    }
    _open();
    if (ref.read(settingsProvider).keepScreenOn) WakelockPlus.enable();
    _applySystemBars();
  }

  /// The system's bars show with the menus; focus mode keeps them hidden
  /// (immersive) all the time.
  void _applySystemBars() {
    SystemChrome.setEnabledSystemUIMode(
      _chrome && !_focus
          ? SystemUiMode.edgeToEdge
          : SystemUiMode.immersiveSticky,
    );
  }

  /// A tap on the page, its frame or the space around it: clears the
  /// selection, or shows and hides the menus. In focus mode it only hides
  /// what is shown (the tools, the menus); with nothing shown it does
  /// nothing.
  void _onPageTap() {
    if (_multi) return;
    if (_selA != null) {
      setState(() => _selA = _selB = null);
    } else if (_focus) {
      if (_focusTools) _setFocusTools(false);
      _setChrome(false);
    } else {
      _setChrome(!_chrome);
    }
  }

  /// Focus mode's tools button: shows the reading tools under the page, or
  /// hides them.
  void _toggleFocusTools() {
    _setChrome(false);
    _setFocusTools(!_focusTools);
  }

  /// The small reading tools (touch reading, listening, recitation mode,
  /// tajweed colours), as [r] sees them; [before] runs ahead of each (it
  /// closes focus mode's window).
  _ReadingTools _readingTools(
    WidgetRef r, {
    bool labelled = false,
    VoidCallback? before,
  }) {
    final settings = r.watch(settingsProvider);
    VoidCallback act(VoidCallback f) => () {
      before?.call();
      f();
    };
    return _ReadingTools(
      labelled: labelled,
      touchReading: settings.touchReading,
      onTouchReading: act(_toggleTouchReading),
      listening: r.watch(recitationProvider).active,
      onListen: act(_listenFromPage),
      recite: _recite || _testing,
      onRecite: act(
        () => _testing
            ? _closeTest()
            : _recite
            ? setState(() {
                _recite = false;
                _revealed.clear();
              })
            : _startRecite(),
      ),
      tajweed: editionHasTajweed(r.watch(editionProvider))
          ? settings.tajweedColors
          : null,
      onTajweed: act(
        () => ref
            .read(settingsProvider.notifier)
            .setTajweedColors(!settings.tajweedColors),
      ),
      onTajweedLegend: act(() => showTajweedLegend(context)),
      focus: settings.focusMode,
      onFocus: act(
        () => settings.focusMode
            ? _exitFocus()
            : ref.read(settingsProvider.notifier).setFocusMode(true),
      ),
    );
  }

  /// «القائمة»: the window with every tool, opened by a long press on
  /// [page]: today's top bar (and the exit from focus mode), the services
  /// of the [verse] pressed (none off a verse), the page's tools, and the
  /// reading tools with the page number. A tap outside closes it.
  Future<void> _openFocusMenu(int page, VerseKey? verse) async {
    HapticFeedback.selectionClick();
    _setChrome(false);
    setState(() {
      _selA = _selB = null;
      _menuVerse = verse;
      // The services read the verse's page from here (copy, marks).
      _pageA = _pageB = page;
      _pickWord = false;
    });
    final l = AppLocalizations.of(context);
    final screen = context;
    await showDialog<void>(
      context: context,
      builder: (dialog) {
        void close() => Navigator.of(dialog).pop();
        VoidCallback then(VoidCallback f) => () {
          close();
          f();
        };
        return Consumer(
          builder: (_, r, _) {
            final info = r.watch(frameInfoProvider(page)).value;
            return _FocusMenu(
              header: [
                (
                  Icons.list_alt,
                  l.indexTitle,
                  then(() => screen.push('/mushaf/index')),
                ),
                (Icons.home_outlined, l.homeTitle, then(() => screen.go('/'))),
                (
                  Icons.search_outlined,
                  l.sectionSearch,
                  then(() => screen.push('/search')),
                ),
                (
                  Icons.tune,
                  l.settingsTitle,
                  then(() => screen.push('/settings')),
                ),
                (Icons.fullscreen_exit, l.focusExit, then(_exitFocus)),
              ],
              verse: verse == null
                  ? null
                  : _verseServices(
                      r,
                      [verse],
                      onClose: close,
                      before: close,
                      embedded: true,
                    ),
              pageTools: [
                (Icons.menu_book_outlined, l.goToPage, then(_goToPage)),
                (
                  Icons.bookmarks_outlined,
                  l.fawasilTitle,
                  then(() => screen.push('/mushaf/fawasil')),
                ),
                (
                  Icons.screen_rotation_outlined,
                  l.oneVerse,
                  then(_openOneVerse),
                ),
                (
                  Icons.view_agenda_outlined,
                  l.continuousView,
                  then(_openContinuous),
                ),
                (
                  Icons.keyboard_double_arrow_down,
                  l.autoScroll,
                  then(_startAutoScroll),
                ),
              ],
              bar: info == null
                  ? null
                  : Directionality(
                      textDirection: TextDirection.rtl,
                      child: ReadingBar.of(
                        [info],
                        page: page,
                        showCatchword: !_recite && !_testing,
                      ),
                    ),
              tools: _readingTools(
                r,
                labelled: screen.tokens.elderly,
                before: close,
              ),
              page: page,
              onPage: then(_goToPage),
            );
          },
        );
      },
    );
    if (mounted) setState(() => _menuVerse = null);
  }

  /// Leaves focus mode (its bar's exit button), back to the normal page.
  void _exitFocus() {
    ref.read(settingsProvider.notifier).setFocusMode(false);
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
    // Opened at a verse found elsewhere: the page it landed on is not
    // counted, only what is read on from there.
    if (widget.entry.countsOnlyAfterLanding) _tracker.onlyAfterPage = start;
    setState(() {
      _page = start;
      if (_selA != null) _pageA = _pageB = start;
      _barHold = null;
      _controller = PageController(initialPage: _indexOf(start));
    });
    _trackPage();
    if (widget.listen) {
      // After the page's verses are loaded.
      await ref.read(pageAyahsProvider(_page).future);
      if (mounted) _listenFromPage();
    }
  }

  /// A page's weight in Madina pages (1 until the verse index is loaded):
  /// a page of the Shamarly edition needs more time than a Madina page.
  double _pageWeight(int page, String edition) {
    // Also called from dispose (the page on screen counts then), when ref
    // is no longer usable: the container is.
    final c = _container;
    final index = c.read(quranIndexProvider).value;
    final e = MushafEdition.values.asNameMap()[edition];
    final pages = e == null ? null : c.read(editionPagesProvider(e)).value;
    if (index == null || pages == null) return 1;
    final w = pages.weightOfPage(page, index);
    return w > 0 ? w : 1;
  }

  Route<dynamic>? _route;

  late final ProviderContainer _container = ProviderScope.containerOf(
    context,
    listen: false,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _route) {
      if (_route != null) coverObserver.unsubscribe(_route!);
      _route = route;
      // The tafsir, the index or the continuous view pushed over the page:
      // nothing counts until the page is back on top.
      coverObserver.subscribe(route, _tracker.freeze);
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
    if (_testing) _muteSajdah(false);
    _lifecycle.dispose();
    if (_route != null) coverObserver.unsubscribe(_route!);
    _tracker.end();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _ticker?.dispose();
    _vertical?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  /// A turn starts: the reading bar keeps the page it shows until the
  /// pager comes to rest, then takes the page settled on.
  bool _onPagerScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    if (n is ScrollStartNotification) {
      _barHold ??= _indexOf(_page);
    } else if (n is ScrollEndNotification && _barHold != null) {
      setState(() => _barHold = null);
    }
    return false;
  }

  /// The pager turned to [index] (a page, or a spread).
  Future<void> _onPageChanged(int index) => _showPage(_pagesAt(index).first);

  Future<void> _showPage(int page) async {
    setState(() {
      _page = page;
      // Turning the page while selecting keeps the selection, so it can be
      // extended onto the next page.
      if (!_multi) _selA = _selB = null;
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
      _barHold = null;
      _controller = PageController(initialPage: _indexOf(page));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
  }

  /// Room kept around a page in focus mode, so its ink does not touch the
  /// screen's edges.
  static const _focusPagePadding = EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 4,
  );

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
    // Focus mode turned on or off (here, or in the settings): the system's
    // bars follow.
    ref.listen(settingsProvider.select((s) => s.focusMode), (_, _) {
      _applySystemBars();
    });

    // Bookmarks are kept in Hafs numbers; a riwaya page shows each on the
    // riwaya verse that holds it.
    final riwaya = ref.watch(riwayaDataProvider).value;
    final marks = <VerseKey, Color>{
      for (final m
          in ref.watch(bookmarkSetsProvider).value ?? const <BookmarkSetRow>[])
        editionKeyOf(riwaya, m.surah, m.ayah): Color(m.color),
    };

    final settings = ref.watch(settingsProvider);
    // The khatma counts nothing in a hifz test or recitation mode, and
    // follows the reading speed and the view.
    _tracker
      ..suspend(_recite || _testing)
      ..mode = _autoScroll ? 'scroll' : 'page'
      ..minDwell = Duration(seconds: settings.readingSpeed.secondsPerPage);
    // Focus mode: the page alone, with no frame and nothing under it.
    final focus = settings.focusMode;
    // The current page's verses: recitation mode hides them, and after an
    // edition change they arrive later, so the page must rebuild then.
    ref.watch(pageAyahsProvider(_page));
    final recitation = ref.watch(recitationProvider);
    // The verses of prostration, at hand for touch reading.
    if (settings.sajdahTimer) ref.watch(sajdahPositionsProvider);
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

    // Elderly mode: no small icon-only tools on the page; the same tools
    // are labelled buttons in the bottom bar (in focus mode, in its tools).
    _ReadingTools readingTools({bool labelled = false}) =>
        _readingTools(ref, labelled: labelled);
    final tools = context.tokens.elderly ? null : readingTools();
    // Focus mode's «القائمة»: a long press on the page opens the window
    // with every tool.
    final menu = focus && settings.focusTools == FocusTools.menu;

    Widget pageOf(int pg) {
      if (pg == 0 || (edition == MushafEdition.shamarly && pg == 1)) {
        return CoverPage(onTap: _onPageTap);
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
      final jumps = _tapJumps(recitation);
      final interaction = PageInteraction(
        // The reader's selection, or else the verse being recited.
        selection: _selA != null
            ? _selectionOn(pg)
            : _menuVerse != null
            ? {_menuVerse!}
            : recitation.active && recitation.ayah != null
            ? {(surah: recitation.surah, ayah: recitation.ayah!)}
            : const {},
        marks: marks,
        onTap: _onPageTap,
        onVerseLongPress: (v) {
          if (menu) {
            unawaited(_openFocusMenu(pg, v));
            return;
          }
          HapticFeedback.selectionClick();
          _setChrome(false);
          setState(() {
            _selA = _selB = v;
            _pageA = _pageB = pg;
            _pickWord = false;
          });
        },
        onPageLongPress: menu
            ? () => unawaited(_openFocusMenu(pg, null))
            : null,
        onMarkerTap: (v) => _toggleMark(v, pg),
        // Selecting several verses: a tap on a verse (on this page or a later
        // or earlier one) extends the selection to it. While listening, it
        // moves the recitation there.
        onVerseTap: _multi
            ? (v, _) => _extendTo(v, pg)
            // The verse services are open: a tap on any verse closes them,
            // as a tap anywhere else on the page does.
            : _selA != null
            ? (_, _) => setState(() => _selA = _selB = null)
            : jumps
            ? (v, point) => _listenFrom(v, pg, point)
            : _touchReading
            ? (v, _) => _touch(v)
            : null,
        onListenFrom: jumps ? (v) => _listenFrom(v, pg, null) : null,
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
        fill: focus ? settings.pageFill : null,
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
      final pageWidget = pageBody;
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

      // Focus mode: no frame at all. The opening pages keep their text
      // only (the top bar names the surah), as wide as the screen and
      // centred; the cover stays as it is.
      if (focus) {
        return Padding(padding: _focusPagePadding, child: pageWidget);
      }

      if (openingSurah != null) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
          child: OpeningPage(
            page: pg,
            surah: openingSurah,
            onPageTap: _goToPage,
            onSurahTap: () => openIndex('surahs'),
            onSurahLongPress: () => _shareSurahImage(pg),
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
          onSurahLongPress: () => _shareSurahImage(pg),
          onBannerLongPress: _shareSurah,
          onPageTap: _goToPage,
          linePadding: edition == MushafEdition.shamarly
              ? shamarlyLinePadding
              : null,
          child: pageWidget,
        ),
      );
    }

    Widget pageAt(int i) => pageOf(i + _first);

    bool isCover(int pg) =>
        pg == 0 || (edition == MushafEdition.shamarly && pg == 1);

    /// The strip under the pages, for the page (or spread) the pager has
    /// settled on: it does not change while a page is being turned.
    Widget readingBar() {
      final pages = _pagesAt(_barHold ?? _indexOf(_page));
      final cover = pages.every(isCover);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        // Laid out as the mushaf is: the quarter on the right, the next
        // page's first word on the left.
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ReadingBar.of(
            [
              for (final pg in pages)
                isCover(pg) ? null : ref.watch(frameInfoProvider(pg)).value,
            ],
            key: const ValueKey('reading-bar'),
            page: pages.last,
            // Recitation mode: the next page's first word would give it away.
            showCatchword: !_recite && !_testing,
            coverCatchword: cover
                ? (ref.watch(basmalaProvider).value ?? '')
                      .split(' ')
                      .take(2)
                      .join(' ')
                : null,
            tools: cover ? null : tools,
          ),
        ),
      );
    }

    final scrubbing = _scrubPage ?? _page;
    final range = _range();
    final shownPages = _pagesAt(_barHold ?? _indexOf(_page));
    final playerStyle = settings.effectivePlayerStyle;
    final focusBar = !focus
        ? null
        : _FocusTopBar(
            key: const ValueKey('focus-bar'),
            onIndex: () => context.push('/mushaf/index'),
            onGoTo: _goToPage,
            infos: [
              for (final pg in shownPages)
                isCover(pg) ? null : ref.watch(frameInfoProvider(pg)).value,
            ],
            actions: [
              (Icons.fullscreen_exit, l.focusExit, _exitFocus),
              if (settings.focusTools == FocusTools.button) ...[
                (
                  Icons.handyman_outlined,
                  _focusTools ? l.focusHideTools : l.focusShowTools,
                  _toggleFocusTools,
                ),
                (Icons.menu, l.showMenus, () => _setChrome(true)),
              ],
            ],
          );
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
                    onLongPress: menu
                        ? () => unawaited(_openFocusMenu(_page, null))
                        : null,
                    child: SafeArea(
                      // Focus mode's bar stands in the room above the page.
                      top: !focus,
                      // While listening, the page sits above the player bar so the
                      // catchword and the reading tools stay visible. The
                      // floating players stay over the page instead.
                      minimum: EdgeInsets.only(
                        bottom:
                            recitation.active &&
                                !_autoScroll &&
                                playerStyle == PlayerStyle.normal
                            ? MediaQuery.paddingOf(context).bottom + 80
                            : 0,
                      ),
                      child: Column(
                        children: [
                          ?focusBar,
                          Expanded(
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
                                // The pages turn under one reading bar, which
                                // stays put.
                                : Column(
                                    children: [
                                      Expanded(
                                        child: NotificationListener<ScrollNotification>(
                                          onNotification: _onPagerScroll,
                                          child:
                                              // The mushaf opens from the right in every interface language.
                                              Directionality(
                                                textDirection:
                                                    TextDirection.rtl,
                                                child: LayoutBuilder(
                                                  builder: (context, box) {
                                                    // A wide screen held sideways shows two
                                                    // pages; not in a hifz test, which is one
                                                    // page at a time.
                                                    final spread =
                                                        settings
                                                            .twoPageSpread &&
                                                        !_testing &&
                                                        box.maxWidth >
                                                            box.maxHeight &&
                                                        box.maxWidth >= 800;
                                                    if (spread != _spread) {
                                                      WidgetsBinding.instance
                                                          .addPostFrameCallback(
                                                            (_) => _setSpread(
                                                              spread,
                                                            ),
                                                          );
                                                    }
                                                    // A mouse and a trackpad drag the pages
                                                    // like a finger; the wheel turns them.
                                                    return Listener(
                                                      onPointerSignal: _onWheel,
                                                      child: ScrollConfiguration(
                                                        behavior:
                                                            ScrollConfiguration.of(
                                                              context,
                                                            ).copyWith(
                                                              dragDevices:
                                                                  PointerDeviceKind
                                                                      .values
                                                                      .toSet(),
                                                            ),
                                                        child: PageView.builder(
                                                          // A new controller (spreads turned on or off, another
                                                          // edition) starts a new pager: the old one would keep its
                                                          // place, now another page.
                                                          key: ObjectKey(
                                                            _controller,
                                                          ),
                                                          controller:
                                                              _controller,
                                                          itemCount:
                                                              _spreads.count,
                                                          // The pages either side are built and their images
                                                          // decoded before they are turned to, so a page turn
                                                          // does not stop on a spinner.
                                                          allowImplicitScrolling:
                                                              true,
                                                          onPageChanged:
                                                              _onPageChanged,
                                                          itemBuilder: (context, i) {
                                                            final pages =
                                                                _pagesAt(i);
                                                            if (pages.length ==
                                                                1) {
                                                              return pageOf(
                                                                pages.single,
                                                              );
                                                            }
                                                            // Right page first: the mushaf opens
                                                            // from the right.
                                                            return Row(
                                                              textDirection:
                                                                  TextDirection
                                                                      .rtl,
                                                              children: [
                                                                for (final pg
                                                                    in pages)
                                                                  Expanded(
                                                                    child:
                                                                        pageOf(
                                                                          pg,
                                                                        ),
                                                                  ),
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
                                      if (!_autoScroll && !focus) readingBar(),
                                      // Focus mode's tools, while shown, take
                                      // their own room under the page: the
                                      // page's lines close up above them. At
                                      // once, not animated: the page is drawn
                                      // into an image of its exact size
                                      // (MushafPage's bake), so every frame of
                                      // a size animation drew it all again.
                                      // The menus lie over it rather than
                                      // resizing the page again.
                                      if (!_autoScroll && focus && _focusTools)
                                        _FocusToolsPanel(
                                          key: const ValueKey('focus-tools'),
                                          bar: readingBar(),
                                          labelledTools: context.tokens.elderly
                                              ? readingTools(labelled: true)
                                              : null,
                                        ),
                                    ],
                                  ),
                          ),
                        ],
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
            // The menus come and go with a short fade and slide (at once
            // when less motion is asked for).
            // A light veil so the controls read as a layer over the page.
            Positioned.fill(
              child: Reveal(
                visible: _chrome,
                from: Offset.zero,
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
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Reveal(
                visible: _chrome,
                from: const Offset(0, -0.25),
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
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Reveal(
                visible: _chrome,
                child: !_chrome
                    ? null
                    : _BottomControls(
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
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Reveal(
                visible: _autoScroll,
                child: SafeArea(
                  top: false,
                  child: _AutoScrollBar(
                    paused: _paused,
                    speed: _speed,
                    onPause: () => setState(() => _paused = !_paused),
                    onSlower: () => ref
                        .read(settingsProvider.notifier)
                        .setAutoScrollSpeed(_speed - 1),
                    onFaster: () => ref
                        .read(settingsProvider.notifier)
                        .setAutoScrollSpeed(_speed + 1),
                    onClose: _stopAutoScroll,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Reveal(
                visible:
                    playerStyle == PlayerStyle.normal &&
                    recitation.active &&
                    range == null &&
                    !_multi &&
                    !_chrome &&
                    !(focus && _focusTools),
                from: const Offset(0, 0.4),
                child: const SafeArea(top: false, child: PlayerBar()),
              ),
            ),
            // «شكل المشغل»: the pill or the single button, over the page
            // wherever the reader left it.
            Positioned.fill(
              child: Reveal(
                visible:
                    playerStyle != PlayerStyle.normal &&
                    recitation.active &&
                    range == null &&
                    !_multi &&
                    !_chrome,
                from: Offset.zero,
                child: playerStyle == PlayerStyle.normal
                    ? null
                    : FloatingPlayer(style: playerStyle),
              ),
            ),
            // The chosen edition is still downloading: say so, and that the
            // new Madina edition is read meanwhile.
            Positioned(
              top: 0,
              left: 24,
              right: 24,
              child: Reveal(
                visible:
                    ref.watch(chosenEditionProvider) != edition && !_chrome,
                from: const Offset(0, -0.25),
                child: const SafeArea(child: DownloadingBanner()),
              ),
            ),
            Positioned(
              top: 0,
              left: 16,
              right: 16,
              child: Reveal(
                visible: _multi,
                from: const Offset(0, -0.25),
                child: SafeArea(
                  child: _MultiSelectBar(
                    count: range?.length ?? 1,
                    onDone: () => setState(() => _multi = false),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Reveal(
                visible: _testing && !_chrome,
                from: const Offset(0, 0.4),
                child: !_testing
                    ? null
                    : SafeArea(top: false, child: _testBar(context, surahs)),
              ),
            ),
            Positioned(
              top: 0,
              left: 16,
              right: 16,
              child: Reveal(
                visible: _pickWord,
                from: const Offset(0, -0.25),
                child: SafeArea(
                  child: _WordPickBar(
                    onCancel: () => setState(() => _pickWord = false),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Reveal(
                visible: range != null && !_multi,
                from: const Offset(0, 0.15),
                child: range == null || _multi
                    ? null
                    : _verseServices(
                        ref,
                        range,
                        onClose: () => setState(() => _selA = _selB = null),
                      ),
              ),
            ),
            const SajdahCardLayer(),
          ],
        ),
      ),
    );
  }

  /// The services of [range] (a verse or a stretch): the panel under the
  /// page, or ([embedded]) the verse part of focus mode's window, which
  /// [before] closes ahead of each service. [r] watches what the panel
  /// shows (the window watches from its own route).
  Widget _verseServices(
    WidgetRef r,
    List<VerseKey> range, {
    required VoidCallback onClose,
    VoidCallback? before,
    bool embedded = false,
  }) {
    final settings = r.watch(settingsProvider);
    final surahs = r.watch(surahsProvider).value;
    final edition = r.watch(editionProvider);
    VoidCallback act(VoidCallback f) => () {
      before?.call();
      f();
    };
    VoidCallback? maybe(VoidCallback? f) => f == null ? null : act(f);
    return VerseServicesPanel(
      verses: range,
      surahs: surahs,
      embedded: embedded,
      onMark: (kind) {
        before?.call();
        _setMark(kind, range.first, _rangeFirstPage(range));
      },
      onSaveToFasil: act(
        () => showSaveToFasil(
          context,
          ref,
          verse: hafsKeyOf(_riwaya, range.first),
          page: _rangeFirstPage(range),
        ),
      ),
      onClose: act(onClose),
      onMultiSelect: act(() {
        _setChrome(false);
        setState(() {
          _selA = range.first;
          _selB = range.last;
          _multi = true;
        });
      }),
      onListen: act(() {
        final one = range.length == 1;
        setState(() => _selA = _selB = null);
        r
            .read(recitationProvider.notifier)
            .play(
              range.first.surah,
              from: range.first.ayah,
              // Several verses: that stretch, repeated as set.
              to: one ? null : range.last.ayah,
            );
      }),
      // Tafsir and translation are keyed by Hafs numbers; from a
      // riwaya the screen also names the verse as read there.
      onTafsir: act(() {
        final v = range.first;
        final h = hafsKeyOf(_riwaya, v);
        final riwaya = edition.riwaya;
        context.push(
          '/mushaf/tafsir?s=${h.surah}&a=${h.ayah}'
          '${riwaya == Riwaya.hafs ? '' : '&r=${riwaya.name}&ra=${v.ayah}'}',
        );
      }),
      // Word study reads the Hafs text's words: on a riwaya's
      // pages it needs the pack's word boxes, and opens only
      // for a word that is exactly a Hafs word (_pickAt).
      onWordStudy: edition.isRiwaya && !(_riwaya?.hasWordBoxes ?? false)
          ? null
          : act(() {
              _setChrome(false);
              setState(() {
                _selA = _selB = null;
                _pickWord = true;
              });
            }),
      // Meanings and reflections are kept by Hafs verse: a riwaya
      // verse opens those of the Hafs verses it covers.
      onWordMeanings: act(
        () => showVerseMeanings(
          context,
          verses: [
            for (final v in range) ...?_riwaya?.toHafs(v.surah, v.ayah),
            if (_riwaya == null)
              for (final v in range) (surah: v.surah, ayah: v.ayah),
          ],
        ),
      ),
      similarCount: range.length == 1
          ? r
                    .watch(
                      similarCountProvider((
                        hafsKeyOf(_riwaya, range.first).surah,
                        hafsKeyOf(_riwaya, range.first).ayah,
                      )),
                    )
                    .value ??
                0
          : 0,
      onSimilar: act(() {
        final h = hafsKeyOf(_riwaya, range.first);
        showSimilarSheet(context, surah: h.surah, ayah: h.ayah);
      }),
      // Occasions of revelation are kept by Hafs verse.
      asbabCount: range.length == 1
          ? r
                .watch(
                  asbabProvider((
                    surah: hafsKeyOf(_riwaya, range.first).surah,
                    ayah: hafsKeyOf(_riwaya, range.first).ayah,
                  )),
                )
                .length
          : 0,
      onAsbab: act(() {
        final h = hafsKeyOf(_riwaya, range.first);
        showAsbabSheet(context, surah: h.surah, ayah: h.ayah);
      }),
      // A tafsir read aloud, by Hafs verse (flag tafsir_audio).
      onTafsirAudio: range.length != 1
          ? null
          : switch (r
                .watch(
                  tafsirAudioForVerseProvider((
                    surah: hafsKeyOf(_riwaya, range.first).surah,
                    ayah: hafsKeyOf(_riwaya, range.first).ayah,
                  )),
                )
                .value
                ?.firstOrNull) {
              (final index, _) => act(() {
                final h = hafsKeyOf(_riwaya, range.first);
                setState(() => _selA = _selB = null);
                r
                    .read(recitationProvider.notifier)
                    .playTafsir(index, h.surah, h.ayah);
              }),
              null => null,
            },
      munasabatCount: range.length == 1
          ? r
                .watch(
                  munasabatProvider((
                    surah: hafsKeyOf(_riwaya, range.first).surah,
                    ayah: hafsKeyOf(_riwaya, range.first).ayah,
                  )),
                )
                .length
          : 0,
      onMunasabat: act(() {
        final h = hafsKeyOf(_riwaya, range.first);
        showBookSheet(
          context,
          spec: BookSectionSpec.munasabat,
          surah: h.surah,
          ayah: h.ayah,
        );
      }),
      onReflect: act(() {
        final h = hafsKeyOf(_riwaya, range.first);
        showReflectionSheet(context, surah: h.surah, ayah: h.ayah);
      }),
      // The text is Tanzil's, which is the Hafs text: a riwaya
      // edition shares only the picture of its page.
      onCopy: edition.isRiwaya ? null : act(() => _copyVerses(range)),
      onShareText: maybe(
        edition.isRiwaya ? null : () => _shareVerseText(range),
      ),
      onShareImage: act(() => _shareVerseImage(range)),
      preview: settings.underVerse.isEmpty
          ? null
          : UnderVerseTexts(
              surah: hafsKeyOf(_riwaya, range.first).surah,
              ayah: hafsKeyOf(_riwaya, range.first).ayah,
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

    // Any touch keeps the reading time going (it stops after 3 minutes
    // without one).
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _tracker.touch(),
      child: CallbackShortcuts(
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
      ),
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
    final slop = _wordSlop;
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

  /// How near a word's box a touch counts as on it: page units in the SVG
  /// editions, image pixels in the others.
  double get _wordSlop {
    final edition = ref.read(editionProvider);
    return edition == MushafEdition.madina1441 || edition.isRiwaya ? 2.0 : 6.0;
  }

  /// Touch reading: shades [v]; when it follows a verse of prostration,
  /// the sajdah card shows (with the timer on, not in a hifz test).
  void _touch(VerseKey v) {
    setState(() => _touched = v);
    if (!ref.read(settingsProvider).sajdahTimer || _testing) return;
    final sajdah = ref
        .read(sajdahPositionsProvider)
        .value
        ?.before(v.surah, v.ayah);
    if (sajdah == null) return;
    // Already up for it: it keeps counting.
    if (ref.read(sajdahCardProvider)?.verse == sajdah) return;
    ref.read(sajdahCardProvider.notifier).show(sajdah, SajdahFrom.reading);
  }

  /// A hifz test mutes the sajdah card (set after the frame: not while
  /// widgets build or unmount).
  void _muteSajdah(bool muted) {
    final notifier = _sajdahMuted;
    Future.microtask(() => notifier.set(muted));
  }

  /// Whether a tap on a verse moves the recitation there: while listening
  /// (playing or paused) in plain reading. Selecting, recitation mode, a
  /// hifz test, word picking and a tafsir played on its own keep their
  /// own taps.
  bool _tapJumps(RecitationState r) =>
      r.active &&
      !(r.clip?.standalone ?? false) &&
      !_multi &&
      _selA == null &&
      !_recite &&
      !_testing &&
      !_pickWord;

  /// While listening, a tap on [v] (at [point] on [page], edition units)
  /// moves the recitation there: to the word tapped when the reader chose
  /// so and the page has that word's box, else to the verse's start. Touch
  /// reading shades the verse too. Verse and word numbers are those of
  /// the page, which a riwaya's recitations share.
  Future<void> _listenFrom(VerseKey v, int page, Offset? point) async {
    if (_touchReading) setState(() => _touched = v);
    int? word;
    if (point != null && ref.read(settingsProvider).tapJumpFromWord) {
      try {
        final boxes = await ref.read(pageWordBoxesProvider(page).future);
        word = wordUnder(boxes, point, verse: v, slop: _wordSlop)?.$3;
      } on Object {
        // No word boxes: from the verse's start.
      }
    }
    final result = await ref
        .read(recitationProvider.notifier)
        .jumpTo(v.surah, v.ayah, word: word);
    if (!mounted) return;
    switch (result) {
      case VerseJump.jumped:
        HapticFeedback.lightImpact();
      case VerseJump.noTiming:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              duration: const Duration(milliseconds: 1800),
              content: Text(AppLocalizations.of(context).tapJumpNoTiming),
            ),
          );
      case VerseJump.ignored:
        break;
    }
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
    _muteSajdah(false);
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
      _barHold = null;
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

  /// The selected verses drawn on Tibyan's picture template, from the
  /// text (the selection marks never show), in the preview.
  Future<void> _shareVerseImage(List<VerseKey> range) =>
      showSharePreview(context, range);

  /// A long press on the surah's name in the frame: the whole surah as
  /// pictures.
  Future<void> _shareSurahImage(int page) async {
    final a = ref.read(pageAyahsProvider(page)).value?.firstOrNull;
    if (a == null) return;
    await _shareSurah(a.surah);
  }

  /// A whole surah as pictures (a long press on its banner in the page).
  Future<void> _shareSurah(int surah) async {
    final count = await ref.read(surahAyahCountProvider(surah).future);
    if (!mounted) return;
    await showSharePreview(context, [
      for (var i = 1; i <= count; i++) (surah: surah, ayah: i),
    ]);
  }

  /// «آية آية» at the first verse of this page (Hafs numbers).
  Future<void> _openOneVerse() async {
    final a = ref.read(pageAyahsProvider(_page)).value?.firstOrNull;
    if (a == null) return;
    final h = hafsKeyOf(_riwaya, (surah: a.surah, ayah: a.number));
    _setChrome(false);
    context.go(
      '/verse?s=${h.surah}&a=${h.ayah}'
      '${widget.entry == EntryPoint.other ? '' : '&entry=${widget.entry.name}'}',
    );
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
