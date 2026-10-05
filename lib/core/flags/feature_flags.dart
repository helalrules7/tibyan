import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Features that stay hidden until their reviewed data is ready.
enum Feature {
  tajweed,
  qiraat,
  qiraatAudio('qiraat_audio'),
  tawjih,
  munasabat,
  wujuhNazair('wujuh_nazair'),
  asbabNuzul('asbab_nuzul'),
  stories,
  topics,
  library,
  tafsirAudio('tafsir_audio'),
  translationAudio('translation_audio'),
  englishTafsir('english_tafsir'),
  oldMadinaEdition('old_madina_edition'),
  meaningSearch('meaning_search'),
  accountsSync('accounts_sync'),
  groupKhatma('group_khatma');

  const Feature([this._key]);
  final String? _key;
  String get key => _key ?? name;
}

/// Flags come from `assets/config/feature_flags.json`. A flagged feature
/// is shown only when its flag is on AND its reviewed data pack is
/// installed (the data check is added with each feature).
class FeatureFlags {
  const FeatureFlags(this._values);

  final Map<String, bool> _values;

  bool isOn(Feature feature) => _values[feature.key] ?? false;

  static Future<FeatureFlags> load(AssetBundle bundle) async {
    final json = jsonDecode(
      await bundle.loadString('assets/config/feature_flags.json'),
    ) as Map<String, dynamic>;
    return FeatureFlags({
      for (final e in json.entries)
        if (e.value is bool) e.key: e.value as bool,
    });
  }
}

final featureFlagsProvider = Provider<FeatureFlags>(
  (ref) => throw UnimplementedError('featureFlagsProvider not overridden'),
);
