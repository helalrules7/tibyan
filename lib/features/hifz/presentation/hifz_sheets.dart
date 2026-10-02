import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../mushaf/mushaf_providers.dart';
import '../../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import '../data/hifz_repository.dart';
import '../domain/fsrs.dart';
import '../hifz_providers.dart';

String gradeLabel(AppLocalizations l, Grade g) => switch (g) {
  Grade.again => l.gradeAgain,
  Grade.hard => l.gradeHard,
  Grade.good => l.gradeGood,
  Grade.easy => l.gradeEasy,
};

/// A date in the interface language, for review dates.
String reviewDate(BuildContext context, DateTime d) =>
    DateFormat.MMMEd(Localizations.localeOf(context).languageCode).format(d);

/// Asks how the test went; [suggested] is preselected from the verse
/// results. Returns null when dismissed.
Future<Grade?> showGradeSheet(
  BuildContext context, {
  required String title,
  required Grade suggested,
  String? counts,
}) => showModalBottomSheet<Grade>(
  context: context,
  showDragHandle: true,
  builder: (context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.gradeTitle, style: Theme.of(context).textTheme.titleLarge),
            Text(title, style: TextStyle(color: t.muted)),
            if (counts != null)
              Text(counts, style: TextStyle(color: t.muted, fontSize: 12)),
            const SizedBox(height: 12),
            for (final g in Grade.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: g == suggested
                    ? FilledButton(
                        onPressed: () => Navigator.pop(context, g),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(
                          '${gradeLabel(l, g)} · ${l.gradeSuggested}',
                        ),
                      )
                    : OutlinedButton(
                        onPressed: () => Navigator.pop(context, g),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(gradeLabel(l, g)),
                      ),
              ),
          ],
        ),
      ),
    );
  },
);

/// Chooses a unit to recite: a page of the edition being read, a hizb
/// quarter or a surah. Returns the unit, or null when dismissed.
Future<HifzUnit?> showStartTestSheet(BuildContext context) =>
    showModalBottomSheet<HifzUnit>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: const SafeArea(child: StartTestForm()),
      ),
    );

class StartTestForm extends ConsumerStatefulWidget {
  const StartTestForm({super.key});

  @override
  ConsumerState<StartTestForm> createState() => _StartTestFormState();
}

class _StartTestFormState extends ConsumerState<StartTestForm> {
  HifzUnitKind _kind = HifzUnitKind.page;
  final _number = TextEditingController();
  int _surah = 1;

  @override
  void initState() {
    super.initState();
    final pos = ref.read(readingPositionProvider).value;
    if (pos != null) {
      _number.text = '${pos.page}';
      _surah = pos.surah;
    }
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  int get _max => switch (_kind) {
    HifzUnitKind.page => ref.read(editionProvider).pageCount,
    HifzUnitKind.quarter => 240,
    HifzUnitKind.surah => 114,
  };

  /// The typed number, in either digit set, when in range.
  int? get _value {
    final s = _number.text.trim().replaceAllMapped(
      RegExp('[٠-٩]'),
      (m) => '${m[0]!.codeUnitAt(0) - 0x0660}',
    );
    final n = int.tryParse(s);
    return n != null && n >= 1 && n <= _max ? n : null;
  }

  Future<void> _begin() async {
    final number = _kind == HifzUnitKind.surah ? _surah : _value;
    if (number == null) return;
    final unit = await ref
        .read(hifzRepositoryProvider)
        .unit(_kind, number, ref.read(editionProvider));
    if (mounted) Navigator.pop(context, unit);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final digits = NumberFormatter(Localizations.localeOf(context));
    final surahs = ref.watch(surahsProvider).value;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.hifzChooseUnit, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SegmentedButton<HifzUnitKind>(
            segments: [
              ButtonSegment(
                value: HifzUnitKind.page,
                label: Text(l.hifzUnitPage),
              ),
              ButtonSegment(
                value: HifzUnitKind.quarter,
                label: Text(l.hifzUnitQuarter),
              ),
              ButtonSegment(
                value: HifzUnitKind.surah,
                label: Text(l.hifzUnitSurah),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: 12),
          if (_kind == HifzUnitKind.surah)
            DropdownButtonFormField<int>(
              initialValue: _surah,
              isExpanded: true,
              items: [
                for (final s in surahs ?? const [])
                  DropdownMenuItem(
                    value: s.id,
                    child: Text(
                      '${digits(s.id)}. ${arabic ? s.nameAr : s.nameEn}',
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _surah = v ?? _surah),
            )
          else
            TextField(
              controller: _number,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩]')),
              ],
              decoration: InputDecoration(
                labelText: l.hifzNumberRange(digits(_max)),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _begin(),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _kind == HifzUnitKind.surah || _value != null
                ? _begin
                : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(l.hifzBegin),
          ),
        ],
      ),
    );
  }
}
