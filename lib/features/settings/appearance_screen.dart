import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/presentation/widgets/art_frame.dart';
import '../mushaf/presentation/widgets/theme_art.dart';
import 'theme_picker.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final t = context.tokens.colors;
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l.appearanceTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _Title(l.themeLabel),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ThemePicker(),
                  const SizedBox(height: 10),
                  Text(
                    context.tokens.style.localizedDescription(lang),
                    style: TextStyle(color: t.muted, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _Title(l.markerStyleLabel),
          const Card(child: _MarkerSettings()),
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
                    value: ModeSetting.white,
                    title: Text(l.modeWhite),
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
    final art = watchThemeArt(context, ref);
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final style in MarkerStyle.values)
                choice(
                  selected: settings.markerStyle == style,
                  label: switch (style) {
                    MarkerStyle.theme => l.markerTheme,
                    MarkerStyle.traditional => l.markerTraditional,
                    _ => l.markerRosette,
                  },
                  onTap: () => controller.setMarkerStyle(style),
                  child: style == MarkerStyle.theme
                      // The theme's own marker; Zakhrafa's is its rosette.
                      ? art == null
                            ? Image.asset(
                                _images[MarkerStyle.rosette16]!,
                                width: 40,
                                height: 40,
                              )
                            : SizedBox(
                                width: 40,
                                height: 40,
                                child: CustomPaint(
                                  painter: ArtPicturePainter(art.marker),
                                ),
                              )
                      : style == MarkerStyle.traditional
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
          const SizedBox(height: 8),
          Text(
            l.markerThemeHint,
            style: TextStyle(color: t.muted, fontSize: 12.5),
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
