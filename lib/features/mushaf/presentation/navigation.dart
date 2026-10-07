import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../khatma/domain/khatmah.dart' show EntryPoint;
import '../mushaf_providers.dart';

var _visit = 0;

/// The page view's location for [page] (and a verse to select). Each call
/// gives a new location: going to the one already open would otherwise
/// do nothing, though the reader may have turned the page since.
///
/// [entry] says where the reading was opened from (the khatma's reading
/// tracker counts only what comes after the page a search landed on).
String mushafLocation(
  int page, {
  int? surah,
  int? ayah,
  EntryPoint entry = EntryPoint.other,
}) =>
    '/mushaf?page=$page'
    '${surah == null || ayah == null ? '' : '&s=$surah&a=$ayah'}'
    '${entry == EntryPoint.other ? '' : '&entry=${entry.name}'}'
    '&v=${++_visit}';

/// Opens a verse in the page view. Navigation only turns the page; it
/// never selects a verse.
Future<void> openVerse(
  BuildContext context,
  WidgetRef ref, {
  required int surah,
  required int ayah,
  EntryPoint entry = EntryPoint.other,
}) async {
  // [surah]:[ayah] is in Hafs numbers; a riwaya edition opens the page of
  // the riwaya verse that holds it.
  final page = await ref.read(versePageProvider((surah, ayah)).future);
  if (!context.mounted) return;
  context.go(mushafLocation(page, entry: entry));
}

/// Opens a page of the edition being read.
Future<void> openPage(BuildContext context, WidgetRef ref, int page) async {
  context.go(mushafLocation(page));
}

/// A link to a verse (Hafs numbers) that opens the app on it:
/// `tibyan://verse?s=2&a=255`.
Uri verseLink(int surah, int ayah) => Uri(
  scheme: 'tibyan',
  host: 'verse',
  queryParameters: {'s': '$surah', 'a': '$ayah'},
);

/// The source attached to a Khatma link when opening the reader.
EntryPoint khatmaEntryOfLink(Uri uri) {
  if (uri.queryParameters.containsKey('homeWidget') || uri.host == 'action') {
    return EntryPoint.widget;
  }
  if (uri.host == 'khatmah' || uri.host == 'reader') {
    return EntryPoint.khatmahContinue;
  }
  if (uri.host == 'khatma') return EntryPoint.notification;
  return EntryPoint.other;
}

/// The verse a `tibyan://verse` link names, if it is one and is valid.
({int surah, int ayah})? verseOfLink(Uri? uri) {
  if (uri == null || uri.scheme != 'tibyan' || uri.host != 'verse') return null;
  final s = int.tryParse(uri.queryParameters['s'] ?? '');
  final a = int.tryParse(uri.queryParameters['a'] ?? '');
  if (s == null || a == null || s < 1 || s > 114 || a < 1 || a > 286) {
    return null;
  }
  return (surah: s, ayah: a);
}
