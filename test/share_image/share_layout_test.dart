import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/share_image/share_document.dart';
import 'package:tibyan/features/share_image/share_layout.dart';
import 'package:tibyan/features/share_image/share_source.dart';
import 'package:tibyan/features/share_image/share_text_runs.dart';

/// Verses of [n] words each: «wS.A.i», the last word held to its number by
/// a no-break space, as the KFGQPC texts end.
List<ShareVerse> _verses(int surah, int from, int to, int n) => [
  for (var a = from; a <= to; a++)
    ShareVerse(
      surah: surah,
      ayah: a,
      text: [for (var i = 1; i <= n; i++) 'w$surah.$a.$i']
          .join(' ')
          .replaceFirst(RegExp(r'$'), ' ﰀ'),
    ),
];

List<SharePageLayout> _paginate(
  List<ShareVerse> verses, {
  int first = 4,
  int rest = 5,
  bool Function(int)? basmala,
  double width = 100,
}) {
  final tokens = tokenize(verses);
  return paginate(
    tokens: tokens,
    verses: verses,
    widths: [for (final _ in tokens) 10],
    width: width,
    space: 2,
    capacity: ({required withBasmala}) => withBasmala ? first : rest,
    hasBasmala: basmala ?? (s) => s != 1 && s != 9,
  );
}

void main() {
  group('tokens and justification never change the text', () {
    test('tokens joined give back the verses joined', () {
      final verses = [
        const ShareVerse(
          surah: 2,
          ayah: 255,
          text: 'ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلۡحَيُّ ﰀ',
        ),
        const ShareVerse(surah: 2, ayah: 256, text: '۞ لَآ إِكۡرَاهَ ﰁ'),
      ];
      final tokens = tokenize(verses);
      expect(joinTokens(tokens), verses.map((v) => v.text).join(' '));
      // ۞ and the number stay with their words: no line starts with them.
      expect(tokens.where((t) => t.text == '۞' || t.text == 'ﰀ'), isEmpty);
    });

    test('every page holds its tokens in order; together, the passage', () {
      final verses = _verses(2, 1, 9, 13);
      final tokens = tokenize(verses);
      final pages = _paginate(verses);
      final drawn = [
        for (final p in pages)
          for (final l in p.lines)
            for (var i = l.from; i < l.to; i++) tokens[i],
      ];
      expect(drawn.length, tokens.length);
      expect(joinTokens(drawn), verses.map((v) => v.text).join(' '));
    });

    test('justified lines fill the width; the last line does not', () {
      final verses = _verses(2, 1, 1, 23);
      final tokens = tokenize(verses);
      final widths = [for (final _ in tokens) 10.0];
      final pages = _paginate(verses);
      expect(pages, hasLength(1));
      final lines = pages.single.lines;
      for (final l in lines.take(lines.length - 1)) {
        expect(l.justified, isTrue);
        final xs = placeLine(widths, l, 100, 2);
        expect(xs.last + widths[l.to - 1], closeTo(100, 1e-9));
      }
      expect(lines.last.justified, isFalse);
      final xs = placeLine(widths, lines.last, 100, 2);
      expect(xs.first, 0);
      expect(xs.last + widths[lines.last.to - 1], lessThan(100));
    });
  });

  group('splitting into pictures', () {
    test('a short passage is one picture', () {
      final pages = _paginate(_verses(112, 1, 4, 4));
      expect(pages, hasLength(1));
      expect(pages.single.firstOfSurah, isTrue);
    });

    test('a long passage splits at verse ends', () {
      final verses = _verses(2, 1, 12, 9);
      final tokens = tokenize(verses);
      final pages = _paginate(verses);
      expect(pages.length, greaterThan(1));
      for (final p in pages.take(pages.length - 1)) {
        expect(tokens[p.to - 1].endsVerse, isTrue);
        expect(p.lines.last.justified, isFalse);
      }
      expect(pages.first.lines.length, lessThanOrEqualTo(4));
      for (final p in pages.skip(1)) {
        expect(p.lines.length, lessThanOrEqualTo(5));
        expect(p.firstOfSurah, isFalse);
      }
    });

    test('a verse longer than a picture is cut at a line break', () {
      final verses = _verses(2, 282, 282, 80);
      final pages = _paginate(verses);
      expect(pages.length, greaterThan(1));
      // Full lines, all justified, on the pictures before the last.
      for (final p in pages.take(pages.length - 1)) {
        expect(p.lines.every((l) => l.justified), isTrue);
      }
    });

    test('each surah starts its own picture', () {
      final verses = [..._verses(1, 6, 7, 5), ..._verses(2, 1, 2, 5)];
      final pages = _paginate(verses);
      expect(pages.map((p) => p.surah), [1, 2]);
      expect(pages.every((p) => p.firstOfSurah), isTrue);
    });
  });

  group('basmala', () {
    SharePassage passage(List<ShareVerse> v, {String? basmala = 'B'}) =>
        SharePassage(
          verses: v,
          headers: const {},
          fontFamily: 'x',
          basmala: basmala,
          reference: '',
          pageLabel: sharePageLabel,
        );

    test('above every surah but at-Tawba and al-Fatiha', () {
      expect(passage(_verses(2, 255, 255, 3)).hasBasmala(2), isTrue);
      expect(passage(_verses(9, 1, 3, 3)).hasBasmala(9), isFalse);
      // In al-Fatiha the basmala is verse 1, drawn with its number.
      expect(passage(_verses(1, 1, 7, 3)).hasBasmala(1), isFalse);
    });

    test('none without a basmala text (the riwaya editions)', () {
      expect(
        passage(_verses(2, 1, 5, 3), basmala: null).hasBasmala(2),
        isFalse,
      );
    });

    test('only on the first picture of a surah', () {
      final verses = _verses(2, 1, 20, 9);
      final pages = _paginate(verses);
      final p = passage(verses);
      final withBasmala = [
        for (final page in pages) page.firstOfSurah && p.hasBasmala(page.surah),
      ];
      expect(withBasmala.first, isTrue);
      expect(withBasmala.skip(1), everyElement(isFalse));
    });

    test('the first picture holds fewer lines, for the basmala', () {
      final pages = _paginate(_verses(2, 1, 40, 5), first: 3, rest: 6);
      expect(pages.first.lines.length, lessThanOrEqualTo(3));
      expect(pages[1].lines.length, greaterThan(3));
    });
  });

  group('footer', () {
    test('numbers the pictures in Arabic-Indic digits', () {
      expect(sharePageLabel(0, 4), '١ من ٤');
      expect(sharePageLabel(3, 12), '٤ من ١٢');
    });
  });

  group('colour runs', () {
    const red = Color(0xFFFF0000);
    const green = Color(0xFF00FF00);
    test('joined, the runs are the token', () {
      const token = 'ٱللَّهِ ﰀ';
      final runs = tokenRuns(
        token,
        firstWord: 1,
        endsVerse: true,
        divine: red,
        number: green,
        letters: const [
          ShareTajweedLetter(
            word: 1,
            letter: 0,
            marksOnly: false,
            color: green,
          ),
        ],
      );
      expect(runs.map((r) => r.$1).join(), token);
      // The hamzat al-wasl in its colour, the rest of the name in red, the
      // number in its own.
      expect(runs.first, ('ٱ', green));
      expect(runs[1].$2, red);
      expect(runs.last, ('ﰀ', green));
    });

    test('letters are a base character with its marks', () {
      expect(letterSpans('بِسۡمِ'), [(0, 2), (2, 4), (4, 6)]);
    });

    test('۞ and the verse number are not words', () {
      expect(wordsInToken('۞ لَآ', endsVerse: false), 1);
      expect(wordsInToken('هُوَ ﰀ', endsVerse: true), 1);
    });
  });

  test('document sizes', () {
    expect(ShareDocument.size.width, 1536);
    expect(ShareDocument.size.height, 2048);
  });
}
