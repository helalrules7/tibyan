import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import '../domain/recitation_recognizer.dart';
import '../domain/speech_activity_detector.dart';

typedef PcmCallback = void Function(Int16List samples);
typedef AudioLevelCallback = void Function(double rms);
typedef SpeechEndedCallback = void Function();
typedef AudioErrorCallback = void Function(Object error, StackTrace stack);

/// The user (or the system) refused microphone access.
class MicrophonePermissionDenied implements Exception {
  const MicrophonePermissionDenied();

  @override
  String toString() => 'Microphone permission was not granted';
}

/// Captures mono 16 kHz PCM in memory and forwards speech segments to the
/// recognizer. It never creates a recording file.
class TasmeeAudioCapture {
  TasmeeAudioCapture({
    AudioRecorder? recorder,
    SpeechActivityDetector? detector,
  }) : _recorder = recorder ?? AudioRecorder(),
       _detector = detector ?? SpeechActivityDetector();

  final AudioRecorder _recorder;
  final SpeechActivityDetector _detector;
  final List<int> _pendingBytes = [];
  final List<int> _pendingSamples = [];

  StreamSubscription<Uint8List>? _subscription;
  PcmCallback? _onPcm;
  AudioLevelCallback? _onLevel;
  SpeechEndedCallback? _onSpeechEnded;
  AudioErrorCallback? _onError;

  /// Every captured frame, speech or not (the panel's spectrum).
  PcmCallback? _onFrame;
  bool _disposed = false;
  bool _running = false;
  DateTime _lastLevelNotification = DateTime.fromMillisecondsSinceEpoch(0);

  bool get isRunning => _running;

  Future<void> start({
    required PcmCallback onPcm,
    required AudioLevelCallback onLevel,
    required SpeechEndedCallback onSpeechEnded,
    required AudioErrorCallback onError,
    PcmCallback? onFrame,
  }) async {
    if (_disposed) throw StateError('Audio capture has been disposed');
    if (_running) return;
    if (!await _recorder.hasPermission()) {
      throw const MicrophonePermissionDenied();
    }
    if (!await _recorder.isEncoderSupported(AudioEncoder.pcm16bits)) {
      throw UnsupportedError('16 kHz PCM capture is not supported');
    }

    _onPcm = onPcm;
    _onLevel = onLevel;
    _onSpeechEnded = onSpeechEnded;
    _onError = onError;
    _onFrame = onFrame;
    _detector.reset();
    _pendingBytes.clear();
    _pendingSamples.clear();
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: RecitationRecognizer.sampleRate,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      ),
    );
    _running = true;
    _subscription = stream.listen(
      _consume,
      onError: (Object error, StackTrace stack) {
        _running = false;
        _onError?.call(error, stack);
      },
      onDone: () {
        _running = false;
      },
      cancelOnError: true,
    );
  }

  Future<void> stop() async {
    if (!_running) return;
    await _recorder.stop();
    await _subscription?.cancel();
    _subscription = null;
    _running = false;
    if (_detector.finish()) _onSpeechEnded?.call();
    _pendingBytes.clear();
    _pendingSamples.clear();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await stop();
    } finally {
      await _recorder.dispose();
      _onPcm = null;
      _onLevel = null;
      _onSpeechEnded = null;
      _onError = null;
      _onFrame = null;
    }
  }

  void _consume(Uint8List bytes) {
    _pendingBytes.addAll(bytes);
    var offset = 0;
    while (offset + 1 < _pendingBytes.length) {
      final sample = _pendingBytes[offset] | (_pendingBytes[offset + 1] << 8);
      _pendingSamples.add(sample >= 0x8000 ? sample - 0x10000 : sample);
      offset += 2;
    }
    if (offset > 0) _pendingBytes.removeRange(0, offset);

    final frameSize = _detector.frameSamples;
    while (_pendingSamples.length >= frameSize) {
      final frame = Int16List.fromList(_pendingSamples.sublist(0, frameSize));
      _pendingSamples.removeRange(0, frameSize);
      _onFrame?.call(frame);
      final result = _detector.addFrame(frame);
      final now = DateTime.now();
      if (now.difference(_lastLevelNotification).inMilliseconds >= 80) {
        _lastLevelNotification = now;
        _onLevel?.call(result.level);
      }
      for (final audio in result.audio) {
        _onPcm?.call(audio);
      }
      if (result.speechEnded) _onSpeechEnded?.call();
    }
  }
}
