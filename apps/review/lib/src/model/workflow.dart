import 'model.dart';

/// The review method, as rules on (entry, action, actor):
///
///   draft --submit--> in_review --approve--> reviewed
///     ^                  |  (reviewer ≠ editor)   |
///     +-----reject-------+  (written note)        |
///     ^                                           |
///     +-------------- reject ---------------------+
///   any edit of a reviewed entry sends it back to in_review.
///
/// Editors (and admins) edit and submit. Reviewers (and admins) approve and
/// reject, never on an entry they edited. The text itself is never edited:
/// edits change links, pages and the note.
sealed class ReviewAction {
  const ReviewAction();
  String get name;
}

class EditAction extends ReviewAction {
  const EditAction({this.links, this.note, this.page, this.pageEnd});

  /// New full list of links, or null to keep them.
  final List<Link>? links;
  final String? note;
  final int? page;
  final int? pageEnd;

  @override
  String get name => 'edit';
}

class SubmitAction extends ReviewAction {
  const SubmitAction();
  @override
  String get name => 'submit';
}

class ApproveAction extends ReviewAction {
  const ApproveAction();
  @override
  String get name => 'approve';
}

class RejectAction extends ReviewAction {
  const RejectAction(this.note);
  final String note;
  @override
  String get name => 'reject';
}

class WorkflowError implements Exception {
  const WorkflowError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// What an allowed action does to the entry.
class Outcome {
  const Outcome({
    required this.to,
    this.setEditor = false,
    this.setReviewer = false,
    this.clearReview = false,
    this.note,
  });

  final ReviewState to;

  /// The actor becomes the entry's editor.
  final bool setEditor;

  /// The actor becomes the entry's reviewer.
  final bool setReviewer;

  /// Reviewer and review date are cleared.
  final bool clearReview;

  /// Replaces the entry's note when not null.
  final String? note;
}

bool _canEdit(Role r) => r == Role.editor || r == Role.admin;
bool _canReview(Role r) => r == Role.reviewer || r == Role.admin;

/// Returns what [action] by [actor] does to [entry], or throws
/// [WorkflowError] with the reason it is not allowed.
Outcome decide(Entry entry, ReviewAction action, Actor actor) {
  if (actor.name.trim().isEmpty) {
    throw const WorkflowError('اكتب اسمك قبل أي إجراء');
  }
  switch (action) {
    case EditAction():
      if (!_canEdit(actor.role)) {
        throw const WorkflowError('التعديل للمحرر أو المشرف');
      }
      final changed = (action.links != null && !_sameLinks(action.links!, entry.links)) ||
          (action.note != null && action.note != (entry.note ?? '')) ||
          (action.page != null && action.page != entry.page) ||
          (action.pageEnd != null && action.pageEnd != entry.pageEnd);
      if (!changed) throw const WorkflowError('لا تغيير');
      for (final l in action.links ?? const <Link>[]) {
        if (l.ayahTo < l.ayahFrom) throw const WorkflowError('نهاية الآيات قبل بدايتها');
        if (l.wordFrom != null && l.wordTo != null && l.wordTo! < l.wordFrom!) {
          throw const WorkflowError('نهاية الكلمات قبل بدايتها');
        }
      }
      return Outcome(
        to: entry.state == ReviewState.reviewed ? ReviewState.inReview : entry.state,
        setEditor: true,
        clearReview: entry.state == ReviewState.reviewed,
        note: action.note,
      );
    case SubmitAction():
      if (!_canEdit(actor.role)) {
        throw const WorkflowError('الإرسال للمراجعة للمحرر أو المشرف');
      }
      if (entry.state != ReviewState.draft) {
        throw const WorkflowError('يرسل للمراجعة ما كان مسودة فقط');
      }
      return const Outcome(to: ReviewState.inReview, setEditor: true);
    case ApproveAction():
      if (!_canReview(actor.role)) throw const WorkflowError('الاعتماد للمراجع أو المشرف');
      if (entry.state != ReviewState.inReview) {
        throw const WorkflowError('يعتمد ما كان قيد المراجعة فقط');
      }
      if (entry.editor == null) throw const WorkflowError('لا محرر مسجل لهذا المدخل');
      if (entry.editor == actor.name) {
        throw const WorkflowError('لا يراجع المحرر عمله: يعتمده شخص آخر');
      }
      return const Outcome(to: ReviewState.reviewed, setReviewer: true);
    case RejectAction():
      if (!_canReview(actor.role)) throw const WorkflowError('الرد للمراجع أو المشرف');
      if (entry.state == ReviewState.draft) throw const WorkflowError('المدخل مسودة أصلا');
      if (action.note.trim().isEmpty) throw const WorkflowError('الرد يحتاج ملاحظة مكتوبة');
      if (entry.editor == actor.name) {
        throw const WorkflowError('لا يراجع المحرر عمله: يرده شخص آخر');
      }
      return Outcome(to: ReviewState.draft, clearReview: true, note: action.note.trim());
  }
}

bool _sameLinks(List<Link> a, List<Link> b) {
  if (a.length != b.length) return false;
  final rest = [...b];
  for (final l in a) {
    final i = rest.indexWhere(l.sameTarget);
    if (i < 0) return false;
    rest.removeAt(i);
  }
  return true;
}
