/// Words highlighted as the divine name: «الله» (with its attached
/// prefixes, e.g. لله، بالله، والله، فالله، تالله، اللهم), «رب» and «ربنا».
/// Only the letters are compared; vowel marks and signs are ignored. The
/// yeh barree of the Warsh and Qalun texts (رَبِّے، «my Lord») is a yeh.
bool isDivineName(String word) {
  final base = word
      .replaceAll('ٱ', 'ا')
      .replaceAll('ے', 'ي')
      .replaceAll(RegExp('[^ء-غف-ي]'), '');
  return _allah.hasMatch(base) || _rabb.hasMatch(base);
}

final _allah = RegExp('^[وف]?[بتل]?ا?لله(م)?\$');
final _rabb = RegExp('^[وف]?رب(نا)?\$');
