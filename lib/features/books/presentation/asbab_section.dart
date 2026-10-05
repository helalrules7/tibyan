import 'package:flutter/widgets.dart';

import '../books_providers.dart';
import 'book_section.dart';

export 'book_section.dart' show BookEntryCard, bookCitation;

/// Opens «أسباب النزول» of a (Hafs) verse in a sheet.
Future<void> showAsbabSheet(
  BuildContext context, {
  required int surah,
  required int ayah,
}) => showBookSheet(
  context,
  spec: BookSectionSpec.asbab,
  surah: surah,
  ayah: ayah,
);

/// «أسباب النزول» of one verse: the [BookSection] of the asbab books.
/// Nothing at all when the feature is off, no reviewed pack is installed
/// or the verse has no entry.
class AsbabSection extends StatelessWidget {
  const AsbabSection({super.key, required this.surah, required this.ayah});

  final int surah;
  final int ayah;

  @override
  Widget build(BuildContext context) =>
      BookSection(spec: BookSectionSpec.asbab, surah: surah, ayah: ayah);
}
