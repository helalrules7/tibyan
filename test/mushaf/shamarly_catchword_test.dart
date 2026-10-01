import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/catchword_view.dart';

/// The Shamarly catchword boxes (tools/build_shamarly_catchword.py) and
/// the cut drawn from them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  test('a box for every page whose next page opens with a text line', () async {
    var boxes = 0;
    for (var page = 3; page < 522; page++) {
      final opens = (await repo.shamarlyLines(page + 1)).first.kind;
      final row = await repo.shamarlyCatchword(page);
      if (opens != 'text') {
        // A surah header or basmala comes first: the basmala, as text.
        expect(row, isNull, reason: 'page $page');
        continue;
      }
      expect(row, isNotNull, reason: 'page $page');
      boxes++;
      final cut = CatchwordCut.of(row!);
      // Inside the next page's image, on its first line, at its start
      // (the right edge: Arabic reads right to left).
      expect(cut.box.left, greaterThanOrEqualTo(0));
      expect(cut.box.right, lessThanOrEqualTo(886));
      expect(cut.box.right, greaterThan(760), reason: 'page $page');
      final first = (await repo.shamarlyLines(page + 1)).first;
      expect(cut.box.center.dy, inInclusiveRange(first.y0, first.y1));
      expect(row.words, inInclusiveRange(1, 2));
      for (final e in cut.erase) {
        expect(cut.box.intersect(e), e, reason: 'page $page: $e');
      }
    }
    expect(boxes, 490);
    // The cover and the two opening pages keep their own catchwords.
    expect(await repo.shamarlyCatchword(1), isNull);
    expect(await repo.shamarlyCatchword(2), isNull);
  });

  test('the erase rectangles are parsed from the stored text', () {
    final cut = CatchwordCut.of(
      const ShamarlyCatchwordRow(
        page: 7,
        x0: 800,
        y0: 40,
        x1: 870,
        y1: 110,
        words: 1,
        erase: '800,90,806,110 801,40,803,44',
      ),
    );
    expect(cut.box, const Rect.fromLTRB(800, 40, 870, 110));
    expect(cut.erase, const [
      Rect.fromLTRB(800, 90, 806, 110),
      Rect.fromLTRB(801, 40, 803, 44),
    ]);
    expect(
      CatchwordCut.of(
        const ShamarlyCatchwordRow(
          page: 7,
          x0: 1,
          y0: 2,
          x1: 3,
          y1: 4,
          words: 1,
          erase: '',
        ),
      ).erase,
      isEmpty,
    );
  });

  test('the cut keeps the box, without the erased ink', () async {
    // A fully inked 40 x 30 "page".
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 40, 30),
      Paint()..color = const Color(0xFF000000),
    );
    final page = await recorder.endRecording().toImage(40, 30);
    const cut = CatchwordCut(
      box: Rect.fromLTRB(10, 5, 30, 25),
      erase: [Rect.fromLTRB(10, 5, 15, 25)],
    );
    final image = await cut.cut(page);
    expect(image.width, 20);
    expect(image.height, 20);
    final bytes = (await image.toByteData())!;
    int alpha(int x, int y) => bytes.getUint8((y * 20 + x) * 4 + 3);
    expect(alpha(2, 10), 0); // erased: page x 12
    expect(alpha(4, 0), 0);
    expect(alpha(5, 10), 255); // kept: page x 15
    expect(alpha(19, 19), 255);
  });
}
