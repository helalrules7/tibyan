import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/content_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../mushaf/mushaf_providers.dart';
import '../data/tasmee_settings.dart';
import '../data/tasmee_words_repository.dart';
import '../domain/alignment_engine.dart';
import '../domain/expected_words.dart';
import '../domain/recitation_range.dart';
import '../domain/tasmee_session_request.dart';
import 'tasmee_style.dart';

final _verseIndexProvider = FutureProvider<List<VerseIndexEntry>>(
  (ref) =>
      TasmeeWordsRepository(ref.watch(contentDatabaseProvider)).verseIndex(),
);

/// The words of a range (null for a range that is not valid).
final _rangeWordsProvider = FutureProvider.autoDispose
    .family<List<ExpectedWord>?, RecitationRange>((ref, range) async {
      try {
        range.validate();
      } on RangeError {
        return null;
      }
      return TasmeeWordsRepository(ref.watch(contentDatabaseProvider))
          .expectedWords(range);
    });

/// Opens the setup sheet over [context]; a chosen range opens the session.
Future<void> showTasmeeSetup(BuildContext context) async {
  final request = await showModalBottomSheet<TasmeeSessionRequest>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    builder: (context) => TasmeeSetupSheet(
      onStart: (request) => Navigator.pop(context, request),
      onClose: () => Navigator.pop(context),
    ),
  );
  if (request != null && context.mounted) {
    await context.push('/tasmee/session', extra: request);
  }
}

/// `/tasmee`: the setup sheet on a screen of its own (a link into the
/// feature); the home's entry opens it as a sheet instead.
class TasmeeSetupScreen extends StatelessWidget {
  const TasmeeSetupScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.tokens.colors.bg,
    body: Align(
      alignment: Alignment.bottomCenter,
      child: TasmeeSetupSheet(
        onStart: (request) =>
            context.pushReplacement('/tasmee/session', extra: request),
        onClose: () => context.canPop() ? context.pop() : context.go('/'),
      ),
    ),
  );
}

/// «New tasmee»: the eight kinds of range, the chosen kind's fields, a live
/// summary, the mode and what a mistake does (defaults from the settings),
/// and the last session to continue.
class TasmeeSetupSheet extends ConsumerStatefulWidget {
  const TasmeeSetupSheet({
    super.key,
    required this.onStart,
    required this.onClose,
  });

  final ValueChanged<TasmeeSessionRequest> onStart;
  final VoidCallback onClose;

  @override
  ConsumerState<TasmeeSetupSheet> createState() => _TasmeeSetupSheetState();
}

/// The kinds in the order the sheet shows them.
const _kinds = [
  RecitationRangeKind.surah,
  RecitationRangeKind.juz,
  RecitationRangeKind.hizb,
  RecitationRangeKind.halfHizb,
  RecitationRangeKind.quarter,
  RecitationRangeKind.threeQuartersHizb,
  RecitationRangeKind.pages,
  RecitationRangeKind.verses,
];

class _TasmeeSetupSheetState extends ConsumerState<TasmeeSetupSheet> {
  RecitationRangeKind _kind = RecitationRangeKind.surah;
  late TasmeeMode _mode;
  late ErrorBehavior _onError;
  int _surah = 1;
  int _juz = 1;
  int _hizb = 1;
  int _quarter = 1;
  int _half = 1;
  bool _fromSecondQuarter = false;
  int _pageFrom = 1;
  int _pageTo = 1;
  int _fromSurah = 1;
  int _fromAyah = 1;
  int _toSurah = 1;
  int _toAyah = 7;

  @override
  void initState() {
    super.initState();
    final s = ref.read(tasmeeSettingsProvider);
    _mode = s.mode;
    _onError = s.onError;
  }

  RecitationRange _range() => switch (_kind) {
    RecitationRangeKind.surah => SurahRange(_surah),
    RecitationRangeKind.juz => JuzRange(_juz),
    RecitationRangeKind.hizb => HizbPartRange.hizb(_hizb),
    RecitationRangeKind.quarter => HizbPartRange.quarter(
      (_hizb - 1) * 4 + _quarter,
    ),
    RecitationRangeKind.halfHizb => HizbPartRange.half(_hizb, _half),
    RecitationRangeKind.threeQuartersHizb => HizbPartRange.threeQuarters(
      _hizb,
      fromSecond: _fromSecondQuarter,
    ),
    RecitationRangeKind.pages => PageRange(_pageFrom, _pageTo),
    RecitationRangeKind.verses => VerseRange(
      fromSurah: _fromSurah,
      fromAyah: _fromAyah,
      toSurah: _toSurah,
      toAyah: _toAyah,
    ),
  };

  void _start(RecitationRange range, List<ExpectedWord> words) {
    widget.onStart(
      TasmeeSessionRequest(
        range: range,
        words: List.unmodifiable(words),
        mode: _mode,
        onError: _onError,
      ),
    );
  }

  Future<void> _continueLast(
    LastTasmee last,
    List<VerseIndexEntry> index,
  ) async {
    var from = (last.fromSurah, last.fromAyah);
    if (!last.completed) {
      final at = index.indexWhere(
        (v) => v.surah == last.reachedSurah && v.ayah == last.reachedAyah,
      );
      if (at >= 0 && at + 1 < index.length) {
        from = (index[at + 1].surah, index[at + 1].ayah);
      }
    }
    final range = VerseRange(
      fromSurah: from.$1,
      fromAyah: from.$2,
      toSurah: last.toSurah,
      toAyah: last.toAyah,
    );
    try {
      final words = await TasmeeWordsRepository(
        ref.read(contentDatabaseProvider),
      ).expectedWords(range);
      if (words.isNotEmpty && mounted) _start(range, words);
    } on RangeError {
      return;
    }
  }

  String _kindLabel(AppLocalizations l, RecitationRangeKind kind) =>
      switch (kind) {
        RecitationRangeKind.surah => l.tasmeeKindSurah,
        RecitationRangeKind.juz => l.tasmeeKindJuz,
        RecitationRangeKind.hizb => l.tasmeeKindHizb,
        RecitationRangeKind.halfHizb => l.tasmeeKindHalfHizb,
        RecitationRangeKind.quarter => l.tasmeeKindQuarter,
        RecitationRangeKind.threeQuartersHizb => l.tasmeeKindThreeQuarters,
        RecitationRangeKind.pages => l.tasmeeKindPages,
        RecitationRangeKind.verses => l.tasmeeKindVerses,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final surahs = ref.watch(surahsProvider).value;
    final index = ref.watch(_verseIndexProvider).value;
    final settings = ref.watch(tasmeeSettingsProvider);
    final range = _range();
    final words = ref.watch(_rangeWordsProvider(range));
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String surahName(int s) => surahs == null
        ? context.digits(s)
        : (ar ? surahs[s - 1].nameAr : surahs[s - 1].nameEn);

    final last = settings.last;
    return TasmeeSheetFrame(
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l.tasmeeNew,
                  style: TextStyle(
                    color: t.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: widget.onClose,
              icon: Icon(Icons.close, color: t.muted),
              tooltip: l.tasmeeClose,
            ),
          ],
        ),
        if (last != null && index != null) ...[
          const SizedBox(height: 4),
          _ResumeRow(
            label: l.tasmeeLastSession(
              last.fromSurah == last.toSurah
                  ? '${surahName(last.fromSurah)} '
                        '${context.digits(last.fromAyah)}–'
                        '${context.digits(last.toAyah)}'
                  : '${surahName(last.fromSurah)} '
                        '${context.digits(last.fromAyah)} – '
                        '${surahName(last.toSurah)} '
                        '${context.digits(last.toAyah)}',
              last.accuracy == null ? '–' : context.percent(last.accuracy!),
            ),
            action: last.completed ? l.tasmeeRepeat : l.tasmeeContinueLast,
            onTap: () => _continueLast(last, index),
          ),
        ],
        const SizedBox(height: 16),
        TasmeeSectionLabel(l.tasmeeRange),
        for (var row = 0; row < 2; row++) ...[
          Row(
            children: [
              for (var i = row * 4; i < row * 4 + 4; i++) ...[
                Expanded(
                  child: _Choice(
                    label: _kindLabel(l, _kinds[i]),
                    selected: _kinds[i] == _kind,
                    onTap: () => setState(() => _kind = _kinds[i]),
                  ),
                ),
                if (i % 4 != 3) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: 6),
        ..._fields(l, surahs).map(
          (row) =>
              Padding(padding: const EdgeInsets.only(bottom: 8), child: row),
        ),
        _Summary(
          words: words,
          surahName: surahName,
          invalid: l.tasmeeInvalidRange,
        ),
        const SizedBox(height: 16),
        TasmeeSectionLabel(l.tasmeeMode),
        _Segmented<TasmeeMode>(
          value: _mode,
          options: [
            (TasmeeMode.continuous, l.tasmeeContinuous, Icons.waves),
            (
              TasmeeMode.verseByVerse,
              l.tasmeeVerseByVerse,
              Icons.format_list_numbered,
            ),
          ],
          onChanged: (v) => setState(() => _mode = v),
        ),
        const SizedBox(height: 12),
        TasmeeSectionLabel(l.tasmeeOnError),
        _Segmented<ErrorBehavior>(
          value: _onError,
          options: [
            (ErrorBehavior.continueReading, l.tasmeeMarkAndGoOn, null),
            (ErrorBehavior.stopToCorrect, l.tasmeeStopToCorrect, null),
          ],
          onChanged: (v) => setState(() => _onError = v),
        ),
        const SizedBox(height: 6),
        Text(
          l.tasmeeDefaultsNote,
          style: TextStyle(color: t.muted, fontSize: 11.5),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const ValueKey('tasmee-start'),
          onPressed: switch (words) {
            AsyncData(value: final ws?) when ws.isNotEmpty => () => _start(
              range,
              ws,
            ),
            _ => null,
          },
          icon: const Icon(Icons.mic),
          label: Text(l.tasmeeStartReciting),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            textStyle: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  List<Widget> _fields(AppLocalizations l, List<SurahRow>? surahs) {
    Widget surah(String label, int value, ValueChanged<int> onChanged) =>
        _SurahField(
          label: label,
          value: value,
          surahs: surahs,
          onChanged: onChanged,
        );
    Widget number(
      String label,
      int value,
      int max,
      ValueChanged<int> onChanged,
    ) => _NumberField(
      label: label,
      value: value,
      max: max,
      onChanged: (v) => setState(() => onChanged(v)),
    );
    int ayahs(int s) => surahs?[s - 1].ayahCount ?? 286;
    Widget pair(Widget a, Widget b, {int flexA = 3, int flexB = 2}) => Row(
      children: [
        Expanded(flex: flexA, child: a),
        const SizedBox(width: 8),
        Expanded(flex: flexB, child: b),
      ],
    );
    return switch (_kind) {
      RecitationRangeKind.surah => [
        surah(l.tasmeeSurah, _surah, (v) => setState(() => _surah = v)),
      ],
      RecitationRangeKind.juz => [
        number(l.tasmeeJuz, _juz, 30, (v) => _juz = v),
      ],
      RecitationRangeKind.hizb => [
        number(l.tasmeeHizb, _hizb, 60, (v) => _hizb = v),
      ],
      RecitationRangeKind.quarter => [
        pair(
          number(l.tasmeeHizb, _hizb, 60, (v) => _hizb = v),
          number(l.tasmeeQuarterOfHizb, _quarter, 4, (v) => _quarter = v),
          flexA: 1,
          flexB: 1,
        ),
      ],
      RecitationRangeKind.halfHizb => [
        pair(
          number(l.tasmeeHizb, _hizb, 60, (v) => _hizb = v),
          _Segmented<int>(
            value: _half,
            options: [
              (1, l.tasmeeFirstHalf, null),
              (2, l.tasmeeSecondHalf, null),
            ],
            onChanged: (v) => setState(() => _half = v),
          ),
          flexA: 1,
          flexB: 1,
        ),
      ],
      RecitationRangeKind.threeQuartersHizb => [
        number(l.tasmeeHizb, _hizb, 60, (v) => _hizb = v),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.tasmeeFromSecondQuarter),
          value: _fromSecondQuarter,
          onChanged: (v) => setState(() => _fromSecondQuarter = v),
        ),
      ],
      RecitationRangeKind.pages => [
        pair(
          number(l.tasmeeFromPage, _pageFrom, lastMushafPage, (v) {
            _pageFrom = v;
            if (_pageTo < v) _pageTo = v;
          }),
          number(l.tasmeeToPage, _pageTo, lastMushafPage, (v) => _pageTo = v),
          flexA: 1,
          flexB: 1,
        ),
      ],
      RecitationRangeKind.verses => [
        pair(
          surah(
            l.tasmeeFromSurah,
            _fromSurah,
            (v) => setState(() {
              _fromSurah = v;
              _fromAyah = 1;
              if (_toSurah < v) {
                _toSurah = v;
                _toAyah = ayahs(v);
              }
            }),
          ),
          number(
            l.tasmeeAyah,
            _fromAyah.clamp(1, ayahs(_fromSurah)),
            ayahs(_fromSurah),
            (v) => _fromAyah = v,
          ),
        ),
        pair(
          surah(
            l.tasmeeToSurah,
            _toSurah,
            (v) => setState(() {
              _toSurah = v;
              _toAyah = ayahs(v);
            }),
          ),
          number(
            l.tasmeeAyah,
            _toAyah.clamp(1, ayahs(_toSurah)),
            ayahs(_toSurah),
            (v) => _toAyah = v,
          ),
        ),
      ],
    };
  }
}

class _ResumeRow extends StatelessWidget {
  const _ResumeRow({
    required this.label,
    required this.action,
    required this.onTap,
  });

  final String label;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      button: true,
      label: '$label · $action',
      excludeSemantics: true,
      child: Material(
        color: t.highlight,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: const ValueKey('tasmee-resume'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(Icons.history, size: 18, color: t.goldText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: t.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  action,
                  style: TextStyle(
                    color: t.goldText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(
                  rtl ? Icons.chevron_left : Icons.chevron_right,
                  size: 18,
                  color: t.goldText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? t.control : t.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? t.control : t.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? t.onControl : t.ink,
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<(T, String, IconData?)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          for (final (v, label, icon) in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: v == value,
                label: label,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(v),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 38),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: v == value ? t.paper : null,
                      borderRadius: BorderRadius.circular(11),
                      border: v == value ? Border.all(color: t.border) : null,
                      boxShadow: v == value
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            size: 16,
                            color: v == value ? t.control : t.muted,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: v == value ? t.ink : t.muted,
                              fontSize: 13.5,
                              fontWeight: v == value
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration(BuildContext context, String label) {
  final t = context.tokens.colors;
  return InputDecoration(
    labelText: label,
    isDense: true,
    filled: true,
    fillColor: t.bg,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: t.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: t.border),
    ),
  );
}

class _SurahField extends StatelessWidget {
  const _SurahField({
    required this.label,
    required this.value,
    required this.surahs,
    required this.onChanged,
  });

  final String label;
  final int value;
  final List<SurahRow>? surahs;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final list = surahs ?? const <SurahRow>[];
    return DropdownButtonFormField<int>(
      key: ValueKey('$label/$value'),
      initialValue: list.isEmpty ? null : value,
      isExpanded: true,
      decoration: _fieldDecoration(context, label),
      items: [
        for (final s in list)
          DropdownMenuItem(
            value: s.id,
            child: Text(
              '${context.digits(s.id)}. ${ar ? s.nameAr : s.nameEn}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

/// A number from 1 to [max]: typed, or stepped with the arrows.
class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final _controller = TextEditingController(text: '${widget.value}');

  @override
  void didUpdateWidget(_NumberField old) {
    super.didUpdateWidget(old);
    if (int.tryParse(_controller.text) != widget.value) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _step(int by) {
    final v = (widget.value + by).clamp(1, widget.max);
    _controller.text = '$v';
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    return Semantics(
      label: widget.label,
      value: '${widget.value}',
      increasedValue: '${(widget.value + 1).clamp(1, widget.max)}',
      decreasedValue: '${(widget.value - 1).clamp(1, widget.max)}',
      onIncrease: () => _step(1),
      onDecrease: () => _step(-1),
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: _fieldDecoration(context, widget.label).copyWith(
          helperText: l.tasmeeOneTo(context.digits(widget.max)),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: l.tasmeeLess,
                onPressed: widget.value > 1 ? () => _step(-1) : null,
                icon: Icon(Icons.remove, size: 18, color: t.goldText),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: l.tasmeeMore,
                onPressed: widget.value < widget.max ? () => _step(1) : null,
                icon: Icon(Icons.add, size: 18, color: t.goldText),
              ),
            ],
          ),
        ),
        onChanged: (text) {
          final v = int.tryParse(text);
          if (v != null && v >= 1 && v <= widget.max) widget.onChanged(v);
        },
      ),
    );
  }
}

/// «11 verses · 123 words · page 3», or why the range is not valid.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.words,
    required this.surahName,
    required this.invalid,
  });

  final AsyncValue<List<ExpectedWord>?> words;
  final String Function(int surah) surahName;
  final String invalid;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final text = switch (words) {
      AsyncData(value: final ws?) when ws.isNotEmpty => () {
        final verses = ws.map((w) => w.verseId).toSet().length;
        final pages = ws.map((w) => w.page);
        final p0 = pages.reduce((a, b) => a < b ? a : b);
        final p1 = pages.reduce((a, b) => a > b ? a : b);
        final first = ws.first, last = ws.last;
        return l.tasmeeRangeSummary(
          '${surahName(first.surah)} ${context.digits(first.ayah)}',
          '${surahName(last.surah)} ${context.digits(last.ayah)}',
          context.digits(verses),
          context.digits(ws.length),
          p0 == p1
              ? context.digits(p0)
              : '${context.digits(p0)}–${context.digits(p1)}',
        );
      }(),
      AsyncData() => invalid,
      AsyncError() => invalid,
      _ => '…',
    };
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_stories_outlined, size: 16, color: t.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: t.muted, fontSize: 12.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
