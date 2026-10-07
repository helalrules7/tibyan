import 'dart:typed_data';

import 'transcript_stabilizer.dart';

/// What a recogniser reports while audio comes in.
sealed class RecognizerEvent {
  const RecognizerEvent(this.text);

  /// The words heard, as the recogniser wrote them.
  final String text;
}

/// The whole transcript of the current stretch of speech so far; it may
/// change with the next event (a recogniser that streams).
class PartialTranscript extends RecognizerEvent {
  const PartialTranscript(super.text);
}

/// The stretch of speech ended: [text] will not change. A recogniser that
/// only transcribes finished chunks (Whisper) reports nothing but these.
class FinalTranscript extends RecognizerEvent {
  const FinalTranscript(super.text);
}

/// Turns speech into text on the device. The rest of the feature depends on
/// this and nothing else, so the model or the engine behind it (sherpa_onnx,
/// whisper.cpp) can be swapped without touching the alignment or the screen.
///
/// Audio is mono PCM at [sampleRate]. Nothing is written to disk: the audio
/// lives only in memory until it is transcribed.
abstract interface class RecitationRecognizer {
  static const sampleRate = 16000;

  /// Loads the model; call once before [acceptAudio].
  Future<void> start();

  /// Feeds the next stretch of audio (16-bit samples, in order).
  void acceptAudio(Int16List pcm);

  /// The reader paused or the verse ended: finish the current stretch of
  /// speech (it comes out as a [FinalTranscript]).
  void endOfSpeech();

  Stream<RecognizerEvent> get events;

  /// Frees the model and stops the events.
  Future<void> dispose();
}

/// The words that are settled, in order, ready for `TasmeeEngine.addWords`:
/// partial transcripts go through a [TranscriptStabilizer] (a word counts
/// once it stays the same in [agreement] transcripts in a row), a final
/// transcript settles all that is left of its stretch.
Stream<List<String>> settledWords(
  Stream<RecognizerEvent> events, {
  int agreement = 2,
}) async* {
  final stabilizer = TranscriptStabilizer(agreement: agreement);
  await for (final event in events) {
    final words = switch (event) {
      PartialTranscript(:final text) => stabilizer.update(text),
      FinalTranscript(:final text) => stabilizer.finish(text),
    };
    if (words.isNotEmpty) yield words;
  }
}
