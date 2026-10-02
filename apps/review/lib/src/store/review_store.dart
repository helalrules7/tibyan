import '../model/model.dart';
import '../model/workflow.dart';

/// Where review data lives. The tool talks only to this interface.
///
/// * [SqliteReviewStore]: a review database file (tools/review_schema.sql)
///   opened in the browser and saved back as a file. One person at a time.
/// * [SupabaseReviewStore]: the shared Postgres database planned for
///   several reviewers at once (apps/review/supabase/). Not connected yet.
abstract interface class ReviewStore {
  /// A short description for the header, e.g. the file name.
  String get label;

  Future<List<Source>> sources();
  Future<List<SurahInfo>> surahs();
  Future<Map<ReviewState, int>> counts();
  Future<List<EntrySummary>> entries(EntryFilter filter);

  /// The entry with its links, or null.
  Future<Entry?> entry(int id);
  Future<List<AuditRow>> audit(int entryId);
  Future<List<Verse>> verses(int surah, int from, int to);

  /// People and their roles, as recorded in the store.
  Future<Map<String, List<Role>>> people();

  /// Records [actor] with their role (first use of a name, or a new role).
  Future<void> addPerson(Actor actor);

  /// Applies [action] by [actor] following the workflow rules, writes the
  /// audit row, and returns the updated entry. Throws [WorkflowError].
  Future<Entry> apply(int entryId, ReviewAction action, Actor actor);
}
