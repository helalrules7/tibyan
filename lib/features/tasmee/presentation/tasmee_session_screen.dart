import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../mushaf/mushaf_providers.dart';
import '../../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import '../data/model_downloader.dart';
import '../data/model_manifest.dart';
import '../data/model_store.dart';
import '../data/sherpa_offline_recognizer.dart';
import '../data/tasmee_audio_capture.dart';
import '../domain/alignment_engine.dart';
import '../domain/expected_words.dart';
import '../domain/recitation_recognizer.dart';
import '../domain/tasmee_session_request.dart';

class TasmeeSessionScreen extends ConsumerStatefulWidget {
  const TasmeeSessionScreen({required this.request, super.key});

  final TasmeeSessionRequest request;

  @override
  ConsumerState<TasmeeSessionScreen> createState() =>
      _TasmeeSessionScreenState();
}

class _TasmeeSessionScreenState extends ConsumerState<TasmeeSessionScreen> {
  ModelStore? _store;
  InstalledModel? _model;
  ModelDownloadProgress? _downloadProgress;
  ModelDownloadCancel? _cancelDownload;
  ModelDownloader? _downloader;
  RecitationRecognizer? _recognizer;
  TasmeeAudioCapture? _capture;
  StreamSubscription<List<String>>? _wordsSubscription;
  late final TasmeeEngine _engine = TasmeeEngine(widget.request.words);

  bool _loading = true;
  bool _downloading = false;
  bool _starting = false;
  bool _listening = false;
  bool _finished = false;
  double _level = 0;
  String? _error;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    unawaited(_loadInstalledModel());
  }

  @override
  void dispose() {
    _clock?.cancel();
    _cancelDownload?.cancel();
    unawaited(_wordsSubscription?.cancel());
    unawaited(_capture?.dispose());
    unawaited(_recognizer?.dispose());
    _downloader?.close();
    super.dispose();
  }

  Future<void> _loadInstalledModel() async {
    try {
      final store = await ModelStore.inAppSupport();
      final model = await store.installed(recitationModelId);
      if (!mounted) return;
      setState(() {
        _store = store;
        _model = model;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _downloadModel() async {
    if (_downloading || _store == null) return;
    final downloader = ModelDownloader(store: _store!);
    _downloader = downloader;
    try {
      final manifest = await downloader.fetchManifest();
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      final size = (manifest.totalBytes / (1024 * 1024)).toStringAsFixed(0);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.tasmeeDownloadModel),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.tasmeeModelConsent('$size MB')),
                const SizedBox(height: 12),
                Text(
                  l.tasmeeModelAttribution,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.tasmeeDownload),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      final cancel = ModelDownloadCancel();
      setState(() {
        _cancelDownload = cancel;
        _downloading = true;
        _downloadProgress = ModelDownloadProgress(
          receivedBytes: 0,
          totalBytes: manifest.totalBytes,
          file: '',
        );
        _error = null;
      });
      final installed = await downloader.download(
        manifest,
        allowCellular: true,
        cancel: cancel,
        onProgress: (progress) {
          if (mounted) setState(() => _downloadProgress = progress);
        },
      );
      // The model an earlier build used is no longer needed.
      for (final id in retiredRecitationModelIds) {
        if (id != installed.manifest.id) await _store!.delete(id);
      }
      if (mounted) {
        setState(() {
          _model = installed;
          _downloadProgress = null;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
          _cancelDownload = null;
        });
      }
      downloader.close();
      _downloader = null;
    }
  }

  Future<void> _startListening() async {
    if (_starting || _listening || _finished) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final model = _model;
      if (model == null) throw StateError('The model is not installed');
      final recognizer = SherpaOfflineRecognizer.forModel(model);
      _recognizer = recognizer;
      _wordsSubscription = settledWords(recognizer.events).listen(
        _acceptWords,
        onError: (Object e, StackTrace s) {
          if (mounted) setState(() => _error = '$e');
        },
      );
      await recognizer.start();

      final capture = TasmeeAudioCapture();
      _capture = capture;
      await capture.start(
        onPcm: recognizer.acceptAudio,
        onLevel: (level) {
          if (mounted) setState(() => _level = level);
        },
        onSpeechEnded: recognizer.endOfSpeech,
        onError: (error, stack) {
          if (mounted) setState(() => _error = '$error');
        },
      );
      if (!mounted) {
        await capture.dispose();
        await recognizer.dispose();
        return;
      }
      _startedAt = DateTime.now();
      _clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _startedAt == null) return;
        setState(() => _elapsed = DateTime.now().difference(_startedAt!));
      });
      setState(() => _listening = true);
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        setState(() {
          _error = e is MicrophonePermissionDenied
              ? l.tasmeeMicDenied
              : l.tasmeeSessionFailed('$e');
          _listening = false;
        });
      }
      await _capture?.dispose();
      await _recognizer?.dispose();
      _capture = null;
      _recognizer = null;
      await _wordsSubscription?.cancel();
      _wordsSubscription = null;
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _acceptWords(List<String> words) {
    if (!mounted || words.isEmpty) return;
    setState(() => _engine.addWords(words));
    if (_engine.isComplete) unawaited(_finish());
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _clock?.cancel();
    final capture = _capture;
    if (capture != null) await capture.stop();
    _engine.finish();
    if (!mounted) return;
    setState(() {
      _listening = false;
      _finished = true;
      _level = 0;
    });
  }

  String _elapsedLabel() {
    final minutes = _elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _statusLabel(AppLocalizations l, WordStatus status) =>
      switch (status) {
        WordStatus.hidden => '',
        WordStatus.correct => l.tasmeeWordCorrect,
        WordStatus.wrong => l.tasmeeWordWrong,
        WordStatus.skipped => l.tasmeeWordSkipped,
        WordStatus.correctedAfterError => l.tasmeeWordCorrected,
        WordStatus.doubtful => l.tasmeeWordDoubtful,
      };

  Color _statusColor(BuildContext context, WordStatus status) {
    final colors = context.tokens.colors;
    return switch (status) {
      WordStatus.hidden || WordStatus.correct => colors.ink,
      WordStatus.wrong => const Color(0xFFC62828),
      WordStatus.skipped => const Color(0xFFB26A00),
      WordStatus.correctedAfterError => colors.goldText,
      // Calm: not an error, not confirmed either.
      WordStatus.doubtful => colors.muted,
    };
  }

  int _count(WordStatus status) =>
      _engine.words.where((w) => _engine.statusOf(w.index) == status).length;

  int get _doubtfulCount => _count(WordStatus.doubtful);

  /// Correct words over the words judged: doubtful words count apart.
  double get _accuracy {
    final judged = _engine.words.length - _doubtfulCount;
    return judged <= 0 ? 0 : _count(WordStatus.correct) / judged;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final grouped = <int, List<ExpectedWord>>{};
    for (final word in widget.request.words) {
      (grouped[word.verseId] ??= []).add(word);
    }
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final surahs = ref.watch(surahsProvider).value;
    final surahNumber = widget.request.words.first.surah;
    final rangeTitle = surahs == null
        ? digits(surahNumber)
        : isArabic
        ? surahs[surahNumber - 1].nameAr
        : surahs[surahNumber - 1].nameEn;
    final modelReady = _model != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tasmeeTitle),
        actions: [
          if (_elapsed > Duration.zero)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Center(child: Text(_elapsedLabel())),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.menu_book, color: t.goldText),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rangeTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    Text(
                                      l.tasmeeWordsCount(
                                        digits(widget.request.words.length),
                                      ),
                                      style: TextStyle(color: t.muted),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                widget.request.mode == TasmeeMode.continuous
                                    ? l.tasmeeContinuous
                                    : l.tasmeeVerseByVerse,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_finished)
                        Card(
                          color: t.paper,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  l.tasmeeSessionComplete,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l.tasmeeSessionAccuracy(
                                    (_accuracy * 100).toStringAsFixed(0),
                                  ),
                                ),
                                if (_doubtfulCount > 0)
                                  Text(
                                    l.tasmeeSessionDoubtful(
                                      digits(_doubtfulCount),
                                    ),
                                    style: TextStyle(color: t.muted),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      for (final words in grouped.values)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Wrap(
                              textDirection: TextDirection.rtl,
                              alignment: WrapAlignment.start,
                              runSpacing: 6,
                              spacing: 4,
                              children: [
                                for (final word in words)
                                  _WordTile(
                                    word: word,
                                    status: _engine.statusOf(word.index),
                                    color: _statusColor(
                                      context,
                                      _engine.statusOf(word.index),
                                    ),
                                    statusLabel: _statusLabel(
                                      l,
                                      _engine.statusOf(word.index),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Material(
                  color: t.paper,
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Color(0xFFC62828)),
                            ),
                          ),
                        if (_listening) ...[
                          Semantics(
                            liveRegion: true,
                            child: Text(l.tasmeeListening),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (_level / 0.12).clamp(0, 1),
                            minHeight: 6,
                          ),
                          const SizedBox(height: 10),
                        ] else if (!_finished && modelReady) ...[
                          Text(l.tasmeeNotListening),
                          const SizedBox(height: 8),
                        ],
                        if (_loading || _starting)
                          const LinearProgressIndicator()
                        else if (!modelReady)
                          FilledButton.icon(
                            onPressed: _downloading ? null : _downloadModel,
                            icon: _downloading
                                ? const Icon(Icons.downloading)
                                : const Icon(Icons.download),
                            label: Text(
                              _downloading
                                  ? l.tasmeeModelDownloading
                                  : l.tasmeeDownloadModel,
                            ),
                          )
                        else if (!_finished)
                          FilledButton.icon(
                            onPressed: _listening ? _finish : _startListening,
                            icon: Icon(_listening ? Icons.stop : Icons.mic),
                            label: Text(
                              _listening
                                  ? l.tasmeeStopListening
                                  : l.tasmeeStartListening,
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.done),
                            label: Text(l.tasmeeSessionComplete),
                          ),
                        if (!_loading && !modelReady) ...[
                          const SizedBox(height: 8),
                          Text(
                            l.tasmeeModelAttribution,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: t.muted),
                          ),
                        ],
                        if (_downloading && _downloadProgress != null) ...[
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _downloadProgress!.fraction,
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              onPressed: () => _cancelDownload?.cancel(),
                              child: Text(
                                MaterialLocalizations.of(context)
                                    .cancelButtonLabel,
                              ),
                            ),
                          ),
                        ],
                        if (_finished)
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              onPressed: () => context.pop(),
                              child: Text(
                                MaterialLocalizations.of(context)
                                    .backButtonTooltip,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({
    required this.word,
    required this.status,
    required this.color,
    required this.statusLabel,
  });

  final ExpectedWord word;
  final WordStatus status;
  final Color color;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    if (status == WordStatus.hidden) {
      return Semantics(
        hidden: true,
        child: Container(
          width: (word.display.runes.length * 11.0).clamp(30, 100),
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          decoration: BoxDecoration(
            color: context.tokens.colors.muted.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
    }
    return Semantics(
      label: statusLabel,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: status == WordStatus.wrong || status == WordStatus.skipped
            ? BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: color),
              )
            : null,
        child: Text(
          word.display,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            color: color,
            decoration: status == WordStatus.doubtful
                ? TextDecoration.underline
                : null,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: color,
            fontSize: 24,
            height: 1.7,
            fontFamily: 'KFGQPC Hafs Uthmanic Script',
          ),
        ),
      ),
    );
  }
}
