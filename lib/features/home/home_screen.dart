import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../assistant/assistant_screen.dart';
import '../hifz/hifz_providers.dart';
import '../khatma/domain/khatmah.dart' show EntryPoint;
import '../khatma/khatma_providers.dart';
import '../mushaf/mushaf_providers.dart';
import '../mushaf/presentation/mushaf_screen.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart';
import '../tasmee/presentation/tasmee_setup_screen.dart' show showTasmeeSetup;
import 'whats_new.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final position = ref.watch(readingPositionProvider).value;
    final surahs = ref.watch(surahsProvider).value;
    final surah = position == null || surahs == null ? 1 : position.surah;
    final ayah = position?.ayah ?? 1;
    maybeShowWhatsNew(context, ref);
    if (context.tokens.elderly) {
      return const _ElderlyHome();
    }
    final khatma = ref.watch(khatmaStatusProvider).value;
    final portion = khatma?.todayPortion;
    final due = dueToday(
      ref.watch(srsItemsProvider).value ?? const [],
      DateTime.now(),
    ).length;

    return Scaffold(
      body: SafeArea(
        // A wide window (a tablet, the Mac) keeps a phone's column: the
        // tiles stay their size instead of growing with the width.
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              l.appTitle,
                              style: TextStyle(
                                fontFamily: 'ArefRuqaa',
                                fontWeight: FontWeight.w700,
                                fontSize: 38,
                                height: 1.2,
                                color: t.headBg == t.paper ? t.headFg : t.ink,
                              ),
                            ),
                          ),
                          Text(
                            l.appTagline,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: t.muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton.outlined(
                      tooltip: l.openSettings,
                      onPressed: () => context.go('/settings'),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                    leading: Icon(Icons.menu_book, color: t.goldText, size: 30),
                    title: Text(
                      l.continueReading,
                      style: TextStyle(
                        color: t.goldText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: position == null || surahs == null
                        ? null
                        : Text(
                            l.continueReadingAt(
                              surahName(context, surahs[position.surah - 1]),
                              digits(position.ayah),
                              digits(position.page),
                            ),
                          ),
                    trailing: FilledButton(
                      onPressed: () => context.go('/mushaf?entry=home'),
                      child: Text(l.openLabel),
                    ),
                  ),
                ),
                if (khatma != null && portion != null) ...[
                  const SizedBox(height: 12),
                  // The «Today» card: the khatma's portion for today.
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push('/khatma'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.homeTodayTitle,
                                    style: TextStyle(
                                      color: t.goldText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${l.khatmaToday}: ${l.khatmaPagesRange(digits(portion.range.from), digits(portion.range.to))}',
                                  ),
                                ],
                              ),
                            ),
                            FilledButton(
                              onPressed: () async => context.go(
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
                              child: Text(l.khatmaReadNow),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                  children: [
                    _SectionTile(
                      icon: Icons.menu_book_outlined,
                      label: l.sectionMushaf,
                      note: l.mushafOpen,
                      onTap: () => context.go('/mushaf?entry=home'),
                    ),
                    _SectionTile(
                      icon: Icons.search_outlined,
                      label: l.sectionSearch,
                      note: l.openLabel,
                      onTap: () => context.go('/search'),
                    ),
                    _SectionTile(
                      icon: Icons.auto_stories_outlined,
                      label: l.sectionTafsir,
                      note: l.openLabel,
                      onTap: () =>
                          context.push('/mushaf/tafsir?s=$surah&a=$ayah'),
                    ),
                    _SectionTile(
                      icon: Icons.headphones_outlined,
                      label: l.sectionListen,
                      note: l.openLabel,
                      onTap: () => context.push('/mushaf/audio'),
                    ),
                    _SectionTile(
                      icon: Icons.groups_outlined,
                      label: l.sectionKhatma,
                      note: portion != null
                          ? l.khatmaTilePages(digits(portion.pages))
                          : khatma != null
                          ? l.khatmaTodayDone
                          : l.khatmaTileStart,
                      onTap: () => context.push('/khatma'),
                    ),
                    _SectionTile(
                      icon: Icons.task_alt_outlined,
                      label: l.sectionHifz,
                      note: due > 0
                          ? '${l.hifzToday} ${digits(due)}'
                          : l.hifzTileNote,
                      onTap: () => context.push('/hifz'),
                    ),
                    _SectionTile(
                      icon: Icons.graphic_eq,
                      label: l.tasmeeTitle,
                      note: l.tasmeeSelectRange,
                      onTap: () => showTasmeeSetup(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // The seventh section spans the grid's width under its two
                // rows, so the 3×2 grid stays whole.
                _WideSectionTile(
                  icon: assistantIcon,
                  label: l.assistantTitle,
                  note: l.tajweedMarksTitle,
                  onTap: () => context.push(assistantLocation),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.label,
    required this.note,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Semantics(
      button: true,
      label: '$label. $note',
      excludeSemantics: true,
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // A translucent disc behind the icon.
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.goldText.withValues(alpha: 0.12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(icon, color: t.goldText, size: 24),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: t.ink, fontWeight: FontWeight.w600),
              ),
              Text(note, style: TextStyle(color: t.goldText, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A section as wide as the grid: its icon on the same disc as the tiles,
/// its name and note beside it, and an arrow to open it.
class _WideSectionTile extends StatelessWidget {
  const _WideSectionTile({
    required this.icon,
    required this.label,
    required this.note,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Semantics(
      button: true,
      label: '$label. $note',
      excludeSemantics: true,
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 12, 14),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.goldText.withValues(alpha: 0.12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(icon, color: t.goldText, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: t.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        note,
                        style: TextStyle(color: t.goldText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: t.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Elderly mode's home: only the three main tasks, as large labelled
/// buttons, and settings (with its name) to leave the mode.
class _ElderlyHome extends ConsumerWidget {
  const _ElderlyHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final position = ref.watch(readingPositionProvider).value;
    final surahs = ref.watch(surahsProvider).value;
    final khatma = ref.watch(khatmaStatusProvider).value;
    final portion = khatma?.todayPortion;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l.appTitle,
                      style: TextStyle(
                        fontFamily: 'ArefRuqaa',
                        fontWeight: FontWeight.w700,
                        fontSize: 40,
                        height: 1.2,
                        color: t.headBg == t.paper ? t.headFg : t.ink,
                      ),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/settings'),
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(l.settingsTitle),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _BigAction(
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
              onTap: () => context.go('/mushaf?entry=home'),
            ),
            // The khatma's portion for today (plan 6: elderly mode's home
            // has its own card): a tap opens the portion.
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
    final t = context.tokens.colors;
    final fg = primary ? t.onControl : t.ink;
    return Semantics(
      button: true,
      label: detail == null ? label : '$label. $detail',
      excludeSemantics: true,
      // The InkWell below is excluded with the rest: the action is here.
      onTap: onTap,
      child: Material(
        color: primary ? t.control : t.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: primary ? t.control : t.border, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(icon, size: 40, color: fg),
                  const SizedBox(width: 20),
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
                          Text(
                            detail!,
                            style: TextStyle(fontSize: 17, color: fg),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
