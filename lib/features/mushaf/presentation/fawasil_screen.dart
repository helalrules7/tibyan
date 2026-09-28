import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../mushaf_providers.dart';
import 'mushaf_screen.dart';
import 'navigation.dart';

/// The last reading position and the reader's named bookmarks (fawasil).
class FawasilScreen extends ConsumerWidget {
  const FawasilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final surahs = ref.watch(surahsProvider).value;
    final last = ref.watch(readingPositionProvider).value;
    final sets = ref.watch(bookmarkSetsProvider).value;
    String name(int surah) =>
        surahs == null ? '' : surahName(context, surahs[surah - 1]);

    return Scaffold(
      appBar: AppBar(title: Text(l.fawasilTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (last != null)
            Card(
              child: ListTile(
                leading: Icon(Icons.history, color: t.goldText),
                title: Text(l.lastPosition),
                subtitle: Text(
                  l.fasilLastAt(
                    name(last.surah),
                    '${last.ayah}',
                    '${last.page}',
                  ),
                ),
                onTap: () =>
                    openVerse(context, ref, surah: last.surah, ayah: last.ayah),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            l.yourFawasil,
            style: TextStyle(color: t.goldText, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          if (sets != null && sets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                '${l.noFawasil}\n${l.fasilHint}',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.muted, height: 1.7),
              ),
            ),
          for (final s in sets ?? const [])
            Card(
              child: ListTile(
                leading: Icon(Icons.bookmark, color: Color(s.color)),
                title: Text(s.name),
                subtitle: Text(
                  l.fasilLastAt(name(s.surah), '${s.ayah}', '${s.page}'),
                ),
                onTap: () =>
                    openVerse(context, ref, surah: s.surah, ayah: s.ayah),
                trailing: IconButton(
                  tooltip: l.delete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (d) => AlertDialog(
                        title: Text(s.name),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(d).pop(false),
                            child: Text(l.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(d).pop(true),
                            child: Text(l.delete),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await ref
                          .read(userDatabaseProvider)
                          .deleteBookmarkSet(s.id);
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
