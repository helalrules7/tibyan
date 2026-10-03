import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/page_pack.dart';
import '../mushaf_providers.dart';
import 'widgets/illuminated_frame.dart';

/// Every edition's download at once, each with its own progress, after
/// «download all». The downloads go on when the reader leaves.
class DownloadAllScreen extends ConsumerWidget {
  const DownloadAllScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    const editions = MushafEdition.values;
    final done = editions
        .where(
          (e) =>
              ref.watch(editionDownloadProvider(e)).phase ==
              PackPhase.installed,
        )
        .length;

    return Scaffold(
      appBar: AppBar(title: Text(l.downloadAllTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                l.downloadAllCount(digits(done), digits(editions.length)),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: t.goldText,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: done / editions.length,
              minHeight: 6,
              semanticsLabel: l.downloadAllTitle,
            ),
            const SizedBox(height: 16),
            for (final e in editions) ...[
              _EditionRow(edition: e),
              const SizedBox(height: 10),
            ],
            if (done < editions.length) ...[
              const SizedBox(height: 6),
              Text(
                l.downloadInBackgroundNote,
                textAlign: TextAlign.center,
                style: TextStyle(color: t.muted, fontSize: 13, height: 1.6),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/mushaf'),
              child: Text(l.doneLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditionRow extends ConsumerWidget {
  const _EditionRow({required this.edition});

  final MushafEdition edition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final p = ref.watch(editionDownloadProvider(edition));
    final ctrl = ref.read(editionDownloadProvider(edition).notifier);
    final spec = PagePackSpec.of(edition);
    String mb(int bytes) => (bytes / 1e6).toStringAsFixed(1);
    final total = p.total > 0 ? p.total : spec.bytes;
    final fraction = switch (p.phase) {
      PackPhase.downloading || PackPhase.idle => p.received / total,
      PackPhase.verifying || PackPhase.installing => null,
      PackPhase.installed => 1.0,
      PackPhase.failed => p.received / total,
    };
    final status = switch (p.phase) {
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
    final action = switch (p.phase) {
      PackPhase.installed => Icon(
        Icons.check_circle,
        color: t.control,
        semanticLabel: l.downloadDone,
      ),
      PackPhase.verifying || PackPhase.installing => null,
      PackPhase.downloading => IconButton(
        tooltip: l.downloadPause,
        onPressed: ctrl.pause,
        icon: const Icon(Icons.pause),
      ),
      PackPhase.failed => IconButton(
        tooltip: l.downloadRetry,
        onPressed: ctrl.start,
        icon: const Icon(Icons.refresh),
      ),
      PackPhase.idle => IconButton(
        tooltip: p.received > 0 ? l.downloadResume : l.downloadStart,
        onPressed: ctrl.start,
        icon: const Icon(Icons.play_arrow),
      ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                label: '${editionName(l, edition)}. $spoken',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      editionName(l, edition),
                      style: TextStyle(
                        color: t.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: fraction, minHeight: 6),
                    const SizedBox(height: 6),
                    Text(
                      status,
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: Center(child: action ?? const SizedBox.shrink()),
            ),
          ],
        ),
      ),
    );
  }
}
