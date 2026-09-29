import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../mushaf_providers.dart';
import 'illuminated_frame.dart';

/// Page 0 in the Zakhrafa style: the mushaf's cover.
class CoverPage extends ConsumerWidget {
  const CoverPage({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final basmala = ref.watch(basmalaProvider).value ?? '';
    final edition = ref.watch(editionProvider);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
        child: OrnateFrame(
          catchword: basmala.split(' ').take(2).join(' '),
          top: Text(
            basmala,
            style: const TextStyle(fontFamily: 'UthmanicHafs', fontSize: 17),
          ),
          bottom: Text(
            l.riwayaHafs,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          child: Semantics(
            header: true,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  child: Text(
                    l.coverTitle,
                    style: TextStyle(
                      fontFamily: 'ArefRuqaa',
                      fontWeight: FontWeight.w700,
                      fontSize: 54,
                      height: 1.4,
                      color: t.ink,
                    ),
                  ),
                ),
                Text(
                  l.coverSubtitle,
                  style: TextStyle(
                    fontFamily: 'KFGQPCAN',
                    fontSize: 18,
                    color: t.ink,
                  ),
                ),
                Container(
                  width: 180,
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 18),
                  color: t.marker,
                ),
                Text(
                  switch (edition) {
                    MushafEdition.madina1441 => l.editionNew,
                    MushafEdition.madina1405 => l.editionOld,
                    MushafEdition.shamarly => l.editionShamarly,
                  },
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: t.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pages 1 and 2 in the Zakhrafa style: the page inside the ornate frame,
/// with the surah's details in the cartouches (from Tanzil's metadata).
class OpeningPage extends ConsumerWidget {
  const OpeningPage({
    super.key,
    required this.page,
    required this.child,
    this.catchword,
    this.onPageTap,
    this.tools,
  });

  final int page;
  final Widget child;
  final String? catchword;
  final VoidCallback? onPageTap;
  final Widget? tools;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final digits = NumberFormatter(Localizations.localeOf(context));
    final surahs = ref.watch(surahsProvider).value;
    final s = surahs?[page - 1];
    final before = s == null
        ? null
        : surahs!
              .where((x) => x.revelationOrder == s.revelationOrder - 1)
              .firstOrNull;
    Widget two(String a, String b, {bool boldFirst = true}) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          a,
          style: TextStyle(
            fontWeight: boldFirst ? FontWeight.w700 : FontWeight.w400,
            fontSize: boldFirst ? 18 : 13,
          ),
        ),
        Text(
          b,
          style: TextStyle(
            fontWeight: boldFirst ? FontWeight.w400 : FontWeight.w700,
            fontSize: boldFirst ? 12 : 15,
          ),
        ),
      ],
    );
    return OrnateFrame(
      page: page,
      onPageTap: onPageTap,
      catchword: catchword,
      tools: tools,
      top: s == null
          ? const SizedBox.shrink()
          : two(
              l.surahWord(s.nameAr),
              l.openingInfo(
                s.revelation == 'meccan' ? l.meccan : l.medinan,
                digits(s.ayahCount),
                digits(s.id),
              ),
            ),
      bottom: s == null
          ? const SizedBox.shrink()
          : two(
              l.revealedOrder(digits(s.revelationOrder)),
              before == null ? '' : l.revealedAfter(before.nameAr),
              boldFirst: false,
            ),
      child: child,
    );
  }
}
