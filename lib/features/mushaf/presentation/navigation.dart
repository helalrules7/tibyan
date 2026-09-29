import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/mushaf_repository.dart';
import '../mushaf_providers.dart';

/// Opens a verse in the page view of the chosen edition when its pages are
/// installed, otherwise in the continuous view.
Future<void> openVerse(
  BuildContext context,
  WidgetRef ref, {
  required int surah,
  required int ayah,
}) async {
  if (!ref.read(pagesInstalledProvider)) {
    context.go('/mushaf/continuous?s=$surah&a=$ayah');
    return;
  }
  final row = await ref.read(mushafRepositoryProvider).ayah(surah, ayah);
  if (!context.mounted) return;
  final page = row.pageIn(ref.read(editionProvider));
  // Navigation only turns the page; it never selects a verse.
  context.go('/mushaf?page=$page');
}

/// Opens a page of the chosen edition, or, while its pages are not
/// installed, the first verse that starts on it in the continuous view.
Future<void> openPage(BuildContext context, WidgetRef ref, int page) async {
  if (ref.read(pagesInstalledProvider)) {
    context.go('/mushaf?page=$page');
    return;
  }
  final edition = ref.read(editionProvider);
  final ayahs = await ref.read(pageAyahsProvider(page).future);
  if (!context.mounted || ayahs.isEmpty) return;
  // A Shamarly page can open with the end of a verse from the page before.
  final a = ayahs.firstWhere(
    (a) => a.pageIn(edition) == page,
    orElse: () => ayahs.first,
  );
  context.go('/mushaf/continuous?s=${a.surah}&a=${a.number}');
}
