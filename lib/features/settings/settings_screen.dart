import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/backup/backup.dart';
import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../audio/player_bar.dart';
import '../audio/recitation.dart';
import '../mushaf/mushaf_providers.dart';
import '../mushaf/presentation/widgets/download_all_button.dart';
import '../mushaf/presentation/widgets/edition_badge.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;

/// The app's version as built (pubspec.yaml), e.g. `0.4.0 (5)`.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.buildNumber.isEmpty
      ? info.version
      : '${info.version} (${info.buildNumber})';
});

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
              subtitle: Text(switch (ref.watch(currentReciterProvider).value) {
                final r? => reciterLabel(context, r),
                null => '',
              }, style: TextStyle(color: t.muted)),
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
                      // The KFGQPC Madina mushafs of the other riwayat.
                      ListTile(
                        title: Text(
                          l.riwayatTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(l.riwayaEditionDesc),
                      ),
                      for (final e in MushafEdition.values)
                        if (e.isRiwaya)
                          RadioListTile(
                            value: e,
                            title: Text(editionName(l, e)),
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
                SwitchListTile(
                  title: Text(l.twoPageSpread),
                  subtitle: Text(
                    l.twoPageSpreadHint,
                    style: TextStyle(color: t.muted),
                  ),
                  value: settings.twoPageSpread,
                  onChanged: controller.setTwoPageSpread,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: Text(l.storageOpen),
              subtitle: Text(
                l.storageOpenHint,
                style: TextStyle(color: t.muted),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/storage'),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(l.backupTitle),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.ios_share),
                  title: Text(l.backupExport),
                  subtitle: Text(
                    l.backupExportHint,
                    style: TextStyle(color: t.muted),
                  ),
                  onTap: () => _export(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: Text(l.backupImport),
                  subtitle: Text(
                    l.backupImportHint,
                    style: TextStyle(color: t.muted),
                  ),
                  onTap: () => _import(context, ref),
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
                    l.versionLabel(ref.watch(appVersionProvider).value ?? ''),
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

Future<void> _export(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final text = await Backup(
      ref.read(userDatabaseProvider),
      prefs: ref.read(sharedPreferencesProvider),
    ).export();
    final dir = await getTemporaryDirectory();
    final day = DateTime.now().toIso8601String().substring(0, 10);
    final file = File('${dir.path}/tibyan-backup-$day.json');
    await file.writeAsString(text, flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l.backupFailed)));
  }
}

Future<void> _import(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final digits = NumberFormatter(Localizations.localeOf(context));
  try {
    final picked = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Tibyan backup', extensions: ['json']),
      ],
    );
    if (picked == null) return;
    final text = utf8.decode(await picked.readAsBytes());
    final r = await Backup(
      ref.read(userDatabaseProvider),
      prefs: ref.read(sharedPreferencesProvider),
    ).import(text);
    // The restored settings take effect now.
    if (r.settings > 0) ref.invalidate(settingsProvider);
    messenger.showSnackBar(
      SnackBar(content: Text(l.backupDone(digits(r.added), digits(r.updated)))),
    );
  } on BackupException {
    messenger.showSnackBar(SnackBar(content: Text(l.backupInvalid)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l.backupFailed)));
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
