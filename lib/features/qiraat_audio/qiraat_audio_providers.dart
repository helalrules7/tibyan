import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/flags/feature_flags.dart';
import '../audio/recitation.dart';
import 'qiraat_audio_index.dart';

/// Where the reviewed index is read: the repository's main branch, where
/// word ranges arrive only after review (docs/QIRAAT_AUDIO.md).
const qiraatAudioIndexBaseUrl =
    'https://raw.githubusercontent.com/helalrules7/tibyan/main/data/qiraat_audio/index/';

/// A surah's index file is a few hundred clips; anything far larger is
/// refused.
const _maxIndexBytes = 4 * 1024 * 1024;

/// Reads one surah's index file; tests put a fake in its place.
abstract class QiraatAudioIndexSource {
  /// The file's text, or null when the surah has none or it cannot be read.
  Future<String?> surah(int surah);
}

class HttpQiraatAudioIndexSource implements QiraatAudioIndexSource {
  HttpQiraatAudioIndexSource(
    this._client, {
    this.baseUrl = qiraatAudioIndexBaseUrl,
  });

  final http.Client _client;
  final String baseUrl;

  @override
  Future<String?> surah(int surah) async {
    if (surah < 1 || surah > 114) return null;
    try {
      final name = surah.toString().padLeft(3, '0');
      final r = await _client
          .get(Uri.parse('$baseUrl$name.json'))
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200 || r.bodyBytes.length > _maxIndexBytes) {
        return null;
      }
      return utf8.decode(r.bodyBytes);
    } on Exception {
      return null;
    }
  }
}

final qiraatAudioIndexSourceProvider = Provider<QiraatAudioIndexSource>(
  (ref) => HttpQiraatAudioIndexSource(ref.watch(audioHttpClientProvider)),
);

/// The verse-level qiraat clips of a surah, or null: the `qiraat_audio`
/// flag is off (the default), or the surah has no clips.
final qiraatAudioSurahProvider = FutureProvider.family<QiraatAudioSurah?, int>((
  ref,
  surah,
) async {
  if (!ref.watch(featureFlagsProvider).isOn(Feature.qiraatAudio)) return null;
  final text = await ref.watch(qiraatAudioIndexSourceProvider).surah(surah);
  return text == null ? null : QiraatAudioSurah.parse(text, surah);
});

/// What to play for a verse in a style (and word, when one is asked), or
/// null when the flag is off or there is no playable clip.
final qiraatPlaybackProvider =
    FutureProvider.family<QiraatPlayback?, (int, int, String, int?)>((
      ref,
      key,
    ) async {
      final (surah, ayah, style, word) = key;
      final index = await ref.watch(qiraatAudioSurahProvider(surah).future);
      return index?.playback(ayah, style, word: word);
    });
