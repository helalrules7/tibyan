import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/page_pack.dart';
import '../../mushaf_providers.dart';
import 'illuminated_frame.dart';

/// Queues every edition that is not on the device yet, in one tap. Hidden
/// when all of them are there.
class DownloadAllButton extends ConsumerWidget {
  const DownloadAllButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final digits = NumberFormatter(Localizations.localeOf(context));
    final here = ref.watch(installedEditionsProvider);
    final missing = [
      for (final e in MushafEdition.values)
        if (!here.contains(e)) e,
    ];
    if (missing.isEmpty) return const SizedBox.shrink();
    final mb = missing.fold<int>(0, (sum, e) => sum + PagePackSpec.of(e).bytes);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.download_for_offline_outlined),
        label: Text(l.downloadAllEditions(digits((mb / 1e6).round()))),
        onPressed: () async {
          await ref.read(pageDownloadProvider.notifier).startAll();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l.allEditionsQueued)));
        },
      ),
    );
  }
}
