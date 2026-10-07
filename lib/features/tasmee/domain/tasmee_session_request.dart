import 'expected_words.dart';
import 'recitation_range.dart';

enum TasmeeMode { continuous, verseByVerse }

class TasmeeSessionRequest {
  const TasmeeSessionRequest({
    required this.range,
    required this.words,
    required this.mode,
  });

  final RecitationRange range;
  final List<ExpectedWord> words;
  final TasmeeMode mode;
}
