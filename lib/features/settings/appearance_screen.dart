import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/style_preview.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final registry = ref.watch(themeRegistryProvider);
    final lang = Localizations.localeOf(context).languageCode;
    final mode = settings.resolveMode(MediaQuery.platformBrightnessOf(context));
    final t = context.tokens.colors;

    return Scaffold(
      appBar: AppBar(title: Text(l.appearanceTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _Title(l.styleLabel),
          SizedBox(
            height: 290,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: registry.styles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final style = registry.styles[i];
                final selected = style.id == settings.styleId;
                final name = style.localizedName(lang);
                return Semantics(
                  selected: selected,
                  button: true,
                  label: '$name. ${style.localizedDescription(lang)}',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => controller.setStyle(style.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? t.goldText : t.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          StylePreview(
                            style: style,
                            mode: mode,
                            headerLabel: l.previewLabel,
                            semanticLabel: name,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            selected
                                ? l.selected
                                : style.localizedDescription(lang),
                            style: TextStyle(color: t.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _Title(l.modeLabel),
          Card(
            child: RadioGroup<ModeSetting>(
              groupValue: settings.mode,
              onChanged: (v) => v == null ? null : controller.setMode(v),
              child: Column(
                children: [
                  RadioListTile(
                    value: ModeSetting.system,
                    title: Text(l.modeSystem),
                    subtitle: Text(
                      l.modeSystemHint,
                      style: TextStyle(color: t.muted),
                    ),
                  ),
                  RadioListTile(
                    value: ModeSetting.light,
                    title: Text(l.modeLight),
                  ),
                  RadioListTile(
                    value: ModeSetting.night,
                    title: Text(l.modeNight),
                  ),
                  RadioListTile(
                    value: ModeSetting.black,
                    title: Text(l.modeBlack),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _Title(l.uiFontLabel),
          Card(
            child: RadioGroup<UiFont>(
              groupValue: settings.uiFont,
              onChanged: (v) => v == null ? null : controller.setUiFont(v),
              child: Column(
                children: [
                  RadioListTile(
                    value: UiFont.plex,
                    title: Text(
                      l.uiFontPlex,
                      style: TextStyle(fontFamily: UiFont.plex.family),
                    ),
                  ),
                  RadioListTile(
                    value: UiFont.kfgqpcAn,
                    title: Text(
                      l.uiFontKfgqpcAn,
                      style: TextStyle(fontFamily: UiFont.kfgqpcAn.family),
                    ),
                  ),
                  RadioListTile(
                    value: UiFont.changa,
                    title: Text(
                      l.uiFontChanga,
                      style: TextStyle(fontFamily: UiFont.changa.family),
                    ),
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

class _Title extends StatelessWidget {
  const _Title(this.text);

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
