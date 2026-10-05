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

  @override
  Future<List<MediaItem>> children(String parentMediaId) async {
    if (parentMediaId == root ||
        parentMediaId == AudioService.browsableRootId) {
      return [
        MediaItem(id: continueId, title: text.continueReading, playable: true),
        MediaItem(id: recitersId, title: text.reciters, playable: false),
      ];
    }
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
      return [
        for (final s in await surahs())
          MediaItem(
            id: 'play/$id/${s.id}',
            title: text.surah(s.id, s.nameAr),
            artist: reciter?.nameAr,
            playable: true,
          ),
      ];
    }
    return const [];
  }

  @override
  Future<void> play(String mediaId) async {
    if (mediaId == continueId) {
      final at = await position();
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
  }
}

/// The car's words, in the interface language.
class CarText {
  const CarText({
    required this.continueReading,
    required this.reciters,
    required this.surah,
  });

  final String continueReading;
  final String reciters;
  final String Function(int number, String name) surah;
}
