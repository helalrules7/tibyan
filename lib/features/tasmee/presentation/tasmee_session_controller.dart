import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/model_store.dart';
import '../data/tasmee_audio_capture.dart';
import '../data/tasmee_backend.dart';
import '../domain/alignment_engine.dart';
import '../domain/expected_words.dart';
import '../domain/recitation_recognizer.dart';
import '../domain/spectrum.dart';
import '../domain/tasmee_report.dart';
import '../domain/tasmee_session_request.dart';
import '../domain/word_match.dart';

enum TasmeePhase {
  /// Looking for the model on the device.
  loading,

  /// The model is not on the device yet.
  needsModel,

  /// Ready; nothing heard yet.
  ready,

  /// The microphone is on (continuous, or a verse in verse by verse).
  listening,

  /// Continuous: paused by the reader. Verse by verse: between verses.
  paused,

  /// The microphone was refused.
  micDenied,

  /// The last words are being settled.
  finishing,
  finished,
}

/// One session of the audio tasmee: the microphone, the recogniser, the
/// alignment engine, and what the screen shows of them. No audio is kept:
/// samples go to the recogniser and the spectrum and are dropped.
class TasmeeSessionController extends ChangeNotifier {
  TasmeeSessionController({
    required this.request,
    required this.backend,
    required this.onError,
    required MatchStrictness strictness,
    required this.toastSeconds,
    required this.vibration,
  }) : engine = TasmeeEngine(
         request.words,
         options: TasmeeEngineOptions(strictness: strictness, onError: onError),
       ) {
    final seen = <int>{};
    for (final w in request.words) {
      if (seen.add(w.verseId)) _verseOrder.add(w.verseId);
    }
  }

  final TasmeeSessionRequest request;
  final TasmeeBackend backend;
  final ErrorBehavior onError;
  final int toastSeconds;
  final bool vibration;
  final TasmeeEngine engine;

  TasmeeMode get mode => request.mode;
  List<ExpectedWord> get words => request.words;

  TasmeePhase _phase = TasmeePhase.loading;
  TasmeePhase get phase => _phase;

  InstalledModel? _model;
  bool get modelReady => _model != null;

  /// Words shown by the hint button.
  final hinted = <int>{};

  /// The live spectrum, about 30 times a second while listening.
  final bands = ValueNotifier<List<double>>(List.filled(18, 0));

  /// The result of the verse just finished, shown for [toastSeconds].
  VerseReport? _toast;
  VerseReport? get toast => _toast;
  Timer? _toastTimer;

  /// A failure to show (not the microphone: see [TasmeePhase.micDenied]).
  String? error;

  Duration _elapsed = Duration.zero;
  DateTime? _since;
  Timer? _clock;
  Duration get elapsed =>
      _since == null ? _elapsed : _elapsed + DateTime.now().difference(_since!);

  final _verseOrder = <int>[];

  /// Verse by verse: the verse to recite next (index into the range).
  int _verse = 0;

  RecitationRecognizer? _recognizer;
  TasmeeMicrophone? _mic;
  StreamSubscription<List<String>>? _words;
  StreamSubscription<RecognizerEvent>? _raw;

  /// Recogniser events so far (to know when it has gone quiet).
  int _events = 0;
  final _spectrum = SpectrumAnalyzer();
  bool _disposed = false;
  bool _busy = false;

  bool get stopToCorrect =>
      _phase == TasmeePhase.listening && engine.waitingAt != null;

  /// The verse being recited: the verse of the word the reader is on.
  int get currentVerseId {
    if (mode == TasmeeMode.verseByVerse) {
      return _verseOrder[_verse.clamp(0, _verseOrder.length - 1)];
    }
    final at = engine.waitingAt ?? engine.cursor;
    return words[at.clamp(0, words.length - 1)].verseId;
  }

  ExpectedWord get currentVerseFirst =>
      words.firstWhere((w) => w.verseId == currentVerseId);

  /// The word the reader is on (null when not listening or at the end).
  int? get cursorWord {
    if (_phase == TasmeePhase.finished) return null;
    var i = engine.cursor;
    while (i < words.length && hinted.contains(i)) {
      i++;
    }
    if (i >= words.length) return null;
    if (mode == TasmeeMode.verseByVerse && words[i].verseId != currentVerseId) {
      return null;
    }
    return i;
  }

  /// The page to show: the page of the word the reader is on.
  int get page {
    if (mode == TasmeeMode.verseByVerse && _phase != TasmeePhase.finished) {
      final at = cursorWord;
      return at != null ? words[at].page : currentVerseFirst.page;
    }
    final at = engine.waitingAt ?? engine.cursor;
    return words[at.clamp(0, words.length - 1)].page;
  }

  /// How much of the range is settled or shown, 0..1.
  double get progress {
    var done = 0;
    for (final w in words) {
      if (engine.statusOf(w.index).isSettled || hinted.contains(w.index)) {
        done++;
      }
    }
    return words.isEmpty ? 0 : done / words.length;
  }

  TasmeeReport get report => TasmeeReport.of(engine, hinted);

  /// Accuracy of the verse being recited, in percent (null before any of
  /// its words was judged).
  int? get currentAccuracy {
    final v = report.verse(currentVerseId)?.accuracy;
    return v == null ? null : (v * 100).round();
  }

  void _set(TasmeePhase p) {
    _phase = p;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // -- the model -----------------------------------------------------------

  Future<void> load() async {
    try {
      _model = await backend.installedModel();
    } catch (e) {
      error = '$e';
    }
    _set(_model == null ? TasmeePhase.needsModel : TasmeePhase.ready);
  }

  void modelInstalled(InstalledModel model) {
    _model = model;
    if (_phase == TasmeePhase.needsModel) _set(TasmeePhase.ready);
  }

  // -- listening -----------------------------------------------------------

  /// Starts the session, resumes it, or (verse by verse) starts the next
  /// verse.
  Future<void> listen() async {
    if (_busy || _model == null) return;
    if (_phase
        case TasmeePhase.listening ||
            TasmeePhase.finishing ||
            TasmeePhase.finished) {
      return;
    }
    _busy = true;
    error = null;
    try {
      await _ensureRecognizer();
      final mic = _mic ??= backend.microphone();
      final recognizer = _recognizer!;
      await mic.start(
        onPcm: recognizer.acceptAudio,
        onLevel: (_) {},
        onSpeechEnded: recognizer.endOfSpeech,
        onError: (e, _) {
          error = '$e';
          _notify();
        },
        onFrame: _onFrame,
      );
      if (_disposed) return;
      _since = DateTime.now();
      _clock ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (_since != null) _notify();
      });
      _set(TasmeePhase.listening);
    } on MicrophonePermissionDenied {
      _set(TasmeePhase.micDenied);
    } catch (e) {
      error = '$e';
      _notify();
    } finally {
      _busy = false;
    }
  }

  Future<void> _ensureRecognizer() async {
    if (_recognizer != null) return;
    final recognizer = backend.recognizer(_model!);
    _recognizer = recognizer;
    _raw = recognizer.events.listen((_) => _events++, onError: (Object _) {});
    _words = settledWords(recognizer.events).listen(
      _accept,
      onError: (Object e, StackTrace _) {
        error = '$e';
        _notify();
      },
    );
    await recognizer.start();
  }

  void _onFrame(Int16List frame) {
    final levels = _spectrum.add(frame);
    if (levels != null && !_disposed) bands.value = levels;
  }

  void _accept(List<String> heard) {
    if (_disposed || heard.isEmpty) return;
    if (_phase == TasmeePhase.finished) return;
    final events = engine.addWords(heard);
    _react(events);
    if (mode == TasmeeMode.verseByVerse) {
      final indices = words.where((w) => w.verseId == currentVerseId);
      if (_phase == TasmeePhase.listening &&
          indices.every((w) => engine.statusOf(w.index).isSettled)) {
        unawaited(finishVerse());
      }
    } else if (engine.isComplete && _phase == TasmeePhase.listening) {
      unawaited(end());
    }
    _notify();
  }

  void _react(List<TasmeeEvent> events) {
    for (final e in events) {
      switch (e) {
        case WordSettled(:final status) when status.isError:
          if (vibration) unawaited(HapticFeedback.mediumImpact());
        case VerseCompleted(:final score) when mode == TasmeeMode.continuous:
          _showToast(score.verseId);
        default:
          break;
      }
    }
  }

  void _showToast(int verseId) {
    _toast = report.verse(verseId);
    _toastTimer?.cancel();
    _toastTimer = Timer(Duration(seconds: toastSeconds), () {
      _toast = null;
      _notify();
    });
  }

  Future<void> _stopMic() async {
    if (_since != null) {
      _elapsed += DateTime.now().difference(_since!);
      _since = null;
    }
    await _mic?.stop();
    _spectrum.reset();
    bands.value = List.filled(bands.value.length, 0);
  }

  /// Waits for the recogniser to give back what it was still working on:
  /// until nothing has come for [_quietSteps] steps in a row, at most
  /// [_flushSteps] steps (about 0.8 s and 4 s).
  Future<void> _flush() async {
    const step = Duration(milliseconds: 150);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    var seen = _events;
    var quiet = 0;
    for (var i = 0; i < _flushSteps && !_disposed; i++) {
      if (quiet >= _quietSteps) break;
      await Future<void>.delayed(step);
      if (_events == seen) {
        quiet++;
      } else {
        seen = _events;
        quiet = 0;
      }
    }
  }

  static const _quietSteps = 5;
  static const _flushSteps = 23;

  Future<void> pause() async {
    if (_phase != TasmeePhase.listening || mode != TasmeeMode.continuous) {
      return;
    }
    _set(TasmeePhase.paused);
    await _stopMic();
    _notify();
  }

  /// Verse by verse: the reader is done with the verse (or it was all
  /// heard). Its words not reached count as skipped; the next verse waits.
  Future<void> finishVerse() async {
    if (mode != TasmeeMode.verseByVerse ||
        _phase != TasmeePhase.listening ||
        _busy) {
      return;
    }
    _busy = true;
    try {
      _set(TasmeePhase.paused);
      await _stopMic();
      await _flush();
      final verseId = currentVerseId;
      _react(engine.finishVerse(verseId));
      _showToast(verseId);
      _verse++;
      if (_verse >= _verseOrder.length) {
        _verse = _verseOrder.length - 1;
        _busy = false;
        await end();
        return;
      }
      _notify();
    } finally {
      _busy = false;
    }
  }

  /// The hint: shows the next word not reached yet, counted apart.
  void hint() {
    if (_phase == TasmeePhase.finished) return;
    final at = cursorWord;
    if (at == null) return;
    hinted.add(at);
    _notify();
  }

  /// Stop to correct: give up on the word waited on, and go on.
  void skipWaiting() {
    _react(engine.skipWaiting());
    _notify();
  }

  /// Ends the session: the words still unsure are settled.
  Future<void> end() async {
    if (_phase case TasmeePhase.finishing || TasmeePhase.finished) return;
    final wasListening = _phase == TasmeePhase.listening;
    _set(TasmeePhase.finishing);
    await _stopMic();
    if (wasListening) await _flush();
    engine.finish();
    _toastTimer?.cancel();
    _toast = null;
    _clock?.cancel();
    _clock = null;
    _set(TasmeePhase.finished);
    await _release();
  }

  Future<void> _release() async {
    final words = _words, raw = _raw, mic = _mic, recognizer = _recognizer;
    _words = null;
    _raw = null;
    _mic = null;
    _recognizer = null;
    await mic?.dispose();
    // Closing the recogniser ends its events, and so both listeners.
    await recognizer?.dispose();
    unawaited(words?.cancel());
    unawaited(raw?.cancel());
  }

  @override
  void dispose() {
    _disposed = true;
    _clock?.cancel();
    _toastTimer?.cancel();
    unawaited(_release());
    bands.dispose();
    super.dispose();
  }
}
