import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../audio/player_bar.dart';
import '../audio/recitation.dart';
import '../mushaf/mushaf_providers.dart';
import '../mushaf/presentation/widgets/download_all_button.dart';
import '../mushaf/presentation/widgets/edition_badge.dart';

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
            child: SwitchListTile(
              secondary: const Icon(Icons.elderly),
              title: Text(l.elderlyMode),
              subtitle: Text(
                l.elderlyModeHint,
                style: TextStyle(color: t.muted),
              ),
              value: settings.elderlyMode,
              onChanged: controller.setElderlyMode,
            ),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.headphones_outlined),
              title: Text(l.playerSettings),
              subtitle: Text(
                ref
                        .watch(recitersProvider)
                        .value
                        ?.where((r) => r.id == settings.reciterId)
                        .map((r) => reciterLabel(context, r))
                        .firstOrNull ??
                    '',
                style: TextStyle(color: t.muted),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/player'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l.aboutMushafTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/mushaf/about'),
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
                  onChanged: (v) async {
                    if (v == null) return;
                    await controller.setEdition(v);
                    // An edition not on the device yet goes straight to
                    // its download, which starts on its own.
                    if (!ref.read(installedEditionsProvider).contains(v) &&
                        context.mounted) {
                      context.push('/mushaf/download');
                    }
                  },
                  child: Column(
                    children: [
                      for (final (e, name) in [
                        (MushafEdition.madina1441, l.editionNew),
                        (MushafEdition.madina1405, l.editionOld),
                        (MushafEdition.shamarly, l.editionShamarly),
                      ])
                        RadioListTile(
                          value: e,
                          title: Text(name),
                          subtitle: EditionBadge(edition: e),
                        ),
                    ],
                  ),
                ),
                const DownloadAllButton(),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(l.keepScreenOn),
                  value: settings.keepScreenOn,
                  onChanged: controller.setKeepScreenOn,
                ),
                SwitchListTile(
                  title: Text(l.highlightDivineNames),
                  subtitle: Text(
                    l.highlightDivineNamesHint,
                    style: TextStyle(color: t.muted),
                  ),
                  value: settings.highlightDivineNames,
                  onChanged: controller.setHighlightDivineNames,
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
