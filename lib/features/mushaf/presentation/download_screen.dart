import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/page_pack.dart';
import '../mushaf_providers.dart';

/// One-time download of the mushaf pages (about 65 MB), with resume.
class DownloadScreen extends ConsumerWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final p = ref.watch(pageDownloadProvider);
    final spec = ref.watch(pageInstallerProvider).spec;
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
              label: status,
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
            const SizedBox(height: 8),
            if (p.phase != PackPhase.installed)
              TextButton(
                onPressed: () => context.go('/mushaf/continuous'),
                child: Text(l.readWhileDownloading),
              ),
            const SizedBox(height: 16),
            Text(
              spec.format == PackFormat.pngQuranCom
                  ? l.pagesCreditOld
                  : l.pagesCredit,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
