import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'tajweed_marks_screen.dart';

/// Where the Assistant opens.
const assistantLocation = '/assistant';

/// The Assistant's icon, the same on every way in (home, the reader's
/// menus).
const assistantIcon = Icons.lightbulb_outline;

/// «المساعد»: the reader's helpers, one card each.
class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final helpers = [
      (
        Icons.format_color_text,
        l.tajweedMarksTitle,
        l.tajweedMarksSubtitle,
        tajweedMarksLocation,
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.assistantTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                child: Text(
                  l.assistantIntro,
                  style: TextStyle(color: t.muted, height: 1.6),
                ),
              ),
              for (final (icon, title, note, location) in helpers)
                _HelperCard(
                  icon: icon,
                  title: title,
                  note: note,
                  onTap: () => context.push(location),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One helper: its icon on a soft disc, its name and what it shows.
class _HelperCard extends StatelessWidget {
  const _HelperCard({
    required this.icon,
    required this.title,
    required this.note,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 10, 12, 10),
        leading: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.goldText.withValues(alpha: 0.12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: t.goldText, size: 26),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(color: t.ink, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(note, style: TextStyle(color: t.muted, height: 1.5)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
