import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'model.dart';

/// SHA-256 of what a reviewer approves: the passage, its place in the
/// edition, and the verses it is linked to. Notes are not part of it.
///
/// Must match `content_hash` in tools/review_db.py byte for byte: canonical
/// JSON with sorted keys, no spaces, UTF-8, links sorted by
/// (surah, ayah_from, ayah_to, word_from or 0, word_to or 0).
String contentHash({
  required String sourceKey,
  required int? volume,
  required int? page,
  required int? pageEnd,
  required String text,
  required List<Link> links,
}) {
  final sorted = [...links]..sort(_compare);
  // Keys in sorted order: Dart maps keep insertion order.
  final canonical = <String, Object?>{
    'links': [
      for (final l in sorted)
        {
          'ayah_from': l.ayahFrom,
          'ayah_to': l.ayahTo,
          'surah': l.surah,
          'word_from': l.wordFrom,
          'word_to': l.wordTo,
        },
    ],
    'page': page,
    'page_end': pageEnd,
    'source': sourceKey,
    'text': text,
    'volume': volume,
  };
  return sha256.convert(utf8.encode(jsonEncode(canonical))).toString();
}

int _compare(Link a, Link b) {
  final ka = [a.surah, a.ayahFrom, a.ayahTo, a.wordFrom ?? 0, a.wordTo ?? 0];
  final kb = [b.surah, b.ayahFrom, b.ayahTo, b.wordFrom ?? 0, b.wordTo ?? 0];
  for (var i = 0; i < ka.length; i++) {
    final c = ka[i].compareTo(kb[i]);
    if (c != 0) return c;
  }
  return 0;
}
