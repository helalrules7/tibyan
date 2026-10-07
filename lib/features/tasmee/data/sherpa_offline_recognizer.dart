import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../domain/recitation_recognizer.dart';
import '../domain/speech_segment_buffer.dart';
import 'model_manifest.dart';
import 'model_store.dart';

/// The files a sherpa_onnx offline model is loaded from: plain paths, so
/// they can be handed to the worker isolate.
sealed class SherpaModelFiles {
  const SherpaModelFiles({required this.tokens});

  final String tokens;

  /// The files of [model], by the engine its manifest names. The beta model
  /// is a NeMo CTC model; Whisper is kept only to compare recognisers.
  factory SherpaModelFiles.of(InstalledModel model) {
    String path(String name) {
      if (!model.manifest.files.any((f) => f.name == name)) {
        throw UnsupportedError(
          'The model ${model.manifest.id} has no file $name',
        );
      }
      return model.file(name).path;
    }

    return switch (model.manifest.engine) {
      ModelEngine.sherpaNemoCtc => NemoCtcFiles(
        model: path(NemoCtcFiles.modelFile),
        tokens: path(NemoCtcFiles.tokensFile),
      ),
      ModelEngine.sherpaWhisper => WhisperFiles(
        encoder: path(WhisperFiles.encoderFile),
        decoder: path(WhisperFiles.decoderFile),
        tokens: path(WhisperFiles.tokensFile),
      ),
      final other => throw UnsupportedError('No recogniser for $other'),
    };
  }
}

/// A NeMo CTC model (the CTC branch of a FastConformer), int8.
final class NemoCtcFiles extends SherpaModelFiles {
  const NemoCtcFiles({required this.model, required super.tokens});

  static const modelFile = 'model.int8.onnx';
  static const tokensFile = 'tokens.txt';

  final String model;
}

/// Whisper (encoder and decoder), int8. sherpa_onnx caps Whisper's output
/// at about 6 tokens a second of audio, which cuts the end of a recitation
/// written with vowel marks: for comparison only.
final class WhisperFiles extends SherpaModelFiles {
  const WhisperFiles({
    required this.encoder,
    required this.decoder,
    required super.tokens,
    this.language = 'ar',
  });

  static const encoderFile = 'encoder.int8.onnx';
  static const decoderFile = 'decoder.int8.onnx';
  static const tokensFile = 'tokens.txt';

  final String encoder;
  final String decoder;
  final String language;
}

/// Turns one segment of speech into text. Lives in the worker isolate.
abstract interface class SegmentTranscriber {
  String transcribe(Float32List samples);
  void free();
}

/// Loads a [SegmentTranscriber] inside the worker isolate. Must be a
/// top-level or static function (it is sent to the isolate).
typedef TranscriberLoader = SegmentTranscriber Function(
  SherpaModelFiles files,
  int numThreads,
);

/// [RecitationRecognizer] on a sherpa_onnx offline model (NeMo CTC for the
/// beta, or Whisper). The model reads a whole stretch of speech at once, so
/// this reports [FinalTranscript]s only: each time the reader pauses
/// ([endOfSpeech], from the capture's voice activity detection) the audio
/// since the last pause is transcribed; a stretch longer than the
/// [SpeechSegmentBuffer] limit is cut there. The model runs in its own
/// isolate, so the screen never waits on it.
class SherpaOfflineRecognizer implements RecitationRecognizer {
  SherpaOfflineRecognizer(
    this.files, {
    this.numThreads = 2,
    TranscriberLoader? loader,
  }) : _loader = loader ?? loadSherpaTranscriber;

  /// The recogniser for an installed model, by its manifest's engine.
  factory SherpaOfflineRecognizer.forModel(InstalledModel model) =>
      SherpaOfflineRecognizer(SherpaModelFiles.of(model));

  final SherpaModelFiles files;
  final int numThreads;
  final TranscriberLoader _loader;

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
        files: files,
        numThreads: numThreads,
        load: _loader,
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

/// The real [TranscriberLoader]: a sherpa_onnx [sherpa.OfflineRecognizer].
SegmentTranscriber loadSherpaTranscriber(
  SherpaModelFiles files,
  int numThreads,
) {
  sherpa.initBindings();
  final model = switch (files) {
    NemoCtcFiles(:final model, :final tokens) => sherpa.OfflineModelConfig(
      nemoCtc: sherpa.OfflineNemoEncDecCtcModelConfig(model: model),
      tokens: tokens,
      numThreads: numThreads,
      debug: false,
    ),
    WhisperFiles(
      :final encoder,
      :final decoder,
      :final language,
      :final tokens,
    ) =>
      sherpa.OfflineModelConfig(
        whisper: sherpa.OfflineWhisperModelConfig(
          encoder: encoder,
          decoder: decoder,
          language: language,
          task: 'transcribe',
        ),
        tokens: tokens,
        numThreads: numThreads,
        debug: false,
      ),
  };
  return _SherpaTranscriber(
    sherpa.OfflineRecognizer(sherpa.OfflineRecognizerConfig(model: model)),
  );
}

class _SherpaTranscriber implements SegmentTranscriber {
  _SherpaTranscriber(this._recognizer);

  final sherpa.OfflineRecognizer _recognizer;

  @override
  String transcribe(Float32List samples) {
    final stream = _recognizer.createStream();
    try {
      stream.acceptWaveform(
        samples: samples,
        sampleRate: RecitationRecognizer.sampleRate,
      );
      _recognizer.decode(stream);
      return _recognizer.getResult(stream).text;
    } finally {
      stream.free();
    }
  }

  @override
  void free() => _recognizer.free();
}

class _WorkerInit {
  const _WorkerInit({
    required this.reply,
    required this.files,
    required this.numThreads,
    required this.load,
  });

  final SendPort reply;
  final SherpaModelFiles files;
  final int numThreads;
  final TranscriberLoader load;
}

class _WorkerFailure {
  const _WorkerFailure(this.message);
  final String message;
}

void _workerMain(_WorkerInit init) {
  final commands = ReceivePort();
  late final SegmentTranscriber transcriber;
  try {
    transcriber = init.load(init.files, init.numThreads);
  } catch (e) {
    init.reply.send(_WorkerFailure('Could not load the model: $e'));
    return;
  }
  init.reply.send(commands.sendPort);

  commands.listen((message) {
    if (message == null) {
      transcriber.free();
      commands.close();
      return;
    }
    final pcm = (message as TransferableTypedData).materialize().asInt16List();
    final samples = Float32List(pcm.length);
    for (var i = 0; i < pcm.length; i++) {
      samples[i] = pcm[i] / 32768.0;
    }
    try {
      final text = transcriber.transcribe(samples).trim();
      if (text.isNotEmpty) init.reply.send(text);
    } catch (e) {
      init.reply.send(_WorkerFailure('Transcription failed: $e'));
    }
  });
}
