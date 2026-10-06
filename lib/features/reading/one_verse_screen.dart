import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/db/content_database.dart';
import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../audio/recitation.dart';
import '../mushaf/data/mushaf_repository.dart';
import '../mushaf/mushaf_providers.dart';
import '../mushaf/presentation/mushaf_screen.dart' show surahName;
import '../mushaf/presentation/navigation.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import '../sajdah/sajdah_card.dart';
import '../sajdah/sajdah_positions.dart';

/// Every verse, by its row id (1 = al-Fatiha 1 … 6236 = an-Nas 6).
final verseByIdProvider = FutureProvider.family<AyahRow, int>(
  (ref, id) => ref.watch(mushafRepositoryProvider).ayahById(id),
);

/// How many verses there are (6236).
const verseCount = 6236;

/// The largest font size, between [min] and [max], at which [text] fits in
/// [box] (rtl, KFGQPC Hafs). Long verses get [min] and scroll.
double fitFontSize(
  String text,
  Size box, {
  double min = 28,
  double max = 120,
  double height = 1.9,
  TextScaler scaler = TextScaler.noScaling,
}) {
  bool fits(double size) {
    final p = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'UthmanicHafs',
          fontSize: size,
          height: height,
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      textScaler: scaler,
    )..layout(maxWidth: box.width);
    final ok = p.height <= box.height;
    p.dispose();
    return ok;
  }

  if (!fits(min)) return min;
  var lo = min, hi = max;
  while (hi - lo > 1) {
    final mid = (lo + hi) / 2;
    fits(mid) ? lo = mid : hi = mid;
  }
  return lo;
}

/// «آية آية»: reading for older eyes. The phone turns sideways and each
/// screen holds one verse, as large as it fits; a swipe or the big
/// buttons go to the next or the previous verse. The verse can be heard,
/// and while the recitation plays the screen follows it. Leaving goes back
/// to the mushaf at the last verse shown. The text is the Hafs text.
class OneVerseScreen extends ConsumerStatefulWidget {
  const OneVerseScreen({super.key, required this.surah, required this.ayah});

  final int surah;
  final int ayah;

  @override
  ConsumerState<OneVerseScreen> createState() => _OneVerseScreenState();
}

class _OneVerseScreenState extends ConsumerState<OneVerseScreen> {
  PageController? _controller;
  int _id = 1;

  /// Turns to the next verse by itself (no recitation playing).
  Timer? _auto;

  /// The verse the screen is turning to because the recitation got there
  /// (not the reader): its sajdah card is the recitation's own.
  int? _following;

  /// The steps the auto-turn button goes through, in seconds (0: off).
  static const autoSteps = [0, 10, 20, 30, 60];

  /// The reader's own choice, put back on leaving.
  late final bool _keepScreenOn = ref.read(settingsProvider).keepScreenOn;

  @override
  void initState() {
    super.initState();
    // Sideways, the whole screen for the verse.
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    unawaited(WakelockPlus.enable().catchError((_) {}));
    _keepScreenOn; // read now: ref is not usable in dispose
    _open();
  }

  /// (Re)starts the auto-turn wait for the verse now shown.
  void _restartAuto() {
    _auto?.cancel();
    final seconds = ref.read(settingsProvider).oneVerseAutoSeconds;
    if (seconds <= 0) return;
    // The sajdah card holds the auto-turn; it starts again once it closes.
    if (ref.read(sajdahCardProvider) != null) return;
    _auto = Timer(Duration(seconds: seconds), () {
      if (!mounted) return;
      // The recitation leads while it plays.
      if (ref.read(recitationProvider).playing) return _restartAuto();
      if (_id < verseCount) _go(1);
    });
  }

  void _cycleAuto() {
    final now = ref.read(settingsProvider).oneVerseAutoSeconds;
    final i = autoSteps.indexOf(now);
    final next = autoSteps[(i + 1) % autoSteps.length];
    unawaited(ref.read(settingsProvider.notifier).setOneVerseAutoSeconds(next));
    // The setting is written; the timer follows the new value.
    Future<void>.microtask(_restartAuto);
  }

  Future<void> _open() async {
    final row = await ref
        .read(mushafRepositoryProvider)
        .ayah(widget.surah, widget.ayah);
    if (!mounted) return;
    setState(() {
      _id = row.id;
      _controller = PageController(initialPage: row.id - 1);
    });
    _restartAuto();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const []);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!_keepScreenOn) {
      unawaited(WakelockPlus.disable().catchError((_) {}));
    }
    _auto?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  /// The reader (a swipe, the arrows, the auto-turn) came to verse [id]:
  /// after a verse of prostration, with the timer on, the sajdah card
  /// shows. Not when the recitation leads (its own card shows at the
  /// verse's end).
  Future<void> _sajdahAfterMove(int id, {required bool followed}) async {
    if (followed || !ref.read(settingsProvider).sajdahTimer) return;
    if (ref.read(recitationProvider).playing) return;
    final positions = await ref.read(hafsSajdahPositionsProvider.future);
    final row = await ref.read(verseByIdProvider(id).future);
    if (!mounted || id != _id || ref.read(recitationProvider).playing) return;
    final sajdah = positions.before(row.surah, row.number);
    if (sajdah == null || ref.read(sajdahCardProvider)?.verse == sajdah) {
      return;
    }
    ref.read(sajdahCardProvider.notifier).show(sajdah, SajdahFrom.reading);
  }

  void _go(int by) {
    final next = (_id + by).clamp(1, verseCount);
    _controller?.animateToPage(
      next - 1,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _leave() async {
    final row = ref.read(verseByIdProvider(_id)).value;
    if (row == null) {
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    await openVerse(context, ref, surah: row.surah, ayah: row.number);
  }

  void _listen(AyahRow row) {
    final r = ref.read(recitationProvider);
    final c = ref.read(recitationProvider.notifier);
    if (r.active && r.surah == row.surah && r.ayah == row.number) {
      unawaited(c.toggle());
      return;
    }
    // From this verse on; the screen follows the recitation.
    unawaited(c.play(row.surah, from: row.number));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    // Follow the recitation: the verse being recited is the one shown.
    ref.listen(recitationProvider, (before, now) {
      final a = now.ayah;
      if (!now.active || a == null) return;
      if (before?.ayah == a && before?.surah == now.surah) return;
      unawaited(() async {
        final row = await ref.read(mushafRepositoryProvider).ayah(now.surah, a);
        if (mounted && row.id != _id) {
          _following = row.id;
          _controller?.animateToPage(
            row.id - 1,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
          );
        }
      }());
    });

    // While the sajdah card is up, the auto-turn waits; it starts again
    // when the card closes.
    ref.listen(sajdahCardProvider, (before, now) {
      if (now != null) {
        _auto?.cancel();
      } else if (before != null) {
        _restartAuto();
      }
    });

    final c = _controller;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: t.paper,
        body: Stack(
          children: [
            Positioned.fill(
              child: c == null
                  ? Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: l.loadingLabel,
                      ),
                    )
                  : CallbackShortcuts(
                      bindings: {
                        const SingleActivator(
                          LogicalKeyboardKey.arrowLeft,
                        ): () =>
                            _go(1),
                        const SingleActivator(
                          LogicalKeyboardKey.arrowRight,
                        ): () =>
                            _go(-1),
                        const SingleActivator(LogicalKeyboardKey.escape):
                            _leave,
                      },
                      child: Focus(
                        autofocus: true,
                        child: Directionality(
                          // Verses run from right to left: the next is on the left.
                          textDirection: TextDirection.rtl,
                          child: PageView.builder(
                            controller: c,
                            itemCount: verseCount,
                            onPageChanged: (i) {
                              // Pages passed on the way to the recited verse
                              // are the recitation's too.
                              final followed = _following != null;
                              if (_following == i + 1) _following = null;
                              setState(() => _id = i + 1);
                              _restartAuto();
                              unawaited(
                                _sajdahAfterMove(i + 1, followed: followed),
                              );
                            },
                            itemBuilder: (context, i) => _VersePage(
                              id: i + 1,
                              onListen: _listen,
                              onAuto: _cycleAuto,
                              onNext: () => _go(1),
                              onPrevious: () => _go(-1),
                              onLeave: _leave,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            // The sajdah card, over the verse.
            const SajdahCardLayer(),
          ],
        ),
      ),
    );
  }
}

class _VersePage extends ConsumerWidget {
  const _VersePage({
    required this.id,
    required this.onListen,
    required this.onAuto,
    required this.onNext,
    required this.onPrevious,
    required this.onLeave,
  });

  final int id;
  final void Function(AyahRow row) onListen;

  /// Steps the auto-turn through off, 10, 20, 30 and 60 seconds.
  final VoidCallback onAuto;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final row = ref.watch(verseByIdProvider(id)).value;
    final surahs = ref.watch(surahsProvider).value;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final riwaya = ref.watch(editionProvider).isRiwaya;
    if (row == null) return const SizedBox.shrink();
    final r = ref.watch(recitationProvider);
    final playing =
        r.active && r.playing && r.surah == row.surah && r.ayah == row.number;
    final auto = ref.watch(
      settingsProvider.select((s) => s.oneVerseAutoSeconds),
    );
    final name = surahs == null
        ? ''
        : surahName(context, surahs[row.surah - 1]);

    Widget big(IconData icon, String label, VoidCallback? onTap) => Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: 72,
        height: 72,
        child: IconButton.filledTonal(
          onPressed: onTap,
          iconSize: 40,
          tooltip: label,
          icon: Icon(icon),
        ),
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          children: [
            // Where this verse is, in large print.
            Row(
              children: [
                big(
                  Icons.close,
                  MaterialLocalizations.of(context).closeButtonTooltip,
                  onLeave,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${l.surahWord(name)} | ${digits(row.number)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: t.goldText,
                        ),
                      ),
                      if (riwaya)
                        Text(
                          l.hafsTextNote,
                          style: TextStyle(fontSize: 14, color: t.muted),
                        ),
                    ],
                  ),
                ),
                // Auto-turn: off, or the seconds each verse stays.
                Semantics(
                  button: true,
                  label: auto == 0
                      ? l.oneVerseAutoOff
                      : l.oneVerseAutoOn(digits(auto)),
                  excludeSemantics: true,
                  child: SizedBox(
                    height: 72,
                    child: FilledButton.tonalIcon(
                      onPressed: onAuto,
                      icon: Icon(
                        auto == 0 ? Icons.timer_off_outlined : Icons.timer,
                        size: 32,
                      ),
                      label: Text(
                        auto == 0
                            ? l.oneVerseAutoShort
                            : l.secondsShort(digits(auto)),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                big(
                  playing ? Icons.pause : Icons.play_arrow,
                  playing ? l.pause : l.listen,
                  () => onListen(row),
                ),
              ],
            ),
            Expanded(
              child: Row(
                children: [
                  // Right: back to the verse before (reading order). The
                  // chevrons mirror in Arabic: chevron_left points right.
                  big(
                    Icons.chevron_left,
                    l.previousVerse,
                    id > 1 ? onPrevious : null,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final text = '${row.displayBody} ${row.displayNumber}';
                        final scaler = MediaQuery.textScalerOf(context);
                        final size = fitFontSize(
                          text,
                          Size(box.maxWidth - 16, box.maxHeight - 8),
                          scaler: scaler,
                        );
                        return Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: '${row.displayBody} '),
                                  TextSpan(
                                    text: row.displayNumber,
                                    style: TextStyle(color: t.marker),
                                  ),
                                ],
                              ),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'UthmanicHafs',
                                fontSize: size,
                                height: 1.9,
                                color: t.ink,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  big(
                    Icons.chevron_right,
                    l.nextVerse,
                    id < verseCount ? onNext : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
