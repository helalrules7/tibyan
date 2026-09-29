import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/content_database.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/mushaf_providers.dart';
import '../mushaf/presentation/mushaf_screen.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart';
import 'recitation.dart';

String reciterLabel(BuildContext context, ReciterRow r) {
  final l = AppLocalizations.of(context);
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  final style = r.style == 'mujawwad' ? l.mujawwad : l.murattal;
  return '${ar ? r.nameAr : r.nameEn} · $style';
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
    final reciterId = ref.watch(settingsProvider.select((x) => x.reciterId));
    final reciter = ref
        .watch(recitersProvider)
        .value
        ?.where((r) => r.id == reciterId)
        .firstOrNull;
    final surah = surahs == null ? '' : surahName(context, surahs[s.surah - 1]);
    final where = s.ayah == null
        ? l.surahWord(surah)
        : '${l.surahWord(surah)} · ${digits(s.ayah!)}';
    final repeating = s.rangeTo != null && s.repeat != 1;
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
                      Text(
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
                      ),
                    ),
                  )
                : IconButton.filled(
                    tooltip: s.playing ? l.pause : l.resume,
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

Future<void> showPlayerSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _PlayerSheet(),
    );

class _PlayerSheet extends ConsumerWidget {
  const _PlayerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final s = ref.watch(recitationProvider);
    final c = ref.read(recitationProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final reciters = ref.watch(recitersProvider).value ?? const [];
    final title = Theme.of(context).textTheme.titleSmall;

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

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(l.reciterLabel, style: title),
            RadioGroup<int>(
              groupValue: settings.reciterId,
              onChanged: (id) async {
                if (id == null) return;
                await ref.read(settingsProvider.notifier).setReciter(id);
                if (s.active) {
                  await c.play(
                    s.surah,
                    from: s.ayah,
                    to: s.rangeTo,
                    repeat: s.repeat,
                  );
                }
              },
              child: Column(
                children: [
                  for (final r in reciters)
                    RadioListTile<int>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: r.id,
                      title: Text(reciterLabel(context, r)),
                    ),
                ],
              ),
            ),
            if (s.active && !s.timed) ...[
              Text(l.noTiming, style: TextStyle(color: t.muted, fontSize: 12)),
              const SizedBox(height: 8),
            ],
            if (s.timed) ...[
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
              Text(l.repeatLabel, style: title),
              const SizedBox(height: 6),
              chips<int>(
                [
                  for (final n in [1, 2, 3, 5, 10])
                    (n, l.repeatTimes(digits(n))),
                  (0, l.repeatForever),
                ],
                s.repeat,
                c.setRepeat,
              ),
              const SizedBox(height: 12),
              Text(l.silenceLabel, style: title),
              const SizedBox(height: 6),
              chips<int>(
                [
                  (0, l.silenceNone),
                  for (final n in [2, 5, 10, 20]) (n, l.seconds(digits(n))),
                ],
                s.silence.inSeconds,
                (n) => c.setSilence(Duration(seconds: n)),
              ),
            ],
            const SizedBox(height: 12),
            Text(l.sleepLabel, style: title),
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.followRecitation),
              value: settings.followRecitation,
              onChanged: ref
                  .read(settingsProvider.notifier)
                  .setFollowRecitation,
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/mushaf/audio');
              },
              icon: const Icon(Icons.download_outlined),
              label: Text(l.audioDownloads),
            ),
            const SizedBox(height: 8),
            Text(l.audioCredit, style: TextStyle(color: t.muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
