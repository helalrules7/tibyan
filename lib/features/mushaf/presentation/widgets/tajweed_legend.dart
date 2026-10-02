import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/settings_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/tajweed.dart';

/// A rule's name: the data's rule, as the usual tajweed term.
String tajweedRuleName(AppLocalizations l, TajweedRule r) => switch (r) {
  TajweedRule.hamzatWasl => l.tajweedHamzatWasl,
  TajweedRule.lamShamsiyyah => l.tajweedLamShamsiyyah,
  TajweedRule.silent => l.tajweedSilent,
  TajweedRule.madd2 => l.tajweedMadd2,
  TajweedRule.madd246 => l.tajweedMadd246,
  TajweedRule.maddMuttasil => l.tajweedMaddMuttasil,
  TajweedRule.maddMunfasil => l.tajweedMaddMunfasil,
  TajweedRule.madd6 => l.tajweedMadd6,
  TajweedRule.ghunnah => l.tajweedGhunnah,
  TajweedRule.ikhfa => l.tajweedIkhfa,
  TajweedRule.ikhfaShafawi => l.tajweedIkhfaShafawi,
  TajweedRule.iqlab => l.tajweedIqlab,
  TajweedRule.idghaamGhunnah => l.tajweedIdghaamGhunnah,
  TajweedRule.idghaamNoGhunnah => l.tajweedIdghaamNoGhunnah,
  TajweedRule.idghaamShafawi => l.tajweedIdghaamShafawi,
  TajweedRule.idghaamMutajanisayn => l.tajweedIdghaamMutajanisayn,
  TajweedRule.idghaamMutaqaribayn => l.tajweedIdghaamMutaqaribayn,
  TajweedRule.qalqalah => l.tajweedQalqalah,
};

String tajweedHueName(AppLocalizations l, TajweedHue h) => switch (h) {
  TajweedHue.crimson => l.tajweedHueCrimson,
  TajweedHue.red => l.tajweedHueRed,
  TajweedHue.orange => l.tajweedHueOrange,
  TajweedHue.gold => l.tajweedHueGold,
  TajweedHue.green => l.tajweedHueGreen,
  TajweedHue.lightGreen => l.tajweedHueLightGreen,
  TajweedHue.teal => l.tajweedHueTeal,
  TajweedHue.blue => l.tajweedHueBlue,
  TajweedHue.purple => l.tajweedHuePurple,
  TajweedHue.pink => l.tajweedHuePink,
  TajweedHue.grey => l.tajweedHueGrey,
};

/// Rules in the order the key lists them: the madd rules, the nasal
/// rules, then the rest.
const tajweedLegendOrder = [
  TajweedRule.madd6,
  TajweedRule.maddMuttasil,
  TajweedRule.maddMunfasil,
  TajweedRule.madd246,
  TajweedRule.madd2,
  TajweedRule.ghunnah,
  TajweedRule.ikhfa,
  TajweedRule.ikhfaShafawi,
  TajweedRule.iqlab,
  TajweedRule.idghaamGhunnah,
  TajweedRule.idghaamShafawi,
  TajweedRule.idghaamNoGhunnah,
  TajweedRule.idghaamMutajanisayn,
  TajweedRule.idghaamMutaqaribayn,
  TajweedRule.qalqalah,
  TajweedRule.hamzatWasl,
  TajweedRule.lamShamsiyyah,
  TajweedRule.silent,
];

/// A round colour sample on the page's paper.
class _Swatch extends StatelessWidget {
  const _Swatch(this.color);

  static const size = 26.0;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? t.paper,
        shape: BoxShape.circle,
        border: Border.all(color: t.border),
      ),
      child: color == null
          ? Icon(Icons.block, size: size * 0.6, color: t.muted)
          : null,
    );
  }
}

/// The colour key: each rule with its colour in the current mode.
Future<void> showTajweedLegend(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.7,
    maxChildSize: 0.95,
    builder: (context, scroll) => _Legend(scroll: scroll),
  ),
);

class _Legend extends ConsumerWidget {
  const _Legend({required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final dark = !context.tokens.mode.isLight;
    final hues = ref.watch(settingsProvider.select((s) => s.tajweedHues));
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Semantics(
          header: true,
          child: Text(
            l.tajweedLegend,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        for (final rule in tajweedLegendOrder)
          if (tajweedHueOf(rule, hues) case final hue)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _Swatch(hue?.on(darkPaper: dark)),
              title: Text(
                tajweedRuleName(l, rule),
                style: TextStyle(color: hue?.on(darkPaper: dark) ?? t.muted),
              ),
              subtitle: Text(
                hue == null ? l.tajweedNoColor : tajweedHueName(l, hue),
                style: TextStyle(color: t.muted, fontSize: 12),
              ),
            ),
        const SizedBox(height: 8),
        Text(l.tajweedSourceNote, style: TextStyle(color: t.muted)),
      ],
    );
  }
}

/// The tajweed part of the mushaf's look settings: on or off, each rule's
/// colour, and the colour key.
class TajweedSettings extends ConsumerWidget {
  const TajweedSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final dark = !context.tokens.mode.isLight;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            title: Text(l.tajweedColors),
            subtitle: Text(
              l.tajweedColorsHint,
              style: TextStyle(color: t.muted),
            ),
            value: settings.tajweedColors,
            onChanged: controller.setTajweedColors,
          ),
          if (settings.tajweedColors) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.format_color_text),
              title: Text(l.tajweedLegend),
              subtitle: Text(
                l.tajweedLegendHint,
                style: TextStyle(color: t.muted, fontSize: 12),
              ),
              onTap: () => showTajweedLegend(context),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
              child: Text(
                l.tajweedRuleColors,
                style: TextStyle(color: t.muted),
              ),
            ),
            for (final rule in tajweedLegendOrder)
              if (tajweedHueOf(rule, settings.tajweedHues) case final hue)
                ListTile(
                  dense: true,
                  title: Text(tajweedRuleName(l, rule)),
                  trailing: _Swatch(hue?.on(darkPaper: dark)),
                  onTap: () => _pick(context, ref, rule),
                ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: TextButton(
                  onPressed: settings.tajweedHues.isEmpty
                      ? null
                      : controller.resetTajweedHues,
                  child: Text(l.tajweedReset),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                l.tajweedSourceNote,
                style: TextStyle(color: t.muted, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, TajweedRule rule) =>
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (context) {
          final l = AppLocalizations.of(context);
          final t = context.tokens.colors;
          final dark = !context.tokens.mode.isLight;
          final hues = ref.read(settingsProvider).tajweedHues;
          final current = tajweedHueOf(rule, hues);
          final controller = ref.read(settingsProvider.notifier);
          Widget choice(TajweedHue? hue, String label) {
            final selected = hue == current;
            return Semantics(
              selected: selected,
              button: true,
              label: label,
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  // Picking the default colour forgets the choice.
                  final isDefault = hue == defaultTajweedHues[rule];
                  controller.setTajweedHue(
                    rule.key,
                    isDefault ? null : (hue?.name ?? ''),
                  );
                  Navigator.pop(context);
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? t.control : t.border,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: Center(child: _Swatch(hue?.on(darkPaper: dark))),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.tajweedPickColor(tajweedRuleName(l, rule)),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    choice(null, l.tajweedNoColor),
                    for (final h in TajweedHue.values)
                      choice(h, tajweedHueName(l, h)),
                  ],
                ),
              ],
            ),
          );
        },
      );
}
