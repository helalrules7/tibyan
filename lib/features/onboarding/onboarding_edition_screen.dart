import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../mushaf/presentation/widgets/download_all_button.dart';
import '../mushaf/presentation/widgets/edition_badge.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/data/page_pack.dart';

/// First launch, screen 2: which Madina mushaf edition to read.
class OnboardingEditionScreen extends ConsumerWidget {
  const OnboardingEditionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final t = context.tokens.colors;

    Future<void> finish(String to) async {
      await ctrl.completeOnboarding();
      if (context.mounted) context.go(to);
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Text(
              l.appTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ArefRuqaa',
                fontSize: 36,
                color: t.goldText,
                height: 1.2,
              ),
            ),
            Text(
              l.onbEditionTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              l.onbStyleHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.muted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            RadioGroup<MushafEdition>(
              groupValue: settings.edition,
              onChanged: (v) => v == null ? null : ctrl.setEdition(v),
              child: Column(
                children: [
                  _EditionCard(
                    value: MushafEdition.madina1441,
                    title: l.editionNew,
                    body: l.editionNewDesc,
                    tag: l.defaultTag,
                  ),
                  const SizedBox(height: 12),
                  _EditionCard(
                    value: MushafEdition.madina1405,
                    title: l.editionOld,
                    body: l.editionOldDesc,
                  ),
                  const SizedBox(height: 12),
                  _EditionCard(
                    value: MushafEdition.shamarly,
                    title: l.editionShamarly,
                    body: l.editionShamarlyDesc,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.download_outlined, color: t.goldText),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.pagesDownloadNote(
                          (PagePackSpec.of(settings.edition).bytes / 1e6)
                              .round()
                              .toString(),
                        ),
                        style: const TextStyle(height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const DownloadAllButton(),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () => finish('/mushaf/download'),
              child: Text(l.continueLabel),
            ),
            TextButton(
              onPressed: () => finish('/mushaf/continuous'),
              child: Text('${l.skipLabel}: ${l.readContinuousNow}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditionCard extends StatelessWidget {
  const _EditionCard({
    required this.value,
    required this.title,
    required this.body,
    this.tag,
  });

  final MushafEdition value;
  final String title;
  final String body;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    final selected =
        RadioGroup.maybeOf<MushafEdition>(context)?.groupValue == value;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? t.control : t.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: RadioListTile<MushafEdition>(
        value: value,
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(body, style: TextStyle(color: t.muted, height: 1.5)),
            EditionBadge(edition: value),
            if (tag != null) ...[
              const SizedBox(height: 6),
              Text(
                tag!,
                style: TextStyle(
                  color: t.control,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
