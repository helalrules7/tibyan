import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../mushaf/mushaf_providers.dart';
import '../../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import '../domain/day.dart';
import '../domain/khatma_plan.dart';
import '../khatma_providers.dart';
import 'khatma_screen.dart' show formatDay, formatMinutes;

enum _PlanBy { date, amount }

/// Plans a khatma in the pages of the edition being read: by an end date
/// or by a daily amount of pages, juz or hizb.
class NewKhatmaScreen extends ConsumerStatefulWidget {
  const NewKhatmaScreen({super.key});

  @override
  ConsumerState<NewKhatmaScreen> createState() => _NewKhatmaScreenState();
}

class _NewKhatmaScreenState extends ConsumerState<NewKhatmaScreen> {
  final _title = TextEditingController();
  _PlanBy _by = _PlanBy.date;
  PortionUnit _unit = PortionUnit.page;
  int _days = 30;
  double _amount = 1;
  int? _reminder = 20 * 60;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  static const _amounts = {
    PortionUnit.page: [1.0, 2, 4, 5, 10, 15, 20, 30, 40],
    PortionUnit.juz: [0.5, 1, 2, 3, 5],
    PortionUnit.hizb: [0.5, 1, 2, 3, 4],
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final edition = ref.watch(editionProvider);
    final unit = _by == _PlanBy.date ? PortionUnit.page : _unit;
    final starts = ref.watch(unitStartsProvider((edition, unit))).value;
    final today = Day.today();
    final days = _by == _PlanBy.date || starts == null
        ? _days
        : KhatmaPlan.daysFor(starts.length, _amount);
    final target = today.add(days - 1);
    final pages = starts == null ? null : edition.pageCount - starts.first + 1;
    String amountLabel(num a) => a == 0.5 ? '½' : digits(a.toInt());
    String unitLabel(PortionUnit u) => switch (u) {
      PortionUnit.page => l.khatmaUnitPage,
      PortionUnit.juz => l.khatmaUnitJuz,
      PortionUnit.hizb => l.khatmaUnitHizb,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l.khatmaNew)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: InputDecoration(
              labelText: l.khatmaNameLabel,
              hintText: l.khatmaDefaultName,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.khatmaEditionNote(editionName(l, edition)),
            style: TextStyle(color: t.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SegmentedButton<_PlanBy>(
            segments: [
              ButtonSegment(value: _PlanBy.date, label: Text(l.khatmaByDate)),
              ButtonSegment(
                value: _PlanBy.amount,
                label: Text(l.khatmaByAmount),
              ),
            ],
            selected: {_by},
            onSelectionChanged: (s) => setState(() => _by = s.single),
          ),
          const SizedBox(height: 16),
          if (_by == _PlanBy.date)
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
                if (picked != null) {
                  setState(() => _days = Day.of(picked).difference(today) + 1);
                }
              },
            )
          else ...[
            Text(l.khatmaAmountLabel),
            const SizedBox(height: 8),
            SegmentedButton<PortionUnit>(
              segments: [
                for (final u in PortionUnit.values)
                  ButtonSegment(value: u, label: Text(unitLabel(u))),
              ],
              selected: {_unit},
              onSelectionChanged: (s) => setState(() {
                _unit = s.single;
                _amount = 1;
              }),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in _amounts[_unit]!)
                  ChoiceChip(
                    label: Text(amountLabel(a)),
                    selected: _amount == a,
                    onSelected: (_) => setState(() => _amount = a.toDouble()),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (pages != null)
            Text(
              '${l.khatmaDuration(digits(days), formatDay(context, target))}\n'
              '${l.khatmaAboutPerDay(digits((pages / days).ceil()))}',
              style: TextStyle(color: t.muted, height: 1.6),
            ),
          const Divider(height: 32),
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
            onChanged: (on) async {
              if (!on) return setState(() => _reminder = null);
              final time = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 20, minute: 0),
              );
              if (time != null) {
                setState(() => _reminder = time.hour * 60 + time.minute);
              }
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving || starts == null
                ? null
                : () => _save(edition, unit, today, target),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(l.khatmaStart),
          ),
        ],
      ),
    );
  }

  Future<void> _save(
    MushafEdition edition,
    PortionUnit unit,
    Day today,
    Day target,
  ) async {
    final l = AppLocalizations.of(context);
    final open = await ref.read(khatmaRepositoryProvider).active();
    if (open != null && mounted) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text(l.khatmaReplaceTitle),
          content: Text(l.khatmaReplaceBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(d).pop(false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(d).pop(true),
              child: Text(l.khatmaStart),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _saving = true);
    final title = _title.text.trim();
    await ref
        .read(khatmaServiceProvider)
        .create(
          title: title.isEmpty ? l.khatmaDefaultName : title,
          edition: edition,
          unit: unit,
          start: today,
          target: target,
          dailyPortion: _by == _PlanBy.amount ? _amount : null,
          reminderTime: _reminder,
        );
    if (mounted) context.pop();
  }
}
