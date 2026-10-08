import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tibyan/features/tasmee/data/model_manifest.dart';
import 'package:tibyan/features/tasmee/data/model_store.dart';
import 'package:tibyan/features/tasmee/data/sherpa_offline_recognizer.dart';
import 'package:tibyan/features/tasmee/domain/recitation_recognizer.dart';

/// Writes what it was given instead of transcribing: the model kind and the
/// number of samples (no native library in tests).
class _FakeTranscriber implements SegmentTranscriber {
  _FakeTranscriber(this.kind);
  final String kind;

  @override
  String transcribe(Float32List samples) {
    if (samples.length == 16000 * 7) throw StateError('bad segment');
    // A segment of silence is transcribed as nothing.
    if (samples.every((s) => s == 0)) return '  ';
    return '$kind ${samples.length}';
  }

  @override
  void free() {}
}

SegmentTranscriber _fakeLoader(SherpaModelFiles files, int threads) =>
    _FakeTranscriber(switch (files) {
      NemoCtcFiles() => 'ctc',
      WhisperFiles() => 'whisper',
    });

SegmentTranscriber _failingLoader(SherpaModelFiles files, int threads) =>
    throw StateError('no model');

ModelManifest _manifest(String engine, List<String> names) => ModelManifest(
  id: 'm',
  version: '1',
  license: 'CC-BY-4.0',
  engine: engine,
  files: [
    for (final n in names)
      ModelFileSpec(
        name: n,
        url: Uri.parse('https://example.org/$n'),
        sha256: 'a' * 64,
        bytes: 1,
      ),
  ],
);

Int16List _speech(double seconds) {
  final n = (seconds * 16000).round();
  return Int16List(n)..fillRange(0, n, 1000);
}

void main() {
  final dir = Directory(p.join(Directory.systemTemp.path, 'model'));

  group('SherpaModelFiles.of', () {
    test('a NeMo CTC manifest gives the CTC model and its tokens', () {
      final files = SherpaModelFiles.of(
        InstalledModel(
          manifest: _manifest(ModelEngine.sherpaNemoCtc, [
            'model.int8.onnx',
            'tokens.txt',
          ]),
          directory: dir,
        ),
      );
      expect(files, isA<NemoCtcFiles>());
      files as NemoCtcFiles;
      expect(files.model, p.join(dir.path, 'model.int8.onnx'));
      expect(files.tokens, p.join(dir.path, 'tokens.txt'));
    });

    test('a Whisper manifest (comparison) gives encoder and decoder', () {
      final files = SherpaModelFiles.of(
        InstalledModel(
          manifest: _manifest(ModelEngine.sherpaWhisper, [
            'encoder.int8.onnx',
            'decoder.int8.onnx',
            'tokens.txt',
          ]),
          directory: dir,
        ),
      );
      expect(files, isA<WhisperFiles>());
      expect((files as WhisperFiles).language, 'ar');
    });

    test('an unknown engine or a missing file is refused', () {
      expect(
        () => SherpaModelFiles.of(
          InstalledModel(
            manifest: _manifest('whisper-cpp', ['model.bin']),
            directory: dir,
          ),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => SherpaModelFiles.of(
          InstalledModel(
            manifest: _manifest(ModelEngine.sherpaNemoCtc, ['tokens.txt']),
            directory: dir,
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('SherpaOfflineRecognizer', () {
    const ctc = NemoCtcFiles(model: 'model.int8.onnx', tokens: 'tokens.txt');

    test('each pause gives the transcript of the speech before it', () async {
      final recognizer = SherpaOfflineRecognizer(ctc, loader: _fakeLoader);
      final events = <RecognizerEvent>[];
      final sub = recognizer.events.listen(events.add);
      await recognizer.start();
      recognizer
        ..acceptAudio(_speech(1))
        ..acceptAudio(_speech(0.5))
        ..endOfSpeech()
        ..acceptAudio(_speech(2))
        ..endOfSpeech()
        // Too short to be speech: dropped, nothing transcribed.
        ..acceptAudio(_speech(0.1))
        ..endOfSpeech();
      await _until(() => events.length >= 2);
      expect(events, everyElement(isA<FinalTranscript>()));
      expect([for (final e in events) e.text], ['ctc 24000', 'ctc 32000']);
      await sub.cancel();
      await recognizer.dispose();
    });

    test('a stretch with no pause is cut near the segment limit', () async {
      final recognizer = SherpaOfflineRecognizer(ctc, loader: _fakeLoader);
      final texts = <String>[];
      final sub = recognizer.events.listen((e) => texts.add(e.text));
      await recognizer.start();
      recognizer.acceptAudio(_speech(30));
      recognizer.endOfSpeech();
      await _until(() => texts.length >= 3);
      final lengths = [for (final t in texts) int.parse(t.split(' ').last)];
      expect(lengths, hasLength(3));
      // Flat audio has no dip: cut at the hard maximum (11 s), never longer.
      for (final n in lengths.take(2)) {
        expect(n, inInclusiveRange(10 * 16000, 11 * 16000));
      }
      // Nothing lost; each cut repeats 0.2 s in the next segment.
      expect(lengths.reduce((a, b) => a + b), 30 * 16000 + 2 * 3200);
      await sub.cancel();
      await recognizer.dispose();
    });

    test('nothing heard gives no event', () async {
      final recognizer = SherpaOfflineRecognizer(ctc, loader: _fakeLoader);
      final texts = <String>[];
      final sub = recognizer.events.listen((e) => texts.add(e.text));
      await recognizer.start();
      recognizer
        ..acceptAudio(Int16List(16000))
        ..endOfSpeech()
        ..acceptAudio(_speech(1))
        ..endOfSpeech();
      await _until(() => texts.isNotEmpty);
      expect(texts, ['ctc 16000']);
      await sub.cancel();
      await recognizer.dispose();
    });

    test('a model that does not load fails start()', () async {
      final recognizer = SherpaOfflineRecognizer(ctc, loader: _failingLoader);
      await expectLater(recognizer.start(), throwsStateError);
    });

    test('a segment that fails is reported on the stream', () async {
      final recognizer = SherpaOfflineRecognizer(ctc, loader: _fakeLoader);
      final errors = <Object>[];
      final sub = recognizer.events.listen((_) {}, onError: errors.add);
      await recognizer.start();
      recognizer
        ..acceptAudio(_speech(7))
        ..endOfSpeech();
      await _until(() => errors.isNotEmpty);
      expect(errors.single, isA<StateError>());
      await sub.cancel();
      await recognizer.dispose();
    });

    test('audio before start() is a mistake', () {
      final recognizer = SherpaOfflineRecognizer(ctc, loader: _fakeLoader);
      expect(() => recognizer.acceptAudio(_speech(1)), throwsStateError);
    });
  });
}

Future<void> _until(bool Function() done) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) fail('timed out');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
