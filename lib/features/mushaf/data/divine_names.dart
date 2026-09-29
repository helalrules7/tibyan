/// Words highlighted as the divine name: «الله» (with its attached
/// prefixes, e.g. لله، بالله، والله، فالله، تالله، اللهم), «رب» and «ربنا».
/// Only the letters are compared; vowel marks and signs are ignored.
bool isDivineName(String word) {
  final base = word.replaceAll('ٱ', 'ا').replaceAll(RegExp('[^ء-غف-ي]'), '');
  return _allah.hasMatch(base) || _rabb.hasMatch(base);
}

final _allah = RegExp('^[وف]?[بتل]?ا?لله(م)?\$');
final _rabb = RegExp('^[وف]?رب(نا)?\$');
