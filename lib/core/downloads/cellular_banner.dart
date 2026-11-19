import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../settings/settings_controller.dart';
import '../theme/interface_style.dart';
import 'background_downloads.dart';
import 'cellular_policy.dart';

/// Shows, over every screen, that downloads wait because the phone is on
/// mobile data, with the choice to go on over it or wait for Wi‑Fi.
class CellularDownloadsBanner extends ConsumerWidget {
  const CellularDownloadsBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!cellularPolicyApplies) return child;
    final state = ref.watch(cellularPolicyProvider);
    final always = ref.watch(
      settingsProvider.select((s) => s.cellularDownloads),
    );
    final tasks = ref.watch(backgroundDownloadsProvider).tasks;
    return ValueListenableBuilder<Map<String, TaskRecord>>(
      valueListenable: tasks,
      builder: (context, records, _) {
        final pending = pendingOf(records.values);
        final show = showCellularBanner(
          applies: true,
          state: state,
          alwaysAllowed: always,
          pending: pending.count,
        );
        return Stack(
          children: [
            child,
            if (show)
              Positioned(
                left: 12,
                right: 12,
                top: MediaQuery.paddingOf(context).top + 8,
                child: _Card(bytes: pending.bytes),
              ),
          ],
        );
      },
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card({required this.bytes});

  final int bytes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final look = context.look;
    final mb = (bytes / (1024 * 1024)).ceil();
    final policy = ref.read(cellularPolicyProvider.notifier);
    return Dismissible(
      key: const ValueKey('cellular-banner'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => policy.dismiss(),
      child: Semantics(
        liveRegion: true,
        child: Material(
          color: look.surface,
          elevation: 6,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.signal_cellular_alt, color: look.goldText),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.cellularPausedTitle,
                        style: TextStyle(
                          color: look.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: policy.dismiss,
                      icon: Icon(Icons.close, color: look.sub),
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonTooltip,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  bytes > 0
                      ? l.cellularPausedBody('$mb')
                      : l.cellularPausedBodyNoSize,
                  style: TextStyle(color: look.sub),
                ),
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: policy.dismiss,
                      child: Text(l.cellularWait),
                    ),
                    FilledButton(
                      onPressed: policy.allowForNow,
                      child: Text(l.cellularContinue),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
