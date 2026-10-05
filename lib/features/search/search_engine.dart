/// Text search over the Quran, forgiving of diacritics and the common
/// spelling differences, and of references like «2:255» or «البقرة 255».
///
/// The text searched is Tanzil's Simple Clean text (no diacritics); the
/// stored text is never changed, only compared after [normalize].
library;

/// Letters folded together when comparing: hamza carriers and wasla to a
/// bare alif, alif maqsura to ya, ta marbuta to ha. Diacritics, Quranic
/// marks and tatweel are dropped.
String normalize(String s) {
  final out = StringBuffer();
  for (final r in s.runes) {
    if ((r >= 0x064B && r <= 0x065F) ||
        r == 0x0670 ||
        (r >= 0x06D6 && r <= 0x06ED) ||
        r == 0x0640) {
      continue;
    }
    out.writeCharCode(switch (r) {
      0x0623 || 0x0625 || 0x0622 || 0x0671 => 0x0627, // أ إ آ ٱ → ا
      0x0649 => 0x064A, // ى → ي
      0x0629 => 0x0647, // ة → ه
      0x0624 => 0x0648, // ؤ → و
      0x0626 => 0x064A, // ئ → ي
      _ => r,
    });
  }
  return out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Arabic-Indic and Persian digits to ASCII.
String asciiDigits(String s) => s.replaceAllMapped(RegExp('[٠-٩۰-۹]'), (m) {
  final c = m[0]!.codeUnitAt(0);
  return String.fromCharCode(0x30 + (c >= 0x06F0 ? c - 0x06F0 : c - 0x0660));
});

/// One verse as searched.
class SearchVerse {
  SearchVerse(this.surah, this.ayah, String text, {this.juz = 0})
    : words = text.split(' '),
      folded = normalize(text) {
    foldedWords = folded.split(' ');
  }

  final int surah;
  final int ayah;

  /// The juz the verse is in (0 when unknown).
  final int juz;

  /// The verse's words as stored (without the basmala prefix).
  final List<String> words;
  final String folded;
  late final List<String> foldedWords;
}

/// A verse that matched, and which of its words the query touches.
class SearchHit {
  const SearchHit(this.surah, this.ayah, this.words, this.count);

  final int surah;
  final int ayah;

  /// 0-based indexes of the matched words.
  final Set<int> words;

  /// Occurrences of the query in the verse.
  final int count;
}

/// A reference the query names: a whole surah or one verse.
typedef VerseRef = ({int surah, int? ayah});

/// Reads «2:255», «2 255», «٢:٢٥٥», «البقرة 255», «سورة البقرة»,
/// «al-baqarah 255». [surahNames] maps a surah's number to its names
/// (Arabic and English). Returns null when the query is not a reference.
VerseRef? parseReference(String query, Map<int, List<String>> surahNames) {
  final q = asciiDigits(query).trim();
  final numbers = RegExp(r'^(\d{1,3})\s*[:：/.\-\s]\s*(\d{1,3})$').firstMatch(q);
  if (numbers != null) {
    final s = int.parse(numbers[1]!);
    if (s < 1 || s > 114) return null;
    return (surah: s, ayah: int.parse(numbers[2]!));
  }
  final named = RegExp(r'^(.*?)\s*(\d{1,3})?$').firstMatch(q);
  if (named == null) return null;
  final name = _foldName(named[1]!);
  if (name.isEmpty) return null;
  for (final e in surahNames.entries) {
    for (final n in e.value) {
      if (_foldName(n) == name) {
        final a = named[2];
        return (surah: e.key, ayah: a == null ? null : int.parse(a));
      }
    }
  }
  return null;
}

String _foldName(String s) {
  var n = normalize(s.toLowerCase())
      .replaceAll(RegExp(r'^سوره\s+'), '')
      .replaceAll(RegExp(r'^(al|an|ar|as|at|ad|adh|az|ash)[-\s]'), '')
      .replaceAll(RegExp("[-'’`]"), '')
      .replaceAll(' ', '');
  if (n.startsWith('ال')) n = n.substring(2);
  return n;
}

/// Every verse containing the query, in mushaf order. The query is
/// matched inside words too (a search for «علم» finds «يعلمون»); several
/// words must appear together, in order.
List<SearchHit> search(List<SearchVerse> verses, String query) {
  final q = normalize(query);
  if (q.length < 2) return const [];
  final hits = <SearchHit>[];
  for (final v in verses) {
    var at = v.folded.indexOf(q);
    if (at < 0) continue;
    final words = <int>{};
    var count = 0;
    while (at >= 0) {
      count++;
      final first = ' '.allMatches(v.folded.substring(0, at)).length;
      final last = ' '.allMatches(v.folded.substring(0, at + q.length)).length;
      for (var i = first; i <= last; i++) {
        words.add(i);
      }
      at = v.folded.indexOf(q, at + q.length);
    }
    hits.add(SearchHit(v.surah, v.ayah, words, count));
  }
  return hits;
}

/// Where a search looks: the whole mushaf, one surah, or one juz.
sealed class SearchScope {
  const SearchScope();
  bool contains(SearchVerse v);
}

class WholeMushaf extends SearchScope {
  const WholeMushaf();
  @override
  bool contains(SearchVerse v) => true;
  @override
  bool operator ==(Object other) => other is WholeMushaf;
  @override
  int get hashCode => 0;
}

class InSurah extends SearchScope {
  const InSurah(this.surah);
  final int surah;
  @override
  bool contains(SearchVerse v) => v.surah == surah;
  @override
  bool operator ==(Object other) => other is InSurah && other.surah == surah;
  @override
  int get hashCode => surah;
}

class InJuz extends SearchScope {
  const InJuz(this.juz);
  final int juz;
  @override
  bool contains(SearchVerse v) => v.juz == juz;
  @override
  bool operator ==(Object other) => other is InJuz && other.juz == juz;
  @override
  int get hashCode => 1000 + juz;
}

/// [search] within [scope].
List<SearchHit> searchIn(
  List<SearchVerse> verses,
  String query,
  SearchScope scope,
) => search(
  scope is WholeMushaf
      ? verses
      : [
          for (final v in verses)
            if (scope.contains(v)) v,
        ],
  query,
);
