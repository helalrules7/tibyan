import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final sections = <(IconData, String)>[
      (Icons.menu_book_outlined, l.sectionMushaf),
      (Icons.auto_stories_outlined, l.sectionTafsir),
      (Icons.headphones_outlined, l.sectionListen),
      (Icons.task_alt_outlined, l.sectionHifz),
      (Icons.groups_outlined, l.sectionKhatma),
      (Icons.search_outlined, l.sectionSearch),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.homeComingTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: t.goldText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.homeComingBody,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
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
                for (final (icon, label) in sections)
                  _ComingSoonTile(icon: icon, label: label, note: l.comingSoon),
              ],
            ),
          ],
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
