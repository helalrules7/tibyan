-- Review database on Supabase (Postgres), schema version 1.
-- Same tables as tools/review_schema.sql (SQLite); keep the two in step.
-- NOT APPLIED ANYWHERE YET. See README.md beside this file.
--
-- Security model:
--   * Every signed-in person has a row in `person` with their roles,
--     granted by an admin. No row, no access.
--   * Clients can read. They cannot INSERT/UPDATE/DELETE entries, links or
--     the audit log directly: there are no write policies. Every change goes
--     through the review_* functions below (SECURITY DEFINER), which apply
--     the workflow rules and write the audit row in the same transaction.
--   * Drafts are loaded with the service key (tools/import_*.py output),
--     never from the browser.

create table meta (key text primary key, value text not null);

create table person (
  user_id  uuid primary key references auth.users (id),
  name     text not null unique,
  roles    text[] not null check (roles <@ array['editor', 'reviewer', 'admin']),
  added_at timestamptz not null default now()
);

create table source (
  id           bigint primary key,
  key          text not null unique,
  kind         text not null,
  title        text not null,
  author       text not null,
  edition      text,
  publisher    text,
  tahqiq       text,
  licence      text not null,
  digitised_by text,
  url          text not null,
  file         text not null,
  sha256       text not null,
  retrieved_at text not null,
  notes        text
);

create table entry (
  id                bigint primary key,
  source_id         bigint not null references source (id),
  seq               int not null,
  kind              text not null,
  section           text,
  volume            int,
  page              int,
  page_end          int,
  text              text not null,
  created_by        text not null,
  created_at        timestamptz not null,
  script_confidence real,
  state             text not null default 'draft' check (state in ('draft', 'in_review', 'reviewed')),
  editor            text,
  edited_at         timestamptz,
  reviewer          text,
  reviewed_at       timestamptz,
  note              text,
  content_hash      text not null,
  updated_at        timestamptz not null,
  unique (source_id, seq),
  check (state <> 'reviewed' or (reviewer is not null and editor is not null and reviewer <> editor))
);
create index entry_state on entry (state);

create table entry_link (
  id         bigint generated always as identity primary key,
  entry_id   bigint not null references entry (id),
  surah      int not null check (surah between 1 and 114),
  ayah_from  int not null,
  ayah_to    int not null,
  word_from  int,
  word_to    int,
  quote      text,
  basis      text not null check (basis in ('marker', 'quote', 'marker+quote', 'manual')),
  confidence real not null check (confidence between 0 and 1),
  created_by text not null,
  check (ayah_to >= ayah_from)
);
create index entry_link_entry on entry_link (entry_id);

create table audit (
  id          bigint generated always as identity primary key,
  entry_id    bigint references entry (id),
  at          timestamptz not null default now(),
  actor       text not null,
  role        text not null check (role in ('script', 'editor', 'reviewer', 'admin')),
  action      text not null,
  from_state  text,
  to_state    text,
  hash_before text,
  hash_after  text,
  note        text,
  detail      jsonb
);
create index audit_entry on audit (entry_id);

create table surah (id int primary key, name_ar text not null, ayah_count int not null);
create table verse (
  surah int not null, ayah int not null, display_text text not null,
  text_search text not null, search_basmala_prefix int not null, page int not null,
  primary key (surah, ayah)
);

-- Append-only and frozen-text rules, also for the service role.
create function forbid() returns trigger language plpgsql as $$
begin raise exception '% on % is not allowed', tg_op, tg_table_name; end $$;
create trigger audit_no_update before update or delete on audit for each row execute function forbid();
create trigger entry_no_delete before delete on entry for each row execute function forbid();
create function entry_text_frozen() returns trigger language plpgsql as $$
begin
  if new.text is distinct from old.text then
    raise exception 'entry text is verbatim and cannot be edited';
  end if;
  return new;
end $$;
create trigger entry_text_frozen before update on entry for each row execute function entry_text_frozen();

-- ------------------------------------------------------------ row-level security

alter table meta enable row level security;
alter table person enable row level security;
alter table source enable row level security;
alter table entry enable row level security;
alter table entry_link enable row level security;
alter table audit enable row level security;
alter table surah enable row level security;
alter table verse enable row level security;

create function me() returns person language sql stable security definer set search_path = public as $$
  select * from person where user_id = auth.uid()
$$;
create function has_role(r text) returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from person where user_id = auth.uid() and r = any (roles))
$$;
create function is_member() returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from person where user_id = auth.uid())
$$;

-- Read: any person with a role. Write: none (functions only).
create policy read_meta on meta for select using (is_member());
create policy read_source on source for select using (is_member());
create policy read_entry on entry for select using (is_member());
create policy read_link on entry_link for select using (is_member());
create policy read_audit on audit for select using (is_member());
create policy read_surah on surah for select using (is_member());
create policy read_verse on verse for select using (is_member());
create policy read_person on person for select using (is_member());
-- Admins manage people.
create policy admin_person on person for all using (has_role('admin')) with check (has_role('admin'));

-- ------------------------------------------------------------ workflow functions
-- The same rules as apps/review/lib/src/model/workflow.dart. The content
-- hash is computed by the client (content_hash.dart) and re-checked by
-- tools/export_pack.py before anything is exported.

create function review_submit(p_entry bigint, p_role text) returns entry
language plpgsql security definer set search_path = public as $$
declare e entry; who person := me();
begin
  if who is null or not (p_role = any (who.roles)) or p_role not in ('editor', 'admin') then
    raise exception 'submitting is for editors or admins';
  end if;
  select * into e from entry where id = p_entry for update;
  if e.state <> 'draft' then raise exception 'only drafts are submitted'; end if;
  update entry set state = 'in_review', editor = who.name, edited_at = now(), updated_at = now()
   where id = p_entry returning * into e;
  insert into audit (entry_id, actor, role, action, from_state, to_state, hash_before, hash_after)
  values (p_entry, who.name, p_role, 'submit', 'draft', 'in_review', e.content_hash, e.content_hash);
  return e;
end $$;

create function review_approve(p_entry bigint, p_role text) returns entry
language plpgsql security definer set search_path = public as $$
declare e entry; who person := me();
begin
  if who is null or not (p_role = any (who.roles)) or p_role not in ('reviewer', 'admin') then
    raise exception 'approving is for reviewers or admins';
  end if;
  select * into e from entry where id = p_entry for update;
  if e.state <> 'in_review' then raise exception 'only entries in review are approved'; end if;
  if e.editor is null or e.editor = who.name then raise exception 'the editor cannot review their own work'; end if;
  update entry set state = 'reviewed', reviewer = who.name, reviewed_at = now(), updated_at = now()
   where id = p_entry returning * into e;
  insert into audit (entry_id, actor, role, action, from_state, to_state, hash_before, hash_after)
  values (p_entry, who.name, p_role, 'approve', 'in_review', 'reviewed', e.content_hash, e.content_hash);
  return e;
end $$;

create function review_reject(p_entry bigint, p_role text, p_note text) returns entry
language plpgsql security definer set search_path = public as $$
declare e entry; who person := me(); old_state text;
begin
  if who is null or not (p_role = any (who.roles)) or p_role not in ('reviewer', 'admin') then
    raise exception 'rejecting is for reviewers or admins';
  end if;
  if coalesce(trim(p_note), '') = '' then raise exception 'a rejection needs a written note'; end if;
  select * into e from entry where id = p_entry for update;
  old_state := e.state;
  if old_state = 'draft' then raise exception 'already a draft'; end if;
  if e.editor = who.name then raise exception 'the editor cannot review their own work'; end if;
  update entry set state = 'draft', reviewer = null, reviewed_at = null, note = trim(p_note), updated_at = now()
   where id = p_entry returning * into e;
  insert into audit (entry_id, actor, role, action, from_state, to_state, hash_before, hash_after, note)
  values (p_entry, who.name, p_role, 'reject', old_state, 'draft', e.content_hash, e.content_hash, trim(p_note));
  return e;
end $$;

-- p_links: jsonb array of {surah, ayah_from, ayah_to, word_from, word_to, quote, basis, confidence}
-- or null to keep the links. p_hash: the new content hash from the client.
create function review_edit(p_entry bigint, p_role text, p_links jsonb, p_note text,
                            p_page int, p_page_end int, p_hash text) returns entry
language plpgsql security definer set search_path = public as $$
declare e entry; who person := me(); old entry; new_state text;
begin
  if who is null or not (p_role = any (who.roles)) or p_role not in ('editor', 'admin') then
    raise exception 'editing is for editors or admins';
  end if;
  select * into old from entry where id = p_entry for update;
  new_state := case when old.state = 'reviewed' then 'in_review' else old.state end;
  if p_links is not null then
    delete from entry_link where entry_id = p_entry;
    insert into entry_link (entry_id, surah, ayah_from, ayah_to, word_from, word_to, quote, basis, confidence, created_by)
    select p_entry, (l->>'surah')::int, (l->>'ayah_from')::int, (l->>'ayah_to')::int,
           (l->>'word_from')::int, (l->>'word_to')::int, l->>'quote',
           coalesce(l->>'basis', 'manual'), coalesce((l->>'confidence')::real, 1), who.name
      from jsonb_array_elements(p_links) l;
  end if;
  update entry set state = new_state, editor = who.name, edited_at = now(),
         reviewer = case when old.state = 'reviewed' then null else reviewer end,
         reviewed_at = case when old.state = 'reviewed' then null else reviewed_at end,
         note = coalesce(p_note, note), page = coalesce(p_page, page),
         page_end = coalesce(p_page_end, page_end), content_hash = p_hash, updated_at = now()
   where id = p_entry returning * into e;
  insert into audit (entry_id, actor, role, action, from_state, to_state, hash_before, hash_after, note, detail)
  values (p_entry, who.name, p_role, 'edit', old.state, new_state, old.content_hash, p_hash, p_note,
          jsonb_build_object('links_after', p_links, 'pages_after', jsonb_build_array(p_page, p_page_end)));
  return e;
end $$;

revoke all on function review_submit, review_approve, review_reject, review_edit from public;
grant execute on function review_submit, review_approve, review_reject, review_edit to authenticated;
