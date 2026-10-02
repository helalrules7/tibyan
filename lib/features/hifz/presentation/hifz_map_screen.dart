import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../mushaf/mushaf_providers.dart';
import '../../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import '../data/hifz_repository.dart';
import '../domain/strength.dart';
import '../hifz_providers.dart';
import 'hifz_screen.dart';
import 'strength_style.dart';

/// Pages of the edition being read, or the 114 surahs, coloured by the
/// strength of their weakest memorized verse. Pinch (or the zoom buttons)
/// to make the cells larger or smaller; tap a cell to test it.
class HifzMapScreen extends ConsumerStatefulWidget {
  const HifzMapScreen({super.key});

  @override
  ConsumerState<HifzMapScreen> createState() => _HifzMapScreenState();
}

class _HifzMapScreenState extends ConsumerState<HifzMapScreen> {
  bool _surahs = false;
  double _cell = 46;
  double _pinchStart = 46;
  double _spread = 0;
  final _pointers = <int, Offset>{};

  double _distance() {
    final p = _pointers.values.toList();
    return (p[0] - p[1]).distance;
  }

  static const _min = 30.0;
  static const _max = 110.0;

  void _zoom(double to) => setState(() => _cell = to.clamp(_min, _max));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tokens = context.tokens;
    final t = tokens.colors;
    final edition = ref.watch(editionProvider);
    final strengths = ref.watch(verseStrengthsProvider).value ?? const {};
    final cells = ref.watch(verseCellsProvider).value;
    final surahs = ref.watch(surahsProvider).value;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final arabic = Localizations.localeOf(context).languageCode == 'ar';

    final byVerse = <String, List<int>>{};
    for (final (ref, surah, p1441, p1405, sh0, sh1)
        in cells ?? const <(String, int, int, int, int, int)>[]) {
      byVerse[ref] = _surahs
          ? [surah]
          : switch (edition) {
              MushafEdition.madina1441 => [p1441],
              MushafEdition.madina1405 => [p1405],
              MushafEdition.shamarly => [for (var p = sh0; p <= sh1; p++) p],
            };
    }
    final levels = cellStrengths(strengths, (r) => byVerse[r] ?? const []);
    final first = _surahs || edition != MushafEdition.shamarly ? 1 : 2;
    final last = _surahs ? 114 : edition.pageCount;
    final width = _surahs ? _cell * 2.2 : _cell;

    Future<void> open(int n) async {
      final kind = _surahs ? HifzUnitKind.surah : HifzUnitKind.page;
      final unit = await ref
          .read(hifzRepositoryProvider)
          .unit(kind, n, edition);
      if (unit == null || !context.mounted) return;
      await openHifzTest(
        context,
        ref,
        kind: kind,
        fromRef: unit.fromRef,
        toRef: unit.toRef,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.hifzMap),
        actions: [
          IconButton(
            tooltip: l.mapZoomOut,
            onPressed: _cell > _min ? () => _zoom(_cell - 12) : null,
            icon: const Icon(Icons.zoom_out),
          ),
          IconButton(
            tooltip: l.mapZoomIn,
            onPressed: _cell < _max ? () => _zoom(_cell + 12) : null,
            icon: const Icon(Icons.zoom_in),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l.mapPages)),
                ButtonSegment(value: true, label: Text(l.mapSurahs)),
              ],
              selected: {_surahs},
              onSelectionChanged: (s) => setState(() => _surahs = s.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                for (final s in Strength.values)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Swatch(strength: s, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        strengthLabel(l, s),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            // Pinch: a raw listener, so the grid still scrolls with one
            // finger.
            child: Listener(
              onPointerDown: (e) {
                _pointers[e.pointer] = e.position;
                if (_pointers.length == 2) {
                  _pinchStart = _cell;
                  _spread = _distance();
                }
              },
              onPointerMove: (e) {
                _pointers[e.pointer] = e.position;
                if (_pointers.length == 2 && _spread > 0) {
                  _zoom(_pinchStart * _distance() / _spread);
                }
              },
              onPointerUp: (e) => _pointers.remove(e.pointer),
              onPointerCancel: (e) => _pointers.remove(e.pointer),
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: width,
                  mainAxisExtent: _cell,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: last - first + 1,
                itemBuilder: (context, i) {
                  final n = first + i;
                  final s = levels[n] ?? Strength.none;
                  final label = _surahs
                      ? (surahs == null
                            ? digits(n)
                            : (arabic
                                  ? surahs[n - 1].nameAr
                                  : surahs[n - 1].nameEn))
                      : digits(n);
                  final spoken = _surahs
                      ? l.surahWord(label)
                      : l.pageOf(digits(n));
                  return _Cell(
                    label: label,
                    number: _surahs ? digits(n) : null,
                    strength: s,
                    size: _cell,
                    semantics: l.mapCell(spoken, strengthLabel(l, s)),
                    onTap: () => open(n),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      backgroundColor: t.bg,
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.strength, required this.size});

  final Strength strength;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: size * 1.3,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: strengthFill(strength, tokens.mode),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tokens.colors.border),
      ),
      child: StrengthBars(
        strength: strength,
        color: strengthInk(strength, tokens.mode, tokens.colors.ink),
        height: size * 0.55,
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.number,
    required this.strength,
    required this.size,
    required this.semantics,
    required this.onTap,
  });

  final String label;
  final String? number;
  final Strength strength;
  final double size;
  final String semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final ink = strengthInk(strength, tokens.mode, tokens.colors.ink);
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: Material(
        color: strengthFill(strength, tokens.mode),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: tokens.colors.border, width: 0.8),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      number == null ? label : '$number $label',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: (size * 0.3).clamp(10, 18),
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                  ),
                ),
                if (strength != Strength.none && size >= 34)
                  StrengthBars(
                    strength: strength,
                    color: ink,
                    height: (size * 0.22).clamp(6, 14),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
