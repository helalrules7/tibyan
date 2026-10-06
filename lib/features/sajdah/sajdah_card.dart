import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/reveal.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import 'sajdah_positions.dart';
import 'supplications.dart';

/// What brought the card up: the recitation reaching the end of a verse
/// of prostration, or the reader moving to the verse after one.
enum SajdahFrom { listening, reading }

/// The sajdah card being shown.
@immutable
class SajdahCard {
  const SajdahCard({
    required this.verse,
    required this.seconds,
    required this.from,
    required this.id,
  });

  /// The verse of prostration, in the edition's count.
  final SajdahKey verse;

  /// The countdown's length.
  final int seconds;
  final SajdahFrom from;

  /// Each card shown gets its own id, so its countdown starts afresh.
  final int id;
}

final sajdahCardProvider = NotifierProvider<SajdahCardController, SajdahCard?>(
  SajdahCardController.new,
);

/// Shows the sajdah card and counts it down («مؤقت سجدات التلاوة»). The
/// countdown runs here, not in the card, so that a recitation paused at a
/// verse of prostration goes on even when no screen shows the card.
class SajdahCardController extends Notifier<SajdahCard?> {
  Timer? _timer;
  VoidCallback? _onClose;
  int _ids = 0;

  @override
  SajdahCard? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  /// Shows the card for [verse] with the reader's countdown. [onClose]
  /// runs once, when the countdown ends or the reader taps the card; not
  /// when the card is [drop]ped.
  void show(SajdahKey verse, SajdahFrom from, {VoidCallback? onClose}) {
    _timer?.cancel();
    final seconds = ref.read(settingsProvider).sajdahSeconds;
    _onClose = onClose;
    state = SajdahCard(verse: verse, seconds: seconds, from: from, id: ++_ids);
    _timer = Timer(Duration(seconds: seconds), close);
  }

  /// Closes the card (the countdown ended, or a tap) and runs its
  /// `onClose`.
  void close() {
    if (state == null) return;
    _timer?.cancel();
    _timer = null;
    state = null;
    final f = _onClose;
    _onClose = null;
    f?.call();
  }

  /// Takes the card away without its `onClose`: the reader moved on.
  void drop() {
    _timer?.cancel();
    _timer = null;
    _onClose = null;
    if (state != null) state = null;
  }
}

/// A hifz test is under way: no sajdah card, while listening or reading.
/// The reading screen sets it for the length of the test.
final sajdahMutedProvider = NotifierProvider<SajdahMuted, bool>(
  SajdahMuted.new,
);

class SajdahMuted extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool muted) => state = muted;
}

/// The card over a reading screen: fades in when a sajdah card is shown,
/// centred, and fades out when it closes. Put it last in the screen's
/// Stack; only the card itself takes touches.
class SajdahCardLayer extends ConsumerWidget {
  const SajdahCardLayer({super.key});

  static const fade = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(sajdahCardProvider);
    return Positioned.fill(
      child: Center(
        child: Reveal(
          visible: card != null,
          from: Offset.zero,
          duration: fade,
          child: card == null
              ? null
              : SajdahCardView(
                  key: ValueKey(card.id),
                  seconds: card.seconds,
                  onTap: ref.read(sajdahCardProvider.notifier).close,
                ),
        ),
      ),
    );
  }
}

/// The card itself: the prostration pictogram, the supplications, a
/// circular countdown from [seconds], and «اضغط للاستكمال». At most 40% of
/// the screen's height; about 85% of a phone's width, at most 420.
class SajdahCardView extends StatefulWidget {
  const SajdahCardView({super.key, required this.seconds, this.onTap});

  final int seconds;
  final VoidCallback? onTap;

  @override
  State<SajdahCardView> createState() => _SajdahCardViewState();
}

class _SajdahCardViewState extends State<SajdahCardView>
    with SingleTickerProviderStateMixin {
  late final _count = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.seconds),
  )..forward();

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tokens = context.tokens;
    final t = tokens.colors;
    final elderly = tokens.elderly;
    final size = MediaQuery.sizeOf(context);
    final digits = NumberFormatter(Localizations.localeOf(context));
    final width = math.min(size.width * 0.85, 420.0);
    final maxHeight = size.height * 0.4;
    final icon = elderly ? 64.0 : 52.0;
    final text = sajdahSupplications;

    final countdown = AnimatedBuilder(
      animation: _count,
      builder: (context, _) {
        final left = (widget.seconds * (1 - _count.value)).ceil();
        return SizedBox.square(
          dimension: elderly ? 48 : 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: 1 - _count.value,
                  strokeWidth: 3,
                  color: t.control,
                  backgroundColor: t.border,
                ),
              ),
              Text(
                digits(left),
                style: TextStyle(
                  fontSize: elderly ? 18 : 15,
                  fontWeight: FontWeight.w700,
                  color: t.ink,
                ),
              ),
            ],
          ),
        );
      },
    );

    return Semantics(
      container: true,
      liveRegion: true,
      label: l.sajdahCardLabel,
      value: l.sajdahSecondsLeft(digits(widget.seconds)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
        child: Material(
          // The paper, slightly see-through: the page shows faintly behind.
          color: t.paper.withValues(alpha: 0.94),
          elevation: 6,
          shadowColor: Colors.black38,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: t.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Semantics(
            button: true,
            label: l.sajdahContinue,
            onTap: widget.onTap,
            child: InkWell(
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: SvgPicture.asset(
                        'assets/ornaments/sajdah.svg',
                        height: icon,
                        colorFilter: ColorFilter.mode(
                          t.control,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(
                          text ?? l.sajdahTextPending,
                          textAlign: TextAlign.center,
                          textDirection: text == null
                              ? null
                              : TextDirection.rtl,
                          style: text == null
                              ? TextStyle(
                                  fontSize: elderly ? 18 : 15,
                                  color: t.muted,
                                  fontStyle: FontStyle.italic,
                                )
                              : TextStyle(
                                  fontFamily: 'UthmanTahaNaskh',
                                  fontSize: elderly ? 24 : 20,
                                  height: 1.8,
                                  color: t.ink,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ExcludeSemantics(child: countdown),
                    const SizedBox(height: 6),
                    ExcludeSemantics(
                      child: Text(
                        l.sajdahTapToContinue,
                        style: TextStyle(
                          fontSize: elderly ? 16 : 13,
                          color: t.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
