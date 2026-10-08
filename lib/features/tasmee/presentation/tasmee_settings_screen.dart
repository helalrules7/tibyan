import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/model_store.dart';
import '../data/tasmee_backend.dart';
import '../data/tasmee_settings.dart';
import '../domain/alignment_engine.dart';
import '../domain/tasmee_session_request.dart';
import '../domain/word_match.dart';
import 'tasmee_sheets.dart';
import 'tasmee_style.dart';

/// The model on the device: installed or not, and the space it takes.
final tasmeeModelInfoProvider =
    FutureProvider.autoDispose<(InstalledModel?, int)>((ref) async {
      final backend = ref.watch(tasmeeBackendProvider);
      return (await backend.installedModel(), await backend.usedBytes());
    });

/// Settings › Tasmee: the defaults of a session, the model, the history.
class TasmeeSettingsScreen extends ConsumerWidget {
  const TasmeeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final s = ref.watch(tasmeeSettingsProvider);
    final c = ref.read(tasmeeSettingsProvider.notifier);
    final model = ref.watch(tasmeeModelInfoProvider);

    Widget title(String text) => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 16, 8, 6),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: TextStyle(color: t.goldText, fontWeight: FontWeight.w700),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.tasmeeTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          title(l.tasmeeMode),
          Card(
            child: RadioGroup<TasmeeMode>(
              groupValue: s.mode,
              onChanged: (v) => v == null ? null : c.setMode(v),
              child: Column(
                children: [
                  RadioListTile(
                    value: TasmeeMode.continuous,
                    title: Text(l.tasmeeContinuous),
                    subtitle: Text(l.tasmeeContinuousHint),
                  ),
                  RadioListTile(
                    value: TasmeeMode.verseByVerse,
                    title: Text(l.tasmeeVerseByVerse),
                    subtitle: Text(l.tasmeeVerseByVerseHint),
                  ),
                ],
              ),
            ),
          ),
          title(l.tasmeeOnError),
          Card(
            child: RadioGroup<ErrorBehavior>(
              groupValue: s.onError,
              onChanged: (v) => v == null ? null : c.setOnError(v),
              child: Column(
                children: [
                  RadioListTile(
                    value: ErrorBehavior.continueReading,
                    title: Text(l.tasmeeMarkAndGoOn),
                  ),
                  RadioListTile(
                    value: ErrorBehavior.stopToCorrect,
                    title: Text(l.tasmeeStopToCorrect),
                    subtitle: Text(l.tasmeeStopToCorrectHint),
                  ),
                ],
              ),
            ),
          ),
          title(l.tasmeeFeedback),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(l.tasmeeToastDuration),
                  subtitle: Slider(
                    value: s.toastSeconds.toDouble(),
                    min: TasmeeSettings.minToast.toDouble(),
                    max: TasmeeSettings.maxToast.toDouble(),
                    divisions:
                        TasmeeSettings.maxToast - TasmeeSettings.minToast,
                    label: l.tasmeeSeconds(context.digits(s.toastSeconds)),
                    semanticFormatterCallback: (v) =>
                        l.tasmeeSeconds(context.digits(v.round())),
                    onChanged: (v) => c.setToastSeconds(v.round()),
                  ),
                  trailing: Text(
                    l.tasmeeSeconds(context.digits(s.toastSeconds)),
                  ),
                ),
                SwitchListTile(
                  title: Text(l.tasmeeVibration),
                  subtitle: Text(l.tasmeeVibrationHint),
                  value: s.vibration,
                  onChanged: c.setVibration,
                ),
              ],
            ),
          ),
          title(l.tasmeeStrictness),
          Card(
            child: RadioGroup<MatchStrictness>(
              groupValue: s.strictness,
              onChanged: (v) => v == null ? null : c.setStrictness(v),
              child: Column(
                children: [
                  RadioListTile(
                    value: MatchStrictness.strict,
                    title: Text(l.tasmeeStrict),
                    subtitle: Text(l.tasmeeStrictHint),
                  ),
                  RadioListTile(
                    value: MatchStrictness.medium,
                    title: Text(l.tasmeeMedium),
                    subtitle: Text(l.tasmeeMediumHint),
                  ),
                  RadioListTile(
                    value: MatchStrictness.lenient,
                    title: Text(l.tasmeeLenient),
                    subtitle: Text(l.tasmeeLenientHint),
                  ),
                ],
              ),
            ),
          ),
          title(l.tasmeeModelTitle),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.memory, color: t.goldText),
                  title: Text(switch (model) {
                    AsyncData(value: (final m?, _)) => l.tasmeeModelInstalled(
                      m.manifest.version,
                    ),
                    AsyncData() => l.tasmeeModelMissing,
                    _ => '…',
                  }),
                  subtitle: Text(switch (model) {
                    AsyncData(value: (_, final bytes)) => l.tasmeeModelSpace(
                      context.digits((bytes / (1024 * 1024)).round()),
                    ),
                    _ => '',
                  }, style: TextStyle(color: t.muted)),
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: Text(
                    model.value?.$1 == null
                        ? l.tasmeeDownloadModel
                        : l.tasmeeRedownload,
                  ),
                  onTap: () => _download(context, ref),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text(l.tasmeeDeleteModel),
                  enabled: (model.value?.$2 ?? 0) > 0,
                  onTap: () => _delete(context, ref),
                ),
              ],
            ),
          ),
          title(l.tasmeeHistory),
          Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text(l.tasmeeClearHistory),
              subtitle: Text(
                l.tasmeeClearHistoryHint,
                style: TextStyle(color: t.muted),
              ),
              enabled: s.last != null,
              onTap: () => _clearHistory(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String title, String body) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.tasmeeConfirm),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final backend = ref.read(tasmeeBackendProvider);
    final installed = ref.read(tasmeeModelInfoProvider).value?.$1;
    if (installed != null) {
      final l = AppLocalizations.of(context);
      if (!await _confirm(
        context,
        l.tasmeeRedownload,
        l.tasmeeRedownloadBody,
      )) {
        return;
      }
      await backend.deleteModel();
      ref.invalidate(tasmeeModelInfoProvider);
      if (!context.mounted) return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => ModelSheet(
        backend: backend,
        onInstalled: (_) => Navigator.pop(sheet),
      ),
    );
    ref.invalidate(tasmeeModelInfoProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    if (!await _confirm(
      context,
      l.tasmeeDeleteModel,
      l.tasmeeDeleteModelBody,
    )) {
      return;
    }
    await ref.read(tasmeeBackendProvider).deleteModel();
    ref.invalidate(tasmeeModelInfoProvider);
  }

  Future<void> _clearHistory(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    if (!await _confirm(
      context,
      l.tasmeeClearHistory,
      l.tasmeeClearHistoryBody,
    )) {
      return;
    }
    unawaited(ref.read(tasmeeSettingsProvider.notifier).clearHistory());
  }
}
