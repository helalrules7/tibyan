import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../audio/recitation.dart';
import '../../core/settings/app_settings.dart';
import '../mushaf/data/page_pack.dart';
import '../mushaf/mushaf_providers.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import 'storage.dart';

final _storageProvider = FutureProvider.autoDispose<List<StorageEntry>>((ref) {
  ref.watch(packInstallsProvider);
  return scanStorage(ref.watch(packRootProvider).path);
});

/// «التخزين والتنزيلات»: what the app downloaded, with sizes, and a way to
/// delete it (everything downloaded can be downloaded again).
class StorageScreen extends ConsumerWidget {
  const StorageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final entries = ref.watch(_storageProvider);
    final digits = NumberFormatter(Localizations.localeOf(context));
    final reciters = ref.watch(allRecitersProvider).value ?? const [];

    String size(int bytes) => l.storageSize(
      digits.decimal((bytes / 1e6).toStringAsFixed(bytes < 1e7 ? 1 : 0)),
    );

    String name(StorageEntry e) {
      switch (e.kind) {
        case StorageKind.pack:
          if (e.id == PagePackSpec.semantic.id) return l.storageSemantic;
          for (final ed in MushafEdition.values) {
            if (PagePackSpec.of(ed).id == e.id) return editionName(l, ed);
          }
          return e.id;
        case StorageKind.audio:
          final r = reciters.where((r) => '${r.id}' == e.id).firstOrNull;
          if (r == null) return '${l.storageUnknown} (${e.id})';
          return l.storageAudioOf(
            Localizations.localeOf(context).languageCode == 'ar'
                ? r.nameAr
                : r.nameEn,
          );
        case StorageKind.timing:
          return l.storageTiming;
        case StorageKind.partial:
          return l.storagePartial;
      }
    }

    // The edition that ships with the app is put back at launch.
    bool bundled(StorageEntry e) =>
        e.kind == StorageKind.pack && e.id == PagePackSpec.madina1441.id;

    Future<void> remove(StorageEntry e) async {
      final messenger = ScaffoldMessenger.of(context);
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(l.storageDeleteAsk(name(e), size(e.bytes))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.delete),
            ),
          ],
        ),
      );
      if (ok != true) return;
      final freed = deleteEntry(e);
      ref.read(audioFilesProvider).changes.value++;
      ref.read(packInstallsProvider.notifier).changed();
      ref.invalidate(_storageProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(l.storageFreed(size(freed)))),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.storageTitle)),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const SizedBox.shrink(),
        data: (list) {
          final total = list.fold<int>(0, (s, e) => s + e.bytes);
          final sorted = [...list]
            ..sort((a, b) {
              final k = a.kind.index.compareTo(b.kind.index);
              return k != 0 ? k : b.bytes.compareTo(a.bytes);
            });
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(l.storageIntro, style: TextStyle(color: t.muted)),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  l.storageTotal(size(total)),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (sorted.isEmpty) Text(l.storageEmpty),
              for (final e in sorted)
                Card(
                  child: ListTile(
                    title: Text(name(e)),
                    subtitle: Text(
                      e.kind == StorageKind.partial
                          ? '${size(e.bytes)} · ${l.storagePartialHint}'
                          : bundled(e)
                          ? '${size(e.bytes)} · ${l.storageBundled}'
                          : size(e.bytes),
                      style: TextStyle(color: t.muted),
                    ),
                    trailing: bundled(e)
                        ? null
                        : e.kind == StorageKind.partial
                        ? TextButton(
                            onPressed: () => remove(e),
                            child: Text(l.storageClean),
                          )
                        : IconButton(
                            tooltip: '${l.delete} ${name(e)}',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => remove(e),
                          ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
