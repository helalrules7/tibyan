import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/tasmee/domain/recitation_recognizer.dart';

void main() {
  group('settledWords', () {
    test('releases a word once it stays the same in two partials', () async {
      final out = await settledWords(
        Stream.fromIterable(const [
          PartialTranscript('بيت'),
          PartialTranscript('بيت ولد'),
          PartialTranscript('بيت ولد كتاب'),
          FinalTranscript('بيت ولد كتاب'),
        ]),
      ).toList();
      expect(out, [
        ['بيت'],
        ['ولد'],
        ['كتاب'],
      ]);
    });

    test('a final-only recogniser settles every word at once', () async {
      final out = await settledWords(
        Stream.fromIterable(const [FinalTranscript('بيت ولد كتاب')]),
      ).toList();
      expect(out, [
        ['بيت', 'ولد', 'كتاب'],
      ]);
    });

    test('a word that changes is not released until it agrees', () async {
      final out = await settledWords(
        Stream.fromIterable(const [
          PartialTranscript('بيت قلم'),
          PartialTranscript('بيت ولد'),
          FinalTranscript('بيت ولد'),
        ]),
      ).toList();
      expect(out, [
        ['بيت'],
        ['ولد'],
      ]);
    });

    test('nothing is emitted for an empty transcript', () async {
      final out = await settledWords(
        Stream.fromIterable(const [FinalTranscript('')]),
      ).toList();
      expect(out, isEmpty);
    });
  });
}
