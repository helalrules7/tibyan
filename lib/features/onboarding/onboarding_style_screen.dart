import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'page_preview.dart';

/// First launch, screen 1: style and colour mode, with a live preview of
/// a real mushaf page.
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
    const modes = [ModeSetting.light, ModeSetting.night, ModeSetting.black];
    final modeNames = [l.modeLight, l.modeNight, l.modeBlack];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            Semantics(
              label: l.styleLabel,
              child: Row(
                children: [
                  for (final s in registry.styles)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _Choice(
                          label: s.localizedName(lang),
                          selected: s.id == settings.styleId,
                          onTap: () => ctrl.setStyle(s.id),
                          swatches: [
                            s.modes[mode]!.paper,
                            s.modes[mode]!.headBg,
                            s.modes[mode]!.frame,
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.swatches,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final List<Color> swatches;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          decoration: BoxDecoration(
            color: t.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? t.control : t.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final c in swatches)
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: t.border),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
