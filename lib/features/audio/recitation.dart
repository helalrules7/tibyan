import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path/path.dart' as p;

import '../../core/db/content_database.dart';
import '../../core/settings/settings_controller.dart';
import '../mushaf/mushaf_providers.dart';

final recitersProvider = FutureProvider<List<ReciterRow>>(
  (ref) => ref.watch(mushafRepositoryProvider).reciters(),
);

/// The verse playing at [ms], or null before the first timed verse.
int? ayahAt(List<AyahTimingRow> timings, int ms) {
  int? found;
  for (final t in timings) {
    if (t.startMs > ms) break;
    found = t.ayah;
  }
  return found;
}

/// The word being recited at [ms] as (verse, word), or null in the
/// silence before the first word. [words] is sorted by start time.
(int, int)? wordAt(List<WordTimingRow> words, int ms) {
  var lo = 0;
  var hi = words.length - 1;
  var found = -1;
  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    if (words[mid].startMs <= ms) {
      found = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  if (found < 0) return null;
  final w = words[found];
  // In the pause after a verse's last word, nothing is being recited.
  if (ms > w.endMs + 400) return null;
  return (w.ayah, w.word);
}

/// Where to jump to shorten the pause after [ayah], or null: once playback
/// ([ms]) is past the verse's speech by half of [keep], it goes to half of
/// [keep] before the next verse's speech, leaving a pause of about [keep]
/// ms. Pauses already that short are left alone. [speech] holds each
/// verse's speech span in ms.
int? pauseJump(Map<int, (int, int)> speech, int ayah, int ms, int keep) {
  final here = speech[ayah];
  final next = speech[ayah + 1];
  if (keep <= 0 || here == null || next == null) return null;
  if (next.$1 - here.$2 <= keep + 250) return null;
  if (ms < here.$2 + keep ~/ 2 || ms >= next.$1 - keep ~/ 2) return null;
  return next.$1 - keep ~/ 2;
}

String surahFile(int surah) => '${surah.toString().padLeft(3, '0')}.mp3';

/// Tibyan's mirror of the recitations, laid out like mp3quran's servers.
const recitationMirror =
    'https://tibyan.ahmedhelal.dev/mirror/sources/recitations';

/// Where a surah file can be fetched, in order: Tibyan's mirror first
/// (faster), then mp3quran itself.
List<Uri> surahUrls(ReciterRow reciter, int surah) {
  final source = Uri.parse('${reciter.folderUrl}${surahFile(surah)}');
  return [Uri.parse('$recitationMirror${source.path}'), source];
}

/// Surah files kept on the device, under `<app support>/audio/<reciter>/`.
class AudioFiles {
  AudioFiles(this.root);

  final Directory root;

  File file(int reciter, int surah) =>
      File(p.join(root.path, 'audio', '$reciter', surahFile(surah)));

  bool has(int reciter, int surah) => file(reciter, surah).existsSync();

  Set<int> downloaded(int reciter) {
    final dir = Directory(p.join(root.path, 'audio', '$reciter'));
    if (!dir.existsSync()) return {};
    return {
      for (final f in dir.listSync())
        if (f.path.endsWith('.mp3'))
          ?int.tryParse(p.basenameWithoutExtension(f.path)),
    };
  }

  /// Downloads one surah, resuming a partial file. The file only gets its
  /// final name once the whole of it has arrived.
  Future<void> download(
    ReciterRow reciter,
    int surah, {
    http.Client? client,
  }) async {
    final target = file(reciter.id, surah);
    if (target.existsSync()) return;
    target.parent.createSync(recursive: true);
    final part = File('${target.path}.part');
    final have = part.existsSync() ? part.lengthSync() : 0;
    final c = client ?? http.Client();
    try {
      // The mirror first, then the source; both serve the same bytes, so
      // a partial file resumes from either.
      http.StreamedResponse? response;
      Object? lastError;
      for (final url in surahUrls(reciter, surah)) {
        try {
          final request = http.Request('GET', url);
          if (have > 0) request.headers['Range'] = 'bytes=$have-';
          final r = await c.send(request);
          if (r.statusCode == 200 || r.statusCode == 206) {
            response = r;
            break;
          }
          lastError = HttpException('HTTP ${r.statusCode}');
        } on Exception catch (e) {
          lastError = e;
        }
      }
      if (response == null) throw lastError ?? const HttpException('No source');
      final sink = part.openWrite(
        mode: response.statusCode == 206 ? FileMode.append : FileMode.write,
      );
      await response.stream.pipe(sink);
      final expected = response.contentLength;
      final got = part.lengthSync();
      if (expected != null &&
          got != (response.statusCode == 206 ? have : 0) + expected) {
        throw const HttpException('Incomplete download');
      }
      part.renameSync(target.path);
    } finally {
      if (client == null) c.close();
    }
  }

  void delete(int reciter, int surah) {
    final f = file(reciter, surah);
    if (f.existsSync()) f.deleteSync();
  }
}

final audioFilesProvider = Provider<AudioFiles>(
  (ref) => AudioFiles(ref.watch(packRootProvider)),
);

/// When the sleep timer stops the recitation.
sealed class SleepTimer {
  const SleepTimer();
}

class SleepAfter extends SleepTimer {
  const SleepAfter(this.duration);
  final Duration duration;
}

class SleepAtSurahEnd extends SleepTimer {
  const SleepAtSurahEnd();
}

class RecitationState {
  const RecitationState({
    this.active = false,
    this.playing = false,
    this.loading = false,
    this.surah = 1,
    this.ayah,
    this.word,
    this.timed = false,
    this.rangeFrom,
    this.rangeTo,
    this.repeat = 1,
    this.repeatDone = 0,
    this.silence = Duration.zero,
    this.sleep,
    this.error,
  });

  /// The player bar is shown.
  final bool active;
  final bool playing;
  final bool loading;
  final int surah;

  /// The verse being recited; null when the file has no timing.
  final int? ayah;

  /// The word being recited in [ayah] (1-based, as in the word boxes);
  /// null when the recitation has no word timing.
  final int? word;

  /// Whether this surah file has verse timings (highlight, repeat).
  final bool timed;

  /// A chosen stretch of the surah to repeat; null plays on to the end.
  final int? rangeFrom;
  final int? rangeTo;

  /// Times to play the stretch; 0 repeats until stopped.
  final int repeat;
  final int repeatDone;

  /// Silence between repetitions, for repeating after the reciter.
  final Duration silence;
  final SleepTimer? sleep;
  final String? error;

  RecitationState copyWith({
    bool? active,
    bool? playing,
    bool? loading,
    int? surah,
    int? Function()? ayah,
    int? Function()? word,
    bool? timed,
    int? Function()? rangeFrom,
    int? Function()? rangeTo,
    int? repeat,
    int? repeatDone,
    Duration? silence,
    SleepTimer? Function()? sleep,
    String? Function()? error,
  }) => RecitationState(
    active: active ?? this.active,
    playing: playing ?? this.playing,
    loading: loading ?? this.loading,
    surah: surah ?? this.surah,
    ayah: ayah == null ? this.ayah : ayah(),
    word: word == null ? this.word : word(),
    timed: timed ?? this.timed,
    rangeFrom: rangeFrom == null ? this.rangeFrom : rangeFrom(),
    rangeTo: rangeTo == null ? this.rangeTo : rangeTo(),
    repeat: repeat ?? this.repeat,
    repeatDone: repeatDone ?? this.repeatDone,
    silence: silence ?? this.silence,
    sleep: sleep == null ? this.sleep : sleep(),
    error: error == null ? this.error : error(),
  );
}

final recitationProvider =
    NotifierProvider<RecitationController, RecitationState>(
      RecitationController.new,
    );

/// Plays one surah file at a time from mp3quran.net (or its downloaded
/// copy), follows the verse being recited using the published timings,
/// repeats a stretch with silence between, and moves on to the next surah.
class RecitationController extends Notifier<RecitationState> {
  AudioPlayer? _player;
  List<AyahTimingRow> _timings = const [];
  List<WordTimingRow> _words = const [];

  /// Speech span of each verse (ms), for shortening the pauses.
  Map<int, (int, int)> _speech = const {};

  /// A jump over a long pause is under way, to [_jumpTo] ms.
  int? _jumpTo;
  final _subs = <StreamSubscription<Object?>>[];
  Timer? _sleepTimer;
  bool _inSilence = false;

  AudioPlayer get _p => _player ??= _create();

  AudioPlayer _create() {
    final player = AudioPlayer();
    _subs
      ..add(
        player
            .createPositionStream(
              minPeriod: const Duration(milliseconds: 60),
              maxPeriod: const Duration(milliseconds: 120),
            )
            .listen(_onPosition),
      )
      ..add(player.playerStateStream.listen(_onPlayerState));
    return player;
  }

  @override
  RecitationState build() {
    ref.onDispose(() {
      for (final s in _subs) {
        s.cancel();
      }
      _sleepTimer?.cancel();
      _player?.dispose();
    });
    return const RecitationState();
  }

  int get _reciterId => ref.read(settingsProvider).reciterId;

  /// Starts reciting [surah] at [from] (the whole surah when null). With
  /// [to], only [from]..[to] plays, [repeat] times.
  Future<void> play(
    int surah, {
    int? from,
    int? to,
    int repeat = 1,
    Duration? silence,
  }) async {
    final reciters = await ref.read(recitersProvider.future);
    final reciter = reciters.firstWhere(
      (r) => r.id == _reciterId,
      orElse: () => reciters.first,
    );
    final repo = ref.read(mushafRepositoryProvider);
    _timings = await repo.timings(reciter.id, surah);
    _words = _timings.isEmpty
        ? const []
        : await repo.wordTimings(reciter.id, surah);
    _speech = {
      for (final s in await repo.speech(reciter.id, surah))
        s.ayah: (s.startMs, s.endMs),
    };
    _jumpTo = null;
    final timed = _timings.isNotEmpty;
    final surahRow = (await ref.read(surahsProvider.future))[surah - 1];
    state = state.copyWith(
      active: true,
      loading: true,
      surah: surah,
      ayah: () => timed ? (from ?? 1) : null,
      word: () => null,
      timed: timed,
      rangeFrom: () => timed && to != null ? from ?? 1 : null,
      rangeTo: () => timed ? to : null,
      repeat: repeat,
      repeatDone: 0,
      silence: silence ?? state.silence,
      error: () => null,
    );
    final files = ref.read(audioFilesProvider);
    final local = files.file(reciter.id, surah);
    // A downloaded copy, else the mirror, else mp3quran itself.
    final uris = local.existsSync() ? [local.uri] : surahUrls(reciter, surah);
    Object? error;
    for (final uri in uris) {
      try {
        await _p.setAudioSource(
          AudioSource.uri(
            uri,
            tag: MediaItem(
              id: '${reciter.id}/$surah',
              title: surahRow.nameAr,
              artist: reciter.nameAr,
              album: 'تبيان',
            ),
          ),
          initialPosition: _startOf(from),
        );
        state = state.copyWith(loading: false);
        unawaited(_p.play());
        return;
      } catch (e) {
        error = e;
      }
    }
    state = state.copyWith(loading: false, error: () => error.toString());
  }

  /// Where [ayah] starts; verse 1 (or none) starts at the top of the file
  /// so the opening before it is heard.
  Duration _startOf(int? ayah) {
    if (ayah == null || ayah <= 1 || _timings.isEmpty) return Duration.zero;
    for (final t in _timings) {
      if (t.ayah == ayah) return Duration(milliseconds: t.startMs);
    }
    return Duration.zero;
  }

  int? _endOf(int ayah) {
    for (final t in _timings) {
      if (t.ayah == ayah) return t.endMs;
    }
    return null;
  }

  void _onPosition(Duration position) {
    if (!state.active || _inSilence || _timings.isEmpty) return;
    final ms = position.inMilliseconds;
    final keep = ref.read(settingsProvider).versePause;
    final to = state.rangeTo;
    if (to != null) {
      // With shorter pauses, a stretch ends a moment after its speech.
      final spoken = keep > 0 ? _speech[to] : null;
      final end = spoken == null ? _endOf(to) : spoken.$2 + keep;
      if (end != null && ms >= end - 40) {
        _endOfRange();
        return;
      }
    }
    final ayah = ayahAt(_timings, ms);
    if (keep > 0) _shortenPause(ayah, ms, keep);
    final w = _words.isEmpty ? null : wordAt(_words, ms);
    final word = w != null && w.$1 == ayah ? w.$2 : null;
    if ((ayah != null && ayah > 0 && ayah != state.ayah) ||
        word != state.word) {
      state = state.copyWith(
        ayah: () => ayah != null && ayah > 0 ? ayah : state.ayah,
        word: () => word,
      );
    }
  }

  /// Reciters leave long silences between verses. Past the end of a
  /// verse's speech, jump to just before the next verse's speech, leaving a
  /// pause of about [keep] ms.
  void _shortenPause(int? ayah, int ms, int keep) {
    final jump = _jumpTo;
    if (jump != null) {
      if (ms >= jump - 50) _jumpTo = null;
      return;
    }
    if (ayah == null || ayah <= 0 || state.rangeTo == ayah) return;
    final target = pauseJump(_speech, ayah, ms, keep);
    if (target == null) return;
    _jumpTo = target;
    unawaited(_p.seek(Duration(milliseconds: target)));
  }

  Future<void> _endOfRange() async {
    final done = state.repeatDone + 1;
    final forever = state.repeat == 0;
    if (!forever && done >= state.repeat) {
      await _p.pause();
      state = state.copyWith(repeatDone: done);
      return;
    }
    _inSilence = true;
    await _p.pause();
    state = state.copyWith(repeatDone: done);
    if (state.silence > Duration.zero) {
      await Future<void>.delayed(state.silence);
    }
    if (!state.active) {
      _inSilence = false;
      return;
    }
    await _p.seek(_startOf(state.rangeFrom));
    state = state.copyWith(ayah: () => state.rangeFrom);
    _inSilence = false;
    unawaited(_p.play());
  }

  void _onPlayerState(PlayerState s) {
    if (state.playing != s.playing) {
      state = state.copyWith(playing: s.playing);
    }
    if (s.processingState == ProcessingState.completed && state.active) {
      _onSurahEnd();
    }
  }

  Future<void> _onSurahEnd() async {
    if (state.rangeTo != null && _timings.isNotEmpty) return;
    if (state.sleep is SleepAtSurahEnd || state.surah >= 114) {
      await _p.pause();
      await _p.seek(Duration.zero);
      state = state.copyWith(sleep: () => null);
      return;
    }
    await play(state.surah + 1);
  }

  Future<void> toggle() async {
    if (!state.active) return;
    if (_p.playing) {
      await _p.pause();
    } else {
      if (_p.processingState == ProcessingState.completed) {
        await _p.seek(_startOf(state.rangeFrom));
        state = state.copyWith(repeatDone: 0);
      }
      unawaited(_p.play());
    }
  }

  /// Moves to the previous or next verse (timed files only).
  Future<void> step(int delta) async {
    final current = state.ayah;
    if (!state.timed || current == null) return;
    final target = current + delta;
    if (target < 1 || _endOf(target) == null) return;
    await _p.seek(_startOf(target));
    state = state.copyWith(ayah: () => target);
  }

  void setRepeat(int times) => state = state.copyWith(repeat: times);

  void setSilence(Duration d) => state = state.copyWith(silence: d);

  /// Repeats only the verse being recited.
  void repeatCurrentVerse() {
    final a = state.ayah;
    if (!state.timed || a == null) return;
    state = state.copyWith(rangeFrom: () => a, rangeTo: () => a, repeatDone: 0);
  }

  /// Plays on to the end of the surah again.
  void clearRange() => state = state.copyWith(
    rangeFrom: () => null,
    rangeTo: () => null,
    repeatDone: 0,
  );

  void setSleep(SleepTimer? timer) {
    _sleepTimer?.cancel();
    state = state.copyWith(sleep: () => timer);
    if (timer is SleepAfter) {
      _sleepTimer = Timer(timer.duration, () async {
        await _player?.pause();
        state = state.copyWith(sleep: () => null);
      });
    }
  }

  Future<void> stop() async {
    _sleepTimer?.cancel();
    await _player?.stop();
    state = const RecitationState().copyWith(silence: state.silence, repeat: 1);
  }
}
