import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/mushaf_providers.dart';
import '../mushaf/presentation/mushaf_screen.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart';

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
    final soon = <(IconData, String)>[
      (Icons.task_alt_outlined, l.sectionHifz),
      (Icons.groups_outlined, l.sectionKhatma),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.appTitle,
                        style: TextStyle(
                          fontFamily: 'ArefRuqaa',
                          fontWeight: FontWeight.w700,
                          fontSize: 38,
                          height: 1.2,
                          color: t.headBg == t.paper ? t.headFg : t.ink,
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
                  onPressed: () => context.go('/mushaf'),
                  child: Text(l.openLabel),
                ),
              ),
            ),
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
                  onTap: () => context.go('/mushaf'),
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
                  onTap: () => context.push('/mushaf/tafsir?s=$surah&a=$ayah'),
                ),
                _SectionTile(
                  icon: Icons.headphones_outlined,
                  label: l.sectionListen,
                  note: l.openLabel,
                  onTap: () => context.push('/mushaf/audio'),
                ),
                for (final (icon, label) in soon)
                  _ComingSoonTile(icon: icon, label: label, note: l.comingSoon),
              ],
            ),
          ],
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
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: t.goldText, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(color: t.ink, fontWeight: FontWeight.w600),
              ),
              Text(note, style: TextStyle(color: t.accent, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonTile extends StatelessWidget {
  const _ComingSoonTile({
    required this.icon,
    required this.label,
    required this.note,
  });

  final IconData icon;
  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Semantics(
      label: '$label. $note',
      excludeSemantics: true,
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: t.goldText, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: t.ink, fontWeight: FontWeight.w600),
            ),
            Text(note, style: TextStyle(color: t.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
