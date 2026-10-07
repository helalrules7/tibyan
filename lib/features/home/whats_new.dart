import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// The «what's new» notes: shown once after an update that brings them,
/// never on a first install (the reader is new to all of it), and from
/// the settings at any time. Bump [whatsNewId] when the list changes.
const whatsNewId = '2026-10-b';

/// Where the last notes seen are remembered.
const whatsNewSeenKey = 'app.whatsNewSeen';

typedef WhatsNewItem = ({IconData icon, String title, String body});

List<WhatsNewItem> whatsNewItems(AppLocalizations l) => [
  (icon: Icons.flag_outlined, title: l.newKhatmah, body: l.newKhatmahBody),
  (icon: Icons.mic_none, title: l.newTasmee, body: l.newTasmeeBody),
  (icon: Icons.timer_outlined, title: l.newSajdah, body: l.newSajdahBody),
  (
    icon: Icons.lightbulb_outline,
    title: l.newAssistant,
    body: l.newAssistantBody,
  ),
  (icon: Icons.fullscreen, title: l.newFocus, body: l.newFocusBody),
];

/// Whether the notes should open now: the reader has used the app before
/// (onboarding done) and has not seen these notes.
bool shouldShowWhatsNew(SharedPreferences prefs) =>
    (prefs.getBool('settings.onboardingDone') ?? false) &&
    prefs.getString(whatsNewSeenKey) != whatsNewId;

/// Marks the notes as seen (also on a first install, so they never show
/// for what the reader meets anyway).
Future<void> markWhatsNewSeen(SharedPreferences prefs) =>
    prefs.setString(whatsNewSeenKey, whatsNewId);

/// Opens the notes once per update, after the first frame of [context].
void maybeShowWhatsNew(BuildContext context, WidgetRef ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  if (!shouldShowWhatsNew(prefs)) return;
  // Seen as soon as offered: it never opens twice.
  markWhatsNewSeen(prefs);
  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) showWhatsNew(context);
  });
}

Future<void> showWhatsNew(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Semantics(
            header: true,
            child: Text(
              l.whatsNewTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          for (final item in whatsNewItems(l))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(item.icon, color: t.goldText),
              title: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(item.body, style: TextStyle(color: t.muted)),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(l.whatsNewDone),
          ),
        ],
      ),
    );
  },
);
