// The verse bar and, on wide screens, the texts beside the page.

part of 'mushaf_screen.dart';

class VerseBar extends StatelessWidget {
  const VerseBar({
    super.key,
    required this.verse,
    required this.surahs,
    required this.onSave,
    required this.onClose,
  });

  final VerseKey verse;
  final List<SurahRow>? surahs;
  final VoidCallback onSave;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final name = surahs == null
        ? ''
        : surahName(context, surahs![verse.surah - 1]);
    return Material(
      color: t.player,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  '${l.surahWord(name)} · ${l.verseSelected('${verse.ayah}')}',
                  style: TextStyle(
                    color: t.playerFg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: l.fasilSaveHere,
              onPressed: onSave,
              icon: Icon(Icons.bookmark_add_outlined, color: t.playerFg),
            ),
            IconButton(
              tooltip: l.cancel,
              onPressed: onClose,
              icon: Icon(Icons.close, color: t.playerFg),
            ),
          ],
        ),
      ),
    );
  }
}

/// Beside the page on a wide screen: the reader's chosen texts (a
/// translation or two, or al-Muyassar) for the verses on the page.
class _SidePane extends ConsumerWidget {
  const _SidePane({required this.page, required this.riwaya});

  final int page;
  final RiwayaData? riwaya;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens.colors;
    final l = AppLocalizations.of(context);
    final ayahs = ref.watch(pageAyahsProvider(page)).value ?? const [];
    final surahs = ref.watch(surahsProvider).value;
    final digits = NumberFormatter(Localizations.localeOf(context));
    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: t.paper,
        border: BorderDirectional(start: BorderSide(color: t.border)),
      ),
      child: SafeArea(
        child: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              for (final a in ayahs)
                Builder(
                  builder: (context) {
                    // Texts are kept by Hafs verse.
                    final h = hafsKeyOf(riwaya, (
                      surah: a.surah,
                      ayah: a.number,
                    ));
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l.verseLabel(
                              surahs == null
                                  ? ''
                                  : surahName(context, surahs[a.surah - 1]),
                              digits(a.number),
                            ),
                            style: TextStyle(
                              color: t.goldText,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          UnderVerseTexts(surah: h.surah, ayah: h.ayah),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
