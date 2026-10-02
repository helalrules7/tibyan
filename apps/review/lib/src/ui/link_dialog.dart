import 'package:flutter/material.dart';

import '../model/model.dart';
import 'controller.dart';
import 'verse_view.dart';

/// Picks a verse range and, optionally, words of its first verse (tap the
/// first and last word).
class LinkDialog extends StatefulWidget {
  const LinkDialog({super.key, required this.controller, this.initial});

  final ReviewController controller;
  final Link? initial;

  @override
  State<LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<LinkDialog> {
  late int _surah = widget.initial?.surah ?? 1;
  late final _from = TextEditingController(text: '${widget.initial?.ayahFrom ?? 1}');
  late final _to = TextEditingController(text: '${widget.initial?.ayahTo ?? 1}');
  late int? _wordFrom = widget.initial?.wordFrom;
  late int? _wordTo = widget.initial?.wordTo;
  List<Verse> _verses = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  int get _count => widget.controller.surah(_surah)?.ayahCount ?? 286;

  Future<void> _load() async {
    final a = int.tryParse(_from.text) ?? 1;
    final b = int.tryParse(_to.text) ?? a;
    if (a < 1 || b < a || b > _count) {
      setState(() => _error = 'الآيات بين 1 و$_count، والنهاية بعد البداية');
      return;
    }
    final v = await widget.controller.verses(_surah, a, b);
    if (!mounted) return;
    setState(() {
      _verses = v;
      _error = null;
    });
  }

  void _tapWord(int n) {
    setState(() {
      if (_wordFrom == null || _wordTo != null) {
        _wordFrom = n;
        _wordTo = null;
      } else if (n < _wordFrom!) {
        _wordTo = _wordFrom;
        _wordFrom = n;
      } else {
        _wordTo = n;
      }
    });
  }

  Link? _result() {
    final a = int.tryParse(_from.text);
    final b = int.tryParse(_to.text);
    if (a == null || b == null || a < 1 || b < a || b > _count) return null;
    final init = widget.initial;
    final link = Link(
      surah: _surah,
      ayahFrom: a,
      ayahTo: b,
      wordFrom: _wordFrom,
      wordTo: _wordFrom == null ? null : (_wordTo ?? _wordFrom),
      quote: init?.quote,
      basis: init?.basis ?? 'manual',
      confidence: init?.confidence ?? 1,
      createdBy: init?.createdBy ?? '',
    );
    return link;
  }

  @override
  Widget build(BuildContext context) {
    final first = _verses.isEmpty ? null : _verses.first;
    final preview = _result();
    return AlertDialog(
      title: const Text('الربط بالآيات'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              DropdownButton<int>(
                value: _surah,
                items: [
                  for (final s in widget.controller.surahs)
                    DropdownMenuItem(value: s.id, child: Text('${s.id}. ${s.nameAr}')),
                ],
                onChanged: (v) {
                  setState(() {
                    _surah = v ?? 1;
                    _from.text = '1';
                    _to.text = '1';
                    _wordFrom = _wordTo = null;
                  });
                  _load();
                },
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _from,
                  decoration: const InputDecoration(labelText: 'من آية'),
                  onSubmitted: (_) {
                    _wordFrom = _wordTo = null;
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _to,
                  decoration: const InputDecoration(labelText: 'إلى آية'),
                  onSubmitted: (_) => _load(),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(onPressed: _load, child: const Text('اعرض')),
            ]),
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 12),
            if (first != null) ...[
              Text('كلمات الآية ${first.ayah} (اختياري: اضغط أول كلمة ثم آخرها)',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Wrap(spacing: 4, runSpacing: 4, children: [
                  for (var i = 0; i < first.words.length; i++)
                    ChoiceChip(
                      label: Text(first.words[i], style: const TextStyle(fontFamily: mushafFont, fontSize: 20)),
                      selected: _wordFrom != null && i + 1 >= _wordFrom! && i + 1 <= (_wordTo ?? _wordFrom!),
                      onSelected: (_) => _tapWord(i + 1),
                    ),
                ]),
              ),
              TextButton(
                onPressed: () => setState(() => _wordFrom = _wordTo = null),
                child: const Text('الآية كلها (بلا كلمات)'),
              ),
              const Divider(),
              if (preview != null) VerseView(verses: _verses, link: preview),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(
          onPressed: preview == null ? null : () => Navigator.pop(context, preview),
          child: const Text('تم'),
        ),
      ],
    );
  }
}
