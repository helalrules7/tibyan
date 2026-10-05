import 'package:flutter/foundation.dart';

import '../model/model.dart';
import '../model/workflow.dart';
import '../store/review_store.dart';

/// State of one review session: the store, who is acting, the list, and the
/// selected entry with its verses and audit log.
class ReviewController extends ChangeNotifier {
  ReviewController(this.store, this.actor);

  final ReviewStore store;
  Actor actor;

  List<Source> sources = const [];
  List<SurahInfo> surahs = const [];
  List<String> kinds = const [];
  Map<ReviewState, int> counts = const {};
  EntryFilter filter = const EntryFilter();
  List<EntrySummary> list = const [];
  Entry? selected;
  List<AuditRow> auditRows = const [];

  /// Verses of each link of the selected entry, in link order.
  List<List<Verse>> linkVerses = const [];
  String? message;
  bool busy = false;

  Source? sourceOf(Entry e) => sources.where((s) => s.id == e.sourceId).firstOrNull;
  SurahInfo? surah(int id) => surahs.where((s) => s.id == id).firstOrNull;

  Future<void> load() async {
    sources = await store.sources();
    surahs = await store.surahs();
    kinds = await store.kinds();
    await refresh();
  }

  Future<void> refresh() async {
    counts = await store.counts();
    list = await store.entries(filter);
    notifyListeners();
  }

  Future<void> setFilter(EntryFilter f) async {
    filter = f;
    await refresh();
  }

  Future<void> select(int id) async {
    selected = await store.entry(id);
    await _loadDetail();
    message = null;
    notifyListeners();
  }

  Future<void> _loadDetail() async {
    final e = selected;
    if (e == null) return;
    auditRows = await store.audit(e.id);
    linkVerses = [for (final l in e.links) await store.verses(l.surah, l.ayahFrom, l.ayahTo)];
  }

  Future<List<Verse>> verses(int surah, int from, int to) => store.verses(surah, from, to);

  Future<bool> act(ReviewAction action) async {
    final e = selected;
    if (e == null) return false;
    busy = true;
    notifyListeners();
    try {
      await store.addPerson(actor);
      selected = await store.apply(e.id, action, actor);
      await _loadDetail();
      message = _done(action);
      await refresh();
      return true;
    } on WorkflowError catch (err) {
      message = err.message;
      notifyListeners();
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void setActor(Actor a) {
    actor = a;
    message = null;
    notifyListeners();
  }

  /// Moves to the next entry in the current list.
  Future<void> next() async {
    final e = selected;
    if (e == null || list.isEmpty) return;
    final i = list.indexWhere((s) => s.id == e.id);
    if (i >= 0 && i + 1 < list.length) await select(list[i + 1].id);
  }

  static String _done(ReviewAction a) => switch (a) {
        EditAction() => 'حُفظ التعديل',
        SubmitAction() => 'أُرسل للمراجعة',
        ApproveAction() => 'اعتُمد',
        RejectAction() => 'رُدّ إلى المسودات مع الملاحظة',
      };
}
