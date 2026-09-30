import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import 'illuminated_frame.dart';
import 'theme_art.dart';
import 'opening_art.dart';

/// The page in a heritage theme, laid out as approved: the juz ✦ hizb ✦
/// surah cartouche above the frame, the theme's frame around the page,
/// the page number in the theme's verse marker below it (with the quarter
/// that starts on the page and the next page's first word on either
/// side), and the reading tools under it.
class ArtPageFrame extends StatelessWidget {
  const ArtPageFrame({
    super.key,
    required this.art,
    required this.info,
    required this.child,
    this.onJuzTap,
    this.onHizbTap,
    this.onSurahTap,
    this.onPageTap,
    this.tools,
    this.linePadding,
    this.showCatchword = true,
  });

  static const cartoucheSpace = 50.0;
  static const numberSpace = 40.0;
  static const toolsSpace = 26.0;

  /// Room between the frame and the page's text.
  static const gap = 8.0;

  /// Null while the art loads.
  final ThemeArtPictures? art;
  final FrameInfo? info;
  final Widget child;
  final VoidCallback? onJuzTap;
  final VoidCallback? onHizbTap;
  final VoidCallback? onSurahTap;
  final VoidCallback? onPageTap;

  final Widget? tools;
  final EdgeInsets Function(Size page)? linePadding;
  final bool showCatchword;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    final l = AppLocalizations.of(context);
    final digits = NumberFormatter(Localizations.localeOf(context));
    final info = this.info;

    final framed = LayoutBuilder(
      builder: (context, box) {
        final inset = art?.layout(box.biggest).inset ?? 20;
        final pad = inset + gap;
        final linePad =
            linePadding?.call(
              Size(box.maxWidth - 2 * pad, box.maxHeight - 2 * pad),
            ) ??
            EdgeInsets.zero;
        final slot =
            (box.maxHeight - 2 * pad - linePad.vertical) /
            IlluminatedFrame.lines;
        final top = pad + linePad.top;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: ArtFramePainter(art: art, paper: t.paper),
              ),
            ),
            Positioned.fill(
              child: Padding(padding: EdgeInsets.all(pad), child: child),
            ),
            for (final b in info?.banners ?? const <SurahBanner>[])
              Positioned(
                top: top + b.line * slot,
                left: pad - 4,
                right: pad - 4,
                height: slot * b.slots,
                child: ArtSurahBanner(banner: b, art: art),
              ),
          ],
        );
      },
    );

    return Column(
      children: [
        SizedBox(
          height: cartoucheSpace,
          child: info == null
              ? null
              // The theme's own surah header: the surah on top, the juz
              // and hizb under it, in its name box.
              : ArtHeader(
                  art: art,
                  inset: 0.05,
                  content: DefaultTextStyle.merge(
                    style: TextStyle(
                      fontFamily: 'UthmanTahaNaskh',
                      color: t.ink,
                      height: 1.25,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SmallTap(
                          label: info.surahName,
                          bold: true,
                          fontSize: 16,
                          onTap: onSurahTap,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SmallTap(
                              label: l.juzLabel(digits(info.juz)),
                              fontSize: 12.5,
                              onTap: onJuzTap,
                            ),
                            FrameStar(color: t.marker),
                            _SmallTap(
                              label: l.hizbLabel(digits(info.hizb)),
                              fontSize: 12.5,
                              onTap: onHizbTap,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        Expanded(child: framed),
        SizedBox(
          height: numberSpace,
          child: Stack(
            children: [
              if (info != null)
                Center(
                  child: ArtPageNumber(
                    art: art,
                    page: info.page,
                    onTap: onPageTap,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // Start side (right in Arabic): the quarter that begins
                    // on this page, so the reader notices it.
                    if (info != null && info.quarters.isNotEmpty)
                      QuarterLabel(
                        text: quarterName(
                          l,
                          digits,
                          info.quarters.last.quarter,
                        ),
                        color: t.muted,
                      ),
                    const Spacer(),
                    if (showCatchword && info?.catchword != null)
                      _Catchword(info!.catchword!),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: toolsSpace,
          child: tools == null ? null : Center(child: tools),
        ),
      ],
    );
  }
}

class _Catchword extends StatelessWidget {
  const _Catchword(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    semanticsLabel: AppLocalizations.of(context).catchwordLabel(text),
    style: TextStyle(
      fontFamily: 'UthmanicHafs',
      fontSize: 15,
      height: 1.4,
      color: context.tokens.colors.muted,
    ),
  );
}

/// A label in the header above the frame that opens its index. Kept
/// tight: the header's name box holds two lines of them.
class _SmallTap extends StatelessWidget {
  const _SmallTap({
    required this.label,
    required this.fontSize,
    this.onTap,
    this.bold = false,
  });

  final String label;
  final double fontSize;
  final VoidCallback? onTap;
  final bool bold;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    ),
  );
}

/// The page number in the theme's verse marker; a tap opens «go to page».
class ArtPageNumber extends StatelessWidget {
  const ArtPageNumber({
    super.key,
    required this.art,
    required this.page,
    this.onTap,
    this.height = 46,
  });

  final ThemeArtPictures? art;
  final int page;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final marker = art?.marker;
    if (marker == null) {
      return FrameTap(
        label: NumberFormatter(Localizations.localeOf(context))(page),
        bold: true,
        semanticLabel: l.pageOf('$page'),
        onTap: onTap,
      );
    }
    final width = height * marker.size.width / marker.size.height;
    return Semantics(
      button: onTap != null,
      label: l.pageOf('$page'),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          // At least 44 px wide, so it is easy to tap.
          width: width < 44 ? 44 : width,
          height: height,
          child: CustomPaint(
            painter: ArtMarkerPainter(
              marker: marker,
              number: page,
              digits: t.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// [content] centred in the theme's surah header, inside its name box.
class ArtHeader extends StatelessWidget {
  const ArtHeader({
    super.key,
    required this.art,
    required this.content,
    this.background,
    this.inset = 0.15,
  });

  final ThemeArtPictures? art;
  final Widget content;

  /// Share of the name box's width kept clear at each end.
  final double inset;

  /// Fills the whole box first (hides a printed header underneath).
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final header = art?.header;
    return LayoutBuilder(
      builder: (context, box) {
        final all = Offset.zero & box.biggest;
        final slot = header == null
            ? all.deflate(box.maxHeight * 0.1)
            : header.slot == null
            ? fittedArt(header.size, all).deflate(box.maxHeight * 0.1)
            : slotIn(header.slot!, header.size, fittedArt(header.size, all));
        return Stack(
          children: [
            Positioned.fill(
              child: header == null
                  ? ColoredBox(color: background ?? Colors.transparent)
                  : CustomPaint(
                      painter: ArtPicturePainter(
                        header,
                        background: background,
                      ),
                    ),
            ),
            Positioned.fromRect(
              // The name box's ends are curved or notched: keep the text
              // clear of them.
              rect: Rect.fromLTRB(
                slot.left + slot.width * inset,
                slot.top + 1,
                slot.right - slot.width * inset,
                slot.bottom - 1,
              ),
              child: Center(
                child: FittedBox(fit: BoxFit.scaleDown, child: content),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A surah header over the page in the theme's header art: the surah's
/// number, name and type in its name box, and its verse count and place
/// in revelation under them where the box is tall enough.
class ArtSurahBanner extends StatelessWidget {
  const ArtSurahBanner({super.key, required this.banner, required this.art});

  final SurahBanner banner;
  final ThemeArtPictures? art;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final b = banner;
    final type = b.meccan ? l.meccan : l.medinan;
    final title = l.surahBannerTitle(digits(b.number), b.name, type);
    final info = b.after == null
        ? l.surahBannerInfoFirst(digits(b.ayahCount), digits(b.order))
        : l.surahBannerInfo(digits(b.ayahCount), digits(b.order), b.after!);
    return Semantics(
      header: true,
      label: '$title. $info',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          // The info line only where the name box leaves room for it.
          final header = art?.header;
          final slotH = header?.slot == null
              ? box.maxHeight * 0.8
              : header!.slot!.height /
                    header.size.height *
                    fittedArt(header.size, Offset.zero & box.biggest).height;
          return ArtHeader(
            art: art,
            // Opaque: the printed header underneath must not show.
            background: t.paper,
            content: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'UthmanTahaNaskh',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.2,
                      color: t.ink,
                    ),
                  ),
                  if (slotH >= 26)
                    Text(
                      info,
                      style: TextStyle(
                        fontFamily: 'KFGQPCAN',
                        fontSize: 10.5,
                        height: 1.3,
                        color: t.ink,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The ornate page (cover, opening pages, splash) in a heritage theme: the
/// theme's frame, its surah header at the top and bottom with [top] and
/// [bottom] in their name boxes, the page between them, and the page
/// number in the theme's marker under the frame.
class ArtOrnateFrame extends StatelessWidget {
  const ArtOrnateFrame({
    super.key,
    required this.art,
    required this.top,
    required this.bottom,
    required this.child,
    this.page,
    this.onPageTap,
    this.catchword,
    this.catchwordSpace = true,
    this.tools,
  });

  final ThemeArtPictures? art;
  final Widget top;
  final Widget bottom;
  final Widget child;
  final int? page;
  final VoidCallback? onPageTap;
  final String? catchword;
  final bool catchwordSpace;
  final Widget? tools;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    final opening = context.tokens.style.opening;
    final body = opening != null
        ? OpeningArtBody(asset: opening, top: top, bottom: bottom, child: child)
        : LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              final h = box.maxHeight;
              final inset = art?.layout(box.biggest).inset ?? 20;
              final pad = inset + ArtPageFrame.gap;
              final header = art?.header;
              final headerW = w - 2 * pad;
              final aspect = header == null
                  ? 8.0
                  : header.size.width / header.size.height;
              final headerH = math.max(
                34.0,
                math.min(headerW / aspect, h * 0.12),
              );
              Widget cartouche(double y, Widget content) => Positioned(
                top: y,
                left: pad,
                width: headerW,
                height: headerH,
                child: ArtHeader(
                  art: art,
                  content: DefaultTextStyle.merge(
                    style: TextStyle(
                      fontFamily: 'KFGQPCAN',
                      color: t.ink,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    child: content,
                  ),
                ),
              );
              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ArtFramePainter(art: art, paper: t.paper),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: Rect.fromLTRB(
                      pad,
                      pad + headerH + 8,
                      w - pad,
                      h - pad - headerH - 8,
                    ),
                    child: child,
                  ),
                  cartouche(pad, top),
                  cartouche(h - pad - headerH, bottom),
                ],
              );
            },
          );
    final catchwordText = catchword == null ? null : _Catchword(catchword!);
    return Column(
      children: [
        Expanded(child: body),
        if (page != null) ...[
          SizedBox(
            height: ArtPageFrame.numberSpace,
            child: Stack(
              children: [
                Center(
                  child: ArtPageNumber(art: art, page: page!, onTap: onPageTap),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: catchwordText,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: ArtPageFrame.toolsSpace,
            child: tools == null ? null : Center(child: tools),
          ),
        ] else if (catchwordSpace)
          SizedBox(
            height: IlluminatedFrame.catchwordSpace,
            child: Stack(
              children: [
                if (tools != null) Center(child: tools),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: catchwordText,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The current theme's art in the current mode; null for Zakhrafa or while
/// it loads.
ThemeArtPictures? watchThemeArt(BuildContext context, WidgetRef ref) {
  final tokens = context.tokens;
  if (tokens.style.art == null) return null;
  return ref
      .watch(themeArtProvider((style: tokens.style.id, mode: tokens.mode)))
      .value;
}
