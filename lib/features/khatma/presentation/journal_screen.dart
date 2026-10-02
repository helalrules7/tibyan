import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/user_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../mushaf/mushaf_providers.dart';
import '../../mushaf/presentation/mushaf_screen.dart' show surahName;
import '../../mushaf/presentation/navigation.dart';
import '../../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import '../domain/day.dart';
import '../khatma_providers.dart';
import 'khatma_screen.dart' show formatDay;

final _journalProvider = StreamProvider.family<List<ReflectionRow>, String>(
  (ref, query) =>
      ref.watch(activityRepositoryProvider).watchReflections(query: query),
);

final _notesOnVerseProvider =
    StreamProvider.family<List<ReflectionRow>, (int, int)>(
      (ref, v) =>
          ref.watch(activityRepositoryProvider).watchReflectionsOn(v.$1, v.$2),
    );

/// "Surah al-Baqarah · verse 255", in the interface language.
String verseLabel(BuildContext context, WidgetRef ref, int surah, int ayah) {
  final l = AppLocalizations.of(context);
  final surahs = ref.watch(surahsProvider).value;
  final digits = NumberFormatter(Localizations.localeOf(context));
  return l.journalVerseRef(
    surahs == null ? '$surah' : surahName(context, surahs[surah - 1]),
    digits(ayah),
  );
}

/// The reader's notes on verses: newest first, searchable; each opens
/// its verse.
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final notes = ref.watch(_journalProvider(_query)).value;
    return Scaffold(
      appBar: AppBar(title: Text(l.journalTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.journalSearch,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: notes == null
                ? const Center(child: CircularProgressIndicator())
                : notes.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _query.trim().isEmpty ? l.journalEmpty : l.journalNoMatch,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: t.muted, height: 1.7),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notes.length,
                    itemBuilder: (context, i) => _NoteCard(note: notes[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.note});

  final ReflectionRow note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    return Card(
      child: InkWell(
        onTap: () =>
            openVerse(context, ref, surah: note.surah, ayah: note.ayah),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verseLabel(context, ref, note.surah, note.ayah),
                      style: TextStyle(
                        color: t.goldText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(note.body, style: const TextStyle(height: 1.6)),
                    const SizedBox(height: 4),
                    Text(
                      formatDay(context, Day.of(note.createdAt)),
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  final repo = ref.read(activityRepositoryProvider);
                  if (v == 'edit') {
                    final text = await _editText(context, note.body);
                    if (text != null && text.isNotEmpty) {
                      await repo.editReflection(note.uuid, text);
                    }
                  } else if (v == 'delete') {
                    await repo.deleteReflection(note.uuid);
                  } else if (context.mounted) {
                    await openVerse(
                      context,
                      ref,
                      surah: note.surah,
                      ayah: note.ayah,
                    );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'open', child: Text(l.journalOpenVerse)),
                  PopupMenuItem(value: 'edit', child: Text(l.journalEdit)),
                  PopupMenuItem(value: 'delete', child: Text(l.delete)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> _editText(BuildContext context, String initial) {
  final l = AppLocalizations.of(context);
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(l.journalEdit),
      content: TextField(
        controller: c,
        autofocus: true,
        minLines: 3,
        maxLines: 8,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(d).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(d).pop(c.text.trim()),
          child: Text(l.save),
        ),
      ],
    ),
  ).whenComplete(c.dispose);
}

/// Writes a note on a verse, from the verse services; the earlier notes
/// on the verse are listed under it.
Future<void> showReflectionSheet(
  BuildContext context, {
  required int surah,
  required int ayah,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _ReflectionSheet(surah: surah, ayah: ayah),
);

class _ReflectionSheet extends ConsumerStatefulWidget {
  const _ReflectionSheet({required this.surah, required this.ayah});

  final int surah;
  final int ayah;

  @override
  ConsumerState<_ReflectionSheet> createState() => _ReflectionSheetState();
}

class _ReflectionSheetState extends ConsumerState<_ReflectionSheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final earlier =
        ref.watch(_notesOnVerseProvider((widget.surah, widget.ayah))).value ??
        const [];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.journalAdd,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          Text(
            verseLabel(context, ref, widget.surah, widget.ayah),
            style: TextStyle(color: t.muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _text,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: l.journalHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () async {
              final text = _text.text.trim();
              if (text.isEmpty) return;
              await ref
                  .read(activityRepositoryProvider)
                  .addReflection(
                    surah: widget.surah,
                    ayah: widget.ayah,
                    text: text,
                  );
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.maybeOf(context)
                  ?.showSnackBar(SnackBar(content: Text(l.journalSaved)));
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(l.save),
          ),
          if (earlier.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l.journalEarlier,
              style: TextStyle(color: t.goldText, fontWeight: FontWeight.w600),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final n in earlier)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(n.body),
                      subtitle: Text(formatDay(context, Day.of(n.createdAt))),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
