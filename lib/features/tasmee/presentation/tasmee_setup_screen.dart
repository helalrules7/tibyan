import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../mushaf/mushaf_providers.dart';
import '../../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import '../data/tasmee_words_repository.dart';
import '../domain/recitation_range.dart';
import '../domain/tasmee_session_request.dart';

final _tasmeeVerseIndexProvider = FutureProvider<List<VerseIndexEntry>>(
  (ref) =>
      TasmeeWordsRepository(ref.watch(contentDatabaseProvider)).verseIndex(),
);

class TasmeeSetupScreen extends ConsumerStatefulWidget {
  const TasmeeSetupScreen({super.key});

  @override
  ConsumerState<TasmeeSetupScreen> createState() => _TasmeeSetupScreenState();
}

class _TasmeeSetupScreenState extends ConsumerState<TasmeeSetupScreen> {
  RecitationRangeKind _kind = RecitationRangeKind.surah;
  TasmeeMode _mode = TasmeeMode.continuous;
  int _surah = 1;
  int _fromSurah = 1;
  int _toSurah = 1;
  int _half = 1;
  bool _fromSecondQuarter = false;
  bool _busy = false;

  final _numbers = <String, TextEditingController>{
    'juz': TextEditingController(text: '1'),
    'hizb': TextEditingController(text: '1'),
    'quarter': TextEditingController(text: '1'),
    'pageFrom': TextEditingController(text: '1'),
    'pageTo': TextEditingController(text: '1'),
    'fromAyah': TextEditingController(text: '1'),
    'toAyah': TextEditingController(text: '7'),
  };

  @override
  void dispose() {
    for (final controller in _numbers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int? _number(String key) => int.tryParse(_numbers[key]!.text.trim());

  RecitationRange? _range() {
    final juz = _number('juz');
    final hizb = _number('hizb');
    final quarter = _number('quarter');
    final pageFrom = _number('pageFrom');
    final pageTo = _number('pageTo');
    final fromAyah = _number('fromAyah');
    final toAyah = _number('toAyah');
    return switch (_kind) {
      RecitationRangeKind.surah => SurahRange(_surah),
      RecitationRangeKind.juz => juz == null ? null : JuzRange(juz),
      RecitationRangeKind.hizb =>
        hizb == null ? null : HizbPartRange.hizb(hizb),
      RecitationRangeKind.quarter =>
        quarter == null ? null : HizbPartRange.quarter(quarter),
      RecitationRangeKind.halfHizb =>
        hizb == null ? null : HizbPartRange.half(hizb, _half),
      RecitationRangeKind.threeQuartersHizb =>
        hizb == null
            ? null
            : HizbPartRange.threeQuarters(hizb, fromSecond: _fromSecondQuarter),
      RecitationRangeKind.pages =>
        pageFrom == null || pageTo == null ? null : PageRange(pageFrom, pageTo),
      RecitationRangeKind.verses =>
        fromAyah == null || toAyah == null
            ? null
            : VerseRange(
                fromSurah: _fromSurah,
                fromAyah: fromAyah,
                toSurah: _toSurah,
                toAyah: toAyah,
              ),
    };
  }

  Future<void> _continue(List<VerseIndexEntry> index) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final range = _range();
      if (range == null) throw const FormatException('Incomplete range');
      range.validate();
      final words = await TasmeeWordsRepository(
        ref.read(contentDatabaseProvider),
      ).expectedWords(range);
      if (words.isEmpty) {
        throw const FormatException('The range has no words');
      }
      if (!mounted) return;
      await context.push(
        '/tasmee/session',
        extra: TasmeeSessionRequest(
          range: range,
          words: List.unmodifiable(words),
          mode: _mode,
        ),
      );
    } on RangeError {
      if (mounted) _showRangeError();
    } on FormatException catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message == 'The range has no words'
                  ? l.tasmeeEmptyRange
                  : l.tasmeeInvalidRange,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showRangeError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).tasmeeInvalidRange)),
    );
  }

  String _kindLabel(AppLocalizations l, RecitationRangeKind kind) =>
      switch (kind) {
        RecitationRangeKind.surah => l.tasmeeSurah,
        RecitationRangeKind.juz => l.tasmeeJuz,
        RecitationRangeKind.hizb => l.tasmeeHizb,
        RecitationRangeKind.quarter => l.tasmeeQuarter,
        RecitationRangeKind.halfHizb => l.tasmeeHalfHizb,
        RecitationRangeKind.threeQuartersHizb => l.tasmeeThreeQuartersHizb,
        RecitationRangeKind.pages => l.tasmeePages,
        RecitationRangeKind.verses => l.tasmeeVerses,
      };

  Widget _numberField(
    AppLocalizations l, {
    required String keyName,
    required String label,
    required int max,
    TextEditingController? controller,
  }) {
    final fieldController = controller ?? _numbers[keyName]!;
    return TextFormField(
      controller: fieldController,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        helperText: '1–$max',
      ),
    );
  }

  Widget _surahField(
    AppLocalizations l,
    String label,
    int value,
    ValueChanged<int> onChanged,
    List<dynamic> surahs,
  ) {
    final digits = NumberFormatter(Localizations.localeOf(context));
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final s in surahs)
          DropdownMenuItem(
            value: s.id as int,
            child: Text(
              '${digits(s.id as int)}. ${isArabic ? s.nameAr : s.nameEn}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  List<Widget> _rangeFields(AppLocalizations l, List<dynamic> surahs) =>
      switch (_kind) {
        RecitationRangeKind.surah => [
          _surahField(
            l,
            l.tasmeeSurah,
            _surah,
            (v) => setState(() => _surah = v),
            surahs,
          ),
        ],
        RecitationRangeKind.juz => [
          _numberField(l, keyName: 'juz', label: l.tasmeeJuz, max: 30),
        ],
        RecitationRangeKind.hizb => [
          _numberField(l, keyName: 'hizb', label: l.tasmeeHizb, max: 60),
        ],
        RecitationRangeKind.quarter => [
          _numberField(l, keyName: 'quarter', label: l.tasmeeQuarter, max: 240),
        ],
        RecitationRangeKind.halfHizb => [
          _numberField(l, keyName: 'hizb', label: l.tasmeeHizb, max: 60),
          DropdownButtonFormField<int>(
            initialValue: _half,
            decoration: InputDecoration(labelText: l.tasmeeHalf),
            items: [
              DropdownMenuItem(value: 1, child: Text(l.tasmeeFirstHalf)),
              DropdownMenuItem(value: 2, child: Text(l.tasmeeSecondHalf)),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _half = v);
            },
          ),
        ],
        RecitationRangeKind.threeQuartersHizb => [
          _numberField(l, keyName: 'hizb', label: l.tasmeeHizb, max: 60),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.tasmeeFromSecondQuarter),
            value: _fromSecondQuarter,
            onChanged: (v) => setState(() => _fromSecondQuarter = v),
          ),
        ],
        RecitationRangeKind.pages => [
          Row(
            children: [
              Expanded(
                child: _numberField(
                  l,
                  keyName: 'pageFrom',
                  label: l.tasmeeFrom,
                  max: lastMushafPage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numberField(
                  l,
                  keyName: 'pageTo',
                  label: l.tasmeeTo,
                  max: lastMushafPage,
                ),
              ),
            ],
          ),
        ],
        RecitationRangeKind.verses => [
          Row(
            children: [
              Expanded(
                child: _surahField(
                  l,
                  l.tasmeeFrom,
                  _fromSurah,
                  (v) => setState(() => _fromSurah = v),
                  surahs,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numberField(
                  l,
                  keyName: 'fromAyah',
                  label: l.tasmeeVerses,
                  max: 286,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _surahField(
                  l,
                  l.tasmeeTo,
                  _toSurah,
                  (v) => setState(() => _toSurah = v),
                  surahs,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numberField(
                  l,
                  keyName: 'toAyah',
                  label: l.tasmeeVerses,
                  max: 286,
                ),
              ),
            ],
          ),
        ],
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final surahs = ref.watch(surahsProvider).value;
    final index = ref.watch(_tasmeeVerseIndexProvider);
    final digits = NumberFormatter(Localizations.localeOf(context));

    return Scaffold(
      appBar: AppBar(title: Text(l.tasmeeTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: index.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('$error'),
                ),
              ),
              data: (entries) {
                if (surahs == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 28),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.graphic_eq, color: t.goldText, size: 30),
                            const SizedBox(height: 12),
                            Text(
                              l.tasmeeDescription,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l.tasmeeModelAttribution,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: t.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l.tasmeeSelectRange,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: t.goldText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<RecitationRangeKind>(
                      initialValue: _kind,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: l.tasmeeRangeType),
                      items: [
                        for (final kind in RecitationRangeKind.values)
                          DropdownMenuItem(
                            value: kind,
                            child: Text(_kindLabel(l, kind)),
                          ),
                      ],
                      onChanged: (kind) {
                        if (kind != null) setState(() => _kind = kind);
                      },
                    ),
                    const SizedBox(height: 12),
                    ..._rangeFields(l, surahs).map(
                      (field) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: field,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.tasmeeMode,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<TasmeeMode>(
                      segments: [
                        ButtonSegment(
                          value: TasmeeMode.continuous,
                          icon: const Icon(Icons.all_inclusive),
                          label: Text(l.tasmeeContinuous),
                        ),
                        ButtonSegment(
                          value: TasmeeMode.verseByVerse,
                          icon: const Icon(Icons.format_list_numbered),
                          label: Text(l.tasmeeVerseByVerse),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (selection) {
                        setState(() => _mode = selection.first);
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _continue(entries),
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward),
                      label: Text(l.tasmeeContinue),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                    if (_range() case final range?) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${_kindLabel(l, range.kind)} · ${digits(entries.where(range.containsVerse).length)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: t.muted),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
