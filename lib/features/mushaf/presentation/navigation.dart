import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../mushaf_providers.dart';

/// Opens a verse in the page view when the pages are installed,
/// otherwise in the continuous view.
void openVerse(
  BuildContext context,
  WidgetRef ref, {
  required int surah,
  required int ayah,
  required int page,
}) {
  if (ref.read(pagesInstalledProvider)) {
    context.go('/mushaf?page=$page&s=$surah&a=$ayah');
  } else {
    context.go('/mushaf/continuous?s=$surah&a=$ayah');
  }
}
