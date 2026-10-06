import 'dart:convert';

import 'package:flutter/services.dart';

/// The statement of a surah's type as the 1924 Cairo mushaf (King Fuad,
/// Bulaq 1342H) prints it in the surah's header, with the verses excepted
/// from it: «مكية إلا الآيات ٢٠ و٢٣ … فمدنية».
///
/// From `assets/config/surah_type_1342.json`: a hand transcription of the
/// 114 headers, read twice and compared (tools/surah_type_1342/build.py).
/// Its status is «draft-transcription» until a qualified reviewer approves
/// it (docs/MISSING_DATA.md, N16). The statement is kept as printed, its
/// spelling («فى», «آيتى») and its Arabic-Indic digits included; nothing
/// here changes a letter of it.
class SurahStatements {
  SurahStatements._(this.status, this._bySurah);

  /// Reads the asset's JSON.
  factory SurahStatements.parse(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final bySurah = <int, SurahStatement>{};
    for (final e in (data['surahs'] as List).cast<Map<String, dynamic>>()) {
      final s = SurahStatement(
        surah: e['surah'] as int,
        page: e['page'] as int,
        type: e['type'] as String,
        statement: e['statement'] as String,
        verseCount: e['verse_count'] as int,
        numbered: (e['exceptions'] as List).isNotEmpty,
      );
      bySurah[s.surah] = s;
    }
    return SurahStatements._(data['status'] as String, bySurah);
  }

  static const asset = 'assets/config/surah_type_1342.json';

  static Future<SurahStatements>? _loaded;

  /// The asset, read once.
  static Future<SurahStatements> load([AssetBundle? bundle]) => _loaded ??=
      (bundle ?? rootBundle).loadString(asset).then(SurahStatements.parse);

  /// «draft-transcription» until the reviewer's approval.
  final String status;
  final Map<int, SurahStatement> _bySurah;

  /// Surah [surah]'s statement; null if the data has none for it.
  SurahStatement? operator [](int surah) => _bySurah[surah];

  int get length => _bySurah.length;
}

/// One surah's header statement in the 1342 print.
class SurahStatement {
  const SurahStatement({
    required this.surah,
    required this.page,
    required this.type,
    required this.statement,
    required this.verseCount,
    required this.numbered,
  });

  final int surah;

  /// The printed page of the header.
  final int page;

  /// meccan, medinan, or mixed (al-Ma'un: its two parts, no type for the
  /// whole).
  final String type;

  /// As printed: «مكية إلا آية ٨٧ فمدنية».
  final String statement;

  /// The verse count the header prints (the Kufan count, as Hafs's).
  final int verseCount;

  /// Whether the statement names verses (by number, or as «the last two»):
  /// then it holds only for a text numbered as Hafs is.
  final bool numbered;
}
