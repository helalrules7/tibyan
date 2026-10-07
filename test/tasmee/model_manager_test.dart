import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:tibyan/features/tasmee/data/model_downloader.dart';
import 'package:tibyan/features/tasmee/data/model_manifest.dart';
import 'package:tibyan/features/tasmee/data/model_store.dart';

class _Net implements NetworkProbe {
  _Net(this.kind);
  final NetworkKind kind;
  @override
  Future<NetworkKind> current() async => kind;
}

/// A fake file server: serves [body] in 1000-byte chunks and honours
/// `Range: bytes=N-` unless [ignoreRange]. [failAfter] cuts the stream with
/// an error after that many bytes of the first response.
class _Server {
  _Server(this.body, {this.ignoreRange = false, this.failAfter});

  final List<int> body;
  final bool ignoreRange;
  int? failAfter;
  final ranges = <String?>[];

  MockClient get client => MockClient.streaming((request, _) async {
    final range = request.headers['Range'];
    ranges.add(range);
    var start = 0;
    final m = range == null ? null : RegExp(r'bytes=(\d+)-').firstMatch(range);
    if (m != null && !ignoreRange) start = int.parse(m.group(1)!);
    final slice = body.sublist(start);
    final cut = failAfter;
    failAfter = null;
    Stream<List<int>> chunks() async* {
      for (var i = 0; i < slice.length; i += 1000) {
        if (cut != null && i >= cut) throw const SocketException('cut');
        yield slice.sublist(i, math.min(i + 1000, slice.length));
      }
    }

    final partial = start > 0;
    return http.StreamedResponse(
      chunks(),
      partial ? 206 : 200,
      headers: partial
          ? {'content-range': 'bytes $start-${body.length - 1}/${body.length}'}
          : {},
    );
  });
}

ModelManifest _manifest(List<int> body, {String version = '1', String? sha}) =>
    ModelManifest(
      id: 'test-model',
      version: version,
      license: 'Apache-2.0',
      files: [
        ModelFileSpec(
          name: 'model.bin',
          url: Uri.parse('https://example.org/model.bin'),
          sha256: sha ?? sha256.convert(body).toString(),
          bytes: body.length,
        ),
      ],
    );

void main() {
  final body = List<int>.generate(5000, (i) => i % 251);
  late Directory tmp;
  late ModelStore store;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('model_manager_test');
    store = ModelStore(Directory(p.join(tmp.path, 'models')));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  group('ModelManifest', () {
    Map<String, dynamic> json() => _manifest(body).toJson();

    test('round-trips through JSON', () {
      final m = ModelManifest.fromJson(json());
      expect(m.id, 'test-model');
      expect(m.totalBytes, 5000);
      expect(m.files.single.sha256, hasLength(64));
    });

    test('rejects a missing licence', () {
      expect(
        () => ModelManifest.fromJson({...json(), 'license': ' '}),
        throwsFormatException,
      );
    });

    test('rejects http URLs, bad checksums and path tricks', () {
      Map<String, dynamic> withFile(Map<String, dynamic> patch) => {
        ...json(),
        'files': [
          {
            ...(json()['files'] as List).first as Map<String, dynamic>,
            ...patch,
          },
        ],
      };
      expect(
        () => ModelManifest.fromJson(
          withFile({'url': 'http://example.org/model.bin'}),
        ),
        throwsFormatException,
      );
      expect(
        () => ModelManifest.fromJson(withFile({'sha256': 'abc'})),
        throwsFormatException,
      );
      expect(
        () => ModelManifest.fromJson(withFile({'name': '../model.bin'})),
        throwsFormatException,
      );
      expect(
        () => ModelManifest.fromJson(withFile({'name': 'installed.json'})),
        throwsFormatException,
      );
      expect(
        () => ModelManifest.fromJson({...json(), 'version': '../x'}),
        throwsFormatException,
      );
    });
  });

  group('ModelDownloader', () {
    test('downloads, verifies and marks the model installed', () async {
      final server = _Server(body);
      final downloader = ModelDownloader(store: store, client: server.client);
      final seen = <double>[];
      final installed = await downloader.download(
        _manifest(body),
        onProgress: (pr) => seen.add(pr.fraction),
      );
      expect(await installed.file('model.bin').readAsBytes(), body);
      expect(seen.last, 1.0);
      expect(await store.installed('test-model'), isNotNull);
      expect(await store.usedBytes(), greaterThanOrEqualTo(5000));
    });

    test('does nothing when exactly that version is installed', () async {
      final server = _Server(body);
      final downloader = ModelDownloader(store: store, client: server.client);
      await downloader.download(_manifest(body));
      await downloader.download(_manifest(body));
      expect(server.ranges, hasLength(1));
    });

    test('resumes an interrupted download with a Range request', () async {
      final server = _Server(body, failAfter: 2000);
      final downloader = ModelDownloader(store: store, client: server.client);
      await expectLater(
        downloader.download(_manifest(body)),
        throwsA(isA<SocketException>()),
      );
      final part = File(
        p.join(store.directoryFor(_manifest(body)).path, 'model.bin.part'),
      );
      expect(await part.length(), 2000);

      final installed = await downloader.download(_manifest(body));
      expect(server.ranges.last, 'bytes=2000-');
      expect(await installed.file('model.bin').readAsBytes(), body);
    });

    test('restarts when the server ignores the Range header', () async {
      final server = _Server(body, ignoreRange: true, failAfter: 2000);
      final downloader = ModelDownloader(store: store, client: server.client);
      await expectLater(
        downloader.download(_manifest(body)),
        throwsA(isA<SocketException>()),
      );
      final installed = await downloader.download(_manifest(body));
      expect(await installed.file('model.bin').readAsBytes(), body);
    });

    test('a wrong checksum is deleted and reported', () async {
      final server = _Server(body);
      final downloader = ModelDownloader(store: store, client: server.client);
      final bad = _manifest(body, sha: sha256.convert([1, 2, 3]).toString());
      await expectLater(
        downloader.download(bad),
        throwsA(isA<ModelChecksumMismatch>()),
      );
      expect(await store.installed('test-model'), isNull);
      expect(
        File(p.join(store.directoryFor(bad).path, 'model.bin.part'))
            .existsSync(),
        isFalse,
      );
    });

    test('cancel keeps the partial file for a later resume', () async {
      final server = _Server(body);
      final downloader = ModelDownloader(store: store, client: server.client);
      final cancel = ModelDownloadCancel();
      await expectLater(
        downloader.download(
          _manifest(body),
          cancel: cancel,
          onProgress: (_) => cancel.cancel(),
        ),
        throwsA(isA<ModelDownloadCancelled>()),
      );
      expect(await store.installed('test-model'), isNull);

      final installed = await downloader.download(_manifest(body));
      expect(await installed.file('model.bin').readAsBytes(), body);
    });

    test('refuses mobile data unless allowed', () async {
      final server = _Server(body);
      final downloader = ModelDownloader(
        store: store,
        client: server.client,
        network: _Net(NetworkKind.cellular),
      );
      await expectLater(
        downloader.download(_manifest(body)),
        throwsA(isA<ModelCellularBlocked>()),
      );
      expect(server.ranges, isEmpty);
      await downloader.download(_manifest(body), allowCellular: true);
      expect(await store.installed('test-model'), isNotNull);
    });

    test('refuses when offline', () async {
      final downloader = ModelDownloader(
        store: store,
        client: _Server(body).client,
        network: _Net(NetworkKind.offline),
      );
      await expectLater(
        downloader.download(_manifest(body)),
        throwsA(isA<ModelDownloadException>()),
      );
    });

    test('a new version replaces the old one', () async {
      final newBody = List<int>.generate(3000, (i) => (i * 7) % 253);
      final downloader = ModelDownloader(
        store: store,
        client: _Server(body).client,
      );
      await downloader.download(_manifest(body, version: '1'));
      final next = ModelDownloader(
        store: store,
        client: _Server(newBody).client,
      );
      await next.download(_manifest(newBody, version: '2'));

      final now = await store.installed('test-model');
      expect(now!.manifest.version, '2');
      expect(
        Directory(p.join(store.root.path, 'test-model', '1')).existsSync(),
        isFalse,
      );
    });
  });

  group('ModelStore', () {
    test('delete removes the model and frees the space', () async {
      final downloader = ModelDownloader(
        store: store,
        client: _Server(body).client,
      );
      await downloader.download(_manifest(body));
      await store.delete('test-model');
      expect(await store.installed('test-model'), isNull);
      expect(await store.usedBytes(), 0);
    });

    test('a model with a truncated file is not installed', () async {
      final downloader = ModelDownloader(
        store: store,
        client: _Server(body).client,
      );
      final installed = await downloader.download(_manifest(body));
      await installed.file('model.bin').writeAsBytes([1, 2, 3]);
      expect(await store.installed('test-model'), isNull);
    });
  });
}
