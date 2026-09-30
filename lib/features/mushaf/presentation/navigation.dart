import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/mushaf_repository.dart';
import '../mushaf_providers.dart';

/// Opens a verse in the page view. Navigation only turns the page; it
/// never selects a verse.
Future<void> openVerse(
  BuildContext context,
  WidgetRef ref, {
  required int surah,
  required int ayah,
}) async {
  final row = await ref.read(mushafRepositoryProvider).ayah(surah, ayah);
  if (!context.mounted) return;
  context.go('/mushaf?page=${row.pageIn(ref.read(editionProvider))}');
}

/// Opens a page of the edition being read.
Future<void> openPage(BuildContext context, WidgetRef ref, int page) async {
  context.go('/mushaf?page=$page');
}
