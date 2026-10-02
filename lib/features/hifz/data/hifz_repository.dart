import 'package:drift/drift.dart';

import '../../../core/db/content_database.dart';
import '../../../core/settings/app_settings.dart';

/// What a reader reviews: a page of the edition being read, a hizb quarter
/// (1..240) or a surah (1..114).
enum HifzUnitKind { page, quarter, surah }

/// A review unit as a verse range (verse ids, `ayah.id`), the same in
/// every edition.
class HifzUnit {
  const HifzUnit(this.kind, this.from, this.to);

  final HifzUnitKind kind;
  final AyahRow from;
  final AyahRow to;

  String get fromRef => '${from.surah}:${from.number}';
  String get toRef => '${to.surah}:${to.number}';
}

/// A passage that resembles another (mutashabihat): its verses in order,
/// and whether the start of the next verse tells it apart.
class SimilarPassage {
  const SimilarPassage(this.verses, {required this.next});

  final List<AyahRow> verses;

  /// The verse after the passage, when the source marks it as needed.
  final AyahRow? next;
}

/// The similar passages of a verse: [passage] is the run of verses the
/// link starts from (the verse itself, or a run it belongs to).
class SimilarGroup {
  const SimilarGroup(this.passage, this.similar);

  final SimilarPassage passage;
  final List<SimilarPassage> similar;
}

/// Hifz queries on the content database: units as verse ranges, the
/// verses of the map, and the mutashabihat links.
class HifzRepository {
  HifzRepository(this._db);

  final ContentDatabase _db;

  Future<AyahRow> ayahById(int id) =>
      (_db.select(_db.ayah)..where((t) => t.id.equals(id))).getSingle();

  Future<AyahRow> ayah(int surah, int number) => (_db.select(
    _db.ayah,
  )..where((t) => t.surah.equals(surah) & t.number.equals(number))).getSingle();

  Future<List<AyahRow>> _range(int from, int to) =>
      (_db.select(_db.ayah)
            ..where((t) => t.id.isBetweenValues(from, to))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  /// Verses of a unit, in order.
  Future<List<AyahRow>> versesOf(String fromRef, String toRef) async {
    final a = _parse(fromRef);
    final b = _parse(toRef);
    final from = await ayah(a.$1, a.$2);
    final to = await ayah(b.$1, b.$2);
    return _range(from.id, to.id);
  }

  static (int, int) _parse(String ref) {
    final i = ref.indexOf(':');
    return (int.parse(ref.substring(0, i)), int.parse(ref.substring(i + 1)));
  }

  /// The unit [number] of [kind]; pages are those of [edition] (in the
  /// Shamarly edition, from the verse that starts the page or runs into it).
  Future<HifzUnit?> unit(
    HifzUnitKind kind,
    int number,
    MushafEdition edition,
  ) async {
    final q = _db.select(_db.ayah)
      ..where(
        (t) => switch (kind) {
          HifzUnitKind.surah => t.surah.equals(number),
          HifzUnitKind.quarter => t.hizbQuarter.equals(number),
          HifzUnitKind.page => switch (edition) {
            MushafEdition.madina1441 => t.page.equals(number),
            MushafEdition.madina1405 => t.page1405.equals(number),
            MushafEdition.shamarly =>
              t.pageShamarly.isSmallerOrEqualValue(number) &
                  t.pageShamarlyEnd.isBiggerOrEqualValue(number),
          },
        },
      )
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    final rows = await q.get();
    if (rows.isEmpty) return null;
    return HifzUnit(kind, rows.first, rows.last);
  }

  /// Every verse with its pages in the three editions and its surah, for
  /// the hifz map: (ref, surah, page 1441, page 1405, Shamarly start, end).
  Future<List<(String, int, int, int, int, int)>> verseCells() async {
    final rows = await _db
        .customSelect(
          'SELECT surah, number, page, page_1405, page_shamarly, '
          'page_shamarly_end FROM ayah ORDER BY id',
        )
        .get();
    return [
      for (final r in rows)
        (
          '${r.read<int>('surah')}:${r.read<int>('number')}',
          r.read<int>('surah'),
          r.read<int>('page'),
          r.read<int>('page_1405'),
          r.read<int>('page_shamarly'),
          r.read<int>('page_shamarly_end'),
        ),
    ];
  }

  /// Links touching verse [id], in both directions (the source lists most
  /// links both ways; the rest are inverted here). Structure only.
  Future<List<MutashabihRow>> _links(int id) =>
      (_db.select(_db.mutashabih)..where(
            (t) =>
                (t.srcFrom.isSmallerOrEqualValue(id) &
                    t.srcTo.isBiggerOrEqualValue(id)) |
                (t.mutFrom.isSmallerOrEqualValue(id) &
                    t.mutTo.isBiggerOrEqualValue(id)),
          ))
          .get();

  /// How many passages resemble verse [surah]:[ayah].
  Future<int> similarCount(int surah, int ayah) async {
    final id = (await this.ayah(surah, ayah)).id;
    return {
      for (final l in await _links(id))
        l.srcFrom <= id && id <= l.srcTo
            ? (l.srcFrom, l.srcTo, l.mutFrom, l.mutTo)
            : (l.mutFrom, l.mutTo, l.srcFrom, l.srcTo),
    }.length;
  }

  /// The passages that resemble verse [surah]:[ayah], grouped by the run
  /// of verses each link starts from. Only verses' own text is returned.
  Future<List<SimilarGroup>> similar(int surah, int ayah) async {
    final verse = await this.ayah(surah, ayah);
    // (own from, own to) -> {(other from, other to): context}
    final groups = <(int, int), Map<(int, int), bool>>{};
    for (final l in await _links(verse.id)) {
      final inSrc = l.srcFrom <= verse.id && verse.id <= l.srcTo;
      final own = inSrc ? (l.srcFrom, l.srcTo) : (l.mutFrom, l.mutTo);
      final other = inSrc ? (l.mutFrom, l.mutTo) : (l.srcFrom, l.srcTo);
      final map = groups.putIfAbsent(own, () => {});
      map[other] = (map[other] ?? false) || l.context == 1;
    }
    final ownKeys = groups.keys.toList()
      ..sort((a, b) => (a.$2 - a.$1).compareTo(b.$2 - b.$1));
    final out = <SimilarGroup>[];
    for (final own in ownKeys) {
      final others = groups[own]!;
      final context = others.values.any((c) => c);
      Future<SimilarPassage> passage((int, int) span, bool next) async =>
          SimilarPassage(
            await _range(span.$1, span.$2),
            next: next && span.$2 < 6236 ? await ayahById(span.$2 + 1) : null,
          );
      final keys = others.keys.toList()..sort((a, b) => a.$1.compareTo(b.$1));
      out.add(
        SimilarGroup(await passage(own, context), [
          for (final k in keys) await passage(k, others[k]!),
        ]),
      );
    }
    return out;
  }
}
