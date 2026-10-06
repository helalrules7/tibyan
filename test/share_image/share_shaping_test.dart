import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/share_image/share_text_runs.dart';

/// Colouring a letter splits a word into runs of one colour each. This
/// checks that the split does not change how the KFGQPC font shapes the
/// word: the word drawn as one run and as one run per letter (all in the
/// same colour) gives the same glyphs (at most a few edge pixels differ,
/// where overlapping glyphs blend), so the letters stay joined; the same
/// letters unjoined differ a lot.
void main() {
  Future<Uint8List> draw(List<String> runs) async {
    final b = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textDirection: ui.TextDirection.rtl,
        fontFamily: 'UthmanicHafsTest',
        fontSize: 80,
      ),
    );
    for (final r in runs) {
      b
        ..pushStyle(
          ui.TextStyle(
            color: const ui.Color(0xFF000000),
            fontFamily: 'UthmanicHafsTest',
            fontSize: 80,
          ),
        )
        ..addText(r)
        ..pop();
    }
    final p = b.build()..layout(const ui.ParagraphConstraints(width: 1400));
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder)
      ..drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src)
      ..drawParagraph(p, ui.Offset.zero);
    final image = await recorder.endRecording().toImage(1400, 200);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }

  testWidgets('runs of one colour per letter keep the shaping', (tester) async {
    await tester.runAsync(() async {
      await (FontLoader('UthmanicHafsTest')..addFont(
            Future.value(
              ByteData.sublistView(
                File('assets/fonts/kfgqpc/uthmanic_hafs_v20.ttf')
                    .readAsBytesSync(),
              ),
            ),
          ))
          .load();
      const words = [
        'ٱلرَّحۡمَٰنِ',
        'يَعۡلَمُ',
        'بِإِذۡنِهِۦۚ',
        'وَلَا',
        'شَيۡءٖ',
        'ٱلسَّمَٰوَٰتِ',
      ];
      for (final w in words) {
        final whole = await draw([w]);
        final split = await draw([
          for (final (s, e) in letterSpans(w)) w.substring(s, e),
        ]);
        // Marks split from their letter, as a «marks only» rule does.
        final marks = await draw([
          for (final (s, e) in letterSpans(w)) ...[
            w.substring(s, s + 1),
            if (e > s + 1) w.substring(s + 1, e),
          ],
        ]);
        // Unjoined letters (a zero-width non-joiner between them, in this
        // test only), to show what a broken word looks like.
        final broken = await draw([
          [for (final (s, e) in letterSpans(w)) w.substring(s, e)]
              .join('\u200c'),
        ]);
        int diff(Uint8List a) {
          var n = 0;
          for (var i = 0; i < a.length; i += 4) {
            if (a[i] != whole[i]) n++;
          }
          return n;
        }

        var ink = 0;
        for (var i = 0; i < whole.length; i += 4) {
          if (whole[i] < 128) ink++;
        }
        // The same glyphs: at most a few edge pixels differ, where two
        // overlapping glyphs are blended in another order.
        expect(diff(split), lessThan(ink * 0.02), reason: w);
        expect(diff(marks), lessThan(ink * 0.02), reason: w);
        expect(diff(broken), greaterThan(ink * 0.2), reason: w);
      }
    });
  });
}
