import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:tibyan/features/tasmee/data/model_downloader.dart';
import 'package:tibyan/features/tasmee/data/model_manifest.dart';
import 'package:tibyan/features/tasmee/data/model_store.dart';
import 'package:tibyan/features/tasmee/data/tasmee_audio_capture.dart';
import 'package:tibyan/features/tasmee/data/tasmee_backend.dart';
import 'package:tibyan/features/tasmee/domain/recitation_recognizer.dart';

ModelManifest fakeManifest() => ModelManifest.fromJson(
  jsonDecode(
    File('test/tasmee/fixtures/recitation_model_manifest.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>,
);

InstalledModel fakeModel() =>
    InstalledModel(manifest: fakeManifest(), directory: Directory.systemTemp);

/// A recogniser that writes down whatever the test says.
class FakeRecognizer implements RecitationRecognizer {
  final _events = StreamController<RecognizerEvent>.broadcast();
  bool started = false;
  bool disposed = false;
  int samples = 0;

  void say(String text) => _events.add(FinalTranscript(text));

  @override
  Future<void> start() async => started = true;

  @override
  void acceptAudio(Int16List pcm) => samples += pcm.length;

  @override
  void endOfSpeech() {}

  @override
  Stream<RecognizerEvent> get events => _events.stream;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _events.close();
  }
}

class FakeMicrophone implements TasmeeMicrophone {
  FakeMicrophone({this.denied = false});

  final bool denied;
  bool running = false;
  int starts = 0;
  PcmCallback? onFrame;

  @override
  Future<void> start({
    required PcmCallback onPcm,
    required AudioLevelCallback onLevel,
    required SpeechEndedCallback onSpeechEnded,
    required AudioErrorCallback onError,
    PcmCallback? onFrame,
  }) async {
    if (denied) throw const MicrophonePermissionDenied();
    starts++;
    running = true;
    this.onFrame = onFrame;
  }

  @override
  Future<void> stop() async => running = false;

  @override
  Future<void> dispose() async => running = false;
}

/// The device side of the tasmee, in memory.
class FakeBackend extends TasmeeBackend {
  FakeBackend({this.installed = true, this.micDenied = false});

  bool installed;
  final bool micDenied;
  final recognizer0 = FakeRecognizer();
  late final microphone0 = FakeMicrophone(denied: micDenied);
  int settingsOpened = 0;
  int deleted = 0;
  Completer<void>? downloadGate;

  @override
  Future<InstalledModel?> installedModel() async =>
      installed ? fakeModel() : null;

  @override
  Future<ModelManifest> fetchManifest() async => fakeManifest();

  @override
  Future<InstalledModel> download(
    ModelManifest manifest, {
    required void Function(ModelDownloadProgress progress) onProgress,
    required ModelDownloadCancel cancel,
  }) async {
    onProgress(
      ModelDownloadProgress(
        receivedBytes: manifest.totalBytes ~/ 2,
        totalBytes: manifest.totalBytes,
        file: 'model.int8.onnx',
      ),
    );
    await downloadGate?.future;
    installed = true;
    return fakeModel();
  }

  @override
  Future<int> usedBytes() async => installed ? 131665482 : 0;

  @override
  Future<void> deleteModel() async {
    deleted++;
    installed = false;
  }

  @override
  RecitationRecognizer recognizer(InstalledModel model) => recognizer0;

  @override
  TasmeeMicrophone microphone() => microphone0;

  @override
  Future<bool> openDeviceSettings() async {
    settingsOpened++;
    return true;
  }
}
