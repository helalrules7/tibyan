import 'package:audio_service/audio_service.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../core/db/content_database.dart';

/// What a car (Android Auto, CarPlay) shows to choose a recitation:
///
///     root ─ «تابع من موضع القراءة»   (plays)
///          └ «القراء» ─ a reciter ─ a surah   (plays)
///
/// It reads and plays through the functions it is given, so it holds no
/// state of its own and can be tested without a car.
class CarBrowser implements MediaBrowserDelegate {
  CarBrowser({
    required this.reciters,
    required this.surahs,
    required this.position,
    required this.start,
    required this.text,
  });

  /// The recitations offered (those of the riwaya being read).
  final Future<List<ReciterRow>> Function() reciters;
  final Future<List<SurahRow>> Function() surahs;

  /// The last reading position (Hafs numbers), if any.
  final Future<({int surah, int ayah})?> Function() position;

  /// Plays [surah] (from [ayah]) by [reciter], or by the current reciter
  /// when [reciter] is null.
  final Future<void> Function({int? reciter, required int surah, int? ayah})
  start;

  /// The few words shown: `continue`, `reciters`, and a surah's name.
  final CarText text;

  static const root = 'root';
  static const continueId = 'continue';
  static const recitersId = 'reciters';

  /// The one item shown when a list can't be loaded (not playable, does
  /// nothing): the car says why instead of showing an empty list.
  static const unavailableId = 'unavailable';

  MediaItem get _unavailable =>
      MediaItem(id: unavailableId, title: text.unavailable, playable: false);

  @override
  String get playbackError => text.playbackError;

  @override
  Future<List<MediaItem>> children(String parentMediaId) async {
    if (parentMediaId == root ||
        parentMediaId == AudioService.browsableRootId) {
      return [
        MediaItem(id: continueId, title: text.continueReading, playable: true),
        MediaItem(id: recitersId, title: text.reciters, playable: false),
      ];
    }
    try {
      final items = await _list(parentMediaId);
      return items.isEmpty && parentMediaId != unavailableId
          ? [_unavailable]
          : items;
    } catch (_) {
      return [_unavailable];
    }
  }

  Future<List<MediaItem>> _list(String parentMediaId) async {
    if (parentMediaId == recitersId) {
      return [
        for (final r in await reciters())
          MediaItem(id: 'reciter/${r.id}', title: r.nameAr, playable: false),
      ];
    }
    if (parentMediaId.startsWith('reciter/')) {
      final id = int.tryParse(parentMediaId.substring('reciter/'.length));
      if (id == null) return const [];
      final reciter = (await reciters()).where((r) => r.id == id).firstOrNull;
      if (reciter == null) return const [];
      return [
        for (final s in await surahs())
          MediaItem(
            id: 'play/$id/${s.id}',
            title: text.surah(s.id, s.nameAr),
            artist: reciter.nameAr,
            playable: true,
          ),
      ];
    }
    return const [];
  }

  @override
  Future<void> play(String mediaId) async {
    if (mediaId == continueId) {
      // No reading position yet (a fresh install): Al-Fatiha.
      ({int surah, int ayah})? at;
      try {
        at = await position();
      } catch (_) {}
      return start(surah: at?.surah ?? 1, ayah: at?.ayah);
    }
    final parts = mediaId.split('/');
    if (parts.length == 3 && parts.first == 'play') {
      final reciter = int.tryParse(parts[1]);
      final surah = int.tryParse(parts[2]);
      if (reciter != null && surah != null && surah >= 1 && surah <= 114) {
        return start(reciter: reciter, surah: surah);
      }
    }
    throw ArgumentError.value(mediaId, 'mediaId', 'not playable');
  }
}

/// The car's words, in the interface language.
class CarText {
  const CarText({
    required this.continueReading,
    required this.reciters,
    required this.surah,
    required this.unavailable,
    required this.playbackError,
  });

  final String continueReading;
  final String reciters;
  final String Function(int number, String name) surah;

  /// Shown in place of a list that can't be loaded.
  final String unavailable;

  /// Shown when a recitation can't start (offline, nothing downloaded).
  final String playbackError;
}
