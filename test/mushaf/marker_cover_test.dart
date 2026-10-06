import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/page_interaction.dart';

/// A page image stretched across (a page of a two-page spread) draws its
/// printed marker wider than tall: the marker drawn over it must still
/// hide all of it, or its ends show as two dashes beside the new marker.
void main() {
  testWidgets('a printed marker wider than tall is covered to its ends', (
    tester,
  ) async {
    const paper = Color(0xFFFFFFFF);
    // The printed marker as stretched on screen, and its side ornaments'
    // ends at mid height, reaching its box's sides.
    const printed = Rect.fromLTWH(20, 22, 46, 36);
    final shot = await tester.runAsync(() async {
      final empty = ui.PictureRecorder();
      Canvas(empty);
      final blank = await empty.endRecording().toImage(4, 4);
      final look = MarkerLook(
        style: MarkerStyle.rosette16,
        image: blank,
        tint: null,
        paper: paper,
        ink: Colors.black,
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..drawColor(paper, BlendMode.src)
        ..drawRect(
          Rect.fromLTWH(printed.left, printed.center.dy - 3, 3, 6),
          Paint()..color = Colors.black,
        )
        ..drawRect(
          Rect.fromLTWH(printed.right - 3, printed.center.dy - 3, 3, 6),
          Paint()..color = Colors.black,
        )
        // A neighbouring letter just outside the box keeps its ink.
        ..drawRect(
          Rect.fromLTWH(printed.right + 3, printed.center.dy - 3, 3, 6),
          Paint()..color = Colors.black,
        );
      look.paintOver(
        canvas,
        printed.center,
        printed.shortestSide / 2,
        7,
        printed: printed,
      );
      final image = await recorder.endRecording().toImage(100, 80);
      return (await image.toByteData())!;
    });
    int red(double x, double y) =>
        shot!.getUint8((y.toInt() * 100 + x.toInt()) * 4);
    final y = printed.center.dy;
    expect(red(printed.left + 1, y), 255, reason: 'left end covered');
    expect(red(printed.right - 2, y), 255, reason: 'right end covered');
    expect(red(printed.right + 4, y), 0, reason: 'the next letter stays');
  });
}
