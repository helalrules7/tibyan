import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/audio/timing_updates.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';

const _folder = 'https://server11.mp3quran.net/sds/';

/// A pack for al-Sudais (11) holding al-Fatiha only, with times that
/// content.db does not have.
List<int> _pack({int version = 3, String folder = _folder, int id = 11}) =>
    gzip.encode(
      utf8.encode(
        jsonEncode({
          'format': 1,
          'slug': 'sudais',
          'reciter_id': id,
          'folder_url': folder,
          'version': version,
          'surahs': {
            '1': [
              [
                1,
                3700,
                6000,
                [
                  [1, 3700, 4000],
                  [2, 4000, 4500],
                  [3, 4600, 5400],
                  [4, 5500, 6000],
                ],
              ],
              [
                2,
                6000,
                10100,
                [
                  [2, 6700, 7500],
                  [1, 6000, 6600],
                ],
              ],
            ],
          },
        }),
      ),
    );

String _manifest(List<int> pack, {int version = 3, String? sha}) => jsonEncode({
  'format': 1,
  'reciters': [
    {
      'slug': 'sudais',
      'reciter_id': 11,
      'version': version,
      'file': 'timing-sudais-v$version.json.gz',
      'bytes': pack.length,
      'sha256': sha ?? sha256.convert(pack).toString(),
    },
  ],
});

MockClient _server(List<int> pack, String manifest, {List<Uri>? asked}) =>
    MockClient((request) async {
      asked?.add(request.url);
      if (request.url.path.endsWith('/manifest.json')) {
        return http.Response(manifest, 200);
      }
      if (request.url.path.endsWith('.json.gz')) {
        return http.Response.bytes(pack, 200);
      }
      return http.Response('', 404);
    });

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('timing'));
  tearDown(() => dir.deleteSync(recursive: true));

  TimingUpdates updates(http.Client client) =>
      TimingUpdates(dir, client: client)
        ..folders = {11: _folder}
        ..bundled = {};

  group('manifest', () {
    test('reads well-formed entries and drops the rest', () {
      final pack = _pack();
      final good = parseTimingManifest(_manifest(pack));
      expect(good.single.slug, 'sudais');
      expect(good.single.version, 3);
      expect(good.single.bytes, pack.length);
      final bad = jsonDecode(_manifest(pack)) as Map<String, dynamic>;
      (bad['reciters'] as List).addAll([
        {'slug': 'x', 'reciter_id': '11'},
        {
          'slug': 'x',
          'reciter_id': 1,
          'version': 1,
          'file': '../../etc/passwd',
          'bytes': 10,
          'sha256': 'a' * 64,
        },
        {
          'slug': 'x',
          'reciter_id': 1,
          'version': 1,
          'file': 'timing-x-v1.json.gz',
          'bytes': 10,
          'sha256': 'not a hash',
        },
      ]);
      expect(parseTimingManifest(jsonEncode(bad)), hasLength(1));
      expect(parseTimingManifest('<html>'), isEmpty);
      expect(parseTimingManifest('{"format": 2, "reciters": []}'), isEmpty);
    });
  });

  group('pack', () {
    test('gives content.db rows, words in order of time', () {
      final pack = TimingPack.decode(_pack());
      expect(pack.has(1), isTrue);
      expect(pack.has(2), isFalse);
      final ayahs = pack.ayahRows(1);
      expect(ayahs.map((r) => (r.ayah, r.startMs, r.endMs)), [
        (1, 3700, 6000),
        (2, 6000, 10100),
      ]);
      final words = pack.wordRows(1);
      expect(words.map((w) => (w.ayah, w.word)).take(6), [
        (1, 1),
        (1, 2),
        (1, 3),
        (1, 4),
        (2, 1),
        (2, 2),
      ]);
      expect(words.every((w) => w.reciter == 11 && w.surah == 1), isTrue);
    });

    test('refuses what is not a well-formed pack', () {
      List<int> gz(Object doc) => gzip.encode(utf8.encode(jsonEncode(doc)));
      expect(() => TimingPack.decode(utf8.encode('{}')), throwsA(anything));
      expect(
        () => TimingPack.decode(gz({'format': 1, 'slug': 's'})),
        throwsFormatException,
      );
      final backwards = {
        'format': 1,
        'slug': 's',
        'reciter_id': 1,
        'folder_url': 'f',
        'version': 1,
        'surahs': {
          '1': [
            [1, 500, 400, []],
          ],
        },
      };
      expect(() => TimingPack.decode(gz(backwards)), throwsFormatException);
    });
  });

  group('updates', () {
    test('installs a verified pack and uses it', () async {
      final pack = _pack();
      final u = updates(_server(pack, _manifest(pack)));
      expect(await u.refresh(), 1);
      expect(u.packFile(11).readAsBytesSync(), pack);
      expect((await u.packFor(11, 1))?.version, 3);
      expect(await u.packFor(11, 2), isNull, reason: 'not in the pack');
      expect(await u.packFor(12, 1), isNull, reason: 'another reciter');
    });

    test('a pack whose SHA-256 does not match is not installed', () async {
      final pack = _pack();
      final u = updates(_server(pack, _manifest(pack, sha: 'b' * 64)));
      expect(await u.refresh(), 0);
      expect(u.packFile(11).existsSync(), isFalse);
      expect(await u.packFor(11, 1), isNull);
    });

    test('a pack for other audio files, or older than content.db, is not '
        'used', () async {
      final other = _pack(folder: 'https://elsewhere/');
      expect(await updates(_server(other, _manifest(other))).refresh(), 0);
      final pack = _pack();
      final u = updates(_server(pack, _manifest(pack)))
        ..bundled = {'sudais': 3};
      expect(await u.refresh(), 0, reason: 'content.db already has v3');
    });

    test('offline or failing, nothing changes and nothing throws', () async {
      final pack = _pack();
      final u = updates(_server(pack, _manifest(pack)));
      expect(await u.refresh(), 1);
      final down = updates(
        MockClient((_) async => throw const SocketException('offline')),
      );
      expect(await down.refresh(force: true), 0);
      expect((await down.packFor(11, 1))?.version, 3, reason: 'kept on disk');
      final broken = updates(MockClient((_) async => http.Response('', 500)));
      expect(await broken.refresh(force: true), 0);
    });

    test('asks the server at most twice a day', () async {
      final pack = _pack();
      final asked = <Uri>[];
      final u = updates(_server(pack, _manifest(pack), asked: asked));
      final t = DateTime(2026, 10, 3, 9);
      await u.refresh(now: t);
      final n = asked.length;
      await u.refresh(now: t.add(const Duration(hours: 1)));
      expect(asked, hasLength(n));
      await u.refresh(now: t.add(const Duration(hours: 13)));
      expect(asked.length, greaterThan(n));
    });

    test('a pack changed on disk is ignored', () async {
      final pack = _pack();
      expect(await updates(_server(pack, _manifest(pack))).refresh(), 1);
      final file = File('${dir.path}/11.json.gz');
      file.writeAsBytesSync(_pack(version: 9));
      final fresh = updates(MockClient((_) async => http.Response('', 404)));
      expect(await fresh.packFor(11, 1), isNull);
    });
  });

  group('preference order', () {
    late ContentDatabase db;

    setUpAll(() {
      db = ContentDatabase(
        NativeDatabase(
          File('assets/db/content.db'),
          setup: (raw) => raw.execute('PRAGMA query_only = ON'),
        ),
      );
    });
    tearDownAll(() => db.close());

    test('a downloaded pack wins over content.db for its reciter and surahs '
        'only', () async {
      final plain = MushafRepository(db);
      final dbFatiha = await plain.timings(11, 1);
      final dbWords = await plain.wordTimings(11, 1);
      expect(dbFatiha.first.startMs, isNot(3700));

      final pack = _pack();
      final u = updates(_server(pack, _manifest(pack)));
      final reciters = await plain.reciters();
      u.folders = {for (final r in reciters) r.id: r.folderUrl};
      expect(u.folders[11], _folder, reason: 'the pack is for these files');
      await u.refresh();
      final repo = MushafRepository(db, u);

      expect((await repo.timings(11, 1)).first.startMs, 3700);
      expect((await repo.wordTimings(11, 1)).first.endMs, 4000);
      // A surah the pack does not hold, and another reciter: content.db.
      expect(
        (await repo.timings(11, 2)).length,
        (await plain.timings(11, 2)).length,
      );
      expect(
        (await repo.timings(12, 1)).map((r) => r.startMs),
        (await plain.timings(12, 1)).map((r) => r.startMs),
      );
      // Once content.db carries this version, its own rows are used again.
      u.bundled = {'sudais': 3};
      expect(
        (await repo.timings(11, 1)).map((r) => r.startMs),
        dbFatiha.map((r) => r.startMs),
      );
      expect(await repo.wordTimings(11, 1), hasLength(dbWords.length));
    });

    test('content.db names the timing versions it was built with', () async {
      final versions = await MushafRepository(db).timingVersions();
      expect(versions.values.every((v) => v > 0), isTrue);
    });
  });
}
