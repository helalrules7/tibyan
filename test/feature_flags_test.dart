import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/flags/feature_flags.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // In the testing phase every flag is on (the owner's decision,
  // 2026-10-05; the app is not public). Before a public release the
  // scholarly features go back off until their reviewed data exists.
  test('every feature has its own flag in the file', () async {
    final json = jsonDecode(
      await rootBundle.loadString('assets/config/feature_flags.json'),
    ) as Map<String, dynamic>;
    for (final f in Feature.values) {
      expect(json[f.key], isA<bool>(), reason: f.key);
    }
    final flags = await FeatureFlags.load(rootBundle);
    for (final f in Feature.values) {
      expect(flags.isOn(f), json[f.key], reason: f.key);
    }
  });
}
