import 'alignment_engine.dart';
import 'expected_words.dart';
import 'recitation_range.dart';

enum TasmeeMode { continuous, verseByVerse }

class TasmeeSessionRequest {
  const TasmeeSessionRequest({
    required this.range,
    required this.words,
    required this.mode,
    this.onError,
  });

  final RecitationRange range;
  final List<ExpectedWord> words;
  final TasmeeMode mode;

  /// What a mistake does in this session; null: the reader's setting.
  final ErrorBehavior? onError;
}
