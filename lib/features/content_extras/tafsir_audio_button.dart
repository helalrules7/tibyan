import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../audio/recitation.dart';
import 'credits.dart';
import 'verse_audio_index.dart';

/// The label of «استمع للتفسير» for [clip] of [index]; [several] adds the
/// tafsir's name when more than one has the verse.
String tafsirAudioLabel(
  AppLocalizations l,
  String languageCode,
  VerseAudioIndex index,
  VerseAudioClip clip, {
  bool several = false,
}) {
  final what = clip.wholeSurah ? l.tafsirAudioListenSurah : l.tafsirAudioListen;
  return several ? '$what · ${index.title(languageCode)}' : what;
}

/// «استمع للتفسير» for a (Hafs) verse: one button for each tafsir
/// recording that has it, the recording's credit line under it, and pause
/// or resume while it plays. Nothing while [Feature.tafsirAudio] is off or
/// no recording has the verse.
class TafsirAudioButtons extends ConsumerWidget {
  const TafsirAudioButtons({
    super.key,
    required this.surah,
    required this.ayah,
  });

  final int surah;
  final int ayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final found =
        ref
            .watch(tafsirAudioForVerseProvider((surah: surah, ayah: ayah)))
            .value ??
        const [];
    if (found.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final s = ref.watch(recitationProvider);
    final c = ref.read(recitationProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, clip) in found) ...[
          Builder(
            builder: (context) {
              final clipNow = s.clip;
              final mine =
                  s.active &&
                  clipNow != null &&
                  clipNow.standalone &&
                  clipNow.surah == surah &&
                  clipNow.ayah == ayah &&
                  clipNow.titleAr == index.titleAr;
              return OutlinedButton.icon(
                onPressed: mine
                    ? c.toggle
                    : () => c.playTafsir(index, surah, ayah),
                icon: Icon(
                  mine && s.playing ? Icons.pause : Icons.headphones_outlined,
                ),
                label: Text(
                  mine
                      ? (s.playing ? l.pause : l.resume)
                      : tafsirAudioLabel(
                          l,
                          lang,
                          index,
                          clip,
                          several: found.length > 1,
                        ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            contentCredit(index.source, lang),
            style: TextStyle(fontSize: 11, color: t.muted),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
