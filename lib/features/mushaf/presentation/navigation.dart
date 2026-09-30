import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/mushaf_repository.dart';
import '../mushaf_providers.dart';

var _visit = 0;

/// The page view's location for [page] (and a verse to select). Each call
/// gives a new location: going to the one already open would otherwise
/// do nothing, though the reader may have turned the page since.
String mushafLocation(int page, {int? surah, int? ayah}) =>
    '/mushaf?page=$page'
    '${surah == null || ayah == null ? '' : '&s=$surah&a=$ayah'}'
    '&v=${++_visit}';

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
  context.go(mushafLocation(row.pageIn(ref.read(editionProvider))));
}

/// Opens a page of the edition being read.
Future<void> openPage(BuildContext context, WidgetRef ref, int page) async {
  context.go(mushafLocation(page));
}
