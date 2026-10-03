# Supabase backend for the review tool (ready, not connected)

The plan wanted a separate Supabase project for review data. None exists yet, and creating accounts is the owner's decision. Until then the tool works on a review database file (one person at a time). This folder is everything needed to move to Supabase later, when several reviewers work at once.

## What is here

- `schema.sql`: the tables of `tools/review_schema.sql` in Postgres, row-level security, and the workflow as `SECURITY DEFINER` functions. Clients can read but cannot write any table directly; every change goes through `review_edit`, `review_submit`, `review_approve` or `review_reject`, which check the role and the "reviewer is not the editor" rule and write the audit row in the same transaction. The audit log and entry text are protected by triggers even from the service role.
- `../lib/src/store/supabase_review_store.dart`: the store class with each method mapped to its query or function call. It throws until connected.

## Steps when the owner decides to use it

1. Create a Supabase project (free tier is enough). Keep the URL, anon key and service key out of the repo.
2. Apply `schema.sql` in the SQL editor.
3. Load a drafts database: copy the rows of `source`, `entry`, `entry_link`, `audit`, `surah` and `verse` from `data/review/<book>.review.db` with the service key (a small loader script is still to be written: `tools/load_review_supabase.py`).
4. Turn on email sign-in. For each person, an admin adds a `person` row with their `auth.users` id and roles.
5. Add `supabase_flutter` to `apps/review/pubspec.yaml`, implement `SupabaseReviewStore`, and offer it on the start screen.
6. `tools/export_pack.py` then reads from a database dump (or gets a Postgres reader); its checks stay the same.
