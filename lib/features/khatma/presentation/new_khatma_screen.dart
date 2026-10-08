import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/content_database.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../mushaf/mushaf_providers.dart';
import '../../mushaf/presentation/mushaf_screen.dart' show surahName;
import '../../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import '../domain/day.dart';
import '../domain/khatmah.dart';
import '../domain/planner.dart';
import '../domain/quran_index.dart';
import '../khatma_providers.dart';
import 'khatma_screen.dart' show formatDay, formatMinutes;

enum _PlanBy { date, amount }

class NewKhatmaScreen extends ConsumerStatefulWidget {
  const NewKhatmaScreen({super.key});

  @override
  ConsumerState<NewKhatmaScreen> createState() => _NewKhatmaScreenState();
}

class _NewKhatmaScreenState extends ConsumerState<NewKhatmaScreen> {
  final _title = TextEditingController();
  int _step = 0;
  KhatmahKind _kind = KhatmahKind.fullQuran;
  KhatmahPreset? _preset;
  _PlanBy _by = _PlanBy.date;
  WirdUnit _unit = WirdUnit.page;
  ScheduleMode _schedule = ScheduleMode.adaptive;
  CountingMode _counting = CountingMode.auto;
  int _days = 30;
  double _amount = 1;
  int _fromSurah = 1;
  int _fromAyah = 1;
  int _toSurah = 114;
  int? _toAyah;
  int? _reminder = 20 * 60;
  final _restWeekdays = <int>{};
  bool _isPrimary = true;
  bool _saving = false;

  static const _amounts = {
    WirdUnit.page: [0.5, 1.0, 2, 4, 5, 10, 15, 20, 30, 40],
    WirdUnit.rub: [1.0, 2, 4, 8, 12, 16, 20, 30, 40, 60],
    WirdUnit.hizb: [0.5, 1.0, 2, 3, 4, 8],
    WirdUnit.juz: [0.5, 1.0, 2, 3, 5],
  };

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final edition = ref.watch(editionProvider);
    final today = ref.watch(todayProvider);
    final indexState = ref.watch(quranIndexProvider);
    final surahsState = ref.watch(surahsProvider);
    final editionPagesState = ref.watch(editionPagesProvider(edition));

    final steps = [l.khatmaStepPlan, l.khatmaStepSchedule, l.khatmaStepReview];
    final planStep = indexState.when(
      data: (index) => surahsState.when(
        data: (surahs) => _buildPlanStep(context, l, digits, index, surahs),
        loading: () => _loading(l),
        error: (error, _) => _loadError(l, error, () {
          ref.invalidate(surahsProvider);
        }),
      ),
      loading: () => _loading(l),
      error: (error, _) => _loadError(l, error, () {
        ref.invalidate(quranIndexProvider);
      }),
    );

    final canContinue = switch (_step) {
      0 =>
        _kind == KhatmahKind.fullQuran ||
            _kind == KhatmahKind.dailyWird ||
            _rangeIds(indexState.value) != null,
      1 => _restWeekdays.length < 7,
      _ =>
        indexState.value != null &&
            surahsState.value != null &&
            editionPagesState.hasValue,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l.khatmaNew),
        leading: _step == 0
            ? null
            : IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => setState(() => _step--),
                icon: const Icon(Icons.arrow_back),
              ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[_step],
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (_step + 1) / steps.length,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (var i = 0; i < steps.length; i++) ...[
                            if (i > 0)
                              Icon(
                                Directionality.of(context) == TextDirection.rtl
                                    ? Icons.chevron_left
                                    : Icons.chevron_right,
                                size: 16,
                                color: colors.muted,
                              ),
                            Text(
                              steps[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: i == _step
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: i == _step
                                    ? colors.control
                                    : colors.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      if (_step == 0) planStep,
                      if (_step == 1)
                        _buildScheduleStep(context, l, digits, today),
                      if (_step == 2)
                        indexState.when(
                          data: (index) => surahsState.when(
                            data: (surahs) => editionPagesState.when(
                              data: (pages) => _buildReviewStep(
                                context,
                                l,
                                digits,
                                index,
                                surahs,
                                edition,
                                today,
                                pages?.textPages.length ??
                                    index.madina1441.textPages.length,
                              ),
                              loading: () => _loading(l),
                              error: (error, _) => _loadError(l, error, () {
                                ref.invalidate(editionPagesProvider(edition));
                              }),
                            ),
                            loading: () => _loading(l),
                            error: (error, _) => _loadError(l, error, () {
                              ref.invalidate(surahsProvider);
                            }),
                          ),
                          loading: () => _loading(l),
                          error: (error, _) => _loadError(l, error, () {
                            ref.invalidate(quranIndexProvider);
                          }),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving || !canContinue
                          ? null
                          : _step < steps.length - 1
                          ? () => setState(() => _step++)
                          : () => _save(
                              l,
                              edition,
                              today,
                              indexState.value,
                              editionPagesState.value?.textPages.length ??
                                  indexState.value?.madina1441.textPages.length,
                            ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _step == steps.length - 1
                                  ? l.khatmaStart
                                  : l.continueLabel,
                            ),
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

  Widget _loading(AppLocalizations l) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Center(
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(l.loadingLabel),
        ],
      ),
    ),
  );

  Widget _loadError(AppLocalizations l, Object error, VoidCallback retry) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Text(l.khatmaLoadFailed(error.toString())),
            TextButton(onPressed: retry, child: Text(l.downloadRetry)),
          ],
        ),
      );

  Widget _buildPlanStep(
    BuildContext context,
    AppLocalizations l,
    NumberFormatter digits,
    QuranIndex index,
    List<SurahRow> surahs,
  ) {
    final colors = context.tokens.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l.khatmaNameLabel,
            hintText: l.khatmaDefaultName,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<KhatmahKind>(
          initialValue: _kind,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l.khatmaKindLabel,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final kind in KhatmahKind.values)
              DropdownMenuItem(value: kind, child: Text(_kindLabel(l, kind))),
          ],
          onChanged: (kind) {
            if (kind == null) return;
            setState(() {
              _kind = kind;
              _preset = null;
              if (kind == KhatmahKind.dailyWird) {
                _by = _PlanBy.amount;
                _unit = WirdUnit.juz;
                _amount = 1;
              }
            });
          },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _preset?.id ?? '',
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l.khatmaPresetLabel,
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: '', child: Text(l.khatmaPresetCustom)),
            for (final preset in KhatmahPreset.values)
              DropdownMenuItem(
                value: preset.id,
                child: Text(_presetLabel(l, preset, digits)),
              ),
          ],
          onChanged: (id) {
            final preset = KhatmahPreset.byId(id);
            setState(() {
              _preset = preset;
              if (preset != null) {
                _kind = preset.kind;
                _unit = preset.unit;
                _schedule = preset.schedule;
                _days = preset.days ?? 30;
                _by = preset.pacing == PacingMode.openEnded
                    ? _PlanBy.amount
                    : _PlanBy.date;
                _amount = 1;
                _restWeekdays.clear();
              }
            });
          },
        ),
        const SizedBox(height: 14),
        Text(
          l.khatmaEditionNote(editionName(l, ref.read(editionProvider))),
          style: TextStyle(color: colors.muted, fontSize: 13),
        ),
        if (_kind == KhatmahKind.partial || _kind == KhatmahKind.custom) ...[
          const SizedBox(height: 18),
          Text(
            l.khatmaReviewRange(
              _verseLabel(
                context,
                digits,
                index,
                surahs,
                _fromSurah,
                _fromAyah,
              ),
              _verseLabel(
                context,
                digits,
                index,
                surahs,
                _toSurah,
                _toAyah ?? surahs[_toSurah - 1].ayahCount,
              ),
            ),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          _surahSelector(
            l.khatmaFromSurah,
            _fromSurah,
            surahs,
            digits,
            (value) => setState(() {
              _fromSurah = value;
              _fromAyah = 1;
              if (_toSurah < value) {
                _toSurah = value;
                _toAyah = null;
              }
            }),
          ),
          const SizedBox(height: 12),
          _ayahSelector(
            l.khatmaFromAyah,
            _fromAyah,
            surahs[_fromSurah - 1].ayahCount,
            digits,
            (value) => setState(() => _fromAyah = value),
          ),
          const SizedBox(height: 12),
          _surahSelector(
            l.khatmaToSurah,
            _toSurah,
            surahs,
            digits,
            (value) => setState(() {
              _toSurah = value;
              _toAyah = null;
              if (_fromSurah > value) {
                _fromSurah = value;
                _fromAyah = 1;
              }
            }),
          ),
          const SizedBox(height: 12),
          _ayahSelector(
            l.khatmaToAyah,
            _toAyah ?? surahs[_toSurah - 1].ayahCount,
            surahs[_toSurah - 1].ayahCount,
            digits,
            (value) => setState(() => _toAyah = value),
          ),
          if (_rangeIds(index) == null) ...[
            const SizedBox(height: 8),
            Text(
              l.khatmaRangeError,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _surahSelector(
    String label,
    int value,
    List<SurahRow> surahs,
    NumberFormatter digits,
    ValueChanged<int> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final surah in surahs)
          DropdownMenuItem(
            value: surah.id,
            child: Text(
              '${digits(surah.id)}. ${surahName(context, surah)}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  Widget _ayahSelector(
    String label,
    int value,
    int ayahCount,
    NumberFormatter digits,
    ValueChanged<int> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (var ayah = 1; ayah <= ayahCount; ayah++)
          DropdownMenuItem(value: ayah, child: Text(digits(ayah))),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  Widget _buildScheduleStep(
    BuildContext context,
    AppLocalizations l,
    NumberFormatter digits,
    Day today,
  ) {
    final colors = context.tokens.colors;
    final target = today.add(_days - 1);
    final weekdays = MaterialLocalizations.of(context).narrowWeekdays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_kind != KhatmahKind.dailyWird) ...[
          SegmentedButton<_PlanBy>(
            segments: [
              ButtonSegment(value: _PlanBy.date, label: Text(l.khatmaByDate)),
              ButtonSegment(
                value: _PlanBy.amount,
                label: Text(l.khatmaByAmount),
              ),
            ],
            selected: {_by},
            onSelectionChanged: (selection) => setState(() {
              _by = selection.single;
              if (_by == _PlanBy.amount) {
                _schedule = ScheduleMode.adaptive;
              }
            }),
          ),
          const SizedBox(height: 18),
        ],
        if (_by == _PlanBy.date && _kind != KhatmahKind.dailyWird) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(l.khatmaEndDateLabel),
            subtitle: Text(formatDay(context, target)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: target.start,
                firstDate: today.start,
                lastDate: today.add(3650).start,
              );
              if (picked != null && mounted) {
                setState(() => _days = Day.of(picked).difference(today) + 1);
              }
            },
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final days in [7, 15, 20, 30, 60])
                ChoiceChip(
                  label: Text(digits(days)),
                  selected: _days == days,
                  onSelected: (_) => setState(() => _days = days),
                ),
            ],
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<ScheduleMode>(
            initialValue: _schedule,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l.khatmaScheduleMode,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: ScheduleMode.adaptive,
                child: Text(l.khatmaScheduleAdaptive),
              ),
              DropdownMenuItem(
                value: ScheduleMode.fixed,
                child: Text(l.khatmaScheduleFixed),
              ),
            ],
            onChanged: (schedule) {
              if (schedule != null) setState(() => _schedule = schedule);
            },
          ),
        ] else ...[
          DropdownButtonFormField<WirdUnit>(
            initialValue: _unit,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l.khatmaAmountLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final unit in WirdUnit.values)
                DropdownMenuItem(value: unit, child: Text(_unitLabel(l, unit))),
            ],
            onChanged: (unit) {
              if (unit == null) return;
              setState(() {
                _unit = unit;
                _amount = 1;
              });
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final amount in _amounts[_unit]!)
                ChoiceChip(
                  label: Text(_amountLabel(digits, amount)),
                  selected: _amount == amount,
                  onSelected: (_) =>
                      setState(() => _amount = amount.toDouble()),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _kind == KhatmahKind.dailyWird
                ? l.khatmaKindDaily
                : l.khatmaByAmount,
            style: TextStyle(color: colors.muted, fontSize: 13),
          ),
        ],
        const SizedBox(height: 20),
        Text(l.khatmaRestDays),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (
              var weekday = DateTime.monday;
              weekday <= DateTime.sunday;
              weekday++
            )
              FilterChip(
                label: Text(weekdays[weekday % 7]),
                selected: _restWeekdays.contains(weekday),
                onSelected: (selected) => setState(() {
                  if (selected && _restWeekdays.length < 6) {
                    _restWeekdays.add(weekday);
                  } else {
                    _restWeekdays.remove(weekday);
                  }
                }),
              ),
          ],
        ),
        if (_restWeekdays.length == 6) ...[
          const SizedBox(height: 6),
          Text(
            l.khatmaAtLeastOneReadingDay,
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 20),
        DropdownButtonFormField<CountingMode>(
          initialValue: _counting,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l.khatmaCountingMode,
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(
              value: CountingMode.auto,
              child: Text(l.khatmaCountAuto),
            ),
            if (!_isPrimary)
              DropdownMenuItem(
                value: CountingMode.ask,
                child: Text(l.khatmaCountAsk),
              ),
            DropdownMenuItem(
              value: CountingMode.manual,
              child: Text(l.khatmaCountManual),
            ),
          ],
          onChanged: (mode) {
            if (mode != null) setState(() => _counting = mode);
          },
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.khatmaMakePrimary),
          value: _isPrimary,
          onChanged: (value) => setState(() {
            _isPrimary = value;
            if (value && _counting == CountingMode.ask) {
              _counting = CountingMode.auto;
            }
          }),
        ),
        const Divider(height: 24),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.notifications_outlined),
          title: Text(l.khatmaReminder),
          subtitle: Text(
            _reminder == null
                ? l.khatmaReminderOff
                : formatMinutes(context, _reminder!),
          ),
          value: _reminder != null,
          onChanged: (enabled) async {
            if (!enabled) return setState(() => _reminder = null);
            final time = await showTimePicker(
              context: context,
              initialTime: const TimeOfDay(hour: 20, minute: 0),
            );
            if (time != null && mounted) {
              setState(() => _reminder = time.hour * 60 + time.minute);
            }
          },
        ),
      ],
    );
  }

  Widget _buildReviewStep(
    BuildContext context,
    AppLocalizations l,
    NumberFormatter digits,
    QuranIndex index,
    List<SurahRow> surahs,
    MushafEdition edition,
    Day today,
    int pageCount,
  ) {
    final bounds = _resolvedRange(index);
    final rangeWeight = index.weightOf(bounds.$1, bounds.$2);
    final dailyWeight = _by == _PlanBy.amount || _kind == KhatmahKind.dailyWird
        ? _amount * _unitWeight(_unit, index.totalWeight, pageCount)
        : null;
    final end = _by == _PlanBy.date && _kind != KhatmahKind.dailyWird
        ? today.add(_days - 1)
        : dailyWeight == null
        ? null
        : _endAfterReadingDays(
            today,
            (rangeWeight / dailyWeight).ceil(),
            _restWeekdays,
          );
    final title = _title.text.trim().isEmpty
        ? l.khatmaDefaultName
        : _title.text.trim();
    final weekdayLabels = MaterialLocalizations.of(context).narrowWeekdays;
    final restDays = [
      for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
        if (_restWeekdays.contains(weekday)) weekdayLabels[weekday % 7],
    ].join(', ');
    final lines = <String>[
      title,
      _kindLabel(l, _kind),
      if (_preset != null) _presetLabel(l, _preset!, digits),
      if (_kind == KhatmahKind.partial || _kind == KhatmahKind.custom)
        l.khatmaReviewRange(
          _verseLabel(context, digits, index, surahs, _fromSurah, _fromAyah),
          _verseLabel(
            context,
            digits,
            index,
            surahs,
            _toSurah,
            _toAyah ?? surahs[_toSurah - 1].ayahCount,
          ),
        ),
      if (_by == _PlanBy.amount || _kind == KhatmahKind.dailyWird)
        '${_amountLabel(digits, _amount)} ${_unitLabel(l, _unit)}',
      if (end != null)
        l.khatmaDuration(
          digits(end.difference(today) + 1),
          formatDay(context, end),
        ),
      if (_by == _PlanBy.date && _kind != KhatmahKind.dailyWird)
        '${l.khatmaScheduleMode}: ${_schedule == ScheduleMode.fixed ? l.khatmaScheduleFixed : l.khatmaScheduleAdaptive}',
      l.khatmaEditionNote(editionName(l, edition)),
      '${l.khatmaCountingMode}: ${_countingLabel(l, _counting)}',
      if (_restWeekdays.isNotEmpty) '${l.khatmaRestDays}: $restDays',
      if (_reminder != null)
        '${l.khatmaReminder}: ${formatMinutes(context, _reminder!)}'
      else
        '${l.khatmaReminder}: ${l.khatmaReminderOff}',
      if (_isPrimary) l.khatmaPrimaryLabel,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines) ...[
              Text(line, style: Theme.of(context).textTheme.bodyLarge),
              if (line != lines.last) const Divider(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save(
    AppLocalizations l,
    MushafEdition edition,
    Day today,
    QuranIndex? index,
    int? pageCount,
  ) async {
    if (index == null || pageCount == null || _saving) return;
    final range = _rangeIds(index);
    if (range == null) return;
    setState(() => _saving = true);
    try {
      final title = _title.text.trim();
      final openEnded = _kind == KhatmahKind.dailyWird;
      final target = _by == _PlanBy.date && !openEnded
          ? today.add(_days - 1)
          : null;
      final dailyWeight = target == null
          ? _amount * _unitWeight(_unit, index.totalWeight, pageCount)
          : null;
      final plan = Khatmah(
        uuid: '',
        title: title.isEmpty ? l.khatmaDefaultName : title,
        kind: _kind,
        rangeStart: range.$1,
        rangeEnd: range.$2,
        startAt: range.$1,
        pacing: openEnded
            ? PacingMode.openEnded
            : target == null
            ? PacingMode.dailyAmount
            : _preset?.pacing ?? PacingMode.endDate,
        schedule: target == null ? ScheduleMode.adaptive : _schedule,
        dailyWeight: dailyWeight,
        startDate: today,
        targetDate: target,
        unit: _unit,
        restWeekdays: Set.unmodifiable(_restWeekdays),
        counting: _counting,
        isPrimary: _isPrimary,
        autoRestart: _preset?.autoRestart ?? openEnded,
        presetId: _preset?.id,
        edition: edition.name,
        reminderTime: _reminder,
        createdAt: DateTime.now(),
      );
      await ref.read(khatmaServiceProvider).createPlan(plan);
      if (mounted) context.pop();
    } catch (error) {
      if (!mounted) rethrow;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.khatmaCreateFailed(error.toString()))),
      );
    }
  }

  (int, int)? _rangeIds(QuranIndex? index) {
    if (index == null) return null;
    final start = _resolvedRange(index).$1;
    final end = _resolvedRange(index).$2;
    return start <= end ? (start, end) : null;
  }

  (int, int) _resolvedRange(QuranIndex index) {
    if (_kind == KhatmahKind.fullQuran || _kind == KhatmahKind.dailyWird) {
      return (1, index.ayahCount);
    }
    return (
      index.idOf(_fromSurah, _fromAyah),
      index.idOf(_toSurah, _toAyah ?? index.ayahCountOf(_toSurah)),
    );
  }

  String _verseLabel(
    BuildContext context,
    NumberFormatter digits,
    QuranIndex index,
    List<SurahRow> surahs,
    int surah,
    int ayah,
  ) {
    final id = index.idOf(surah, ayah);
    final location = index.keyOf(id);
    return '${surahName(context, surahs[location.surah - 1])} '
        '${digits(location.ayah)}';
  }

  String _kindLabel(AppLocalizations l, KhatmahKind kind) => switch (kind) {
    KhatmahKind.fullQuran => l.khatmaKindFull,
    KhatmahKind.partial => l.khatmaKindPartial,
    KhatmahKind.dailyWird => l.khatmaKindDaily,
    KhatmahKind.custom => l.khatmaKindCustom,
  };

  String _presetLabel(
    AppLocalizations l,
    KhatmahPreset preset,
    NumberFormatter digits,
  ) => switch (preset) {
    KhatmahPreset.month => l.khatmaPresetMonth,
    KhatmahPreset.ramadan30 => l.khatmaPresetRamadan30(digits(30)),
    KhatmahPreset.ramadanTwice => l.khatmaPresetRamadanTwice,
    KhatmahPreset.beforeLastTen => l.khatmaPresetBeforeLastTen,
    KhatmahPreset.weekly => l.khatmaPresetWeekly,
    KhatmahPreset.dailyJuz => l.khatmaPresetDailyJuz,
  };

  String _unitLabel(AppLocalizations l, WirdUnit unit) => switch (unit) {
    WirdUnit.page => l.khatmaUnitPage,
    WirdUnit.rub => l.khatmaUnitRub,
    WirdUnit.hizb => l.khatmaUnitHizb,
    WirdUnit.juz => l.khatmaUnitJuz,
  };

  String _countingLabel(AppLocalizations l, CountingMode mode) =>
      switch (mode) {
        CountingMode.auto => l.khatmaCountAuto,
        CountingMode.ask => l.khatmaCountAsk,
        CountingMode.manual => l.khatmaCountManual,
      };

  String _amountLabel(NumberFormatter digits, num amount) =>
      amount == 0.5 ? '½' : digits(amount.toInt());

  double _unitWeight(WirdUnit unit, double totalWeight, int pageCount) =>
      switch (unit) {
        WirdUnit.page => totalWeight / pageCount,
        WirdUnit.rub => totalWeight / 240,
        WirdUnit.hizb => totalWeight / 60,
        WirdUnit.juz => totalWeight / 30,
      };

  Day _endAfterReadingDays(Day start, int count, Set<int> restWeekdays) {
    var day = start;
    var completed = 0;
    while (completed < count) {
      if (!restWeekdays.contains(day.start.weekday)) completed++;
      if (completed < count) day = day.add(1);
    }
    return day;
  }
}
