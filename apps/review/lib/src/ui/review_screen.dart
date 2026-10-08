import 'package:flutter/material.dart';

import '../model/model.dart';
import '../model/workflow.dart';
import '../platform/file_io.dart';
import 'controller.dart';
import 'link_dialog.dart';
import 'verse_view.dart';
import 'tajweed_view.dart';

/// The book's text (Uthman Taha Naskh) and the mushaf text (KFGQPC Hafs).
const bookFont = 'UthmanTaha';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.controller, required this.file, required this.fileName});

  final ReviewController controller;
  final OpenedDatabase file;
  final String fileName;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _dirty = false;

  ReviewController get c => widget.controller;

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
    guardUnsaved(true);
  }

  void _save() {
    saveFile(widget.fileName, widget.file.export());
    setState(() => _dirty = false);
    guardUnsaved(false);
  }

  Future<void> _changeActor() async {
    final name = TextEditingController(text: c.actor.name);
    var role = c.actor.role;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('من يعمل الآن'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم')),
            const SizedBox(height: 12),
            SegmentedButton<Role>(
              segments: [for (final r in Role.values) ButtonSegment(value: r, label: Text(r.label))],
              selected: {role},
              onSelectionChanged: (s) => setLocal(() => role = s.first),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تم')),
          ],
        ),
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) c.setActor(Actor(name.text.trim(), role));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final title = c.sources.isEmpty ? widget.fileName : c.sources.map((s) => s.title).join('، ');
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              for (final s in ReviewState.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Chip(label: Text('${s.label}: ${c.counts[s] ?? 0}')),
                ),
              const SizedBox(width: 12),
              ActionChip(
                avatar: const Icon(Icons.person, size: 18),
                label: Text('${c.actor.name} (${c.actor.role.label})'),
                onPressed: _changeActor,
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _save,
                icon: Icon(_dirty ? Icons.save : Icons.save_outlined),
                label: Text(_dirty ? 'حفظ الملف (تغييرات لم تُحفظ)' : 'حفظ الملف'),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: Row(
            children: [
              SizedBox(width: 420, child: _EntryList(controller: c)),
              const VerticalDivider(width: 1),
              Expanded(
                child: c.selected == null
                    ? const Center(child: Text('اختر مدخلا من القائمة'))
                    : _EntryDetail(key: ValueKey(c.selected!.id), controller: c, onChanged: _markDirty),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- list

class _EntryList extends StatefulWidget {
  const _EntryList({required this.controller});
  final ReviewController controller;

  @override
  State<_EntryList> createState() => _EntryListState();
}

class _EntryListState extends State<_EntryList> {
  final _search = TextEditingController();

  ReviewController get c => widget.controller;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _set({
    Object? state = _keep,
    Object? kind = _keep,
    Object? surah = _keep,
    Object? maxConfidence = _keep,
    Object? search = _keep,
  }) {
    final f = c.filter;
    c.setFilter(EntryFilter(
      state: state == _keep ? f.state : state as ReviewState?,
      kind: kind == _keep ? f.kind : kind as String?,
      surah: surah == _keep ? f.surah : surah as int?,
      maxConfidence: maxConfidence == _keep ? f.maxConfidence : maxConfidence as double?,
      search: search == _keep ? f.search : search as String?,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final f = c.filter;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<ReviewState?>(
                value: f.state,
                hint: const Text('كل الحالات'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('كل الحالات')),
                  for (final s in ReviewState.values) DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (v) => _set(state: v),
              ),
              DropdownButton<String?>(
                value: f.kind,
                hint: const Text('كل الأنواع'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('كل الأنواع')),
                  for (final k in c.kinds) DropdownMenuItem(value: k, child: Text(entryKindLabel(k))),
                ],
                onChanged: (v) => _set(kind: v),
              ),
              DropdownButton<int?>(
                value: f.surah,
                hint: const Text('كل السور'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('كل السور')),
                  for (final s in c.surahs) DropdownMenuItem(value: s.id, child: Text('${s.id}. ${s.nameAr}')),
                ],
                onChanged: (v) => _set(surah: v),
              ),
              FilterChip(
                label: const Text('ثقة الربط أقل من 0.9'),
                selected: f.maxConfidence != null,
                onSelected: (on) => _set(maxConfidence: on ? 0.9 : null),
              ),
              SizedBox(
                width: 380,
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.search),
                    hintText: 'بحث في نص الكتاب',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (v) => _set(search: v),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('${c.list.length} مدخلا', style: Theme.of(context).textTheme.labelMedium),
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: c.list.length,
            itemBuilder: (context, i) {
              final e = c.list[i];
              return ListTile(
                dense: true,
                selected: c.selected?.id == e.id,
                onTap: () => c.select(e.id),
                title: Text('#${e.seq} · ${e.section ?? ''}${e.page != null ? ' · ص ${e.page}' : ''}'),
                subtitle: Text(e.preview, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: bookFont)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StateBadge(e.state),
                    Text(
                      e.firstLink == null
                          ? 'بلا ربط'
                          : '${e.firstLink} · ${e.confidence?.toStringAsFixed(2) ?? ''}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

const _keep = Object();

class _StateBadge extends StatelessWidget {
  const _StateBadge(this.state);
  final ReviewState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (state) {
      ReviewState.draft => scheme.outline,
      ReviewState.inReview => scheme.tertiary,
      ReviewState.reviewed => scheme.primary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(border: Border.all(color: color), borderRadius: BorderRadius.circular(8)),
      child: Text(state.label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}

// ---------------------------------------------------------------- detail

class _EntryDetail extends StatefulWidget {
  const _EntryDetail({super.key, required this.controller, required this.onChanged});
  final ReviewController controller;
  final VoidCallback onChanged;

  @override
  State<_EntryDetail> createState() => _EntryDetailState();
}

class _EntryDetailState extends State<_EntryDetail> {
  late List<Link> _links;
  late final TextEditingController _note;
  late final TextEditingController _page;
  late final TextEditingController _pageEnd;

  ReviewController get c => widget.controller;
  Entry get e => c.selected!;

  @override
  void initState() {
    super.initState();
    _links = [...e.links];
    _note = TextEditingController(text: e.note ?? '');
    _page = TextEditingController(text: e.page?.toString() ?? '');
    _pageEnd = TextEditingController(text: e.pageEnd?.toString() ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    _page.dispose();
    _pageEnd.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _links = [...e.links];
      _note.text = e.note ?? '';
      _page.text = e.page?.toString() ?? '';
      _pageEnd.text = e.pageEnd?.toString() ?? '';
    });
  }

  Future<void> _act(ReviewAction a) async {
    if (await c.act(a)) {
      widget.onChanged();
      _reset();
    }
  }

  Future<void> _saveEdit() => _act(EditAction(
        links: _links,
        note: _note.text,
        page: int.tryParse(_page.text),
        pageEnd: int.tryParse(_pageEnd.text),
      ));

  Future<void> _reject() async {
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رد إلى المسودات'),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: note,
            maxLines: 4,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'سبب الرد (مطلوب)', border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('رد')),
        ],
      ),
    );
    if (ok == true) await _act(RejectAction(note.text));
  }

  Future<void> _editLink(int? index) async {
    final link = await showDialog<Link>(
      context: context,
      builder: (_) => LinkDialog(controller: c, initial: index == null ? null : _links[index]),
    );
    if (link == null) return;
    setState(() {
      if (index == null) {
        _links.add(link);
      } else {
        _links[index] = link;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final source = c.sourceOf(e);
    final canEdit = c.actor.role != Role.reviewer;
    final canReview = c.actor.role != Role.editor;
    final linksChanged = _links.length != e.links.length ||
        !_links.every((l) => e.links.any(l.sameTarget));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('#${e.seq} · ${e.kindLabel}', style: theme.textTheme.titleLarge),
          _StateBadge(e.state),
          if (e.section != null) Text(e.section!, style: theme.textTheme.titleMedium),
        ]),
        const SizedBox(height: 8),
        if (source != null)
          Text(
            '${source.title}، ${source.author}. تحقيق: ${source.tahqiq ?? 'غير مذكور'}. '
            '${source.publisher ?? ''}، ${source.edition ?? ''}. '
            '${e.page == null ? 'بلا أرقام صفحات في المصدر' : '${e.volume != null ? 'ج${e.volume} ' : ''}ص ${e.page}'}'
            '${e.pageEnd != null && e.pageEnd != e.page ? '-${e.pageEnd}' : ''}',
            style: theme.textTheme.bodySmall,
          ),
        Text(
          'أنشأه: ${e.createdBy}${e.scriptConfidence != null ? ' (أعلى ثقة ربط ${e.scriptConfidence!.toStringAsFixed(2)})' : ''}'
          ' · المحرر: ${e.editor ?? '—'} · المراجع: ${e.reviewer ?? '—'}',
          style: theme.textTheme.bodySmall,
        ),
        const Divider(height: 32),
        if (e.kind == 'tajweed_verse' && e.links.isNotEmpty) ...[
          Text('الآية ملونة بأحكام البيانات', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          FutureBuilder<List<Verse>>(
            future: c.verses(e.links.first.surah, e.links.first.ayahFrom, e.links.first.ayahFrom),
            builder: (context, snap) => snap.hasData && snap.data!.isNotEmpty
                ? TajweedVerseView(verse: snap.data!.first, marks: TajweedMark.parse(e.text))
                : const LinearProgressIndicator(),
          ),
          const Divider(height: 32),
        ],
        Text(e.kind == 'tajweed_verse' ? 'الأحكام كما في البيانات (لا تُعدَّل)' : 'نص الكتاب (كما هو، لا يُعدَّل)',
            style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(e.text, style: const TextStyle(fontFamily: bookFont, fontSize: 20, height: 1.9)),
        ),
        const Divider(height: 32),
        Row(children: [
          Text('الربط بالآيات', style: theme.textTheme.labelLarge),
          const Spacer(),
          if (canEdit)
            TextButton.icon(
              onPressed: () => _editLink(null),
              icon: const Icon(Icons.add_link),
              label: const Text('ربط جديد'),
            ),
        ]),
        if (_links.isEmpty) const Text('لا ربط. المقطع لا يظهر عند أي آية حتى يُربط.'),
        for (var i = 0; i < _links.length; i++)
          _LinkCard(
            link: _links[i],
            verses: i < c.linkVerses.length && e.links.length > i && _links[i].sameTarget(e.links[i])
                ? c.linkVerses[i]
                : null,
            controller: c,
            surahName: c.surah(_links[i].surah)?.nameAr ?? '',
            onEdit: canEdit ? () => _editLink(i) : null,
            onRemove: canEdit ? () => setState(() => _links.removeAt(i)) : null,
          ),
        const Divider(height: 32),
        Row(children: [
          SizedBox(
            width: 120,
            child: TextField(
              controller: _page,
              enabled: canEdit,
              decoration: const InputDecoration(labelText: 'من صفحة', isDense: true),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: TextField(
              controller: _pageEnd,
              enabled: canEdit,
              decoration: const InputDecoration(labelText: 'إلى صفحة', isDense: true),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          enabled: canEdit,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'ملاحظة (خطأ في التقسيم، فرق عن المطبوع، سبب تغيير الربط...)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 12, runSpacing: 12, children: [
          if (canEdit)
            OutlinedButton.icon(
              onPressed: c.busy ? null : _saveEdit,
              icon: const Icon(Icons.edit),
              label: Text(linksChanged ? 'حفظ التعديل (الربط تغير)' : 'حفظ التعديل'),
            ),
          if (canEdit && e.state == ReviewState.draft)
            FilledButton.icon(
              onPressed: c.busy ? null : () => _act(const SubmitAction()),
              icon: const Icon(Icons.send),
              label: const Text('إرسال للمراجعة'),
            ),
          if (canReview && e.state == ReviewState.inReview)
            FilledButton.icon(
              onPressed: c.busy ? null : () => _act(const ApproveAction()),
              icon: const Icon(Icons.verified),
              label: const Text('اعتماد'),
            ),
          if (canReview && e.state != ReviewState.draft)
            OutlinedButton.icon(
              onPressed: c.busy ? null : _reject,
              icon: const Icon(Icons.undo),
              label: const Text('رد مع ملاحظة'),
            ),
          TextButton.icon(
            onPressed: c.next,
            icon: const Icon(Icons.skip_previous),
            label: const Text('التالي'),
          ),
        ]),
        if (c.message != null) ...[
          const SizedBox(height: 12),
          Text(c.message!, style: TextStyle(color: theme.colorScheme.tertiary)),
        ],
        const Divider(height: 32),
        Text('سجل الإجراءات (لا يُحذف)', style: theme.textTheme.labelLarge),
        for (final a in c.auditRows)
          ListTile(
            dense: true,
            leading: Text(a.at.replaceFirst('T', ' ').replaceFirst('Z', '')),
            title: Text('${a.actor} (${a.role}): ${a.action}'
                '${a.fromState != null ? ' · ${a.fromState} ← ${a.toState}' : ' · ${a.toState ?? ''}'}'),
            subtitle: a.note == null && a.detail == null
                ? null
                : Text([a.note, a.detail].whereType<String>().join('\n'), maxLines: 4,
                    overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.link,
    required this.verses,
    required this.controller,
    required this.surahName,
    this.onEdit,
    this.onRemove,
  });

  final Link link;
  final List<Verse>? verses;
  final ReviewController controller;
  final String surahName;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text('سورة $surahName · ${link.label}', style: theme.textTheme.titleSmall),
            const SizedBox(width: 12),
            Text('الأساس: ${_basis(link.basis)} · الثقة ${link.confidence.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall),
            const Spacer(),
            if (onEdit != null) IconButton(onPressed: onEdit, icon: const Icon(Icons.edit), tooltip: 'تعديل'),
            if (onRemove != null)
              IconButton(onPressed: onRemove, icon: const Icon(Icons.link_off), tooltip: 'حذف الربط'),
          ]),
          if (link.quote != null)
            Text('اقتباس الكتاب: {${link.quote}}', style: const TextStyle(fontFamily: bookFont, fontSize: 17)),
          const SizedBox(height: 8),
          if (verses != null)
            VerseView(verses: verses!, link: link)
          else
            FutureBuilder<List<Verse>>(
              future: controller.verses(link.surah, link.ayahFrom, link.ayahTo),
              builder: (context, snap) =>
                  snap.hasData ? VerseView(verses: snap.data!, link: link) : const LinearProgressIndicator(),
            ),
        ]),
      ),
    );
  }

  static String _basis(String b) => switch (b) {
        'marker' => 'رقم الآية في الطبعة',
        'quote' => 'نص الاقتباس',
        'marker+quote' => 'الرقم والاقتباس متفقان',
        'manual' => 'يدوي',
        _ => b,
      };
}
