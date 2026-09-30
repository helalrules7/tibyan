import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_tokens.dart';

/// Where things sit in the opening-page frames (docs/design/fateha-themes,
/// each a recolour of one 1200×1457 drawing): the transparent panel for
/// the page, and the two cream cartouches above and below it.
abstract final class OpeningArtLayout {
  static const size = Size(1200, 1457);
  static const panel = Rect.fromLTRB(339, 407, 860, 1049);
  static const top = Rect.fromLTRB(455, 225, 745, 380);
  static const bottom = Rect.fromLTRB(454, 1077, 745, 1231);
}

/// The opening pages (al-Fatiha, the start of al-Baqarah) and the cover in
/// the theme's opening frame: the picture scaled whole, [child] in its
/// panel, [top] and [bottom] in its cartouches, and [pageNumber] (when
/// given) just under it.
class OpeningArtBody extends StatelessWidget {
  const OpeningArtBody({
    super.key,
    required this.asset,
    required this.top,
    required this.bottom,
    required this.child,
    this.pageNumber,
  });

  static const numberSpace = 38.0;

  final String asset;
  final Widget top;
  final Widget bottom;
  final Widget child;
  final Widget? pageNumber;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return LayoutBuilder(
      builder: (context, box) {
        final room = Size(
          box.maxWidth,
          box.maxHeight - (pageNumber == null ? 0 : numberSpace),
        );
        const art = OpeningArtLayout.size;
        final k = room.width / art.width < room.height / art.height
            ? room.width / art.width
            : room.height / art.height;
        final frame = Rect.fromLTWH(
          (room.width - art.width * k) / 2,
          (room.height - art.height * k) / 2,
          art.width * k,
          art.height * k,
        );
        Rect place(Rect r) => Rect.fromLTRB(
          frame.left + r.left * k,
          frame.top + r.top * k,
          frame.left + r.right * k,
          frame.top + r.bottom * k,
        );
        final panel = place(OpeningArtLayout.panel);
        return Stack(
          children: [
            // The page's paper shows through the panel.
            Positioned.fromRect(
              rect: panel,
              child: ColoredBox(color: tokens.colors.paper),
            ),
            Positioned.fromRect(
              rect: frame,
              child: Image.asset(
                asset,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
            Positioned.fromRect(
              rect: panel.deflate(panel.width * 0.03),
              child: child,
            ),
            for (final c in [
              (OpeningArtLayout.top, top),
              (OpeningArtLayout.bottom, bottom),
            ])
              Positioned.fromRect(
                // The cartouche's ends are notched: keep the text inside.
                rect: () {
                  final r = place(c.$1);
                  return Rect.fromLTRB(
                    r.left + r.width * 0.16,
                    r.top + r.height * 0.14,
                    r.right - r.width * 0.16,
                    r.bottom - r.height * 0.14,
                  );
                }(),
                child: _OnCream(
                  child: FittedBox(fit: BoxFit.scaleDown, child: c.$2),
                ),
              ),
            if (pageNumber != null)
              Positioned(
                left: 0,
                right: 0,
                top: frame.bottom + 2,
                height: numberSpace - 2,
                child: Center(child: pageNumber),
              ),
          ],
        );
      },
    );
  }
}

/// The cartouches are cream in every mode: what they hold is drawn in the
/// light mode's colours.
class _OnCream extends StatelessWidget {
  const _OnCream({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final light = tokens.style.modes[ThemeModeId.light]!;
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        extensions: [tokens.copyWith(mode: ThemeModeId.light, colors: light)],
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: light.ink),
        child: child,
      ),
    );
  }
}
