import '../model/model.dart';
import '../model/workflow.dart';
import 'review_store.dart';

/// The shared backend for several reviewers at once: a Supabase project
/// (Postgres + auth). **Not connected yet**: no project exists, and making
/// one is the owner's decision. Everything it needs is ready:
///
/// * apps/review/supabase/schema.sql: the same tables as
///   tools/review_schema.sql, row-level security, and the workflow as
///   SECURITY DEFINER functions (review_edit, review_submit, review_approve,
///   review_reject) so no client can update an entry or the audit log
///   directly.
/// * apps/review/supabase/README.md: how to create the project, apply the
///   schema, load a drafts database, and give people roles.
///
/// To connect it: add `supabase_flutter` to apps/review/pubspec.yaml, then
/// implement each method below with the call noted beside it, and choose
/// this store on the start screen when a project URL and anon key are
/// given (never commit them).
class SupabaseReviewStore implements ReviewStore {
  SupabaseReviewStore({required this.projectUrl});

  final String projectUrl;

  @override
  String get label => projectUrl;

  Never _todo(String call) =>
      throw UnimplementedError('Supabase is not connected yet ($call)');

  @override
  Future<List<Source>> sources() => _todo("from('source').select()");

  @override
  Future<List<SurahInfo>> surahs() => _todo("from('surah').select()");

  @override
  Future<Map<ReviewState, int>> counts() => _todo("rpc('review_counts')");

  @override
  Future<List<String>> kinds() => _todo("from('entry').select('kind')");

  @override
  Future<List<EntrySummary>> entries(EntryFilter filter) =>
      _todo("from('entry_summary').select() with filters");

  @override
  Future<Entry?> entry(int id) => _todo("from('entry').select('*, entry_link(*)').eq('id', id)");

  @override
  Future<List<AuditRow>> audit(int entryId) => _todo("from('audit').select().eq('entry_id', id)");

  @override
  Future<List<Verse>> verses(int surah, int from, int to) =>
      _todo("from('verse').select().eq('surah', s).gte('ayah', a).lte('ayah', b)");

  @override
  Future<Map<String, List<Role>>> people() => _todo("from('person').select()");

  @override
  Future<void> addPerson(Actor actor) =>
      _todo('roles are granted by an admin in the person table, not by the client');

  @override
  Future<Entry> apply(int entryId, ReviewAction action, Actor actor) =>
      _todo("rpc('review_${action.name}', params) — the role comes from the signed-in user");
}
