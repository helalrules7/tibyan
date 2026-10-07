import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'model_manifest.dart';
import 'model_store.dart';

enum NetworkKind { wifi, cellular, offline, unknown }

/// Tells the downloader what kind of connection the phone is on, so it can
/// refuse to spend mobile data unasked. Implemented by the app (the plan's
/// download screen); the manager itself needs no platform plugin.
abstract interface class NetworkProbe {
  Future<NetworkKind> current();
}

class ModelDownloadProgress {
  const ModelDownloadProgress({
    required this.receivedBytes,
    required this.totalBytes,
    required this.file,
  });

  /// Bytes of the whole model that are on disk so far.
  final int receivedBytes;
  final int totalBytes;

  /// The file being fetched now.
  final String file;

  double get fraction => totalBytes == 0 ? 0 : receivedBytes / totalBytes;
}

/// Lets the screen stop a running download. The partial file is kept, so
/// the next [ModelDownloader.download] resumes where this one stopped.
class ModelDownloadCancel {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

class ModelDownloadException implements Exception {
  const ModelDownloadException(this.message);
  final String message;

  @override
  String toString() => 'ModelDownloadException: $message';
}

class ModelDownloadCancelled extends ModelDownloadException {
  const ModelDownloadCancelled() : super('Download cancelled');
}

/// On mobile data and the caller did not allow it: ask the user, then call
/// again with `allowCellular: true`.
class ModelCellularBlocked extends ModelDownloadException {
  const ModelCellularBlocked(this.bytes)
    : super('Mobile data is not allowed for this download');

  final int bytes;
}

class ModelChecksumMismatch extends ModelDownloadException {
  const ModelChecksumMismatch(String file)
    : super('Downloaded file does not match its checksum: $file');
}

/// Downloads a [ModelManifest] into a [ModelStore]: resumable (HTTP Range),
/// every file checked against its size and SHA-256 before it is kept.
///
/// A network failure mid-download is rethrown as is (`http.ClientException`,
/// `SocketException`); the partial file stays on disk and calling
/// [download] again resumes it.
class ModelDownloader {
  ModelDownloader({required this.store, http.Client? client, this.network})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final ModelStore store;
  final NetworkProbe? network;
  final http.Client _client;
  final bool _ownsClient;

  void close() {
    if (_ownsClient) _client.close();
  }

  /// Installs [manifest]; returns at once if exactly that version is already
  /// installed. Replaces any older version of the same model on success.
  Future<InstalledModel> download(
    ModelManifest manifest, {
    bool allowCellular = false,
    void Function(ModelDownloadProgress progress)? onProgress,
    ModelDownloadCancel? cancel,
  }) async {
    final already = await store.installedFor(manifest);
    if (already != null) return already;

    final probe = network;
    if (probe != null) {
      final kind = await probe.current();
      if (kind == NetworkKind.offline) {
        throw const ModelDownloadException('No internet connection');
      }
      if (kind == NetworkKind.cellular && !allowCellular) {
        throw ModelCellularBlocked(manifest.totalBytes);
      }
    }

    final dir = store.directoryFor(manifest);
    await dir.create(recursive: true);

    final total = manifest.totalBytes;
    var finished = 0;
    for (final spec in manifest.files) {
      if (cancel?.isCancelled ?? false) throw const ModelDownloadCancelled();
      final target = File(p.join(dir.path, spec.name));
      if (await target.exists() && await target.length() == spec.bytes) {
        finished += spec.bytes;
        continue;
      }
      await _fetch(
        spec,
        target,
        finished: finished,
        total: total,
        onProgress: onProgress,
        cancel: cancel,
      );
      finished += spec.bytes;
    }
    return store.markInstalled(manifest);
  }

  Future<void> _fetch(
    ModelFileSpec spec,
    File target, {
    required int finished,
    required int total,
    required void Function(ModelDownloadProgress)? onProgress,
    required ModelDownloadCancel? cancel,
  }) async {
    final part = File('${target.path}.part');
    var offset = await part.exists() ? await part.length() : 0;
    if (offset > spec.bytes) {
      await part.delete();
      offset = 0;
    }
    if (offset < spec.bytes) {
      await _stream(
        spec,
        part,
        offset,
        finished: finished,
        total: total,
        onProgress: onProgress,
        cancel: cancel,
      );
    }
    final digest = await sha256.bind(part.openRead()).first;
    if (await part.length() != spec.bytes || digest.toString() != spec.sha256) {
      await part.delete();
      throw ModelChecksumMismatch(spec.name);
    }
    await part.rename(target.path);
  }

  Future<void> _stream(
    ModelFileSpec spec,
    File part,
    int offset, {
    required int finished,
    required int total,
    required void Function(ModelDownloadProgress)? onProgress,
    required ModelDownloadCancel? cancel,
  }) async {
    var start = offset;
    // At most one retry from zero, when the server refuses the resume.
    for (var attempt = 0; attempt < 2; attempt++) {
      final request = http.Request('GET', spec.url);
      if (start > 0) request.headers['Range'] = 'bytes=$start-';
      final response = await _client.send(request);

      final code = response.statusCode;
      if (code != 200 && code != 206 && code != 416) {
        await response.stream.drain<void>();
        throw ModelDownloadException('HTTP $code for ${spec.name}');
      }
      final resumeRefused =
          (code == 416 && start > 0) ||
          (code == 206 &&
              !_rangeStartsAt(response.headers['content-range'], start));
      if (resumeRefused) {
        await response.stream.drain<void>();
        if (await part.exists()) await part.delete();
        start = 0;
        continue;
      }
      if (code == 416) {
        await response.stream.drain<void>();
        throw ModelDownloadException('HTTP 416 for ${spec.name}');
      }

      // A 200 to a ranged request means the server ignored the range: it
      // sends the whole file again.
      final append = code == 206;
      var received = append ? start : 0;
      var tooLong = false;
      final sink = part.openWrite(
        mode: append ? FileMode.append : FileMode.write,
      );
      try {
        await for (final chunk in response.stream) {
          if (cancel?.isCancelled ?? false) {
            throw const ModelDownloadCancelled();
          }
          received += chunk.length;
          if (received > spec.bytes) {
            tooLong = true;
            break;
          }
          sink.add(chunk);
          onProgress?.call(
            ModelDownloadProgress(
              receivedBytes: finished + received,
              totalBytes: total,
              file: spec.name,
            ),
          );
        }
      } finally {
        await sink.close();
      }
      if (tooLong) {
        await part.delete();
        throw ModelChecksumMismatch(spec.name);
      }
      return;
    }
    throw ModelDownloadException('Could not fetch ${spec.name}');
  }

  /// `Content-Range: bytes 100-999/1000` starts at 100.
  static bool _rangeStartsAt(String? header, int start) {
    final m = header == null
        ? null
        : RegExp(r'^bytes (\d+)-').firstMatch(header);
    return m != null && int.parse(m.group(1)!) == start;
  }
}
