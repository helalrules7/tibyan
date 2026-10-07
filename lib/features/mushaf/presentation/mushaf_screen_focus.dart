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
  const _FocusTopBar({
    super.key,
    required this.infos,
    required this.actions,
    required this.onIndex,
    required this.onGoTo,
    this.wird,
  });

  /// «ورد اليوم · 18 / 20» (it takes no room when there is none).
  final Widget? wird;

  /// Height of the bar's row (elderly mode's is larger).
  static const height = 32.0;
  static const elderlyHeight = 40.0;

  /// The frame details of the pages on screen, right to left (null for a
  /// cover, or while loading).
  final List<FrameInfo?> infos;

  /// The buttons at the far left, in order from the right.
  final List<_FocusAction> actions;

  /// A tap on the surah, the juz or the hizb: the index.
  final VoidCallback onIndex;

  /// A tap on the page number: go to another page.
  final VoidCallback onGoTo;

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
    // The surah, the juz and the hizb open the index; the page number,
    // going to a page.
    Widget tappable(Widget child, VoidCallback onTap, String label) =>
        Semantics(
          button: true,
          label: label,
          onTap: onTap,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: child,
            ),
          ),
        );
    final info = SizedBox(
      height: elderly ? elderlyHeight : height,
      child: DefaultTextStyle.merge(
        style: text,
        // The surah, the page number, the juz and the buttons spread over
        // the whole width with equal room between them; a text too long for
        // its room shrinks rather than overflowing.
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: tappable(
                shrink(
                  Text(
                    surahs.join(' · '),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  AlignmentDirectional.centerStart,
                ),
                onIndex,
                l.indexTitle,
              ),
            ),
            tappable(
              Text(
                [for (final i in known) digits(i.page)].join(' – '),
                semanticsLabel: known.isEmpty
                    ? null
                    : l.pageOf(digits(known.first.page)),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onGoTo,
              l.goToPage,
            ),
            ?switch (where) {
              final w? => Flexible(
                child: tappable(
                  shrink(w, AlignmentDirectional.center),
                  onIndex,
                  l.indexTitle,
                ),
              ),
              null => null,
            },
            if (wird case final w?)
              Flexible(child: shrink(w, AlignmentDirectional.center)),
            if (!elderly)
              for (final (icon, label, onTap) in actions)
                _SmallFocusButton(icon: icon, label: label, onTap: onTap),
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
                      // Each button with its name under it, in one row.
                      Row(
                        children: [
                          for (final (icon, label, onTap) in actions)
                            Expanded(
                              child: InkWell(
                                onTap: onTap,
                                borderRadius: BorderRadius.circular(12),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: elderlyTarget,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(icon, color: t.ink, size: 28),
                                      Text(
                                        label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(color: t.ink),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
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
      shape: Border(top: BorderSide(color: t.border)),
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

/// «القائمة»: focus mode's window with every tool, centred on the screen.
/// The header holds today's top bar and the exit from focus mode; the body
/// the services of the verse pressed (when the press was on one) and the
/// page's tools; the footer the reading strip, the page number and the
/// reading tools.
class _FocusMenu extends StatelessWidget {
  const _FocusMenu({
    required this.header,
    required this.verse,
    required this.pageTools,
    required this.bar,
    required this.tools,
    required this.page,
    required this.onPage,
  });

  final List<_FocusAction> header;

  /// The verse's services; null when the press was off any verse.
  final Widget? verse;
  final List<_FocusAction> pageTools;

  /// The page's reading strip (its quarter and next page's first word).
  final Widget? bar;
  final Widget tools;
  final int page;

  /// The page number was tapped: go to another page.
  final VoidCallback onPage;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    final l = AppLocalizations.of(context);
    final digits = NumberFormatter(Localizations.localeOf(context));
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      key: const ValueKey('focus-menu'),
      backgroundColor: t.paper,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
              child: Row(
                children: [
                  for (final (icon, label, onTap) in header)
                    Expanded(
                      child: InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 56),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, color: t.muted, size: 24),
                              const SizedBox(height: 3),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: t.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (verse != null) ...[
                      verse!,
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                    ],
                    Semantics(
                      header: true,
                      child: Text(
                        l.focusPageTools,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (icon, label, onTap) in pageTools)
                          OutlinedButton.icon(
                            onPressed: onTap,
                            icon: Icon(icon, size: 20),
                            label: Text(label),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ?bar,
                  const SizedBox(height: 6),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Semantics(
                        button: true,
                        label: l.pageOf(digits(page)),
                        excludeSemantics: true,
                        onTap: onPage,
                        child: ActionChip(
                          avatar: const Icon(Icons.menu_book_outlined),
                          label: Text(
                            digits(page),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onPressed: onPage,
                        ),
                      ),
                      tools,
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
