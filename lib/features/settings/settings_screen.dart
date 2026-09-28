import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final t = context.tokens.colors;

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(l.appearanceTitle),
              subtitle: Text(
                ref
                    .watch(themeRegistryProvider)
                    .byId(settings.styleId)
                    .localizedName(
                      Localizations.localeOf(context).languageCode,
                    ),
                style: TextStyle(color: t.muted),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/appearance'),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(l.languageLabel),
          Card(
            child: RadioGroup<LanguageSetting>(
              groupValue: settings.language,
              onChanged: (v) => v == null ? null : controller.setLanguage(v),
              child: Column(
                children: [
                  RadioListTile(
                    value: LanguageSetting.system,
                    title: Text(l.languageSystem),
                  ),
                  RadioListTile(
                    value: LanguageSetting.ar,
                    title: Text(l.languageArabic),
                  ),
                  RadioListTile(
                    value: LanguageSetting.en,
                    title: Text(l.languageEnglish),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(l.readingTitle),
          Card(
            child: Column(
              children: [
                RadioGroup<MushafEdition>(
                  groupValue: settings.edition,
                  onChanged: (v) => v == null ? null : controller.setEdition(v),
                  child: Column(
                    children: [
                      RadioListTile(
                        value: MushafEdition.madina1441,
                        title: Text(l.editionNew),
                      ),
                      RadioListTile(
                        value: MushafEdition.madina1405,
                        title: Text(l.editionOld),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(l.keepScreenOn),
                  value: settings.keepScreenOn,
                  onChanged: controller.setKeepScreenOn,
                ),
                ListTile(
                  title: Text(l.quranFontSize),
                  subtitle: Slider(
                    value: settings.quranFontScale,
                    min: 0.8,
                    max: 2.0,
                    divisions: 12,
                    label: '${(settings.quranFontScale * 100).round()}%',
                    onChanged: controller.setQuranFontScale,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(l.privacyTitle),
          Card(
            child: SwitchListTile(
              value: settings.crashReportsOptIn,
              onChanged: controller.setCrashReportsOptIn,
              title: Text(l.crashReportsLabel),
              subtitle: Text(
                l.crashReportsHint,
                style: TextStyle(color: t.muted),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(l.aboutTitle),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.aboutBody),
                  const SizedBox(height: 8),
                  Text(
                    l.versionLabel('0.1.1'),
                    style: TextStyle(color: t.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 8),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: context.tokens.colors.goldText,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
