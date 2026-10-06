import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../mushaf_providers.dart';
import 'illuminated_frame.dart';

/// The Shamarly edition's own cover, copied as printed on its first page
/// (tools/.cache/shamarly/pages/001.png). The contact address printed there
/// is left out.
const shamarlyCover = (
  title: 'مصحف الشمرلي',
  calligrapher: 'بخط محمد سعد إبراهيم الشهير بحداد',
  terms:
      'هذا المصحف مجاني ويجوز نسخه وتداوله على أن يعامل بكل احترام '
      'و لا يجوز استخدامه في الأغراض التجارية',
  release: 'الإصدار الثاني',
  date: 'العاشر من جمادى الأول عام ١٤٣١ هـ',
);

/// The mushaf's cover in the app's frame: page 0 of the Madina editions in
/// the Zakhrafa style, and page 1 of the Shamarly edition, which carries
/// the edition's own cover text and terms.
class CoverPage extends ConsumerWidget {
  const CoverPage({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final ink = t.ink;
    final muted = t.muted;
    final rule = t.marker;
    final basmala = ref.watch(basmalaProvider).value ?? '';
    final edition = ref.watch(editionProvider);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
        child: OrnateFrame(
          top: Text(
            basmala,
            style: const TextStyle(fontFamily: 'UthmanicHafs', fontSize: 17),
          ),
          bottom: Text(
            riwayaName(l, edition.riwaya),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          child: Semantics(
            header: true,
            child: edition == MushafEdition.shamarly
                ? _ShamarlyCover(ink: ink, muted: muted, rule: rule)
                : Column(
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
                            color: ink,
                          ),
                        ),
                      ),
                      Text(
                        l.coverSubtitle,
                        style: TextStyle(
                          fontFamily: 'KFGQPCAN',
                          fontSize: 18,
                          color: ink,
                        ),
                      ),
                      Container(
                        width: 180,
                        height: 1,
                        margin: const EdgeInsets.symmetric(vertical: 18),
                        color: rule,
                      ),
                      Text(
                        editionName(l, edition),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ShamarlyCover extends StatelessWidget {
  const _ShamarlyCover({
    required this.ink,
    required this.muted,
    required this.rule,
  });

  final Color ink;
  final Color muted;
  final Color rule;

  @override
  Widget build(BuildContext context) {
    final c = shamarlyCover;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            child: Text(
              c.title,
              style: TextStyle(
                fontFamily: 'ArefRuqaa',
                fontWeight: FontWeight.w700,
                fontSize: 54,
                height: 1.4,
                color: ink,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            c.calligrapher,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'UthmanTahaNaskh',
              fontSize: 17,
              color: ink,
            ),
          ),
          Container(
            width: 180,
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 18),
            color: rule,
          ),
          Text(
            c.terms,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.7, color: ink),
          ),
          const SizedBox(height: 18),
          Text(
            c.release,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: muted,
            ),
          ),
          Text(c.date, style: TextStyle(fontSize: 12, color: muted)),
        ],
      ),
    );
  }
}

/// The first two pages of the text in the Zakhrafa style (pages 1 and 2 of
/// the Madina editions, 2 and 3 of the Shamarly): the page inside the
/// ornate frame,
/// with the surah's details in the cartouches (from Tanzil's metadata).
class OpeningPage extends ConsumerWidget {
  const OpeningPage({
    super.key,
    required this.page,
    required this.surah,
    required this.child,
    this.onPageTap,
    this.onSurahTap,
    this.onSurahLongPress,
  });

  final int page;

  /// The surah this opening page starts (1 or 2).
  final int surah;
  final Widget child;
  final VoidCallback? onPageTap;

  /// The surah's name was tapped (opens the index, as on other pages).
  final VoidCallback? onSurahTap;

  /// A long press on the surah's name (shares the surah as pictures).
  final VoidCallback? onSurahLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final digits = NumberFormatter(Localizations.localeOf(context));
    final surahs = ref.watch(surahsProvider).value;
    final s = surahs?[surah - 1];
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
      top: s == null
          ? const SizedBox.shrink()
          : Semantics(
              button: onSurahTap != null,
              onLongPress: onSurahLongPress,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSurahTap,
                onLongPress: onSurahLongPress,
                child: two(
                  l.surahWord(s.nameAr),
                  l.openingInfo(
                    s.revelation == 'meccan' ? l.meccan : l.medinan,
                    // The edition's own count (a riwaya counts differently).
                    digits(
                      ref.watch(surahAyahCountProvider(surah)).value ??
                          s.ayahCount,
                    ),
                    digits(s.id),
                  ),
                ),
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
