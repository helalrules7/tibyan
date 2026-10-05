import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:tibyan/features/books/data/book_pack.dart';
import 'package:tibyan/features/books/presentation/quran_quotes.dart';
import 'package:tibyan/features/mushaf/data/page_pack.dart';

import 'fake_pack.dart';

void main() {
  group('entries linked to a verse', () {
    late BookPack pack;
    setUp(() => pack = fakePack());
    tearDown(() => pack.close());

    List<int> ids(int s, int a, {String? kind = BookKind.asbabNuzul}) => [
      for (final e in pack.entriesFor(s, a, kind: kind)) e.id,
    ];

    test('a range covers its first, middle and last verse only', () {
      expect(ids(2, 1), [1, 2]); // entry 2 also links 2:1
      expect(ids(2, 3), [1]);
      expect(ids(2, 5), [1]);
      expect(ids(2, 6), isEmpty);
      expect(ids(3, 3), isEmpty); // same verse number, other surah
    });

    test('several links: each verse they cover, the entry once', () {
      expect(ids(2, 10), [2]);
      expect(ids(2, 11), isEmpty);
      expect(ids(2, 12), [2]);
      expect(ids(2, 13), [2]); // two links cover it
    });

    test('in the book order, with the text and page as stored', () {
      final entries = pack.entriesFor(2, 1);
      expect([for (final e in entries) e.seq], [1, 2]);
      expect(entries.first.text, fakeText1);
      expect(entries.first.section, 'عنوان ﴿تجريبي﴾');
      expect((entries.first.page, entries.first.pageEnd), (12, 12));
      expect((entries[1].page, entries[1].pageEnd), (15, 16));
    });

    test('never an entry whose reviewer is its editor', () {
      expect(
        pack.entriesFor(2, 3, kind: null).map((e) => e.text),
        isNot(contains(fakeText3)),
      );
    });

    test('kind keeps one kind of book', () {
      expect(ids(2, 3, kind: null), [1, 4]);
      expect(ids(2, 3, kind: 'wujuh_nazair'), [4]);
    });

    test('the source, with the publisher\'s citation', () {
      final s = pack.entriesFor(2, 1).first.source;
      expect(s.title, 'كتاب تجريبي');
      expect(s.author, 'مؤلف تجريبي');
      expect(s.edition, 'الطبعة الأولى');
      expect(s.publisher, 'ناشر تجريبي');
      expect(s.tahqiq, isNull);
      expect(s.citation, fakeCitation);
    });
  });

  test('a pack without the citation column still opens', () {
    final pack = BookPack(fakePackDb(citationColumn: false));
    addTearDown(pack.close);
    expect(pack.entriesFor(2, 1).first.source.citation, isNull);
  });

  test('refuses a file of another format or not a pack', () {
    expect(
      () => BookPack(fakePackDb(format: '2')),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => BookPack(sqlite3.openInMemory()),
      throwsA(isA<FormatException>()),
    );
  });

  test('install: checked against its SHA-256, then opened read-only', () async {
    final dir = Directory.systemTemp.createTempSync('book_pack');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'download.db'));
    final db = fakePackDb();
    // An on-disk copy of the in-memory pack.
    db.execute('VACUUM INTO ?', [file.path]);
    db.close();
    final bytes = file.readAsBytesSync();
    final spec = BookPackSpec(
      id: 'book-test-v1',
      url: 'https://example.invalid/book-test-v1.pack.db',
      sha256: sha256.convert(bytes).toString(),
      bytes: bytes.length,
      kind: BookKind.asbabNuzul,
      title: 'كتاب تجريبي',
    );
    final installer = PagePackInstaller(
      root: Directory(p.join(dir.path, 'packs')),
      spec: spec.pack,
    );
    await installer.installFrom(file);
    expect(installer.isInstalled, isTrue);
    expect(file.existsSync(), isFalse);
    final pack = BookPack.open(
      File(p.join(installer.dir.path, bookPackFile)),
      spec: spec,
    );
    addTearDown(pack.close);
    expect(pack.entriesFor(2, 1).length, 2);

    // A damaged download is refused and nothing is installed.
    final bad = File(p.join(dir.path, 'bad.db'))..writeAsBytesSync([1, 2]);
    final other = PagePackInstaller(
      root: Directory(p.join(dir.path, 'packs2')),
      spec: spec.pack,
    );
    await expectLater(other.installFrom(bad), throwsFormatException);
    expect(other.isInstalled, isFalse);
  });

  test('the spec list is empty until a pack is published', () {
    expect(BookPackSpec.all, isEmpty);
  });

  group('verses quoted between ﴿ ﴾', () {
    String joined(String s) => splitQuranQuotes(s).map((x) => x.text).join();

    test('split into plain and quoted pieces', () {
      expect(splitQuranQuotes('قال ﴿آية﴾ ثم ﴿أخرى﴾.'), const [
        QuoteSegment('قال ', quote: false),
        QuoteSegment('﴿آية﴾', quote: true),
        QuoteSegment(' ثم ', quote: false),
        QuoteSegment('﴿أخرى﴾', quote: true),
        QuoteSegment('.', quote: false),
      ]);
      expect(splitQuranQuotes('﴿آية﴾').single.inner, 'آية');
      expect(splitQuranQuotes(''), isEmpty);
    });

    test('unbalanced brackets stay plain text', () {
      expect(splitQuranQuotes('نص ﴿بلا إغلاق'), const [
        QuoteSegment('نص ﴿بلا إغلاق', quote: false),
      ]);
      expect(splitQuranQuotes('نص﴾ ثم ﴿آية﴾'), const [
        QuoteSegment('نص﴾ ثم ', quote: false),
        QuoteSegment('﴿آية﴾', quote: true),
      ]);
      expect(
        splitQuranQuotes('﴿أ ﴿ب﴾ ج').first,
        const QuoteSegment('﴿أ ﴿ب﴾', quote: true),
      );
    });

    test('the pieces give the text back byte for byte', () {
      for (final s in [
        fakeText1,
        'نص ﴿بلا إغلاق',
        '﴾﴿﴾﴿',
        'سطر\nسطر ﴿آية\nفي سطرين﴾ آخر',
      ]) {
        expect(joined(s), s);
      }
    });
  });
}
