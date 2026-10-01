import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
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

/// Where a reciter's surah files are: [ReciterRow.folderUrl] with `NNN.mp3`
/// after it, or, when it holds `{surah}`, that replaced by the number
/// (quranicaudio names them `1.mp3`..`114.mp3`). See `surah_url` in
/// `tools/build_content_db.py`, which writes the column.
String surahUrl(ReciterRow reciter, int surah) =>
    reciter.folderUrl.contains('{surah}')
    ? reciter.folderUrl.replaceAll('{surah}', '$surah')
    : '${reciter.folderUrl}${surahFile(surah)}';

/// Tibyan's mirror of the recitations, laid out like mp3quran's servers.
const recitationMirror =
    'https://tibyan.ahmedhelal.dev/mirror/sources/recitations';

/// Where a surah file can be fetched: Tibyan's mirror, then the source
/// (mp3quran itself); the source first when [sourceFirst].
List<Uri> surahUrls(ReciterRow reciter, int surah, {bool sourceFirst = false}) {
  final source = Uri.parse(surahUrl(reciter, surah));
  final mirror = Uri.parse('$recitationMirror${source.path}');
  return sourceFirst ? [source, mirror] : [mirror, source];
}

/// Surah files kept on the device, under `<app support>/audio/<reciter>/`:
/// those the reader downloads and those saved while listening, alike.
class AudioFiles {
  AudioFiles(this.root);

  final Directory root;

  /// Downloads under way, by `reciter/surah`; a second request for the same
  /// file joins the first instead of writing the same partial file.
  final _running = <String, Future<void>>{};

  /// Bumped whenever a download starts or ends, for screens to follow.
  final changes = ValueNotifier<int>(0);

  File file(int reciter, int surah) =>
      File(p.join(root.path, 'audio', '$reciter', surahFile(surah)));

  bool has(int reciter, int surah) => file(reciter, surah).existsSync();

  bool downloading(int reciter, int surah) =>
      _running.containsKey('$reciter/$surah');

  Set<int> downloaded(int reciter) {
    final dir = Directory(p.join(root.path, 'audio', '$reciter'));
    if (!dir.existsSync()) return {};
    return {
      for (final f in dir.listSync())
        if (f.path.endsWith('.mp3'))
          ?int.tryParse(p.basenameWithoutExtension(f.path)),
    };
  }

  /// Downloads one surah from [urls] (by default the mirror, then the
  /// source), resuming a partial file. The file only gets its final name
  /// once the whole of it has arrived.
  Future<void> download(
    ReciterRow reciter,
    int surah, {
    http.Client? client,
    List<Uri>? urls,
  }) {
    final key = '${reciter.id}/$surah';
    final running = _running[key];
    if (running != null) return running;
    final job = _download(reciter, surah, client, urls);
    _running[key] = job;
    changes.value++;
    return job.whenComplete(() {
      _running.remove(key);
      changes.value++;
    });
  }

  Future<void> _download(
    ReciterRow reciter,
    int surah,
    http.Client? client,
    List<Uri>? urls,
  ) async {
    final target = file(reciter.id, surah);
    if (target.existsSync()) return;
    target.parent.createSync(recursive: true);
    final part = File('${target.path}.part');
    final have = part.existsSync() ? part.lengthSync() : 0;
    final c = client ?? http.Client();
    try {
      // Both hosts serve the same bytes, so a partial file resumes from
      // either.
      http.StreamedResponse? response;
      Object? lastError;
      for (final url in urls ?? surahUrls(reciter, surah)) {
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
    changes.value++;
  }
}

/// The faster of the two hosts of a recitation, for this reader.
enum AudioHost { mirror, source }

/// Races a small ranged request ([bytes] long) to [mirror] and [source]
/// and returns the host that delivered it first, or null when neither did
/// within [timeout] (both failed, or the network is too slow to tell).
Future<AudioHost?> fasterHost(
  http.Client client, {
  required Uri mirror,
  required Uri source,
  Duration timeout = const Duration(seconds: 4),
  int bytes = 32 * 1024,
}) {
  Future<AudioHost> probe(AudioHost host, Uri uri) async {
    final request = http.Request('GET', uri)
      ..headers['Range'] = 'bytes=0-${bytes - 1}';
    final response = await client.send(request);
    if (response.statusCode != 200 && response.statusCode != 206) {
      throw HttpException('HTTP ${response.statusCode}');
    }
    var got = 0;
    // A host that ignores the range sends the whole file: stop at [bytes].
    await for (final chunk in response.stream) {
      got += chunk.length;
      if (got >= bytes) break;
    }
    return host;
  }

  final winner = Completer<AudioHost?>();
  var failed = 0;
  for (final (host, uri) in [
    (AudioHost.mirror, mirror),
    (AudioHost.source, source),
  ]) {
    probe(host, uri).then(
      (h) {
        if (!winner.isCompleted) winner.complete(h);
      },
      onError: (Object _) {
        if (++failed == 2 && !winner.isCompleted) winner.complete(null);
      },
    );
  }
  final timer = Timer(timeout, () {
    if (!winner.isCompleted) winner.complete(null);
  });
  return winner.future.whenComplete(timer.cancel);
}

/// The HTTP client of the recitation (host tests, saving while listening).
final audioHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final audioHostsProvider = NotifierProvider<AudioHosts, Map<String, AudioHost>>(
  AudioHosts.new,
);

/// Which host serves each source server (by host name) faster, measured
/// once a session with [fasterHost]. Until it is known, the mirror comes
/// first; the other host is always kept as the fallback.
class AudioHosts extends Notifier<Map<String, AudioHost>> {
  final _measuring = <String>{};

  @override
  Map<String, AudioHost> build() => const {};

  /// Where to fetch [surah] of [reciter], the faster host first.
  List<Uri> urls(ReciterRow reciter, int surah) => surahUrls(
    reciter,
    surah,
    sourceFirst: state[_host(reciter)] == AudioHost.source,
  );

  static String _host(ReciterRow r) =>
      // The folder may carry the `{surah}` placeholder: give it a value so
      // the URL parses.
      Uri.parse(surahUrl(r, 1)).host;

  /// Measures the hosts of [reciter] unless already known or under way.
  /// Nothing waits for it; a failed or timed-out test is tried again the
  /// next time.
  Future<void> measure(ReciterRow reciter) async {
    final host = _host(reciter);
    if (state.containsKey(host) || !_measuring.add(host)) return;
    try {
      final urls = surahUrls(reciter, 1);
      final faster = await fasterHost(
        ref.read(audioHttpClientProvider),
        mirror: urls.first,
        source: urls.last,
      );
      if (faster != null && ref.mounted) state = {...state, host: faster};
    } catch (_) {
      // Keep the usual order.
    } finally {
      _measuring.remove(host);
    }
  }
}

/// On start: measure the hosts of the chosen recitation, in the background.
Future<void> measureAudioHosts(ProviderContainer container) async {
  try {
    final reciters = await container.read(recitersProvider.future);
    final id = container.read(settingsProvider).reciterId;
    final reciter = reciters.where((r) => r.id == id).firstOrNull;
    if (reciter != null) {
      await container.read(audioHostsProvider.notifier).measure(reciter);
    }
  } catch (_) {
    // Measured again when listening starts.
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

/// The parts of the audio player the recitation uses; tests put a fake in
/// its place.
abstract class RecitationAudio {
  Stream<Duration> get positions;
  Stream<PlayerState> get states;
  ProcessingState get processingState;

  /// Loads [uri], ready to play at [initial].
  Future<void> load(Uri uri, MediaItem tag, Duration initial);

  /// Starts playing; the future ends when playback stops.
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();
  Future<void> dispose();
}

class _JustAudio implements RecitationAudio {
  final _p = AudioPlayer();

  @override
  Stream<Duration> get positions => _p.createPositionStream(
    minPeriod: const Duration(milliseconds: 60),
    maxPeriod: const Duration(milliseconds: 120),
  );

  @override
  Stream<PlayerState> get states => _p.playerStateStream;

  @override
  ProcessingState get processingState => _p.processingState;

  @override
  Future<void> load(Uri uri, MediaItem tag, Duration initial) => _p
      .setAudioSource(AudioSource.uri(uri, tag: tag), initialPosition: initial);

  @override
  Future<void> play() => _p.play();

  @override
  Future<void> pause() => _p.pause();

  @override
  Future<void> seek(Duration position) => _p.seek(position);

  @override
  Future<void> stop() => _p.stop();

  @override
  Future<void> dispose() => _p.dispose();
}

final recitationAudioProvider = Provider<RecitationAudio Function()>(
  (ref) => _JustAudio.new,
);

final recitationProvider =
    NotifierProvider<RecitationController, RecitationState>(
      RecitationController.new,
    );

/// Plays one surah file at a time (the copy on the device, else streamed
/// from the faster host and saved as it plays), follows the verse being
/// recited using the published timings, repeats each verse or a chosen
/// stretch with silence between, and moves on to the next surah.
class RecitationController extends Notifier<RecitationState> {
  RecitationAudio? _player;
  List<AyahTimingRow> _timings = const [];
  List<WordTimingRow> _words = const [];

  /// Speech span of each verse (ms), for shortening the pauses.
  Map<int, (int, int)> _speech = const {};

  /// A jump over a long pause is under way, to [_jumpTo] ms.
  int? _jumpTo;
  final _subs = <StreamSubscription<Object?>>[];
  Timer? _sleepTimer;

  /// Bumped by each [play] and [stop]: a load begun before gives up.
  int _loads = 0;

  /// Bumped by each pause from outside (the reader, the sleep timer): a
  /// silence between repetitions begun before does not play on.
  int _waits = 0;

  /// A new file is loading: positions until then are the old file's, or
  /// the new one's start before it is placed at the verse, and are ignored.
  bool _loading = false;

  /// Positions before this (ms) are ignored until playback gets there: a
  /// file loaded at a verse may still report its start for a moment.
  int? _resumeMs;

  bool _inSilence = false;
  bool _ending = false;

  /// A silence between repetitions was cut short by a pause: playing again
  /// starts the next repetition here.
  Duration? _restartAt;

  /// When each verse repeats, the verse whose repetitions are done: it
  /// plays on into the next one.
  int? _verseDone;
  ProcessingState? _processing;

  RecitationAudio get _p => _player ??= _create();

  RecitationAudio _create() {
    final player = ref.read(recitationAudioProvider)();
    _subs
      ..add(player.positions.listen(_onPosition))
      ..add(player.states.listen(_onPlayerState));
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
    return _idle();
  }

  /// Not listening, with the reader's saved repeat and silence.
  RecitationState _idle() {
    final s = ref.read(settingsProvider);
    return RecitationState(
      repeat: s.repeat,
      silence: Duration(seconds: s.repeatSilence),
    );
  }

  int get _reciterId => ref.read(settingsProvider).reciterId;

  /// Starts reciting [surah] at [from] (the whole surah when null). With
  /// [to], only [rangeFrom] (by default [from])..[to] plays. [repeat]
  /// defaults to the reader's setting. Unless [start] is false, playback
  /// begins once the file is ready.
  Future<void> play(
    int surah, {
    int? from,
    int? to,
    int? rangeFrom,
    int? repeat,
    Duration? silence,
    bool start = true,
  }) async {
    final load = ++_loads;
    _loading = true;
    _waits++;
    _inSilence = false;
    _restartAt = null;
    final reciters = await ref.read(recitersProvider.future);
    final reciter = reciters.firstWhere(
      (r) => r.id == _reciterId,
      orElse: () => reciters.first,
    );
    final hosts = ref.read(audioHostsProvider.notifier);
    unawaited(hosts.measure(reciter));
    final repo = ref.read(mushafRepositoryProvider);
    final timings = await repo.timings(reciter.id, surah);
    final words = timings.isEmpty
        ? const <WordTimingRow>[]
        : await repo.wordTimings(reciter.id, surah);
    final speech = {
      for (final s in await repo.speech(reciter.id, surah))
        s.ayah: (s.startMs, s.endMs),
    };
    final surahRow = (await ref.read(surahsProvider.future))[surah - 1];
    if (load != _loads) return;
    // Only now, with everything at hand, does the new file's timing
    // replace the old: the old file may still be playing meanwhile.
    _timings = timings;
    _words = words;
    _speech = speech;
    _jumpTo = null;
    _verseDone = null;
    final timed = timings.isNotEmpty;
    final ayah = timed ? (from ?? 1) : null;
    state = state.copyWith(
      active: true,
      loading: true,
      surah: surah,
      ayah: () => ayah,
      word: () => null,
      timed: timed,
      rangeFrom: () => timed && to != null ? rangeFrom ?? from ?? 1 : null,
      rangeTo: () => timed ? to : null,
      repeat: repeat,
      repeatDone: 0,
      silence: silence,
      error: () => null,
    );
    final files = ref.read(audioFilesProvider);
    final local = files.file(reciter.id, surah);
    final stream = !local.existsSync();
    // The copy on the device, else the faster host, then the other.
    final uris = stream ? hosts.urls(reciter, surah) : [local.uri];
    final at = _startOf(ayah);
    Object? error;
    for (final uri in uris) {
      try {
        await _p.load(
          uri,
          MediaItem(
            id: '${reciter.id}/$surah',
            title: surahRow.nameAr,
            artist: reciter.nameAr,
            album: 'تبيان',
          ),
          at,
        );
        if (load != _loads) return;
        _loading = false;
        _resumeMs = at > Duration.zero ? at.inMilliseconds : null;
        state = state.copyWith(loading: false);
        if (start) unawaited(_p.play());
        if (stream) _save(reciter, surah);
        return;
      } catch (e) {
        if (load != _loads) return;
        error = e;
      }
    }
    _loading = false;
    state = state.copyWith(loading: false, error: () => error.toString());
  }

  /// A streamed surah is saved to the device while it plays (the same file
  /// a download makes), so it plays from there the next time.
  void _save(ReciterRow reciter, int surah) {
    unawaited(
      ref
          .read(audioFilesProvider)
          .download(
            reciter,
            surah,
            client: ref.read(audioHttpClientProvider),
            urls: ref.read(audioHostsProvider.notifier).urls(reciter, surah),
          )
          .catchError((Object _) {}),
    );
  }

  /// Switches the recitation. While listening, the new one carries on from
  /// the verse being recited when it has verse timings for this surah, and
  /// from the start of the surah when it has none.
  Future<void> changeReciter(int id) async {
    await ref.read(settingsProvider.notifier).setReciter(id);
    final s = state;
    if (!s.active) return;
    await play(
      s.surah,
      from: s.ayah,
      to: s.rangeTo,
      rangeFrom: s.rangeFrom,
      repeat: s.repeat,
      start: s.playing || s.loading,
    );
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

  /// The verse whose end closes what is being repeated: the chosen
  /// stretch's last verse or, when each verse repeats, the verse itself.
  int? get _stretchLast {
    if (state.rangeTo != null) return state.rangeTo;
    final a = state.ayah;
    if (state.repeat == 1 || a == null || a == _verseDone) return null;
    return a;
  }

  /// Where the stretch starts again.
  int? get _stretchFirst =>
      state.rangeTo != null ? state.rangeFrom : state.ayah;

  bool get _rangeFinished =>
      state.rangeTo != null &&
      state.repeat != 0 &&
      state.repeatDone >= state.repeat;

  /// Where a repetition of [ayah] starts: with shorter pauses, a moment
  /// before its speech rather than at the end of the long pause before it.
  Duration _repeatStart(int? ayah) {
    final start = _startOf(ayah);
    final keep = ref.read(settingsProvider).versePause;
    final spoken = ayah == null || keep <= 0 || start == Duration.zero
        ? null
        : _speech[ayah];
    if (spoken == null) return start;
    final near = spoken.$1 - keep ~/ 2;
    return near > start.inMilliseconds ? Duration(milliseconds: near) : start;
  }

  /// Where a repeated [ayah] ends: with shorter pauses, a moment after its
  /// speech, never past the start of the next verse.
  int? _repeatEnd(int ayah, int keep) {
    final end = _endOf(ayah);
    final spoken = keep > 0 ? _speech[ayah] : null;
    if (spoken == null) return end;
    final short = spoken.$2 + keep;
    return end == null || short < end ? short : end;
  }

  void _onPosition(Duration position) {
    if (!state.active || _loading || _inSilence || _timings.isEmpty) return;
    final ms = position.inMilliseconds;
    final resume = _resumeMs;
    if (resume != null) {
      if (ms < resume - 300) return;
      _resumeMs = null;
    }
    final keep = ref.read(settingsProvider).versePause;
    final last = _stretchLast;
    if (last != null && !_rangeFinished) {
      final end = _repeatEnd(last, keep);
      if (end != null && ms >= end - 40) {
        unawaited(_endOfStretch());
        return;
      }
    }
    final ayah = ayahAt(_timings, ms);
    if (keep > 0) _shortenPause(ayah, ms, keep, last);
    final w = _words.isEmpty ? null : wordAt(_words, ms);
    final word = w != null && w.$1 == ayah ? w.$2 : null;
    final verse = ayah != null && ayah > 0 ? ayah : state.ayah;
    if (verse != state.ayah || word != state.word) {
      // Each verse is repeated afresh.
      final next = verse != state.ayah && state.rangeTo == null;
      if (next) _verseDone = null;
      state = state.copyWith(
        ayah: () => verse,
        word: () => word,
        repeatDone: next ? 0 : null,
      );
    }
  }

  /// Reciters leave long silences between verses. Past the end of a
  /// verse's speech, jump to just before the next verse's speech, leaving a
  /// pause of about [keep] ms; not after [last], the verse being repeated.
  void _shortenPause(int? ayah, int ms, int keep, int? last) {
    final jump = _jumpTo;
    if (jump != null) {
      if (ms >= jump - 50) _jumpTo = null;
      return;
    }
    if (ayah == null || ayah <= 0 || ayah == last) return;
    final target = pauseJump(_speech, ayah, ms, keep);
    if (target == null) return;
    _jumpTo = target;
    unawaited(_p.seek(Duration(milliseconds: target)));
  }

  /// The verse or stretch being repeated has ended: after the silence it
  /// plays again, or, its repetitions done, the stretch stops there and a
  /// verse plays on into the next. Returns false only when it does not
  /// play again (so, at the end of the file, the next surah may follow).
  Future<bool> _endOfStretch() async {
    if (_ending || _rangeFinished) return !_rangeFinished;
    final first = _stretchFirst;
    final done = state.repeatDone + 1;
    if (state.repeat != 0 && done >= state.repeat) {
      if (state.rangeTo == null) {
        _verseDone = state.ayah;
        state = state.copyWith(repeatDone: 0);
        return false;
      }
      _ending = true;
      try {
        await _p.pause();
      } finally {
        _ending = false;
      }
      state = state.copyWith(repeatDone: done);
      return false;
    }
    final wait = _waits;
    _inSilence = true;
    state = state.copyWith(repeatDone: done);
    await _p.pause();
    if (state.silence > Duration.zero) {
      await Future<void>.delayed(state.silence);
    }
    // Paused, stopped or moved on meanwhile: it waits for the reader.
    if (wait != _waits || !state.active) return true;
    await _p.seek(_repeatStart(first));
    _resumeMs = null;
    state = state.copyWith(ayah: () => first, playing: true);
    _inSilence = false;
    unawaited(_p.play());
    return true;
  }

  void _onPlayerState(PlayerState s) {
    // The silence between repetitions counts as playing.
    final playing = s.playing || _inSilence;
    if (state.playing != playing) {
      state = state.copyWith(playing: playing);
    }
    final before = _processing;
    _processing = s.processingState;
    if (s.processingState == ProcessingState.completed &&
        before != ProcessingState.completed &&
        state.active &&
        !_loading) {
      unawaited(_onSurahEnd());
    }
  }

  Future<void> _onSurahEnd() async {
    if (_timings.isNotEmpty && _stretchLast != null) {
      if (await _endOfStretch() || state.rangeTo != null) return;
    }
    if (state.sleep is SleepAtSurahEnd || state.surah >= 114) {
      await _p.pause();
      await _p.seek(Duration.zero);
      state = state.copyWith(sleep: () => null);
      return;
    }
    await play(state.surah + 1);
  }

  /// Pauses, and holds a silence between repetitions that is under way.
  Future<void> _halt() async {
    _waits++;
    if (_inSilence) {
      _inSilence = false;
      _restartAt = _repeatStart(_stretchFirst);
    }
    await _player?.pause();
    if (state.playing) state = state.copyWith(playing: false);
  }

  Future<void> toggle() async {
    if (!state.active || state.loading) return;
    if (state.playing) return _halt();
    final restart = _restartAt;
    _restartAt = null;
    if (restart != null) {
      await _p.seek(restart);
      state = state.copyWith(ayah: () => _stretchFirst);
    } else if (_rangeFinished ||
        _p.processingState == ProcessingState.completed) {
      final first = state.timed ? state.rangeFrom ?? 1 : null;
      _verseDone = null;
      await _p.seek(_startOf(first));
      state = state.copyWith(repeatDone: 0, ayah: () => first);
    }
    _resumeMs = null;
    unawaited(_p.play());
  }

  /// Moves to the previous or next verse (timed files only).
  Future<void> step(int delta) async {
    final current = state.ayah;
    if (!state.timed || current == null) return;
    final target = current + delta;
    if (target < 1 || _endOf(target) == null) return;
    final silent = _inSilence;
    _waits++;
    _inSilence = false;
    _restartAt = null;
    _resumeMs = null;
    _verseDone = null;
    await _p.seek(_startOf(target));
    state = state.copyWith(
      ayah: () => target,
      repeatDone: state.rangeTo == null ? 0 : null,
    );
    if (silent) unawaited(_p.play());
  }

  /// Sets how many times each verse (or the chosen stretch) plays, and
  /// keeps it for the next time.
  void setRepeat(int times) {
    state = state.copyWith(repeat: times);
    unawaited(ref.read(settingsProvider.notifier).setRepeat(times));
  }

  /// Sets the silence between repetitions, and keeps it for the next time.
  void setSilence(Duration d) {
    state = state.copyWith(silence: d);
    unawaited(
      ref.read(settingsProvider.notifier).setRepeatSilence(d.inSeconds),
    );
  }

  /// Repeats only the verse being recited: as many times as set, or, when
  /// set to once, until stopped.
  void repeatCurrentVerse() {
    final a = state.ayah;
    if (!state.timed || a == null) return;
    state = state.copyWith(
      rangeFrom: () => a,
      rangeTo: () => a,
      repeatDone: 0,
      repeat: state.repeat == 1 ? 0 : null,
    );
  }

  /// Plays on to the end of the surah again, from the verse being recited.
  void clearRange() {
    _verseDone = state.ayah;
    state = state.copyWith(
      rangeFrom: () => null,
      rangeTo: () => null,
      repeatDone: 0,
    );
  }

  void setSleep(SleepTimer? timer) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    state = state.copyWith(sleep: () => timer);
    if (timer is SleepAfter) {
      _sleepTimer = Timer(timer.duration, () {
        _sleepTimer = null;
        state = state.copyWith(sleep: () => null);
        unawaited(_halt());
      });
    }
  }

  Future<void> stop() async {
    _loads++;
    _waits++;
    _loading = false;
    _inSilence = false;
    _restartAt = null;
    _resumeMs = null;
    _sleepTimer?.cancel();
    _sleepTimer = null;
    await _player?.stop();
    state = _idle();
  }
}
