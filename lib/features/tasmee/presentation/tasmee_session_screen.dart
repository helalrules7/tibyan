import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/flags/feature_flags.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../hifz/data/hifz_repository.dart';
import '../../hifz/presentation/hifz_screen.dart' show openHifzTest;
import '../../mushaf/mushaf_providers.dart';
import '../data/tasmee_backend.dart';
import '../data/tasmee_settings.dart';
import '../domain/alignment_engine.dart';
import '../domain/expected_words.dart';
import '../domain/recitation_range.dart';
import '../domain/tasmee_report.dart';
import '../domain/tasmee_session_request.dart';
import 'recording_panel.dart';
import 'tasmee_page.dart';
import 'tasmee_session_controller.dart';
import 'tasmee_sheets.dart';
import 'tasmee_style.dart';

/// Where the side panel replaces the bottom one (laptops, tablets held
/// sideways).
const _sideLayoutWidth = 1000.0;

/// The audio tasmee: the range's words covered on the real page, shown in
/// place as they are recited, and the recording panel under the page.
class TasmeeSessionScreen extends ConsumerStatefulWidget {
  const TasmeeSessionScreen({required this.request, super.key});

  final TasmeeSessionRequest request;

  @override
  ConsumerState<TasmeeSessionScreen> createState() =>
      _TasmeeSessionScreenState();
}

class _TasmeeSessionScreenState extends ConsumerState<TasmeeSessionScreen> {
  late final TasmeeSessionController _session;
  int? _viewPage;
  bool _summaryShown = false;
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(tasmeeSettingsProvider);
    _session = TasmeeSessionController(
      request: widget.request,
      backend: ref.read(tasmeeBackendProvider),
      onError: widget.request.onError ?? settings.onError,
      strictness: settings.strictness,
      toastSeconds: settings.toastSeconds,
      vibration: settings.vibration,
    )..addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void dispose() {
    _session
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  Future<void> _open() async {
    await _session.load();
    if (!mounted) return;
    if (!ref.read(tasmeeSettingsProvider).firstUseSeen) {
      await _showNotice(firstTime: true);
      if (!mounted) return;
    }
    if (_session.phase == TasmeePhase.needsModel) await _showModelSheet();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    if (_session.phase == TasmeePhase.finished && !_summaryShown) {
      _summaryShown = true;
      unawaited(_saveLast());
      WidgetsBinding.instance.addPostFrameCallback((_) => _showSummary());
    }
  }

  Future<void> _saveLast() async {
    final report = _session.report;
    if (report.verses.isEmpty) return;
    final words = widget.request.words;
    final acc = report.accuracy;
    await ref
        .read(tasmeeSettingsProvider.notifier)
        .setLast(
          LastTasmee(
            fromSurah: words.first.surah,
            fromAyah: words.first.ayah,
            toSurah: words.last.surah,
            toAyah: words.last.ayah,
            reachedSurah: report.verses.last.surah,
            reachedAyah: report.verses.last.ayah,
            accuracy: acc == null ? null : (acc * 100).round(),
          ),
        );
  }

  Future<T?> _sheet<T>(WidgetBuilder builder, {bool dismissible = true}) async {
    _sheetOpen = true;
    try {
      return await showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        isDismissible: dismissible,
        enableDrag: dismissible,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.38),
        builder: builder,
      );
    } finally {
      _sheetOpen = false;
    }
  }

  Future<void> _showNotice({required bool firstTime}) => _sheet<void>(
    (context) => FirstUseSheet(
      firstTime: firstTime,
      onDone: () {
        if (firstTime) {
          unawaited(
            ref.read(tasmeeSettingsProvider.notifier).setFirstUseSeen(),
          );
        }
        Navigator.pop(context);
      },
    ),
  );

  Future<void> _showModelSheet() => _sheet<void>(
    (context) => ModelSheet(
      backend: ref.read(tasmeeBackendProvider),
      onAbout: () => this.context.push('/mushaf/about'),
      onInstalled: (model) {
        _session.modelInstalled(model);
        Navigator.pop(context);
      },
    ),
  );

  Future<void> _showSummary() async {
    if (!mounted || _sheetOpen) return;
    final report = _session.report;
    final review = report.toReview;
    final title = _title(context).$2;
    final verse = await _sheet<VerseReport>(
      (context) => SummarySheet(
        title: title,
        duration: _session.elapsed,
        report: report,
        words: widget.request.words,
        onVerse: (v) => Navigator.pop(context, v),
        onDone: () {
          Navigator.pop(context);
          if (this.context.mounted) this.context.pop();
        },
        onAgain: review.isEmpty
            ? null
            : () {
                Navigator.pop(context);
                _reciteAgain({for (final v in review) v.verseId});
              },
      ),
    );
    if (verse != null && mounted) {
      final first = widget.request.words.firstWhere(
        (w) => w.verseId == verse.verseId,
      );
      setState(() => _viewPage = first.page);
    }
  }

  void _reciteAgain(Set<int> verseIds) {
    final words = wordsOfVerses(widget.request.words, verseIds);
    if (words.isEmpty) return;
    context.pushReplacement(
      '/tasmee/session',
      extra: TasmeeSessionRequest(
        range: VerseRange(
          fromSurah: words.first.surah,
          fromAyah: words.first.ayah,
          toSurah: words.last.surah,
          toAyah: words.last.ayah,
        ),
        words: List.unmodifiable(words),
        mode: widget.request.mode,
        onError: widget.request.onError,
      ),
    );
  }

  Future<void> _openSettings() async {
    final ok = await ref.read(tasmeeBackendProvider).openDeviceSettings();
    if (ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).tasmeeAllowMicHint)),
    );
  }

  Future<void> _touchTest() async {
    final words = widget.request.words;
    final kind = switch (widget.request.range) {
      SurahRange() => HifzUnitKind.surah,
      HizbPartRange(kind: RecitationRangeKind.quarter) => HifzUnitKind.quarter,
      _ => HifzUnitKind.page,
    };
    await openHifzTest(
      context,
      ref,
      kind: kind,
      fromRef: '${words.first.surah}:${words.first.ayah}',
      toRef: '${words.last.surah}:${words.last.ayah}',
    );
  }

  void _main() {
    final s = _session;
    switch (s.phase) {
      case TasmeePhase.needsModel:
        unawaited(_showModelSheet());
      case TasmeePhase.listening:
        unawaited(
          s.mode == TasmeeMode.verseByVerse ? s.finishVerse() : s.pause(),
        );
      case TasmeePhase.finished:
        unawaited(_showSummary());
      default:
        setState(() => _viewPage = null);
        unawaited(s.listen());
    }
  }

  Future<void> _end() async {
    if (_session.phase == TasmeePhase.finished) {
      if (mounted) context.pop();
      return;
    }
    if (_session.report.verses.isEmpty) {
      // Nothing recited: leave without a summary.
      if (mounted) context.pop();
      return;
    }
    await _session.end();
  }

  /// The title and the range line of the top bar.
  (String, String) _title(BuildContext context) {
    final l = AppLocalizations.of(context);
    final words = widget.request.words;
    final first = words.first, last = words.last;
    final surahs = ref.read(surahsProvider).value;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String name(int s) => surahs == null
        ? context.digits(s)
        : (ar ? surahs[s - 1].nameAr : surahs[s - 1].nameEn);
    final mode = widget.request.mode == TasmeeMode.continuous
        ? l.tasmeeContinuous
        : l.tasmeeVerseByVerse;
    if (first.surah == last.surah) {
      return (
        l.tasmeeSessionTitle(name(first.surah)),
        l.tasmeeVersesLine(
          context.digits(first.ayah),
          context.digits(last.ayah),
          mode,
        ),
      );
    }
    return (
      l.tasmeeTitle,
      l.tasmeeAcrossSurahs(
        name(first.surah),
        context.digits(first.ayah),
        name(last.surah),
        context.digits(last.ayah),
        mode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    final s = _session;
    final flags = ref.watch(featureFlagsProvider);
    final actions = PanelActions(
      onMain: _main,
      onEnd: _end,
      onHint: flags.isOn(Feature.tasmeeHint) ? s.hint : null,
      onSkipWaiting: s.skipWaiting,
      onOpenSettings: _openSettings,
      onTouchTest: _touchTest,
    );
    final page = _viewPage ?? s.page;
    final finished = s.phase == TasmeePhase.finished;
    final words = [
      for (final w in widget.request.words)
        if (w.page == page) w,
    ];
    final pageState = TasmeePageState(
      statusOf: s.engine.statusOf,
      hinted: s.hinted,
      cursor: s.phase == TasmeePhase.listening ? s.cursorWord : null,
      waitingAt: s.engine.waitingAt,
      revealAll: finished,
    );
    final edition = ref.watch(editionProvider);
    final Widget pageView = edition == MushafEdition.madina1441
        ? TasmeePage(page: page, words: words, state: pageState)
        : _WordsView(words: widget.request.words, state: pageState);
    ref.watch(surahsProvider);
    final (title, line) = _title(context);
    final wide = MediaQuery.sizeOf(context).width >= _sideLayoutWidth;
    final top = _TopBar(
      title: title,
      line: line,
      progress: s.progress,
      onClose: () => context.pop(),
      onHelp: () => _showNotice(firstTime: false),
    );
    return PopScope(
      child: Scaffold(
        backgroundColor: t.bg,
        body: wide
            ? Column(
                children: [
                  SafeArea(bottom: false, child: top),
                  Expanded(
                    child: Row(
                      children: [
                        const SizedBox(width: 24),
                        Expanded(
                          child: KeyedSubtree(
                            key: const ValueKey('tasmee-page'),
                            child: pageView,
                          ),
                        ),
                        const SizedBox(width: 24),
                        SizedBox(
                          width: 340,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: _SidePanel(session: s, actions: actions),
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  SafeArea(bottom: false, child: top),
                  Expanded(
                    child: KeyedSubtree(
                      key: const ValueKey('tasmee-page'),
                      child: pageView,
                    ),
                  ),
                  RecordingPanel(session: s, actions: actions),
                ],
              ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.line,
    required this.progress,
    required this.onClose,
    required this.onHelp,
  });

  final String title;
  final String line;
  final double progress;
  final VoidCallback onClose;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    return Material(
      color: t.bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 54,
            child: Row(
              children: [
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close, color: t.ink),
                  tooltip: l.tasmeeClose,
                ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: t.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          line,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: t.muted,
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onHelp,
                  icon: Icon(Icons.help_outline, color: t.ink),
                  tooltip: l.tasmeeHelp,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Semantics(
              label: l.tasmeeProgress,
              value: context.percent((progress * 100).round()),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  color: t.goldText,
                  backgroundColor: t.border,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

/// Laptop: the panel beside the page, with each verse's accuracy.
class _SidePanel extends StatelessWidget {
  const _SidePanel({required this.session, required this.actions});

  final TasmeeSessionController session;
  final PanelActions actions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final c = context.tasmeeColors;
    final report = session.report;
    final verses = <ExpectedWord>[];
    for (final w in session.words) {
      if (verses.isEmpty || verses.last.verseId != w.verseId) verses.add(w);
    }
    final current = session.currentVerseId;
    return Container(
      key: const ValueKey('tasmee-panel'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RecordingPanel(session: session, actions: actions, side: true),
          const SizedBox(height: 18),
          TasmeeSectionLabel(l.tasmeeVersesHeading),
          Expanded(
            child: ListView(
              children: [
                for (final v in verses)
                  () {
                    final acc = report.verse(v.verseId)?.accuracy;
                    final pct = acc == null ? null : (acc * 100).round();
                    final here = v.verseId == current;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 72,
                            child: Text(
                              l.tasmeeVerseNumber(context.digits(v.ayah)),
                              style: TextStyle(
                                color: here ? t.goldText : t.ink,
                                fontSize: 13,
                                fontWeight: here
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: (pct ?? 0) / 100,
                                minHeight: 6,
                                color: pct == null || pct >= 90
                                    ? t.goldText
                                    : c.skipped,
                                backgroundColor: t.border,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 46,
                            child: Text(
                              pct == null ? '–' : context.percent(pct),
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                color: pct == null ? t.muted : t.ink,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Editions other than the new Madina one: the range's words in order
/// (their pages differ from the 1441 pages the session follows).
class _WordsView extends StatelessWidget {
  const _WordsView({required this.words, required this.state});

  final List<ExpectedWord> words;
  final TasmeePageState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final c = context.tasmeeColors;
    final grouped = <int, List<ExpectedWord>>{};
    for (final w in words) {
      (grouped[w.verseId] ??= []).add(w);
    }
    Color colour(int i) {
      if (state.hinted.contains(i)) return c.hint;
      return switch (state.statusOf(i)) {
        WordStatus.wrong => c.wrong,
        WordStatus.skipped => c.skipped,
        WordStatus.correctedAfterError => c.corrected,
        WordStatus.doubtful => c.doubtful,
        WordStatus.hidden => t.muted,
        WordStatus.correct => t.ink,
      };
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Text(l.tasmeeOtherEdition, style: TextStyle(color: t.muted)),
        const SizedBox(height: 8),
        for (final ws in grouped.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              textDirection: TextDirection.rtl,
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final w in ws)
                  if (state.statusOf(w.index) == WordStatus.hidden &&
                      !state.hinted.contains(w.index) &&
                      !state.revealAll)
                    ExcludeSemantics(
                      child: Container(
                        width: (w.display.runes.length * 10.0).clamp(28, 96),
                        height: 30,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: t.border.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    )
                  else
                    Text(
                      w.display,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: colour(w.index),
                        fontSize: 24,
                        height: 1.7,
                        fontFamily: 'KFGQPC Hafs Uthmanic Script',
                      ),
                    ),
              ],
            ),
          ),
      ],
    );
  }
}
