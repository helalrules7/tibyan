import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan_review/src/model/model.dart';
import 'package:tibyan_review/src/model/workflow.dart';

Entry entry(ReviewState state, {String? editor, String? reviewer, String? note}) => Entry(
      id: 1,
      sourceId: 1,
      seq: 1,
      kind: 'passage',
      text: 'نص',
      createdBy: 'script:test',
      createdAt: '2026-10-02T00:00:00Z',
      state: state,
      editor: editor,
      reviewer: reviewer,
      note: note,
      contentHash: 'h',
      updatedAt: '2026-10-02T00:00:00Z',
      links: const [Link(surah: 2, ayahFrom: 1, ayahTo: 2)],
    );

const ali = Actor('علي', Role.editor);
const omar = Actor('عمر', Role.reviewer);
const aliReviewing = Actor('علي', Role.reviewer);
const admin = Actor('زيد', Role.admin);

Matcher refused() => throwsA(isA<WorkflowError>());

void main() {
  group('submit', () {
    test('an editor sends a draft to review and becomes its editor', () {
      final o = decide(entry(ReviewState.draft), const SubmitAction(), ali);
      expect(o.to, ReviewState.inReview);
      expect(o.setEditor, isTrue);
    });
    test('a reviewer cannot submit', () {
      expect(() => decide(entry(ReviewState.draft), const SubmitAction(), omar), refused());
    });
    test('only drafts are submitted', () {
      expect(() => decide(entry(ReviewState.inReview, editor: 'علي'), const SubmitAction(), ali), refused());
    });
  });

  group('approve', () {
    test('another reviewer approves', () {
      final o = decide(entry(ReviewState.inReview, editor: 'علي'), const ApproveAction(), omar);
      expect(o.to, ReviewState.reviewed);
      expect(o.setReviewer, isTrue);
    });
    test('the editor cannot approve their own work, even as reviewer or admin', () {
      final e = entry(ReviewState.inReview, editor: 'علي');
      expect(() => decide(e, const ApproveAction(), aliReviewing), refused());
      expect(() => decide(entry(ReviewState.inReview, editor: 'زيد'), const ApproveAction(), admin), refused());
    });
    test('an editor role cannot approve', () {
      expect(() => decide(entry(ReviewState.inReview, editor: 'عمر'), const ApproveAction(), ali), refused());
    });
    test('drafts are not approved', () {
      expect(() => decide(entry(ReviewState.draft, editor: 'علي'), const ApproveAction(), omar), refused());
    });
  });

  group('reject', () {
    test('returns to draft with the written note', () {
      final o = decide(entry(ReviewState.inReview, editor: 'علي'), const RejectAction('  الربط خطأ  '), omar);
      expect(o.to, ReviewState.draft);
      expect(o.note, 'الربط خطأ');
      expect(o.clearReview, isTrue);
    });
    test('needs a note', () {
      expect(() => decide(entry(ReviewState.inReview, editor: 'علي'), const RejectAction(' '), omar), refused());
    });
    test('a reviewed entry can be rejected too', () {
      final e = entry(ReviewState.reviewed, editor: 'علي', reviewer: 'عمر');
      expect(decide(e, const RejectAction('سبب'), admin).to, ReviewState.draft);
    });
  });

  group('edit', () {
    const newLinks = [Link(surah: 2, ayahFrom: 3, ayahTo: 3)];
    test('editing a reviewed entry sends it back to review and clears the review', () {
      final e = entry(ReviewState.reviewed, editor: 'عمر', reviewer: 'زيد');
      final o = decide(e, const EditAction(links: newLinks), ali);
      expect(o.to, ReviewState.inReview);
      expect(o.clearReview, isTrue);
      expect(o.setEditor, isTrue);
    });
    test('editing a draft keeps it a draft', () {
      expect(decide(entry(ReviewState.draft), const EditAction(note: 'ملاحظة'), ali).to, ReviewState.draft);
    });
    test('a reviewer cannot edit', () {
      expect(() => decide(entry(ReviewState.draft), const EditAction(links: newLinks), omar), refused());
    });
    test('an edit that changes nothing is refused', () {
      final e = entry(ReviewState.draft);
      expect(() => decide(e, EditAction(links: [...e.links]), ali), refused());
    });
    test('ranges must run forward', () {
      expect(
        () => decide(entry(ReviewState.draft),
            const EditAction(links: [Link(surah: 2, ayahFrom: 5, ayahTo: 4)]), ali),
        refused(),
      );
    });
  });

  test('a name is required for every action', () {
    expect(() => decide(entry(ReviewState.draft), const SubmitAction(), const Actor(' ', Role.admin)), refused());
  });
}
