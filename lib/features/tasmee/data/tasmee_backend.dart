import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/recitation_recognizer.dart';
import 'model_downloader.dart';
import 'model_manifest.dart';
import 'model_store.dart';
import 'sherpa_offline_recognizer.dart';
import 'tasmee_audio_capture.dart';

/// The microphone as the session uses it ([TasmeeAudioCapture]).
abstract interface class TasmeeMicrophone {
  Future<void> start({
    required PcmCallback onPcm,
    required AudioLevelCallback onLevel,
    required SpeechEndedCallback onSpeechEnded,
    required AudioErrorCallback onError,
    PcmCallback? onFrame,
  });

  Future<void> stop();
  Future<void> dispose();
}

class _Capture implements TasmeeMicrophone {
  final _capture = TasmeeAudioCapture();

  @override
  Future<void> start({
    required PcmCallback onPcm,
    required AudioLevelCallback onLevel,
    required SpeechEndedCallback onSpeechEnded,
    required AudioErrorCallback onError,
    PcmCallback? onFrame,
  }) => _capture.start(
    onPcm: onPcm,
    onLevel: onLevel,
    onSpeechEnded: onSpeechEnded,
    onError: onError,
    onFrame: onFrame,
  );

  @override
  Future<void> stop() => _capture.stop();

  @override
  Future<void> dispose() => _capture.dispose();
}

/// What the tasmee screens need from the device: the model on disk, its
/// download, the recogniser and the microphone. Tests replace it.
class TasmeeBackend {
  const TasmeeBackend();

  Future<ModelStore> _store() => ModelStore.inAppSupport();

  /// The installed recognition model, or null.
  Future<InstalledModel?> installedModel() async =>
      (await _store()).installed(recitationModelId);

  /// The model's manifest (its size, before asking to download it).
  Future<ModelManifest> fetchManifest() async {
    final downloader = ModelDownloader(store: await _store());
    try {
      return await downloader.fetchManifest();
    } finally {
      downloader.close();
    }
  }

  /// Downloads [manifest] (resumable) and removes models no longer used.
  Future<InstalledModel> download(
    ModelManifest manifest, {
    required void Function(ModelDownloadProgress progress) onProgress,
    required ModelDownloadCancel cancel,
  }) async {
    final store = await _store();
    final downloader = ModelDownloader(store: store);
    try {
      final installed = await downloader.download(
        manifest,
        allowCellular: true,
        cancel: cancel,
        onProgress: onProgress,
      );
      for (final id in retiredRecitationModelIds) {
        if (id != installed.manifest.id) await store.delete(id);
      }
      return installed;
    } finally {
      downloader.close();
    }
  }

  /// Space the models take, unfinished downloads included.
  Future<int> usedBytes() async => (await _store()).usedBytes();

  /// Removes the model (and any unfinished download of it).
  Future<void> deleteModel() async {
    final store = await _store();
    await store.delete(recitationModelId);
    for (final id in retiredRecitationModelIds) {
      await store.delete(id);
    }
  }

  RecitationRecognizer recognizer(InstalledModel model) =>
      SherpaOfflineRecognizer.forModel(model);

  TasmeeMicrophone microphone() => _Capture();

  static const _settings = MethodChannel('app.tibyan/settings');

  /// Opens this app's page in the device settings (to allow the
  /// microphone); false where the platform cannot.
  Future<bool> openDeviceSettings() async {
    try {
      return await _settings.invokeMethod<bool>('openAppSettings') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}

final tasmeeBackendProvider = Provider<TasmeeBackend>(
  (ref) => const TasmeeBackend(),
);
