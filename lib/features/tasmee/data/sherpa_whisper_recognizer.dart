import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../domain/recitation_recognizer.dart';
import '../domain/speech_segment_buffer.dart';
import 'model_store.dart';

/// [RecitationRecognizer] on sherpa_onnx running Whisper. Whisper reads a
/// whole stretch of speech at once, so this reports [FinalTranscript]s only:
/// each time the reader pauses ([endOfSpeech]) the audio since the last
/// pause is transcribed. The model runs in its own isolate, so the screen
/// never waits on it.
///
/// Expects the files of the beta model (`manifest.json` of
/// `tarteel-whisper-base-ar-quran`): [encoderFile], [decoderFile] and
/// [tokensFile] in the installed model's folder.
class SherpaWhisperRecognizer implements RecitationRecognizer {
  SherpaWhisperRecognizer(
    this.model, {
    this.language = 'ar',
    this.numThreads = 2,
    this.encoderFile = 'encoder.int8.onnx',
    this.decoderFile = 'decoder.int8.onnx',
    this.tokensFile = 'tokens.txt',
  });

  final InstalledModel model;
  final String language;
  final int numThreads;
  final String encoderFile;
  final String decoderFile;
  final String tokensFile;

  final _events = StreamController<RecognizerEvent>.broadcast();
  final _segments = SpeechSegmentBuffer();

  Isolate? _isolate;
  ReceivePort? _fromWorker;
  SendPort? _toWorker;

  @override
  Stream<RecognizerEvent> get events => _events.stream;

  @override
  Future<void> start() async {
    if (_toWorker != null) return;
    final fromWorker = ReceivePort();
    final ready = Completer<SendPort>();
    fromWorker.listen((message) {
      switch (message) {
        case SendPort port:
          ready.complete(port);
        case String text:
          if (!_events.isClosed) _events.add(FinalTranscript(text));
        case _WorkerFailure failure:
          if (!ready.isCompleted) {
            ready.completeError(StateError(failure.message));
          } else if (!_events.isClosed) {
            _events.addError(StateError(failure.message));
          }
      }
    });
    _fromWorker = fromWorker;
    _isolate = await Isolate.spawn(
      _workerMain,
      _WorkerInit(
        reply: fromWorker.sendPort,
        encoder: model.file(encoderFile).path,
        decoder: model.file(decoderFile).path,
        tokens: model.file(tokensFile).path,
        language: language,
        numThreads: numThreads,
      ),
    );
    try {
      _toWorker = await ready.future;
    } catch (_) {
      await dispose();
      rethrow;
    }
  }

  @override
  void acceptAudio(Int16List pcm) {
    if (_toWorker == null) throw StateError('start() was not called');
    for (final segment in _segments.add(pcm)) {
      _send(segment);
    }
  }

  @override
  void endOfSpeech() {
    final segment = _segments.flush();
    if (segment != null) _send(segment);
  }

  void _send(Int16List segment) {
    _toWorker?.send(TransferableTypedData.fromList([segment]));
  }

  @override
  Future<void> dispose() async {
    _segments.clear();
    _toWorker?.send(null);
    _toWorker = null;
    _fromWorker?.close();
    _fromWorker = null;
    _isolate?.kill();
    _isolate = null;
    if (!_events.isClosed) await _events.close();
  }
}

class _WorkerInit {
  const _WorkerInit({
    required this.reply,
    required this.encoder,
    required this.decoder,
    required this.tokens,
    required this.language,
    required this.numThreads,
  });

  final SendPort reply;
  final String encoder;
  final String decoder;
  final String tokens;
  final String language;
  final int numThreads;
}

class _WorkerFailure {
  const _WorkerFailure(this.message);
  final String message;
}

void _workerMain(_WorkerInit init) {
  final commands = ReceivePort();
  late final sherpa.OfflineRecognizer recognizer;
  try {
    sherpa.initBindings();
    recognizer = sherpa.OfflineRecognizer(
      sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          whisper: sherpa.OfflineWhisperModelConfig(
            encoder: init.encoder,
            decoder: init.decoder,
            language: init.language,
            task: 'transcribe',
          ),
          tokens: init.tokens,
          numThreads: init.numThreads,
          debug: false,
        ),
      ),
    );
  } catch (e) {
    init.reply.send(_WorkerFailure('Could not load the model: $e'));
    return;
  }
  init.reply.send(commands.sendPort);

  commands.listen((message) {
    if (message == null) {
      recognizer.free();
      commands.close();
      return;
    }
    final pcm = (message as TransferableTypedData).materialize().asInt16List();
    final samples = Float32List(pcm.length);
    for (var i = 0; i < pcm.length; i++) {
      samples[i] = pcm[i] / 32768.0;
    }
    final stream = recognizer.createStream();
    try {
      stream.acceptWaveform(
        samples: samples,
        sampleRate: RecitationRecognizer.sampleRate,
      );
      recognizer.decode(stream);
      final text = recognizer.getResult(stream).text.trim();
      if (text.isNotEmpty) init.reply.send(text);
    } catch (e) {
      init.reply.send(_WorkerFailure('Transcription failed: $e'));
    } finally {
      stream.free();
    }
  });
}
