import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/features/khatma/domain/interval_set.dart';
import 'package:tibyan/features/khatma/domain/reading_tracker.dart';

void main() {
  late DateTime now;
  late List<PageRead> reads;
  late List<VersesRead> verses;
  late List<ReadingSpan> spans;
  late ReadingTracker tracker;
  var weights = <int, double>{};

  ReadingTracker make({String mode = 'page'}) => ReadingTracker(
    onPageRead: reads.add,
    onVersesRead: verses.add,
    onSessionEnd: spans.add,
    clock: () => now,
    pageWeight: (p, _) => weights[p] ?? 1,
    verseWeight: (id) => 0.1,
    mode: mode,
  );

  setUp(() {
    now = DateTime(2026, 10, 10, 8);
    reads = [];
    verses = [];
    spans = [];
    weights = {};
    tracker = make();
  });

  void wait(int seconds) => now = now.add(Duration(seconds: seconds));
  List<int> pages() => [for (final r in reads) r.page];
  Set<int> verseIds() => {
    for (final v in verses)
      for (final r in v.verses.ranges)
        for (var i = r.from; i <= r.to; i++) i,
  };

  group('weighted dwell', () {
    test('a heavier page needs longer, a light one at least 5 seconds', () {
      weights = {10: 1.2, 11: 0.1};
      tracker.show(10, 'shamarly');
      wait(20); // 20 × 1.2 = 24 seconds needed
      tracker.show(11, 'shamarly');
      wait(4); // 2 needed, but never less than 5
      tracker.show(12, 'shamarly');
      wait(21);
      tracker.show(10, 'shamarly');
      wait(25);
      tracker.end();
      expect(pages(), [12, 10]);
    });

    test('scenario 8: flipping fast through 50 pages counts nothing', () {
      for (var p = 100; p < 150; p++) {
        tracker.show(p, 'madina1441');
        wait(2);
      }
      tracker.end();
      expect(reads, isEmpty);
      // 100 seconds in all: the session is kept for the reports, with no
      // page in it.
      expect(spans.single.pages, 0);
    });

    test('the reading speed sets the time a page needs', () {
      // «سريعة»: 12 seconds a page.
      tracker.minDwell = Duration(seconds: ReadingSpeed.fast.secondsPerPage);
      tracker.show(1, 'madina1441');
      wait(11);
      tracker.show(2, 'madina1441');
      wait(12);
      tracker.end();
      expect(pages(), [2]);
      expect(ReadingSpeed.values.map((s) => s.secondsPerPage), [30, 20, 12]);
    });
  });

  group('idle', () {
    test('the active time stops 3 minutes after the last touch', () {
      tracker.show(1, 'madina1441');
      wait(60);
      tracker.touch();
      wait(600); // the phone left on the table
      tracker.end();
      expect(pages(), [1]);
      expect(spans.single.activeSeconds, 60 + 180);
      expect(spans.single.end.difference(spans.single.start).inSeconds, 660);
    });

    test('a touch brings the time back', () {
      tracker.show(1, 'madina1441');
      wait(400);
      tracker.touch();
      wait(30);
      tracker.end();
      expect(spans.single.activeSeconds, 180 + 30);
    });
  });

  group('another screen over the view', () {
    test('scenario 19: the tafsir open 5 minutes counts neither the page '
        'nor the time', () {
      tracker.show(5, 'madina1441');
      wait(4);
      tracker.freeze(true);
      wait(300);
      tracker.freeze(false);
      wait(10); // back, but not long enough yet
      tracker.end();
      expect(reads, isEmpty);
      expect(spans, isEmpty, reason: '14 active seconds, nothing read');
    });

    test('what stayed long enough before the push counts; after it, the '
        'page waits again', () {
      tracker.show(5, 'madina1441');
      wait(20);
      tracker.freeze(true);
      expect(pages(), [5]);
      wait(300);
      tracker.freeze(false);
      tracker.show(6, 'madina1441');
      wait(21);
      tracker.end();
      expect(pages(), [5, 6]);
      expect(spans.single.activeSeconds, 41);
    });
  });

  group('hifz test and recitation mode (decision 4)', () {
    test('nothing counts while suspended', () {
      tracker.suspend(true);
      tracker.show(7, 'madina1441');
      wait(60);
      tracker.show(8, 'madina1441');
      wait(60);
      tracker.suspend(false);
      wait(5);
      tracker.end();
      expect(reads, isEmpty);
    });

    test('the page counts once the test is over and it stays', () {
      tracker.show(7, 'madina1441');
      tracker.suspend(true);
      wait(60);
      tracker.suspend(false);
      wait(21);
      tracker.end();
      expect(pages(), [7]);
    });
  });

  group('opened from a search, a tafsir or the hifz', () {
    test('the landing page does not count; reading on from it does', () {
      tracker.onlyAfterPage = 293;
      tracker.show(293, 'madina1441');
      wait(30);
      tracker.show(294, 'madina1441');
      wait(30);
      tracker.show(292, 'madina1441');
      wait(30);
      tracker.end();
      expect(pages(), [294]);
    });
  });

  group('«آية آية»', () {
    test('scenario 20: thirty verses with time enough all count', () {
      tracker = make(mode: 'verse');
      for (var id = 100; id < 130; id++) {
        tracker.showVerse(id);
        wait(3); // 20 × 0.1 = 2, at least 2
      }
      tracker.end();
      expect(verseIds(), {for (var i = 100; i < 130; i++) i});
      expect(spans.single.mode, 'verse');
      expect(spans.single.verses.count, 30);
      expect(spans.single.pages, 0);
    });

    test('a verse swiped past counts nothing', () {
      tracker = make(mode: 'verse');
      tracker.showVerse(1);
      wait(1);
      tracker.showVerse(2);
      wait(5);
      tracker.end();
      expect(verseIds(), {2});
    });

    test('from a search, only the verses after the landing one', () {
      tracker = make(mode: 'verse');
      tracker.onlyAfterVerse = 10;
      tracker.showVerse(10);
      wait(5);
      tracker.showVerse(11);
      wait(5);
      tracker.end();
      expect(verseIds(), {11});
    });
  });

  group('the continuous view', () {
    test('verses count once they have spent their time in the zone', () {
      tracker = make(mode: 'continuous');
      tracker.showVerses([1, 2, 3]);
      wait(1);
      tracker.showVerses([2, 3, 4]); // 1 left after a second
      wait(1);
      tracker.showVerses([3, 4, 5]); // 2 had two seconds: read
      wait(3);
      tracker.showVerses([6]);
      tracker.end();
      expect(verseIds(), {2, 3, 4, 5});
    });

    test('scrolling straight through counts nothing', () {
      tracker = make(mode: 'continuous');
      for (var i = 1; i < 50; i++) {
        tracker.showVerses([i, i + 1]);
        now = now.add(const Duration(milliseconds: 300));
      }
      tracker.end();
      expect(verses, isEmpty);
    });
  });

  group('listening', () {
    test('a session while playing; each verse once; the session ends on '
        'stop', () {
      final heard = <VersesRead>[];
      final ended = <(String, IntervalSet)>[];
      final counter = ListeningCounter(
        onHeard: heard.add,
        onSessionEnd: (s, _, _, v) => ended.add((s, v)),
        clock: () => now,
      );
      counter.playing(true);
      counter.heard(IntervalSet.of([1]));
      counter.heard(IntervalSet.of([2]));
      counter.heard(IntervalSet.of([2]));
      counter.playing(false);
      counter.playing(false);
      expect(heard.length, 2);
      expect(ended.single.$2, IntervalSet.range(1, 2));
      expect(heard.first.session, ended.single.$1);
      // Playing without hearing a verse to its end leaves nothing.
      counter.playing(true);
      counter.playing(false);
      expect(ended, hasLength(1));
    });
  });
}
