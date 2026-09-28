import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/flags/feature_flags.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every flagged feature starts switched off', () async {
    final flags = await FeatureFlags.load(rootBundle);
    for (final f in Feature.values) {
      expect(flags.isOn(f), isFalse, reason: f.key);
    }
  });
}
