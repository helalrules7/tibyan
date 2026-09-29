import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/page_pack.dart';
import '../../mushaf_providers.dart';
import 'illuminated_frame.dart';

/// Whether an edition's pages are on this device, shown beside its name.
class EditionBadge extends ConsumerWidget {
  const EditionBadge({super.key, required this.edition});

  final MushafEdition edition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final here = ref.watch(installedEditionsProvider).contains(edition);
    final size = (PagePackSpec.of(edition).bytes / 1e6).round();
    final color = here ? t.control : t.muted;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: here ? t.control.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              here ? Icons.check_circle : Icons.cloud_download_outlined,
              size: 13,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              here ? l.editionOnDevice : l.editionNotDownloaded(digits(size)),
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
