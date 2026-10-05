// The hifz test's bar and its grading buttons.

part of 'mushaf_screen.dart';

/// Hifz test toolbar.
class _TestBar extends StatelessWidget {
  const _TestBar({
    required this.verse,
    required this.result,
    required this.byLine,
    required this.counts,
    required this.similar,
    required this.onSimilar,
    required this.onNextWord,
    required this.onNextVerse,
    required this.onAll,
    required this.onRemembered,
    required this.onMissed,
    required this.onGrade,
    required this.onClose,
  });

  /// The verse being recited, named; null before the first reveal.
  final String? verse;
  final VerseResult? result;

  /// The current verse is revealed line by line (no word boxes).
  final bool byLine;
  final String? counts;

  /// Passages similar to the current verse.
  final int similar;
  final VoidCallback? onSimilar;
  final VoidCallback onNextWord;
  final VoidCallback onNextVerse;
  final VoidCallback onAll;
  final VoidCallback? onRemembered;
  final VoidCallback? onMissed;
  final VoidCallback onGrade;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    return Material(
      color: t.paper,
      elevation: 6,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (verse != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            verse!,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (counts != null)
                            Text(
                              counts!,
                              style: TextStyle(fontSize: 12, color: t.muted),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (similar > 0)
                    TextButton.icon(
                      onPressed: onSimilar,
                      icon: const Icon(Icons.compare_arrows, size: 18),
                      label: Text(l.similarCount(digits(similar))),
                    ),
                ],
              ),
              if (byLine)
                Text(
                  l.revealByLine,
                  style: TextStyle(fontSize: 12, color: t.muted),
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _JudgeButton(
                      label: l.verseRemembered,
                      icon: Icons.check,
                      chosen: result == VerseResult.remembered,
                      onPressed: onRemembered,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _JudgeButton(
                      label: l.verseMissed,
                      icon: Icons.close,
                      chosen: result == VerseResult.missed,
                      onPressed: onMissed,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onNextWord,
                    child: Text(l.revealNextWord),
                  ),
                ),
                IconButton(
                  tooltip: l.revealNextVerse,
                  onPressed: onNextVerse,
                  icon: const Icon(Icons.keyboard_double_arrow_left),
                ),
                IconButton(
                  tooltip: l.revealAll,
                  onPressed: onAll,
                  icon: const Icon(Icons.visibility_outlined),
                ),
                IconButton(
                  tooltip: l.gradeUnit,
                  onPressed: onGrade,
                  icon: const Icon(Icons.grading),
                ),
                IconButton(
                  tooltip: l.endRecite,
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// «حفظت» or «أخطأت» for the current verse; filled once chosen.
class _JudgeButton extends StatelessWidget {
  const _JudgeButton({
    required this.label,
    required this.icon,
    required this.chosen,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool chosen;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: chosen,
    child: chosen
        ? FilledButton.tonalIcon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
          ),
  );
}
