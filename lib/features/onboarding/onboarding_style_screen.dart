import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../settings/theme_picker.dart';
import 'page_preview.dart';

/// First launch, screen 1: the theme and the colour mode, with a live
/// preview of a real mushaf page in the chosen theme.
class OnboardingStyleScreen extends ConsumerWidget {
  const OnboardingStyleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final registry = ref.watch(themeRegistryProvider);
    final lang = Localizations.localeOf(context).languageCode;
    final style = registry.byId(settings.styleId);
    final mode = settings.resolveMode(MediaQuery.platformBrightnessOf(context));
    final t = context.tokens.colors;
    const modes = [
      ModeSetting.light,
      ModeSetting.white,
      ModeSetting.night,
      ModeSetting.black,
    ];
    final modeNames = [l.modeLight, l.modeWhite, l.modeNight, l.modeBlack];

    return Scaffold(
      body: SafeArea(
        // Built whole (not lazily): the picker makes the screen taller than
        // a phone, and the continue button must always exist.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.appTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'ArefRuqaa',
                  fontSize: 36,
                  color: t.goldText,
                  height: 1.2,
                ),
              ),
              Text(
                l.onbStyleTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                l.onbStyleHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: t.muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Center(
                child: RealPagePreview(
                  style: style,
                  mode: mode,
                  width: 230,
                  semanticLabel:
                      '${style.localizedName(lang)}، ${modeNames[modes.indexOf(settings.mode == ModeSetting.system ? ModeSetting.light : settings.mode)]}',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                style.localizedDescription(lang),
                textAlign: TextAlign.center,
                style: TextStyle(color: t.muted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Semantics(header: true, child: Text(l.themeLabel)),
              const SizedBox(height: 8),
              const ThemePicker(columns: 5),
              const SizedBox(height: 14),
              SegmentedButton<ModeSetting>(
                segments: [
                  for (var i = 0; i < modes.length; i++)
                    ButtonSegment(value: modes[i], label: Text(modeNames[i])),
                ],
                selected: {
                  settings.mode == ModeSetting.system
                      ? ModeSetting.light
                      : settings.mode,
                },
                onSelectionChanged: (v) => ctrl.setMode(v.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go('/onboarding/edition'),
                child: Text(l.continueLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
