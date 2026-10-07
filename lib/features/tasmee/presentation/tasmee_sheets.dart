import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/model_downloader.dart';
import '../data/model_manifest.dart';
import '../data/model_store.dart';
import '../data/tasmee_backend.dart';
import '../domain/expected_words.dart';
import '../domain/tasmee_report.dart';
import 'tasmee_style.dart';

/// «It checks your memorisation, not your tajweed»: shown before the first
/// session, and from the session's help button.
class FirstUseSheet extends StatelessWidget {
  const FirstUseSheet({super.key, required this.onDone, this.firstTime = true});

  final VoidCallback onDone;
  final bool firstTime;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final c = context.tasmeeColors;
    Widget point(IconData icon, Color color, String title, String body) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 19, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: t.ink,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        body,
                        style: TextStyle(
                          color: t.muted,
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
    return TasmeeSheetFrame(
      children: [
        Icon(Icons.graphic_eq, size: 34, color: t.goldText),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(
            l.tasmeeNoticeTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: t.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        point(
          Icons.spellcheck,
          c.corrected,
          l.tasmeeNoticeWordsTitle,
          l.tasmeeNoticeWordsBody,
        ),
        point(
          Icons.block,
          c.wrong,
          l.tasmeeNoticeTajweedTitle,
          l.tasmeeNoticeTajweedBody,
        ),
        point(
          Icons.lock_outline,
          t.goldText,
          l.tasmeeNoticeDeviceTitle,
          l.tasmeeNoticeDeviceBody,
        ),
        point(
          Icons.more_horiz,
          c.doubtful,
          l.tasmeeNoticeMishearTitle,
          l.tasmeeNoticeMishearBody,
        ),
        const SizedBox(height: 4),
        FilledButton(
          key: const ValueKey('tasmee-notice-ok'),
          onPressed: onDone,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: Text(firstTime ? l.tasmeeNoticeStart : l.tasmeeNoticeOk),
        ),
      ],
    );
  }
}

/// The model download: its size and what it means, then its progress.
/// The model's credit and licence are in About this mushaf › Sources.
class ModelSheet extends StatefulWidget {
  const ModelSheet({
    super.key,
    required this.backend,
    required this.onInstalled,
    this.onAbout,
  });

  final TasmeeBackend backend;
  final ValueChanged<InstalledModel> onInstalled;

  /// Opens About this mushaf (the model's credit and licence).
  final VoidCallback? onAbout;

  @override
  State<ModelSheet> createState() => _ModelSheetState();
}

class _ModelSheetState extends State<ModelSheet> {
  ModelManifest? _manifest;
  ModelDownloadProgress? _progress;
  ModelDownloadCancel? _cancel;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_fetch());
  }

  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _error = null);
    try {
      final m = await widget.backend.fetchManifest();
      if (mounted) setState(() => _manifest = m);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _download() async {
    final manifest = _manifest;
    if (manifest == null || _cancel != null) return;
    final cancel = ModelDownloadCancel();
    setState(() {
      _cancel = cancel;
      _error = null;
      _progress = ModelDownloadProgress(
        receivedBytes: 0,
        totalBytes: manifest.totalBytes,
        file: '',
      );
    });
    try {
      final installed = await widget.backend.download(
        manifest,
        cancel: cancel,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      widget.onInstalled(installed);
    } on ModelDownloadCancelled {
      if (mounted) setState(() => _progress = null);
    } catch (e) {
      if (mounted) {
        setState(() {
          _progress = null;
          _error = '$e';
        });
      }
    } finally {
      if (mounted) setState(() => _cancel = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final manifest = _manifest;
    final mb = manifest == null
        ? null
        : (manifest.totalBytes / (1024 * 1024)).round();
    final progress = _progress;
    Widget fact(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: t.goldText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: t.ink, fontSize: 13.5)),
          ),
        ],
      ),
    );
    return TasmeeSheetFrame(
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: t.highlight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.download_for_offline_outlined,
                color: t.goldText,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l.tasmeeModelTitle,
                      style: TextStyle(
                        color: t.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    mb == null
                        ? l.tasmeeModelSizeUnknown
                        : l.tasmeeModelSize(context.digits(mb)),
                    style: TextStyle(color: t.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        fact(Icons.wifi_off, l.tasmeeModelOffline),
        fact(Icons.mic_none, l.tasmeeModelVoiceStays),
        fact(Icons.delete_outline, l.tasmeeModelRemove),
        fact(Icons.wifi, l.tasmeeModelWifiNote),
        if (progress != null) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.fraction,
              minHeight: 8,
              color: t.control,
              backgroundColor: t.border,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.tasmeeModelProgress(
              context.digits((progress.receivedBytes / (1024 * 1024)).round()),
              context.digits((progress.totalBytes / (1024 * 1024)).round()),
            ),
            style: TextStyle(color: t.ink, fontSize: 13),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            l.tasmeeModelFailed,
            style: TextStyle(color: context.tasmeeColors.wrong, fontSize: 13),
          ),
        ],
        if (widget.onAbout != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: widget.onAbout,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(l.tasmeeModelDetails),
            ),
          ),
        const SizedBox(height: 10),
        if (progress == null)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.maybePop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text(l.tasmeeNotNow),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  key: const ValueKey('tasmee-model-download'),
                  onPressed: manifest == null
                      ? (_error == null ? null : _fetch)
                      : _download,
                  icon: Icon(manifest == null ? Icons.refresh : Icons.download),
                  label: Text(
                    manifest == null
                        ? (_error == null
                              ? l.tasmeeModelChecking
                              : l.tasmeeRetry)
                        : l.tasmeeDownloadSize(context.digits(mb!)),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            ],
          )
        else
          OutlinedButton(
            onPressed: () => _cancel?.cancel(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: Text(l.tasmeeCancelDownload),
          ),
      ],
    );
  }
}

/// The end of a session: accuracy, counts, the verses to look at again.
class SummarySheet extends StatelessWidget {
  const SummarySheet({
    super.key,
    required this.title,
    required this.duration,
    required this.report,
    required this.words,
    required this.onVerse,
    required this.onDone,
    required this.onAgain,
  });

  final String title;
  final Duration duration;
  final TasmeeReport report;

  /// The session's words (the excerpts are their text, as stored).
  final List<ExpectedWord> words;
  final ValueChanged<VerseReport> onVerse;
  final VoidCallback onDone;

  /// Null when there is nothing to recite again.
  final VoidCallback? onAgain;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final c = context.tasmeeColors;
    final acc = report.accuracy;
    final pct = acc == null ? null : (acc * 100).round();
    Widget chip(Color color, String label, int n) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label ${context.digits(n)}',
            style: TextStyle(
              color: t.ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    String excerpt(int verseId) => words
        .where((w) => w.verseId == verseId)
        .take(4)
        .map((w) => w.display)
        .join(' ');
    final rows = report.toReview;
    final minutes = duration.inMinutes, seconds = duration.inSeconds % 60;
    return TasmeeSheetFrame(
      children: [
        Row(
          children: [
            Semantics(
              label: l.tasmeeAccuracy,
              value: pct == null ? '–' : context.percent(pct),
              excludeSemantics: true,
              child: SizedBox.square(
                dimension: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 84,
                      child: CircularProgressIndicator(
                        value: (pct ?? 0) / 100,
                        strokeWidth: 7,
                        color: t.goldText,
                        backgroundColor: t.border,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pct == null ? '–' : context.percent(pct),
                          style: TextStyle(
                            color: t.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          l.tasmeeAccuracyShort,
                          style: TextStyle(color: t.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l.tasmeeSessionComplete,
                      style: TextStyle(
                        color: t.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(title, style: TextStyle(color: t.ink, fontSize: 14)),
                  Text(
                    l.tasmeeDurationWords(
                      context.digits(minutes),
                      context.digits(seconds),
                      context.digits(words.length),
                    ),
                    style: TextStyle(color: t.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            chip(c.wrong, l.tasmeeWordWrong, report.wrong),
            chip(c.skipped, l.tasmeeWordSkipped, report.skipped),
            chip(c.corrected, l.tasmeeWordCorrectedShort, report.corrected),
            chip(c.hint, l.tasmeeWordHinted, report.hinted),
          ],
        ),
        if (report.doubtful > 0) ...[
          const SizedBox(height: 6),
          Text(
            l.tasmeeSessionDoubtful(context.digits(report.doubtful)),
            style: TextStyle(color: t.muted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 14),
        if (rows.isEmpty)
          Text(
            l.tasmeeNothingToReview,
            style: TextStyle(color: t.ink, fontSize: 14),
          )
        else ...[
          TasmeeSectionLabel(l.tasmeeToReview),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: t.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                for (final (i, r) in rows.indexed) ...[
                  if (i > 0) Divider(height: 1, color: t.border),
                  _ReviewRow(
                    report: r,
                    excerpt: excerpt(r.verseId),
                    onTap: () => onVerse(r),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('tasmee-summary-done'),
                onPressed: onDone,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(l.tasmeeDone),
              ),
            ),
            if (onAgain != null) ...[
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  key: const ValueKey('tasmee-summary-again'),
                  onPressed: onAgain,
                  icon: const Icon(Icons.replay),
                  label: Text(l.tasmeeReciteAgain),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l.tasmeeNoAudioKept,
          textAlign: TextAlign.center,
          style: TextStyle(color: t.muted, fontSize: 11.5),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.report,
    required this.excerpt,
    required this.onTap,
  });

  final VerseReport report;
  final String excerpt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final c = context.tasmeeColors;
    final r = report;
    final acc = r.accuracy;
    final pct = acc == null ? '–' : context.percent((acc * 100).round());
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      button: true,
      label: l.tasmeeReviewRow(context.digits(r.ayah), pct),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: t.marker),
                ),
                child: Text(
                  context.digits(r.ayah),
                  style: TextStyle(
                    color: t.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        excerpt,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: t.ink,
                          fontSize: 17,
                          height: 1.6,
                          fontFamily: 'KFGQPC Hafs Uthmanic Script',
                        ),
                      ),
                    ),
                    Text(' …', style: TextStyle(color: t.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              for (final (n, col) in [
                (r.wrong, c.wrong),
                (r.skipped, c.skipped),
                (r.corrected, c.corrected),
                (r.hinted, c.hint),
              ])
                if (n > 0)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 3),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              const SizedBox(width: 6),
              Text(
                pct,
                style: TextStyle(
                  color: t.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                rtl ? Icons.chevron_left : Icons.chevron_right,
                color: t.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
