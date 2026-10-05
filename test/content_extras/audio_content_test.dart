import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;
import 'package:tibyan/core/flags/feature_flags.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/audio/recitation.dart';
import 'package:tibyan/features/content_extras/credits.dart';
import 'package:tibyan/features/content_extras/english_tafsir.dart';
import 'package:tibyan/features/content_extras/tafsir_audio_button.dart';
import 'package:tibyan/features/content_extras/verse_audio_index.dart';
import 'package:tibyan/features/mushaf/data/page_pack.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/verse_services.dart';
import 'package:tibyan/l10n/app_localizations.dart';

import '../audio/player_test.dart' show FakeAudio, FakeRepo;

import 'package:tibyan/core/testing/test_packs.dart';

String fixtureText(String name) =>
    File('test/fixtures/audio_content/$name.json').readAsStringSync();
VerseAudioIndex fixture(String name) =>
    VerseAudioIndex.parse(fixtureText(name));

/// The schema `tools/fetch_quranenc_extra.py pack` writes. The texts are
/// placeholders, not from any tafsir.
File fakeTafsirPack(Directory dir, {String kind = 'tafsir_text'}) {
  final f = File(p.join(dir.path, bookPackFile))
    ..parent.createSync(recursive: true);
  final db = sqlite3.open(f.path);
  db.execute(
    'CREATE TABLE pack_index (key TEXT PRIMARY KEY, value TEXT NOT NULL);'
    'CREATE TABLE verse (surah INTEGER NOT NULL, ayah INTEGER NOT NULL, '
    'text TEXT NOT NULL, footnotes TEXT, PRIMARY KEY (surah, ayah)) '
    'WITHOUT ROWID;',
  );
  for (final (k, v) in [
    ('format', '1'),
    ('kind', kind),
    ('key', 'english_mokhtasar'),
    ('source', ContentSources.quranEncMokhtasar),
    ('lang', 'en'),
    ('direction', 'ltr'),
    ('title', 'Placeholder English tafsir'),
    ('version', '1.0.7'),
  ]) {
    db.execute('INSERT INTO pack_index VALUES (?, ?)', [k, v]);
  }
  db.execute('INSERT INTO verse VALUES (2, 1, ?, NULL)', [
    'Placeholder text  for 2:1, kept as stored.',
  ]);
  db.execute('INSERT INTO verse VALUES (2, 2, ?, ?)', [
    'Placeholder text for 2:2.',
    'Placeholder note.',
  ]);
  db.close();
  return f;
}

const spec = TafsirTextPackSpec(
  id: 'tafsir-en-mokhtasar-test',
  url: 'https://mirror.example/books/tafsir-en-mokhtasar-test.pack.db',
  sha256: '00',
  bytes: 2500000,
  title: 'Al-Mukhtasar (English)',
);

class _QuietDownloads extends EnglishTafsirDownloads {
  final started = <String>[];

  @override
  Map<String, PackProgress> build() => const {};

  @override
  Future<void> start(TafsirTextPackSpec spec, String notification) async =>
      started.add(spec.id);
}

late ThemeRegistry registry;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => registry = await ThemeRegistry.load(rootBundle));

  group('the verse audio index', () {
    test('reads the formats the tools write', () {
      final rwwad = fixture('rwwad_translation_sample');
      expect(rwwad.kind, VerseAudioKind.translation);
      expect(rwwad.source, ContentSources.quranEncRwwadAudio);
      expect(
        rwwad.clipFor(2, 3),
        VerseAudioClip(
          Uri.parse(
            'https://d.quranenc.com/data/audio/english_rwwad/002003.mp3',
          ),
        ),
      );
      expect(rwwad.clipFor(2, 4), isNull);

      final saadi = fixture('nuqayah_per_surah_sample');
      expect(saadi.title('ar'), 'تفسير السعدي');
      final c = saadi.clipFor(2, 2)!;
      expect(c.uri.path, '/saadi/002.mp3');
      expect(c.start, const Duration(milliseconds: 42000));
      expect(c.end, const Duration(milliseconds: 90500));
      expect(saadi.clipFor(3, 9)!.wholeSurah, isTrue);
      expect(saadi.clipFor(3, 9, wholeSurahs: false), isNull);
      expect(saadi.clipFor(4, 1), isNull);
    });

    test('refuses what it cannot play safely', () {
      Map<String, Object?> base() =>
          jsonDecode(fixtureText('nuqayah_per_surah_sample'))
              as Map<String, Object?>;
      String with_(void Function(Map<String, Object?>) f) {
        final j = base();
        f(j);
        return jsonEncode(j);
      }

      for (final bad in [
        with_((j) => j['format'] = 2),
        with_(
          (j) => j['surahs'] = [
            [2, 'http://audio.example.org/saadi/002.mp3'],
          ],
        ),
        with_(
          (j) => j['offsets'] = [
            [4, 1, 0, 10],
          ],
        ),
        with_(
          (j) => j['offsets'] = [
            [2, 1, 10, 10],
          ],
        ),
        with_(
          (j) => j
            ..remove('surahs')
            ..remove('offsets'),
        ),
        with_((j) => j.remove('source')),
        'not json',
        '[]',
      ]) {
        expect(
          () => VerseAudioIndex.parse(bad),
          throwsFormatException,
          reason: bad,
        );
      }
    });

    test('fetched once, checked against its hash, kept', () async {
      final body = utf8.encode(fixtureText('nuqayah_per_verse_sample'));
      final hash = sha256.convert(body).toString();
      final s = AudioIndexSpec(
        id: 'nuqayah-almuyassar',
        kind: VerseAudioKind.tafsir,
        url: 'https://mirror.example/audio-index/nuqayah-almuyassar.json',
        sha256: hash,
      );
      var calls = 0;
      final root = Directory.systemTemp.createTempSync('audio_index');
      final store = AudioIndexStore(
        root,
        MockClient((_) async {
          calls++;
          return http.Response.bytes(body, 200);
        }),
      );
      expect((await store.load(s)).id, 'nuqayah-almuyassar');
      expect((await store.load(s)).verses.length, 2);
      expect(calls, 1);
      expect(store.file(s).existsSync(), isTrue);

      final wrong = AudioIndexSpec(
        id: 'other',
        kind: VerseAudioKind.tafsir,
        url: s.url,
        sha256: 'f' * 64,
      );
      await expectLater(store.load(wrong), throwsFormatException);
      expect(store.file(wrong).existsSync(), isFalse);
    });

    test('nothing of a kind while its flag is off', () async {
      ProviderContainer container(bool on) {
        final c = ProviderContainer(
          overrides: [
            featureFlagsProvider.overrideWithValue(
              FeatureFlags({
                Feature.tafsirAudio.key: on,
                Feature.translationAudio.key: on,
              }),
            ),
            verseAudioIndexesProvider.overrideWith(
              (ref) async => [
                fixture('rwwad_translation_sample'),
                fixture('nuqayah_per_verse_sample'),
              ],
            ),
          ],
        );
        addTearDown(c.dispose);
        return c;
      }

      final off = container(false);
      expect(await off.read(translationAudioIndexProvider.future), isNull);
      expect(
        await off.read(tafsirAudioForVerseProvider((surah: 2, ayah: 1)).future),
        isEmpty,
      );
      final on = container(true);
      expect(
        (await on.read(translationAudioIndexProvider.future))?.id,
        'quranenc-english-rwwad',
      );
      expect(
        await on.read(tafsirAudioForVerseProvider((surah: 2, ayah: 1)).future),
        hasLength(1),
      );
    });

    test('no index is published yet, only the test ones', () {
      expect(
        AudioIndexSpec.all.where((s) => !testAudioIndexes.contains(s)),
        isEmpty,
      );
      expect(
        TafsirTextPackSpec.english.where(
          (s) => !testEnglishTafsirPacks.contains(s),
        ),
        isEmpty,
      );
    });
  });

  Future<(ProviderContainer, FakeAudio)> pump(
    WidgetTester tester,
    Widget child, {
    Map<Feature, bool> flags = const {},
    List<VerseAudioIndex>? indexes,
    String locale = 'ar',
    List<TafsirTextPackSpec> specs = const [],
    Directory? root,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    final audio = FakeAudio();
    await tester.binding.setSurfaceSize(const Size(420, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = ProviderContainer(
      overrides: [
        themeRegistryProvider.overrideWithValue(registry),
        sharedPreferencesProvider.overrideWithValue(prefs!),
        featureFlagsProvider.overrideWithValue(
          FeatureFlags({for (final e in flags.entries) e.key.key: e.value}),
        ),
        verseAudioIndexesProvider.overrideWith(
          (ref) async =>
              indexes ??
              [
                fixture('nuqayah_per_verse_sample'),
                fixture('rwwad_translation_sample'),
              ],
        ),
        mushafRepositoryProvider.overrideWithValue(FakeRepo()),
        packRootProvider.overrideWithValue(
          root ?? Directory.systemTemp.createTempSync('content_extras'),
        ),
        recitationAudioProvider.overrideWithValue(() => audio),
        audioHttpClientProvider.overrideWithValue(
          MockClient((_) async => http.Response('', 404)),
        ),
        englishTafsirSpecsProvider.overrideWithValue(specs),
        englishTafsirDownloadsProvider.overrideWith(_QuietDownloads.new),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTheme(
            style: registry.byId(registry.defaultStyleId),
            mode: ThemeModeId.light,
            uiFont: UiFont.plex,
          ),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (c, audio);
  }

  group('«استمع للتفسير»', () {
    const buttons = TafsirAudioButtons(surah: 2, ayah: 1);

    testWidgets('hidden while the flag is off', (tester) async {
      await pump(tester, buttons);
      expect(find.text('استمع للتفسير'), findsNothing);
      expect(find.byIcon(Icons.headphones_outlined), findsNothing);
    });

    testWidgets('hidden for a verse no recording has', (tester) async {
      await pump(
        tester,
        const TafsirAudioButtons(surah: 2, ayah: 7),
        flags: {Feature.tafsirAudio: true},
      );
      expect(find.text('استمع للتفسير'), findsNothing);
    });

    testWidgets('plays the verse\'s tafsir, its source under it', (
      tester,
    ) async {
      final (c, audio) = await pump(
        tester,
        buttons,
        flags: {Feature.tafsirAudio: true},
      );
      expect(find.text('استمع للتفسير'), findsOneWidget);
      expect(
        find.text(contentCredit(ContentSources.nuqayahTafsirAudio, 'ar')),
        findsOneWidget,
      );
      await tester.tap(find.text('استمع للتفسير'));
      await tester.pumpAndSettle();
      expect(audio.loads.single.$1.path, '/almuyassar/002001.mp3');
      expect(c.read(recitationProvider).clip?.standalone, isTrue);
      // While it plays the button pauses it.
      expect(find.text('إيقاف مؤقت'), findsOneWidget);
      await tester.tap(find.text('إيقاف مؤقت'));
      await tester.pumpAndSettle();
      expect(audio.playing, isFalse);
    });

    testWidgets('a surah file without offsets says so', (tester) async {
      await pump(
        tester,
        const TafsirAudioButtons(surah: 3, ayah: 2),
        flags: {Feature.tafsirAudio: true},
        indexes: [fixture('nuqayah_per_surah_sample')],
      );
      expect(find.text('استمع لتفسير السورة'), findsOneWidget);
    });

    testWidgets('several recordings are named', (tester) async {
      await pump(
        tester,
        buttons,
        flags: {Feature.tafsirAudio: true},
        indexes: [
          fixture('nuqayah_per_verse_sample'),
          fixture('nuqayah_per_surah_sample'),
        ],
      );
      expect(find.text('استمع للتفسير · التفسير الميسر'), findsOneWidget);
      expect(find.text('استمع للتفسير · تفسير السعدي'), findsOneWidget);
    });

    Widget panel(VoidCallback? onTafsirAudio) => VerseServicesPanel(
      verses: const [(surah: 2, ayah: 1)],
      surahs: null,
      onMark: (_) {},
      onSaveToFasil: () {},
      onClose: () {},
      onMultiSelect: () {},
      onTafsir: () {},
      onListen: () {},
      onWordStudy: null,
      onWordMeanings: () {},
      onTafsirAudio: onTafsirAudio,
    );

    testWidgets('the verse panel offers it with a recording', (tester) async {
      var tapped = false;
      await pump(tester, panel(() => tapped = true));
      await tester.tap(find.text('استمع للتفسير'));
      expect(tapped, isTrue);
    });

    testWidgets('and not without one', (tester) async {
      await pump(tester, panel(null));
      expect(find.text('استمع للتفسير'), findsNothing);
    });
  });

  group('English tafsir', () {
    const section = EnglishTafsirSection(surah: 2, ayah: 2);

    Directory installed() {
      final root = Directory.systemTemp.createTempSync('en_tafsir');
      final dir = Directory(p.join(root.path, 'packs', spec.id));
      fakeTafsirPack(dir);
      File(p.join(dir.path, '.installed')).writeAsStringSync('now');
      return root;
    }

    test('reads the pack as stored and refuses another kind', () {
      final dir = Directory.systemTemp.createTempSync('en_pack');
      final pack = TafsirTextPack.open(fakeTafsirPack(dir));
      addTearDown(pack.close);
      expect(
        pack.entry(2, 1)?.text,
        'Placeholder text  for 2:1, kept as stored.',
      );
      expect(pack.entry(2, 1)?.footnotes, isNull);
      expect(pack.entry(2, 2)?.footnotes, 'Placeholder note.');
      expect(pack.entry(2, 3), isNull);
      expect(pack.version, '1.0.7');
      expect(pack.rtl, isFalse);
      final other = Directory.systemTemp.createTempSync('en_pack');
      expect(
        () => TafsirTextPack.open(fakeTafsirPack(other, kind: 'book')),
        throwsFormatException,
      );
    });

    testWidgets('shown in the English interface with its source', (
      tester,
    ) async {
      await pump(
        tester,
        section,
        locale: 'en',
        flags: {Feature.englishTafsir: true},
        specs: [spec],
        root: installed(),
      );
      expect(find.text('Placeholder English tafsir'), findsOneWidget);
      expect(find.text('Placeholder text for 2:2.'), findsOneWidget);
      expect(find.text('Placeholder note.'), findsOneWidget);
      expect(
        find.text(
          contentCredit(
            ContentSources.quranEncMokhtasar,
            'en',
            version: '1.0.7',
          ),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('QuranEnc.com'), findsOneWidget);
      expect(find.textContaining('1.0.7'), findsOneWidget);
    });

    testWidgets('hidden while the flag is off', (tester) async {
      await pump(
        tester,
        section,
        locale: 'en',
        specs: [spec],
        root: installed(),
      );
      expect(find.textContaining('Placeholder'), findsNothing);
      expect(find.text('Download'), findsNothing);
    });

    testWidgets('hidden in the Arabic interface', (tester) async {
      await pump(
        tester,
        section,
        flags: {Feature.englishTafsir: true},
        specs: [spec],
        root: installed(),
      );
      expect(find.textContaining('Placeholder'), findsNothing);
    });

    testWidgets('offered for download when published, not installed', (
      tester,
    ) async {
      final (c, _) = await pump(
        tester,
        section,
        locale: 'en',
        flags: {Feature.englishTafsir: true},
        specs: [spec],
      );
      expect(
        find.text('Download the English tafsir: Al-Mukhtasar (English)'),
        findsOneWidget,
      );
      expect(find.textContaining('QuranEnc.com'), findsOneWidget);
      await tester.tap(find.text('Download'));
      final downloads =
          c.read(englishTafsirDownloadsProvider.notifier) as _QuietDownloads;
      expect(downloads.started, [spec.id]);
    });

    testWidgets('nothing at all while no pack is published', (tester) async {
      await pump(
        tester,
        section,
        locale: 'en',
        flags: {Feature.englishTafsir: true},
      );
      expect(find.byType(Card), findsNothing);
      expect(find.text('Download'), findsNothing);
    });
  });
}
