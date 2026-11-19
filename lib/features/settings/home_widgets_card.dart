// «الودجات» in the settings: the home screen widgets the app offers, a
// button that places one on the home screen where the system allows it
// (Android 8 and later), how to add one elsewhere (iOS, macOS), and a
// button that rewrites their data now.
import 'package:flutter/foundation.dart';

import '../../core/ui/app_toast.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/settings/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../khatma/domain/day.dart';
import '../khatma/khatma_providers.dart';
import '../khatma/services/home_widget_sync.dart';
import '../khatma/services/verse_of_day.dart';
import '../mushaf/mushaf_providers.dart';

/// Whether the launcher can place a widget when the app asks (Android).
final _canPinProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
  try {
    return await HomeWidget.isRequestPinWidgetSupported() ?? false;
  } catch (_) {
    return false;
  }
});

/// Rewrites every widget's data: the khatma's days and a month of verses.
Future<void> refreshHomeWidgets(WidgetRef ref) async {
  try {
    await ref.read(khatmaServiceProvider).refresh();
  } catch (e) {
    debugPrint('home widgets: refresh failed: $e');
  }
  final settings = ref.read(settingsProvider);
  await ref
      .read(homeWidgetSyncProvider)
      .writeVerses(
        await verseOfDayEntries(
          ayahById: ref.read(mushafRepositoryProvider).ayahById,
          surahs: await ref.read(surahsProvider.future),
          l: lookupAppLocalizations(settings.locale ?? const Locale('ar')),
          from: Day.today(),
        ),
      );
}

class HomeWidgetsCard extends ConsumerStatefulWidget {
  const HomeWidgetsCard({super.key});

  @override
  ConsumerState<HomeWidgetsCard> createState() => _HomeWidgetsCardState();
}

class _HomeWidgetsCardState extends ConsumerState<HomeWidgetsCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final muted = TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: 12,
    );
    final canPin = ref.watch(_canPinProvider).value ?? false;
    final widgets = [
      (
        Icons.format_quote_outlined,
        l.verseOfDayTitle,
        l.widgetVerseHint,
        PluginHomeWidgetSync.androidVerseProvider,
      ),
      (
        Icons.event_repeat_outlined,
        l.khatmaTitle,
        l.widgetKhatmaHint,
        PluginHomeWidgetSync.androidProvider,
      ),
      (
        Icons.apps_outlined,
        l.widgetActionsTitle,
        l.widgetActionsHint,
        PluginHomeWidgetSync.androidActionsProvider,
      ),
    ];
    final howTo = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => l.widgetHowToIos,
      TargetPlatform.macOS => l.widgetHowToMac,
      TargetPlatform.android => canPin ? null : l.widgetHowToAndroid,
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (icon, name, hint, android) in widgets)
          ListTile(
            contentPadding: const EdgeInsetsDirectional.symmetric(
              horizontal: 16,
            ),
            leading: Icon(icon),
            title: Text(name),
            subtitle: Text(hint, style: muted),
            trailing: canPin
                ? FilledButton.tonal(
                    onPressed: () => HomeWidget.requestPinWidget(
                      qualifiedAndroidName: android,
                    ),
                    child: Text(l.widgetAdd),
                  )
                : null,
          ),
        if (howTo != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
            child: Text(howTo, style: muted),
          ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      await refreshHomeWidgets(ref);
                      if (!mounted) return;
                      setState(() => _busy = false);
                      messenger?.showSnackBar(
                        appToast(content: Text(l.widgetRefreshed)),
                      );
                    },
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(l.widgetRefresh),
            ),
          ),
        ),
      ],
    );
  }
}
