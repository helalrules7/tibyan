import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/testing/test_packs.dart';
import 'package:tibyan/features/books/data/book_pack.dart';
import 'package:tibyan/features/content_extras/english_tafsir.dart';
import 'package:tibyan/features/content_extras/verse_audio_index.dart';
import 'package:tibyan/features/mushaf/data/background_packs.dart';

/// The closed-test packs (lib/core/testing/test_packs.dart): all on our
/// server's test area, all titled as test drafts, all in the app's lists,
/// and gone together when the switch is off.
void main() {
  bool underTest(String url) =>
      Uri.parse(url).scheme == 'https' &&
      Uri.parse(url).host == 'tibyan.ahmedhelal.dev' &&
      Uri.parse(url).path.startsWith('/mirror/test/');

  final hex = RegExp(r'^[0-9a-f]{64}$');

  test('every test book pack: under /mirror/test/, titled a test draft', () {
    for (final s in testBookPacks) {
      expect(underTest(s.url), isTrue, reason: s.url);
      expect(s.url, endsWith('/${s.id}.pack.db'));
      expect(s.id, startsWith('test-'));
      expect(s.title, contains(testTitleMarkAr), reason: s.title);
      expect(s.sha256, matches(hex));
      expect(s.bytes, greaterThan(0));
      expect(BookPackSpec.all, contains(s));
    }
  });

  test('every test audio index: under /mirror/test/', () {
    for (final s in testAudioIndexes) {
      expect(underTest(s.url), isTrue, reason: s.url);
      expect(s.id, startsWith('test-'));
      expect(s.sha256, matches(hex));
      expect(VerseAudioKind.feature(s.kind), isNotNull);
      expect(AudioIndexSpec.all, contains(s));
    }
  });

  test('every test English tafsir pack: under /mirror/test/, titled', () {
    for (final s in testEnglishTafsirPacks) {
      expect(underTest(s.url), isTrue, reason: s.url);
      expect(s.id, startsWith('test-'));
      expect(s.title, contains(testTitleMarkEn), reason: s.title);
      expect(s.sha256, matches(hex));
      expect(TafsirTextPackSpec.english, contains(s));
    }
  });

  test('the background downloader installs every test pack', () {
    for (final s in [
      for (final b in testBookPacks) b.pack,
      for (final t in testEnglishTafsirPacks) t.pack,
    ]) {
      expect(downloadablePackSpec(s.id)?.url, s.url, reason: s.id);
    }
  });

  test('ids are unique across the test packs', () {
    final ids = [
      for (final s in testBookPacks) s.id,
      for (final s in testAudioIndexes) s.id,
      for (final s in testEnglishTafsirPacks) s.id,
    ];
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('the test packs are on while the closed test runs', () {
    // Turn includeTestPacks off (or delete test_packs.dart) before a
    // public release: docs/MISSING_DATA.md, «قبل النشر العام».
    expect(includeTestPacks, isTrue);
    expect(testBookPacks, isNotEmpty);
  });
}
