import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/page_pack.dart';
import '../mushaf_providers.dart';
import 'widgets/illuminated_frame.dart';

/// One-time download of the chosen edition's pages (65 to 215 MB), with
/// resume. It starts on its own: the reader got here by choosing an
/// edition that is not on the device yet.
class DownloadScreen extends ConsumerStatefulWidget {
  const DownloadScreen({super.key});

  @override
  ConsumerState<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends ConsumerState<DownloadScreen> {
  MushafEdition? _started;

  /// Starts (or resumes) the current edition's download once per edition.
  void _autoStart() {
    final edition = ref.read(chosenEditionProvider);
    if (_started == edition) return;
    _started = edition;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(pageDownloadProvider).phase == PackPhase.idle) {
        ref.read(pageDownloadProvider.notifier).start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _autoStart();
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final p = ref.watch(pageDownloadProvider);
    final spec = PagePackSpec.of(ref.watch(chosenEditionProvider));
    final ctrl = ref.read(pageDownloadProvider.notifier);
    String mb(int bytes) => (bytes / 1e6).toStringAsFixed(1);
    final total = p.total > 0 ? p.total : spec.bytes;
    final fraction = switch (p.phase) {
      PackPhase.downloading || PackPhase.idle => p.received / total,
      PackPhase.verifying || PackPhase.installing => null,
      PackPhase.installed => 1.0,
      PackPhase.failed => p.received / total,
    };
    final status = switch (p.phase) {
      PackPhase.idle when p.received == 0 => l.downloadWifiHint,
      PackPhase.idle ||
      PackPhase.downloading => l.downloadProgress(mb(p.received), mb(total)),
      PackPhase.verifying => l.downloadVerifying,
      PackPhase.installing => l.downloadInstalling,
      PackPhase.installed => l.downloadDone,
      PackPhase.failed => l.downloadFailed(p.error ?? ''),
    };
    // Read aloud in steps of ten percent, not on every piece received.
    final spoken = p.phase == PackPhase.downloading
        ? l.downloadPercentSpoken(
            NumberFormatter(Localizations.localeOf(context))(
              ((fraction ?? 0) * 10).floor() * 10,
            ),
          )
        : status;

    return Scaffold(
      appBar: AppBar(title: Text(l.downloadTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Icon(Icons.menu_book_outlined, size: 56, color: t.goldText),
            const SizedBox(height: 12),
            Text(
              l.pagesDownloadNote(mb(spec.bytes)),
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.7),
            ),
            const SizedBox(height: 24),
            Semantics(
              liveRegion: true,
              label: spoken,
              excludeSemantics: true,
              child: Column(
                children: [
                  LinearProgressIndicator(value: fraction, minHeight: 8),
                  const SizedBox(height: 10),
                  Text(
                    status,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: t.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            switch (p.phase) {
              PackPhase.installed => FilledButton(
                onPressed: () => context.go('/mushaf'),
                child: Text(l.mushafOpen),
              ),
              PackPhase.downloading => OutlinedButton(
                onPressed: ctrl.pause,
                child: Text(l.downloadPause),
              ),
              PackPhase.verifying ||
              PackPhase.installing => const SizedBox.shrink(),
              PackPhase.failed => FilledButton(
                onPressed: ctrl.start,
                child: Text(l.downloadRetry),
              ),
              PackPhase.idle => FilledButton(
                onPressed: ctrl.start,
                child: Text(
                  p.received > 0 ? l.downloadResume : l.downloadStart,
                ),
              ),
            },
            if (p.phase == PackPhase.downloading) ...[
              const SizedBox(height: 12),
              Text(
                l.downloadInBackgroundNote,
                textAlign: TextAlign.center,
                style: TextStyle(color: t.muted, fontSize: 13, height: 1.6),
              ),
            ],
            const SizedBox(height: 8),
            if (p.phase != PackPhase.installed)
              TextButton(
                onPressed: () => context.go('/mushaf'),
                child: Text(l.readInMadinaWhileDownloading),
              ),
            const SizedBox(height: 16),
            Text(
              switch (spec.format) {
                PackFormat.svgXz => l.pagesCredit,
                PackFormat.pngQuranCom => l.pagesCreditOld,
                PackFormat.pngShamarly => l.pagesCreditShamarly,
                // Not an edition: never shown here.
                PackFormat.semantic || PackFormat.book => '',
              },
              textAlign: TextAlign.center,
              style: TextStyle(color: t.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown over the pages while the chosen edition is still downloading and
/// the new Madina edition is read meanwhile. Tapping it opens the download.
class DownloadingBanner extends ConsumerWidget {
  const DownloadingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Nothing started the chosen edition's download yet: start it.
    if (ref.watch(pageDownloadProvider).phase == PackPhase.idle &&
        ref.read(pageDownloadProvider).received == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(pageDownloadProvider).phase == PackPhase.idle) {
          ref.read(pageDownloadProvider.notifier).start();
        }
      });
    }
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final p = ref.watch(pageDownloadProvider);
    final chosen = ref.watch(chosenEditionProvider);
    final percent = (p.fraction * 100).clamp(0, 100).round();
    return Material(
      color: t.paper,
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      child: Semantics(
        button: true,
        label: l.downloadingBanner(editionName(l, chosen), digits(percent)),
        excludeSemantics: true,
        onTap: () => context.push('/mushaf/download'),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/mushaf/download'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.downloadingBanner(editionName(l, chosen), digits(percent)),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: t.ink),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: p.phase == PackPhase.downloading ? p.fraction : null,
                  minHeight: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
