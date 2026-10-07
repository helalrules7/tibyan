import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../content_extras/verse_audio_index.dart';

/// One step of a recitation: a verse of the surah file, or a clip played
/// between verses (the translation read after a verse).
sealed class QueueItem {
  const QueueItem(this.surah, this.ayah);
  final int surah;
  final int ayah;
}

/// The reciter's [ayah], from the surah file and its timing.
class VerseItem extends QueueItem {
  const VerseItem(super.surah, super.ayah);

  @override
  bool operator ==(Object other) =>
      other is VerseItem && other.surah == surah && other.ayah == ayah;

  @override
  int get hashCode => Object.hash('v', surah, ayah);

  @override
  String toString() => 'VerseItem($surah:$ayah)';
}

/// A clip about [ayah] ([clip] of [index]), played after it.
class ClipItem extends QueueItem {
  const ClipItem(super.surah, super.ayah, this.clip, this.index);
  final VerseAudioClip clip;
  final VerseAudioIndex index;

  @override
  bool operator ==(Object other) =>
      other is ClipItem &&
      other.surah == surah &&
      other.ayah == ayah &&
      other.clip == clip &&
      other.index.id == index.id;

  @override
  int get hashCode => Object.hash('c', surah, ayah, clip, index.id);

  @override
  String toString() => 'ClipItem($surah:$ayah, ${clip.uri})';
}

/// What plays from [from] to [to] of [surah]: each verse, followed by its
/// clip in [after] when [after] has one for it. Only a verse's own file or
/// its stretch of a surah file counts: a whole surah file is not a verse's
/// clip. A verse the index lacks is simply followed by the next verse.
List<QueueItem> buildVerseQueue({
  required int surah,
  required int from,
  required int to,
  VerseAudioIndex? after,
}) => [
  for (var a = from; a <= to; a++) ...[
    VerseItem(surah, a),
    if (after?.clipFor(surah, a, wholeSurahs: false) case final clip?)
      ClipItem(surah, a, clip, after!),
  ],
];

/// The clip that follows each verse in [queue], by verse.
Map<int, ClipItem> clipsAfterVerses(List<QueueItem> queue) => {
  for (var i = 0; i + 1 < queue.length; i++)
    if (queue[i + 1] case final ClipItem c when queue[i] is VerseItem)
      queue[i].ayah: c,
};

/// The reader's choice «الترجمة المسموعة بعد كل آية»: off until chosen,
/// and offered only while its flag is on and the index is available.
class TranslationAudioChoice extends Notifier<bool> {
  static const key = 'settings.translationAudio';

  @override
  bool build() {
    final language = ref.watch(settingsProvider.select((s) => s.language));
    return ref.read(sharedPreferencesProvider).getBool(key) ??
        defaultTranslationAudioEnabled(
          language,
          systemLanguageCode: PlatformDispatcher.instance.locale.languageCode,
        );
  }

  void set(bool value) {
    state = value;
    unawaited(ref.read(sharedPreferencesProvider).setBool(key, value));
  }
}

final translationAudioChoiceProvider =
    NotifierProvider<TranslationAudioChoice, bool>(TranslationAudioChoice.new);
