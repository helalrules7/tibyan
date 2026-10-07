import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import '../domain/khatmah.dart' show EntryPoint;
import '../domain/khatmah_engine.dart' show PendingCredit;
import '../khatma_providers.dart';

/// Today's portion of [s] in the pages of the edition being read: how many
/// of its pages are read (plan 5: «ورد اليوم · 18 / 20»). Null on a rest
/// day, while paused, or once the khatma is complete.
({int read, int total})? wirdPagesOf(KhatmaStatus s) {
  final w = s.wird;
  if (w == null || s.complete || !s.khatmah.isActive) return null;
  final pages = {
    for (final r in w.ranges.ranges) ...s.pages.pagesOf(r.from, r.to),
  };
  if (pages.isEmpty) return null;
  return (read: pages.intersection(s.read).length, total: pages.length);
}

/// The primary khatma's portion for the reader's indicator, when the
/// indicator is on (settings: «إظهار مؤشر الورد»).
final readerWirdProvider =
    Provider<({KhatmaStatus status, int read, int total})?>((ref) {
      if (!ref.watch(settingsProvider.select((s) => s.showWirdIndicator))) {
        return null;
      }
      final s = ref.watch(khatmaStatusProvider).value;
      if (s == null) return null;
      final pages = wirdPagesOf(s);
      if (pages == null) return null;
      return (status: s, read: pages.read, total: pages.total);
    });

/// «متابعة ختمتي»: the first unread verse of [uuid], in the edition open.
Future<void> continueKhatmah(
  BuildContext context,
  WidgetRef ref,
  String uuid,
) async {
  final route = await ref
      .read(khatmaServiceProvider)
      .routeFor(
        Uri(scheme: 'tibyan', host: 'khatmah', path: '/$uuid/continue'),
        entry: EntryPoint.khatmahContinue,
      );
  if (context.mounted) context.go(route);
}

/// The reader's «ورد اليوم · 18 / 20»: a tap continues the khatma from its
/// first unread verse. Nothing when there is no portion today.
class WirdIndicator extends ConsumerWidget {
  const WirdIndicator({super.key, this.dense = false});

  /// Focus mode's thin bar: text only, in the bar's own style.
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wird = ref.watch(readerWirdProvider);
    if (wird == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final done = wird.read >= wird.total;
    final label = l.wirdIndicator(digits(wird.read), digits(wird.total));
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: dense
          ? null
          : TextStyle(
              color: t.ink,
              fontWeight: FontWeight.w600,
              fontSize: context.tokens.elderly ? 17 : 14,
            ),
    );
    void open() =>
        unawaited(continueKhatmah(context, ref, wird.status.khatmah.uuid));
    return Semantics(
      button: true,
      label: '$label. ${l.khatmaContinueMine}',
      excludeSemantics: true,
      onTap: open,
      child: dense
          ? InkWell(
              onTap: open,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: text,
              ),
            )
          : Material(
              color: t.paper,
              shape: StadiumBorder(side: BorderSide(color: t.border)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: open,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: context.tokens.elderly ? 56 : 40,
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 16, 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          done
                              ? Icons.check_circle_outline
                              : Icons.auto_stories_outlined,
                          size: 18,
                          color: done ? t.control : t.goldText,
                        ),
                        const SizedBox(width: 8),
                        Flexible(child: text),
                        const SizedBox(width: 10),
                        Text(
                          l.khatmaContinueMine,
                          style: TextStyle(
                            color: t.control,
                            fontWeight: FontWeight.w600,
                            fontSize: context.tokens.elderly ? 17 : 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// The pending decision the reader's «ask» line shows: the latest reading
/// of a session that has ended ([current] is the one still going), for a
/// khatma in `ask` mode.
PendingCredit? latestEndedPending(
  Iterable<PendingCredit> pending,
  String? current, {
  Set<(String, String)> dismissed = const {},
}) {
  PendingCredit? latest;
  for (final p in pending) {
    if (p.sessionUuid == current) continue;
    if (dismissed.contains((p.sessionUuid, p.khatmaUuid))) continue;
    if (latest == null || p.at.isAfter(latest.at)) latest = p;
  }
  return latest;
}

/// «ask» (plan 4.3): a calm line at the foot of the reader once a session
/// has ended with reading that a khatma in `ask` mode could take. It goes
/// by itself after [timeout]; unanswered, nothing is counted and the
/// reading stays in the khatma's details.
class AskCreditLine extends ConsumerStatefulWidget {
  const AskCreditLine({
    super.key,
    required this.currentSession,
    required this.allowed,
    this.timeout = const Duration(seconds: 15),
  });

  /// The reader's session still going: its reading is asked about once it
  /// ends.
  final String? Function() currentSession;

  /// False while something else holds the foot of the screen (the menus,
  /// the player, the sajdah card, a hifz test).
  final bool allowed;
  final Duration timeout;

  @override
  ConsumerState<AskCreditLine> createState() => _AskCreditLineState();
}

class _AskCreditLineState extends ConsumerState<AskCreditLine> {
  final _dismissed = <(String, String)>{};
  (String, String)? _shown;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _dismiss(PendingCredit p) {
    _timer?.cancel();
    setState(() => _dismissed.add((p.sessionUuid, p.khatmaUuid)));
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingCreditsProvider).value ?? const [];
    final p = widget.allowed
        ? latestEndedPending(
            pending,
            widget.currentSession(),
            dismissed: _dismissed,
          )
        : null;
    final plans = ref.watch(khatmaStatusesProvider).value ?? const [];
    final title = p == null
        ? null
        : plans
              .where((s) => s.khatmah.uuid == p.khatmaUuid)
              .firstOrNull
              ?.row
              .title;
    if (p == null || title == null) return const SizedBox.shrink();
    final key = (p.sessionUuid, p.khatmaUuid);
    if (_shown != key) {
      _shown = key;
      _timer?.cancel();
      _timer = Timer(widget.timeout, () {
        if (mounted) _dismiss(p);
      });
    }
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final service = ref.read(khatmaServiceProvider);
    return SafeArea(
      top: false,
      child: Material(
        color: t.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: t.border),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l.askCreditLine(title),
                  style: TextStyle(color: t.ink, height: 1.4),
                ),
              ),
              TextButton(
                onPressed: () {
                  _dismiss(p);
                  unawaited(service.declinePending(p));
                },
                child: Text(l.askCreditNo),
              ),
              FilledButton(
                onPressed: () {
                  _dismiss(p);
                  unawaited(service.acceptPending(p));
                },
                child: Text(l.askCreditCount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
