import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/mushaf/data/verse_image.dart';

void main() {
  captureTest();
  stackTest();
  test('changedBounds finds the box of what differs', () {
    const w = 6, h = 5;
    final a = Uint8List(w * h * 4);
    final b = Uint8List.fromList(a);
    // Change the pixels (2,1) and (4,3).
    for (final (x, y) in [(2, 1), (4, 3)]) {
      b[(y * w + x) * 4 + 2] = 9;
    }
    expect(changedBounds(a, b, w, h), const Rect.fromLTRB(2, 1, 5, 4));
  });

  test('identical captures have no bounds', () {
    final a = Uint8List(4 * 4 * 4);
    expect(changedBounds(a, Uint8List.fromList(a), 4, 4), isNull);
  });
}

class _Page extends StatefulWidget {
  const _Page({required this.boundary, required this.state});
  final GlobalKey boundary;
  final ValueNotifier<bool> state;
  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: widget.state,
    builder: (_, selected, _) => RepaintBoundary(
      key: widget.boundary,
      child: Stack(
        textDirection: TextDirection.ltr,
        children: [
          const SizedBox(width: 200, height: 300),
          Positioned(
            left: 20,
            top: 40,
            width: 100,
            height: 50,
            child: ColoredBox(
              color: selected
                  ? const Color(0xFFFFFF00)
                  : const Color(0x00000000),
            ),
          ),
        ],
      ),
    ),
  );
}

void stackTest() {
  testWidgets('stackVertically joins pieces with a gap, centred', (
    tester,
  ) async {
    final result = await tester.runAsync(() async {
      Future<ui.Image> solid(int w, int h) async {
        final r = ui.PictureRecorder();
        Canvas(r).drawRect(
          Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
          Paint()..color = const Color(0xFF000000),
        );
        return r.endRecording().toImage(w, h);
      }

      final stacked = await stackVertically(
        [await solid(100, 40), await solid(60, 30)],
        const Color(0xFFFFFFFF),
        gap: 10,
      );
      return (stacked.width, stacked.height);
    });
    expect(result, (100, 80));
  });
}

void captureTest() {
  testWidgets('captureSelectionImage cuts the page to the selection', (
    tester,
  ) async {
    final key = GlobalKey();
    final selected = ValueNotifier(true);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: _Page(boundary: key, state: selected),
        ),
      ),
    );
    final file = await tester.runAsync(
      () => captureSelectionImage(
        key: key,
        paper: const Color(0xFFFFFFFF),
        pixelRatio: 1,
        into: Directory.systemTemp,
        clean: () async {
          selected.value = false;
          await tester.pump();
        },
        restore: () async => selected.value = true,
      ),
    );
    expect(file, isNotNull);
    final bytes = file!.readAsBytesSync();
    // A PNG, and the selection restored afterwards.
    expect(bytes.sublist(1, 4), 'PNG'.codeUnits);
    expect(selected.value, isTrue);
  });
}
