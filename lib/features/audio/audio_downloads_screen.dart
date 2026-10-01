import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/content_database.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/mushaf_providers.dart';
import '../mushaf/presentation/mushaf_screen.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart';
import 'player_bar.dart';
import 'recitation.dart';
import 'reciter_avatar.dart';

/// Download the chosen reciter's surahs for listening offline. Surahs
/// saved while listening are listed here too, as downloaded.
class AudioDownloadsScreen extends ConsumerStatefulWidget {
  const AudioDownloadsScreen({super.key});

  @override
  ConsumerState<AudioDownloadsScreen> createState() =>
      _AudioDownloadsScreenState();
}

class _AudioDownloadsScreenState extends ConsumerState<AudioDownloadsScreen> {
  final _busy = <int>{};
  final _failed = <int>{};
  bool _all = false;

  Future<void> _download(ReciterRow r, int surah) async {
    setState(() {
      _busy.add(surah);
      _failed.remove(surah);
    });
    try {
      await ref
          .read(audioFilesProvider)
          .download(
            r,
            surah,
            client: ref.read(audioHttpClientProvider),
            urls: ref.read(audioHostsProvider.notifier).urls(r, surah),
          );
    } catch (_) {
      _failed.add(surah);
    }
    if (mounted) setState(() => _busy.remove(surah));
  }

  Future<void> _downloadAll(ReciterRow r) async {
    setState(() => _all = true);
    final files = ref.read(audioFilesProvider);
    for (var s = 1; s <= 114 && _all && mounted; s++) {
      if (!files.has(r.id, s)) await _download(r, s);
    }
    if (mounted) setState(() => _all = false);
  }

  @override
  Widget build(BuildContext context) {
    final reciterId = ref.watch(settingsProvider.select((s) => s.reciterId));
    final reciters = ref.watch(recitersProvider).value;
    final surahs = ref.watch(surahsProvider).value;
    final reciter = reciters?.where((r) => r.id == reciterId).firstOrNull;
    if (reciter == null || surahs == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final files = ref.watch(audioFilesProvider);

    // Saving while listening also ends here: follow it.
    return ValueListenableBuilder<int>(
      valueListenable: files.changes,
      builder: (context, _, _) =>
          _build(context, reciter, surahs, files.downloaded(reciter.id)),
    );
  }

  Widget _build(
    BuildContext context,
    ReciterRow reciter,
    List<SurahRow> surahs,
    Set<int> have,
  ) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final files = ref.read(audioFilesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.audioDownloads)),
      body: Column(
        children: [
          ListTile(
            leading: ReciterAvatar(
              id: reciter.id,
              name: reciterLabel(context, reciter),
              size: 38,
            ),
            title: Text(reciterLabel(context, reciter)),
            subtitle: Text(
              '${l.audioDownloaded}: ${digits(have.length)} / ${digits(114)}',
            ),
            trailing: _all
                ? TextButton(
                    onPressed: () => setState(() => _all = false),
                    child: Text(l.pause),
                  )
                : FilledButton.tonal(
                    onPressed: have.length == 114
                        ? null
                        : () => _downloadAll(reciter),
                    child: Text(l.downloadAll),
                  ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: 114,
              itemBuilder: (context, i) {
                final n = i + 1;
                final done = have.contains(n);
                return ListTile(
                  dense: true,
                  leading: Text(digits(n), style: TextStyle(color: t.muted)),
                  title: Text(surahName(context, surahs[i])),
                  trailing:
                      _busy.contains(n) || files.downloading(reciter.id, n)
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : done
                      ? IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .deleteButtonTooltip,
                          icon: Icon(Icons.check_circle, color: t.control),
                          onPressed: () =>
                              setState(() => files.delete(reciter.id, n)),
                        )
                      : IconButton(
                          tooltip: l.audioDownloads,
                          icon: Icon(
                            _failed.contains(n)
                                ? Icons.error_outline
                                : Icons.download_outlined,
                          ),
                          onPressed: () => _download(reciter, n),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
