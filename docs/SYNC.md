# الحسابات والمزامنة والختمة الجماعية

الحالة: **طبقة المزامنة في التطبيق جاهزة ومطفأة** (`accounts_sync: false` و`group_khatma: false` في `assets/config/feature_flags.json`). لا يوجد مشروع Supabase بعد، ولا مفاتيح في المستودع. ما يلي هو كل ما يلزم لتشغيلها.

## ما في التطبيق الآن

نموذج المزامنة كما في المخطط: الجهاز هو المرجع، وكل جدول للمستخدم فيه `uuid` و`updated_at` و`deleted_at`، والتغييرات تدخل جدول الصادر `outbox`، وآخر كتابة تغلب لكل صف. والضيوف لا تخرج بياناتهم من الجهاز.

| الملف | ما فيه |
|---|---|
| `lib/core/db/habit_tables.dart` | الجداول المزامَنة: `khatma`، `khatma_log`، `reading_session`، `listening_session`، `reflection`، وجدول `outbox` |
| `lib/core/sync/outbox_writer.dart` | كل كتابة تضيف صفها للصادر في نفس المعاملة. صف واحد لكل سطر: التغيير الأحدث يحل محل الأقدم |
| `lib/core/sync/sync.dart` | الواجهة `SyncBackend`، والخلفية المحلية `LocalOnlyBackend` (لا أحد مسجل، فلا يُرسل شيء)، و`SyncEngine.syncOnce()`، و`applyRemote()` (آخر كتابة تغلب؛ التعادل يبقي الصف المحلي)، و`syncBackendProvider` |
| `lib/features/khatma/khatma_providers.dart` | `syncEngineProvider`، يقرأ علم `accounts_sync` |
| `test/khatma/sync_test.dart` | الاختبارات بخلفية وهمية |

`syncOnce()` يرجع `off` والعلم مطفأ، و`guest` بلا حساب. وعند الدخول: يرسل الصادر، ويحذف ما أُرسل فقط، ثم يسحب الصفوف الأحدث من آخر سحب (`sync.lastPull` في SharedPreferences) ويدمجها.

شكل الحمولة: `toJson()` لصف drift، والمفاتيح بأسماء Dart (`updatedAt`، `khatmaUuid`، `body` لعمود `text`…)، والتواريخ بالمللي ثانية. والعمود `id` محلي لكل جهاز؛ الصفوف تتطابق بـ `uuid`.

جدولا `bookmark_sets` و`reading_positions` القديمان لا يحملان `uuid` بعد، فلم يدخلا المزامنة (تغييرهما ليس إضافيا). يحتاجان خطوة ترحيل تضيف الأعمدة الثلاثة قبل مزامنتهما.

## خطوات التشغيل

### 1. مشروع Supabase (أحمد)

- مشروع جديد، منفصل عن مشروع أداة المراجعة.
- المنطقة الأقرب للمستخدمين (مثلا Frankfurt).
- يُحفظ `SUPABASE_URL` و`anon key` خارج المستودع، ويمرران وقت البناء: `--dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…`. مفتاح `service_role` لا يدخل التطبيق أبدا.

### 2. الجداول والصلاحيات (SQL)

جدول واحد لكل جدول محلي، بنفس الأعمدة مع `user_id`، وصلاحيات على مستوى الصف:

```sql
create table public.reflection (
  uuid uuid primary key,
  user_id uuid not null references auth.users on delete cascade default auth.uid(),
  surah int not null,
  ayah int not null,
  text text not null,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
);
create index on public.reflection (user_id, updated_at);
alter table public.reflection enable row level security;
create policy "own rows" on public.reflection
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Last write wins on the server too: an older write never replaces a newer row.
create or replace function public.lww() returns trigger language plpgsql as $$
begin
  if tg_op = 'UPDATE' and new.updated_at <= old.updated_at then
    return old;
  end if;
  return new;
end $$;
create trigger reflection_lww before update on public.reflection
  for each row execute function public.lww();
```

وبالمثل:
- `khatma(uuid, user_id, title, edition, unit, start_date date, target_date date, daily_portion real, reminder_time int, rebased_on date, completed_at, created_at, updated_at, deleted_at)`
- `khatma_log(uuid, user_id, khatma_uuid uuid, date date, from_page int, to_page int, updated_at, deleted_at)`
- `reading_session(uuid, user_id, started_at, ended_at, pages int, mode text, edition text, updated_at, deleted_at)`
- `listening_session(uuid, user_id, started_at, seconds int, reciter_id int, updated_at, deleted_at)`

لا يُحذف صف من الخادم أبدا: الحذف هو `deleted_at`.

### 3. الدخول بجوجل وأبل

- **Google**: في Google Cloud Console، عملاء OAuth لأندرويد (اسم الحزمة `app.tibyan.tibyan` وبصمة SHA-1 لمفتاح الرفع ومفتاح Play)، ولـ iOS، ولـ Web (هذا معرفه وسره يوضعان في Supabase ‹ Auth ‹ Providers ‹ Google). وفي iOS يضاف `REVERSED_CLIENT_ID` إلى `CFBundleURLTypes`.
- **Apple**: في حساب Apple Developer، تفعيل Sign in with Apple للمعرف `app.tibyan.tibyan`، وService ID ومفتاح (.p8) يوضعان في Supabase ‹ Auth ‹ Providers ‹ Apple. وفي Xcode تضاف قدرة Sign in with Apple للهدف Runner. (أبل تشترطه إن وُجد دخول بجوجل.)
- الحزم (لا تُضاف قبل التشغيل): `supabase_flutter`، `google_sign_in`، `sign_in_with_apple`.
- الدخول اختياري دائما. التطبيق كله يعمل بلا حساب.

### 4. الخلفية `SupabaseBackend`

صنف واحد يطبق `SyncBackend`، ثم يستبدل في `main.dart`:

```dart
class SupabaseBackend implements SyncBackend {
  SupabaseBackend(this._client);
  final SupabaseClient _client;

  @override
  Future<String?> currentUser() async => _client.auth.currentUser?.id;

  @override
  Future<void> push(List<OutboxRow> changes) async {
    for (final table in syncedTables) {
      final rows = [
        for (final c in changes)
          if (c.entity == table) toServerRow(table, outboxPayload(c)),
      ];
      if (rows.isNotEmpty) {
        await _client.from(table).upsert(rows, onConflict: 'uuid');
      }
    }
  }

  @override
  Future<List<RemoteChange>> pull({DateTime? since}) async {
    final out = <RemoteChange>[];
    for (final table in syncedTables) {
      var q = _client.from(table).select();
      if (since != null) q = q.gt('updated_at', since.toUtc().toIso8601String());
      for (final r in await q) {
        final row = fromServerRow(table, r); // snake_case to the toJson() keys
        out.add(RemoteChange(
          table: table,
          uuid: r['uuid'] as String,
          row: row,
          updatedAt: DateTime.parse(r['updated_at'] as String),
        ));
      }
    }
    return out;
  }
}
```

`toServerRow`/`fromServerRow` يحولان المفاتيح (camelCase ↔ snake_case) والتواريخ (مللي ثانية ↔ ISO) ويحذفان `id` المحلي.

ثم في `main.dart`:

```dart
await Supabase.initialize(url: …, anonKey: …);
// overrides:
syncBackendProvider.overrideWithValue(SupabaseBackend(Supabase.instance.client)),
```

ومتى يُستدعى `syncEngine.syncOnce()`: بعد الدخول، وعند عودة التطبيق من الخلفية، وبعد الكتابة بمهلة (مثلا 30 ثانية تجمع التغييرات).

### 5. الواجهة

- شاشة «الحساب» في الإعدادات: دخول بجوجل/أبل، وآخر مزامنة، وخروج، وحذف الحساب (حذف صفوف الخادم كلها؛ أبل تشترطه).
- عند أول دخول على جهاز فيه بيانات: تُرفع كلها (الصادر يحمل كل صف كُتب). وصفوف الخادم تُدمج بآخر كتابة تغلب.
- قلب العلم `accounts_sync` إلى `true`.

## الختمة الجماعية (العلم `group_khatma`)

الوحيدة التي مرجعها الخادم، لا الجهاز:

```sql
create table public.group_khatma (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null references auth.users default auth.uid(),
  title text not null,
  edition text not null,          -- page numbers of this edition
  unit text not null default 'juz',
  invite_code text unique not null default encode(gen_random_bytes(6), 'base64'),
  start_date date not null,
  target_date date not null,
  created_at timestamptz not null default now()
);
create table public.group_member (
  group_id uuid references public.group_khatma on delete cascade,
  user_id uuid references auth.users on delete cascade default auth.uid(),
  display_name text,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);
create table public.group_portion (
  group_id uuid references public.group_khatma on delete cascade,
  unit_index int not null,        -- juz 0..29, hizb 0..59, or page
  taken_by uuid references auth.users,
  done_at timestamptz,
  primary key (group_id, unit_index)
);
```

- الصلاحيات: العضو يرى مجموعته وأعضاءها وأجزاءها، ويحجز جزءا شاغرا أو يعلم جزأه مقروءا. المالك يعدل ويحذف.
- الانضمام: دالة `join_group(code text)` بصلاحية `security definer` تتحقق من الرمز وتضيف العضو، حتى لا تُكشف المجموعات بالرموز.
- رابط الدعوة: `https://tibyan.ahmedhelal.dev/k/<code>` (App Links في أندرويد بملف `assetlinks.json`، وUniversal Links في iOS بملف `apple-app-site-association` على نفس النطاق)، مع المخطط `tibyan://join?code=…` احتياطا. ويضاف مسار `/join` في `app_router.dart`.
- التحديث اللحظي: Supabase Realtime على `group_portion` لكل مجموعة.
- الأجزاء المحجوزة تظهر في ورد العضو كأي ختمة، وقراءتها في المصحف تعلمها مقروءة (`KhatmaService.pageRead` بعد إضافة المجموعة).
- قلب العلم `group_khatma` إلى `true` بعد الاختبار.
