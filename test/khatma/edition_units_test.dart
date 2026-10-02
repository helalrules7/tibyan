import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/features/khatma/domain/day.dart';
import 'package:tibyan/features/khatma/domain/khatma_plan.dart';
import 'package:tibyan/features/khatma/khatma_providers.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';

/// Runs against the real bundled database: every edition can carry a
/// khatma, in pages, juz or hizb.
void main() {
  late ContentDatabase db;
  late MushafRepository repo;

  setUpAll(() {
    db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
    repo = MushafRepository(db);
  });
  tearDownAll(() => db.close());

  for (final edition in MushafEdition.values) {
    test('${edition.name}: units cover the text pages in order', () async {
      final pages = await unitStartsOf(repo, edition, PortionUnit.page);
      final juz = await unitStartsOf(repo, edition, PortionUnit.juz);
      final hizb = await unitStartsOf(repo, edition, PortionUnit.hizb);
      final first = edition == MushafEdition.shamarly ? 2 : 1;
      expect(pages.first, first);
      expect(pages.last, edition.pageCount);
      expect(pages.length, edition.pageCount - first + 1);
      expect(juz.length, 30);
      expect(hizb.length, 60);
      for (final u in [juz, hizb]) {
        expect(u.first, first);
        for (var i = 1; i < u.length; i++) {
          expect(u[i], greaterThan(u[i - 1]));
        }
        expect(u.last, lessThanOrEqualTo(edition.pageCount));
      }

      // A juz a day ends on the last page in 30 days.
      final start = Day(2026, 10, 1);
      final plan = KhatmaPlan(
        unitStarts: juz,
        lastPage: edition.pageCount,
        from: start,
        target: start.add(29),
      );
      expect(plan.todayPortion(start, {})!.range, (
        from: first,
        to: juz[1] - 1,
      ));
      expect(plan.expectedEnd(start.add(29)), edition.pageCount);
    });
  }

  test(
    'a page read in one edition counts in another through its verses',
    () async {
      // Al-Baqarah 2:255 is on page 42 of the new Madina edition.
      final a = await repo.ayah(2, 255);
      expect(a.pageIn(MushafEdition.madina1441), 42);
      final onPage = await repo.ayahsOnPage(42, MushafEdition.madina1441);
      final inShamarly = {
        for (final v in onPage) v.pageIn(MushafEdition.shamarly),
      };
      expect(inShamarly, contains(a.pageIn(MushafEdition.shamarly)));
      expect(inShamarly.length, lessThanOrEqualTo(2));
    },
  );
}
