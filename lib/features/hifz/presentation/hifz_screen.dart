import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/content_database.dart';
import '../../../core/db/user_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../mushaf/data/mushaf_repository.dart';
import '../../mushaf/mushaf_providers.dart';
import '../../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import '../data/hifz_repository.dart';
import '../data/hifz_store.dart';
import '../domain/strength.dart';
import '../hifz_providers.dart';
import 'hifz_sheets.dart';
import 'strength_style.dart';

/// Opens the mushaf on a unit's first page in recitation mode, as a test
/// of that unit (graded at the end).
Future<void> openHifzTest(
  BuildContext context,
  WidgetRef ref, {
  required HifzUnitKind kind,
  required String fromRef,
  required String toRef,
}) async {
  final verses = await ref
      .read(hifzRepositoryProvider)
      .versesOf(fromRef, toRef);
  if (verses.isEmpty || !context.mounted) return;
  final page = verses.first.pageIn(ref.read(editionProvider));
  await context.push(
    '/mushaf?page=$page&hifz=${kind.name}&from=$fromRef&to=$toRef',
  );
}

/// The name of a unit: «صفحة ٥٠», «الربع ١٢» or «سورة الملك».
String unitTitle(
  BuildContext context,
  HifzUnitKind kind,
  AyahRow first,
  int page,
  List<SurahRow>? surahs,
) {
  final l = AppLocalizations.of(context);
  final digits = NumberFormatter(Localizations.localeOf(context));
  final arabic = Localizations.localeOf(context).languageCode == 'ar';
  return switch (kind) {
    HifzUnitKind.page => l.pageOf(digits(page)),
    HifzUnitKind.quarter => l.hifzQuarter(digits(first.hizbQuarter)),
    HifzUnitKind.surah => l.surahWord(
      surahs == null
          ? '${first.surah}'
          : (arabic
                ? surahs[first.surah - 1].nameAr
                : surahs[first.surah - 1].nameEn),
    ),
  };
}

/// Memorization: today's review, starting a test, and the hifz map.
class HifzScreen extends ConsumerWidget {
  const HifzScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final items = ref.watch(srsItemsProvider).value ?? const <SrsItemRow>[];
    final due = dueToday(items, DateTime.now());
    final later = [
      for (final i in items)
        if (!due.contains(i)) i,
    ];
    final strengths = ref.watch(verseStrengthsProvider).value ?? const {};
    final counts = <Strength, int>{};
    for (final v in strengths.values) {
      final s = Strength.of(v);
      counts[s] = (counts[s] ?? 0) + 1;
    }
    final digits = NumberFormatter(Localizations.localeOf(context));

    Future<void> start() async {
      final unit = await showStartTestSheet(context);
      if (unit == null || !context.mounted) return;
      await openHifzTest(
        context,
        ref,
        kind: unit.kind,
        fromRef: unit.fromRef,
        toRef: unit.toRef,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.hifzTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          FilledButton.icon(
            onPressed: start,
            icon: const Icon(Icons.visibility_off_outlined),
            label: Text(l.hifzStartTest),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 20),
          _Heading(l.hifzToday),
          if (due.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.hifzNothingDue,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.hifzNothingDueHint,
                      style: TextStyle(color: t.muted),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final i in due) _UnitTile(item: i, due: true),
          const SizedBox(height: 20),
          _Heading(l.hifzMap),
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push('/hifz/map'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.hifzMapHint, style: TextStyle(color: t.muted)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        for (final s in Strength.values.skip(1))
                          _LegendChip(
                            strength: s,
                            label:
                                '${strengthLabel(l, s)} ${digits(counts[s] ?? 0)}',
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Icon(Icons.arrow_forward, color: t.control),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (later.isNotEmpty) ...[
            const SizedBox(height: 20),
            _Heading(l.hifzAllUnits),
            for (final i in later) _UnitTile(item: i, due: false),
          ],
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: context.tokens.colors.goldText,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.strength, required this.label});

  final Strength strength;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fill = strengthFill(strength, tokens.mode);
    final ink = strengthInk(strength, tokens.mode, tokens.colors.ink);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: tokens.colors.border),
          ),
          child: StrengthBars(strength: strength, color: ink, height: 11),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

/// A review unit: its name, verse range and next date; tap to test it.
class _UnitTile extends ConsumerWidget {
  const _UnitTile({required this.item, required this.due});

  final SrsItemRow item;
  final bool due;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final tokens = context.tokens;
    final kind =
        HifzUnitKind.values.asNameMap()[item.unit] ?? HifzUnitKind.page;
    final verses = ref.watch(_unitVersesProvider((item.fromRef, item.toRef)));
    final surahs = ref.watch(surahsProvider).value;
    final edition = ref.watch(editionProvider);
    final digits = NumberFormatter(Localizations.localeOf(context));
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final first = verses.value?.first;
    final last = verses.value?.last;
    String name(int s) => surahs == null
        ? '$s'
        : (arabic ? surahs[s - 1].nameAr : surahs[s - 1].nameEn);
    final title = first == null
        ? ''
        : unitTitle(context, kind, first, first.pageIn(edition), surahs);
    final range = first == null || last == null
        ? ''
        : first.surah == last.surah
        ? l.verseRange(
            name(first.surah),
            digits(first.number),
            digits(last.number),
          )
        : '${name(first.surah)} ${digits(first.number)} – ${name(last.surah)} ${digits(last.number)}';
    final strength = Strength.fromStability(item.stability);
    return Card(
      child: ListTile(
        onTap: () => openHifzTest(
          context,
          ref,
          kind: kind,
          fromRef: item.fromRef,
          toRef: item.toRef,
        ),
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: strengthFill(strength, tokens.mode),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: t.border),
          ),
          child: StrengthBars(
            strength: strength,
            color: strengthInk(strength, tokens.mode, t.ink),
            height: 16,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '$range\n${due ? l.hifzDueToday : l.hifzDueOn(reviewDate(context, item.dueAt))} · ${strengthLabel(l, strength)}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<int>(
          onSelected: (_) =>
              ref.read(userDatabaseProvider).deleteSrsItem(item.id),
          itemBuilder: (context) => [
            PopupMenuItem(value: 0, child: Text(l.hifzRemove)),
          ],
        ),
      ),
    );
  }
}

final _unitVersesProvider = FutureProvider.autoDispose
    .family<List<AyahRow>, (String, String)>(
      (ref, r) => ref.watch(hifzRepositoryProvider).versesOf(r.$1, r.$2),
    );
