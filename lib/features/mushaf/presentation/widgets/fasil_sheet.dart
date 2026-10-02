import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../mushaf_providers.dart';
import 'mushaf_page.dart';

/// Colours offered for new fawasil, in order.
const fasilColors = <int>[
  0xFFB23A3A,
  0xFF2E7D5B,
  0xFF2F5E9E,
  0xFFB7860B,
  0xFF7A4A9E,
  0xFF3A7F8C,
];

/// Moves an existing fasil to [verse], or creates a new one there.
Future<void> showSaveToFasil(
  BuildContext context,
  WidgetRef ref, {
  required VerseKey verse,
  required int page,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => Consumer(
      builder: (context, ref, _) {
        final l = AppLocalizations.of(context);
        final t = context.tokens.colors;
        final db = ref.read(userDatabaseProvider);
        final sets = ref.watch(bookmarkSetsProvider).value ?? const [];
        void done() {
          Navigator.of(sheet).pop();
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l.saved)));
        }

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              Semantics(
                header: true,
                child: ListTile(
                  title: Text(
                    l.fasilSaveHere,
                    style: TextStyle(
                      color: t.goldText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              for (final s in sets)
                ListTile(
                  leading: Icon(Icons.bookmark, color: Color(s.color)),
                  title: Text(s.name),
                  onTap: () async {
                    await db.moveBookmarkSet(
                      s.id,
                      surah: verse.surah,
                      ayah: verse.ayah,
                      page: page,
                    );
                    done();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.add),
                title: Text(l.fasilNew),
                onTap: () async {
                  final name = await _askName(context);
                  if (name == null || name.isEmpty) return;
                  await db.addBookmarkSet(
                    name: name,
                    color: fasilColors[sets.length % fasilColors.length],
                    surah: verse.surah,
                    ayah: verse.ayah,
                    page: page,
                  );
                  done();
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<String?> _askName(BuildContext context) {
  final l = AppLocalizations.of(context);
  final field = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(l.fasilNew),
      content: TextField(
        controller: field,
        autofocus: true,
        maxLength: 40,
        decoration: InputDecoration(
          labelText: l.fasilName,
          helperText: l.fasilHint,
        ),
        onSubmitted: (v) => Navigator.of(dialog).pop(v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialog).pop(field.text.trim()),
          child: Text(l.save),
        ),
      ],
    ),
  );
}
