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
                      RadioListTile(
                        value: MushafEdition.shamarly,
                        title: Text(l.editionShamarly),
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
                SwitchListTile(
                  title: Text(l.highlightDivineNames),
                  subtitle: Text(
                    l.highlightDivineNamesHint,
                    style: TextStyle(color: t.muted),
                  ),
                  value: settings.highlightDivineNames,
                  onChanged: controller.setHighlightDivineNames,
                ),
                const Divider(height: 1),
                const _MarkerSettings(),
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

/// Verse-end marker shape and tint.
class _MarkerSettings extends ConsumerWidget {
  const _MarkerSettings();

  static const _images = {
    MarkerStyle.rosette7: 'assets/ornaments/marker_7.png',
    MarkerStyle.rosette9: 'assets/ornaments/marker_9.png',
    MarkerStyle.rosette16: 'assets/ornaments/marker_16.png',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    Widget choice({
      required bool selected,
      required String label,
      required Widget child,
      required VoidCallback onTap,
    }) {
      return Semantics(
        selected: selected,
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? t.control : t.border,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: Center(child: child),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.markerStyleLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final style in MarkerStyle.values)
                choice(
                  selected: settings.markerStyle == style,
                  label: style == MarkerStyle.traditional
                      ? l.markerTraditional
                      : l.markerRosette,
                  onTap: () => controller.setMarkerStyle(style),
                  child: style == MarkerStyle.traditional
                      ? Text(
                          '\u06DD',
                          style: TextStyle(
                            fontFamily: 'UthmanicHafs',
                            fontSize: 30,
                            color: t.ink,
                          ),
                        )
                      : Image.asset(_images[style]!, width: 40, height: 40),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l.markerTintLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              choice(
                selected: settings.markerTint == null,
                label: l.markerTintNone,
                onTap: () => controller.setMarkerTint(null),
                child: Icon(Icons.block, color: t.muted),
              ),
              for (final c in markerTints)
                choice(
                  selected: settings.markerTint == c,
                  label: l.markerTintLabel,
                  onTap: () => controller.setMarkerTint(c),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
