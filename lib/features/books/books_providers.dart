import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/flags/feature_flags.dart';
import '../../core/settings/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/data/page_pack.dart';
import '../mushaf/mushaf_providers.dart';
import 'data/book_pack.dart';

/// The reviewed book packs the app knows (overridden in tests).
final bookPackSpecsProvider = Provider<List<BookPackSpec>>(
  (ref) => BookPackSpec.all,
);

PagePackInstaller bookInstaller(Directory root, BookPackSpec spec) =>
    PagePackInstaller(root: root, spec: spec.pack);

/// The reviewed book packs on this device, opened read-only. Only packs
/// from [bookPackSpecsProvider] count: each was checked against its
/// SHA-256 when it was installed. A pack that cannot be opened is left
/// out (the storage screen still lists it, so it can be deleted).
final installedBookPacksProvider = Provider<List<BookPack>>((ref) {
  ref.watch(packInstallsProvider);
  final root = ref.watch(packsDirProvider);
  final packs = <BookPack>[];
  for (final spec in ref.watch(bookPackSpecsProvider)) {
    final installer = bookInstaller(root, spec);
    if (!installer.isInstalled) continue;
    try {
      packs.add(
        BookPack.open(
          File(p.join(installer.dir.path, bookPackFile)),
          spec: spec,
        ),
      );
    } on Object {
      // Damaged or of a newer format: not shown.
    }
  }
  ref.onDispose(() {
    for (final pack in packs) {
      pack.close();
    }
  });
  return packs;
});

/// What one book section of the app shows: the kind of book, the flag
/// that hides it (null: shown whenever a reviewed pack is installed), and
/// which of the book's entries it takes.
class BookSectionSpec {
  const BookSectionSpec({
    required this.kind,
    required this.feature,
    this.entryKinds,
    this.parentKind,
    this.showRange = false,
    this.firstVerseOnly = const {},
  });

  /// [BookKind].
  final String kind;
  final Feature? feature;

  /// [EntryKind]s shown (null: all).
  final Set<String>? entryKinds;

  /// Each entry is shown under the entry of this kind it belongs to
  /// (al-Damghani's word header above its senses).
  final String? parentKind;

  /// An entry linked to several verses says which ones.
  final bool showRange;

  /// [EntryKind]s shown on the first verse of their link only (a surah's
  /// introduction is linked to the whole surah).
  final Set<String> firstVerseOnly;

  static const asbab = BookSectionSpec(
    kind: BookKind.asbabNuzul,
    feature: Feature.asbabNuzul,
  );

  /// The tafsir screen already lets the reader choose tafsirs: a book
  /// tafsir is one more choice once its reviewed pack is installed.
  static const tafsir = BookSectionSpec(
    kind: BookKind.tafsir,
    feature: null,
    showRange: true,
    firstVerseOnly: {EntryKind.surahIntro},
  );

  static const munasabat = BookSectionSpec(
    kind: BookKind.munasabat,
    feature: Feature.munasabat,
    showRange: true,
    firstVerseOnly: {EntryKind.surahIntro},
  );

  static const wujuh = BookSectionSpec(
    kind: BookKind.wujuhNazair,
    feature: Feature.wujuhNazair,
    entryKinds: {EntryKind.wajh},
    parentKind: EntryKind.word,
  );

  /// On: its flag (if any) is on. The section still needs a pack.
  bool isOn(FeatureFlags flags) => feature == null || flags.isOn(feature!);
}

/// Entries of one book section for a (Hafs) verse: [source] keeps one
/// book, [word] (1-based) one word of the verse.
typedef BookQuery = ({
  BookSectionSpec spec,
  int surah,
  int ayah,
  String? source,
  int? word,
});

/// The reviewed entries of a book section for a verse, from the installed
/// packs; empty when the section's flag is off.
final bookEntriesProvider = Provider.autoDispose
    .family<List<BookEntry>, BookQuery>((ref, q) {
      if (!q.spec.isOn(ref.watch(featureFlagsProvider))) return const [];
      return [
        for (final pack in ref.watch(installedBookPacksProvider))
          for (final e in pack.entriesFor(
            q.surah,
            q.ayah,
            kind: q.spec.kind,
            source: q.source,
            entryKinds: q.spec.entryKinds,
            word: q.word,
          ))
            if (!q.spec.firstVerseOnly.contains(e.kind) ||
                e.link?.ayahFrom == q.ayah)
              e,
      ];
    });

/// The books of [kind] in the installed reviewed packs.
final installedBookSourcesProvider = Provider.autoDispose
    .family<List<BookSource>, String>(
      (ref, kind) => [
        for (final pack in ref.watch(installedBookPacksProvider))
          ...pack.sourcesOf(kind),
      ],
    );

/// The entry [entry] belongs under in its pack (see [BookPack.parentOf]).
BookEntry? bookParentOf(
  List<BookPack> packs,
  BookEntry entry, {
  required String kind,
}) {
  for (final pack in packs) {
    if (pack.sources[entry.source.id] != entry.source) continue;
    return pack.parentOf(entry, kind: kind);
  }
  return null;
}

/// The occasions of revelation of a (Hafs) verse from the installed
/// reviewed packs; empty unless [Feature.asbabNuzul] is on.
final asbabProvider = Provider.autoDispose
    .family<List<BookEntry>, ({int surah, int ayah})>(
      (ref, v) => ref.watch(
        bookEntriesProvider((
          spec: BookSectionSpec.asbab,
          surah: v.surah,
          ayah: v.ayah,
          source: null,
          word: null,
        )),
      ),
    );

/// The munasabat of a (Hafs) verse; empty unless [Feature.munasabat] is on.
final munasabatProvider = Provider.autoDispose
    .family<List<BookEntry>, ({int surah, int ayah})>(
      (ref, v) => ref.watch(
        bookEntriesProvider((
          spec: BookSectionSpec.munasabat,
          surah: v.surah,
          ayah: v.ayah,
          source: null,
          word: null,
        )),
      ),
    );

/// Downloads of the book packs, by pack id, run by the system like the
/// page packs.
class BookDownloads extends Notifier<Map<String, PackProgress>> {
  StreamSubscription<(String, PackProgress)>? _sub;

  @override
  Map<String, PackProgress> build() {
    ref.onDispose(() => _sub?.cancel());
    final specs = ref.watch(bookPackSpecsProvider);
    final ids = {for (final s in specs) s.id};
    final packs = ref.read(backgroundPacksProvider);
    _sub = packs.progress.listen((e) {
      if (!ids.contains(e.$1)) return;
      state = {...state, e.$1: e.$2};
      if (e.$2.phase == PackPhase.installed) {
        ref.read(packInstallsProvider.notifier).changed();
      }
    });
    for (final s in specs) {
      unawaited(
        packs
            .stateOf(s.pack)
            .then((p) => state = {...state, s.id: p})
            .catchError((_) => state),
      );
    }
    return const {};
  }

  Future<void> start(BookPackSpec spec) async {
    final l = lookupAppLocalizations(
      ref.read(settingsProvider).locale ?? const Locale('ar'),
    );
    state = {
      ...state,
      spec.id: PackProgress(PackPhase.downloading, total: spec.bytes),
    };
    await ref
        .read(backgroundPacksProvider)
        .enqueue(spec.pack, l.storageBook(spec.title));
  }
}

final bookDownloadsProvider =
    NotifierProvider<BookDownloads, Map<String, PackProgress>>(
      BookDownloads.new,
    );
