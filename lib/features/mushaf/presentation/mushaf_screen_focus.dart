// Focus mode: the thin bar over the page, and the window that holds every
// tool when they are reached by a long press («القائمة»).

part of 'mushaf_screen.dart';

/// One action of focus mode's bars and menu: an icon, its name, and what
/// it does.
typedef _FocusAction = (IconData icon, String label, VoidCallback onTap);

/// Focus mode's only bar, over the page: the surah on the right, the page
/// number in the middle, the juz and the hizb quarter on the left, then
/// focus mode's buttons. A spread names both its pages. In elderly mode it
/// is larger, and its buttons, with their names, take a row of their own.
class _FocusTopBar extends StatelessWidget {
  const _FocusTopBar({super.key, required this.infos, required this.actions});

  /// Height of the bar's row (elderly mode's is larger).
  static const height = 32.0;
  static const elderlyHeight = 40.0;

  /// The frame details of the pages on screen, right to left (null for a
  /// cover, or while loading).
  final List<FrameInfo?> infos;

  /// The buttons at the far left, in order from the right.
  final List<_FocusAction> actions;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    final l = AppLocalizations.of(context);
    final digits = NumberFormatter(Localizations.localeOf(context));
    final elderly = context.tokens.elderly;
    final known = [for (final i in infos) ?i];
    final surahs = <String>{for (final i in known) i.surahName};
    final first = known.firstOrNull;
    final size = elderly ? 18.0 : 15.0;
    final text = TextStyle(
      fontFamily: 'UthmanTahaNaskh',
      fontSize: size,
      height: 1.2,
      color: t.ink,
    );
    final where = first == null
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.juzLabel(digits(first.juz))),
              if (first.quarter != null || first.hizb != null) ...[
                FrameStar(color: t.marker),
                Text(
                  first.quarter != null
                      ? _quarterShort(l, digits, first.quarter!)
                      : l.hizbLabel(digits(first.hizb!)),
                ),
              ],
            ],
          );
    Widget shrink(Widget child, AlignmentDirectional at) =>
        FittedBox(fit: BoxFit.scaleDown, alignment: at, child: child);
    final info = SizedBox(
      height: elderly ? elderlyHeight : height,
      child: DefaultTextStyle.merge(
        style: text,
        // The page number sits halfway between the surah and the juz; a
        // text too long for its room shrinks rather than overflowing.
        child: Row(
          children: [
            Flexible(
              child: shrink(
                Text(
                  surahs.join(' · '),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                AlignmentDirectional.centerStart,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  [for (final i in known) digits(i.page)].join(' – '),
                  semanticsLabel: known.isEmpty
                      ? null
                      : l.pageOf(digits(known.first.page)),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            ?switch (where) {
              final w? => Flexible(
                child: shrink(w, AlignmentDirectional.centerEnd),
              ),
              null => null,
            },
            if (!elderly) ...[
              const SizedBox(width: 6),
              for (final (icon, label, onTap) in actions)
                _SmallFocusButton(icon: icon, label: label, onTap: onTap),
            ],
          ],
        ),
      ),
    );
    return Material(
      color: t.bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          // Laid out as the mushaf is, whatever the interface language.
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: elderly
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      info,
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            for (final (icon, label, onTap) in actions)
                              FilledButton.tonalIcon(
                                onPressed: onTap,
                                icon: Icon(icon),
                                label: Text(label),
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                : info,
          ),
        ),
      ),
    );
  }
}

/// A small icon button of the focus bar: a 32 pt circle, named for screen
/// readers and in a tooltip.
class _SmallFocusButton extends StatelessWidget {
  const _SmallFocusButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 20,
          child: SizedBox.square(
            dimension: _FocusTopBar.height,
            child: Icon(icon, size: 19, color: t.muted),
          ),
        ),
      ),
    );
  }
}

/// Focus mode's bottom tools, shown by the bar's tools button: today's
/// reading bar (the quarter, the small tools, the next page's first word),
/// and in elderly mode the same tools as named buttons.
class _FocusToolsPanel extends StatelessWidget {
  const _FocusToolsPanel({
    super.key,
    required this.bar,
    required this.labelledTools,
  });

  final Widget bar;

  /// Elderly mode: the reading tools with their names; null otherwise.
  final Widget? labelledTools;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Material(
      color: t.paper,
      elevation: 4,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              bar,
              if (labelledTools != null) ...[
                const SizedBox(height: 8),
                labelledTools!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The hizb quarter the page opens in, short as the top box's: «الحزب ٢٨»,
/// «¼ الحزب ٢٨», «½ الحزب ٢٨» or «¾ الحزب ٢٨».
String _quarterShort(AppLocalizations l, NumberFormatter digits, int quarter) {
  final hizb = l.hizbLabel(digits((quarter - 1) ~/ 4 + 1));
  return switch ((quarter - 1) % 4) {
    0 => hizb,
    1 => '¼ $hizb',
    2 => '½ $hizb',
    _ => '¾ $hizb',
  };
}
