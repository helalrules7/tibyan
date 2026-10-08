// The page's tools and bars: the small tools under the page, the top
// destinations, the bottom controls and scrubber, and the selection, word
// pick and auto-scroll bars.

part of 'mushaf_screen.dart';

/// Touch reading, listening from the top of the page and hiding the
/// verses, just under the page number.
class _ReadingTools extends StatelessWidget {
  const _ReadingTools({
    required this.touchReading,
    required this.recite,
    required this.listening,
    required this.onTouchReading,
    required this.onListen,
    required this.onRecite,
    required this.tajweed,
    required this.onTajweed,
    required this.onTajweedLegend,
    required this.focus,
    required this.onFocus,
    this.labelled = false,
  });

  /// Elderly mode in focus mode: each tool a button with its name.
  final bool labelled;

  /// Tajweed colouring: a tap turns it on or off; a long press shows the
  /// colour key. null: the edition has no tajweed data, so no button.
  final bool? tajweed;
  final VoidCallback onTajweed;
  final VoidCallback onTajweedLegend;

  /// Focus mode is on: the button leaves it, or (off) enters it.
  final bool focus;
  final VoidCallback onFocus;

  final bool touchReading;
  final bool recite;
  final bool listening;
  final VoidCallback onTouchReading;
  final VoidCallback onListen;
  final VoidCallback onRecite;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    if (labelled) {
      Widget named(IconData icon, String label, bool on, VoidCallback onTap) =>
          Semantics(
            toggled: on,
            child: FilledButton.tonalIcon(
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(label),
              // In the interface's font, as the rest of the bar.
              style: FilledButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          );
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          named(
            touchReading ? Icons.touch_app : Icons.touch_app_outlined,
            l.touchReading,
            touchReading,
            onTouchReading,
          ),
          named(
            Icons.headphones_outlined,
            l.listenFromPage,
            listening,
            onListen,
          ),
          named(Icons.visibility_off_outlined, l.reciteMode, recite, onRecite),
          if (tajweed case final on?)
            named(Icons.palette_outlined, l.tajweedColors, on, onTajweed),
          named(
            focus ? Icons.fullscreen_exit : Icons.fullscreen,
            focus ? l.focusExit : l.focusModeTitle,
            focus,
            onFocus,
          ),
        ],
      );
    }
    // [glyph] is an icon, or a letter drawn in its place.
    Widget button(
      Object glyph,
      String label,
      bool on,
      VoidCallback onTap, {
      VoidCallback? onLongPress,
    }) => Semantics(
      button: true,
      toggled: on,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: InkResponse(
          onTap: onTap,
          onLongPress: onLongPress,
          radius: 24,
          // A 48 px target around the small drawn button.
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Container(
              width: 30,
              height: 22,
              decoration: BoxDecoration(
                color: on ? t.control.withValues(alpha: 0.15) : null,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: on ? t.control : t.border,
                  width: 0.8,
                ),
              ),
              alignment: Alignment.center,
              child: switch (glyph) {
                IconData icon => Icon(
                  icon,
                  size: 15,
                  color: on ? t.control : t.muted,
                ),
                _ => Text(
                  '$glyph',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: on ? t.control : t.muted,
                  ),
                ),
              },
            ),
          ),
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(
          Icons.touch_app_outlined,
          l.touchReading,
          touchReading,
          onTouchReading,
        ),
        button(
          Icons.headphones_outlined,
          l.listenFromPage,
          listening,
          onListen,
        ),
        button(Icons.visibility_off_outlined, l.reciteMode, recite, onRecite),
        if (tajweed case final on?) ...[
          const SizedBox(width: 10),
          button(
            'ج',
            l.tajweedColors,
            on,
            onTajweed,
            onLongPress: onTajweedLegend,
          ),
        ],
        button(
          focus ? Icons.fullscreen_exit : Icons.fullscreen,
          focus ? l.focusExit : l.focusModeTitle,
          focus,
          onFocus,
        ),
      ],
    );
  }
}

/// Destinations shown at the top when the reader touches the page.
class _TopControls extends StatelessWidget {
  const _TopControls({required this.items});

  final List<(IconData, String, VoidCallback)> items;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Material(
      color: t.paper,
      elevation: 2,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          child: Row(
            children: [
              for (final (icon, label, onTap) in items)
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
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: t.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page scrubber: drag to any page; a bubble shows the surah and page.
class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.page,
    required this.pageCount,
    required this.label,
    required this.onChanged,
    required this.onChangeEnd,
    required this.onRecite,
    required this.onListen,
    required this.onGoTo,
    required this.onAutoScroll,
    required this.onContinuous,
    required this.onOneVerse,
    required this.touchReading,
    required this.onTouchReading,
    required this.recite,
    required this.listening,
  });

  final bool recite;
  final bool listening;
  final bool touchReading;
  final VoidCallback onTouchReading;
  final int page;
  final int pageCount;
  final String label;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;
  final VoidCallback onRecite;
  final VoidCallback onListen;
  final VoidCallback onGoTo;
  final VoidCallback onAutoScroll;

  /// Opens the continuous view (with the texts under each verse).
  final VoidCallback onContinuous;

  /// Opens «آية آية»: one verse a screen, sideways, in large print.
  final VoidCallback onOneVerse;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    final l = AppLocalizations.of(context);
    return Material(
      color: t.paper,
      elevation: 2,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (context.tokens.elderly)
                // Elderly mode: every tool with its name, large enough to
                // press easily.
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: onOneVerse,
                      icon: const Icon(Icons.screen_rotation_outlined),
                      label: Text(l.oneVerse),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: onListen,
                      icon: const Icon(Icons.headphones_outlined),
                      label: Text(l.listen),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: onGoTo,
                      icon: const Icon(Icons.menu_book_outlined),
                      label: Text(l.goToPage),
                    ),
                    Semantics(
                      toggled: recite,
                      child: FilledButton.tonalIcon(
                        onPressed: onRecite,
                        icon: const Icon(Icons.visibility_outlined),
                        label: Text(l.reciteMode),
                      ),
                    ),
                    Semantics(
                      toggled: touchReading,
                      child: FilledButton.tonalIcon(
                        onPressed: onTouchReading,
                        icon: Icon(
                          touchReading
                              ? Icons.touch_app
                              : Icons.touch_app_outlined,
                        ),
                        label: Text(l.touchReading),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: onAutoScroll,
                      icon: const Icon(Icons.keyboard_double_arrow_down),
                      label: Text(l.autoScroll),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: onContinuous,
                      icon: const Icon(Icons.view_agenda_outlined),
                      label: Text(l.continuousView),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: l.reciteMode,
                      isSelected: recite,
                      onPressed: onRecite,
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: l.listen,
                      isSelected: listening,
                      onPressed: onListen,
                      icon: const Icon(Icons.headphones_outlined),
                    ),
                    const Spacer(),
                    // On a narrow phone the labelled button gives way (it
                    // shrinks) so the five tools beside it stay on screen.
                    Flexible(
                      flex: 8,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: FilledButton.tonalIcon(
                          onPressed: onGoTo,
                          icon: const Icon(Icons.menu_book_outlined, size: 18),
                          label: Text(l.goToPage),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      tooltip: l.oneVerse,
                      onPressed: onOneVerse,
                      icon: const Icon(Icons.screen_rotation_outlined),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: l.continuousView,
                      onPressed: onContinuous,
                      icon: const Icon(Icons.view_agenda_outlined),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: l.autoScroll,
                      onPressed: onAutoScroll,
                      icon: const Icon(Icons.keyboard_double_arrow_down),
                    ),
                  ],
                ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: t.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.border),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'KFGQPCAN',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: t.ink,
                  ),
                ),
              ),
              // Page 1 on the right, like the mushaf.
              SizedBox(
                width: double.infinity,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Slider(
                    activeColor: t.control,
                    inactiveColor: t.border,
                    min: 1,
                    max: pageCount.toDouble(),
                    divisions: pageCount - 1,
                    value: page.clamp(1, pageCount).toDouble(),
                    semanticFormatterCallback: (v) => l.pageOf('${v.round()}'),
                    onChanged: (v) => onChanged(v.round()),
                    onChangeEnd: (v) => onChangeEnd(v.round()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown while the reader drags the selection handles.
class _MultiSelectBar extends StatelessWidget {
  const _MultiSelectBar({required this.count, required this.onDone});

  final int count;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    return Material(
      color: t.paper,
      elevation: 6,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  '${l.multiSelectHint} · ${count == 2 ? l.twoVerses : l.versesCount(digits(count))}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            FilledButton(onPressed: onDone, child: Text(l.doneLabel)),
          ],
        ),
      ),
    );
  }
}

/// Word study: asks for a word to be tapped.
class _WordPickBar extends StatelessWidget {
  const _WordPickBar({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    return Material(
      color: t.paper,
      elevation: 6,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
        child: Row(
          children: [
            Icon(Icons.touch_app_outlined, color: t.goldText),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l.wordPickHint,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            TextButton(onPressed: onCancel, child: Text(l.cancel)),
          ],
        ),
      ),
    );
  }
}

/// Auto-scroll toolbar.
class _AutoScrollBar extends StatelessWidget {
  const _AutoScrollBar({
    required this.paused,
    required this.speed,
    required this.onPause,
    required this.onSlower,
    required this.onFaster,
    required this.onClose,
  });

  final bool paused;
  final int speed;
  final VoidCallback onPause;
  final VoidCallback onSlower;
  final VoidCallback onFaster;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    return Material(
      color: t.paper,
      elevation: 6,
      borderRadius: BorderRadius.circular(32),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            IconButton.filled(
              tooltip: paused ? l.resume : l.pause,
              onPressed: onPause,
              icon: Icon(paused ? Icons.play_arrow : Icons.pause),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l.speedLabel(digits(speed)),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: l.slower,
              onPressed: onSlower,
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 4),
            IconButton.filledTonal(
              tooltip: l.faster,
              onPressed: onFaster,
              icon: const Icon(Icons.add),
            ),
            IconButton(
              tooltip: l.stopAutoScroll,
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
