import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/features/home/whats_new.dart';

void main() {
  Future<SharedPreferences> prefs(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test('an update shows the notes once', () async {
    final p = await prefs({'settings.onboardingDone': true});
    expect(shouldShowWhatsNew(p), isTrue);
    await markWhatsNewSeen(p);
    expect(shouldShowWhatsNew(p), isFalse);
  });

  test('a first install never shows them', () async {
    final p = await prefs({});
    expect(shouldShowWhatsNew(p), isFalse);
  });

  test('older notes seen: the new ones show', () async {
    final p = await prefs({
      'settings.onboardingDone': true,
      whatsNewSeenKey: 'older',
    });
    expect(shouldShowWhatsNew(p), isTrue);
  });
}
