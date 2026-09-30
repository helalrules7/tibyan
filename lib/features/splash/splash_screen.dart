import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart';

/// Shown briefly at launch: the ornate page in light mode, the golden arch
/// in night and black modes; with a drawn frame design, its own splash in
/// every mode.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 1600),
  });

  final Duration duration;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, () {
      if (mounted) context.go('/');
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
    final dark = tokens.mode != ThemeModeId.light;
    // A drawn design shows its own splash in every mode; otherwise the
    // golden arch in the dark modes.
    final look = FrameLook.of(context, ref);
    final gold = dark && look == null;
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
            color: look?.ink ?? (gold ? const Color(0xFFF2D48A) : t.ink),
          ),
        ),
        Text(
          l.coverTitle,
          style: TextStyle(
            fontFamily: 'KFGQPCAN',
            fontSize: 17,
            color: look?.ink ?? (gold ? const Color(0xFFE9E1CF) : t.ink),
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
                    catchwordSpace: false,
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
