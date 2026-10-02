import 'package:flutter/material.dart';

import '../model/model.dart';
import '../platform/file_io.dart';
import '../store/sqlite_review_store.dart';
import 'controller.dart';
import 'review_screen.dart';

/// Who is reviewing, in which role, and which review file.
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final _name = TextEditingController();
  Role _role = Role.editor;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'اكتب اسمك أولا: يُسجَّل مع كل إجراء');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await pickFile();
      if (file == null) return;
      final opened = await openDatabase(file.bytes);
      final store = SqliteReviewStore(opened.database, label: file.name);
      final controller = ReviewController(store, Actor(_name.text.trim(), _role));
      await controller.load();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => ReviewScreen(controller: controller, file: opened, fileName: file.name),
      ));
    } catch (e) {
      setState(() => _error = 'تعذر فتح الملف: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('أداة المراجعة', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'افتح ملف مراجعة (‎*.review.db‎). كل إجراء يُسجَّل باسمك ودورك. '
                  'احفظ الملف بعد العمل وسلّمه لمن يكمل: يعمل عليه شخص واحد في كل مرة.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'الاسم', border: OutlineInputBorder()),
                  onSubmitted: (_) => _open(),
                ),
                const SizedBox(height: 16),
                SegmentedButton<Role>(
                  segments: [
                    for (final r in Role.values) ButtonSegment(value: r, label: Text(r.label)),
                  ],
                  selected: {_role},
                  onSelectionChanged: (s) => setState(() => _role = s.first),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _busy ? null : _open,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('فتح ملف المراجعة'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
