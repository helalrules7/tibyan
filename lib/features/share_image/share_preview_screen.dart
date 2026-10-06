import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/data/tajweed.dart';
import '../mushaf/mushaf_providers.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import 'photo_saver.dart';
import 'share_document.dart';
import 'share_source.dart';

/// Opens the preview of [range] (numbered as in the edition being read)
/// shared as pictures.
Future<void> showSharePreview(BuildContext context, ShareRange range) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SharePreviewScreen(range: range),
        fullscreenDialog: true,
      ),
    );

/// The pictures of a passage, one after the other, with the tajweed and
/// divine-name switches, «Share» and «Save to Photos».
class SharePreviewScreen extends ConsumerStatefulWidget {
  const SharePreviewScreen({super.key, required this.range});

  final ShareRange range;

  @override
  ConsumerState<SharePreviewScreen> createState() => _SharePreviewState();
}

class _SharePreviewState extends ConsumerState<SharePreviewScreen> {
  late ShareOptions _options;
  ShareDocument? _doc;
  ui.Image? _logo;
  int _page = 0;
  bool _busy = false;

  /// The riwaya's text or font is not on the device: nothing is drawn.
  bool _unavailable = false;
  int _build = 0;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _options = ShareOptions(
      divineNames: s.highlightDivineNames,
      tajweedHues: s.tajweedHues,
    );
    unawaited(_rebuild());
  }

  @override
  void dispose() {
    _doc?.dispose();
    _logo?.dispose();
    super.dispose();
  }

  Future<ui.Image> _loadLogo() async {
    final data = await rootBundle.load('assets/ornaments/share_logo.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }

  Future<void> _rebuild() async {
    final build = ++_build;
    _logo ??= await _loadLogo();
    final edition = ref.read(editionProvider);
    final surahs = await ref.read(surahsProvider.future);
    SharePassage? passage;
    if (edition.isRiwaya) {
      // The riwaya's own text and font, from its pack; never Hafs's.
      final data = await ref.read(riwayaDataProvider.future);
      final r = edition.riwaya;
      if (data != null && riwayaFontLoaded(r)) {
        passage = riwayaPassage(
          data: data,
          fontFamily: riwayaFontFamily(r),
          range: widget.range,
          surahs: surahs,
          options: _options,
        );
      }
    } else {
      passage = await hafsPassage(
        repo: ref.read(mushafRepositoryProvider),
        range: widget.range,
        surahs: surahs,
        options: _options,
      );
    }
    if (!mounted || build != _build) return;
    if (passage == null || passage.verses.isEmpty) {
      setState(() => _unavailable = true);
      return;
    }
    final doc = ShareDocument.build(passage, logo: _logo);
    final old = _doc;
    // The old pictures' text is freed once nothing draws it any more.
    if (old != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    setState(() {
      _doc = doc;
      if (_page >= doc.pageCount) _page = doc.pageCount - 1;
    });
  }

  void _set(ShareOptions o) {
    setState(() => _options = o);
    unawaited(_rebuild());
  }

  /// The pictures as PNG files in the temporary folder.
  Future<List<File>> _files(ShareDocument doc) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final first = widget.range.first;
    return [
      for (var i = 0; i < doc.pageCount; i++)
        await File(
          '${dir.path}${Platform.pathSeparator}tibyan_'
          '${first.surah}_${first.ayah}_${stamp}_${i + 1}.png',
        ).writeAsBytes(await doc.png(i), flush: true),
    ];
  }

  Future<void> _share() async {
    final doc = _doc;
    if (doc == null || _busy) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject();
    final origin = box is RenderBox
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    setState(() => _busy = true);
    try {
      final files = await _files(doc);
      await SharePlus.instance.share(
        ShareParams(
          files: [for (final f in files) XFile(f.path, mimeType: 'image/png')],
          sharePositionOrigin: origin,
        ),
      );
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l.shareImageFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final doc = _doc;
    if (doc == null || _busy) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final (:saved, :folder) = await PhotoSaver.save(await _files(doc));
      if (!saved) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            folder == null ? l.savedToPhotos : l.savedToFolder(folder),
          ),
        ),
      );
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l.saveToPhotosFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final digits = NumberFormatter(Localizations.localeOf(context));
    final edition = ref.watch(editionProvider);
    final doc = _doc;
    return Scaffold(
      appBar: AppBar(title: Text(l.shareImageTitle)),
      body: SafeArea(
        child: _unavailable
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l.shareImageRiwayaUnavailable,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: doc == null
                        ? const Center(child: CircularProgressIndicator())
                        : PageView.builder(
                            itemCount: doc.pageCount,
                            onPageChanged: (i) => setState(() => _page = i),
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: AspectRatio(
                                  aspectRatio: 3 / 4,
                                  child: DecoratedBox(
                                    decoration: const BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x33000000),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: FittedBox(
                                      child: SizedBox.fromSize(
                                        size: ShareDocument.size,
                                        child: CustomPaint(
                                          painter: _PagePainter(doc, i),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                  if (_busy) const LinearProgressIndicator(),
                  if (doc != null && doc.pageCount > 1)
                    Text(
                      l.shareImageOf(digits(_page + 1), digits(doc.pageCount)),
                    ),
                  if (editionHasTajweed(edition))
                    SwitchListTile(
                      title: Text(l.tajweedColors),
                      value: _options.tajweed,
                      onChanged: (v) => _set(_options.copyWith(tajweed: v)),
                    ),
                  SwitchListTile(
                    title: Text(l.highlightDivineNames),
                    value: _options.divineNames,
                    onChanged: (v) => _set(_options.copyWith(divineNames: v)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: doc == null || _busy ? null : _share,
                            icon: const Icon(Icons.ios_share),
                            label: Text(l.shareButton),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: doc == null || _busy ? null : _save,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(l.saveToPhotos),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PagePainter extends CustomPainter {
  _PagePainter(this.doc, this.page);

  final ShareDocument doc;
  final int page;

  @override
  void paint(Canvas canvas, Size size) => doc.paint(canvas, page);

  @override
  bool shouldRepaint(_PagePainter old) => old.doc != doc || old.page != page;
}
