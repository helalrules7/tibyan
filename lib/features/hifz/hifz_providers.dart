import 'dart:ui' show Rect;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/user_database.dart';
import '../../core/settings/app_settings.dart';
import '../mushaf/mushaf_providers.dart';
import '../word_study/data/word_study_repository.dart' show verseWords;
import '../mushaf/presentation/widgets/mushaf_page.dart'
    show VerseKey, outlineRects;
import 'data/hifz_repository.dart';
import 'data/hifz_store.dart';
import 'domain/fsrs.dart';
import 'domain/recitation_test.dart';
import 'domain/strength.dart';

final hifzRepositoryProvider = Provider<HifzRepository>(
  (ref) => HifzRepository(ref.watch(contentDatabaseProvider)),
);

/// Review units, soonest due first.
final srsItemsProvider = StreamProvider<List<SrsItemRow>>(
  (ref) => ref.watch(userDatabaseProvider).watchSrsItems(),
);

/// Strength of each memorized verse, by `surah:ayah`.
final verseStrengthsProvider = StreamProvider<Map<String, int>>(
  (ref) => ref.watch(userDatabaseProvider).watchVerseStrengths(),
);

/// Every verse with its pages and surah, for the map.
final verseCellsProvider =
    FutureProvider<List<(String, int, int, int, int, int)>>(
      (ref) => ref.watch(hifzRepositoryProvider).verseCells(),
    );

/// Number of passages similar to a verse.
final similarCountProvider = FutureProvider.family<int, (int, int)>(
  (ref, v) => ref.watch(hifzRepositoryProvider).similarCount(v.$1, v.$2),
);

/// Units due today or earlier (before the start of tomorrow).
List<SrsItemRow> dueToday(List<SrsItemRow> items, DateTime now) {
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  return [
    for (final i in items)
      if (i.dueAt.isBefore(tomorrow)) i,
  ];
}

/// The pieces each verse on a page is revealed in during a recitation
/// test. Words where the edition has the verse's word boxes on this page
/// (all of them, or a run of them for a Shamarly verse crossing the page);
/// otherwise the verse's lines: the outline's line boxes in the new
/// edition, the glyph boxes of each line in the old one (quran.com's
/// ayahinfo), the verse boxes in the Shamarly edition.
final pageRevealUnitsProvider =
    FutureProvider.family<Map<VerseKey, RevealUnits>, int>((ref, page) async {
      final edition = ref.watch(editionProvider);
      final ayahs = await ref.watch(pageAyahsProvider(page).future);
      final words = await ref.watch(pageWordBoxesProvider(page).future);
      final byVerse = <VerseKey, Map<int, List<Rect>>>{};
      for (final MapEntry(key: (s, a, n), value: rects) in words.entries) {
        (byVerse[(surah: s, ayah: a)] ??= {})[n] = rects;
      }
      final lines = await _verseLines(ref, page, edition);
      final out = <VerseKey, RevealUnits>{};
      for (final a in ayahs) {
        final k = (surah: a.surah, ayah: a.number);
        final count = verseWords(a).length;
        final w = byVerse[k];
        if (w != null && w.isNotEmpty) {
          final numbers = w.keys.toList()..sort();
          final contiguous = numbers.last - numbers.first + 1 == numbers.length;
          final whole = numbers.length == count;
          final crossesPage =
              edition == MushafEdition.shamarly &&
              a.pageShamarly != a.pageShamarlyEnd;
          if (contiguous && (whole || crossesPage)) {
            out[k] = RevealUnits([
              for (final n in numbers) w[n]!,
            ], byWord: true);
            continue;
          }
        }
        final l = lines[k];
        if (l != null && l.isNotEmpty) {
          out[k] = RevealUnits([
            for (final r in l) [r],
          ], byWord: false);
        }
      }
      return out;
    });

/// One box per line of each verse on a page, top to bottom (edition units).
Future<Map<VerseKey, List<Rect>>> _verseLines(
  Ref ref,
  int page,
  MushafEdition edition,
) async {
  final repo = ref.watch(mushafRepositoryProvider);
  final out = <VerseKey, List<Rect>>{};
  switch (edition) {
    case MushafEdition.madina1441:
      for (final p in await repo.polygons(page)) {
        out[(surah: p.surah, ayah: p.number)] = outlineRects(p.path)
          ..sort((a, b) => a.center.dy.compareTo(b.center.dy));
      }
    case MushafEdition.madina1405:
      final glyphs =
          await ref.watch(ayahInfoDatabaseProvider)?.page(page) ?? const [];
      final byLine = <VerseKey, Map<int, Rect>>{};
      for (final g in glyphs) {
        final k = (surah: g.suraNumber, ayah: g.ayahNumber);
        final r = Rect.fromLTRB(
          g.minX.toDouble(),
          g.minY.toDouble(),
          g.maxX.toDouble(),
          g.maxY.toDouble(),
        );
        final m = byLine[k] ??= {};
        m[g.lineNumber] = m[g.lineNumber]?.expandToInclude(r) ?? r;
      }
      for (final e in byLine.entries) {
        final keys = e.value.keys.toList()..sort();
        out[e.key] = [for (final j in keys) e.value[j]!];
      }
    // A riwaya page has no line boxes here: its verses are revealed whole.
    case MushafEdition.warsh ||
        MushafEdition.qalun ||
        MushafEdition.douri ||
        MushafEdition.shubah:
      break;
    case MushafEdition.shamarly:
      for (final b in await repo.shamarlyVerseBoxes(page)) {
        (out[(surah: b.surah, ayah: b.ayah)] ??= []).add(
          Rect.fromLTRB(
            b.x0.toDouble(),
            b.y0.toDouble(),
            b.x1.toDouble(),
            b.y1.toDouble(),
          ),
        );
      }
  }
  return out;
}

/// Records verse results from a test in the memorization table.
Future<void> saveVerseResults(
  UserDatabase db,
  Map<VerseKey, VerseResult> results,
) async {
  if (results.isEmpty) return;
  final refs = {for (final k in results.keys) verseRef(k.surah, k.ayah): k};
  final before = await db.verseStrengths(refs.keys);
  await db.setVerseStrengths({
    for (final MapEntry(key: ref, value: k) in refs.entries)
      ref: afterVerseTest(Strength.of(before[ref]), results[k]!).level,
  });
}

/// Grades a review unit: schedules its next review (FSRS) and sets the
/// strength of its verses from the new stability; verses missed in this
/// test stay weak.
Future<Review> gradeUnit({
  required UserDatabase db,
  required HifzRepository repo,
  required HifzUnitKind kind,
  required String fromRef,
  required String toRef,
  required Grade grade,
  required Map<VerseKey, VerseResult> results,
  DateTime? now,
}) async {
  final at = now ?? DateTime.now();
  final old = await db.srsItem(kind.name, fromRef, toRef);
  final review = const Fsrs().review(
    state: old == null
        ? null
        : MemoryState(stability: old.stability, difficulty: old.difficulty),
    lastReview: old?.lastReviewAt,
    grade: grade,
    now: at,
  );
  await db.saveSrsReview(
    unit: kind.name,
    fromRef: fromRef,
    toRef: toRef,
    stability: review.state.stability,
    difficulty: review.state.difficulty,
    dueAt: review.due,
    lapse: grade == Grade.again && old != null,
    now: at,
  );
  final level = Strength.fromStability(review.state.stability);
  final verses = await repo.versesOf(fromRef, toRef);
  await db.setVerseStrengths({
    for (final a in verses)
      verseRef(
        a.surah,
        a.number,
      ): results[(surah: a.surah, ayah: a.number)] == VerseResult.missed
          ? Strength.weak.level
          : level.level,
  });
  return review;
}
