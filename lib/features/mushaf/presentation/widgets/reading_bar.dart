import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import 'catchword_view.dart';
import 'illuminated_frame.dart';

/// The strip under the pages: the hizb quarter that starts on the page at
/// the start side (right in Arabic), the reading tools in the middle, and
/// the next page's first word at the end side.
///
/// There is one for the screen, outside the pager: it stays put while the
/// pages turn under it, and the screen gives it the page the pager has
/// settled on. A two-page spread has one strip, for both pages.
class ReadingBar extends StatelessWidget {
  const ReadingBar({
    super.key,
    required this.page,
    this.quarter,
    this.catchword,
    this.cutCatchword = false,
    this.tools,
  });

  /// The strip of [infos], the frame details of the pages on screen (right
  /// to left; null while loading): the latest quarter starting on them,
  /// and the catchword of the last one unless [showCatchword] is off
  /// (recitation mode and hifz tests, where it would give a word away).
  /// A cover has no details, only its [coverCatchword].
  factory ReadingBar.of(
    List<FrameInfo?> infos, {
    Key? key,
    required int page,
    bool showCatchword = true,
    String? coverCatchword,
    Widget? tools,
  }) {
    final quarter = [
      for (final i in infos)
        if (i != null && i.quarters.isNotEmpty) i.quarters.last.quarter,
    ].lastOrNull;
    final last = infos.lastOrNull;
    final word = showCatchword && (last?.hasCatchword ?? false);
    return ReadingBar(
      key: key,
      page: last?.page ?? page,
      quarter: quarter,
      catchword: !showCatchword
          ? null
          : word
          ? last!.catchword
          : coverCatchword,
      cutCatchword: word,
      tools: tools,
    );
  }

  /// Height of the strip.
  static const height = 26.0;

  /// The page the strip stands under (in a spread, the left one).
  final int page;

  /// The hizb quarter (1..240) starting on the page, named at the start.
  final int? quarter;

  /// The next page's first word.
  final String? catchword;

  /// The catchword is the page's own ([CatchwordView]: cut from the next
  /// page's image in the Shamarly edition), not a cover's plain text.
  final bool cutCatchword;

  /// The small reading tools, centred; none in elderly mode, where they
  /// are labelled buttons in the bottom controls.
  final Widget? tools;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    final l = AppLocalizations.of(context);
    final digits = NumberFormatter(Localizations.localeOf(context));
    final style = TextStyle(
      fontFamily: 'UthmanicHafs',
      fontSize: 15,
      height: 1.4,
      color: t.muted,
    );
    final word = catchword;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          if (tools != null) Center(child: tools),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                if (quarter != null)
                  QuarterLabel(
                    text: quarterName(l, digits, quarter!),
                    color: t.muted,
                  ),
                const Spacer(),
                if (cutCatchword)
                  CatchwordView(page: page, text: word, style: style)
                else if (word != null)
                  Text(
                    word,
                    semanticsLabel: l.catchwordLabel(word),
                    style: style,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
