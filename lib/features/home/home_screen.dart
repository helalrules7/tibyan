import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/crash/crash_consent.dart';
import '../../core/privacy/store_privacy_prompt.dart';
import '../../core/db/content_database.dart' show SurahRow;
import '../../core/settings/settings_controller.dart'
    show sharedPreferencesProvider;
import '../../core/theme/app_theme.dart';
import '../../core/theme/interface_style.dart';
import '../../core/theme/ornaments.dart';
import '../../core/ui/look_kit.dart';
import '../../core/ui/surah_name.dart';
import '../../l10n/app_localizations.dart';
import '../hifz/hifz_providers.dart';
import '../khatma/domain/khatmah.dart' show EntryPoint;
import '../khatma/khatma_providers.dart';
import '../tasbih/presentation/tasbih_screen.dart'
    show tasbihIcon, tasbihLocation;
import '../tasbih/tasbih_providers.dart' show tasbihTodayProvider;
import '../mushaf/mushaf_providers.dart';
import '../mushaf/presentation/continue_snapshot.dart';
import '../mushaf/presentation/mushaf_screen.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart';
import '../tasmee/presentation/tasmee_setup_screen.dart' show showTasmeeSetup;
import 'whats_new.dart';
import '../../core/ui/responsive.dart';
import '../../core/ui/meta_separator.dart';

/// How much larger the home's cards and buttons draw on a tablet or a
/// desktop window, so the extra room is used rather than left empty.
double _scale(BuildContext context) => context.isExpanded ? 1.3 : 1.0;

/// A section of the home: its icon, name, a short note and where it goes.
typedef _Section = ({
  IconData icon,
  String label,
  // A live line under the label (today's portion, verses due); null when
  // there is nothing to say, rather than a filler «افتح».
  String? note,
  VoidCallback onTap,
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The store's privacy notice comes first; the other sheets wait for a
    // later launch.
    if (storePrivacyPending(ref)) {
      maybeShowStorePrivacy(context, ref);
    } else {
      final whatsNewNow = shouldShowWhatsNew(
        ref.read(sharedPreferencesProvider),
      );
      maybeShowWhatsNew(context, ref);
      maybeAskCrashConsent(context, ref, busy: whatsNewNow);
    }
    if (context.tokens.elderly) return const _ElderlyHome();
    final l = AppLocalizations.of(context);
    final digits = NumberFormatter(Localizations.localeOf(context));
    final position = ref.watch(readingPositionProvider).value;
    final surahs = ref.watch(surahsProvider).value;
    final surah = position == null || surahs == null ? 1 : position.surah;
    final ayah = position?.ayah ?? 1;
    final khatma = ref.watch(khatmaStatusProvider).value;
    final portion = khatma?.todayPortion;
    final due = dueToday(
      ref.watch(srsItemsProvider).value ?? const [],
      DateTime.now(),
    ).length;
    final tasbihToday = ref.watch(tasbihTodayProvider);

    final sections = <_Section>[
      (
        icon: railIcon(RailItem.mushaf),
        label: l.sectionMushaf,
        note: null,
        onTap: () => context.go('/mushaf?entry=home'),
      ),
      (
        icon: railIcon(RailItem.listen),
        label: l.sectionListen,
        note: null,
        onTap: () => context.push('/mushaf/audio'),
      ),
      (
        icon: railIcon(RailItem.tafsir),
        label: l.sectionTafsir,
        note: null,
        onTap: () => context.push('/mushaf/tafsir?s=$surah&a=$ayah'),
      ),
      (
        icon: railIcon(RailItem.search),
        label: l.sectionSearch,
        note: null,
        onTap: () => context.go('/search'),
      ),
      (
        icon: railIcon(RailItem.khatma),
        label: l.sectionKhatma,
        note: portion != null
            ? l.khatmaTilePages(digits(portion.pages))
            : khatma != null
            ? l.khatmaTodayDone
            : l.khatmaTileStart,
        onTap: () => context.push('/khatma'),
      ),
      (
        icon: railIcon(RailItem.hifz),
        label: l.sectionHifz,
        note: due > 0 ? '${l.hifzToday} ${digits(due)}' : l.hifzTileNote,
        onTap: () => context.push('/hifz'),
      ),
      (
        icon: railIcon(RailItem.tasbih),
        label: l.sectionTasbih,
        note: tasbihToday > 0
            ? l.tasbihTileToday(digits(tasbihToday))
            : l.tasbihTileStart,
        onTap: () => context.push(tasbihLocation),
      ),
      (
        icon: railIcon(RailItem.tasmee),
        label: l.tasmeeTileLabel,
        note: l.tasmeeSelectRange,
        onTap: () => showTasmeeSetup(context),
      ),
    ];

    // The page grows from this card (see [ContinueTransition]).
    final hero = Builder(
      builder: (card) => _ContinueCard(
        surahRow: position == null || surahs == null
            ? null
            : surahs[position.surah - 1],
        detail: position == null || surahs == null
            ? null
            : l.continueReadingAt(
                surahName(context, surahs[position.surah - 1]),
                digits(position.ayah),
                digits(position.page),
              ),
        onOpen: () => openContinueReading(
          card,
          ref,
          () => context.go('/mushaf?entry=home'),
        ),
      ),
    );
    final today = khatma != null && portion != null
        ? _TodayCard(
            title: l.homeTodayTitle,
            detail:
                '${l.khatmaToday}: ${l.khatmaPagesRange(digits(portion.range.from), digits(portion.range.to))}',
            done:
                1 -
                portion.pages /
                    (portion.range.to - portion.range.from + 1).clamp(1, 604),
            percent: digits(
              ((1 -
                          portion.pages /
                              (portion.range.to - portion.range.from + 1).clamp(
                                1,
                                604,
                              )) *
                      100)
                  .round()
                  .clamp(0, 100),
            ),
            onTap: () async => context.go(
              await ref
                  .read(khatmaServiceProvider)
                  .routeFor(
                    Uri(
                      queryParameters: {
                        'page': '${portion.range.from}',
                        'edition': khatma.edition.name,
                      },
                    ),
                    entry: EntryPoint.home,
                  ),
            ),
          )
        : null;
    final journey = _JourneyCard(progress: ref.watch(journeyProvider));

    return LookScaffold(
      maxWidth: double.infinity,
      selected: RailItem.home,
      hero: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            // A laptop or tablet: the reading cards and the sections side
            // by side, so the window is used instead of a lone column.
            final twoColumns = box.maxWidth >= 760;
            final grid = _SectionsGrid(
              sections: sections,
              columns: twoColumns ? 4 : 4,
            );
            if (twoColumns) {
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: ContentWidth.full,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                    children: [
                      const _TopBar(),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                hero,
                                if (today != null) ...[
                                  const SizedBox(height: 16),
                                  today,
                                ],
                                const SizedBox(height: 16),
                                journey,
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(flex: 6, child: grid),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600, // the tiles grid is tuned to this width
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    const _TopBar(),
                    const SizedBox(height: 12),
                    hero,
                    if (today != null) ...[const SizedBox(height: 16), today],
                    const SizedBox(height: 16),
                    journey,
                    const SizedBox(height: 24),
                    grid,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The brand and the search and settings buttons.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final look = context.look;
    final wide = isWide(context);
    final Widget brand = switch (look.style) {
      InterfaceStyle.makhtuta => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        decoration: BoxDecoration(
          color: look.frame,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: look.gold, width: 1.2),
        ),
        child: TibyanWordmark(color: look.onFrame, height: 40),
      ),
      InterfaceStyle.handasi => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: 28,
              child: CustomPaint(
                painter: StarPainter(look.accent, look.accent),
              ),
            ),
          ),
          const SizedBox(width: 10),
          TibyanWordmark(color: look.ink, height: 42),
        ],
      ),
      InterfaceStyle.layli => TibyanWordmark(color: look.goldText, height: 46),
    };
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          if (wide)
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l.appTagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: lookTitleStyle(context, size: 22 * _scale(context)),
                ),
              ),
            )
          else ...[
            brand,
            const Spacer(),
          ],
          IconButton(
            tooltip: l.sectionSearch,
            onPressed: () => context.go('/search'),
            icon: Icon(Icons.search, color: look.ink),
          ),
          IconButton(
            tooltip: l.openSettings,
            onPressed: () => context.go('/settings'),
            icon: Icon(Icons.tune, color: look.ink),
          ),
        ],
      ),
    );
  }
}

/// The «continue reading» card: an illuminated panel in «مخطوطة», a
/// pointed arch in «هندسي» and «ليلي ذهبي».
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.surahRow,
    required this.detail,
    required this.onOpen,
  });

  final SurahRow? surahRow;
  final String? detail;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return Semantics(
      container: true,
      label: [AppLocalizations.of(context).continueReading, ?detail].join('. '),
      child: switch (look.style) {
        InterfaceStyle.makhtuta => _panel(context),
        _ => _arch(context),
      },
    );
  }

  Widget _text(
    BuildContext context,
    Color ink,
    Color sub, {
    bool center = false,
  }) {
    final l = AppLocalizations.of(context);
    final look = context.look;
    final s = surahRow;
    final k = _scale(context);
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.homeContinueHint,
            style: TextStyle(fontSize: 13 * k, color: sub),
          ),
          if (s != null)
            SurahNameText(
              surah: s.id,
              name: s.nameAr,
              size: (look.elderly ? 50 : 44) * k,
              color: ink,
              height: 1.7,
            ),
          if (detail != null)
            MetaText(
              detail!,
              textAlign: center ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                fontSize: 14 * k,
                fontWeight: FontWeight.w500,
                color: sub,
              ),
            ),
        ],
      ),
    );
  }

  Widget _button(BuildContext context, Color bg, Color fg, double radius) {
    final l = AppLocalizations.of(context);
    final k = _scale(context);
    return FilledButton(
      onPressed: onOpen,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: Size(160 * k, context.look.target * k),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        textStyle: Theme.of(context).textTheme.labelLarge
            ?.copyWith(fontSize: 15 * k, fontWeight: FontWeight.w600),
      ),
      child: Text(l.continueReading),
    );
  }

  Widget _panel(BuildContext context) {
    final look = context.look;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: look.frame,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: look.surface,
          border: Border.all(color: look.gold, width: 1.4),
          borderRadius: BorderRadius.circular(3),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          children: [
            const ExcludeSemantics(child: TazhibBand()),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _text(context, look.ink, look.sub)),
                if (surahRow != null)
                  ExcludeSemantics(
                    child: StarBadge(
                      text: NumberFormatter(Localizations.localeOf(context))(
                        surahRow!.id,
                      ),
                      fill: look.gold.withValues(alpha: .14),
                      line: look.gold,
                      textColor: look.accent,
                      size: 84,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: _button(context, look.control, look.onControl, 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _arch(BuildContext context) {
    final look = context.look;
    // «هندسي»: the arch in teal with a star lattice; «ليلي ذهبي»: a night
    // sky in blue and gold.
    final layli = look.isLayli;
    final (:sky, :rim, :ink, :sub, :buttonBg, :buttonFg) = heroArchColors(look);
    final k = _scale(context);
    return SizedBox(
      // The texts and the button grow with the reader's text size.
      height:
          (look.elderly ? 340 : 300) * k +
          MediaQuery.textScalerOf(context).scale(48) -
          48,
      child: Stack(
        children: [
          const Positioned.fill(child: HeroArch()),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 76 * k, 20, 20 * k),
              child: Column(
                children: [
                  _text(context, ink, sub, center: true),
                  const Spacer(),
                  _button(context, buttonBg, buttonFg, layli ? 24 : 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «محفوظ ١٢٠ آية، منها ٨٠ متقنة», or how to begin.
String journeyLine(BuildContext context, Journey p) {
  final l = AppLocalizations.of(context);
  final digits = NumberFormatter(Localizations.localeOf(context));
  if (p.memorized == 0) return l.hifzJourneyEmpty;
  return l.hifzJourneyLine(
    p.memorized,
    digits(p.memorized),
    digits(p.mastered),
  );
}

/// «مسيرة الحفظ»: memorized and mastered verses, beside the khatma's card.
/// A calm share, no streaks or levels.
class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.progress});

  final Journey progress;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = progress;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final share = p.memorized == 0 ? 0.0 : p.mastered / p.memorized;
    return _TodayCard(
      title: l.hifzJourney,
      detail: journeyLine(context, p),
      done: share,
      percent: digits((share * 100).round()),
      onTap: () => context.push('/hifz?tab=progress'),
    );
  }
}

/// Today's khatma portion with its progress ring.
class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.title,
    required this.detail,
    required this.done,
    required this.percent,
    required this.onTap,
  });

  final String title;
  final String detail;
  final double done;
  final String percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final k = _scale(context);
    return Semantics(
      button: true,
      label: '$title. $detail',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: look.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(look.radius),
          side: BorderSide(color: look.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(16 * k),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 60 * k,
                  child: CustomPaint(
                    painter: Ring(
                      done.clamp(0, 1),
                      look.isHandasi ? look.accent2 : look.gold,
                      look.ink.withValues(alpha: .1),
                      width: 5,
                    ),
                    child: Center(
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? '$percent٪'
                            : '$percent%',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          fontSize: 14 * k,
                          fontWeight: FontWeight.w600,
                          color: look.ink,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14 * k),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16 * k,
                          fontWeight: FontWeight.w600,
                          color: look.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: TextStyle(fontSize: 13 * k, color: look.sub),
                      ),
                    ],
                  ),
                ),
                // Mirrors itself: points left in Arabic, right in English.
                Icon(Icons.chevron_right, color: look.sub),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The sections as medallions (مخطوطة), tiles (هندسي) or arches (ليلي).
class _SectionsGrid extends StatelessWidget {
  const _SectionsGrid({required this.sections, required this.columns});

  final List<_Section> sections;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 12),
          child: Semantics(
            header: true,
            child: Text(
              l.homeSections,
              style: lookTitleStyle(context, size: 20 * _scale(context)),
            ),
          ),
        ),
        // Rows of equal-width tiles, each row as tall as its tallest tile,
        // so a label never overflows a fixed cell: not on a small phone,
        // not in a tablet's narrow side column, not at a larger text size.
        // Wide windows draw each section as a card; a row's cards share
        // its height, and fewer columns are used when a tile would be
        // narrower than its icon and label need.
        LayoutBuilder(
          builder: (context, box) {
            final card = context.isExpanded;
            final gap = card ? 16.0 : 10.0;
            final minTile = card ? 132.0 * _scale(context) : 0.0;
            final fit = minTile <= 0
                ? columns
                : ((box.maxWidth + gap) / (minTile + gap)).floor();
            final n = fit.clamp(2, columns);
            Widget row(int i) => Row(
              crossAxisAlignment: card
                  ? CrossAxisAlignment.stretch
                  : CrossAxisAlignment.start,
              children: [
                for (var j = i; j < i + n; j++) ...[
                  if (j > i) SizedBox(width: gap),
                  Expanded(
                    child: j < sections.length
                        ? _SectionTile(sections[j])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            );
            return Column(
              children: [
                for (var i = 0; i < sections.length; i += n) ...[
                  if (i > 0) SizedBox(height: card ? 16 : 12),
                  card ? IntrinsicHeight(child: row(i)) : row(i),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile(this.s);

  final _Section s;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final card = context.isExpanded;
    final k = _scale(context);
    final Widget icon = SectionIcon(s.icon, k: k);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: card
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        icon,
        SizedBox(height: 8 * k),
        Text(
          s.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13 * k,
            fontWeight: FontWeight.w600,
            color: look.ink,
          ),
        ),
        if (s.note case final note?)
          Text(
            note,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11 * k, color: look.sub),
          ),
      ],
    );
    return Semantics(
      button: true,
      label: s.note == null ? s.label : '${s.label}. ${s.note}',
      excludeSemantics: true,
      onTap: s.onTap,
      child: card
          // A wide window: a bordered card, the whole of it a target.
          ? Material(
              color: look.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(look.radius),
                side: BorderSide(color: look.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: s.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 16,
                  ),
                  child: Center(child: content),
                ),
              ),
            )
          : InkWell(
              onTap: s.onTap,
              borderRadius: BorderRadius.circular(look.radius),
              child: content,
            ),
    );
  }
}

/// Elderly mode's home: only the main tasks, as large labelled buttons,
/// and settings (with its name) to leave the mode.
class _ElderlyHome extends ConsumerWidget {
  const _ElderlyHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final look = context.look;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final position = ref.watch(readingPositionProvider).value;
    final surahs = ref.watch(surahsProvider).value;
    final khatma = ref.watch(khatmaStatusProvider).value;
    final portion = khatma?.todayPortion;
    return LookScaffold(
      maxWidth: double.infinity,
      selected: RailItem.home,
      hero: true,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ContentWidth.text),
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
              children: [
                // Wraps the settings button under the wordmark when a small
                // phone at a large text size has no room for both.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TibyanWordmark(
                      color: look.isLayli ? look.goldText : look.ink,
                      height: 52,
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/settings'),
                      icon: const Icon(Icons.tune),
                      label: Text(l.settingsTitle),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Builder(
                  builder: (button) => _BigAction(
                    icon: Icons.menu_book,
                    label: l.continueReading,
                    detail: position == null || surahs == null
                        ? null
                        : l.continueReadingAt(
                            surahName(context, surahs[position.surah - 1]),
                            digits(position.ayah),
                            digits(position.page),
                          ),
                    primary: true,
                    onTap: () => openContinueReading(
                      button,
                      ref,
                      () => context.go('/mushaf?entry=home'),
                    ),
                  ),
                ),
                // The khatma's portion for today (plan 6: elderly mode's
                // home has its own card): a tap opens the portion.
                if (khatma != null && !khatma.complete) ...[
                  const SizedBox(height: 16),
                  _BigAction(
                    icon: Icons.auto_stories_outlined,
                    label: l.homeTodayTitle,
                    detail: portion != null
                        ? '${l.khatmaToday}: ${l.khatmaPagesRange(digits(portion.range.from), digits(portion.range.to))}'
                        : l.khatmaTodayDone,
                    onTap: () async {
                      if (portion == null) {
                        unawaited(context.push('/khatma'));
                        return;
                      }
                      final route = await ref
                          .read(khatmaServiceProvider)
                          .routeFor(
                            Uri(
                              scheme: 'tibyan',
                              host: 'khatmah',
                              path: '/${khatma.khatmah.uuid}/continue',
                            ),
                            entry: EntryPoint.home,
                          );
                      if (context.mounted) context.go(route);
                    },
                  ),
                ],
                const SizedBox(height: 16),
                _BigAction(
                  icon: Icons.task_alt_outlined,
                  label: l.hifzJourney,
                  detail: journeyLine(context, ref.watch(journeyProvider)),
                  onTap: () => context.push('/hifz?tab=progress'),
                ),
                const SizedBox(height: 16),
                _BigAction(
                  icon: tasbihIcon,
                  label: l.sectionTasbih,
                  detail: ref.watch(tasbihTodayProvider) > 0
                      ? l.tasbihTileToday(
                          digits(ref.watch(tasbihTodayProvider)),
                        )
                      : null,
                  onTap: () => context.push(tasbihLocation),
                ),
                const SizedBox(height: 16),
                _BigAction(
                  icon: Icons.headphones_outlined,
                  label: l.sectionListen,
                  onTap: () => context.push('/mushaf/audio'),
                ),
                const SizedBox(height: 16),
                _BigAction(
                  icon: Icons.search,
                  label: l.sectionSearch,
                  onTap: () => context.go('/search'),
                ),
                const SizedBox(height: 16),
                _BigAction(
                  icon: Icons.graphic_eq,
                  label: l.tasmeeTitle,
                  detail: l.tasmeeDescription,
                  onTap: () => showTasmeeSetup(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BigAction extends StatelessWidget {
  const _BigAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.detail,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final fg = primary ? look.onControl : look.ink;
    final Widget medallion = SizedBox.square(
      dimension: 60,
      child: switch (look.style) {
        InterfaceStyle.layli => CustomPaint(
          painter: ArchBorder(primary ? fg : look.gold, spring: .5, inset: 4),
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Icon(icon, size: 30, color: primary ? fg : look.goldText),
          ),
        ),
        _ => CustomPaint(
          painter: StarPainter(
            primary ? fg.withValues(alpha: .12) : look.accent,
            primary ? fg : look.gold,
          ),
          child: Icon(icon, size: 30, color: primary ? fg : look.surface),
        ),
      },
    );
    return Semantics(
      button: true,
      label: detail == null ? label : '$label. $detail',
      excludeSemantics: true,
      // The InkWell below is excluded with the rest: the action is here.
      onTap: onTap,
      child: Material(
        color: primary ? look.control : look.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(look.isMakhtuta ? 6 : 20),
          side: BorderSide(
            color: primary
                ? look.control
                : (look.isHandasi ? look.line : look.gold),
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  medallion,
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: fg,
                          ),
                        ),
                        if (detail != null)
                          MetaText(
                            detail!,
                            style: TextStyle(fontSize: 17, color: fg),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 30, color: fg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
