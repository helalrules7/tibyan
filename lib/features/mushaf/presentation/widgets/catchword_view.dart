import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../../core/db/content_database.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../mushaf_providers.dart';
import 'image_page.dart';

/// Where the Shamarly catchword of a page is cut from the next page's
/// image: the box of its first word(s), and the rectangles of other ink
/// inside that box, which are left out.
@immutable
class CatchwordCut {
  const CatchwordCut({required this.box, this.erase = const []});

  /// Takes the row's boxes, in image px, at [factor]: the page is decoded
  /// smaller than it is printed, since the catchword is drawn at a third
  /// of its size.
  factory CatchwordCut.of(ShamarlyCatchwordRow row, [double factor = 1]) =>
      CatchwordCut(
        box: _rect([row.x0, row.y0, row.x1, row.y1], factor),
        erase: [
          for (final r in row.erase.split(' '))
            if (r.isNotEmpty)
              _rect([for (final v in r.split(',')) int.parse(v)], factor),
        ],
      );

  static Rect _rect(List<int> v, double factor) => Rect.fromLTRB(
    v[0] * factor,
    v[1] * factor,
    v[2] * factor,
    v[3] * factor,
  );

  /// Image px of the next page.
  final Rect box;
  final List<Rect> erase;

  /// The word(s) alone, from [page] (the next page's image), at 1:1:
  /// the box with the other ink cleared. Its alpha is the ink.
  Future<ui.Image> cut(ui.Image page) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..translate(-box.left, -box.top);
    canvas
      ..saveLayer(box, Paint())
      ..drawImageRect(page, box, box, Paint());
    final clear = Paint()..blendMode = BlendMode.clear;
    for (final r in erase) {
      canvas.drawRect(r, clear);
    }
    canvas.restore();
    return recorder.endRecording().toImage(
      box.width.round(),
      box.height.round(),
    );
  }
}

/// The catchword of a Shamarly page cut from the next page's image, or
/// null: not the Shamarly edition, no cut for this page (the next page
/// opens with a surah header or basmala), or the next page's image is not
/// installed.
final shamarlyCatchwordProvider = FutureProvider.family<ui.Image?, int>((
  ref,
  page,
) async {
  if (ref.watch(editionProvider) != MushafEdition.shamarly) return null;
  final row = await ref.watch(mushafRepositoryProvider).shamarlyCatchword(page);
  if (row == null) return null;
  final file = File(
    p.join(
      ref.watch(pageInstallerProvider).dir.path,
      '${(page + 1).toString().padLeft(3, '0')}.png',
    ),
  );
  if (!file.existsSync()) return null;
  // The catchword is drawn at [CatchwordView.scale], so the page is
  // decoded at that size and never at the size it is printed: decoding a
  // whole page for one word made every page turn decode two page images.
  final buffer = await ui.ImmutableBuffer.fromFilePath(file.path);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  final codec = await descriptor.instantiateCodec(
    targetWidth: (descriptor.width * CatchwordView.scale).round(),
  );
  final image = (await codec.getNextFrame()).image;
  try {
    return await CatchwordCut.of(
      row,
      image.width / descriptor.width,
    ).cut(image);
  } finally {
    image.dispose();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
  }
});

/// The first word of the next page, under the frame: in the Shamarly
/// edition cut from the next page's image and drawn in the page's ink
/// ([shamarlyCatchwordProvider]); otherwise [text] in [style].
class CatchwordView extends ConsumerWidget {
  const CatchwordView({
    super.key,
    required this.page,
    required this.text,
    required this.style,
  });

  /// The page the catchword stands under.
  final int page;

  /// The word as text, when known.
  final String? text;
  final TextStyle style;

  /// Screen px per image px: a Shamarly line (88.6 px apart) about as tall
  /// as the text catchword's.
  static const scale = 0.3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final edition = ref.watch(editionProvider);
    if (edition == MushafEdition.shamarly) {
      final image = ref.watch(shamarlyCatchwordProvider(page));
      final cut = image.value;
      if (cut != null) {
        return Semantics(
          label: text == null ? l.catchwordImageLabel : l.catchwordLabel(text!),
          image: true,
          child: ExcludeSemantics(
            child: _CatchwordImage(
              image: cut,
              color: context.tokens.colors.ink,
            ),
          ),
        );
      }
      // Still loading: nothing, so the text does not flash before it.
      if (image.isLoading) return const SizedBox.shrink();
    }
    if (text == null) return const SizedBox.shrink();
    // A riwaya's catchword is its own KFGQPC text, in its own font.
    final riwayaStyle = edition.isRiwaya && riwayaFontLoaded(edition.riwaya)
        ? style.copyWith(fontFamily: riwayaFontFamily(edition.riwaya))
        : style;
    return Text(
      text!,
      semanticsLabel: l.catchwordLabel(text!),
      style: riwayaStyle,
    );
  }
}

class _CatchwordImage extends StatelessWidget {
  const _CatchwordImage({required this.image, required this.color});

  final ui.Image image;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // The image is already at the size it is drawn (see the provider).
    final size = Size(image.width.toDouble(), image.height.toDouble());
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: CustomPaint(size: size, painter: _CatchwordPainter(image, color)),
    );
  }
}

class _CatchwordPainter extends CustomPainter {
  _CatchwordPainter(this.image, this.color);

  final ui.Image image;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..colorFilter = inkFilter(color, alphaInk: true),
    );
  }

  @override
  bool shouldRepaint(_CatchwordPainter old) =>
      old.image != image || old.color != color;
}
