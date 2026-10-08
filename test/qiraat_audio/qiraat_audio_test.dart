import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tibyan/core/flags/feature_flags.dart';
import 'package:tibyan/features/qiraat_audio/qiraat_audio_index.dart';
import 'package:tibyan/features/qiraat_audio/qiraat_audio_providers.dart';

Map<String, Object?> _clip(
  String file, {
  String group = 'authors_own',
  int? duration = 10000,
  List<Object?> words = const [],
  String url = 'https://osf.io/download/x/',
}) => {
  'file': file,
  'reciter': file.substring(0, file.indexOf('_')),
  'clip': 1,
  'path': '/AQQD/$file',
  'url': url,
  'size': 882044,
  'duration_ms': duration,
  'group': group,
  'words': words,
};

/// A fake surah 36 index: verse 40 in S5 (one clip from the authors with a
/// reviewed and an unreviewed range, one cut from a public recording) and
/// in S2 (public only); verse 41 in S1, whole clip only.
String _index({int surah = 36}) => jsonEncode({
  'format': 1,
  'surah': surah,
  'verses': {
    '40': {
      'S5': [
        _clip('R002_S5_Surah_036_Aya40_C1.wav', group: 'public_cut'),
        _clip(
          'R023_S5_Surah_036_Aya40_C2.wav',
          words: [
            {
              'range': [1830, 2410, 3],
              'by': 'alice',
              'reviewed_by': 'bob',
            },
            {
              'range': [4000, 4500, 5],
              'by': 'alice',
            },
          ],
        ),
      ],
      'S2': [_clip('R101_S2_Surah_036_Aya40_C1.wav', group: 'public_cut')],
    },
    '41': {
      'S1': [
        _clip('R023_S1_Surah_036_Aya41_C1.wav'),
        _clip('R023_S9_Surah_036_Aya41_C2.wav'), // filed under the wrong style
        _clip('R023_S1_Surah_036_Aya41_C3.wav', url: 'http://osf.io/x'),
      ],
    },
  },
});

class _FakeSource implements QiraatAudioIndexSource {
  _FakeSource(this.files);
  final Map<int, String> files;
  final asked = <int>[];

  @override
  Future<String?> surah(int surah) async {
    asked.add(surah);
    return files[surah];
  }
}

void main() {
  group('QiraatAudioSurah', () {
    final index = QiraatAudioSurah.parse(_index(), 36)!;

    test('only clips of a group with a clear licence are playable', () {
      expect(playableProvenance, {ProvenanceGroup.authorsOwn});
      expect(index.clips(40, 'S5').map((c) => c.file), [
        'R023_S5_Surah_036_Aya40_C2.wav',
      ]);
      expect(index.clips(40, 'S2'), isEmpty);
      expect(index.styles(40), ['S5']);
      expect(index.verses[40]!['S2'], hasLength(1)); // kept, not played
    });

    test('a reviewed word range plays only that range', () {
      final p = index.playback(40, 'S5', word: 3)!;
      expect(p.uri, Uri.parse('https://osf.io/download/x/'));
      expect(p.start, const Duration(milliseconds: 1830));
      expect(p.end, const Duration(milliseconds: 2410));
      expect(p.word, 3);
      // With no word asked, the clip's only reviewed range.
      expect(index.playback(40, 'S5')!.word, 3);
    });

    test('an unreviewed range plays the whole verse clip', () {
      final p = index.playback(40, 'S5', word: 5)!;
      expect(p.wholeClip, isTrue);
      expect(p.end, isNull);
      expect(p.clip.file, 'R023_S5_Surah_036_Aya40_C2.wav');
    });

    test('no playable clip, no playback', () {
      expect(index.playback(40, 'S2'), isNull);
      expect(index.playback(39, 'S5'), isNull);
    });

    test('malformed clips are left out', () {
      expect(index.clips(41, 'S1').map((c) => c.clip), [1]);
      expect(index.playback(41, 'S1')!.wholeClip, isTrue);
      expect(QiraatAudioSurah.parse(_index(), 2), isNull); // wrong surah
      expect(QiraatAudioSurah.parse('not json', 36), isNull);
    });

    test('a reviewer who is the measurer does not count', () {
      const r = QiraatWordRange(
        startMs: 1,
        endMs: 2,
        word: 1,
        by: 'Ali',
        reviewedBy: 'ali',
      );
      expect(r.reviewed, isFalse);
    });
  });

  group('providers', () {
    ProviderContainer container(bool on, _FakeSource source) {
      final c = ProviderContainer(
        overrides: [
          featureFlagsProvider.overrideWithValue(
            FeatureFlags({'qiraat_audio': on}),
          ),
          qiraatAudioIndexSourceProvider.overrideWithValue(source),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('off by default: nothing is fetched', () async {
      final source = _FakeSource({36: _index()});
      final c = container(false, source);
      expect(await c.read(qiraatAudioSurahProvider(36).future), isNull);
      expect(
        await c.read(qiraatPlaybackProvider((36, 40, 'S5', 3)).future),
        isNull,
      );
      expect(source.asked, isEmpty);
    });

    test('on: the playback of a verse and word', () async {
      final c = container(true, _FakeSource({36: _index()}));
      final p = await c.read(qiraatPlaybackProvider((36, 40, 'S5', 3)).future);
      expect(p!.start, const Duration(milliseconds: 1830));
      expect(
        await c.read(qiraatPlaybackProvider((1, 1, 'S5', null)).future),
        isNull,
      );
    });
  });

  test(
    'the HTTP source reads the surah file by its three-digit name',
    () async {
      final urls = <Uri>[];
      final source = HttpQiraatAudioIndexSource(
        MockClient((r) async {
          urls.add(r.url);
          return r.url.path.endsWith('/036.json')
              ? http.Response.bytes(utf8.encode(_index()), 200)
              : http.Response('', 404);
        }),
        baseUrl: 'https://example.test/index/',
      );
      expect(await source.surah(36), _index());
      expect(await source.surah(2), isNull);
      expect(await source.surah(115), isNull);
      expect(urls.map((u) => u.toString()), [
        'https://example.test/index/036.json',
        'https://example.test/index/002.json',
      ]);
    },
  );
}
