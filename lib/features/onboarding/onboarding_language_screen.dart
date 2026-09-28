import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// First launch, screen 1: interface language. The title is in both
/// languages so it reads before a choice is made; the screen switches
/// language as soon as one is picked.
class OnboardingLanguageScreen extends ConsumerWidget {
  const OnboardingLanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final t = context.tokens.colors;
    final options = [
      (LanguageSetting.ar, l.languageArabic),
      (LanguageSetting.en, l.languageEnglish),
      (LanguageSetting.system, l.languageSystem),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          children: [
            Text(
              'تبيان · Tibyan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ArefRuqaa',
                fontSize: 36,
                color: t.goldText,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.onbLanguageTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 24),
            Card(
              child: RadioGroup<LanguageSetting>(
                groupValue: settings.language,
                onChanged: (v) => v == null ? null : ctrl.setLanguage(v),
                child: Column(
                  children: [
                    for (final (value, label) in options)
                      RadioListTile(
                        value: value,
                        title: Text(
                          label,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => context.go('/onboarding/style'),
              child: Text(l.continueLabel),
            ),
          ],
        ),
      ),
    );
  }
}
