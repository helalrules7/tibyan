import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart';

/// Shown briefly at launch: the ornate page in the light modes, the golden
/// arch in night and black modes.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 1600),
  });

  final Duration duration;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

/// Where the splash leads: home, or for store screenshots the screen given
/// with `--dart-define=TIBYAN_START=/settings` (tools/store_screenshots.sh).
const _start = String.fromEnvironment('TIBYAN_START', defaultValue: '/');

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, () {
      if (mounted) context.go(_start);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tokens = context.tokens;
    final t = tokens.colors;
    // The golden arch in the dark modes.
    final gold = !tokens.mode.isLight;
    final title = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l.appTitle,
          style: TextStyle(
            fontFamily: 'ArefRuqaa',
            fontWeight: FontWeight.w700,
            fontSize: 64,
            height: 1.3,
            color: gold ? const Color(0xFFF2D48A) : t.ink,
          ),
        ),
        Text(
          l.coverTitle,
          style: TextStyle(
            fontFamily: 'KFGQPCAN',
            fontSize: 17,
            color: gold ? const Color(0xFFE9E1CF) : t.ink,
          ),
        ),
      ],
    );
    return Scaffold(
      backgroundColor: gold ? Colors.black : t.bg,
      body: Semantics(
        label: l.appTitle,
        child: gold
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/ornaments/splash_gold.jpg',
                    fit: BoxFit.cover,
                  ),
                  Center(child: title),
                ],
              )
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: OrnateFrame(
                    top: Text(
                      l.coverSubtitle,
                      style: const TextStyle(fontSize: 16),
                    ),
                    bottom: Text(
                      l.appTagline,
                      style: const TextStyle(fontSize: 13),
                    ),
                    child: Center(child: title),
                  ),
                ),
              ),
      ),
    );
  }
}
