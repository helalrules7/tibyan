import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/books/data/book_pack.dart';

/// The packs tools/export_pack.py writes, one per kind of book, built here
/// from tiny reviewed fixtures (tools/tests/book_pack_fixtures.py; its
/// texts are placeholders) and read as the app reads an installed pack.
void main() {
  late Directory dir;
  Map<String, String>? packs;
  String? skip;

  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('export_pipeline');
    try {
      final r = Process.runSync('python3', [
        'tools/tests/book_pack_fixtures.py',
        dir.path,
      ], stdoutEncoding: utf8);
      if (r.exitCode != 0) {
        fail('book_pack_fixtures.py failed: ${r.stderr}');
      }
      packs = (jsonDecode(r.stdout as String) as Map).cast<String, String>();
    } on ProcessException {
      skip = 'python3 is not available';
    }
  });
  tearDownAll(() => dir.deleteSync(recursive: true));

  BookPack open(String kind) {
    final pack = BookPack.open(File(packs![kind]!));
    addTearDown(pack.close);
    return pack;
  }

  test('a pack of every kind opens', () {
    if (skip != null) return markTestSkipped(skip!);
    expect(packs!.keys.toSet(), {
      BookKind.asbabNuzul,
      BookKind.tafsir,
      BookKind.munasabat,
      BookKind.wujuhNazair,
    });
    for (final kind in packs!.keys) {
      expect(open(kind).sourcesOf(kind), hasLength(1));
    }
  });

  test('asbab: reviewed entries only', () {
    if (skip != null) return markTestSkipped(skip!);
    final entries = open(BookKind.asbabNuzul)
        .entriesFor(2, 1, kind: BookKind.asbabNuzul);
    expect([for (final e in entries) e.text], ['نص سبب تجريبي.']);
    expect(entries.single.section, 'عنوان تجريبي');
    expect(entries.single.page, 1);
  });

  test('tafsir: the text byte for byte, on its range', () {
    if (skip != null) return markTestSkipped(skip!);
    final pack = open(BookKind.tafsir);
    final e = pack.entriesFor(2, 4, kind: BookKind.tafsir).single;
    expect(
      e.text,
      'نص تفسير تجريبي {نص بين معقوفين} ثم ﴿نص آية تجريبي﴾.\nفقرة ثانية.',
    );
    expect((e.link!.ayahFrom, e.link!.ayahTo), (1, 5));
    expect(pack.entriesFor(2, 6, kind: BookKind.tafsir), isEmpty);
  });

  test('munasabat: on its verses', () {
    if (skip != null) return markTestSkipped(skip!);
    final pack = open(BookKind.munasabat);
    expect(pack.entriesFor(2, 3, kind: BookKind.munasabat), hasLength(1));
    expect(pack.entriesFor(2, 1, kind: BookKind.munasabat), isEmpty);
  });

  test('wujuh: the sense on its word, under its word header', () {
    if (skip != null) return markTestSkipped(skip!);
    final pack = open(BookKind.wujuhNazair);
    List<BookEntry> senses(int word) => pack.entriesFor(
      1,
      1,
      kind: BookKind.wujuhNazair,
      entryKinds: {EntryKind.wajh},
      word: word,
    );
    final sense = senses(3).single;
    expect(sense.text, 'فوجه منها: نص وجه تجريبي.');
    expect((sense.link!.wordFrom, sense.link!.wordTo), (3, 3));
    expect(senses(2), isEmpty);
    expect(
      pack.parentOf(sense, kind: EntryKind.word)?.text,
      'كلمة على وجهين: نص تجريبي، ونص تجريبي.',
    );
  });
}
