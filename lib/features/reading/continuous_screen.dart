import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/content_database.dart';
import '../../core/router/cover_observer.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../khatma/domain/khatmah.dart' show EntryPoint;
import '../khatma/domain/reading_tracker.dart';
import '../khatma/khatma_providers.dart';
import '../mushaf/data/mushaf_repository.dart';
import '../mushaf/mushaf_providers.dart';
import '../mushaf/presentation/mushaf_screen.dart' show surahName;
import '../mushaf/presentation/navigation.dart';
import 'under_verse.dart';

/// The continuous view: a surah verse after verse in the KFGQPC text, with
/// the reader's choice under each verse (a translation or two, al-Muyassar,
/// or nothing). It opens at [ayah]. The text is the Hafs text whatever
/// edition is being read (docs/features/translation_under_ayah.md).
class ContinuousScreen extends ConsumerWidget {
  const ContinuousScreen({
    super.key,
    required this.surah,
    this.ayah = 1,
    this.entry = EntryPoint.other,
  });

  final int surah;
  final int ayah;

  /// Where the reading was opened from (see [MushafScreen.entry]).
  final EntryPoint entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final surahs = ref.watch(surahsProvider).value;
    final row = surahs == null || surah < 1 || surah > surahs.length
        ? null
        : surahs[surah - 1];
    final ayahs = ref.watch(surahAyahsProvider(surah)).value;
    final riwaya = ref.watch(editionProvider).isRiwaya;

    return Scaffold(
      backgroundColor: t.paper,
      appBar: AppBar(
        title: Text(row == null ? '' : l.surahWord(surahName(context, row))),
        actions: [
          IconButton(
            tooltip: l.underVerseTitle,
            icon: const Icon(Icons.translate),
            onPressed: () => showUnderVerseChooser(context),
          ),
          IconButton(
            tooltip: l.sectionMushaf,
            icon: const Icon(Icons.auto_stories_outlined),
            onPressed: () => openVerse(context, ref, surah: surah, ayah: ayah),
          ),
        ],
      ),
      body: ayahs == null
          ? Center(
              child: CircularProgressIndicator(semanticsLabel: l.loadingLabel),
            )
          : _VerseList(
              key: ValueKey('$surah:$ayah'),
              surah: surah,
              ayah: ayah,
              ayahs: ayahs,
              riwaya: riwaya,
              surahCount: surahs?.length ?? 114,
              entry: entry,
            ),
    );
  }
}

class _VerseList extends ConsumerStatefulWidget {
  const _VerseList({
    super.key,
    required this.surah,
    required this.ayah,
    required this.ayahs,
    required this.riwaya,
    required this.surahCount,
    required this.entry,
  });

  final int surah;
  final int ayah;
  final List<AyahRow> ayahs;
  final bool riwaya;
  final int surahCount;
  final EntryPoint entry;

  @override
  ConsumerState<_VerseList> createState() => _VerseListState();
}

class _VerseListState extends ConsumerState<_VerseList> {
  static const _center = ValueKey('center');

  /// The tile of each verse built, by `ayah.id`.
  final _tiles = <int, GlobalKey>{};

  /// Counts the verses that pass through the reading zone (the middle of
  /// the screen) for the khatma, and saves the place read.
  late final ReadingTracker _tracker;
  late final AppLifecycleListener _lifecycle;
  Route<dynamic>? _route;
  int? _saved;

  int get surah => widget.surah;
  int get ayah => widget.ayah;
  List<AyahRow> get ayahs => widget.ayahs;
  bool get riwaya => widget.riwaya;
  int get surahCount => widget.surahCount;

  @override
  void initState() {
    super.initState();
    // The tracker's callbacks also run from dispose, when ref is no longer
    // usable: they read through the container.
    final c = ProviderScope.containerOf(context, listen: false);
    final service = ref.read(khatmaServiceProvider);
    _tracker = ReadingTracker(
      mode: 'continuous',
      onPageRead: (_) {},
      onVersesRead: (r) => unawaited(
        service
            .versesRead(
              r,
              entry: widget.entry,
              mode: 'continuous',
              edition: c.read(editionProvider).name,
            )
            .catchError((_) {}),
      ),
      onSessionEnd: (s) => unawaited(
        service.sessionEnded(s, entry: widget.entry).catchError((_) {}),
      ),
      verseWeight: (id) =>
          c.read(quranIndexProvider).value?.weight(id) ?? 1 / 15,
      minDwell: Duration(
        seconds: ref.read(settingsProvider).readingSpeed.secondsPerPage,
      ),
    );
    ref.read(quranIndexProvider.future).ignore();
    final landed = ayahs.where((a) => a.number == ayah).firstOrNull;
    if (widget.entry.countsOnlyAfterLanding && landed != null) {
      _tracker.onlyAfterVerse = landed.id;
    }
    _lifecycle = AppLifecycleListener(onHide: _tracker.end, onShow: _look);
    WidgetsBinding.instance.addPostFrameCallback((_) => _look());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _route) {
      if (_route != null) coverObserver.unsubscribe(_route!);
      _route = route;
      coverObserver.subscribe(route, _tracker.freeze);
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    if (_route != null) coverObserver.unsubscribe(_route!);
    _tracker.end();
    super.dispose();
  }

  /// The verses whose tiles are in the reading zone: the middle half of
  /// the screen.
  void _look() {
    if (!mounted) return;
    final height = MediaQuery.sizeOf(context).height;
    final top = height * 0.25, bottom = height * 0.75;
    final inZone = <int>[];
    for (final MapEntry(key: id, value: key) in _tiles.entries) {
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final y = box.localToGlobal(Offset.zero).dy;
      if (y + box.size.height > top && y < bottom) inZone.add(id);
    }
    inZone.sort();
    _tracker.showVerses(inZone, edition: ref.read(editionProvider).name);
    if (inZone.isNotEmpty && inZone.first != _saved) {
      _saved = inZone.first;
      unawaited(_save(inZone.first));
    }
  }

  /// The first verse in the zone is the last place read.
  Future<void> _save(int id) async {
    final row = ayahs.where((a) => a.id == id).firstOrNull;
    if (row == null) return;
    try {
      final page = await ref.read(
        versePageProvider((row.surah, row.number)).future,
      );
      await ref
          .read(userDatabaseProvider)
          .savePosition(
            edition: ref.read(editionProvider).name,
            view: 'continuous',
            surah: row.surah,
            ayah: row.number,
            page: page,
          );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final basmala = ref.watch(basmalaProvider).value;
    _tracker.minDwell = Duration(
      seconds: ref.watch(settingsProvider).readingSpeed.secondsPerPage,
    );

    // The list from its top: the header, the verses, the way on.
    final items = <Widget>[
      _Header(
        basmala: surah != 1 && surah != 9 ? basmala : null,
        note: riwaya ? l.hafsTextNote : null,
      ),
      for (final a in ayahs)
        _VerseTile(key: _tiles.putIfAbsent(a.id, GlobalKey.new), verse: a),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Row(
          children: [
            if (surah > 1)
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      context.pushReplacement('/read?s=${surah - 1}'),
                  child: Text(l.previousSurah),
                ),
              ),
            if (surah > 1 && surah < surahCount) const SizedBox(width: 12),
            if (surah < surahCount)
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      context.pushReplacement('/read?s=${surah + 1}'),
                  child: Text(l.nextSurah),
                ),
              ),
          ],
        ),
      ),
    ];
    // Opens at the verse: what is above it grows upward from the centre.
    final at = ayahs.indexWhere((a) => a.number == ayah);
    final center = at <= 0 ? 0 : at + 1;
    final above = items.sublist(0, center).reversed.toList();
    final below = items.sublist(center);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _tracker.touch(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollUpdateNotification || n is ScrollEndNotification) {
            _look();
          }
          return false;
        },
        child: SelectionArea(
          child: CustomScrollView(
            center: _center,
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => above[i],
                  childCount: above.length,
                ),
              ),
              SliverList(
                key: _center,
                delegate: SliverChildBuilderDelegate(
                  (context, i) => below[i],
                  childCount: below.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.basmala, this.note});

  final String? basmala;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        children: [
          if (note != null)
            Text(note!, style: TextStyle(color: t.muted, fontSize: 12)),
          if (basmala != null)
            Text(
              basmala!,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'UthmanicHafs',
                fontSize: 24,
                height: 2,
                color: t.ink,
              ),
            ),
        ],
      ),
    );
  }
}

class _VerseTile extends StatelessWidget {
  const _VerseTile({super.key, required this.verse});

  final AyahRow verse;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return InkWell(
      // A tap opens the verse's tafsir and translations.
      onTap: () =>
          context.push('/mushaf/tafsir?s=${verse.surah}&a=${verse.number}'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.border, width: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${verse.displayBody} '),
                  TextSpan(
                    text: verse.displayNumber,
                    style: TextStyle(color: t.marker),
                  ),
                ],
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontFamily: 'UthmanicHafs',
                fontSize: 24,
                height: 2,
                color: t.ink,
              ),
            ),
            UnderVerseTexts(surah: verse.surah, ayah: verse.number),
          ],
        ),
      ),
    );
  }
}
