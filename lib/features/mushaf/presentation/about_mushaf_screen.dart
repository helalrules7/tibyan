import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../audio/recitation.dart';
import '../../../l10n/app_localizations.dart';
import '../mushaf_providers.dart';
import 'source_names.dart';

/// Where the text and pages come from, their licences, and open review notes.
class AboutMushafScreen extends ConsumerWidget {
  const AboutMushafScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final sources = ref.watch(sourcesProvider).value;
    final reviewCount = ref.watch(reviewNoteCountProvider).value;
    final reciters = {
      for (final r in ref.watch(recitersProvider).value ?? const [])
        r.id: Localizations.localeOf(context).languageCode == 'ar'
            ? r.nameAr
            : r.nameEn,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l.aboutMushafTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.aboutMushafIntro, style: const TextStyle(height: 1.7)),
          const SizedBox(height: 12),
          if (reviewCount != null && reviewCount > 0)
            Card(
              child: ListTile(
                leading: Icon(Icons.rate_review_outlined, color: t.goldText),
                title: Text(l.reviewNotesTitle),
                subtitle: Text(
                  l.reviewNotesBody('$reviewCount'),
                  style: const TextStyle(height: 1.6),
                ),
              ),
            ),
          for (final s in sources ?? const [])
            Card(
              child: Builder(
                builder: (context) {
                  final named = sourceText(
                    s.key,
                    Localizations.localeOf(context).languageCode,
                  );
                  return ExpansionTile(
                    title: Text(named?.title ?? s.title),
                    subtitle: Text(
                      named?.publisher ?? s.publisher,
                      style: TextStyle(color: t.muted),
                    ),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      if (s.version != null) Text(l.versionShort(s.version!)),
                      Text(l.licenseLabel(named?.license ?? s.license)),
                      SelectableText(s.url, style: TextStyle(color: t.accent)),
                      const SizedBox(height: 6),
                      Text(
                        named?.credit ?? s.attribution,
                        style: TextStyle(color: t.muted),
                      ),
                      if (s.notice != null) ...[
                        const SizedBox(height: 8),
                        // The source's notice, shown exactly as published.
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: SelectableText(
                            s.notice!,
                            style: const TextStyle(fontSize: 12, height: 1.5),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          for (final s in bundledSources)
            Card(
              child: Builder(
                builder: (context) {
                  final named = sourceText(
                    s.key,
                    Localizations.localeOf(context).languageCode,
                  )!;
                  return ExpansionTile(
                    title: Text(named.title),
                    subtitle: Text(
                      named.publisher,
                      style: TextStyle(color: t.muted),
                    ),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Text(l.versionShort(s.version.substring(0, 7))),
                      Text(l.licenseLabel(named.license)),
                      SelectableText(
                        s.url,
                        style: TextStyle(color: t.goldText),
                      ),
                      const SizedBox(height: 6),
                      Text(named.credit, style: TextStyle(color: t.muted)),
                    ],
                  );
                },
              ),
            ),
          Card(
            child: ExpansionTile(
              title: Text(l.reciterPhotosTitle),
              subtitle: Text(
                l.reciterPhotosNote,
                style: TextStyle(color: t.muted),
              ),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                for (final c in reciterPhotoCredits) ...[
                  const SizedBox(height: 8),
                  Text(
                    reciters[c.reciter] ?? '${c.reciter}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    l.reciterPhotoCredit(
                      c.author ?? l.unknownAuthor,
                      c.license,
                    ),
                    style: TextStyle(color: t.muted),
                  ),
                  SelectableText(c.url, style: TextStyle(color: t.accent)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
