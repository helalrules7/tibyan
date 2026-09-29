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
import '../data/mushaf_repository.dart';
import '../mushaf_providers.dart';
import 'download_screen.dart';
import 'widgets/fasil_sheet.dart';
import 'widgets/go_to_page.dart';
import 'widgets/illuminated_frame.dart';
import 'widgets/mushaf_page.dart';
import 'widgets/ornate_pages.dart';
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

  /// Auto-scroll: pages stacked vertically, moving at [_speed].
  bool _autoScroll = false;
  bool _paused = false;
  int _speed = 3;
  ScrollController? _vertical;
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  double _pageExtent = 1;

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
    final start = (page ?? 1).clamp(_first, mushafPageCount);
    if (!mounted) return;
    setState(() {
      _page = start;
      _controller = PageController(initialPage: start - _first);
    });
  }

  @override
  void dispose() {
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
      _revealed.clear();
    });
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
  int get _first => _illuminated ? 0 : 1;
  bool get _illuminated =>
      ref
          .read(themeRegistryProvider)
          .byId(ref.read(settingsProvider).styleId)
          .frame
          .outerStyle ==
      'illuminated';

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

    final settings = ref.watch(settingsProvider);
    final markerImages = ref.watch(markerImagesProvider).value;
    final markerLook =
        settings.markerStyle == MarkerStyle.traditional &&
            settings.markerTint == null
        ? null
        : MarkerLook(
            style: settings.markerStyle,
            image: markerImages?[settings.markerStyle],
            tint: settings.markerTint == null
                ? null
                : Color(settings.markerTint!),
            paper: t.paper,
            ink: t.ink,
          );

    Widget pageAt(int i) {
      final pg = i + _first;
      if (pg == 0) return CoverPage(onTap: () => _setChrome(!_chrome));
      final interaction = PageInteraction(
        selection: pg == _page ? _selectionOn(pg) : const {},
        marks: marks,
        onTap: () {
          if (_multi) return;
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
        onMarkerTap: (v) => _toggleMark(v, pg),
        onHandleDrag: (start, v) =>
            setState(() => start ? _selA = v : _selB = v),
        markerLook: markerLook,
        hidden: _recite && pg == _page ? _hiddenOn(pg) : null,
        onHiddenTap: (v) => setState(() => _revealed.add(v)),
        ornateOpening: illuminated && pg <= 2,
        showHandles: _multi,
      );
      final pageWidget = oldEdition
          ? OldMushafPage(page: pg, interaction: interaction)
          : MushafPage(page: pg, interaction: interaction);
      if (!illuminated) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: pageWidget,
        );
      }
      final info = ref.watch(frameInfoProvider(pg)).value;
      if (pg <= 2) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
          child: OpeningPage(
            page: pg,
            catchword: info?.catchword,
            onPageTap: _goToPage,
            child: pageWidget,
          ),
        );
      }
      void openIndex(String tab) {
        final a = ref.read(pageAyahsProvider(pg)).value?.firstOrNull;
        context.push(
          '/mushaf/index?tab=$tab&p=$pg'
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
          onQuarterTap: (q) => _setMark(
            MarkKind.reading,
            (surah: q.surah, ayah: q.ayah),
            pg,
            auto: true,
          ),
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
                        itemCount: mushafPageCount + 1 - _first,
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
                      itemCount: mushafPageCount + 1 - _first,
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
                  _controller?.jumpToPage(p - _first);
                },
                onRecite: _startRecite,
                onGoTo: _goToPage,
                onAutoScroll: _startAutoScroll,
              ),
            ),
          ],
          if (_recite)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: _ReciteBar(
                  onNextVerse: _revealNext,
                  onAll: () => setState(() => _revealed.addAll(_pageKeys())),
                  onClose: () => setState(() {
                    _recite = false;
                    _revealed.clear();
                  }),
                ),
              ),
            ),
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

  List<VerseKey> _pageKeys() => [
    for (final a
        in ref.read(pageAyahsProvider(_page)).value ?? const <AyahRow>[])
      (surah: a.surah, ayah: a.number),
  ];

  Set<VerseKey> _hiddenOn(int page) => {
    for (final k in _pageKeys())
      if (!_revealed.contains(k)) k,
  };

  void _startRecite() {
    _setChrome(false);
    setState(() {
      _recite = true;
      _revealed.clear();
      _selA = _selB = null;
      _multi = false;
    });
  }

  void _revealNext() {
    for (final k in _pageKeys()) {
      if (!_revealed.contains(k)) {
        setState(() => _revealed.add(k));
        return;
      }
    }
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
    final page = await showGoToPage(context, current: _page);
    if (page != null) _controller?.jumpToPage(page - _first);
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
    required this.onRecite,
    required this.onGoTo,
    required this.onAutoScroll,
  });

  final int page;
  final String label;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;
  final VoidCallback onRecite;
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

/// Recitation mode toolbar.
class _ReciteBar extends StatelessWidget {
  const _ReciteBar({
    required this.onNextVerse,
    required this.onAll,
    required this.onClose,
  });

  final VoidCallback onNextVerse;
  final VoidCallback onAll;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    return Material(
      color: t.paper,
      elevation: 6,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.visibility_outlined,
                color: t.control,
                semanticLabel: l.reciteMode,
              ),
            ),
            Expanded(
              child: FilledButton(
                onPressed: onNextVerse,
                child: Text(l.revealNextVerse),
              ),
            ),
            const SizedBox(width: 6),
            OutlinedButton(onPressed: onAll, child: Text(l.revealAll)),
            IconButton(
              tooltip: l.endRecite,
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
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
