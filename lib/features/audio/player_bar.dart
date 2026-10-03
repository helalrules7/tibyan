import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/content_database.dart';
import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/mushaf_providers.dart';
import '../mushaf/presentation/mushaf_screen.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart';
import 'recitation.dart';
import 'reciter_avatar.dart';

String reciterLabel(BuildContext context, ReciterRow r) {
  final l = AppLocalizations.of(context);
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  // Every recitation offered is murattal: the mujawwad readings were removed
  // and their ids are never reused, so there is nothing to branch on.
  return '${ar ? r.nameAr : r.nameEn} · ${l.murattal}';
}

/// The recitation controls shown over the mushaf while listening.
class PlayerBar extends ConsumerWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final s = ref.watch(recitationProvider);
    final c = ref.read(recitationProvider.notifier);
    final surahs = ref.watch(surahsProvider).value;
    final reciter = ref.watch(currentReciterProvider).value;
    final surah = surahs == null ? '' : surahName(context, surahs[s.surah - 1]);
    final where = s.ayah == null
        ? l.surahWord(surah)
        : '${l.surahWord(surah)} · ${digits(s.ayah!)}';
    final repeating = s.timed && s.repeat != 1;
    // Verses go right to left in Arabic: "previous" points right there.
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: t.player,
      elevation: 8,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Row(
          children: [
            IconButton(
              tooltip: l.stopListening,
              onPressed: c.stop,
              icon: Icon(Icons.close, color: t.playerFg),
            ),
            Expanded(
              child: InkWell(
                onTap: () => showPlayerSheet(context),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          where,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: t.playerFg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // Live: an error or the repeat count is announced.
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          s.error != null
                              ? l.playerError
                              : repeating
                              ? l.repeatProgress(
                                  digits(s.repeatDone + 1),
                                  s.repeat == 0 ? '∞' : digits(s.repeat),
                                )
                              : reciter == null
                              ? ''
                              : reciterLabel(context, reciter),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: t.playerFg.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (s.timed)
              IconButton(
                tooltip: l.previousVerse,
                onPressed: () => c.step(-1),
                icon: Icon(
                  rtl ? Icons.skip_next : Icons.skip_previous,
                  color: t.playerFg,
                ),
              ),
            s.loading
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: t.playerFg,
                        semanticsLabel: l.loadingLabel,
                      ),
                    ),
                  )
                : IconButton.filled(
                    tooltip: s.playing ? l.pause : l.resume,
                    isSelected: s.playing,
                    onPressed: c.toggle,
                    style: IconButton.styleFrom(
                      backgroundColor: t.playerFg,
                      foregroundColor: t.player,
                    ),
                    icon: Icon(s.playing ? Icons.pause : Icons.play_arrow),
                  ),
            if (s.timed)
              IconButton(
                tooltip: l.nextVerse,
                onPressed: () => c.step(1),
                icon: Icon(
                  rtl ? Icons.skip_previous : Icons.skip_next,
                  color: t.playerFg,
                ),
              ),
            IconButton(
              tooltip: l.playerSettings,
              onPressed: () => showPlayerSheet(context),
              icon: Icon(Icons.tune, color: t.playerFg),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showPlayerSheet(BuildContext context) {
  final t = context.tokens.colors;
  final panel = playerPanelTheme(Theme.of(context), t);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: t.player,
    builder: (_) => Theme(data: panel, child: const _PlayerSheet()),
  );
}

/// The player sheet wears the player bar's colours, which each theme sets
/// for each mode: [ModeTokens.player] as the surface, [ModeTokens.playerFg]
/// for text, icons and selected controls (the pair is kept at 4.5:1).
ThemeData playerPanelTheme(ThemeData base, ModeTokens t) {
  final fg = t.playerFg;
  final bg = t.player;
  final muted = playerPanelMuted(t);
  final scheme = base.colorScheme.copyWith(
    brightness: ThemeData.estimateBrightnessForColor(bg),
    primary: fg,
    onPrimary: bg,
    secondary: fg,
    onSecondary: bg,
    secondaryContainer: fg,
    onSecondaryContainer: bg,
    surface: bg,
    onSurface: fg,
    onSurfaceVariant: muted,
    surfaceContainerLowest: bg,
    surfaceContainerLow: bg,
    surfaceContainer: bg,
    surfaceContainerHigh: bg,
    surfaceContainerHighest: bg,
    outline: muted,
    outlineVariant: fg.withValues(alpha: 0.3),
  );
  WidgetStateProperty<Color> selected(Color on, Color off) =>
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? on : off,
      );
  return base.copyWith(
    colorScheme: scheme,
    textTheme: base.textTheme.apply(bodyColor: fg, displayColor: fg),
    iconTheme: base.iconTheme.copyWith(color: fg),
    dividerTheme: DividerThemeData(color: fg.withValues(alpha: 0.3), space: 1),
    listTileTheme: base.listTileTheme.copyWith(textColor: fg, iconColor: fg),
    radioTheme: RadioThemeData(fillColor: selected(fg, muted)),
    switchTheme: SwitchThemeData(
      thumbColor: selected(bg, muted),
      trackColor: selected(fg, bg),
      trackOutlineColor: selected(fg, muted),
    ),
    chipTheme: base.chipTheme.copyWith(
      color: selected(fg, bg),
      checkmarkColor: bg,
      side: BorderSide(color: muted),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        disabledForegroundColor: fg.withValues(alpha: 0.45),
        side: BorderSide(color: muted),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: fg),
  );
}

/// Secondary text in the player sheet: [ModeTokens.playerFg] softened over
/// [ModeTokens.player], still at 4.5:1 in every theme and mode.
Color playerPanelMuted(ModeTokens t) =>
    Color.alphaBlend(t.playerFg.withValues(alpha: 0.86), t.player);

class _PlayerSheet extends StatelessWidget {
  const _PlayerSheet();

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurfaceVariant;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The drag handle, in the sheet's own colours.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: fg,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Flexible(child: PlayerOptions(inSheet: true)),
          ],
        ),
      ),
    );
  }
}

/// The player's options: in the sheet over the mushaf ([inSheet]), with
/// the controls of what is playing, and in the settings, where only the
/// options kept for the next time are shown.
class PlayerOptions extends ConsumerWidget {
  const PlayerOptions({super.key, required this.inSheet});

  final bool inSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final s = ref.watch(recitationProvider);
    final c = ref.read(recitationProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final riwaya = ref.watch(editionProvider.select((e) => e.riwaya));
    final all = ref.watch(allRecitersProvider).value ?? const [];
    final reciters = [
      for (final r in all)
        if (r.riwaya == riwaya.name) r,
    ];
    final others = [
      for (final r in all)
        if (r.riwaya != riwaya.name) r,
    ];
    final current = ref.watch(currentReciterProvider).value;
    final title = Theme.of(context).textTheme.titleSmall;
    final hint = TextStyle(color: muted, fontSize: 12);
    final playing = inSheet && s.active;

    Widget chips<T>(
      List<(T, String)> options,
      T selected,
      void Function(T) on,
    ) => Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final (v, label) in options)
          ChoiceChip(
            label: Text(label),
            selected: v == selected,
            onSelected: (_) => on(v),
          ),
      ],
    );

    final sleep = s.sleep;
    final sleepKey = switch (sleep) {
      null => 0,
      SleepAtSurahEnd() => -1,
      SleepAfter(:final duration) => duration.inMinutes,
    };

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        // A riwaya edition lists that riwaya's recitations only.
        Semantics(
          header: true,
          child: Text(
            riwaya == Riwaya.hafs
                ? l.reciterLabel
                : l.riwayaRecitersNote(riwayaName(l, riwaya)),
            style: title,
          ),
        ),
        RadioGroup<int>(
          groupValue: current?.id ?? settings.reciterId,
          onChanged: (id) => id == null ? null : c.changeReciter(id),
          child: Column(
            children: [
              for (final r in reciters)
                RadioListTile<int>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: r.id,
                  title: Text(reciterLabel(context, r)),
                  secondary: ReciterAvatar(
                    id: r.id,
                    name: reciterLabel(context, r),
                    size: 36,
                  ),
                ),
              // Shown greyed out: their verses are numbered by another
              // riwaya, so they play only from that riwaya's mushaf.
              if (others.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(l.otherRiwayaReciters, style: title),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(l.otherRiwayaHint, style: hint),
                ),
                for (final r in others)
                  Opacity(
                    opacity: 0.45,
                    child: RadioListTile<int>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      enabled: false,
                      value: r.id,
                      title: Text(reciterLabel(context, r)),
                      subtitle: Text(
                        l.reciterOfRiwaya(
                          riwayaName(l, Riwaya.values.byName(r.riwaya)),
                        ),
                      ),
                      secondary: ReciterAvatar(
                        id: r.id,
                        name: reciterLabel(context, r),
                        size: 36,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        if (playing && !s.timed) ...[
          Text(l.noTiming, style: hint),
          const SizedBox(height: 8),
        ],
        if (playing && s.timed) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: c.repeatCurrentVerse,
                  child: Text(l.repeatVerse),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: s.rangeTo == null ? null : c.clearRange,
                  child: Text(l.playToEnd),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (!playing || s.timed) ...[
          Semantics(header: true, child: Text(l.repeatLabel, style: title)),
          Text(l.repeatHint, style: hint),
          const SizedBox(height: 6),
          chips<int>(
            [
              for (final n in [1, 2, 3, 5, 10]) (n, l.repeatTimes(digits(n))),
              (0, l.repeatForever),
            ],
            s.repeat,
            c.setRepeat,
          ),
          const SizedBox(height: 12),
          Semantics(header: true, child: Text(l.silenceLabel, style: title)),
          const SizedBox(height: 6),
          chips<int>(
            [
              (0, l.silenceNone),
              for (final n in [2, 5, 10, 20]) (n, l.seconds(digits(n))),
            ],
            s.silence.inSeconds,
            (n) => c.setSilence(Duration(seconds: n)),
          ),
          const SizedBox(height: 12),
        ],
        // A sleep timer belongs to one listening, so it is set only then.
        if (playing) ...[
          Semantics(header: true, child: Text(l.sleepLabel, style: title)),
          const SizedBox(height: 6),
          chips<int>(
            [
              (0, l.sleepOff),
              for (final n in [15, 30, 60]) (n, l.minutes(digits(n))),
              (-1, l.sleepSurahEnd),
            ],
            sleepKey,
            (n) => c.setSleep(
              n == 0
                  ? null
                  : n < 0
                  ? const SleepAtSurahEnd()
                  : SleepAfter(Duration(minutes: n)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Semantics(header: true, child: Text(l.versePauseLabel, style: title)),
        Text(l.versePauseHint, style: hint),
        const SizedBox(height: 6),
        chips<int>(
          [
            (0, l.versePauseAsRecorded),
            (1000, l.versePauseSecond),
            (500, l.versePauseHalf),
          ],
          settings.versePause,
          ref.read(settingsProvider.notifier).setVersePause,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.followRecitation),
          value: settings.followRecitation,
          onChanged: ref.read(settingsProvider.notifier).setFollowRecitation,
        ),
        OutlinedButton.icon(
          onPressed: () {
            if (inSheet) Navigator.pop(context);
            context.push('/mushaf/audio');
          },
          icon: const Icon(Icons.download_outlined),
          label: Text(l.audioDownloads),
        ),
        const SizedBox(height: 8),
        Text(l.audioCredit, style: hint.copyWith(fontSize: 11)),
      ],
    );
  }
}
