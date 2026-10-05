import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Where an AQQD clip comes from, which decides its licence
/// (`data/qiraat_audio/provenance.json`).
enum ProvenanceGroup {
  /// Recorded by the dataset's authors (Taibah University mushaf): CC0 1.0
  /// per their paper.
  authorsOwn('authors_own'),

  /// Cut by the authors from recordings published elsewhere: the paper's
  /// CC0 does not clearly cover them.
  publicCut('public_cut'),

  /// Not yet assigned to a group.
  unknown('unknown');

  const ProvenanceGroup(this.key);
  final String key;

  static ProvenanceGroup fromKey(Object? key) => values.firstWhere(
    (g) => g.key == key,
    orElse: () => ProvenanceGroup.unknown,
  );
}

/// The groups the app plays: only those whose licence is clear. The one
/// place to change when another group's terms are settled.
const playableProvenance = {ProvenanceGroup.authorsOwn};

/// Where the differing word sits in a clip: milliseconds from the clip's
/// start and the word's number in the verse (KFGQPC Hafs words), measured
/// by [by] and approved by [reviewedBy], a second person.
@immutable
class QiraatWordRange {
  const QiraatWordRange({
    required this.startMs,
    required this.endMs,
    required this.word,
    required this.by,
    this.reviewedBy,
  });

  final int startMs;
  final int endMs;
  final int word;
  final String by;
  final String? reviewedBy;

  /// Played only once a second person has approved it.
  bool get reviewed {
    final r = reviewedBy?.trim().toLowerCase();
    return r != null && r.isNotEmpty && r != by.trim().toLowerCase();
  }
}

/// One AQQD clip: a verse (or part of one) recited in one style.
@immutable
class QiraatClip {
  const QiraatClip({
    required this.file,
    required this.reciter,
    required this.clip,
    required this.url,
    required this.group,
    this.durationMs,
    this.words = const [],
  });

  final String file;
  final String reciter;
  final int clip;

  /// Streamed from its source; never bundled.
  final Uri url;
  final ProvenanceGroup group;
  final int? durationMs;
  final List<QiraatWordRange> words;

  bool get playable => playableProvenance.contains(group);

  /// The reviewed range of [word]; with no word, the clip's only reviewed
  /// range (none when it has several: which one is meant is not known).
  QiraatWordRange? reviewedRange([int? word]) {
    final ok = [
      for (final r in words)
        if (r.reviewed &&
            (word == null || r.word == word) &&
            (durationMs == null || r.endMs <= durationMs!))
          r,
    ];
    if (word != null) return ok.isEmpty ? null : ok.first;
    return ok.length == 1 ? ok.single : null;
  }
}

/// What to play: [uri] streamed, from [start] to [end] when a reviewed word
/// range exists, else the whole clip. To be played by the app's single
/// audio player (just_audio_background allows one): a `ClippingAudioSource`
/// over `AudioSource.uri(uri)` when [start] is set.
@immutable
class QiraatPlayback {
  const QiraatPlayback({
    required this.clip,
    required this.uri,
    this.start,
    this.end,
    this.word,
  });

  final QiraatClip clip;
  final Uri uri;
  final Duration? start;
  final Duration? end;

  /// The word the range holds, when only that range is played.
  final int? word;

  bool get wholeClip => start == null;
}

final _style = RegExp(r'^S\d+$');
final _name = RegExp(
  r'^R(\d+)_S(\d+)_Surah_(\d+)_Aya_?(\d+)_C(\d+)\.wav$',
  caseSensitive: false,
);

int? _int(Object? v) => v is int ? v : null;

/// One surah's file of the verse-level index (`data/qiraat_audio/index/`).
/// Malformed entries are left out; clips whose group's licence is unclear
/// are kept here and filtered by [clips].
@immutable
class QiraatAudioSurah {
  const QiraatAudioSurah(this.surah, this.verses);

  final int surah;

  /// Verse → style code (`S5`) → clips.
  final Map<int, Map<String, List<QiraatClip>>> verses;

  static QiraatAudioSurah? parse(String text, int surah) {
    try {
      final doc = jsonDecode(text);
      if (doc is! Map ||
          doc['format'] != 1 ||
          doc['surah'] != surah ||
          doc['verses'] is! Map) {
        return null;
      }
      final verses = <int, Map<String, List<QiraatClip>>>{};
      for (final ve in (doc['verses'] as Map).entries) {
        final ayah = int.tryParse('${ve.key}');
        if (ayah == null || ayah < 1 || ve.value is! Map) continue;
        for (final se in (ve.value as Map).entries) {
          final style = '${se.key}';
          if (!_style.hasMatch(style) || se.value is! List) continue;
          for (final c in se.value as List) {
            final clip = _clip(c, surah, ayah, style);
            if (clip == null) continue;
            ((verses[ayah] ??= {})[style] ??= []).add(clip);
          }
        }
      }
      return QiraatAudioSurah(surah, verses);
    } on FormatException {
      return null;
    }
  }

  static QiraatClip? _clip(Object? c, int surah, int ayah, String style) {
    if (c is! Map) return null;
    final file = c['file'];
    final url = Uri.tryParse('${c['url']}');
    final m = file is String ? _name.firstMatch(file) : null;
    if (m == null ||
        url == null ||
        url.scheme != 'https' ||
        int.parse(m.group(3)!) != surah ||
        int.parse(m.group(4)!) != ayah ||
        'S${int.parse(m.group(2)!)}' != style) {
      return null;
    }
    final words = <QiraatWordRange>[];
    if (c['words'] is List) {
      for (final w in c['words'] as List) {
        if (w is! Map || w['range'] is! List || w['by'] is! String) continue;
        final r = w['range'] as List;
        if (r.length != 3 || r.any((x) => x is! int)) continue;
        final (s, e, n) = (r[0] as int, r[1] as int, r[2] as int);
        if (s < 0 || e <= s || n < 1) continue;
        final rev = w['reviewed_by'];
        words.add(
          QiraatWordRange(
            startMs: s,
            endMs: e,
            word: n,
            by: w['by'] as String,
            reviewedBy: rev is String ? rev : null,
          ),
        );
      }
    }
    final dur = _int(c['duration_ms']);
    return QiraatClip(
      file: file as String,
      reciter: 'R${m.group(1)}',
      clip: int.parse(m.group(5)!),
      url: url,
      group: ProvenanceGroup.fromKey(c['group']),
      durationMs: dur != null && dur > 0 ? dur : null,
      words: List.unmodifiable(words),
    );
  }

  /// The playable clips of [ayah] in [style].
  List<QiraatClip> clips(int ayah, String style) => [
    for (final c in verses[ayah]?[style] ?? const <QiraatClip>[])
      if (c.playable) c,
  ];

  /// The styles [ayah] has a playable clip in, in code order.
  List<String> styles(int ayah) {
    final out = [
      for (final s in (verses[ayah] ?? const {}).keys)
        if (clips(ayah, s).isNotEmpty) s,
    ];
    out.sort((a, b) => int.parse(a.substring(1)) - int.parse(b.substring(1)));
    return out;
  }

  /// What to play for [ayah] in [style]: a clip with a reviewed range of
  /// [word] (only that range is played) if one exists, else the first
  /// playable clip, whole (or its only reviewed range when no word is
  /// asked). Null when the verse has no playable clip in that style.
  QiraatPlayback? playback(int ayah, String style, {int? word}) {
    final all = clips(ayah, style);
    if (all.isEmpty) return null;
    for (final c in all) {
      final r = c.reviewedRange(word);
      if (r != null) {
        return QiraatPlayback(
          clip: c,
          uri: c.url,
          start: Duration(milliseconds: r.startMs),
          end: Duration(milliseconds: r.endMs),
          word: r.word,
        );
      }
    }
    return QiraatPlayback(clip: all.first, uri: all.first.url);
  }
}
